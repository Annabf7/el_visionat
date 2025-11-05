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

// 1. Funció 'lookupLicense': Verifica la llicència contra el registre.
import { lookupLicense } from './auth/lookup_license';

// 2. Funció 'requestRegistration': Desa la sol·licitud pendent amb l'email.
import { requestRegistration } from './auth/request_registration';

// 3. Funció 'completeRegistration': Finalitza el registre creant l'usuari (després de l'aprovació manual).
import { completeRegistration } from './auth/complete_registration';

// 4. Funció Auxiliar 'checkRegistrationStatus': Comprova si un email té una sol·licitud aprovada.
import { checkRegistrationStatus } from './auth/check_registration_status';

// 🗳️ SISTEMA DE VOTACIONS — trigger (single implementation exported)
import { onVoteWrite } from './votes/on_vote_write';

// ============================================================================
// Exportem les funcions perquè Firebase les reconegui
// ============================================================================
exports.lookupLicense = lookupLicense;
exports.requestRegistration = requestRegistration;
exports.completeRegistration = completeRegistration;
exports.checkRegistrationStatus = checkRegistrationStatus;

// 🗳️ Trigger de votacions — exposem una sola funció 'onVoteWrite' per evitar
// múltiples registres del mateix handler (exportar-la sota 3 noms feia que
// l'emulador executés el mateix handler diverses vegades per cada esdeveniment).
exports.onVoteWrite = onVoteWrite;

// --- ALTRES FUNCIONS (si n'hi ha en el futur) ---
// Aquí podríem afegir altres tipus de funcions (ex: triggers de Firestore, etc.)
