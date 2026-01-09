/**
 * Script per testejar el flux de notificacions
 * Afegeix 10 reaccions a un highlight per activar notifyRefereesOnThreshold
 *
 * Ús:
 * node test_notification_flow.mjs <matchId> <highlightId>
 */

import admin from 'firebase-admin';

// Utilitzar les credencials per defecte de l'aplicació
admin.initializeApp();

const db = admin.firestore();

async function addReactionsToHighlight(matchId, highlightId, numReactions = 10) {
  console.log(`📝 Afegint ${numReactions} reaccions al highlight ${highlightId} del match ${matchId}...`);

  try {
    // Verificar que el highlight existeix
    const highlightRef = db
      .collection('highlights')
      .doc(matchId)
      .collection('highlightList')
      .doc(highlightId);

    const highlightDoc = await highlightRef.get();
    if (!highlightDoc.exists) {
      console.error('❌ El highlight no existeix!');
      return;
    }

    const highlightData = highlightDoc.data();
    console.log(`✅ Highlight trobat: ${highlightData.description || 'Sense descripció'}`);
    console.log(`   Temps: ${highlightData.minute}:${highlightData.second}`);

    // Obtenir reaccions actuals
    const reactionsSnapshot = await highlightRef
      .collection('reactions')
      .get();

    const currentReactions = reactionsSnapshot.size;
    console.log(`📊 Reaccions actuals: ${currentReactions}`);

    // Obtenir usuaris del sistema per simular reaccions
    const usersSnapshot = await db.collection('users')
      .limit(numReactions)
      .get();

    if (usersSnapshot.empty) {
      console.error('❌ No hi ha usuaris al sistema per crear reaccions');
      return;
    }

    const users = usersSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    console.log(`👥 Usuaris disponibles: ${users.length}`);

    // Afegir reaccions
    const batch = db.batch();
    let addedCount = 0;

    for (let i = 0; i < Math.min(numReactions, users.length); i++) {
      const user = users[i];
      const reactionRef = highlightRef
        .collection('reactions')
        .doc(user.id);

      // Verificar si ja té reacció
      const existingReaction = await reactionRef.get();
      if (existingReaction.exists) {
        console.log(`⏭️  ${user.name || user.email} ja té reacció, saltant...`);
        continue;
      }

      batch.set(reactionRef, {
        userId: user.id,
        userName: user.name || user.email,
        type: 'important', // O 'agree', 'disagree' segons prefereixis
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      addedCount++;
      console.log(`✅ Afegint reacció de: ${user.name || user.email}`);
    }

    if (addedCount > 0) {
      await batch.commit();
      console.log(`\n🎉 S'han afegit ${addedCount} reaccions amb èxit!`);

      // Esperar una mica per deixar que la Cloud Function processi
      console.log('\n⏳ Esperant 5 segons per deixar que la Cloud Function processi...');
      await new Promise(resolve => setTimeout(resolve, 5000));

      // Verificar les notificacions creades
      const notificationsSnapshot = await db.collection('notifications')
        .where('data.highlightId', '==', highlightId)
        .orderBy('createdAt', 'desc')
        .limit(10)
        .get();

      console.log(`\n📬 Notificacions creades: ${notificationsSnapshot.size}`);

      notificationsSnapshot.forEach(doc => {
        const notification = doc.data();
        console.log(`   - Usuari: ${notification.userId}`);
        console.log(`     Títol: ${notification.title}`);
        console.log(`     Missatge: ${notification.message}`);
        console.log(`     Llegida: ${notification.isRead ? 'Sí' : 'No'}`);
        console.log('');
      });

      // Verificar reaccions finals
      const finalReactionsSnapshot = await highlightRef
        .collection('reactions')
        .get();

      console.log(`📊 Total de reaccions després del test: ${finalReactionsSnapshot.size}`);

      if (finalReactionsSnapshot.size >= 10) {
        console.log('✅ El llindar de 10 reaccions s\'ha assolit!');
        console.log('🔔 La Cloud Function hauria d\'haver creat notificacions per als àrbitres ACB');
      }

    } else {
      console.log('\n⚠️  No s\'ha afegit cap reacció nova (potser ja existien totes)');
    }

  } catch (error) {
    console.error('❌ Error:', error);
  }
}

// Llegir arguments de la línia de comandes
const matchId = process.argv[2];
const highlightId = process.argv[3];
const numReactions = process.argv[4] ? parseInt(process.argv[4]) : 10;

if (!matchId || !highlightId) {
  console.error('❌ Ús: node test_notification_flow.mjs <matchId> <highlightId> [numReactions]');
  console.error('   Exemple: node test_notification_flow.mjs match123 highlight456 10');
  process.exit(1);
}

addReactionsToHighlight(matchId, highlightId, numReactions)
  .then(() => {
    console.log('\n✅ Test completat!');
    process.exit(0);
  })
  .catch(error => {
    console.error('\n❌ Error durant el test:', error);
    process.exit(1);
  });
