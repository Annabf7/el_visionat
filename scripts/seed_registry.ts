import admin from 'firebase-admin';
import { type RefereeLicenseProfile } from './models';

// Utilitzem 'as any' i el model importat com a tipus per a evitar errors de compilació de ts-node

// Inicialitza l'SDK d'Admin de forma tolerant per a l'Emulador
if (admin.apps.length === 0) {
    admin.initializeApp({ projectId: 'el-visionat' });
}
const db = admin.firestore();

// Dades de prova (Àrbitres amb llicència vàlida)
// [CORRECCIÓ FINAL] - Eliminar la tipificació de línia aquí
const refereesToSeed: RefereeLicenseProfile[] = [
    {
        llissenciaId: '12483',
        email: 'rachid.abouchebat@elvisionat.com', // Correu que farem servir per al test d'èxit
        nom: 'Rachid',
        cognoms: 'Abouchebat Bouchlagam',
        categoriaRrtt: 'ÀRBITRE FCBQ C1 Barcelona',
        accountStatus: 'pending',
    },
    {
        llissenciaId: '99999',
        email: 'auxiliar.taula@elvisionat.com',
        nom: 'Anna',
        cognoms: 'Auxiliar',
        categoriaRrtt: 'AUXILIAR DE TAULA TT2',
        accountStatus: 'pending',
    },
];

/**
 * Funció principal que carrega les dades de llicència a l'emulador de Firestore.
 */
async function seedRegistry() {
    console.log('--- Iniciant Càrrega de Dades de Llicències (Seeding) ---');
    
    const batch = db.batch();
    const registryCollection = db.collection('referees_registry');

    for (const referee of refereesToSeed) {
        const docRef = registryCollection.doc(referee.llissenciaId);
        batch.set(docRef, referee);
    }

    try {
        await batch.commit();
        console.log(`✅ ${refereesToSeed.length} registres de llicència carregats a 'referees_registry'.`);
        console.log('----------------------------------------------------');
    } catch (error) {
        console.error('❌ Error durant el Seeding:', error);
    }
}

seedRegistry();

