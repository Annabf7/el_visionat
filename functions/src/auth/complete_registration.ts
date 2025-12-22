// functions/src/auth/complete_registration.ts

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {getAuth, UserRecord} from "firebase-admin/auth";
import {RegistrationRequest} from "../models/registration_request";
import {AppUser} from "../models/app_user";
import {LicenseProfile} from "../models/license_profile";

// NOTA: No cal admin.initializeApp() aquí, ja es fa a index.ts
const db = getFirestore();
const auth = getAuth();

/**
 * Interfície per tipar les dades que arriben des de Flutter (pantalla createPassword).
 */
interface CompleteRegistrationData {
  llissenciaId: string;
  email: string; // Incloem l'email per doble verificació
  password: string;
}

/**
 * Funció Callable (Pas 3 del flux de registre manual)
 * Finalitza el registre creant l'usuari a Firebase Auth i el perfil a Firestore,
 * NOMÉS SI la sol·licitud prèvia ha estat aprovada manualment.
 *
 * @param {CompleteRegistrationData} data - Conté 'llissenciaId', 'email' i 'password'.
 * @returns {Promise<{success: boolean, uid: string, message: string}>} Informació de l'usuari creat.
 * @throws {HttpsError}
 * - 'invalid-argument': Si falten dades o la contrasenya és massa curta.
 * - 'not-found': Si no es troba una sol·licitud APROVADA per a la llicència/email.
 * - 'permission-denied': Si la sol·licitud existeix però no està aprovada ('pending' o 'rejected').
 * - 'already-exists': Si l'email ja està en ús a Firebase Auth.
 * - 'internal': Per a errors inesperats durant el procés.
 */
export const completeRegistration = onCall({region: "europe-west1", timeoutSeconds: 60}, async (request) => {
  const {llissenciaId, email, password} = request.data as CompleteRegistrationData;

  // 1. Validació d'entrada
  if (!llissenciaId || !email || !password) {
    throw new HttpsError("invalid-argument", "Falten dades necessàries per completar el registre.");
  }
  // Firebase Auth requereix mínim 6 caràcters per a la contrasenya
  if (password.length < 6) {
    throw new HttpsError("invalid-argument", "La contrasenya ha de tenir almenys 6 caràcters.");
  }

  const normalizedEmail = email.toLowerCase();

  try {
    const requestCollectionRef = db.collection("registration_requests");
    const registryCollectionRef = db.collection("referees_registry");
    const usersCollectionRef = db.collection("users");

    // 2. Cercar la sol·licitud APROVADA
    // Busquem per llicència I email per assegurar-nos que coincideixen amb la sol·licitud original
    const requestQuery = requestCollectionRef
      .where("llissenciaId", "==", llissenciaId)
      .where("email", "==", normalizedEmail)
      .where("status", "==", "approved") // <-- CLAU: Només si està aprovada!
      .limit(1); // Només n'hi hauria d'haver una

    const requestSnapshot = await requestQuery.get();

    if (requestSnapshot.empty) {
      // Podria ser que no existeixi, que estigui pendent o rebutjada.
      // Comprovem si existeix però amb un altre estat per donar un error més específic.
      const checkOtherStatusQuery = requestCollectionRef
        .where("llissenciaId", "==", llissenciaId)
        .where("email", "==", normalizedEmail)
        .limit(1);
      const checkOtherStatusSnapshot = await checkOtherStatusQuery.get();

      if (checkOtherStatusSnapshot.empty) {
        throw new HttpsError("not-found", "No s'ha trobat cap sol·licitud de registre aprovada per a aquestes dades.");
      } else {
        const existingRequest = checkOtherStatusSnapshot.docs[0].data() as RegistrationRequest;
        if (existingRequest.status === "pending") {
          throw new HttpsError("permission-denied", "La teva sol·licitud de registre encara està pendent de revisió.");
        } else if (existingRequest.status === "rejected") {
          throw new HttpsError("permission-denied", `La teva sol·licitud de registre ha estat rebutjada. Motiu: ${existingRequest.rejectionReason || "No especificat"}`);
        } else {
          throw new HttpsError("not-found", "No s'ha trobat cap sol·licitud de registre aprovada vàlida.");
        }
      }
    }

    // Tenim una sol·licitud aprovada
    const approvedRequestDoc = requestSnapshot.docs[0];
    const approvedRequestData = approvedRequestDoc.data() as RegistrationRequest;

    // 3. Transacció Atòmica per crear usuari i actualitzar estats
    const newUid = await db.runTransaction(async (transaction) => {
      // 3a. Llegir de nou el registre dins la transacció per assegurar l'estat 'pending'
      const registryDocRef = registryCollectionRef.doc(llissenciaId);
      const registryDoc = await transaction.get(registryDocRef);
      if (!registryDoc.exists || registryDoc.data()?.accountStatus !== "pending") {
        throw new HttpsError("failed-precondition", "L'estat de la llicència al registre no és vàlid per completar el registre.");
      }
      const registryData = registryDoc.data() as LicenseProfile;

      // 3b. Crear l'usuari a Firebase Authentication
      let userRecord: UserRecord;
      try {
        userRecord = await auth.createUser({
          email: normalizedEmail,
          password: password,
          displayName: `${registryData.nom} ${registryData.cognoms}`, // Nom agafat del registre
        });
      } catch (error: any) {
        if (error.code === "auth/email-already-exists") {
          throw new HttpsError("already-exists", "Aquest correu electrònic ja està registrat.");
        } else {
          console.error("Error creant usuari a Auth:", error);
          throw new HttpsError("internal", "Error intern al crear el compte d'usuari.");
        }
      }
      const createdUid = userRecord.uid;

      // 3c. Crear el document de perfil a /users/{uid}
      // Obtenim el gender de la sol·licitud aprovada (fallback a 'male' per compatibilitat)
      const userGender = approvedRequestData.gender || "male";
      const newUserProfile: AppUser = {
        uid: createdUid,
        email: normalizedEmail,
        displayName: `${registryData.nom} ${registryData.cognoms}`,
        role: "referee", // O determinar si és 'auxiliar' basat en registryData.categoriaRrtt si cal
        llissenciaId: llissenciaId,
        categoriaRrtt: registryData.categoriaRrtt,
        gender: userGender,
        isSubscribed: false, // Estat inicial de subscripció
        createdAt: FieldValue.serverTimestamp(),
      };
      const userDocRef = usersCollectionRef.doc(createdUid);
      transaction.set(userDocRef, newUserProfile);

      // 3d. Actualitzar l'estat a /referees_registry/{llissenciaId} a 'active'
      transaction.update(registryDocRef, {accountStatus: "active"});

      // 3e. Actualitzar l'estat a /registration_requests/{requestId} a 'completed'
      transaction.update(approvedRequestDoc.ref, {
        status: "completed", // Marquem com a completada
        updatedAt: FieldValue.serverTimestamp(),
      });

      return createdUid; // La transacció retorna el UID del nou usuari
    }); // Fi de la transacció

    // 4. Èxit
    return {
      success: true,
      uid: newUid,
      message: "Registre completat amb èxit! Ja pots iniciar sessió.",
    };
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error; // Re-llancem els errors HttpsError
    }
    console.error("Error a completeRegistration:", error);
    throw new HttpsError("internal", "Ha ocorregut un error inesperat en finalitzar el registre.");
  }
});
