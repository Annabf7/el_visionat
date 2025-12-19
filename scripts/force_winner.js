/**
 * Script per forçar el processament del guanyador d'una jornada
 * Executa amb: node scripts/force_winner.js [jornada]
 */

async function forceWinner() {
  const jornada = parseInt(process.argv[2]) || 12;
  
  console.log(`🏆 Forçant processament del guanyador de jornada ${jornada}...\n`);

  try {
    const response = await fetch(
      "https://europe-west1-el-visionat.cloudfunctions.net/forceProcessWinner",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          data: { jornada },
        }),
      }
    );

    const result = await response.json();
    console.log("✅ Resposta:", JSON.stringify(result, null, 2));
  } catch (error) {
    console.error("❌ Error:", error.message);
  }

  process.exit(0);
}

forceWinner();
