import { onRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

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

    console.log('[validateActivationToken] Received validation request for token');

    // Find the registration request that contains this token
    const q = await db.collection('registration_requests').where('activationToken', '==', token).limit(1).get();
    if (q.empty) {
      console.warn('[validateActivationToken] Token not found');
      res.status(404).json({ success: false, message: 'Invalid token or email' });
      return;
    }

    const doc = q.docs[0];
    const docRef = doc.ref;
    const data = doc.data() as any;

    // Basic checks
    if ((data.activationTokenUsed ?? false) === true) {
      console.warn('[validateActivationToken] Token already used');
      res.status(409).json({ success: false, message: 'Token already used' });
      return;
    }

    if ((data.email || '').toLowerCase() !== email) {
      console.warn('[validateActivationToken] Email mismatch');
      res.status(400).json({ success: false, message: 'Invalid token or email' });
      return;
    }

    const createdAt = data.activationTokenCreatedAt;
    if (!createdAt) {
      console.warn('[validateActivationToken] No token timestamp');
      res.status(400).json({ success: false, message: 'Invalid token' });
      return;
    }

    const createdMs = (createdAt.toDate ? createdAt.toDate().getTime() : new Date(createdAt).getTime());
    const now = Date.now();
    const ageMs = now - createdMs;
    const ttlMs = 48 * 60 * 60 * 1000; // 48 hours
    if (ageMs > ttlMs) {
      console.warn('[validateActivationToken] Token expired');
      res.status(410).json({ success: false, message: 'Token expired' });
      return;
    }

    // Atomically mark token used in a transaction
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(docRef);
      const cur = snap.data() as any;
      if (!snap.exists) {
        throw new Error('NotFound');
      }
      if ((cur.activationTokenUsed ?? false) === true) {
        throw new Error('AlreadyUsed');
      }
      tx.update(docRef, {
        activationTokenUsed: true,
        activationTokenUsedAt: FieldValue.serverTimestamp(),
      });
    });

    // Create Firebase Auth user (idempotent)
    let userRecord;
    try {
      userRecord = await admin.auth().createUser({ email, emailVerified: false });
      console.log('[validateActivationToken] Created new user', userRecord.uid);
    } catch (err: any) {
      if (err.code === 'auth/email-already-exists' || err.code === 'auth/email-already-in-use') {
        console.log('[validateActivationToken] User already exists, continuing');
      } else {
        console.error('[validateActivationToken] Failed to create user', err);
        // We will not revert the token used flag; return generic error
        res.status(500).json({ success: false, message: 'Server error' });
        return;
      }
    }

    // Generate password reset / set password link
    let link: string;
    try {
      link = await admin.auth().generatePasswordResetLink(email);
    } catch (err) {
      console.error('[validateActivationToken] Failed to generate password link', err);
      res.status(500).json({ success: false, message: 'Server error' });
      return;
    }

    res.status(200).json({ success: true, setPasswordLink: link });
    return;
  } catch (err) {
    console.error('[validateActivationToken] Unexpected error', err);
    try {
      res.status(500).json({ success: false, message: 'Server error' });
    } catch (_) {}
    return;
  }
});
