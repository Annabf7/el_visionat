/**
 * Script per configurar el weekly_focus de jornada 12 amb el partit CB ARTÉS vs FC MARTINENC
 * i la info completa dels àrbitres
 */

async function setupJornada12() {
  console.log('🏀 Configurant weekly_focus per jornada 12...\n');

  const data = {
    jornada: 12,
    competitionName: "Super Copa Masculina",
    totalVotes: 1,
    winningMatch: {
      matchId: "12-cb-artes-fc-martinenc-basquet-a",
      jornada: 12,
      home: {
        teamId: "cbartes",
        teamNameRaw: "CB ARTÉS",
        teamNameDisplay: "CB ARTÉS",
        logoSlug: "cb-artes.webp",
        colorHex: "#FF0000"
      },
      away: {
        teamId: "fcmartinenc",
        teamNameRaw: "FC MARTINENC BÀSQUET A",
        teamNameDisplay: "FC MARTINENC BÀSQUET A",
        logoSlug: "fc-martinenc-basquet-a.webp",
        colorHex: "#FF0000"
      },
      dateTime: "2025-12-13T18:15:00",
      dateDisplay: "Dissabte 13 Desembre, 18:15",
      location: "PAVELLO ESPORTIU D'ARTES - Artés (08271)",
      status: "finished",
      homeScore: 80,
      awayScore: 72
    },
    refereeInfo: {
      principal: "SERGI LOPEZ I MARQUES",
      auxiliar: "JORDI GINE GUIXERIS",
      tableOfficials: [
        { role: "Anotador", name: "MARC BARRERA SANCHEZ" },
        { role: "Operador RLL", name: "XAVIER CASERO MASJUAN" },
        { role: "Cronometrador", name: "ALBERT RODRIGUEZ SANCHEZ" },
        { role: "Caller", name: "JORDI CASAFONT CAMPOS" }
      ],
      source: "fcbq-acta",
      actaUrl: "https://www.basquetcatala.cat/acta/2955"
    }
  };

  try {
    const response = await fetch(
      "https://europe-west1-el-visionat.cloudfunctions.net/setupWeeklyFocus",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ data }),
      }
    );

    const result = await response.json();
    
    if (result.result?.success) {
      console.log('✅ Weekly focus configurat correctament!');
      console.log('\nResum:');
      console.log('- Jornada: 12');
      console.log('- Partit: CB ARTÉS 80 - 72 FC MARTINENC BÀSQUET A');
      console.log('- Àrbitre Principal: SERGI LOPEZ I MARQUES');
      console.log('- Àrbitre Auxiliar: JORDI GINE GUIXERIS');
      console.log('- Oficials de taula: 4');
      console.log('\nFes Hot Reload a l\'app per veure els canvis!');
    } else {
      console.log('❌ Error:', JSON.stringify(result, null, 2));
    }
  } catch (error) {
    console.error('❌ Error:', error.message);
  }

  process.exit(0);
}

setupJornada12();
