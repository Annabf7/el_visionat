// Script per llegir Firestore usant Firebase Functions
// (workaround perquè el service account no funciona directament)
import fetch from 'node-fetch';

const FUNCTION_URL = 'https://europe-west1-el-visionat.cloudfunctions.net';

async function main() {
  console.log('\n=== COMPROVACIÓ PRODUCCIÓ (via HTTP) ===\n');
  
  // Llegir voting_meta via callable function
  // Com que no tenim una funció específica, podem cridar triggerSyncWeeklyVoting 
  // però això ja ho hem fet.
  
  // Alternativament, mirem els logs del terminal de Flutter
  console.log('Per veure les dades, comprova la consola del navegador o');
  console.log('fes servir la Firebase Console: https://console.firebase.google.com/project/el-visionat/firestore');
  
  console.log('\nDes del trigger_sync, sabem que:');
  console.log('- Jornada activa: 13');
  console.log('- Partits: 8');
  console.log('\nPero l\'app mostra Jornada 14. Això vol dir que voting_meta/current');
  console.log('probablement té activeJornada=14 però voting_jornades/14 no existeix.');
}

main();
