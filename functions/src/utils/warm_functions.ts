// functions/src/utils/warm_functions.ts
// Funció simple per "escalfar" l'emulador i evitar cold starts

import {onCall} from "firebase-functions/v2/https";

/**
 * Funció de warming per inicialitzar l'emulador més ràpidament.
 * Es pot cridar al començament de l'aplicació per evitar el cold start.
 */
export const warmFunctions = onCall({
  region: "europe-west1",
  timeoutSeconds: 10,
  memory: "128MiB",
}, async (request) => {
  console.log("[warmFunctions] Warming up Functions emulator...");

  // Simplement retornem un missatge de confirmació
  return {
    success: true,
    message: "Functions emulator is now warm and ready!",
    timestamp: new Date().toISOString(),
  };
});
