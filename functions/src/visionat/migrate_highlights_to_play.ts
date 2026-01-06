// ============================================================================
// Script de migració: Afegir camps de reaccions a highlights existents
// ============================================================================
// Executa aquest script manualment per migrar highlights antics

import * as admin from "firebase-admin";

// Inicialitzar Firebase Admin (si no està ja inicialitzat)
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

async function migrateHighlightsToPlay() {
  console.log("🔄 Iniciant migració de highlights...");

  try {
    // Obtenir tots els matchIds
    const entriesSnapshot = await db.collection("entries").get();

    let totalMigrated = 0;
    let totalSkipped = 0;

    for (const matchDoc of entriesSnapshot.docs) {
      const matchId = matchDoc.id;
      console.log(`\n📁 Processant partit: ${matchId}`);

      // Obtenir tots els highlights d'aquest partit
      const highlightsSnapshot = await db
        .collection("entries")
        .doc(matchId)
        .collection("entries")
        .get();

      console.log(`   Trobades ${highlightsSnapshot.docs.length} jugades`);

      for (const entryDoc of highlightsSnapshot.docs) {
        const data = entryDoc.data();

        // Comprovar si ja té els camps de reaccions
        if (data.reactions !== undefined) {
          console.log(`   ⏭️  ${entryDoc.id} - Ja migrat, saltant...`);
          totalSkipped++;
          continue;
        }

        // Afegir camps de HighlightPlay
        const updates = {
          reactions: [],
          reactionsSummary: {
            likeCount: 0,
            importantCount: 0,
            controversialCount: 0,
            totalCount: 0,
          },
          commentCount: 0,
          status: "open",
        };

        await entryDoc.ref.update(updates);
        console.log(`   ✅ ${entryDoc.id} - Migrat correctament`);
        totalMigrated++;
      }
    }

    console.log("\n" + "=".repeat(50));
    console.log("✅ Migració completada!");
    console.log(`   Total migrats: ${totalMigrated}`);
    console.log(`   Total saltats: ${totalSkipped}`);
    console.log("=".repeat(50));
  } catch (error) {
    console.error("❌ Error durant la migració:", error);
    throw error;
  }
}

// Executar la migració
migrateHighlightsToPlay()
  .then(() => {
    console.log("\n🎉 Script completat amb èxit!");
    process.exit(0);
  })
  .catch((error) => {
    console.error("\n💥 Script fallit:", error);
    process.exit(1);
  });
