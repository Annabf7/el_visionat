/**
 * ✅ on_vote_write_test.js
 *
 * Test d'integració per al trigger Cloud Function `onVoteWrite` del sistema de votacions d’El Visionat.
 * 
 * Executa proves automàtiques contra l’emulador de Firestore i comprova que:
 *  1️⃣ Crear un vot incrementa correctament el comptador del partit.
 *  2️⃣ Actualitzar el vot a un altre partit decrementa l’antic i incrementa el nou.
 *  3️⃣ Eliminar el vot decrementa el comptador corresponent.
 *  4️⃣ Els comptadors mai no queden per sota de zero.
 *
 * 💡 Com executar:
 *  1. Inicia els emuladors (functions + firestore):
 *     firebase emulators:start
 *  2. En una altra terminal:
 *     cd functions
 *     npm run test:emulator
 *
 * Els resultats es mostren amb “PASS/FAIL” per a cada test i un resum final.
 */

const admin = require('firebase-admin');

// ✅ Connecta amb els emuladors locals (ports definits a firebase.json)
process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8185';
process.env.FIREBASE_AUTH_EMULATOR_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9199';

// ✅ Inicialitza l'SDK d'administrador amb el projecte local
if (!admin.apps.length) {
  admin.initializeApp({ projectId: 'el-visionat' });
}
const db = admin.firestore();

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function waitForCount(docPath, expected, timeoutMs = 10000) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    const snap = await db.doc(docPath).get();
    const val = snap.exists ? (snap.data().count || 0) : 0;
    if (val === expected) return true;
    await sleep(300);
  }
  return false;
}

async function run() {
  console.log('🚀 Iniciant test de la funció on_vote_write...\n');

  const jornada = 14;
  const userId = 'test-user-1';
  const voteDocId = `${jornada}_${userId}`;
  const m1 = 'match-one';
  const m2 = 'match-two';

  // 🧹 Neteja prèvia
  await Promise.all([
    db.doc(`votes/${voteDocId}`).delete().catch(() => {}),
    db.doc(`vote_counts/${jornada}_${m1}`).delete().catch(() => {}),
    db.doc(`vote_counts/${jornada}_${m2}`).delete().catch(() => {}),
  ]);

  // Test 1: Creació
  console.log('🧩 Test 1: crear vot → esperem que el comptador del partit sigui 1');
  await db.doc(`votes/${voteDocId}`).set({
    userId,
    jornada,
    matchId: m1,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  const ok1 = await waitForCount(`vote_counts/${jornada}_${m1}`, 1, 10000);
  console.log('Test 1 result:', ok1 ? '✅ PASS' : '❌ FAIL');

  // Test 2: Actualització
  console.log('\n🧩 Test 2: actualitzar vot → esperem que l\'antic baixi a 0 i el nou pugi a 1');
  await db.doc(`votes/${voteDocId}`).update({
    matchId: m2,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  const ok2_old = await waitForCount(`vote_counts/${jornada}_${m1}`, 0, 10000);
  const ok2_new = await waitForCount(`vote_counts/${jornada}_${m2}`, 1, 10000);
  console.log('Test 2 result:', (ok2_old && ok2_new) ? '✅ PASS' : `❌ FAIL (old:${ok2_old}, new:${ok2_new})`);

  // Test 3: Eliminació
  console.log('\n🧩 Test 3: eliminar vot → esperem que el comptador del nou partit baixi a 0');
  await db.doc(`votes/${voteDocId}`).delete();
  const ok3 = await waitForCount(`vote_counts/${jornada}_${m2}`, 0, 10000);
  console.log('Test 3 result:', ok3 ? '✅ PASS' : '❌ FAIL');

  // Test 4: Integritat dels comptadors
  console.log('\n🧩 Test 4: integritat → cap comptador ha de ser negatiu');
  await db.doc(`votes/${voteDocId}`).set({ userId, jornada, matchId: m1 });
  await waitForCount(`vote_counts/${jornada}_${m1}`, 1, 10000);
  await db.doc(`votes/${voteDocId}`).update({ matchId: m2 });
  await waitForCount(`vote_counts/${jornada}_${m1}`, 0, 10000);
  await db.doc(`votes/${voteDocId}`).delete();
  await waitForCount(`vote_counts/${jornada}_${m2}`, 0, 10000);

  const snap1 = await db.doc(`vote_counts/${jornada}_${m1}`).get();
  const snap2 = await db.doc(`vote_counts/${jornada}_${m2}`).get();
  const v1 = snap1.exists ? (snap1.data().count || 0) : 0;
  const v2 = snap2.exists ? (snap2.data().count || 0) : 0;
  const ok4 = v1 >= 0 && v2 >= 0;
  console.log('Test 4 result:', ok4 ? '✅ PASS' : `❌ FAIL (counts: ${v1}, ${v2})`);

  // Resum
  console.log('\n🧾 Resum final:');
  console.log(`vote_counts/${jornada}_${m1} = ${v1}`);
  console.log(`vote_counts/${jornada}_${m2} = ${v2}`);
  console.log('\n🟩 Tots els tests completats.\n');

  process.exit(ok1 && ok2_old && ok2_new && ok3 && ok4 ? 0 : 2);
}

run().catch((err) => {
  console.error('❌ Error al test:', err);
  process.exit(1);
});
