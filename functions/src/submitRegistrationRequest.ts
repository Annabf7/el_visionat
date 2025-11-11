import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getFirestore, FieldValue, DocumentSnapshot } from 'firebase-admin/firestore';

const db = getFirestore();

interface Payload {
  email: string;
  llissenciaId: string;
}

// Helper: normalize email
function normalizeEmail(raw: unknown): string {
  if (typeof raw !== 'string') return '';
  return raw.trim().toLowerCase();
}

// Helper: read registry doc and validate
async function validateLicenseInTx(tx: FirebaseFirestore.Transaction, llissenciaId: string) {
  const registryRef = db.collection('referees_registry').doc(llissenciaId);
  const registrySnap = await tx.get(registryRef);
  if (!registrySnap.exists) {
    console.warn('[submitRegistrationRequest] License not found:', llissenciaId);
    throw new HttpsError('not-found', 'El número de llicència no s\'ha trobat al nostre registre.');
  }
  const registryData = registrySnap.data() as any;
  if (!registryData) {
    console.error('[submitRegistrationRequest] Failed to read registry data for', llissenciaId);
    throw new HttpsError('internal', 'Error llegint les dades del registre.');
  }
  if (registryData.accountStatus !== 'pending') {
    console.warn('[submitRegistrationRequest] License status not pending:', registryData.accountStatus);
    throw new HttpsError('failed-precondition', 'Aquesta llicència ja té un compte actiu o està en un estat inesperat.');
  }
  return registryData;
}

// Helper: check pending requests for license/email
async function checkPendingRequestsInTx(tx: FirebaseFirestore.Transaction, llissenciaId: string, normalizedEmail: string) {
  const requestCollectionRef = db.collection('registration_requests');
  const existingRequestLicenseQuery = requestCollectionRef
    .where('llissenciaId', '==', llissenciaId)
    .where('status', '==', 'pending');
  const existingRequestLicenseSnap = await tx.get(existingRequestLicenseQuery);
  if (!existingRequestLicenseSnap.empty) {
    console.warn('[submitRegistrationRequest] Pending request exists for license:', llissenciaId);
    throw new HttpsError('already-exists', 'licenseRequestExists');
  }

  const existingRequestEmailQuery = requestCollectionRef
    .where('email', '==', normalizedEmail)
    .where('status', '==', 'pending');
  const existingRequestEmailSnap = await tx.get(existingRequestEmailQuery);
  if (!existingRequestEmailSnap.empty) {
    console.warn('[submitRegistrationRequest] Pending request exists for email:', normalizedEmail);
    throw new HttpsError('already-exists', 'emailAlreadyInUse');
  }
}

export const submitRegistrationRequest = onCall(async (request) => {
  console.log('[submitRegistrationRequest] Received request:', JSON.stringify(request.data));

  const data = request.data as Payload | undefined;
  if (!data) {
    console.warn('[submitRegistrationRequest] Missing payload');
    throw new HttpsError('invalid-argument', 'Falten dades (email o llissenciaId)');
  }

  const normalizedEmail = normalizeEmail((data as any).email);
  const llissenciaId = (data as any).llissenciaId;

  // Basic validation
  if (!normalizedEmail || !llissenciaId) {
    console.warn('[submitRegistrationRequest] Invalid input', { normalizedEmail, llissenciaId });
    throw new HttpsError('invalid-argument', 'Falten dades vàlides (email o llissenciaId).');
  }

  const emailDocRef = db.collection('emails').doc(normalizedEmail);

  try {
    await db.runTransaction(async (tx) => {
      console.log('[submitRegistrationRequest] Transaction start for', normalizedEmail, llissenciaId);

      // 1. Check if emails/<email> exists
      const emailSnap = await tx.get(emailDocRef);
      if (emailSnap.exists) {
        console.warn('[submitRegistrationRequest] Email already reserved:', normalizedEmail);
        throw new HttpsError('already-exists', 'emailAlreadyInUse');
      }

      // 2. Validate license inside transaction
      const registryData = await validateLicenseInTx(tx as any, llissenciaId);

      // 3. Check pending requests for license/email
      await checkPendingRequestsInTx(tx as any, llissenciaId, normalizedEmail);

      // 4. Reserve email doc
      console.log('[submitRegistrationRequest] Reserving emails doc for', normalizedEmail);
      tx.set(emailDocRef, {
        licenseId: llissenciaId,
        createdAt: FieldValue.serverTimestamp(),
      });

      // 5. Create registration_requests doc
      const requestCollectionRef = db.collection('registration_requests');
      const newRequestRef = requestCollectionRef.doc();
      const newRequestData = {
        llissenciaId: llissenciaId,
        email: normalizedEmail,
        nom: registryData.nom,
        cognoms: registryData.cognoms,
        status: 'pending',
        createdAt: FieldValue.serverTimestamp(),
      };
      tx.set(newRequestRef, newRequestData);

      console.log('[submitRegistrationRequest] Transaction prepared: reservation + request doc set for', normalizedEmail);
    });

    console.log('[submitRegistrationRequest] Transaction committed successfully for', normalizedEmail);
    return { success: true, message: 'Sol·licitud de registre enviada correctament.' };
  } catch (err) {
    console.error('[submitRegistrationRequest] Error during transaction:', err);
    if (err instanceof HttpsError) {
      // propagate structured error
      throw err;
    }
    // For unexpected errors, wrap in an internal error
    throw new HttpsError('internal', 'Ha ocorregut un error inesperat en processar la sol\u00b7licitud.');
  }
});
