/**
 * Script per verificar l'estructura dels highlights
 */

import admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

async function checkStructure() {
  console.log('🔍 Verificant estructura de Firestore...\n');

  try {
    // Comprovar entries
    const entriesSnapshot = await db.collection('entries').limit(5).get();
    console.log(`📁 Col·lecció 'entries': ${entriesSnapshot.size} documents`);

    for (const doc of entriesSnapshot.docs) {
      console.log(`\n   Document ID: ${doc.id}`);
      const data = doc.data();
      console.log(`   - matchId: ${data.matchId}`);
      console.log(`   - title: ${data.title}`);
      console.log(`   - reactionsSummary.totalCount: ${data.reactionsSummary?.totalCount}`);
      console.log(`   - status: ${data.status}`);

      // Comprovar si té subcol·lecció entries
      const subEntriesSnapshot = await doc.ref.collection('entries').limit(1).get();
      console.log(`   - Subcol·lecció 'entries': ${subEntriesSnapshot.size} documents`);
    }

    // Comprovar si hi ha usuari Jordi Aliaga
    console.log('\n\n👤 Buscant usuari Jordi Aliaga...');
    const usersSnapshot = await db.collection('app_users')
      .where('displayName', '==', 'ALIAGA SOLE, JORDI')
      .get();

    if (!usersSnapshot.empty) {
      const userData = usersSnapshot.docs[0].data();
      console.log(`✅ Trobat: ${usersSnapshot.docs[0].id}`);
      console.log(`   - displayName: ${userData.displayName}`);
      console.log(`   - llissenciaId: ${userData.llissenciaId}`);
    } else {
      console.log('❌ No trobat a app_users');
    }

    // Comprovar a referees_registry
    const refereesSnapshot = await db.collection('referees_registry')
      .where('llissenciaId', '==', '1771')
      .get();

    if (!refereesSnapshot.empty) {
      const refereeData = refereesSnapshot.docs[0].data();
      console.log(`\n✅ Trobat a referees_registry:`);
      console.log(`   - nom: ${refereeData.nom}`);
      console.log(`   - categoriaRrtt: ${refereeData.categoriaRrtt}`);
    } else {
      console.log('\n❌ No trobat a referees_registry');
    }

  } catch (error) {
    console.error('❌ Error:', error);
  }
}

checkStructure()
  .then(() => process.exit(0))
  .catch(error => {
    console.error('❌ Error:', error);
    process.exit(1);
  });
