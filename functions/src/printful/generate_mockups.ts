// ============================================================================
// Printful - Generador de Mockups per color
// ============================================================================
// Utilitza l'API Mockup Generator de Printful per generar imatges de producte
// per a cada color. Les imatges es guarden a Firebase Storage (URLs permanents)
// i es cachegen a Firestore per evitar regeneracions innecessàries.
// ============================================================================

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import * as admin from "firebase-admin";
import {randomUUID} from "crypto";
import {PrintfulResponse, SyncProductDetail, SyncVariant} from "./types";

const printfulApiKey = defineSecret("PRINTFUL_API_KEY");
const PRINTFUL_BASE_URL = "https://api.printful.com";
const MOCKUPS_COLLECTION = "product_mockups";
const CACHE_MAX_AGE_MS = 30 * 24 * 60 * 60 * 1000; // 30 dies

// ===== Tipus locals per a l'API de Mockup Generator =====

interface PrintfilesResult {
  product_id: number;
  available_placements: Record<string, {
    title: string;
    width: number;
    height: number;
  }>;
  printfiles: Array<{
    printfile_id: number;
    width: number;
    height: number;
    dpi: number;
    fill_mode: string;
    can_rotate: boolean;
  }>;
  variant_printfiles: Array<{
    variant_id: number;
    placements: Record<string, { printfile_id: number }>;
  }>;
}

interface MockupTaskCreated {
  task_key: string;
  status: string;
}

interface MockupTaskResult {
  task_key: string;
  status: string;
  mockups: Array<{
    placement: string;
    variant_ids: number[];
    mockup_url: string;
    extra: Array<{
      title: string;
      url: string;
      option: string;
      option_group: string;
    }>;
  }>;
}

interface MockupCacheDoc {
  generatedAt: admin.firestore.Timestamp;
  /** Mapa catalogVariantId → Firebase Storage download URL */
  mockups: Record<string, string>;
}

// ===== Helpers =====

async function pfGet<T>(path: string, apiKey: string): Promise<T> {
  const res = await fetch(`${PRINTFUL_BASE_URL}${path}`, {
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Printful GET ${path}: ${res.status} - ${text}`);
  }
  return (await res.json()) as T;
}

async function pfPost<T>(
  path: string,
  body: unknown,
  apiKey: string
): Promise<T> {
  const res = await fetch(`${PRINTFUL_BASE_URL}${path}`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Printful POST ${path}: ${res.status} - ${text}`);
  }
  return (await res.json()) as T;
}

const sleep = (ms: number) => new Promise<void>((r) => setTimeout(r, ms));

/**
 * Puja un buffer d'imatge a Firebase Storage i retorna la URL de descàrrega.
 * Usa un download token per accés directe sense autenticació.
 */
async function uploadMockupToStorage(
  imageBuffer: Buffer,
  storagePath: string,
  contentType: string
): Promise<string> {
  const bucket = admin.storage().bucket();
  const file = bucket.file(storagePath);
  const token = randomUUID();

  await file.save(imageBuffer, {
    metadata: {
      contentType,
      metadata: {firebaseStorageDownloadTokens: token},
    },
  });

  const encodedPath = encodeURIComponent(storagePath);
  return `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodedPath}?alt=media&token=${token}`;
}

// ===== Cloud Function =====

/**
 * Genera mockups per a cada color d'un producte Printful.
 *
 * Flux:
 * 1. Comprova cache a Firestore (30 dies TTL)
 * 2. Obté detalls del sync product + placements disponibles
 * 3. Crea tasca de generació al Mockup Generator de Printful
 * 4. Poll fins que estigui completada
 * 5. Descarrega imatges i les puja a Firebase Storage
 * 6. Cacheja el mapping variant_id → Storage URL a Firestore
 *
 * Retorna: { mockups: { [catalogVariantId]: storageUrl } }
 */
export const getPrintfulProductMockups = onCall(
  {
    region: "europe-west1",
    secrets: [printfulApiKey],
    timeoutSeconds: 120,
    memory: "512MiB",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Cal estar autenticat");
    }

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const syncProductId = (request.data as any)?.productId;
    if (!syncProductId) {
      throw new HttpsError("invalid-argument", "El productId és obligatori");
    }

    const db = admin.firestore();
    const apiKey = printfulApiKey.value();

    // 1. Comprovar cache
    const cacheRef = db
      .collection(MOCKUPS_COLLECTION)
      .doc(String(syncProductId));
    const cacheDoc = await cacheRef.get();

    if (cacheDoc.exists) {
      const cache = cacheDoc.data() as MockupCacheDoc;
      const age = Date.now() - cache.generatedAt.toMillis();
      if (age < CACHE_MAX_AGE_MS) {
        console.log(`[Mockups] Cache hit: producte ${syncProductId}`);
        return {mockups: cache.mockups};
      }
    }

    try {
      // 2. Obtenir detalls del sync product
      const prodData = await pfGet<PrintfulResponse<SyncProductDetail>>(
        `/store/products/${syncProductId}`,
        apiKey
      );
      const variants = prodData.result.sync_variants.filter(
        (v: SyncVariant) => !v.is_ignored
      );
      if (variants.length === 0) return {mockups: {}};

      const catalogProductId = variants[0].product.product_id;

      // 3. Obtenir placements disponibles del producte
      const pfData = await pfGet<PrintfulResponse<PrintfilesResult>>(
        `/mockup-generator/printfiles/${catalogProductId}`,
        apiKey
      );
      const placements = Object.keys(pfData.result.available_placements);
      if (placements.length === 0) {
        console.warn(
          `[Mockups] Sense placements: producte catàleg ${catalogProductId}`
        );
        return {mockups: {}};
      }

      // 4. Preparar fitxers de disseny per al mockup generator
      // L'API del sync product pot retornar url: null per als fitxers de disseny.
      // En aquest cas, obtenim la URL via GET /files/{id}.
      // El type del fitxer (ex: "front_dtf_hat") no coincideix amb els
      // placements del generator (ex: "embroidery_front_large"), així que
      // assignem cada fitxer de disseny al primer placement disponible.
      const designFiles: Array<{placement: string; image_url: string}> = [];
      const usedPlacements = new Set<string>();

      for (const file of variants[0].files) {
        if (file.type === "preview") continue;

        // Obtenir URL: directa o via Files API
        let fileUrl = file.url;
        if (!fileUrl) {
          try {
            const fileData = await pfGet<PrintfulResponse<{url: string}>>(
              `/files/${file.id}`,
              apiKey
            );
            fileUrl = fileData.result.url;
          } catch (err) {
            console.warn(
              `[Mockups] No s'ha pogut obtenir URL del fitxer ${file.id}:`,
              err
            );
          }
        }
        if (!fileUrl) continue;

        // Assignar al primer placement no utilitzat
        const placement = placements.find((p) => !usedPlacements.has(p));
        if (placement) {
          usedPlacements.add(placement);
          designFiles.push({placement, image_url: fileUrl});
          console.log(
            `[Mockups] Fitxer ${file.id} (${file.type}) → placement ${placement}`
          );
        }
      }

      if (designFiles.length === 0) {
        console.warn(
          `[Mockups] Sense fitxers de disseny: producte ${syncProductId}`
        );
        return {mockups: {}};
      }

      // 5. Tots els catalog variant IDs (el generator agrupa per color)
      const catalogVariantIds = variants.map(
        (v: SyncVariant) => v.variant_id
      );

      console.log(
        `[Mockups] Generant: ${catalogVariantIds.length} variants, ` +
        `producte catàleg ${catalogProductId}, ` +
        `placements: ${placements.join(", ")}`
      );

      // 6. Crear tasca de generació
      const taskRes = await pfPost<PrintfulResponse<MockupTaskCreated>>(
        `/mockup-generator/create-task/${catalogProductId}`,
        {
          variant_ids: catalogVariantIds,
          format: "png",
          files: designFiles,
        },
        apiKey
      );
      const taskKey = taskRes.result.task_key;
      console.log(`[Mockups] Tasca creada: ${taskKey}`);

      // 7. Poll fins completat (cada 3s, màx 30 intents = ~90s)
      let result: MockupTaskResult | null = null;
      for (let i = 0; i < 30; i++) {
        await sleep(3000);
        const poll = await pfGet<PrintfulResponse<MockupTaskResult>>(
          `/mockup-generator/task?task_key=${taskKey}`,
          apiKey
        );
        if (poll.result.status === "completed") {
          result = poll.result;
          break;
        }
        if (poll.result.status === "failed") {
          console.error(`[Mockups] Tasca fallida: ${taskKey}`);
          throw new Error("La generació de mockups ha fallat");
        }
      }

      if (!result) {
        throw new Error("Timeout esperant la generació de mockups");
      }

      console.log(
        `[Mockups] Tasca completada: ${result.mockups.length} mockups generats`
      );

      // 8. Descarregar cada mockup i pujar a Firebase Storage
      const mockups: Record<string, string> = {};

      for (const m of result.mockups) {
        try {
          const imgRes = await fetch(m.mockup_url);
          if (!imgRes.ok) {
            console.warn(
              `[Mockups] Error descarregant: ${imgRes.status} - ${m.mockup_url}`
            );
            continue;
          }
          const imgBuffer = Buffer.from(await imgRes.arrayBuffer());
          const contentType =
            imgRes.headers.get("content-type") || "image/png";

          // Un fitxer per grup de variants (mateix visual/color)
          const representativeId = m.variant_ids[0];
          const storagePath =
            `mockups/${syncProductId}/${representativeId}.png`;
          const storageUrl = await uploadMockupToStorage(
            imgBuffer,
            storagePath,
            contentType
          );

          // Assignar mateixa URL a tots els variants del grup
          for (const vid of m.variant_ids) {
            mockups[String(vid)] = storageUrl;
          }
        } catch (err) {
          console.warn("[Mockups] Error processant mockup:", err);
        }
      }

      // 9. Guardar a cache Firestore
      await cacheRef.set({
        generatedAt: admin.firestore.Timestamp.now(),
        mockups,
      } as MockupCacheDoc);

      console.log(
        `[Mockups] Completat: ${Object.keys(mockups).length} ` +
        `URLs guardades per producte ${syncProductId}`
      );
      return {mockups};
    } catch (error) {
      console.error(`[Mockups] Error producte ${syncProductId}:`, error);
      if (error instanceof HttpsError) throw error;
      throw new HttpsError(
        "internal",
        "Error generant els mockups del producte"
      );
    }
  }
);
