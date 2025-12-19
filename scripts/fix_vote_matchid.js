/**
 * Script per corregir el matchId d'un vot existent
 * Executa amb: node scripts/fix_vote_matchid.js
 */

import admin from 'firebase-admin';
import { createRequire } from 'module';
const require = createRequire(import.meta.url);

const serviceAccount = require('../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function fixVoteMatchId() {
  const oldMatchId = 'cb-ipsi-a.webp';
  const newMatchId = '13-cb-ipsi-a-ramon-soler-cb-salt';
  const jornada = 13;

  console.log(`🔧 Corregint matchId de "${oldMatchId}" a "${newMatchId}"...\n`);

  try {
    // 1. Buscar el document antic a vote_counts
    const oldDocId = `${jornada}_${oldMatchId}`;
    const newDocId = `${jornada}_${newMatchId}`;
    
    const oldDocRef = db.collection('vote_counts').doc(oldDocId);
    const oldDoc = await oldDocRef.get();

    if (!oldDoc.exists) {
      console.log(`❌ No s'ha trobat el document: ${oldDocId}`);
      
      // Busquem amb query per si el docId és diferent
      const query = await db.collection('vote_counts')
        .where('matchId', '==', oldMatchId)
        .where('jornada', '==', jornada)
        .get();
      
      if (query.empty) {
        console.log('❌ No s\'ha trobat cap document amb aquest matchId');
        process.exit(1);
      }
      
      const doc = query.docs[0];
      console.log(`✅ Trobat document: ${doc.id}`);
      
      const data = doc.data();
      
      // Crear nou document amb matchId corregit
      await db.collection('vote_counts').doc(newDocId).set({
        ...data,
        matchId: newMatchId,
      });
      
      // Eliminar document antic
      await doc.ref.delete();
      
      console.log(`✅ Document migrat a: ${newDocId}`);
    } else {
      const data = oldDoc.data();
      
      // Crear nou document
      await db.collection('vote_counts').doc(newDocId).set({
        ...data,
        matchId: newMatchId,
      });
      
      // Eliminar document antic
      await oldDocRef.delete();
      
      console.log(`✅ Document migrat de ${oldDocId} a ${newDocId}`);
    }

    // 2. També actualitzar els vots individuals (col·lecció votes)
    const votesQuery = await db.collection('votes')
      .where('matchId', '==', oldMatchId)
      .where('jornada', '==', jornada)
      .get();

    console.log(`\n📋 Trobats ${votesQuery.size} vots individuals per actualitzar`);

    const batch = db.batch();
    votesQuery.docs.forEach(doc => {
      batch.update(doc.ref, { matchId: newMatchId });
    });
    await batch.commit();

    console.log(`✅ ${votesQuery.size} vots actualitzats\n`);
    console.log('🎉 Correcció completada!');

  } catch (error) {
    console.error('❌ Error:', error.message);
  }

  process.exit(0);
}

fixVoteMatchId();
