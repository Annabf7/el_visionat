import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {sendWelcomeEmail} from "../email/send_welcome_email";

const db = getFirestore();

export const onRegistrationStatusUpdate = onDocumentUpdated(
  {document: "registration_requests/{id}", secrets: ["RESEND_API_KEY"]},
  async (event) => {
    // event.data is a Change<QueryDocumentSnapshot>
    const change = event.data;
    if (!change) {
      console.log("[onRegistrationStatusUpdate] No change data, skipping.");
      return;
    }

    const beforeSnap = change.before;
    const afterSnap = change.after;
    if (!beforeSnap || !afterSnap) {
      console.log("[onRegistrationStatusUpdate] Missing before/after snapshots, skipping.");
      return;
    }

    const beforeData = beforeSnap.data();
    const afterData = afterSnap.data();

    const prevStatus = beforeData?.status;
    const newStatus = afterData?.status;

    console.log(`[onRegistrationStatusUpdate] doc=${event.params.id} status ${prevStatus} -> ${newStatus}`);

    if (prevStatus !== "pending" || newStatus !== "approved") {
      // Not the transition we care about
      return;
    }

    const docRef = db.collection("registration_requests").doc(String(event.params.id));

    // Use transaction to mark welcomeEmailSent and to store activation token to avoid duplicate sends
    let captured: any = null;

    // Generate a secure alphanumeric token (8-10 uppercase chars)
    const generateToken = (len = 8) => {
      const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
      const bytes = require("crypto").randomBytes(len);
      let out = "";
      for (let i = 0; i < bytes.length; i++) {
        out += chars[bytes[i] % chars.length];
      }
      return out;
    };

    // Ensure token uniqueness (try up to 5 times)
    let activationToken: string | null = null;
    for (let attempt = 0; attempt < 5; attempt++) {
      const candidate = generateToken(8 + (attempt % 3));
      const existing = await db.collection("registration_requests").where("activationToken", "==", candidate).limit(1).get();
      if (existing.empty) {
        activationToken = candidate;
        break;
      }
    }
    if (!activationToken) {
      // fallback to a random longer token
      activationToken = generateToken(10);
    }

    await db.runTransaction(async (tx) => {
      const snap = await tx.get(docRef);
      if (!snap.exists) {
        console.warn("[onRegistrationStatusUpdate] Document disappeared, aborting.");
        return;
      }
      const data = snap.data() as any;

      // If already marked, skip
      if (data?.welcomeEmailSent) {
        console.log("[onRegistrationStatusUpdate] welcomeEmailSent already true, skipping send.");
        return;
      }

      // Ensure status is still approved
      if (data.status !== "approved") {
        console.log("[onRegistrationStatusUpdate] status changed since event, skipping.");
        return;
      }

      // Capture fields for sending after commit
      captured = {
        email: data.email,
        nom: data.nom,
        cognoms: data.cognoms,
        llissenciaId: data.llissenciaId,
      };

      // Mark as sent and attach activation token atomically
      tx.update(docRef, {
        welcomeEmailSent: true,
        welcomeEmailSentAt: FieldValue.serverTimestamp(),
        activationToken: activationToken,
        activationTokenUsed: false,
        activationTokenCreatedAt: FieldValue.serverTimestamp(),
      });
    });

    if (!captured) {
      console.log("[onRegistrationStatusUpdate] No captured data (already sent or aborted), returning.");
      return;
    }

    try {
      await sendWelcomeEmail({
        email: captured!.email,
        nom: captured!.nom,
        cognoms: captured!.cognoms,
        llissenciaId: captured!.llissenciaId,
        activationToken: activationToken || undefined,
      });
      console.log("[onRegistrationStatusUpdate] Welcome email sent to", captured!.email);
    } catch (err) {
      console.error("[onRegistrationStatusUpdate] Failed to send welcome email", err);
      // We opted to mark the doc as sent before sending to prevent duplicates. If desired,
      // we could implement a retry mechanism here (e.g., push to a retry queue).
    }

    return;
  }
);
