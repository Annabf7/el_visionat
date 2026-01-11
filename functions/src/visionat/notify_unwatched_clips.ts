// ============================================================================
// notify_unwatched_clips.ts - Notifica usuaris amb clips pendents de veure
// ============================================================================
// Cloud Function programada que s'executa periòdicament (per exemple cada dilluns)
// per notificar als usuaris que tenen clips del Club de l'Àrbitre pendents
// de veure de fa més de 10 dies.

import {onSchedule} from "firebase-functions/v2/scheduler";
import {onRequest} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

const db = admin.firestore();

interface YouTubeVideo {
  videoId: string;
  title: string;
  publishedAt: admin.firestore.Timestamp;
  thumbnailUrl: string;
  youtubeUrl: string;
}

/**
 * Cloud Function programada que notifica usuaris amb clips pendents
 * S'executa cada dilluns a les 9:00 AM
 */
export const notifyUnwatchedClips = onSchedule(
  {
    schedule: "0 9 * * 1", // Cada dilluns a les 9:00 AM
    timeZone: "Europe/Madrid",
    region: "europe-west1",
  },
  async () => {
    try {
      console.log("[notifyUnwatchedClips] Iniciant comprovació de clips pendents...");

      const now = admin.firestore.Timestamp.now();
      const tenDaysAgo = admin.firestore.Timestamp.fromMillis(
        now.toMillis() - 10 * 24 * 60 * 60 * 1000
      );

      // 1. Obtenir tots els vídeos publicats fa més de 10 dies
      const videosSnapshot = await db
        .collection("youtube_videos")
        .where("publishedAt", "<=", tenDaysAgo)
        .orderBy("publishedAt", "desc")
        .limit(50) // Limitar a els últims 50 vídeos antics
        .get();

      if (videosSnapshot.empty) {
        console.log("[notifyUnwatchedClips] No hi ha vídeos de fa més de 10 dies");
        return;
      }

      const videos = videosSnapshot.docs.map((doc) => ({
        videoId: doc.id,
        ...(doc.data() as Omit<YouTubeVideo, "videoId">),
      }));

      console.log(`[notifyUnwatchedClips] Trobats ${videos.length} vídeos de fa més de 10 dies`);

      // 2. Obtenir tots els usuaris actius
      const usersSnapshot = await db.collection("users").get();

      if (usersSnapshot.empty) {
        console.log("[notifyUnwatchedClips] No hi ha usuaris registrats");
        return;
      }

      const users = usersSnapshot.docs.map((doc) => ({
        userId: doc.id,
        name: doc.data().name || "Àrbitre",
      }));

      console.log(`[notifyUnwatchedClips] Processant ${users.length} usuaris...`);

      let notificationsCreated = 0;

      // 3. Per cada usuari, comprovar clips pendents
      for (const user of users) {
        try {
          // Obtenir clips vistos per l'usuari
          const watchedClipsSnapshot = await db
            .collection("watched_clips")
            .where("userId", "==", user.userId)
            .get();

          const watchedVideoIds = new Set(
            watchedClipsSnapshot.docs.map((doc) => doc.data().videoId as string)
          );

          // Filtrar vídeos no vistos
          const unwatchedVideos = videos.filter(
            (video) => !watchedVideoIds.has(video.videoId)
          );

          if (unwatchedVideos.length === 0) {
            console.log(`[notifyUnwatchedClips] Usuari ${user.userId}: cap clip pendent`);
            continue;
          }

          console.log(
            `[notifyUnwatchedClips] Usuari ${user.userId}: ${unwatchedVideos.length} clips pendents`
          );

          // Crear notificació
          const notificationRef = db.collection("notifications").doc();

          const notification = {
            id: notificationRef.id,
            userId: user.userId,
            type: "unwatched_clips_reminder",
            title: "Clips pendents del Club de l'Àrbitre",
            message: unwatchedVideos.length === 1 ?
              "Tens 1 clip pendent de veure de fa més de 10 dies. Recorda fer els teus deures!" :
              `Tens ${unwatchedVideos.length} clips pendents de veure de fa més de 10 dies. Recorda fer els teus deures!`,
            data: {
              unwatchedCount: unwatchedVideos.length,
              oldestVideoId: unwatchedVideos[unwatchedVideos.length - 1].videoId,
              oldestVideoTitle: unwatchedVideos[unwatchedVideos.length - 1].title,
            },
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            expiresAt: admin.firestore.Timestamp.fromMillis(
              now.toMillis() + 30 * 24 * 60 * 60 * 1000 // Expira en 30 dies
            ),
          };

          await notificationRef.set(notification);
          notificationsCreated++;

          console.log(
            `[notifyUnwatchedClips] ✅ Notificació creada per ${user.userId} (${unwatchedVideos.length} clips pendents)`
          );
        } catch (userError) {
          console.error(
            `[notifyUnwatchedClips] ❌ Error processant usuari ${user.userId}:`,
            userError
          );
          // Continuar amb el següent usuari
        }
      }

      console.log(
        `[notifyUnwatchedClips] ✅ Completat! ${notificationsCreated} notificacions creades`
      );
    } catch (error) {
      console.error("[notifyUnwatchedClips] ❌ Error general:", error);
      throw error;
    }
  }
);

/**
 * Trigger HTTP per executar manualment la comprovació (útil per testing)
 */
export const checkUnwatchedClipsHttp = onRequest(
  {region: "europe-west1"},
  async (_req, res) => {
    try {
      console.log("[checkUnwatchedClipsHttp] Executant comprovació manual...");

      // Executar la mateixa lògica manualment
      const now = admin.firestore.Timestamp.now();

      // PER TESTING: Obtenir TOTS els vídeos (sense filtre de dies)
      const videosSnapshot = await db
        .collection("youtube_videos")
        .orderBy("publishedAt", "desc")
        .limit(50)
        .get();

      if (videosSnapshot.empty) {
        res.status(200).json({
          success: true,
          message: "No hi ha vídeos a la base de dades",
          result: {videosChecked: 0, usersProcessed: 0, notificationsCreated: 0},
        });
        return;
      }

      const videos = videosSnapshot.docs.map((doc) => ({
        videoId: doc.id,
        ...(doc.data() as Omit<YouTubeVideo, "videoId">),
      }));

      const usersSnapshot = await db.collection("users").get();

      if (usersSnapshot.empty) {
        res.status(200).json({
          success: true,
          message: "No hi ha usuaris registrats",
          result: {videosChecked: videos.length, usersProcessed: 0, notificationsCreated: 0},
        });
        return;
      }

      const users = usersSnapshot.docs.map((doc) => ({
        userId: doc.id,
        name: doc.data().name || "Àrbitre",
      }));

      let notificationsCreated = 0;

      for (const user of users) {
        try {
          const watchedClipsSnapshot = await db
            .collection("watched_clips")
            .where("userId", "==", user.userId)
            .get();

          const watchedVideoIds = new Set(
            watchedClipsSnapshot.docs.map((doc) => doc.data().videoId as string)
          );

          const unwatchedVideos = videos.filter(
            (video) => !watchedVideoIds.has(video.videoId)
          );

          if (unwatchedVideos.length === 0) {
            continue;
          }

          const notificationRef = db.collection("notifications").doc();

          const notification = {
            id: notificationRef.id,
            userId: user.userId,
            type: "unwatched_clips_reminder",
            title: "Clips pendents del Club de l'Àrbitre",
            message: unwatchedVideos.length === 1 ?
              "Tens 1 clip pendent de veure de fa més de 10 dies. Recorda fer els teus deures!" :
              `Tens ${unwatchedVideos.length} clips pendents de veure de fa més de 10 dies. Recorda fer els teus deures!`,
            data: {
              unwatchedCount: unwatchedVideos.length,
              oldestVideoId: unwatchedVideos[unwatchedVideos.length - 1].videoId,
              oldestVideoTitle: unwatchedVideos[unwatchedVideos.length - 1].title,
            },
            isRead: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            expiresAt: admin.firestore.Timestamp.fromMillis(
              now.toMillis() + 30 * 24 * 60 * 60 * 1000
            ),
          };

          await notificationRef.set(notification);
          notificationsCreated++;
        } catch (userError) {
          console.error(`Error processant usuari ${user.userId}:`, userError);
        }
      }

      res.status(200).json({
        success: true,
        message: "Comprovació de clips pendents executada correctament",
        result: {
          videosChecked: videos.length,
          usersProcessed: users.length,
          notificationsCreated,
        },
      });
    } catch (error) {
      console.error("[checkUnwatchedClipsHttp] Error:", error);
      res.status(500).json({
        success: false,
        error: error instanceof Error ? error.message : "Error desconegut",
      });
    }
  }
);
