/**
 * Script per debugar les notificacions de Jordi Aliaga
 */

import admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

const JORDI_UID = 'cDgEwM2VymQ7vDIjxslSY2aL4cj2';

async function debugNotifications() {
  console.log('🔍 Debugant notificacions per Jordi Aliaga...\n');
  console.log(`UID de Jordi: ${JORDI_UID}\n`);

  try {
    // 1. Verificar que l'usuari existeix
    const userDoc = await db.collection('users').doc(JORDI_UID).get();

    if (!userDoc.exists) {
      console.error('❌ L\'usuari Jordi Aliaga no existeix!');
      return;
    }

    const userData = userDoc.data();
    console.log('✅ Usuari trobat:');
    console.log(`   Nom: ${userData.displayName}`);
    console.log(`   Email: ${userData.email}`);
    console.log(`   Llicència: ${userData.llissenciaId}`);
    console.log(`   Categoria: ${userData.categoriaRrtt}`);

    // 2. Buscar notificacions per userId
    console.log('\n📬 Buscant notificacions per userId...');

    const notificationsSnapshot = await db.collection('notifications')
      .where('userId', '==', JORDI_UID)
      .get();

    console.log(`   Trobades: ${notificationsSnapshot.size} notificacions\n`);

    if (notificationsSnapshot.empty) {
      console.log('❌ No s\'han trobat notificacions amb aquest userId');

      // Buscar totes les notificacions per veure si n'hi ha amb userId diferent
      const allNotifications = await db.collection('notifications')
        .limit(10)
        .get();

      console.log(`\n🔍 Total de notificacions al sistema: ${allNotifications.size}`);

      if (!allNotifications.empty) {
        console.log('\n📋 Notificacions existents:');
        allNotifications.forEach(doc => {
          const data = doc.data();
          console.log(`   - ${doc.id}:`);
          console.log(`     userId: ${data.userId}`);
          console.log(`     type: ${data.type}`);
          console.log(`     title: ${data.title}`);

          // Comparar userId
          if (data.userId === JORDI_UID) {
            console.log('     ✅ Aquest userId coincideix amb Jordi!');
          } else {
            console.log(`     ❌ Aquest userId NO coincideix (esperat: ${JORDI_UID})`);
          }
          console.log('');
        });
      }
    } else {
      // Mostrar notificacions trobades
      notificationsSnapshot.forEach(doc => {
        const notification = doc.data();
        const createdAt = notification.createdAt?.toDate?.() || notification.createdAt;

        console.log(`   📩 ${doc.id}:`);
        console.log(`      Tipus: ${notification.type}`);
        console.log(`      Títol: ${notification.title}`);
        console.log(`      Missatge: ${notification.message}`);
        console.log(`      Highlight ID: ${notification.data?.highlightId}`);
        console.log(`      Match ID: ${notification.data?.matchId}`);
        console.log(`      Llegida: ${notification.isRead ? 'Sí' : 'No'}`);
        console.log(`      Creada: ${createdAt}`);
        console.log(`      Expira: ${notification.expiresAt?.toDate?.()}`);
        console.log('');
      });
    }

    // 3. Verificar l'índex necessari
    console.log('\n🔍 Verificant si pots fer queries amb orderBy...');
    try {
      const orderedQuery = await db.collection('notifications')
        .where('userId', '==', JORDI_UID)
        .orderBy('createdAt', 'desc')
        .limit(1)
        .get();

      console.log('✅ Query amb orderBy funciona correctament');
      console.log(`   Resultats: ${orderedQuery.size}`);
    } catch (error) {
      console.error('❌ Error amb query orderBy:');
      console.error(`   ${error.message}`);
      if (error.message.includes('index')) {
        console.log('\n⚠️  Cal crear un índex a Firestore!');
        console.log('   Obre el link que apareix a l\'error per crear-lo automàticament');
      }
    }

  } catch (error) {
    console.error('❌ Error:', error);
  }
}

debugNotifications()
  .then(() => process.exit(0))
  .catch(error => {
    console.error('❌ Error:', error);
    process.exit(1);
  });
