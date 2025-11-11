// functions/src/auth/request_registration.ts
// Versió amb onCall v2, regió especificada, i logs de depuració

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { RegistrationRequest } from "../models/registration_request";
import { LicenseProfile } from "../models/license_profile"; // Importem LicenseProfile

const db = getFirestore();

interface RequestRegistrationData {
  llissenciaId: string;
  email: string;
}

// Assegurem la regió aquí
export const requestRegistration = onCall(async (request) => {
  // Log inicial
  console.log('[requestRegistration onCall] Received request with data:', JSON.stringify(request.data));

  const { llissenciaId, email } = request.data as RequestRegistrationData;

  // 1. Validació bàsica d'entrada
  if (!llissenciaId || !email) {
     console.warn('[requestRegistration onCall] Invalid argument: Missing llissenciaId or email');
    throw new HttpsError('invalid-argument', 'Falten l\'ID de llicència o el correu electrònic.');
  }
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
     console.warn('[requestRegistration onCall] Invalid argument: Invalid email format');
    throw new HttpsError('invalid-argument', 'El format del correu electrònic no és vàlid.');
  }
  const normalizedEmail = email.toLowerCase();
  console.log(`[requestRegistration onCall] Processing request for license ${llissenciaId} and email ${normalizedEmail}`);


  try {
    const registryDocRef = db.collection('referees_registry').doc(llissenciaId);
    const requestCollectionRef = db.collection('registration_requests');

    // 2. Transacció per garantir consistència
    await db.runTransaction(async (transaction) => {
      console.log('[requestRegistration onCall] Starting transaction...'); // Log transacció

      // 2a. Llegir el document del registre dins la transacció
      const registryDoc = await transaction.get(registryDocRef);
      console.log(`[requestRegistration onCall] Transaction: Fetched registry doc (exists: ${registryDoc.exists})`);


      if (!registryDoc.exists) {
         console.warn(`[requestRegistration onCall] Transaction: Registry doc ${llissenciaId} not found.`);
        throw new HttpsError(
          'not-found',
          'El número de llicència no s\'ha trobat al nostre registre.'
        );
      }

      // [CORRECCIÓ] Assegurem el tipus correcte aquí
      const registryData = registryDoc.data() as LicenseProfile | undefined;
      if (!registryData) { // Comprovació més segura
         console.error(`[requestRegistration onCall] Transaction: Failed to read registry data for ${llissenciaId}.`);
        throw new HttpsError('internal', 'Error llegint les dades del registre.');
      }

      // 2b. Comprovar l'estat al registre
      if (registryData.accountStatus !== 'pending') {
         console.warn(`[requestRegistration onCall] Transaction: License ${llissenciaId} status is not pending (${registryData.accountStatus}).`);
        throw new HttpsError(
          'failed-precondition',
          'Aquesta llicència ja té un compte actiu o està en un estat inesperat.'
        );
      }

      // 2c. Comprovar si JA EXISTEIX una sol·licitud PENDENT per aquesta llicència
      console.log(`[requestRegistration onCall] Transaction: Querying existing pending request by license ${llissenciaId}...`);
      const existingRequestLicenseQuery = requestCollectionRef
        .where('llissenciaId', '==', llissenciaId)
        .where('status', '==', 'pending');
      const existingRequestLicenseSnapshot = await transaction.get(existingRequestLicenseQuery);
       console.log(`[requestRegistration onCall] Transaction: Found ${existingRequestLicenseSnapshot.size} pending requests for license.`);

      if (!existingRequestLicenseSnapshot.empty) {
          console.warn(`[requestRegistration onCall] Transaction: Pending request already exists for license ${llissenciaId}.`);
         throw new HttpsError(
          'already-exists',
          'Ja existeix una sol·licitud de registre pendent per a aquesta llicència.'
        );
      }

      // 2d. Comprovar si JA EXISTEIX una sol·licitud PENDENT per aquest EMAIL
       console.log(`[requestRegistration onCall] Transaction: Querying existing pending request by email ${normalizedEmail}...`);
       const existingRequestEmailQuery = requestCollectionRef
        .where('email', '==', normalizedEmail)
        .where('status', '==', 'pending');
      const existingRequestEmailSnapshot = await transaction.get(existingRequestEmailQuery);
      console.log(`[requestRegistration onCall] Transaction: Found ${existingRequestEmailSnapshot.size} pending requests for email.`);

       if (!existingRequestEmailSnapshot.empty) {
         console.warn(`[requestRegistration onCall] Transaction: Pending request already exists for email ${normalizedEmail}.`);
         throw new HttpsError(
          'already-exists',
          'Ja existeix una sol·licitud de registre pendent per a aquest correu electrònic.'
        );
      }

      // 3. Crear el nou document de sol·licitud
      console.log('[requestRegistration onCall] Transaction: Creating new request document...');
      const newRequestRef = requestCollectionRef.doc(); // Firestore genera un ID automàtic
      const newRequestData: RegistrationRequest = {
        llissenciaId: llissenciaId,
        email: normalizedEmail,
        nom: registryData.nom, // Agafem nom/cognoms del document llegit dins la transacció
        cognoms: registryData.cognoms,
        status: 'pending',
        createdAt: FieldValue.serverTimestamp(),
      };

      transaction.set(newRequestRef, newRequestData);
      console.log('[requestRegistration onCall] Transaction: New request document set.');

    }); // Fi de la transacció
     console.log('[requestRegistration onCall] Transaction committed successfully.');


    // 4. Èxit
     console.log('[requestRegistration onCall] Request processed successfully.');
    return {
      success: true,
      message: 'Sol·licitud de registre enviada correctament. Serà revisada aviat.',
    };

  } catch (error) {
     console.error('[requestRegistration onCall] Error during execution:', error); // Log d'error
    if (error instanceof HttpsError) {
      throw error; // Re-llancem els errors HttpsError
    }
    // Per a qualsevol altre error inesperat dins la lògica o transacció
    throw new HttpsError('internal', 'Ha ocorregut un error inesperat en processar la sol·licitud.');
  }
});
