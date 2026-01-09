// ============================================================================
// Cloud Function: Notificar àrbitres quan una jugada arriba a 10 reaccions
// ============================================================================
// Trigger: Quan s'actualitza un highlight i arriba al threshold
// Accions:
// 1. Detecta si ha arribat a 10 reaccions
// 2. Obté àrbitres de màxima categoria (ACB, FEB Grup 1, FEB Grup 2)
// 3. Crea notificacions in-app per aquests àrbitres

import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";

interface HighlightData {
  id: string;
  matchId: string;
  title: string;
  timestamp: number;
  category: string;
  reactionsSummary: {
    totalCount: number;
    likeCount: number;
    importantCount: number;
    controversialCount: number;
  };
  status: "open" | "under_review" | "resolved";
  reviewNotifiedAt?: admin.firestore.Timestamp;
}

interface RefereeProfile {
  uid: string;
  displayName?: string;
  categoriaRrtt?: string;
}

/**
 * Extreu categoria des de categoriaRrtt
 * Exemple: "ÀRBITRE FEB (GRUP 1) Barcelona" → "FEB_GRUP_1"
 */
function extractCategory(categoriaRrtt: string | undefined): string {
  if (!categoriaRrtt) return "FCBQ_OTHER";

  const normalized = categoriaRrtt.toUpperCase();

  if (normalized.includes("ACB")) return "ACB";
  if (normalized.includes("FEB") && normalized.includes("GRUP 1")) return "FEB_GRUP_1";
  if (normalized.includes("FEB") && normalized.includes("GRUP 2")) return "FEB_GRUP_2";
  if (normalized.includes("FEB") && normalized.includes("GRUP 3")) return "FEB_GRUP_3";
  if (normalized.includes("FCBQ A1") || normalized.includes("A1")) return "FCBQ_A1";

  return "FCBQ_OTHER";
}

/**
 * Comprova si una categoria és de màxima categoria
 * ACB, FEB Grup 1, FEB Grup 2 poden revisar jugades
 */
function isHighCategoryReferee(category: string): boolean {
  return ["ACB", "FEB_GRUP_1", "FEB_GRUP_2"].includes(category);
}

/**
 * Obté àrbitres de màxima categoria
 */
async function getHighCategoryReferees(): Promise<RefereeProfile[]> {
  const db = admin.firestore();

  try {
    // Buscar a referees_registry tots els àrbitres amb categoria alta
    const snapshot = await db.collection("referees_registry").get();

    const highCategoryReferees: RefereeProfile[] = [];

    for (const doc of snapshot.docs) {
      const data = doc.data();
      const category = extractCategory(data.categoriaRrtt as string);

      if (isHighCategoryReferee(category)) {
        // Buscar l'usuari corresponent a users
        const userSnapshot = await db
          .collection("users")
          .where("llissenciaId", "==", data.llissenciaId)
          .limit(1)
          .get();

        if (!userSnapshot.empty) {
          const userData = userSnapshot.docs[0].data();
          highCategoryReferees.push({
            uid: userSnapshot.docs[0].id,
            displayName: userData.displayName as string,
            categoriaRrtt: data.categoriaRrtt as string,
          });
        }
      }
    }

    console.log(`[notifyReferees] Trobats ${highCategoryReferees.length} àrbitres de màxima categoria`);
    return highCategoryReferees;
  } catch (error) {
    console.error("[notifyReferees] Error obtenint àrbitres:", error);
    return [];
  }
}

/**
 * Crea notificacions in-app per als àrbitres
 */
async function createNotifications(
  referees: RefereeProfile[],
  highlightData: HighlightData
): Promise<void> {
  const db = admin.firestore();
  const batch = db.batch();

  for (const referee of referees) {
    const notificationRef = db.collection("notifications").doc();

    const notification = {
      id: notificationRef.id,
      userId: referee.uid,
      type: "highlight_review_requested",
      title: "Nova jugada per revisar",
      message: `La jugada "${highlightData.title}" ha arribat a ${highlightData.reactionsSummary.totalCount} reaccions i necessita la teva opinió.`,
      data: {
        matchId: highlightData.matchId,
        highlightId: highlightData.id,
        reactionCount: highlightData.reactionsSummary.totalCount,
        category: highlightData.category,
      },
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 7 dies
      ),
    };

    batch.set(notificationRef, notification);
  }

  await batch.commit();
  console.log(`[notifyReferees] ✅ ${referees.length} notificacions creades`);
}

/**
 * Trigger principal: Detecta quan un highlight arriba al threshold
 */
export const notifyRefereesOnThreshold = functions.firestore.onDocumentUpdated(
  {
    document: "entries/{matchId}/entries/{highlightId}",
    region: "europe-west1",
    memory: "256MiB",
  },
  async (event) => {
    const beforeData = event.data?.before.data() as HighlightData | undefined;
    const afterData = event.data?.after.data() as HighlightData | undefined;

    if (!beforeData || !afterData) {
      console.log("[notifyReferees] Dades no vàlides");
      return;
    }

    const matchId = event.params.matchId;
    const highlightId = event.params.highlightId;

    // Comprovar si ha arribat al threshold (10 reaccions)
    const beforeCount = beforeData.reactionsSummary?.totalCount || 0;
    const afterCount = afterData.reactionsSummary?.totalCount || 0;

    // Només executar quan passa de <10 a >=10
    if (beforeCount >= 10 || afterCount < 10) {
      return;
    }

    // Comprovar que l'estat ha canviat a "under_review"
    if (afterData.status !== "under_review") {
      console.log("[notifyReferees] Estat no és 'under_review'");
      return;
    }

    console.log(
      `[notifyReferees] 🔔 Threshold assolit! Match: ${matchId}, Highlight: ${highlightId}, Reaccions: ${afterCount}`
    );

    try {
      // Obtenir àrbitres de màxima categoria
      const referees = await getHighCategoryReferees();

      if (referees.length === 0) {
        console.log("[notifyReferees] ⚠️ No hi ha àrbitres disponibles");
        return;
      }

      // Crear notificacions
      await createNotifications(referees, {
        id: highlightId,
        matchId,
        title: afterData.title,
        timestamp: afterData.timestamp,
        category: afterData.category,
        reactionsSummary: afterData.reactionsSummary,
        status: afterData.status,
      });

      console.log("[notifyReferees] ✅ Procés completat");
    } catch (error) {
      console.error("[notifyReferees] ❌ Error:", error);
      throw error;
    }
  }
);
