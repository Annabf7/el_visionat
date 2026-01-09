/**
 * Script per forçar un entry a arribar al threshold de 10 reaccions
 * Crea reaccions amb usuaris ficticis per testejar
 *
 * Ús: node force_threshold.mjs <matchId> <entryId>
 * Exemple: node force_threshold.mjs match_123 F2kg0A6KIsJhMgjzUFva
 */

import admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

async function forceThreshold(matchId, entryId) {
  console.log(`📝 Forçant threshold per l'entry ${entryId} del match ${matchId}...\n`);

  try {
    // Accedir directament al document
    const entryRef = db
      .collection('entries')
      .doc(matchId)
      .collection('entries')
      .doc(entryId);

    const entryDoc = await entryRef.get();

    if (!entryDoc.exists) {
      console.error('❌ Entry no trobat!');
      console.error(`   Path: entries/${matchId}/entries/${entryId}`);
      return;
    }

    const entryData = entryDoc.data();

    console.log(`✅ Entry trobat:`);
    console.log(`   Títol: ${entryData.title}`);
    console.log(`   Categoria: ${entryData.category}`);
    console.log(`   Estat actual: ${entryData.status}`);

    // Reaccions actuals
    const currentReactions = entryData.reactions || [];
    const currentCount = entryData.reactionsSummary?.totalCount || 0;

    console.log(`\n📊 Reaccions actuals: ${currentCount}`);

    if (currentCount >= 10) {
      console.log('⚠️  Ja té 10 o més reaccions!');
      return;
    }

    // Calcular quantes reaccions necessitem
    const needed = 10 - currentCount;
    console.log(`\n🎯 Necessitem afegir ${needed} reaccions més per arribar a 10`);

    // Crear reaccions fictícies
    const newReactions = [...currentReactions];
    let importantCount = entryData.reactionsSummary?.importantCount || 0;
    let likeCount = entryData.reactionsSummary?.likeCount || 0;
    let controversialCount = entryData.reactionsSummary?.controversialCount || 0;

    for (let i = 0; i < needed; i++) {
      const types = ['important', 'like', 'controversial'];
      const type = types[i % 3];

      newReactions.push({
        userId: `test_user_${Date.now()}_${i}`,
        type,
        createdAt: admin.firestore.Timestamp.now(),
      });

      if (type === 'important') importantCount++;
      else if (type === 'like') likeCount++;
      else if (type === 'controversial') controversialCount++;

      console.log(`   ✅ Afegint reacció fictícia "${type}"`);
    }

    // Nou resum
    const newSummary = {
      totalCount: 10,
      likeCount,
      importantCount,
      controversialCount
    };

    // Actualitzar document amb estat under_review
    const updateData = {
      reactions: newReactions,
      reactionsSummary: newSummary,
      status: 'under_review',
    };

    console.log(`\n🔔 Actualitzant estat a "under_review" i afegint reaccions...`);
    await entryRef.update(updateData);

    console.log(`\n🎉 Actualització completa!`);
    console.log(`\n📊 Nou resum:`);
    console.log(`   Total: ${newSummary.totalCount}`);
    console.log(`   Like: ${newSummary.likeCount}`);
    console.log(`   Important: ${newSummary.importantCount}`);
    console.log(`   Controversial: ${newSummary.controversialCount}`);
    console.log(`   Estat: under_review`);

    console.log(`\n✅ El llindar de 10 reaccions s'ha assolit!`);
    console.log(`🔔 La Cloud Function "notifyRefereesOnThreshold" hauria de crear notificacions`);

    // Esperar per deixar que la Cloud Function processi
    console.log(`\n⏳ Esperant 15 segons per deixar que la Cloud Function processi...\n`);
    await new Promise(resolve => setTimeout(resolve, 15000));

    // Verificar notificacions
    const notificationsSnapshot = await db.collection('notifications')
      .where('data.highlightId', '==', entryId)
      .orderBy('createdAt', 'desc')
      .get();

    console.log(`\n📬 Notificacions creades: ${notificationsSnapshot.size}`);

    if (notificationsSnapshot.empty) {
      console.log(`\n⚠️  No s'han creat notificacions. Possibles causes:`);
      console.log(`   1. La Cloud Function pot trigar uns segons més`);
      console.log(`   2. No hi ha àrbitres ACB/FEB a users amb llissenciaId`);
      console.log(`   3. Revisa els logs de Cloud Functions:`);
      console.log(`   firebase functions:log --only notifyRefereesOnThreshold`);
    } else {
      console.log(`\n✅ Notificacions creades correctament:\n`);
      notificationsSnapshot.forEach(doc => {
        const notification = doc.data();
        console.log(`   📩 ${doc.id}:`);
        console.log(`      Usuari: ${notification.userId}`);
        console.log(`      Títol: ${notification.title}`);
        console.log(`      Missatge: ${notification.message}`);
        console.log(`      Llegida: ${notification.isRead ? 'Sí' : 'No'}`);
        console.log('');
      });
    }

  } catch (error) {
    console.error('\n❌ Error:', error);
  }
}

// Llegir arguments
const matchId = process.argv[2];
const entryId = process.argv[3];

if (!matchId || !entryId) {
  console.error('❌ Ús: node force_threshold.mjs <matchId> <entryId>');
  console.error('   Exemple: node force_threshold.mjs match_123 F2kg0A6KIsJhMgjzUFva');
  process.exit(1);
}

forceThreshold(matchId, entryId)
  .then(() => {
    console.log('\n✅ Test completat!');
    process.exit(0);
  })
  .catch(error => {
    console.error('\n❌ Error durant el test:', error);
    process.exit(1);
  });
