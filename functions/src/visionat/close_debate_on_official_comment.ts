// ============================================================================
// Cloud Function: Tancar debat quan àrbitre ACB/FEB Grup 1 dona veredicte
// ============================================================================
// Trigger: Quan es crea un comentari oficial (isOfficial: true)
// Accions:
// 1. Valida que l'àrbitre té autoritat (ACB o FEB Grup 1)
// 2. Marca el highlight com "resolved"
// 3. Notifica tots els participants del debat

import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";

interface CommentData {
  id: string;
  highlightId: string;
  matchId: string;
  userId: string;
  userName: string;
  userCategory: string;
  text: string;
  isOfficial: boolean;
  parentCommentId?: string;
  likesCount: number;
  repliesCount: number;
  createdAt: admin.firestore.Timestamp;
}

/**
 * Comprova si una categoria pot tancar debats
 */
function canCloseDebate(category: string): boolean {
  const upperCategory = category.toUpperCase();
  return upperCategory.includes("ACB") || upperCategory.includes("FEB GRUP 1");
}

/**
 * Obté tots els usuaris que han participat en una jugada
 * (creador + usuaris amb reaccions + usuaris amb comentaris)
 */
async function getDebateParticipants(
  matchId: string,
  highlightId: string
): Promise<Set<string>> {
  const db = admin.firestore();
  const participants = new Set<string>();

  try {
    // 1. Obtenir el creador del highlight
    const highlightDoc = await db
      .collection("entries")
      .doc(matchId)
      .collection("entries")
      .doc(highlightId)
      .get();

    if (highlightDoc.exists) {
      const data = highlightDoc.data();
      if (data?.createdBy) {
        participants.add(data.createdBy as string);
      }

      // 2. Obtenir usuaris amb reaccions
      if (data?.reactions && Array.isArray(data.reactions)) {
        for (const reaction of data.reactions) {
          if (reaction.userId) {
            participants.add(reaction.userId as string);
          }
        }
      }
    }

    // 3. Obtenir usuaris amb comentaris (ara a la col·lecció "comments")
    const commentsSnapshot = await db
      .collection("entries")
      .doc(matchId)
      .collection("entries")
      .doc(highlightId)
      .collection("comments")
      .get();

    for (const doc of commentsSnapshot.docs) {
      const commentData = doc.data();
      if (commentData.userId) {
        participants.add(commentData.userId as string);
      }
    }

    console.log(`[closeDebate] Trobats ${participants.size} participants`);
    return participants;
  } catch (error) {
    console.error("[closeDebate] Error obtenint participants:", error);
    return participants;
  }
}

/**
 * Crea notificacions per als participants
 */
async function notifyParticipants(
  participants: Set<string>,
  officialUserId: string,
  matchId: string,
  highlightId: string,
  highlightTitle: string,
  refereeCategory: string
): Promise<void> {
  const db = admin.firestore();
  const batch = db.batch();

  const categoryDisplay = refereeCategory === "ACB" ? "ACB" : "FEB Grup 1";

  for (const userId of participants) {
    // No notificar al mateix àrbitre que va tancar el debat
    if (userId === officialUserId) continue;

    const notificationRef = db.collection("notifications").doc();

    const notification = {
      id: notificationRef.id,
      userId,
      type: "debate_closed",
      title: "Debat tancat amb veredicte oficial",
      message: `Un àrbitre ${categoryDisplay} ha donat el veredicte final sobre "${highlightTitle}".`,
      data: {
        matchId,
        highlightId,
        refereeCategory,
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
  console.log(`[closeDebate] ✅ ${participants.size - 1} notificacions creades`);
}

/**
 * Trigger principal: Detecta comentaris oficials
 */
export const closeDebateOnOfficialComment = functions.firestore.onDocumentCreated(
  {
    document: "entries/{matchId}/entries/{highlightId}/comments/{commentId}",
    region: "europe-west1",
    memory: "256MiB",
  },
  async (event) => {
    const commentData = event.data?.data() as CommentData | undefined;

    if (!commentData) {
      console.log("[closeDebate] Dades no vàlides");
      return;
    }

    // Només processar si és un comentari oficial
    if (!commentData.isOfficial) {
      return;
    }

    const matchId = event.params.matchId;
    const highlightId = event.params.highlightId;
    const commentId = event.params.commentId;

    console.log(
      `[closeDebate] 🔒 Comentari oficial detectat! Match: ${matchId}, Highlight: ${highlightId}, Comment: ${commentId}`
    );

    // Validar que l'àrbitre té autoritat
    if (!canCloseDebate(commentData.userCategory)) {
      console.error(
        `[closeDebate] ⚠️ Àrbitre ${commentData.userCategory} no té autoritat per tancar debats`
      );
      // Revertir isOfficial a false
      const db = admin.firestore();
      await db
        .collection("entries")
        .doc(matchId)
        .collection("entries")
        .doc(highlightId)
        .collection("comments")
        .doc(commentId)
        .update({
          isOfficial: false,
        });
      return;
    }

    try {
      const db = admin.firestore();

      // Obtenir dades del highlight
      const highlightDoc = await db
        .collection("entries")
        .doc(matchId)
        .collection("entries")
        .doc(highlightId)
        .get();

      if (!highlightDoc.exists) {
        console.error("[closeDebate] Highlight no trobat");
        return;
      }

      const highlightData = highlightDoc.data()!;

      // Actualitzar highlight (ja s'hauria fet al service, però per seguretat)
      await db
        .collection("entries")
        .doc(matchId)
        .collection("entries")
        .doc(highlightId)
        .update({
          status: "resolved",
          officialCommentId: commentId,
          resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      console.log("[closeDebate] ✅ Highlight marcat com resolt");

      // Obtenir participants i notificar
      const participants = await getDebateParticipants(matchId, highlightId);

      if (participants.size > 1) {
        await notifyParticipants(
          participants,
          commentData.userId,
          matchId,
          highlightId,
          highlightData.title as string,
          commentData.userCategory
        );
      }

      console.log("[closeDebate] ✅ Procés completat");
    } catch (error) {
      console.error("[closeDebate] ❌ Error:", error);
      throw error;
    }
  }
);
