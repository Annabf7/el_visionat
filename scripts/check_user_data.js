/**
 * Script per comprovar les dades d'un usuari a Firestore
 */

import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';

initializeApp({
  credential: applicationDefault(),
  projectId: 'el-visionat',
});

const db = getFirestore();
const auth = getAuth();

async function checkUserData(identifier) {
  console.log(`\n🔍 Cercant dades per: ${identifier}\n`);
  
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
      console.log(`📋 REFEREES_REGISTRY/${llicenciaId}:`);
      console.log(JSON.stringify(data, null, 2));
    } else {
      console.log(`❌ No trobat a referees_registry`);
    }
  }

  // 2. Buscar usuari a Firebase Auth per email
  if (email) {
    try {
      const userRecord = await auth.getUserByEmail(email);
      uid = userRecord.uid;
      console.log(`\n👤 FIREBASE AUTH:`);
      console.log(`   UID: ${uid}`);
      console.log(`   Email: ${userRecord.email}`);
      console.log(`   DisplayName: ${userRecord.displayName}`);
    } catch (e) {
      if (e.code === 'auth/user-not-found') {
        console.log(`\nℹ️  No hi ha usuari a Firebase Auth amb email: ${email}`);
      }
    }
  }

  // 3. Si tenim UID, mostrem el document /users/{uid}
  if (uid) {
    const userDoc = await db.collection('users').doc(uid).get();
    if (userDoc.exists) {
      const userData = userDoc.data();
      console.log(`\n📄 USERS/${uid}:`);
      console.log(JSON.stringify(userData, null, 2));
      
      // Destacar el camp gender
      console.log(`\n⚡ GENDER: ${userData.gender || '❌ NO DEFINIT!'}`);
    } else {
      console.log(`\n❌ No trobat document a /users/${uid}`);
    }
  }

  // 4. Buscar registration_requests
  if (llicenciaId) {
    const requestsSnapshot = await db.collection('registration_requests')
      .where('llissenciaId', '==', llicenciaId)
      .get();
    
    if (!requestsSnapshot.empty) {
      console.log(`\n📝 REGISTRATION_REQUESTS (${requestsSnapshot.size} documents):`);
      requestsSnapshot.forEach(doc => {
        console.log(`   ID: ${doc.id}`);
        console.log(JSON.stringify(doc.data(), null, 2));
      });
    }
  }

  console.log('\n✅ Fi de la consulta');
  process.exit(0);
}

const identifier = process.argv[2];
if (!identifier) {
  console.log('Ús: node scripts/check_user_data.js <llicenciaId o email>');
  process.exit(1);
}

checkUserData(identifier).catch(console.error);
