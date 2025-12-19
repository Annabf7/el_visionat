/**
 * Script per verificar els matchIds a voting_jornades
 */

async function checkMatchIds() {
  const jornada = process.argv[2] || 13;
  
  console.log(`🔍 Verificant matchIds de jornada ${jornada}...\n`);

  try {
    const response = await fetch(
      "https://europe-west1-el-visionat.cloudfunctions.net/getActiveVotingJornada",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          data: {},
        }),
      }
    );

    const result = await response.json();
    
    if (result.result && result.result.matches) {
      console.log(`📋 Jornada activa: ${result.result.jornada}`);
      console.log(`📋 Total partits: ${result.result.matches.length}\n`);
      
      console.log('matchIds disponibles:');
      result.result.matches.forEach((m, i) => {
        console.log(`  ${i + 1}. ${m.matchId}`);
        console.log(`     ${m.home.teamNameDisplay} vs ${m.away.teamNameDisplay}`);
      });
    } else {
      console.log('Resposta:', JSON.stringify(result, null, 2));
    }
  } catch (error) {
    console.error("❌ Error:", error.message);
  }

  process.exit(0);
}

checkMatchIds();
