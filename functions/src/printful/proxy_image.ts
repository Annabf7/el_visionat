// ============================================================================
// Proxy d'imatges de Printful - Soluciona CORS per a Flutter web
// ============================================================================
// El CDN de Printful (files.cdn.printful.com) no envia capçaleres CORS,
// cosa que impedeix que Flutter web carregui les imatges directament.
// Aquesta funció HTTP actua com a proxy: descarrega la imatge del CDN
// i la retorna amb les capçaleres CORS necessàries + cache llarg.
// ============================================================================

import {onRequest} from "firebase-functions/v2/https";

export const proxyPrintfulImage = onRequest(
  {
    region: "europe-west1",
    memory: "256MiB",
    timeoutSeconds: 30,
    cors: true,
  },
  async (req, res) => {
    const imageUrl = req.query.url as string;

    // Validar que la URL sigui del CDN de Printful (seguretat)
    if (!imageUrl?.startsWith("https://files.cdn.printful.com/")) {
      res.status(400).send("URL no vàlida: només URLs de Printful CDN");
      return;
    }

    try {
      const response = await fetch(imageUrl);

      if (!response.ok) {
        console.error("Error descarregant imatge de Printful:", {
          status: response.status,
          url: imageUrl,
        });
        res.status(response.status).send("Error obtenint la imatge");
        return;
      }

      const buffer = Buffer.from(await response.arrayBuffer());
      const contentType = response.headers.get("content-type") || "image/png";

      res.set("Content-Type", contentType);
      res.set("Cache-Control", "public, max-age=604800, s-maxage=604800"); // 7 dies
      res.set("Access-Control-Allow-Origin", "*");
      res.send(buffer);
    } catch (error) {
      console.error("Error al proxy d'imatge:", error);
      res.status(500).send("Error intern del proxy");
    }
  }
);
