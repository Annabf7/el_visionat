// ============================================================================
// Printful - Cloud Functions per obtenir productes de la botiga
// ============================================================================
// Funcions callable que fan de proxy entre l'app Flutter i l'API de Printful.
// El token d'API es guarda com a Firebase Secret (mai exposat al client).
// ============================================================================

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import {
  PrintfulResponse,
  SyncProduct,
  SyncProductDetail,
  SyncVariant,
} from "./types";

// Secret per la API key de Printful
const printfulApiKey = defineSecret("PRINTFUL_API_KEY");

const PRINTFUL_BASE_URL = "https://api.printful.com";

/**
 * Cloud Function per obtenir la llista de productes sincronitzats de la botiga.
 *
 * Paràmetres opcionals (via request.data):
 *   - offset: number (defecte 0)
 *   - limit: number (defecte 20, màx 100)
 *
 * Retorna: { products: SyncProduct[], paging: { total, offset, limit } }
 */
export const getPrintfulProducts = onCall(
  {
    region: "europe-west1",
    secrets: [printfulApiKey],
    timeoutSeconds: 30,
    memory: "256MiB",
  },
  async (request) => {
    // Verificar autenticació
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Cal estar autenticat per accedir a la botiga"
      );
    }

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const body = request.data as any;
    const offset = Math.max(0, body?.offset ?? 0);
    const limit = Math.min(100, Math.max(1, body?.limit ?? 20));

    try {
      const url = new URL(`${PRINTFUL_BASE_URL}/store/products`);
      url.searchParams.append("offset", String(offset));
      url.searchParams.append("limit", String(limit));

      const response = await fetch(url.toString(), {
        method: "GET",
        headers: {
          "Authorization": `Bearer ${printfulApiKey.value()}`,
          "Content-Type": "application/json",
        },
      });

      if (!response.ok) {
        console.error("Printful API error:", {
          status: response.status,
          statusText: response.statusText,
        });
        throw new HttpsError(
          "internal",
          `Error de l'API Printful: ${response.status}`
        );
      }

      const data = await response.json() as PrintfulResponse<SyncProduct[]>;

      // Enriquir cada producte amb la millor imatge de variant disponible.
      // L'endpoint de llista només retorna thumbnail_url genèric; en canvi,
      // el detall de cada producte té previews i imatges de catàleg per variant.
      const enriched = await Promise.all(
        data.result.map(async (product) => {
          try {
            const detailRes = await fetch(
              `${PRINTFUL_BASE_URL}/store/products/${product.id}`,
              {
                method: "GET",
                headers: {
                  "Authorization": `Bearer ${printfulApiKey.value()}`,
                  "Content-Type": "application/json",
                },
              }
            );
            if (!detailRes.ok) return product;

            const detail = await detailRes.json() as
              PrintfulResponse<SyncProductDetail>;
            const variants = detail.result.sync_variants.filter(
              (v: SyncVariant) => !v.is_ignored
            );
            if (variants.length === 0) return product;

            const first = variants[0];

            // Prioritat: preview file → design file preview → catàleg
            const previewFile = first.files.find((f) => f.type === "preview");
            const bestPreview = previewFile?.preview_url ?? previewFile?.url;
            if (bestPreview) {
              product.thumbnail_url = bestPreview;
              return product;
            }

            const designFile = first.files.find(
              (f) => f.type !== "preview" && f.preview_url
            );
            if (designFile?.preview_url) {
              product.thumbnail_url = designFile.preview_url;
              return product;
            }

            if (first.product?.image) {
              product.thumbnail_url = first.product.image;
            }
          } catch (err) {
            console.warn(
              `[Printful] Error enriquint producte ${product.id}:`, err
            );
          }
          return product;
        })
      );

      for (const p of enriched) {
        console.log(
          `[Printful] Producte "${p.name}" (id: ${p.id}) → ` +
          `thumbnail_url: ${p.thumbnail_url ?? "NULL"}`
        );
      }

      return {
        products: enriched,
        paging: data.paging ?? {total: 0, offset, limit},
      };
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      console.error("Error obtenint productes Printful:", error);
      throw new HttpsError(
        "internal",
        "Error obtenint els productes de la botiga"
      );
    }
  }
);

/**
 * Cloud Function per obtenir els detalls d'un producte amb els seus variants.
 *
 * Paràmetres (via request.data):
 *   - productId: number (obligatori) - ID del Sync Product
 *
 * Retorna: { product: SyncProduct, variants: SyncVariant[] }
 */
export const getPrintfulProduct = onCall(
  {
    region: "europe-west1",
    secrets: [printfulApiKey],
    timeoutSeconds: 30,
    memory: "256MiB",
  },
  async (request) => {
    // Verificar autenticació
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Cal estar autenticat per accedir a la botiga"
      );
    }

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const body = request.data as any;
    const productId = body?.productId;

    if (!productId) {
      throw new HttpsError(
        "invalid-argument",
        "El productId és obligatori"
      );
    }

    try {
      const url = `${PRINTFUL_BASE_URL}/store/products/${productId}`;

      const response = await fetch(url, {
        method: "GET",
        headers: {
          "Authorization": `Bearer ${printfulApiKey.value()}`,
          "Content-Type": "application/json",
        },
      });

      if (!response.ok) {
        if (response.status === 404) {
          throw new HttpsError(
            "not-found",
            "Producte no trobat"
          );
        }
        console.error("Printful API error:", {
          status: response.status,
          statusText: response.statusText,
        });
        throw new HttpsError(
          "internal",
          `Error de l'API Printful: ${response.status}`
        );
      }

      const data = await response.json() as PrintfulResponse<SyncProductDetail>;

      // Debug: log detalls del producte i variants
      const sp = data.result.sync_product;
      console.log(`[Printful DEBUG] Producte "${sp.name}" → thumbnail_url: ${sp.thumbnail_url ?? "NULL"}`);
      for (const v of data.result.sync_variants) {
        console.log(`[Printful DEBUG] Variant "${v.name}" → files: ${JSON.stringify(v.files.map((f) => ({type: f.type, preview_url: f.preview_url, thumbnail_url: f.thumbnail_url, url: f.url})))}`);
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const raw = v as any;
        if (raw.thumbnail_url || raw.preview_url) {
          console.log(`[Printful DEBUG] Variant-level images → thumbnail_url: ${raw.thumbnail_url}, preview_url: ${raw.preview_url}`);
        }
      }

      return {
        product: data.result.sync_product,
        variants: data.result.sync_variants,
      };
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      console.error("Error obtenint producte Printful:", error);
      throw new HttpsError(
        "internal",
        "Error obtenint els detalls del producte"
      );
    }
  }
);
