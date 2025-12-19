// Script per configurar weekly_focus de jornada 12 amb el partit guanyador i àrbitres
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const path = require('path');

const serviceAccount = require(path.join(__dirname, '..', 'serviceAccountKey.json'));

initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

async function setupJornada12() {
  console.log('\n=== CONFIGURANT JORNADA 12 AMB ÀRBITRES ===\n');

  const jornada = 12;
  
  // Dades del partit guanyador
  const matchId = `${jornada}-cb-artes-fc-martinenc-basquet-a`;
  
  // 1. Crear/actualitzar el document de vote_counts
  console.log('1. Afegint vot al partit...');
  await db.collection('vote_counts').doc(matchId).set({
    jornada: jornada,
    count: 1,
    matchId: matchId,
    lastVoteAt: new Date().toISOString(),
  });
  console.log(`   ✅ Vot afegit a ${matchId}`);

  // 2. Crear el document weekly_focus/current amb la info completa
  console.log('\n2. Creant weekly_focus/current...');
  
  const weeklyFocusData = {
    jornada: jornada,
    competitionName: 'Super Copa Masculina',
    winningMatch: {
      matchId: matchId,
      jornada: jornada,
      home: {
        teamId: 'cbartes',
        teamNameRaw: 'CB ARTÉS',
        teamNameDisplay: 'CB ARTÉS',
        logoSlug: 'cb-artes.webp',
        colorHex: '#FF0000',
      },
      away: {
        teamId: 'fcmartinenc',
        teamNameRaw: 'FC MARTINENC BÀSQUET A',
        teamNameDisplay: 'FC MARTINENC BÀSQUET A',
        logoSlug: 'fc-martinenc-basquet-a.webp',
        colorHex: '#FF0000',
      },
      dateTime: '2025-12-13T18:15:00',
      dateDisplay: 'Dissabte 13 Desembre, 18:15',
      status: 'completed',
      result: {
        homeScore: 80,
        awayScore: 72,
      },
    },
    refereeInfo: {
      principal: 'SERGI LOPEZ I MARQUES',
      auxiliar: 'JORDI GINE GUIXERIS',
      tableOfficials: [
        { role: 'Anotador', name: 'MARC BARRERA SANCHEZ' },
        { role: 'Operador RLL', name: 'XAVIER CASERO MASJUAN' },
        { role: 'Cronometrador', name: 'ALBERT RODRIGUEZ SANCHEZ' },
        { role: 'Caller', name: 'JORDI CASAFONT CAMPOS' },
      ],
      source: 'fcbq-acta',
      actaUrl: 'https://www.basquetcatala.cat/acta/2955',
      fetchedAt: new Date().toISOString(),
    },
    totalVotes: 1,
    votingClosedAt: '2025-12-16T08:00:00.000Z', // Dilluns 16 a les 8h
    status: 'completat', // Ja tenim la info dels àrbitres
    processedAt: new Date().toISOString(),
  };

  await db.collection('weekly_focus').doc('current').set(weeklyFocusData);
  console.log('   ✅ weekly_focus/current creat amb àrbitres');

  // 3. Guardar també com a històric
  console.log('\n3. Guardant històric...');
  await db.collection('weekly_focus').doc(`jornada_${jornada}`).set(weeklyFocusData);
  console.log(`   ✅ weekly_focus/jornada_${jornada} guardat`);

  // 4. Actualitzar voting_meta per marcar jornada 12 com tancada
  console.log('\n4. Marcant jornada 12 com tancada...');
  await db.collection('voting_meta').doc(`jornada_${jornada}`).set({
    votingOpen: false,
    closedAt: '2025-12-16T08:00:00.000Z',
    closedReason: 'Votació tancada - processament completat',
  }, { merge: true });
  console.log('   ✅ voting_meta/jornada_12 actualitzat');

  console.log('\n=== CONFIGURACIÓ COMPLETADA ===');
  console.log('\nResum:');
  console.log(`- Partit guanyador: CB ARTÉS vs FC MARTINENC BÀSQUET A`);
  console.log(`- Resultat: 80-72`);
  console.log(`- Àrbitre principal: SERGI LOPEZ I MARQUES`);
  console.log(`- Àrbitre auxiliar: JORDI GINE GUIXERIS`);
  console.log(`- Oficials de taula: 4`);
  console.log('\nFes Hot Reload a l\'app per veure els canvis!\n');
}

setupJornada12()
  .then(() => process.exit(0))
  .catch(err => {
    console.error('Error:', err);
    process.exit(1);
  });
