/**
 * Script per afegir reaccions a un entry (highlight)
 * Actualitza reactionsSummary i canvia l'estat a under_review quan arriba a 10
 *
 * Ús: node add_reactions_to_entry.mjs <matchId> <entryId> [numReactions]
 * Exemple: node add_reactions_to_entry.mjs match_123 F2kg0A6KIsJhMgjzUFva 10
 */

import admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

async function addReactionsToEntry(matchId, entryId, numReactions = 10) {
  console.log(`📝 Afegint ${numReactions} reaccions a l'entry ${entryId} del match ${matchId}...\n`);

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
    console.log(`   Path: ${entryRef.path}`);
    console.log(`   Match ID: ${matchId}`);
    console.log(`   Títol: ${entryData.title}`);
    console.log(`   Descripció: ${entryData.description}`);
    console.log(`   Categoria: ${entryData.category}`);
    console.log(`   Estat actual: ${entryData.status}`);

    // Reaccions actuals
    const currentReactions = entryData.reactions || [];
    const currentSummary = entryData.reactionsSummary || {
      totalCount: 0,
      likeCount: 0,
      importantCount: 0,
      controversialCount: 0
    };

    console.log(`\n📊 Reaccions actuals:`);
    console.log(`   Total: ${currentSummary.totalCount}`);
    console.log(`   Like: ${currentSummary.likeCount}`);
    console.log(`   Important: ${currentSummary.importantCount}`);
    console.log(`   Controversial: ${currentSummary.controversialCount}`);

    // Obtenir usuaris per simular reaccions
    const usersSnapshot = await db.collection('users')
      .limit(numReactions)
      .get();

    if (usersSnapshot.empty) {
      console.error('\n❌ No hi ha usuaris disponibles per crear reaccions');
      return;
    }

    console.log(`\n👥 Usuaris disponibles: ${usersSnapshot.size}`);

    // Preparar noves reaccions
    const newReactions = [...currentReactions];
    const existingUserIds = new Set(currentReactions.map(r => r.userId));
    let addedCount = 0;
    let importantCount = currentSummary.importantCount || 0;
    let likeCount = currentSummary.likeCount || 0;
    let controversialCount = currentSummary.controversialCount || 0;

    for (const userDoc of usersSnapshot.docs) {
      if (addedCount >= numReactions) break;

      const userId = userDoc.id;
      if (existingUserIds.has(userId)) {
        console.log(`   ⏭️  ${userDoc.data().displayName || userDoc.data().email} ja té reacció`);
        continue;
      }

      // Alternar tipus de reacció
      const types = ['important', 'like', 'controversial'];
      const type = types[addedCount % 3];

      newReactions.push({
        userId,
        type,
        createdAt: admin.firestore.Timestamp.now(),
      });

      if (type === 'important') importantCount++;
      else if (type === 'like') likeCount++;
      else if (type === 'controversial') controversialCount++;

      addedCount++;
      console.log(`   ✅ Afegint reacció "${type}" de: ${userDoc.data().displayName || userDoc.data().email}`);
    }

    if (addedCount === 0) {
      console.log('\n⚠️  No s\'ha afegit cap reacció nova');
      return;
    }

    // Calcular nou resum
    const newTotalCount = currentSummary.totalCount + addedCount;
    const newSummary = {
      totalCount: newTotalCount,
      likeCount,
      importantCount,
      controversialCount
    };

    // Determinar nou estat
    let newStatus = entryData.status;
    if (newTotalCount >= 10 && entryData.status === 'open') {
      newStatus = 'under_review';
      console.log(`\n🔔 Canviant estat a "under_review" (threshold assolit!)`);
    }

    // Actualitzar document
    const updateData = {
      reactions: newReactions,
      reactionsSummary: newSummary,
      status: newStatus,
    };

    // Si canvia a under_review, afegir reviewNotifiedAt
    if (newStatus === 'under_review' && entryData.status !== 'under_review') {
      updateData.reviewNotifiedAt = admin.firestore.FieldValue.serverTimestamp();
    }

    await entryRef.update(updateData);

    console.log(`\n🎉 S'han afegit ${addedCount} reaccions amb èxit!`);
    console.log(`\n📊 Nou resum de reaccions:`);
    console.log(`   Total: ${newSummary.totalCount}`);
    console.log(`   Like: ${newSummary.likeCount}`);
    console.log(`   Important: ${newSummary.importantCount}`);
    console.log(`   Controversial: ${newSummary.controversialCount}`);
    console.log(`   Estat: ${newStatus}`);

    if (newTotalCount >= 10) {
      console.log(`\n✅ El llindar de 10 reaccions s'ha assolit!`);
      console.log(`🔔 La Cloud Function "notifyRefereesOnThreshold" hauria de crear notificacions`);

      // Esperar per deixar que la Cloud Function processi
      console.log(`\n⏳ Esperant 10 segons per deixar que la Cloud Function processi...\n`);
      await new Promise(resolve => setTimeout(resolve, 10000));

      // Verificar notificacions
      const notificationsSnapshot = await db.collection('notifications')
        .where('data.highlightId', '==', entryId)
        .orderBy('createdAt', 'desc')
        .get();

      console.log(`\n📬 Notificacions creades: ${notificationsSnapshot.size}`);

      if (notificationsSnapshot.empty) {
        console.log(`⚠️  No s'han creat notificacions. Verifica:`);
        console.log(`   1. La Cloud Function està desplegada`);
        console.log(`   2. Hi ha àrbitres ACB/FEB registrats a users amb llissenciaId`);
        console.log(`   3. Els logs de Cloud Functions per errors`);
      } else {
        notificationsSnapshot.forEach(doc => {
          const notification = doc.data();
          console.log(`\n   📩 Notificació ${doc.id}:`);
          console.log(`      Usuari: ${notification.userId}`);
          console.log(`      Títol: ${notification.title}`);
          console.log(`      Missatge: ${notification.message}`);
          console.log(`      Llegida: ${notification.isRead ? 'Sí' : 'No'}`);
        });
      }
    }

  } catch (error) {
    console.error('\n❌ Error:', error);
  }
}

// Llegir arguments
const matchId = process.argv[2];
const entryId = process.argv[3];
const numReactions = process.argv[4] ? parseInt(process.argv[4]) : 10;

if (!matchId || !entryId) {
  console.error('❌ Ús: node add_reactions_to_entry.mjs <matchId> <entryId> [numReactions]');
  console.error('   Exemple: node add_reactions_to_entry.mjs match_123 F2kg0A6KIsJhMgjzUFva 10');
  process.exit(1);
}

addReactionsToEntry(matchId, entryId, numReactions)
  .then(() => {
    console.log('\n✅ Test completat!');
    process.exit(0);
  })
  .catch(error => {
    console.error('\n❌ Error durant el test:', error);
    process.exit(1);
  });
