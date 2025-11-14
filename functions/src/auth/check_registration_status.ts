// functions/src/auth/check_registration_status.ts

import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { RegistrationRequest } from "../models/registration_request"; // Reutilitzem el model

// NOTA: No cal admin.initializeApp() aquí, ja es fa a index.ts
const db = admin.firestore();

/**
 * Interfície per tipar les dades que arriben des de Flutter.
 */
interface CheckStatusData {
  email: string;
}

/**
 * Funció Callable Auxiliar
 * Comprova si existeix una sol·licitud de registre APROVADA per a un email donat.
 * Dissenyada per ser cridada des de Flutter quan falla un intent de login,
 * per determinar si l'usuari hauria de ser redirigit a crear la contrasenya.
 *
 * @param {CheckStatusData} data - Conté 'email'.
 * @returns {Promise<{ isApproved: boolean, licenseId: string | null }>}
 * Retorna `isApproved: true` i el `licenseId` associat si es troba una
 * sol·licitud aprovada. Retorna `isApproved: false` altrament.
 * @throws {HttpsError}
 * - 'invalid-argument': Si falta l'email o no és vàlid.
 * - 'internal': Per a errors inesperats.
 */
export const checkRegistrationStatus = onCall({ timeoutSeconds: 30 }, async (request) => {
  const { email } = request.data as CheckStatusData;

  // 1. Validació bàsica d'entrada
  if (!email) {
    throw new HttpsError('invalid-argument', 'No s\'ha proporcionat cap correu electrònic.');
  }
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    // Tot i que improbable si ve d'un intent de login, validem per si de cas.
    throw new HttpsError('invalid-argument', 'El format del correu electrònic no és vàlid.');
  }

  const normalizedEmail = email.toLowerCase();

  try {
    const requestCollectionRef = db.collection('registration_requests');

    // 2. Cercar una sol·licitud APROVADA per aquest email
    const requestQuery = requestCollectionRef
      .where('email', '==', normalizedEmail)
      .where('status', '==', 'approved') // <-- CLAU: Només busquem les aprovades
      .limit(1);

    const requestSnapshot = await requestQuery.get();

    // 3. Retornar el resultat
    if (requestSnapshot.empty) {
      // No hi ha cap sol·licitud aprovada per aquest email
      return { isApproved: false, licenseId: null };
    } else {
      // Hem trobat una sol·licitud aprovada! Retornem 'true' i la llicència
      const approvedRequestData = requestSnapshot.docs[0].data() as RegistrationRequest;
      return { isApproved: true, licenseId: approvedRequestData.llissenciaId };
    }

  } catch (error) {
    console.error('Error a checkRegistrationStatus:', error);
    // No llancem HttpsError 'not-found', ja que no trobar res és un resultat esperat (isApproved: false).
    // Només llancem error per problemes interns.
    throw new HttpsError('internal', 'Ha ocorregut un error inesperat en comprovar l\'estat del registre.');
  }
});