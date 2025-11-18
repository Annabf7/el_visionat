// functions/src/email/send_registration_notification_http.ts
import {onRequest} from "firebase-functions/v2/https";
import {Resend} from "resend";

export const sendRegistrationNotificationHttp = onRequest(
  {secrets: ["RESEND_API_KEY"]},
  async (req, res) => {
    console.log("[sendRegistrationNotificationHttp] Invoked");

    if (req.method !== "POST") {
      res.status(405).json({error: "Only POST is allowed"});
      return;
    }

    const {email} = req.body;

    if (!email) {
      res.status(400).json({error: "Missing 'email' in body"});
      return;
    }

    try {
      const resend = new Resend(process.env.RESEND_API_KEY);

      await resend.emails.send({
        from: "noreply@elvisionat.com",
        to: email,
        subject: "Test — Email enviat correctament",
        html: "<p>Això és una prova del Visionat! 🚀</p>",
      });

      console.log("[sendRegistrationNotificationHttp] Email sent to:", email);

      res.status(200).json({success: true, sentTo: email});
      return;
    } catch (err) {
      console.error("[sendRegistrationNotificationHttp] Failed:", err);
      res.status(500).json({error: "Email send failed"});
      return;
    }
  }
);
