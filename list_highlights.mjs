/**
 * Script per llistar highlights existents
 */

import admin from 'firebase-admin';

// Utilitzar les credencials per defecte de l'aplicació
admin.initializeApp();

const db = admin.firestore();

async function listHighlights() {
  console.log('🔍 Buscant highlights...\n');

  try {
    const highlightsSnapshot = await db.collectionGroup('highlightList')
      .limit(20)
      .get();

    if (highlightsSnapshot.empty) {
      console.log('❌ No s\'han trobat highlights');
      return;
    }

    console.log(`✅ Trobats ${highlightsSnapshot.size} highlights:\n`);

    for (const doc of highlightsSnapshot.docs) {
      const data = doc.data();
      const matchId = doc.ref.parent.parent.id;
      const highlightId = doc.id;

      // Comptar reaccions
      const reactionsSnapshot = await doc.ref.collection('reactions').get();
      const reactionCount = reactionsSnapshot.size;

      console.log(`📍 Match ID: ${matchId}`);
      console.log(`   Highlight ID: ${highlightId}`);
      console.log(`   Descripció: ${data.description || 'Sense descripció'}`);
      console.log(`   Temps: ${data.minute}:${data.second}`);
      console.log(`   Reaccions: ${reactionCount}`);
      console.log(`   Comandament per testejar:`);
      console.log(`   node test_notification_flow.mjs ${matchId} ${highlightId}\n`);
    }

  } catch (error) {
    console.error('❌ Error:', error);
  }
}

listHighlights()
  .then(() => process.exit(0))
  .catch(error => {
    console.error('❌ Error:', error);
    process.exit(1);
  });
