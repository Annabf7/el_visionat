// ============================================================================
// getYouTubeVideos - Integració amb YouTube Data API v3
// ============================================================================
// Aquesta funció obté els 5 vídeos més recents del canal Club del Árbitro
// utilitzant l'API de YouTube i retorna una llista simplificada.
// ============================================================================

import {onRequest} from "firebase-functions/v2/https";
import {logger} from "firebase-functions";

// Interfície per la resposta de YouTube API v3
interface YouTubeSearchItem {
  id: {
    videoId: string;
  };
  snippet: {
    title: string;
    thumbnails: {
      default: { url: string };
      medium?: { url: string };
      high?: { url: string };
    };
    publishedAt: string;
  };
}

interface YouTubeSearchResponse {
  items: YouTubeSearchItem[];
}

// Interfície per la resposta simplificada de la nostra API
interface VideoData {
  videoId: string;
  title: string;
  thumbnailUrl: string;
  publishedAt: string;
}

// Constants del canal Club del Árbitro
const CHANNEL_ID = "UCmhbb617NoQPjXSxQkvUSyw";
const MAX_RESULTS = 5;

/**
 * Cloud Function v2 que obté els vídeos més recents del canal Club del Árbitro
 *
 * @returns Lista de vídeos amb: videoId, title, thumbnailUrl, publishedAt
 */
export const getYouTubeVideos = onRequest(
  {
    region: "europe-west1",
    secrets: ["YOUTUBE_API_KEY"],
    timeoutSeconds: 30,
    memory: "256MiB",
    cors: true,
  },
  async (request, response) => {
    logger.info("[getYouTubeVideos] Starting YouTube API request");

    try {
      // Obtenir la clau API des del Secret Manager
      const apiKey = process.env.YOUTUBE_API_KEY;

      if (!apiKey) {
        logger.error("[getYouTubeVideos] YouTube API key not found in environment");
        response.status(500).json({
          error: "YouTube API key not configured",
        });
        return;
      }

      // Construir la URL de l'API de YouTube
      const youtubeUrl = new URL("https://www.googleapis.com/youtube/v3/search");
      youtubeUrl.searchParams.set("part", "snippet");
      youtubeUrl.searchParams.set("channelId", CHANNEL_ID);
      youtubeUrl.searchParams.set("type", "video");
      youtubeUrl.searchParams.set("maxResults", MAX_RESULTS.toString());
      youtubeUrl.searchParams.set("order", "date");
      youtubeUrl.searchParams.set("key", apiKey);

      logger.info(`[getYouTubeVideos] Calling YouTube API: ${youtubeUrl.toString().replace(apiKey, "[API_KEY_HIDDEN]")}`);

      // Realitzar la petició a YouTube API (Node 18+ native fetch)
      const youtubeResponse = await fetch(youtubeUrl.toString());

      if (!youtubeResponse.ok) {
        const errorText = await youtubeResponse.text();
        logger.error(`[getYouTubeVideos] YouTube API error: ${youtubeResponse.status} ${youtubeResponse.statusText}`, {
          error: errorText,
        });

        response.status(500).json({
          error: `YouTube API failed: ${youtubeResponse.status} ${youtubeResponse.statusText}`,
        });
        return;
      }

      const youtubeData = await youtubeResponse.json() as YouTubeSearchResponse;

      // Transformar les dades a format simplificat
      const videos: VideoData[] = youtubeData.items.map((item) => ({
        videoId: item.id.videoId,
        title: item.snippet.title,
        thumbnailUrl: item.snippet.thumbnails.medium?.url || item.snippet.thumbnails.default.url,
        publishedAt: item.snippet.publishedAt,
      }));

      logger.info(`[getYouTubeVideos] Successfully retrieved ${videos.length} videos from Club del Árbitro`);

      // Retornar resposta amb èxit
      response.status(200).json({
        success: true,
        videos: videos,
      });
    } catch (error: unknown) {
      logger.error("[getYouTubeVideos] Unexpected error:", error);

      response.status(500).json({
        error: "Internal server error while fetching YouTube videos",
        message: error instanceof Error ? error.message : "Unknown error",
      });
    }
  }
);
