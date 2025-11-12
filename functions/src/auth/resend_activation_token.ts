import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { inspect } from 'util';
import { sendWelcomeEmail } from '../email/send_welcome_email';

const db = getFirestore();

// Helper to generate an 8-character alphanumeric token
function generateToken(length = 8) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let out = '';
  for (let i = 0; i < length; i++) {
    out += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return out;
}

// Use onCall v2 so we can declare the secret (RESEND_API_KEY) in the function
export const resendActivationToken = onCall({ secrets: ['RESEND_API_KEY'] }, async (request) => {
  try {
    const body = request.data as any;
    try {
      console.log('[resendActivationToken] Request received:', JSON.stringify(body));
    } catch (e) {
      console.log('[resendActivationToken] Request received (inspect):', inspect(body, { depth: null }));
    }

    const normalized = (body && typeof body === 'object' && (body.data || body.payload))
      ? (body.data ?? body.payload)
      : body;

    const emailRaw = (normalized?.email ?? '');
    const email = (typeof emailRaw === 'string' ? emailRaw : String(emailRaw)).trim().toLowerCase();

    console.log(`[resendActivationToken] Request received for ${email}.`);

    if (!email) {
      throw new HttpsError('invalid-argument', 'Missing email');
    }

    // Find approved registration request for this email
    const q = await db.collection('registration_requests')
      .where('email', '==', email)
      .where('status', '==', 'approved')
      .limit(1)
      .get();

    if (q.empty) {
      console.warn(`[resendActivationToken] No approved registration found for ${email}`);
      throw new HttpsError('not-found', 'No s\'ha trobat cap registre amb aquest correu.');
    }

    const doc = q.docs[0];
    const docRef = doc.ref;
    const dataDoc = doc.data() as any;

    // Generate new token and update the document
    const newToken = generateToken(8);

    await docRef.update({
      activationToken: newToken,
      activationTokenCreatedAt: FieldValue.serverTimestamp(),
      activationTokenUsed: false,
    });

    // Fire the welcome email (re-uses existing helper)
    try {
      await sendWelcomeEmail({
        email,
        nom: dataDoc.nom || '',
        cognoms: dataDoc.cognoms || '',
        llissenciaId: dataDoc.llissenciaId || dataDoc.licencia || '',
        activationToken: newToken,
      });
    } catch (emailErr) {
      console.error('[resendActivationToken] Email send failed', emailErr);
      // Don't reveal email errors to the client; surface as internal
      throw new HttpsError('internal', 'Failed to send email');
    }

    console.log('[resendActivationToken] New token generated and email sent.');

    return { success: true, message: 'Nou codi enviat.' };
  } catch (err) {
    console.error('[resendActivationToken] Error', err);
    if (err instanceof HttpsError) {
      throw err;
    }
    throw new HttpsError('internal', 'Server error');
  }
});
