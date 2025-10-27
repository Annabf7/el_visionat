import { onCall, HttpsError } from "firebase-functions/v2/https"; // <-- CANVI CLAU
import * as admin from "firebase-admin";

// Assegura't que l'SDK d'Admin estigui inicialitzat
if (admin.apps.length === 0) {
  admin.initializeApp();
}
const db = admin.firestore();

/**
 * Funció Callable (Pas 2 del flux)
 * Busca una llicència al registre i retorna les dades si és vàlida.
 *
 * @param {string} llissenciaId - El número de llicència introduït per l'usuari.
 * @returns {Promise<{nom: string, cognoms: string, categoriaRrtt: string}>}
 * Retorna les dades públiques de l'àrbitre si es troba i està pendent.
 * @throws {HttpsError}
 * - 'invalid-argument': Si no es proporciona 'llissenciaId'.
 * - 'not-found': Si la llicència no existeix al registre.
 * - 'already-exists': Si la llicència ja té un compte actiu.
 */
export const lookupLicense = onCall(async (request) => { // <-- CANVI CLAU
  const llissenciaId = String(request.data.llissenciaId || '').trim();

  if (!llissenciaId) {
    throw new HttpsError( // <-- CANVI CLAU
      'invalid-argument',
      'No s\'ha proporcionat un número de llicència.'
    );
  }

  try {
    const registryDocRef = db.collection('referees_registry').doc(llissenciaId);
    const registryDoc = await registryDocRef.get();

    if (!registryDoc.exists) {
      throw new HttpsError( // <-- CANVI CLAU
        'not-found',
        'El número de llicència no s\'ha trobat al nostre registre. Si us plau, verifica-ho.'
      );
    }

    const registryData = registryDoc.data();
    if (!registryData) {
      throw new HttpsError('internal', 'Error llegint les dades del registre.'); // <-- CANVI CLAU
    }

    // Comprovem si el compte ja està actiu
    if (registryData.accountStatus === 'active') {
      throw new HttpsError( // <-- CANVI CLAU
        'already-exists',
        'Aquesta llicència ja està associada a un compte actiu.'
      );
    }

    // Èxit: La llicència és vàlida i està pendent de registre
    return {
      nom: registryData.nom,
      cognoms: registryData.cognoms,
      categoriaRrtt: registryData.categoriaRrtt,
    };

  } catch (error) {
    if (error instanceof HttpsError) { // <-- CANVI CLAU
      throw error; // Re-llancem els errors HttpsError que hem creat nosaltres
    }
    // Per a qualsevol altre error inesperat
    console.error('Error a lookupLicense:', error);
    throw new HttpsError('internal', 'Ha ocorregut un error inesperat.'); // <-- CANVI CLAU
  }
});

