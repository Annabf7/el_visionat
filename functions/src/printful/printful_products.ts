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
  CatalogProductDetail,
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

      // --- Enriquiment amb dades del catàleg (color, talla, color_code) ---
      const activeVariants = data.result.sync_variants.filter(
        (v: SyncVariant) => !v.is_ignored
      );
      const catalogProductId = activeVariants.length > 0 ?
        activeVariants[0].product.product_id :
        null;

      // Lookup: catalogVariantId → { color, size, color_code }
      const catalogLookup: Record<
        number,
        { color: string; size: string; color_code: string }
      > = {};

      if (catalogProductId) {
        try {
          const catalogRes = await fetch(
            `${PRINTFUL_BASE_URL}/products/${catalogProductId}`,
            {
              method: "GET",
              headers: {
                "Authorization": `Bearer ${printfulApiKey.value()}`,
                "Content-Type": "application/json",
              },
            }
          );
          if (catalogRes.ok) {
            const catalogData = await catalogRes.json() as
              PrintfulResponse<CatalogProductDetail>;
            for (const cv of catalogData.result.variants) {
              catalogLookup[cv.id] = {
                color: cv.color,
                size: cv.size,
                color_code: cv.color_code,
              };
            }
            console.log(
              `[Printful] Catàleg enriquit: ${Object.keys(catalogLookup).length} variants`
            );
          }
        } catch (err) {
          console.warn("[Printful] Error obtenint catàleg (degradació elegant):", err);
        }
      }

      // Enriquir cada variant amb color/size/color_code + bestPreviewUrl
      const enrichedVariants = data.result.sync_variants.map((v) => {
        const catalog = catalogLookup[v.variant_id];
        const previewFile = v.files.find((f) => f.type === "preview");
        const bestPreviewUrl =
          previewFile?.preview_url ?? previewFile?.url ?? null;

        const base = catalog ? {
          ...v,
          product: {
            ...v.product,
            color: catalog.color,
            size: catalog.size,
            color_code: catalog.color_code,
          },
        } : v;

        return {...base, bestPreviewUrl};
      });

      const sp = data.result.sync_product;
      console.log(
        `[Printful] Producte "${sp.name}" → ` +
        `${enrichedVariants.length} variants, ` +
        `${Object.keys(catalogLookup).length} enriquits amb catàleg`
      );

      return {
        product: data.result.sync_product,
        variants: enrichedVariants,
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
