// functions/src/auth/lookup_license.ts
// Versió original amb onCall v2

import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * Funció Callable (Pas 1 del flux)
 * Busca una llicència al registre i retorna les dades si és vàlida i pendent.
 */
export const lookupLicense = onCall(async (request) => { 
  // Afegim un log aquí per veure si arriba la crida
  console.log('[lookupLicense onCall] Received request with data:', JSON.stringify(request.data));

  const llissenciaId = String(request.data.llissenciaId || '').trim();

  if (!llissenciaId) {
    console.warn('[lookupLicense onCall] Invalid argument: Missing llissenciaId');
    throw new HttpsError(
      'invalid-argument',
      'No s\'ha proporcionat un número de llicència.'
    );
  }

  console.log(`[lookupLicense onCall] Looking up license: ${llissenciaId}`);

  try {
    const registryDocRef = db.collection('referees_registry').doc(llissenciaId);
    const registryDoc = await registryDocRef.get();

    if (!registryDoc.exists) {
      console.warn(`[lookupLicense onCall] Not found: License ${llissenciaId}`);
      throw new HttpsError(
        'not-found',
        'El número de llicència no s\'ha trobat al nostre registre. Si us plau, verifica-ho.'
      );
    }

    const registryData = registryDoc.data();
    if (!registryData) {
      console.error(`[lookupLicense onCall] Internal error: Could not read data for license ${llissenciaId}`);
      throw new HttpsError('internal', 'Error llegint les dades del registre.');
    }
     console.log(`[lookupLicense onCall] Found data:`, registryData);


    if (registryData.accountStatus === 'active') {
       console.warn(`[lookupLicense onCall] Already exists: License ${llissenciaId} is active`);
      throw new HttpsError(
        'already-exists',
        'Aquesta llicència ja està associada a un compte actiu.'
      );
    }
    if (registryData.accountStatus !== 'pending') {
         console.warn(`[lookupLicense onCall] Failed precondition: License ${llissenciaId} has unexpected status: ${registryData.accountStatus}`);
         throw new HttpsError(
           'failed-precondition',
           `L'estat de la llicència (${registryData.accountStatus}) no permet el registre.`
         );
       }


    console.log(`[lookupLicense onCall] Success for license ${llissenciaId}`);
    return {
      nom: registryData.nom,
      cognoms: registryData.cognoms,
      categoriaRrtt: registryData.categoriaRrtt,
    };

  } catch (error) {
     console.error(`[lookupLicense onCall] Error during execution for license ${llissenciaId}:`, error);
    if (error instanceof HttpsError) {
      throw error; // Re-llancem els HttpsError que hem creat nosaltres
    }
    // Per a qualsevol altre error inesperat
    throw new HttpsError('internal', 'Ha ocorregut un error inesperat durant la verificació.');
  }
});