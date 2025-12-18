/**
 * Script per invocar triggerSyncWeeklyVoting manualment
 * Executa amb: node scripts/trigger_sync.js
 */

import {createRequire} from "module";
const require = createRequire(import.meta.url);

const serviceAccount = require("../serviceAccountKey.json");

async function triggerSync() {
  console.log("🔄 Invocant triggerSyncWeeklyVoting...\n");

  try {
    const response = await fetch(
      "https://europe-west1-el-visionat.cloudfunctions.net/triggerSyncWeeklyVoting",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          data: {}, // Callable functions esperen { data: ... }
        }),
      }
    );

    const result = await response.json();
    console.log("✅ Resposta:", JSON.stringify(result, null, 2));
  } catch (error) {
    console.error("❌ Error:", error.message);
  }

  process.exit(0);
}

triggerSync();
