import {Resend} from "resend";

export interface WelcomeEmailArgs {
  email: string;
  nom: string;
  cognoms: string;
  llissenciaId: string;
  activationToken?: string;
}

export async function sendWelcomeEmail(args: WelcomeEmailArgs): Promise<void> {
  const {email, nom, cognoms, llissenciaId, activationToken} = args;

  const fullName = `${nom || ""} ${cognoms || ""}`.trim();

  const tokenSection = activationToken ?
    `
    <tr>
      <td style="padding-top:18px; text-align:center;">
        <table role="presentation" cellpadding="0" cellspacing="0" width="100%" style="max-width:520px; margin:0 auto;">
          <tr>
            <td style="color:#CDD1C4; font-size:14px; text-align:left; padding-bottom:8px;">Codi d'activació:</td>
          </tr>
          <tr>
            <td style="background:#2F313C; border-radius:8px; padding:16px; text-align:center;">
              <span style="color:#E8C547; font-size:20px; font-weight:700; letter-spacing:2px;">${activationToken}</span>
            </td>
          </tr>
          <tr>
            <td style="color:#CDD1C4; font-size:13px; text-align:left; padding-top:10px;">Introdueix aquest codi a l'aplicació El Visionat per completar el teu registre. El codi caduca en 48 hores.</td>
          </tr>
        </table>
      </td>
    </tr>
    ` :
    "";

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
            <tr>
              <td style="text-align:center; padding:18px 0 6px 0;">
                <img src="https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/elvisionat.png?alt=media&token=0408a81c-44f3-495f-bbe4-dd2dee09ae74"alt="El Visionat"width="172"style="display:block; height:auto; margin:0 auto; border:0; outline:none; text-decoration:none;"/>
                <h1 style="margin:12px 0 4px 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial; color:#E8C547; font-size:26px;">El Visionat</h1>
                <div style="color:#CDD1C4; font-size:13px;">Formació i inspiració arbitral</div>
              </td>
            </tr>

            <tr>
              <td>
                <table role="presentation" cellpadding="0" cellspacing="0" width="100%" style="background:#4D5061; border-radius:12px; padding:24px;">
                  <tr>
                    <td style="color:#CDD1C4; font-size:15px;">
                      <p style="margin:0 0 12px 0;">Benvingut/da, <strong style="color:#FFFFFF;">${fullName || ""}</strong>!</p>
                      <p style="margin:0 0 12px 0;">La teva sol·licitud a <strong style="color:#FFFFFF;">El Visionat</strong> ha estat <strong style="color:#E8C547;">aprovada</strong>. Ja formes part de la nostra comunitat.</p>
                    </td>
                  </tr>

                  ${activationToken ? "" : ""}

                  ${/* insert tokenSection as table rows */ ""}
                  ${activationToken ? tokenSection : ""}

                  <tr>
                    <td style="padding-top:18px; text-align:center;">
                      <a href="#" style="background:#E8C547; color:#2F313C; text-decoration:none; display:inline-block; padding:12px 22px; border-radius:8px; font-weight:700;">Accedeix a l'aplicació El Visionat</a>
                    </td>
                  </tr>

                  <tr>
                    <td style="padding-top:20px; color:#CDD1C4; font-size:13px;">
                      <hr style="border:none; border-top:1px solid rgba(205,209,196,0.12); margin:18px 0;" />
                      <div style="font-size:13px; color:#CDD1C4;">Detalls del registre:</div>
                      <div style="margin-top:8px; font-size:13px; color:#CDD1C4;"><strong>Llicència:</strong> ${llissenciaId}</div>
                      <div style="font-size:13px; color:#CDD1C4;"><strong>Correu associat:</strong> ${email}</div>
                      <p style="margin-top:12px; color:#CDD1C4; font-size:13px;">Gràcies per unir-te a <strong style="color:#FFFFFF;">El Visionat</strong> — seguim millorant junts.</p>
                    </td>
                  </tr>
                </table>
              </td>
            </tr>

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

  const resend = new Resend(process.env.RESEND_API_KEY as string);

  await resend.emails.send({
    from: "noreply@elvisionat.com",
    to: email,
    subject: "El teu registre ha estat aprovat — Benvingut a El Visionat",
    html,
  });
}
