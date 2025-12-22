import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getFirestore, Timestamp} from "firebase-admin/firestore";
import {getAuth} from "firebase-admin/auth";
import {LicenseProfile} from "../models/license_profile";
import {AppUser} from "../models/app_user";

const db = getFirestore();

interface RegisterData {
  email: string;
  password: string;
  nom: string;
  cognoms: string;
  llissenciaId: string;
}

export const validateLicenseRegister = onCall({region: "europe-west1", timeoutSeconds: 60}, async (request) => {
  const data = request.data as RegisterData;
  const {email, password, nom, cognoms, llissenciaId} = data;

  if (!email || !password || !nom || !cognoms || !llissenciaId) {
    throw new HttpsError("invalid-argument", "Tots els camps de registre són obligatoris.");
  }

  // --- SEGURETAT: PAS CLAU DE VALIDACIÓ CONTRA LA LLISTA MESTRA ---
  try {
    // 2. Cercar a la Llista de Llicències
    const registryDoc = await db.collection("referees_registry").doc(llissenciaId).get();

    if (!registryDoc.exists) {
      // Llicència no trobada
      throw new HttpsError("unauthenticated", "Llicència no trobada al registre. Accés denegat.");
    }

    const registryData = registryDoc.data() as LicenseProfile;

    // 3. Comprovació d'Extricta Coincidència de Dades
    const emailMatch = registryData.email.toLowerCase() === email.toLowerCase();
    const nomMatch = registryData.nom.toLowerCase() === nom.toLowerCase();
    const cognomsMatch = registryData.cognoms.toLowerCase() === cognoms.toLowerCase();

    if (!emailMatch || !nomMatch || !cognomsMatch) {
      throw new HttpsError("unauthenticated", "Les dades proporcionades no coincideixen amb el registre oficial. Verifiqueu nom, cognoms i correu electrònic.");
    }

    // 4. Comprovar que l'email no estigui ja en ús abans de crear el document /users
    const auth = getAuth();
    try {
      await auth.getUserByEmail(email);
      throw new HttpsError("already-exists", "Aquest correu electrònic ja té un compte registrat.");
    } catch (e: any) {
      if (e.code !== "auth/user-not-found") {
        throw new HttpsError("internal", "Error de verificació d'usuari existent.");
      }
    }


    // 5. Crear l'usuari a Firebase Authentication
    const userRecord = await auth.createUser({email, password});
    const newUid = userRecord.uid;

    // 6. Crear el Document de Perfil de l'Usuari a /users/{uid}
    const newUserProfile: AppUser = {
      uid: newUid,
      email: email,
      displayName: `${nom} ${cognoms}`,
      role: "referee",
      isSubscribed: false,
      createdAt: Timestamp.now(),
      llissenciaId: llissenciaId,
      categoriaRrtt: registryData.categoriaRrtt,
      gender: "male", // Default per flux sense selecció
    };

    await db.collection("users").doc(newUid).set(newUserProfile);

    // 7. Actualitzar l'estat al registre oficial
    await registryDoc.ref.update({accountStatus: "active"});

    return {success: true, uid: newUid, message: "Registre completat amb èxit."};
  } catch (error: any) {
    console.error("Error during license registration process:", error);

    if (error instanceof HttpsError) {
      throw error;
    }
    if (error.code && error.code === "auth/email-already-in-use") {
      throw new HttpsError("already-exists", "Aquest correu electrònic ja té un compte registrat.");
    }

    throw new HttpsError("internal", `Error intern: ${error.message}`);
  }
});
