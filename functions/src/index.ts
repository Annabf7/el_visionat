// ============================================================================
// Index - Punt d'Entrada de les Cloud Functions
// ============================================================================
// Aquest fitxer importa les funcions individuals dels seus mòduls
// i les exporta perquè Firebase les pugui desplegar i executar.
// ============================================================================

import * as admin from 'firebase-admin';

// [CONSTITUCIÓ] Inicialitzem l'SDK d'Admin UNA SOLA VEGADA aquí
// Això evita inicialitzacions múltiples dins de cada funció.
if (admin.apps.length === 0) {
  admin.initializeApp();
}

// --- FLUX DE REGISTRE MANUAL (Opció B) ---

// [PROVA DE DEPURACIÓ] Reactivant les funcions una per una.

// 1. Funció 'lookupLicense': Verifica la llicència contra el registre.
import { lookupLicense } from './auth/lookup_license';

// 2. Funció 'requestRegistration': Guarda la sol·licitud pendent amb l'email.
import { requestRegistration } from './auth/request_registration';

// 3. Funció 'completeRegistration': Finalitza el registre creant l'usuari (després de l'aprovació manual).
import { completeRegistration } from './auth/complete_registration';

// 4. Funció Auxiliar 'checkRegistrationStatus': Comprova si un email té una sol·licitud aprovada.
import { checkRegistrationStatus } from './auth/check_registration_status';

// Exportem les funcions perquè Firebase les reconegui
exports.lookupLicense = lookupLicense;
exports.requestRegistration = requestRegistration;
exports.completeRegistration = completeRegistration;
exports.checkRegistrationStatus = checkRegistrationStatus;


// --- ALTRES FUNCIONS (si n'hi ha en el futur) ---
// Aquí podríem afegir altres tipus de funcions (ex: triggers de Firestore, etc.)

// --- Codi d'exemple (comentat, de la plantilla inicial) ---
/**
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 * import {onRequest} from "firebase-functions/v2/https";
 * import * as logger from "firebase-functions/logger";
 *
 * export const helloWorld = onRequest((request, response) => {
 * logger.info("Hello logs!", {structuredData: true});
 * response.send("Hello from Firebase!");
 * });
 */