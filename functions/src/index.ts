// ============================================================================
// Index - Punt d'Entrada de les Cloud Functions
// ============================================================================
// Aquest fitxer importa les funcions individuals dels seus mòduls
// i les exporta perquè Firebase les pugui desplegar i executar.
// ============================================================================

import * as admin from 'firebase-admin';

// Initialize the Admin SDK once for all functions in this module
if (admin.apps.length === 0) {
  admin.initializeApp();
}

// Import only existing function modules from src/auth and src/votes
import { lookupLicense } from './auth/lookup_license';
import { requestRegistration } from './auth/request_registration';
import { completeRegistration } from './auth/complete_registration';
import { checkRegistrationStatus } from './auth/check_registration_status';
import { onVoteWrite } from './votes/on_vote_write';
import { sendRegistrationNotificationHttp } from './email/send_registration_notification_http';
import { onRegistrationStatusUpdate } from './auth/on_registration_status_update';

// Export functions with the exact names expected by the client
exports.lookupLicense = lookupLicense;
exports.requestRegistration = requestRegistration;
exports.completeRegistration = completeRegistration;
exports.checkRegistrationStatus = checkRegistrationStatus;
exports.onVoteWrite = onVoteWrite;
exports.sendRegistrationNotificationHttp = sendRegistrationNotificationHttp;
exports.onRegistrationStatusUpdate = onRegistrationStatusUpdate;

// --- ALTRES FUNCIONS (si n'hi ha en el futur) ---
// Aquí podríem afegir altres tipus de funcions (ex: triggers de Firestore, etc.)
