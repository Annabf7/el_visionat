import {onCall, HttpsError} from "firebase-functions/v2/https";
import {getAuth} from "firebase-admin/auth";
import {Resend} from "resend";

/**
 * Cloud Function per enviar un correu de reset de contrasenya
 * Utilitza Firebase Auth per generar l'enllaç i Resend per enviar-lo
 */
export const sendPasswordResetEmail = onCall(
  {
    region: "europe-west1",
    secrets: ["RESEND_API_KEY"],
  },
  async (request) => {
    try {
      const body = request.data as any;
      console.log("[sendPasswordResetEmail] Request received:", JSON.stringify(body));

      // Normalitzar l'estructura del body (podria venir amb wrappers)
      const normalized = (body && typeof body === "object" && (body.data || body.payload)) ?
        (body.data ?? body.payload) :
        body;

      const emailRaw = (normalized?.email ?? "");
      const email = (typeof emailRaw === "string" ? emailRaw : String(emailRaw)).trim().toLowerCase();

      console.log(`[sendPasswordResetEmail] Processing for email: ${email}`);

      if (!email || !email.includes("@")) {
        throw new HttpsError("invalid-argument", "Correu electrònic no vàlid");
      }

      // Verificar que l'usuari existeix a Firebase Auth
      const auth = getAuth();
      let userExists = false;
      try {
        await auth.getUserByEmail(email);
        userExists = true;
      } catch (err: any) {
        if (err.code === "auth/user-not-found") {
          console.warn(`[sendPasswordResetEmail] User not found: ${email}`);
          // Per seguretat, no revelar si l'usuari existeix o no
          // Retornar èxit igualment per evitar enumeration attacks
          return {
            success: true,
            message: "Si el correu existeix, rebràs un enllaç per restablir la contrasenya.",
          };
        }
        throw err;
      }

      if (!userExists) {
        // Aquest cas no hauria de passar mai per el try-catch anterior
        // però ho deixem per seguretat
        return {
          success: true,
          message: "Si el correu existeix, rebràs un enllaç per restablir la contrasenya.",
        };
      }

      // Generar l'enllaç de reset de contrasenya de Firebase
      const resetLink = await auth.generatePasswordResetLink(email, {
        url: "https://el-visionat.web.app/", // URL on es redirigirà després del reset
        handleCodeInApp: false,
      });

      console.log(`[sendPasswordResetEmail] Reset link generated for ${email}`);

      // Enviar el correu amb Resend
      const resend = new Resend(process.env.RESEND_API_KEY as string);

      const html = `
      <!doctype html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
      </head>
      <body style="margin:0; padding:0; background-color:#2F313C; -webkit-font-smoothing:antialiased;">
        <table role="presentation" cellpadding="0" cellspacing="0" width="100%" style="background-color:#2F313C; padding:24px 16px;">
          <tr>
            <td align="center">
              <table role="presentation" cellpadding="0" cellspacing="0" width="100%" style="max-width:600px;">
                <!-- Header amb logo -->
                <tr>
                  <td style="text-align:center; padding:18px 0 6px 0;">
                    <img src="https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/elvisionat.png?alt=media&token=0408a81c-44f3-495f-bbe4-dd2dee09ae74" alt="El Visionat" width="172" style="display:block; height:auto; margin:0 auto; border:0; outline:none; text-decoration:none;"/>
                    <h1 style="margin:12px 0 4px 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial; color:#E8C547; font-size:26px;">El Visionat</h1>
                    <div style="color:#CDD1C4; font-size:13px;">Formació i inspiració arbitral</div>
                  </td>
                </tr>

                <!-- Contingut principal -->
                <tr>
                  <td>
                    <table role="presentation" cellpadding="0" cellspacing="0" width="100%" style="background:#4D5061; border-radius:12px; padding:24px;">
                      <tr>
                        <td style="color:#CDD1C4; font-size:15px;">
                          <p style="margin:0 0 12px 0;">Hola,</p>
                          <p style="margin:0 0 12px 0;">Hem rebut una sol·licitud per <strong style="color:#E8C547;">restablir la contrasenya</strong> del teu compte a <strong style="color:#FFFFFF;">El Visionat</strong> (${email}).</p>
                          <p style="margin:0 0 12px 0;">Per continuar amb el procés, fes clic al següent botó:</p>
                        </td>
                      </tr>

                      <!-- Botó d'acció -->
                      <tr>
                        <td style="padding-top:18px; text-align:center;">
                          <a href="${resetLink}" style="background:#E8C547; color:#2F313C; text-decoration:none; display:inline-block; padding:14px 28px; border-radius:8px; font-weight:700; font-size:15px;">Restablir contrasenya</a>
                        </td>
                      </tr>

                      <!-- Enllaç alternatiu -->
                      <tr>
                        <td style="padding-top:20px; color:#CDD1C4; font-size:13px;">
                          <p style="margin:0 0 8px 0;">Si el botó no funciona, copia i enganxa aquest enllaç al teu navegador:</p>
                          <div style="background:#2F313C; border-radius:6px; padding:10px; word-break:break-all; font-size:12px; color:#E8C547;">
                            ${resetLink}
                          </div>
                        </td>
                      </tr>

                      <!-- Avís de seguretat -->
                      <tr>
                        <td style="padding-top:20px; color:#CDD1C4; font-size:13px;">
                          <hr style="border:none; border-top:1px solid rgba(205,209,196,0.12); margin:18px 0;" />
                          <p style="margin:0; color:#CDD1C4;">
                            <strong style="color:#E8C547;">⚠️ Important:</strong> Si no has sol·licitat aquest canvi, pots ignorar aquest missatge amb total tranquil·litat. La teva contrasenya no canviarà a menys que accedeixis a l'enllaç i en creïs una de nova.
                          </p>
                          <p style="margin:12px 0 0 0; color:#CDD1C4; font-size:12px;">
                            Aquest enllaç caduca en 1 hora per motius de seguretat.
                          </p>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>

                <!-- Footer -->
                <tr>
                  <td style="padding-top:18px; text-align:center; color:#CDD1C4; font-size:12px;">
                    © ${new Date().getFullYear()} El Visionat — Plataforma d'anàlisi arbitral
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </body>
      </html>
      `;

      await resend.emails.send({
        from: "noreply@elvisionat.com",
        to: email,
        subject: "Restableix la teva contrasenya — El Visionat",
        html,
      });

      console.log(`[sendPasswordResetEmail] Email sent successfully to ${email}`);

      return {
        success: true,
        message: "S'ha enviat un correu amb les instruccions per restablir la contrasenya.",
      };
    } catch (err) {
      console.error("[sendPasswordResetEmail] Error:", err);

      if (err instanceof HttpsError) {
        throw err;
      }

      // Error genèric per no revelar detalls interns
      throw new HttpsError(
        "internal",
        "No s'ha pogut enviar el correu. Torna-ho a intentar més tard."
      );
    }
  }
);
