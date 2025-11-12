import { onRequest, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
// For callable compatibility with the client SDK (httpsCallable), export a
// small wrapper using the v1 `onCall` API. Importing v1 here is safe and
// keeps the existing onRequest implementation for direct HTTP use.
import * as functionsV1 from 'firebase-functions';
import { inspect } from 'util';

const db = getFirestore();

interface ValidateBody {
  token?: string;
  email?: string;
}

export const validateActivationToken = onRequest(async (req, res) => {
  try {
    if (req.method !== 'POST') {
      res.status(405).json({ success: false, message: 'Method Not Allowed' });
      return;
    }

    const body = req.body as ValidateBody;
    const token = (body?.token || '').trim();
    const email = (body?.email || '').trim().toLowerCase();

    if (!token || !email) {
      res.status(400).json({ success: false, message: 'Invalid request' });
      return;
    }

    console.log(`[validateActivationToken] Received token validation request for email: ${email}`);

    // Query for a registration request that matches email, token and unused
    const q = await db
      .collection('registration_requests')
      .where('email', '==', email)
      .where('activationToken', '==', token)
      .where('activationTokenUsed', '==', false)
      .limit(1)
      .get();

    if (q.empty) {
      console.warn('[validateActivationToken] Token match not found for provided email');
      throw new HttpsError('permission-denied', 'Token invàlid o caducat.');
    }

    const doc = q.docs[0];
    const docRef = doc.ref;
    const data = doc.data() as any;

    const createdAt = data.activationTokenCreatedAt;
    if (!createdAt) {
      console.warn('[validateActivationToken] No token timestamp');
      throw new HttpsError('permission-denied', 'Token invàlid o caducat.');
    }

    const createdMs = (createdAt.toDate ? createdAt.toDate().getTime() : new Date(createdAt).getTime());
    const now = Date.now();
    const ttlMs = 48 * 60 * 60 * 1000; // 48 hours
    if (now - createdMs > ttlMs) {
      console.warn('[validateActivationToken] Token expired');
      throw new HttpsError('permission-denied', 'Token invàlid o caducat.');
    }

    // Atomically mark token used in a transaction (double-check fields to avoid race)
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(docRef);
      if (!snap.exists) {
        console.warn('[validateActivationToken] Document disappeared in transaction');
        throw new HttpsError('not-found', 'Token not found');
      }
      const cur = snap.data() as any;
      if ((cur.activationTokenUsed ?? false) === true) {
        console.warn('[validateActivationToken] Token already marked used');
        throw new HttpsError('permission-denied', 'Token invàlid o caducat.');
      }
      if ((cur.activationToken || '') !== token || (cur.email || '').toLowerCase() !== email) {
        console.warn('[validateActivationToken] Token/email mismatch in transaction');
        throw new HttpsError('permission-denied', 'Token invàlid o caducat.');
      }
      tx.update(docRef, {
        activationTokenUsed: true,
        activationTokenUsedAt: FieldValue.serverTimestamp(),
      });
    });

    console.log('[validateActivationToken] Token match found and marked used');

    // Success: return a clear message
    res.status(200).json({ success: true, message: 'Token valid. User may proceed.' });
    return;
  } catch (err) {
    console.error('[validateActivationToken] Error', err);
    // Handle errors that follow the HttpsError shape (some runtimes don't
    // expose the same HttpsError constructor for instanceof checks). Fall
    // back to checking for a string `code` property so we don't trigger a
    // TypeError when the constructor is missing in the emulator/runtime.
    // Map some common HttpsError codes to HTTP statuses.
    if (err && (err as any).code && typeof (err as any).code === 'string') {
      const code = (err as any).code || 'internal';
      let status = 500;
      if (code === 'permission-denied') status = 403;
      else if (code === 'invalid-argument') status = 400;
      else if (code === 'not-found') status = 404;
      else if (code === 'already-exists') status = 409;

      try {
        res.status(status).json({ success: false, message: (err as any).message });
      } catch (_) {}
      return;
    }

    try {
      res.status(500).json({ success: false, message: 'Server error' });
    } catch (_) {}
    return;
  }
});

// --- Callable wrapper (for firebase client httpsCallable) ---
// This wrapper reuses the same logic as the HTTP handler but exposes a
// callable function which the Flutter `httpsCallable('validateActivationToken')`
// call can successfully reach. The callable expects an object { email, token }.
export const validateActivationTokenCallable = functionsV1.https.onCall(async (data, context) => {
  try {
    const body = data as ValidateBody | any;

    // Log the incoming payload for debugging (helps diagnose emulator vs client shapes).
    // Use JSON.stringify when possible, but fall back to util.inspect to avoid
    // "Converting circular structure to JSON" errors when the payload contains
    // circular references (seen in emulator environments).
    try {
      console.log('[validateActivationTokenCallable] incoming payload:', JSON.stringify(body));
    } catch (logErr) {
      console.log('[validateActivationTokenCallable] incoming payload (inspect):', inspect(body, { depth: null }));
    }

    // Some clients (notably the callable emulator and some SDK versions)
    // wrap the payload under a `data` property (or rarely `payload`). Normalize
    // to a single `payload` object so we can accept both shapes.
    const normalized = (body && typeof body === 'object' && (body.data || body.payload))
      ? (body.data ?? body.payload)
      : body;

    // Accept either { token } or { activationToken } from clients
    const tokenRaw = (normalized?.token ?? normalized?.activationToken ?? '');
    const token = (typeof tokenRaw === 'string' ? tokenRaw : String(tokenRaw)).trim();
    const emailRaw = (normalized?.email ?? '');
    const email = (typeof emailRaw === 'string' ? emailRaw : String(emailRaw)).trim().toLowerCase();

    if (!token || !email) {
      console.warn('[validateActivationTokenCallable] Invalid request, missing token or email');
      throw new functionsV1.https.HttpsError('invalid-argument', 'Invalid request');
    }

    console.log(`[validateActivationTokenCallable] Received token validation request for email: ${email}`);

    // Query for a registration request that matches email, token and unused
    const q = await db
      .collection('registration_requests')
      .where('email', '==', email)
      .where('activationToken', '==', token)
      .where('activationTokenUsed', '==', false)
      .limit(1)
      .get();

    if (q.empty) {
      console.warn('[validateActivationTokenCallable] Token match not found for provided email');
      throw new functionsV1.https.HttpsError('permission-denied', 'Token invàlid o caducat.');
    }

    const doc = q.docs[0];
    const docRef = doc.ref;
    const dataDoc = doc.data() as any;

    const createdAt = dataDoc.activationTokenCreatedAt;
    if (!createdAt) {
      console.warn('[validateActivationTokenCallable] No token timestamp');
      throw new functionsV1.https.HttpsError('permission-denied', 'Token invàlid o caducat.');
    }

    const createdMs = (createdAt.toDate ? createdAt.toDate().getTime() : new Date(createdAt).getTime());
    const now = Date.now();
    const ttlMs = 48 * 60 * 60 * 1000; // 48 hours
    if (now - createdMs > ttlMs) {
      console.warn('[validateActivationTokenCallable] Token expired');
      throw new functionsV1.https.HttpsError('permission-denied', 'Token invàlid o caducat.');
    }

    // Atomically mark token used in a transaction (double-check fields to avoid race)
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(docRef);
      if (!snap.exists) {
        console.warn('[validateActivationTokenCallable] Document disappeared in transaction');
        throw new functionsV1.https.HttpsError('not-found', 'Token not found');
      }
      const cur = snap.data() as any;
      if ((cur.activationTokenUsed ?? false) === true) {
        console.warn('[validateActivationTokenCallable] Token already marked used');
        throw new functionsV1.https.HttpsError('permission-denied', 'Token invàlid o caducat.');
      }
      if ((cur.activationToken || '') !== token || (cur.email || '').toLowerCase() !== email) {
        console.warn('[validateActivationTokenCallable] Token/email mismatch in transaction');
        throw new functionsV1.https.HttpsError('permission-denied', 'Token invàlid o caducat.');
      }
      tx.update(docRef, {
        activationTokenUsed: true,
        activationTokenUsedAt: FieldValue.serverTimestamp(),
      });
    });

    console.log('[validateActivationTokenCallable] Token match found and marked used');

    return { success: true, message: 'Token valid. User may proceed.' };
  } catch (err) {
    console.error('[validateActivationTokenCallable] Error', err);
    if (err instanceof functionsV1.https.HttpsError) {
      throw err; // client receives proper callable error
    }
    throw new functionsV1.https.HttpsError('internal', 'Server error');
  }
});
