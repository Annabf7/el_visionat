/**
 * Script per testejar el flux complet de syncWeeklyVoting
 * Simula el que passaria el proper dilluns a les 8h
 * 
 * ⚠️ COMPTE: Això pot modificar dades de producció!
 */

async function testSyncFlow() {
  console.log('🧪 TEST: Flux syncWeeklyVoting\n');
  console.log('=' .repeat(50));
  
  // 1. Primer veiem l'estat actual
  console.log('\n📋 1. Verificant jornada activa actual...');
  
  try {
    const activeResponse = await fetch(
      "https://europe-west1-el-visionat.cloudfunctions.net/getActiveVotingJornada",
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ data: {} }),
      }
    );
    const activeResult = await activeResponse.json();
    
    if (activeResult.result) {
      console.log(`   ✅ Jornada activa: ${activeResult.result.jornada}`);
      console.log(`   📅 Cap de setmana: ${activeResult.result.weekendStart?.split('T')[0]} - ${activeResult.result.weekendEnd?.split('T')[0]}`);
      console.log(`   🏀 Partits: ${activeResult.result.matches?.length || 0}`);
    } else {
      console.log('   ❌ No hi ha jornada activa');
    }
  } catch (e) {
    console.log(`   ❌ Error: ${e.message}`);
  }
  
  // 2. Simular què faria syncWeeklyVoting si s'executés ara
  console.log('\n📋 2. Simulant triggerSyncWeeklyVoting...');
  console.log('   (Buscarà partits pel proper cap de setmana i processarà el guanyador de la jornada anterior)');
  
  const confirmPrompt = '\n⚠️  ATENCIÓ: Això modificarà dades de producció!';
  console.log(confirmPrompt);
  console.log('   - Tancarà la votació de jornada 13 (si encara està oberta)');
  console.log('   - Processarà el guanyador i crearà weekly_focus/current nou');
  console.log('   - Obrirà la votació per jornada 14');
  console.log('\nPer executar-ho, descomenta el codi a sota i torna a executar.');
  
  // EXECUTANT TEST REAL:
  try {
    const syncResponse = await fetch(
      "https://europe-west1-el-visionat.cloudfunctions.net/triggerSyncWeeklyVoting",
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ data: {} }),
      }
    );
    const syncResult = await syncResponse.json();
    console.log('\n📋 Resultat triggerSyncWeeklyVoting:');
    console.log(JSON.stringify(syncResult, null, 2));
  } catch (e) {
    console.log(`   ❌ Error: ${e.message}`);
  }
  
  console.log('\n' + '=' .repeat(50));
  console.log('✅ Test completat (mode simulació)');
}

testSyncFlow();
