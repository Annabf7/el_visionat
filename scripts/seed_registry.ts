/**
 * 📦 seed_registry.ts
 * 
 * Script de càrrega massiva de dades de llicències d'àrbitres a Firestore.
 * Llegeix l'arxiu JSON `registre_complet.json` i crea/actualitza la col·lecció
 * `referees_registry` amb els perfils de llicència.
 * 
 * Compatible amb Firestore Emulator (port 8085) i amb Firestore real.
 * 
 * Execució:
 *   ▶ npm run seed
 * 
 * Si l’emulador està actiu, el detectarà automàticament i hi enviarà les dades.
 * Si no, connectarà al projecte “el-visionat” a Firebase.
 */

import admin from 'firebase-admin';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { type RefereeLicenseProfile } from './models.js';

// -----------------------------------------------------------------------------
// 🧩 Configuració de rutes (necessari en mòduls ESM)
// -----------------------------------------------------------------------------
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// -----------------------------------------------------------------------------
// ⚙️ Connexió amb Firestore (detecta automàticament l’emulador)
// Preferències d'ús (ordre de prioritat):
//  1) argument CLI --emulatorHost=host:port
//  2) variable d'entorn FIRESTORE_EMULATOR_HOST
//  3) valor per defecte 127.0.0.1:8088
// -----------------------------------------------------------------------------
// Support per passar el host per CLI: `node ... scripts/seed_registry.ts --emulatorHost=127.0.0.1:8086`
const cliArg = process.argv.find((a) => a.startsWith('--emulatorHost='));
if (cliArg) {
  const host = cliArg.split('=')[1];
  process.env.FIRESTORE_EMULATOR_HOST = host;
  console.log(`⚙️  FIRESTORE_EMULATOR_HOST definit via CLI: ${host}`);
} else if (process.env.FIRESTORE_EMULATOR_HOST) {
  console.log(`⚙️  FIRESTORE_EMULATOR_HOST pres (env): ${process.env.FIRESTORE_EMULATOR_HOST}`);
} else {
  // Default updated to 8088 (matches emulator invocation used in this repo)
  process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8088';
  console.log('⚙️  FIRESTORE_EMULATOR_HOST no definit. S’estableix a 127.0.0.1:8088 (valor per defecte)');
}

// Inicialitza l’SDK d’Admin sense credencials reals si es treballa amb l’emulador
if (!admin.apps.length) {
  admin.initializeApp({ projectId: 'el-visionat' });
}
const db = admin.firestore();

// -----------------------------------------------------------------------------
// Tipus base per a les dades d’origen (raw JSON)
// -----------------------------------------------------------------------------
interface RawRefereeData {
  cognoms: string;
  nom: string;
  licencia: string;
  categoria: string;
  rrtt: string;
}

// -----------------------------------------------------------------------------
// 🧠 Funció principal: Llegeix JSON, transforma i carrega a Firestore
// -----------------------------------------------------------------------------
async function seedRegistry() {
  console.log('--- Iniciant Càrrega Massiva de Dades de Llicències (Seeding) ---');

  // 1️⃣ Llegim l’arxiu JSON
  const jsonPath = path.join(__dirname, 'registre_complet.json');
  let rawData: RawRefereeData[];

  try {
    const fileContent = fs.readFileSync(jsonPath, 'utf8');
    rawData = JSON.parse(fileContent);
    console.log(`i  S'han llegit ${rawData.length} registres de l'arxiu JSON.`);
  } catch (error: any) {
    console.error(`❌ ERROR: No s'ha pogut llegir l'arxiu 'registre_complet.json'.`);
    console.error(`Detall: ${error.message}`);
    return;
  }

  // 2️⃣ Preparació per a la càrrega massiva
  const registryCollection = db.collection('referees_registry');
  let batch = db.batch();
  let operations = 0;

  // 3️⃣ Processar cada registre
  for (const rawReferee of rawData) {
    if (!rawReferee.licencia || !rawReferee.nom || !rawReferee.cognoms) {
      console.warn(`⚠️  Saltant registre invàlid: ${JSON.stringify(rawReferee)}`);
      continue;
    }

    const cleanedLicencia = String(rawReferee.licencia).trim();
    const categoriaCompleta = `${rawReferee.categoria ? String(rawReferee.categoria).trim() : ''} ${rawReferee.rrtt ? String(rawReferee.rrtt).trim() : ''}`.trim();

    const transformedData: RefereeLicenseProfile = {
      llissenciaId: cleanedLicencia,
      nom: String(rawReferee.nom).trim(),
      cognoms: String(rawReferee.cognoms).trim(),
      categoriaRrtt: categoriaCompleta,
      accountStatus: 'pending',
    };

    const docRef = registryCollection.doc(transformedData.llissenciaId);
    batch.set(docRef, transformedData);
    operations++;

    // 🔁 Cada 499 registres, fem commit del lot
    if (operations % 499 === 0) {
      await batch.commit();
      console.log(`i  Lot de 499 registres carregat... (Total: ${operations})`);
      batch = db.batch();
    }
  }

  // 4️⃣ Commit final (els registres restants)
  try {
    await batch.commit();
    console.log(`✅ ÈXIT: S'han carregat un total de ${operations} registres a 'referees_registry'.`);
    console.log('----------------------------------------------------');
  } catch (error) {
    console.error('❌ Error durant la càrrega massiva (batch commit):', error);
  }
}

// -----------------------------------------------------------------------------
// ▶ Execució
// -----------------------------------------------------------------------------
seedRegistry()
  .then(() => console.log('🏁 Càrrega finalitzada correctament.'))
  .catch((err) => {
    console.error('❌ Error inesperat durant l’execució:', err);
  });
