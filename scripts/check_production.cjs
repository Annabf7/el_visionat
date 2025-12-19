// Script per comprovar l'estat de producció de Firestore
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const path = require('path');

const serviceAccount = require(path.join(__dirname, '..', 'serviceAccountKey.json'));

initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

async function check() {
  console.log('\n=== COMPROVACIÓ PRODUCCIÓ FIRESTORE ===\n');

  // 1. Comprovar voting_meta/current
  console.log('1. voting_meta/current:');
  const meta = await db.collection('voting_meta').doc('current').get();
  if (meta.exists) {
    const data = meta.data();
    console.log('   ✅ Existeix');
    console.log(`   - activeJornada: ${data.activeJornada}`);
    console.log(`   - matchCount: ${data.matchCount}`);
    console.log(`   - weekendStart: ${data.weekendStart?.toDate?.() || data.weekendStart}`);
    console.log(`   - weekendEnd: ${data.weekendEnd?.toDate?.() || data.weekendEnd}`);
  } else {
    console.log('   ❌ NO EXISTEIX - Cal executar syncWeeklyVoting');
  }

  // 2. Comprovar voting_jornades
  console.log('\n2. voting_jornades:');
  const jornadesSnap = await db.collection('voting_jornades').get();
  console.log(`   Total documents: ${jornadesSnap.size}`);
  
  for (const doc of jornadesSnap.docs) {
    const data = doc.data();
    const matchCount = data.matches?.length || 0;
    console.log(`   - Jornada ${doc.id}: ${matchCount} partits`);
  }

  // 3. Comprovar weekly_focus
  console.log('\n3. weekly_focus/current:');
  const focus = await db.collection('weekly_focus').doc('current').get();
  if (focus.exists) {
    const data = focus.data();
    console.log('   ✅ Existeix');
    console.log(`   - jornada: ${data.jornada}`);
    console.log(`   - totalVotes: ${data.totalVotes}`);
    console.log(`   - winningMatch: ${data.winningMatch?.matchDisplayName || 'N/A'}`);
  } else {
    console.log('   ❌ NO EXISTEIX - Es crearà quan es processi el guanyador');
  }

  // 4. Comprovar vote_counts
  console.log('\n4. vote_counts (últims vots):');
  const votes = await db.collection('vote_counts').orderBy('count', 'desc').limit(5).get();
  if (votes.empty) {
    console.log('   Cap vot registrat');
  } else {
    for (const doc of votes.docs) {
      const data = doc.data();
      console.log(`   - ${doc.id}: ${data.count} vots (jornada ${data.jornada})`);
    }
  }

  console.log('\n=== FI COMPROVACIÓ ===\n');
}

check()
  .then(() => process.exit(0))
  .catch(err => {
    console.error('Error:', err);
    process.exit(1);
  });
