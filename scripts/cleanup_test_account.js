/**
 * Script per netejar un compte de prova i poder repetir el flux de registre.
 * 
 * Ús: node scripts/cleanup_test_account.js <llicenciaId o email>
 * 
 * Accions:
 * 1. Elimina l'usuari de Firebase Auth (si existeix)
 * 2. Elimina el document de /users/{uid}
 * 3. Actualitza /referees_registry/{llicenciaId} accountStatus a "pending"
 * 4. Elimina documents de /registration_requests amb aquesta llicència
 */

import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';

// Inicialitzar Firebase Admin amb Application Default Credentials
initializeApp({
  credential: applicationDefault(),
  projectId: 'el-visionat',
});

const db = getFirestore();
const auth = getAuth();

async function cleanupAccount(identifier) {
  console.log(`\n🔍 Cercant compte amb identificador: ${identifier}\n`);
  
  let email = null;
  let llicenciaId = null;
  let uid = null;

  // Determinar si és email o llicència
  if (identifier.includes('@')) {
    email = identifier.toLowerCase();
  } else {
    llicenciaId = identifier;
  }

  // 1. Si tenim llicència, busquem al registre
  if (llicenciaId) {
    const registryDoc = await db.collection('referees_registry').doc(llicenciaId).get();
    if (registryDoc.exists) {
      const data = registryDoc.data();
      email = data.email?.toLowerCase();
      console.log(`✅ Trobat al registre: ${data.nom} ${data.cognoms} (${email})`);
      console.log(`   Estat actual: ${data.accountStatus}`);
    } else {
      console.log(`❌ Llicència ${llicenciaId} no trobada al registre`);
      return;
    }
  }

  // 2. Buscar usuari a Firebase Auth per email
  if (email) {
    try {
      const userRecord = await auth.getUserByEmail(email);
      uid = userRecord.uid;
      console.log(`✅ Usuari trobat a Auth: ${uid}`);
    } catch (e) {
      if (e.code === 'auth/user-not-found') {
        console.log(`ℹ️  No hi ha usuari a Firebase Auth amb aquest email`);
      } else {
        console.error(`❌ Error cercant usuari:`, e.message);
      }
    }
  }

  // 3. Si tenim UID, buscar el document a /users per obtenir la llicència
  if (uid) {
    const userDoc = await db.collection('users').doc(uid).get();
    if (userDoc.exists) {
      const userData = userDoc.data();
      if (!llicenciaId && userData.llissenciaId) {
        llicenciaId = userData.llissenciaId;
        console.log(`✅ Llicència obtinguda del perfil: ${llicenciaId}`);
      }
    }
  }

  // Confirmar abans d'eliminar
  console.log(`\n⚠️  S'eliminaran les següents dades:`);
  if (uid) console.log(`   - Usuari Auth: ${uid}`);
  if (uid) console.log(`   - Document /users/${uid}`);
  if (llicenciaId) console.log(`   - Registration requests per llicència: ${llicenciaId}`);
  if (llicenciaId) console.log(`   - Actualitzar /referees_registry/${llicenciaId} a "pending"`);
  
  console.log(`\n🚀 Procedint amb la neteja...\n`);

  // 4. Eliminar usuari de Firebase Auth
  if (uid) {
    try {
      await auth.deleteUser(uid);
      console.log(`✅ Usuari eliminat de Firebase Auth`);
    } catch (e) {
      console.error(`❌ Error eliminant usuari de Auth:`, e.message);
    }
  }

  // 5. Eliminar document de /users/{uid}
  if (uid) {
    try {
      await db.collection('users').doc(uid).delete();
      console.log(`✅ Document /users/${uid} eliminat`);
    } catch (e) {
      console.error(`❌ Error eliminant document d'usuari:`, e.message);
    }
  }

  // 6. Eliminar registration_requests associades
  if (llicenciaId) {
    try {
      const requestsQuery = await db.collection('registration_requests')
        .where('llissenciaId', '==', llicenciaId)
        .get();
      
      if (!requestsQuery.empty) {
        const batch = db.batch();
        requestsQuery.docs.forEach(doc => {
          batch.delete(doc.ref);
        });
        await batch.commit();
        console.log(`✅ ${requestsQuery.size} registration_request(s) eliminades`);
      } else {
        console.log(`ℹ️  No hi havia registration_requests per aquesta llicència`);
      }
    } catch (e) {
      console.error(`❌ Error eliminant registration_requests:`, e.message);
    }
  }

  // 7. Actualitzar accountStatus a "pending" al registre
  if (llicenciaId) {
    try {
      await db.collection('referees_registry').doc(llicenciaId).update({
        accountStatus: 'pending'
      });
      console.log(`✅ /referees_registry/${llicenciaId} actualitzat a "pending"`);
    } catch (e) {
      console.error(`❌ Error actualitzant registre:`, e.message);
    }
  }

  console.log(`\n🎉 Neteja completada! Ara pots tornar a registrar-te amb aquesta llicència.\n`);
}

// Executar
const identifier = process.argv[2];

if (!identifier) {
  console.log(`
Ús: node scripts/cleanup_test_account.js <llicenciaId o email>

Exemples:
  node scripts/cleanup_test_account.js 12345
  node scripts/cleanup_test_account.js anna@example.com
`);
  process.exit(1);
}

cleanupAccount(identifier)
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('Error:', err);
    process.exit(1);
  });
