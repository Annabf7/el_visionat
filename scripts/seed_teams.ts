// scripts/seed_teams.ts
import admin from 'firebase-admin';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// [CORRECCIÓ 1] Importem l'enum de gènere directament des del seu fitxer font
// Handle CommonJS/ESM interop for imports from the functions package when running
// this script under `ts-node/esm`. Some compiled files under `functions/src`
// may be CommonJS, so import the default and extract the named export.
import { Timestamp } from 'firebase-admin/firestore';

// Instead of importing runtime types from the functions package (which may be
// compiled to CommonJS/TS and cause interop issues when running under
// ts-node/esm), declare a local lightweight type and use plain string values
// for gender. This avoids module-format problems when seeding from scripts.
type TeamGender = 'Masculina' | 'Femenina';

interface TeamType {
    id: string;
    name: string;
    acronym: string;
    gender: TeamGender;
    logoUrl: string;
    colorHex: string;
    lastUpdated: any;
}

// Obtenció de rutes en entorns ESM
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Interfície per a les dades crues del JSON
interface RawTeamData {
    id: string;
    name: string;
    acronym: string;
    gender: 'Masculina' | 'Femenina';
    colorHex: string;
    logoUrl: string;
}

// [CONNEXIÓ EMULADOR] Apuntem a Firestore local
process.env['FIRESTORE_EMULATOR_HOST'] = 'localhost:8080';

// Inicialitza l'SDK d'Admin per a l'Emulador
if (admin.apps.length === 0) {
    admin.initializeApp({ projectId: 'el-visionat' });
}
const db = admin.firestore();

/**
 * Funció principal que llegeix el JSON d'equips i els carrega a Firestore.
 */
async function seedTeamsRegistry() {
    console.log('--- Iniciant Càrrega Massiva de Dades d\'Equips (Seeding) ---');

    const jsonPath = path.join(__dirname, 'supercopa_teams.json');
    let rawData: RawTeamData[];
    try {
        const fileContent = fs.readFileSync(jsonPath, 'utf8');
        rawData = JSON.parse(fileContent);
        console.log(`i  S'han llegit ${rawData.length} registres d'equips.`);
    } catch (error: any) {
        console.error(`❌ ERROR: No s'ha pogut llegir l'arxiu 'supercopa_teams.json'.`);
        console.error(`Detall: ${error.message}`);
        return;
    }

    const teamCollection = db.collection('teams');
    let batch = db.batch();
    let operations = 0;

    // Utilitzem una marca de temps fixa per als equips per a futures comprovacions de sincronització
    const updateTime = Timestamp.now(); 

    // 2. Transformar i afegir al lot (Batch)
    for (const rawTeam of rawData) {
        if (!rawTeam.id || !rawTeam.name) {
            console.warn(`⚠️  Saltant registre d'equip invàlid: ${JSON.stringify(rawTeam)}`);
            continue;
        }
        
        // Transformem les dades del JSON al nostre model de Firestore
    const transformedData: TeamType = {
            id: rawTeam.id,
            name: rawTeam.name.trim(),
            acronym: rawTeam.acronym.trim(),
            gender: rawTeam.gender === 'Masculina' ? 'Masculina' : 'Femenina',
            logoUrl: rawTeam.logoUrl.trim(),
            colorHex: rawTeam.colorHex.trim(),
            lastUpdated: updateTime, // Utilitzem la marca de temps
        };

        // Fem servir l'ID definit al JSON com a ID del document
        const docRef = teamCollection.doc(transformedData.id);
        batch.set(docRef, transformedData);
        operations++;

        // Executem el lot si s'acosta al límit (500)
        if (operations > 0 && operations % 499 === 0) {
            await batch.commit();
            console.log(`i  Lot de 499 equips carregat... (Total: ${operations})`);
            batch = db.batch(); // Reiniciem el lot
        }
    }

    // 3. Enviar l'últim lot
    try {
        await batch.commit();
        console.log(`✅ ÈXIT: S'han carregat un total de ${operations} equips a la col·lecció 'teams'.`);
        console.log('----------------------------------------------------');
    } catch (error) {
        console.error('❌ Error durant la càrrega massiva d\'equips (batch commit):', error);
    }
}

seedTeamsRegistry();