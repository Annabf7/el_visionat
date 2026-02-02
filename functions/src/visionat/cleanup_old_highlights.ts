// ============================================================================
// Cleanup Old Highlights - Elimina highlights quan canvia el partit setmanal
// ============================================================================
// Aquesta funció s'executa quan s'actualitza weekly_focus/current
// i elimina els highlights del partit anterior per estalviar costos de Firestore.
// ============================================================================

import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

/**
 * Trigger que s'executa quan s'actualitza el document weekly_focus/current
 * Si el matchId canvia, elimina tots els highlights del partit anterior
 */
export const cleanupOldHighlightsOnWeeklyFocusChange = onDocumentUpdated(
  {
    document: "weekly_focus/current",
    region: "europe-west1",
  },
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!beforeData || !afterData) {
      logger.warn("No s'han pogut obtenir les dades del document");
      return;
    }

    // Obtenir matchId anterior i nou
    const oldMatchId = beforeData.winningMatch?.matchId;
    const newMatchId = afterData.winningMatch?.matchId;

    // Si no hi ha canvi de matchId, no fer res
    if (!oldMatchId || oldMatchId === newMatchId) {
      logger.info("El matchId no ha canviat, no cal netejar highlights");
      return;
    }

    logger.info(`Partit setmanal canviat: ${oldMatchId} -> ${newMatchId}`);
    logger.info("Iniciant neteja de highlights del partit anterior...");

    try {
      const db = admin.firestore();
      const batch = db.batch();
      let deletedCount = 0;

      // 1. Eliminar highlights (entries/{matchId}/entries)
      const highlightsSnapshot = await db
        .collection("entries")
        .doc(oldMatchId)
        .collection("entries")
        .get();

      for (const doc of highlightsSnapshot.docs) {
        batch.delete(doc.ref);
        deletedCount++;
      }

      // Eliminar també el document pare si existeix
      const parentDoc = db.collection("entries").doc(oldMatchId);
      const parentSnapshot = await parentDoc.get();
      if (parentSnapshot.exists) {
        batch.delete(parentDoc);
      }

      // 2. Eliminar comentaris col·lectius (collective_comments on matchId == oldMatchId)
      const commentsSnapshot = await db
        .collection("collective_comments")
        .where("matchId", "==", oldMatchId)
        .get();

      for (const doc of commentsSnapshot.docs) {
        batch.delete(doc.ref);
        deletedCount++;
      }

      // Executar batch delete
      if (deletedCount > 0) {
        await batch.commit();
        logger.info(
          `Neteja completada: ${deletedCount} documents eliminats del partit ${oldMatchId}`
        );
      } else {
        logger.info(`No hi havia documents per eliminar del partit ${oldMatchId}`);
      }

      // 3. Log per auditoria (opcional)
      await db.collection("cleanup_logs").add({
        action: "weekly_focus_change_cleanup",
        oldMatchId,
        newMatchId,
        deletedDocuments: deletedCount,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (error) {
      logger.error("Error netejant highlights antics:", error);
    }
  }
);
