// functions/src/email/send_registration_notification.ts
import {Resend} from "resend";

export interface SendRegistrationNotificationArgs {
  llissenciaId: string;
  email: string;
  nom: string;
  cognoms: string;
  requestId: string;
  createdAt?: any;
}

export async function sendRegistrationNotification(args: SendRegistrationNotificationArgs) {
  const resend = new Resend(process.env.RESEND_API_KEY as string);

  const {llissenciaId, email, nom, cognoms, requestId, createdAt} = args;

  const createdAtStr =
    createdAt && typeof createdAt.toDate === "function" ?
      createdAt.toDate().toISOString() :
      createdAt ?
        String(createdAt) :
        "N/A";

  const html = `
    <h2>Nova sol·licitud de registre</h2>
    <p>Hi ha una nova sol·licitud de registre al sistema El Visionat.</p>
    <ul>
      <li><strong>Llicència:</strong> ${llissenciaId}</li>
      <li><strong>Email introduït:</strong> ${email}</li>
      <li><strong>Nom i cognoms:</strong> ${nom} ${cognoms}</li>
      <li><strong>ID de la sol·licitud:</strong> ${requestId}</li>
      <li><strong>Timestamp de creació:</strong> ${createdAtStr}</li>
      <li><strong>Firestore path:</strong> registration_requests/${requestId}</li>
    </ul>
  `;

  try {
    await resend.emails.send({
      from: "noreply@elvisionat.com",
      to: "info@elvisionat.com", // 📌 email intern del Visionat
      subject: "Nova sol·licitud de registre",
      html,
    });

    console.log("[sendRegistrationNotification] Email sent for request", requestId);
  } catch (err) {
    console.error("[sendRegistrationNotification] Failed to send notification", err);
    throw err;
  }
}
