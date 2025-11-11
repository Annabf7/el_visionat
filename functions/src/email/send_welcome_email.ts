import { Resend } from 'resend';

export interface WelcomeEmailArgs {
  email: string;
  nom: string;
  cognoms: string;
  llissenciaId: string;
  activationToken?: string;
}

export async function sendWelcomeEmail(args: WelcomeEmailArgs): Promise<void> {
  const { email, nom, cognoms, llissenciaId, activationToken } = args;

  const fullName = `${nom || ''} ${cognoms || ''}`.trim();

  const tokenSection = activationToken
    ? `<p style="font-size:16px; font-weight:600;">Codi d'activació: <span style="background:#f3f4f6;padding:6px 10px;border-radius:6px;letter-spacing:2px;">${activationToken}</span></p>
       <p>Introdueix aquest codi d'activació a l'aplicació El Visionat per completar el teu registre. El codi caduca en 48 hores.</p>`
    : '';

  const html = `
  <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial; color: #111; line-height:1.5;">
    <table width="100%" cellpadding="0" cellspacing="0" role="presentation">
      <tr>
        <td style="padding:24px; text-align:center;">
          <h1 style="margin:0; color:#2b6cb0;">El Visionat</h1>
        </td>
      </tr>
      <tr>
        <td style="background:#ffffff; padding:24px; border-radius:8px;">
          <p>Hola <strong>${fullName || 'amic/ga'}</strong>,</p>
          <p>Gràcies per registrar-te a <strong>El Visionat</strong>. La teva sol·licitud ha estat <strong>aprovada</strong> i el teu compte ja és actiu.</p>
          <p style="margin-top:16px;">Ara ja pots iniciar sessió a l'aplicació i començar a fer servir les funcionalitats disponibles per a àrbitres i usuaris.</p>
          <p style="font-style:italic; color:#555;">Et recomanem que ingressis a l'app i revisis el teu perfil per completar qualsevol dada que en faltés.</p>

          ${tokenSection}

          <div style="margin-top:20px; text-align:center;">
            <a href="#" style="display:inline-block; padding:12px 20px; background:#2b6cb0; color:#fff; text-decoration:none; border-radius:6px;">Ja pots iniciar sessió a l'aplicació El Visionat</a>
          </div>

          <hr style="margin:24px 0; border:none; border-top:1px solid #eee;" />
          <p style="font-size:13px; color:#666;">Detalls de la sol·licitud:</p>
          <ul style="font-size:13px; color:#666;">
            <li><strong>Llicència:</strong> ${llissenciaId}</li>
            <li><strong>Correu associat:</strong> ${email}</li>
          </ul>

          <p style="font-size:13px; color:#666; margin-top:8px;">Gràcies per unir-te a la comunitat d'El Visionat — seguim millorant junts.</p>
        </td>
      </tr>
      <tr>
        <td style="padding:12px; text-align:center; color:#999; font-size:12px;">
          © ${new Date().getFullYear()} El Visionat
        </td>
      </tr>
    </table>
  </div>
  `;

  const resend = new Resend(process.env.RESEND_API_KEY as string);

  await resend.emails.send({
    from: 'noreply@elvisionat.com',
    to: email,
    subject: 'El teu registre ha estat aprovat — Benvingut a El Visionat',
    html,
  });
}
