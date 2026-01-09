// Script temporal per forçar el processament del guanyador de la Jornada 13
// Executa: node test_force_winner.js

const admin = require('firebase-admin');

// Inicialitza Firebase Admin
const serviceAccount = require('./el-visionat-firebase-adminsdk.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://el-visionat.firebaseio.com'
});

const functions = admin.functions();

async function testForceProcessWinner() {
  console.log('🏀 Forçant processament del guanyador de la Jornada 13...\n');

  try {
    // Importem les funcions directament
    const { forceProcessWinner } = require('./functions/lib/fcbq/sync_weekly_voting');

    // Cridem la funció amb jornada 13
    const result = await forceProcessWinner.run({
      data: { jornada: 13 },
      auth: null,
      rawRequest: null
    });

    console.log('\n✅ Resultat:');
    console.log(JSON.stringify(result, null, 2));

    // Llegim el document weekly_focus/current per verificar
    const db = admin.firestore();
    const focusDoc = await db.collection('weekly_focus').doc('current').get();

    if (focusDoc.exists) {
      console.log('\n📋 Document weekly_focus/current:');
      const data = focusDoc.data();
      console.log(JSON.stringify(data, null, 2));

      console.log('\n👥 Equip Arbitral:');
      if (data.refereeInfo) {
        console.log(`  Àrbitre Principal: ${data.refereeInfo.principal || 'No trobat'}`);
        console.log(`  Àrbitre Auxiliar: ${data.refereeInfo.auxiliar || 'No trobat'}`);
        if (data.refereeInfo.tableOfficials) {
          console.log('  Oficials de taula:');
          data.refereeInfo.tableOfficials.forEach(official => {
            console.log(`    - ${official.role}: ${official.name}`);
          });
        }
      } else {
        console.log('  ⚠️ No hi ha informació d\'àrbitres');
      }
    }

    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

testForceProcessWinner();