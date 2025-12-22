/**
 * Script per crear/reparar el document de perfil d'un usuari existent
 * Útil quan l'usuari existeix a Auth però no té document a /users/
 */

import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';

initializeApp({
  credential: applicationDefault(),
  projectId: 'el-visionat',
});

const db = getFirestore();
const auth = getAuth();

async function fixUserProfile(email) {
  console.log(`\n🔧 Reparant perfil per: ${email}\n`);
  
  const normalizedEmail = email.toLowerCase();
  
  // 1. Obtenir usuari de Firebase Auth
  let userRecord;
  try {
    userRecord = await auth.getUserByEmail(normalizedEmail);
    console.log(`✅ Usuari trobat a Auth: ${userRecord.uid}`);
    console.log(`   DisplayName: ${userRecord.displayName}`);
  } catch (e) {
    console.log(`❌ No hi ha usuari a Firebase Auth amb email: ${normalizedEmail}`);
    process.exit(1);
  }

  // 2. Verificar si ja té document a /users/
  const userDocRef = db.collection('users').doc(userRecord.uid);
  const userDoc = await userDocRef.get();
  
  if (userDoc.exists) {
    console.log(`\n📄 Document existent a /users/${userRecord.uid}:`);
    console.log(JSON.stringify(userDoc.data(), null, 2));
    
    // Verificar si li falta el gender
    const userData = userDoc.data();
    if (!userData.gender) {
      console.log('\n⚠️  El document no té gender! Buscant a registration_requests...');
      await updateMissingFields(userRecord, userDocRef, normalizedEmail);
    } else {
      console.log(`\n✅ Gender: ${userData.gender}`);
    }
  } else {
    console.log(`\n❌ No té document a /users/. Creant-lo...`);
    await createUserDocument(userRecord, normalizedEmail);
  }

  process.exit(0);
}

async function updateMissingFields(userRecord, userDocRef, email) {
  // Buscar registration_request per obtenir gender
  const requestsSnapshot = await db.collection('registration_requests')
    .where('email', '==', email)
    .limit(1)
    .get();
  
  let gender = 'male';
  if (!requestsSnapshot.empty) {
    const requestData = requestsSnapshot.docs[0].data();
    gender = requestData.gender || 'male';
    console.log(`   Gender trobat a registration_request: ${gender}`);
  }
  
  await userDocRef.update({
    gender: gender,
  });
  console.log(`✅ Camp gender actualitzat a: ${gender}`);
}

async function createUserDocument(userRecord, email) {
  // Buscar informació a registration_requests i referees_registry
  const requestsSnapshot = await db.collection('registration_requests')
    .where('email', '==', email)
    .limit(1)
    .get();
  
  let llissenciaId = null;
  let gender = 'male';
  
  if (!requestsSnapshot.empty) {
    const requestData = requestsSnapshot.docs[0].data();
    llissenciaId = requestData.llissenciaId;
    gender = requestData.gender || 'male';
    console.log(`   Llicència: ${llissenciaId}`);
    console.log(`   Gender: ${gender}`);
  }
  
  // Buscar categoria al registre
  let categoriaRrtt = null;
  if (llissenciaId) {
    const registryDoc = await db.collection('referees_registry').doc(llissenciaId).get();
    if (registryDoc.exists) {
      categoriaRrtt = registryDoc.data().categoriaRrtt;
      console.log(`   Categoria: ${categoriaRrtt}`);
    }
  }
  
  // Crear el document
  const newUserProfile = {
    uid: userRecord.uid,
    email: email,
    displayName: userRecord.displayName || 'Usuari',
    role: 'referee',
    llissenciaId: llissenciaId,
    categoriaRrtt: categoriaRrtt,
    gender: gender,
    isSubscribed: false,
    createdAt: FieldValue.serverTimestamp(),
  };
  
  await db.collection('users').doc(userRecord.uid).set(newUserProfile);
  console.log(`\n✅ Document creat a /users/${userRecord.uid}:`);
  console.log(JSON.stringify(newUserProfile, null, 2));
  
  // Actualitzar estat al registre
  if (llissenciaId) {
    await db.collection('referees_registry').doc(llissenciaId).update({
      accountStatus: 'active'
    });
    console.log(`\n✅ accountStatus actualitzat a 'active' a referees_registry/${llissenciaId}`);
  }
  
  // Actualitzar status de la request
  if (!requestsSnapshot.empty) {
    await requestsSnapshot.docs[0].ref.update({
      status: 'completed'
    });
    console.log(`\n✅ status actualitzat a 'completed' a registration_requests`);
  }
}

const email = process.argv[2];
if (!email) {
  console.log('Ús: node scripts/fix_user_profile.js <email>');
  process.exit(1);
}

fixUserProfile(email).catch(console.error);
