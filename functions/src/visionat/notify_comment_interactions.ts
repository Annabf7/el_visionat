// ============================================================================
// Cloud Function: Notificacions per interaccions amb comentaris
// ============================================================================
// Triggers:
// 1. Quan es crea una resposta a un comentari -> notificar autor del comentari pare
// 2. Quan es crea un like a un comentari -> notificar autor del comentari

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
  createdAt: admin.firestore.Timestamp;
}

interface LikeData {
  userId: string;
  createdAt: admin.firestore.Timestamp;
}

/**
 * Notifica l'autor d'un comentari quan algú respon
 */
export const notifyCommentReply = functions.firestore.onDocumentCreated(
  {
    document: "entries/{matchId}/entries/{highlightId}/comments/{commentId}",
    region: "europe-west1",
    memory: "256MiB",
  },
  async (event) => {
    const commentData = event.data?.data() as CommentData | undefined;

    if (!commentData) {
      console.log("[notifyReply] Dades no vàlides");
      return;
    }

    // Només processar si és una resposta (té parentCommentId)
    if (!commentData.parentCommentId) {
      return;
    }

    const matchId = event.params.matchId;
    const highlightId = event.params.highlightId;
    const parentCommentId = commentData.parentCommentId;

    console.log(
      `[notifyReply] 💬 Resposta detectada! Match: ${matchId}, Highlight: ${highlightId}, Parent: ${parentCommentId}`
    );

    try {
      const db = admin.firestore();

      // Obtenir el comentari pare per saber qui és l'autor
      const parentCommentDoc = await db
        .collection("entries")
        .doc(matchId)
        .collection("entries")
        .doc(highlightId)
        .collection("comments")
        .doc(parentCommentId)
        .get();

      if (!parentCommentDoc.exists) {
        console.error("[notifyReply] Comentari pare no trobat");
        return;
      }

      const parentCommentData = parentCommentDoc.data() as CommentData;

      // No notificar si l'usuari respon al seu propi comentari
      if (parentCommentData.userId === commentData.userId) {
        return;
      }

      // Obtenir dades del highlight per al títol
      const highlightDoc = await db
        .collection("entries")
        .doc(matchId)
        .collection("entries")
        .doc(highlightId)
        .get();

      const highlightTitle = highlightDoc.exists ?
        (highlightDoc.data()?.title as string) :
        "una jugada";

      // Crear notificació
      const notificationRef = db.collection("notifications").doc();

      const notification = {
        id: notificationRef.id,
        userId: parentCommentData.userId,
        type: "comment_reply",
        title: "Nova resposta al teu comentari",
        message: `${commentData.userName} ha respost al teu comentari sobre "${highlightTitle}".`,
        data: {
          matchId,
          highlightId,
          commentId: commentData.id,
          parentCommentId,
          replyAuthorId: commentData.userId,
          replyAuthorName: commentData.userName,
        },
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 7 dies
        ),
      };

      await notificationRef.set(notification);

      console.log(`[notifyReply] ✅ Notificació creada per ${parentCommentData.userId}`);
    } catch (error) {
      console.error("[notifyReply] ❌ Error:", error);
      throw error;
    }
  }
);

/**
 * Notifica l'autor d'un comentari quan algú fa like
 */
export const notifyCommentLike = functions.firestore.onDocumentCreated(
  {
    document: "entries/{matchId}/entries/{highlightId}/comments/{commentId}/likes/{likeId}",
    region: "europe-west1",
    memory: "256MiB",
  },
  async (event) => {
    const likeData = event.data?.data() as LikeData | undefined;

    if (!likeData) {
      console.log("[notifyLike] Dades no vàlides");
      return;
    }

    const matchId = event.params.matchId;
    const highlightId = event.params.highlightId;
    const commentId = event.params.commentId;
    const likeUserId = likeData.userId;

    console.log(
      `[notifyLike] ❤️ Like detectat! Match: ${matchId}, Highlight: ${highlightId}, Comment: ${commentId}`
    );

    try {
      const db = admin.firestore();

      // Obtenir el comentari per saber qui és l'autor
      const commentDoc = await db
        .collection("entries")
        .doc(matchId)
        .collection("entries")
        .doc(highlightId)
        .collection("comments")
        .doc(commentId)
        .get();

      if (!commentDoc.exists) {
        console.error("[notifyLike] Comentari no trobat");
        return;
      }

      const commentData = commentDoc.data() as CommentData;

      // No notificar si l'usuari fa like al seu propi comentari
      if (commentData.userId === likeUserId) {
        return;
      }

      // Obtenir el nom de l'usuari que fa like
      const likeUserDoc = await db.collection("users").doc(likeUserId).get();

      const likeUserName = likeUserDoc.exists ?
        (likeUserDoc.data()?.name as string) || "Algú" :
        "Algú";

      // Obtenir dades del highlight per al títol
      const highlightDoc = await db
        .collection("entries")
        .doc(matchId)
        .collection("entries")
        .doc(highlightId)
        .get();

      const highlightTitle = highlightDoc.exists ?
        (highlightDoc.data()?.title as string) :
        "una jugada";

      // Crear notificació
      const notificationRef = db.collection("notifications").doc();

      const notification = {
        id: notificationRef.id,
        userId: commentData.userId,
        type: "comment_like",
        title: "A algú li agrada el teu comentari",
        message: `A ${likeUserName} li ha agradat el teu comentari sobre "${highlightTitle}".`,
        data: {
          matchId,
          highlightId,
          commentId,
          likeUserId,
          likeUserName,
        },
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + 3 * 24 * 60 * 60 * 1000) // 3 dies (menys temps que respostes)
        ),
      };

      await notificationRef.set(notification);

      console.log(`[notifyLike] ✅ Notificació creada per ${commentData.userId}`);
    } catch (error) {
      console.error("[notifyLike] ❌ Error:", error);
      throw error;
    }
  }
);
