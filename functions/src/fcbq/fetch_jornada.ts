// ============================================================================
// fetchJornada - Cloud Function per obtenir dades d'una jornada
// ============================================================================
// Aquesta funció proporciona accés a les dades de jornades de la FCBQ
// amb un sistema de cache intel·ligent a Firestore.
// ============================================================================

import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {
  FetchJornadaRequest,
  JornadaResponse,
  DEFAULT_SCRAPER_CONFIG,
} from "./types";
import {scrapeJornada} from "./scraper";

const db = admin.firestore();

/**
 * Comprova si el cache és vàlid
 */
function isCacheValid(cachedData: JornadaResponse): boolean {
  if (!cachedData.cacheExpiresAt) return false;
  const expiresAt = new Date(cachedData.cacheExpiresAt).getTime();
  return Date.now() < expiresAt;
}

/**
 * Obté dades del cache de Firestore
 */
async function getFromCache(
  jornada: number,
  competitionId: string
): Promise<JornadaResponse | null> {
  try {
    const docRef = db
      .collection("jornades_cache")
      .doc(`${competitionId}_${jornada}`);
    const doc = await docRef.get();

    if (!doc.exists) {
      console.log(`[Cache] Miss: jornada ${jornada} no trobada al cache`);
      return null;
    }

    const data = doc.data() as JornadaResponse;

    if (!isCacheValid(data)) {
      console.log(`[Cache] Expired: jornada ${jornada} cache caducat`);
      return null;
    }

    console.log(`[Cache] Hit: jornada ${jornada} servida des del cache`);
    return {...data, source: "fcbq-cache"};
  } catch (error) {
    console.error("[Cache] Error llegint cache:", error);
    return null;
  }
}

/**
 * Guarda dades al cache de Firestore
 */
async function saveToCache(
  jornada: number,
  competitionId: string,
  data: JornadaResponse
): Promise<void> {
  try {
    const docRef = db
      .collection("jornades_cache")
      .doc(`${competitionId}_${jornada}`);

    await docRef.set(data);
    console.log(`[Cache] Saved: jornada ${jornada} guardada al cache`);
  } catch (error) {
    console.error("[Cache] Error guardant cache:", error);
    // No llancem error, el cache és opcional
  }
}

/**
 * Cloud Function principal per obtenir dades d'una jornada
 *
 * @param jornada - Número de jornada (1-30)
 * @param competitionId - ID de la competició (per defecte "19795")
 * @param forceRefresh - Si és true, ignora el cache
 */
export const fetchJornada = onCall(
  {
    region: "europe-west1",
    timeoutSeconds: 30,
    memory: "256MiB",
    maxInstances: 10,
  },
  async (request): Promise<JornadaResponse> => {
    const data = request.data as FetchJornadaRequest;

    // Validació de paràmetres
    const jornada = data.jornada;
    if (typeof jornada !== "number" || jornada < 1 || jornada > 30) {
      throw new HttpsError(
        "invalid-argument",
        "El paràmetre 'jornada' ha de ser un número entre 1 i 30"
      );
    }

    const competitionId = data.competitionId || DEFAULT_SCRAPER_CONFIG.competitionId;
    const forceRefresh = data.forceRefresh === true;

    console.log(
      `[fetchJornada] Petició: jornada=${jornada}, ` +
      `competition=${competitionId}, forceRefresh=${forceRefresh}`
    );

    // Intentem obtenir del cache si no es força refresh
    if (!forceRefresh) {
      const cached = await getFromCache(jornada, competitionId);
      if (cached) {
        return cached;
      }
    }

    // Fem scraping de la web de la FCBQ
    try {
      const config = {
        ...DEFAULT_SCRAPER_CONFIG,
        competitionId,
      };

      const {matches, standings} = await scrapeJornada(jornada, config);

      // Preparem la resposta
      const now = new Date();
      const expiresAt = new Date(
        now.getTime() + config.cacheTtlMinutes * 60 * 1000
      );

      const response: JornadaResponse = {
        jornada,
        competitionId,
        competitionName: "Super Copa Masculina", // Podria venir del scraping
        partits: matches,
        classificacio: standings,
        fetchedAt: now.toISOString(),
        source: "fcbq-live",
        cacheExpiresAt: expiresAt.toISOString(),
      };

      // Guardem al cache (async, no bloqueja la resposta)
      saveToCache(jornada, competitionId, response).catch((err) => {
        console.error("[fetchJornada] Error guardant cache:", err);
      });

      return response;
    } catch (error) {
      console.error("[fetchJornada] Error durant scraping:", error);

      // Si falla el scraping, intentem retornar dades del cache encara que siguin caducades
      try {
        const docRef = db
          .collection("jornades_cache")
          .doc(`${competitionId}_${jornada}`);
        const doc = await docRef.get();

        if (doc.exists) {
          const staleData = doc.data() as JornadaResponse;
          console.log("[fetchJornada] Retornant dades caducades del cache");
          return {...staleData, source: "fcbq-cache"};
        }
      } catch (cacheError) {
        console.error("[fetchJornada] Error llegint cache d'emergència:", cacheError);
      }

      throw new HttpsError(
        "unavailable",
        "No s'han pogut obtenir les dades de la jornada. " +
        "La web de la FCBQ pot estar temporalment inaccessible."
      );
    }
  }
);

/**
 * Cloud Function per obtenir múltiples jornades
 * Útil per carregar un rang de jornades o totes alhora
 */
export const fetchMultipleJornades = onCall(
  {
    region: "europe-west1",
    timeoutSeconds: 120,
    memory: "512MiB",
    maxInstances: 5,
  },
  async (request): Promise<{jornades: JornadaResponse[]; errors: string[]}> => {
    const data = request.data as {
      start: number;
      end: number;
      competitionId?: string;
      forceRefresh?: boolean;
    };

    const start = data.start || 1;
    const end = data.end || 30;
    const competitionId = data.competitionId || DEFAULT_SCRAPER_CONFIG.competitionId;
    const forceRefresh = data.forceRefresh === true;

    if (start < 1 || end > 30 || start > end) {
      throw new HttpsError(
        "invalid-argument",
        "Rang de jornades invàlid. Ha de ser entre 1 i 30."
      );
    }

    const jornades: JornadaResponse[] = [];
    const errors: string[] = [];

    // Processem les jornades seqüencialment per no sobrecarregar la FCBQ
    for (let j = start; j <= end; j++) {
      try {
        // Intentem cache primer
        if (!forceRefresh) {
          const cached = await getFromCache(j, competitionId);
          if (cached) {
            jornades.push(cached);
            continue;
          }
        }

        // Scraping
        const config = {...DEFAULT_SCRAPER_CONFIG, competitionId};
        const {matches, standings} = await scrapeJornada(j, config);

        const now = new Date();
        const expiresAt = new Date(
          now.getTime() + config.cacheTtlMinutes * 60 * 1000
        );

        const response: JornadaResponse = {
          jornada: j,
          competitionId,
          competitionName: "Super Copa Masculina",
          partits: matches,
          classificacio: standings,
          fetchedAt: now.toISOString(),
          source: "fcbq-live",
          cacheExpiresAt: expiresAt.toISOString(),
        };

        jornades.push(response);

        // Guardem al cache
        await saveToCache(j, competitionId, response);

        // Petit delay per no fer spam a la FCBQ
        await new Promise((resolve) => setTimeout(resolve, 500));
      } catch (error) {
        const errMsg = `Jornada ${j}: ${error instanceof Error ? error.message : "Error desconegut"}`;
        console.error(errMsg);
        errors.push(errMsg);
      }
    }

    return {jornades, errors};
  }
);

/**
 * Cloud Function per netejar el cache (admin only)
 */
export const clearJornadaCache = onCall(
  {
    region: "europe-west1",
  },
  async (request): Promise<{deleted: number}> => {
    // Només admins poden netejar el cache
    // TODO: Afegir verificació de rol admin quan estigui implementat

    const data = request.data as {
      jornada?: number;
      competitionId?: string;
    };

    const competitionId = data.competitionId || DEFAULT_SCRAPER_CONFIG.competitionId;

    if (data.jornada) {
      // Elimina una jornada específica
      const docRef = db
        .collection("jornades_cache")
        .doc(`${competitionId}_${data.jornada}`);
      await docRef.delete();
      return {deleted: 1};
    }

    // Elimina tot el cache de la competició
    const snapshot = await db
      .collection("jornades_cache")
      .where("competitionId", "==", competitionId)
      .get();

    const batch = db.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();

    return {deleted: snapshot.size};
  }
);
