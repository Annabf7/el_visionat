import admin from 'firebase-admin';
import fs from 'fs'; // Mòdul 'File System' per llegir arxius
import path from 'path';
import { fileURLToPath } from 'url'; // Per obtenir __dirname en mòduls ESM
import { type RefereeLicenseProfile } from './models.js'; // Importació de tipus ESM

// Obtenció de rutes en entorns ESM (necessari per a la funció fs.readFileSync)
// NOTA: Afegeix ".js" al final de la importació de './models' si TypeScript es queixa.
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Tipus per a les dades crues del JSON (el format que arriba de l'extracció del PDF)
interface RawRefereeData {
  cognoms: string;
  nom: string;
  licencia: string;
  categoria: string;
  rrtt: string;
}

// Inicialitza l'SDK d'Admin per a l'Emulador
if (admin.apps.length === 0) {
  admin.initializeApp({ projectId: 'el-visionat' });
}
const db = admin.firestore();

/**
 * Funció principal que llegeix el JSON, transforma les dades i les carrega a Firestore.
 */
async function seedRegistry() {
  console.log('--- Iniciant Càrrega Massiva de Dades de Llicències (Seeding) ---');

  // 1. Llegir l'arxiu JSON
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

  const registryCollection = db.collection('referees_registry');
  let batch = db.batch();
  let operations = 0;

  // 2. Transformar i afegir al lot (Batch)
  for (const rawReferee of rawData) {
    // Validació simple de dades
    if (!rawReferee.licencia || !rawReferee.nom || !rawReferee.cognoms) {
      console.warn(`⚠️  Saltant registre invàlid (falta llicència, nom o cognoms): ${JSON.stringify(rawReferee)}`);
      continue;
    }
    
    const cleanedLicencia = String(rawReferee.licencia).trim();
    const categoriaCompleta = `${rawReferee.categoria ? String(rawReferee.categoria).trim() : ''} ${rawReferee.rrtt ? String(rawReferee.rrtt).trim() : ''}`.trim();

    // Transformem les dades del JSON al nostre model de Firestore
    // El camp 'email' no s'inclou, ja que és opcional (marcat amb '?')
    const transformedData: RefereeLicenseProfile = {
      llissenciaId: cleanedLicencia,
      nom: String(rawReferee.nom).trim(),
      cognoms: String(rawReferee.cognoms).trim(),
      categoriaRrtt: categoriaCompleta,
      accountStatus: 'pending', // Estat inicial per a tots
    };

    // Fem servir la llicència com a ID del document
    const docRef = registryCollection.doc(transformedData.llissenciaId);
    batch.set(docRef, transformedData);
    operations++;

    // Firestore limita els lots a 500 operacions.
    // Creem un nou lot cada 499 escriptures.
    if (operations > 0 && operations % 499 === 0) {
      await batch.commit();
      console.log(`i  Lot de 499 registres carregat... (Total: ${operations})`);
      batch = db.batch(); // Reiniciem el lot
    }
  }

  // 3. Enviar l'últim lot (els registres restants)
  try {
    await batch.commit();
    console.log(`✅ ÈXIT: S'han carregat un total de ${operations} registres a 'referees_registry'.`);
    console.log('----------------------------------------------------');
  } catch (error) {
    console.error('❌ Error durant la càrrega massiva (batch commit):', error);
  }
}

seedRegistry();
