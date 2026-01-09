// ============================================================================
// test_unwatched_clips.mjs - Script per provar notificacions de clips pendents
// ============================================================================
// Executa manualment la Cloud Function checkUnwatchedClipsHttp per testing

import fetch from 'node-fetch';

const CLOUD_FUNCTION_URL = 'https://europe-west1-el-visionat.cloudfunctions.net/checkUnwatchedClipsHttp';

async function testUnwatchedClipsNotification() {
  console.log('🧪 Test: Notificació de clips pendents');
  console.log('=====================================\n');

  try {
    console.log('📡 Executant Cloud Function...');
    console.log(`URL: ${CLOUD_FUNCTION_URL}\n`);

    const response = await fetch(CLOUD_FUNCTION_URL, {
      method: 'GET',
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const result = await response.json();

    console.log('✅ Resultat:');
    console.log(JSON.stringify(result, null, 2));

    if (result.success) {
      console.log('\n📊 Resum:');
      if (result.result) {
        console.log(`   - Vídeos comprovats: ${result.result.videosChecked}`);
        console.log(`   - Usuaris processats: ${result.result.usersProcessed}`);
        console.log(`   - Notificacions creades: ${result.result.notificationsCreated}`);
      }
      console.log('\n✅ Test completat amb èxit!');
    } else {
      console.log('\n❌ Error en el test');
    }

  } catch (error) {
    console.error('\n❌ Error executant el test:', error.message);
    process.exit(1);
  }
}

// Executar el test
testUnwatchedClipsNotification();
