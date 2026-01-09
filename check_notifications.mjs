/**
 * Script per verificar les notificacions creades
 */

import admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

async function checkNotifications() {
  console.log('🔍 Verificant notificacions creades...\n');

  try {
    // Obtenir totes les notificacions recents
    const notificationsSnapshot = await db.collection('notifications')
      .limit(50)
      .get();

    console.log(`📬 Total de notificacions al sistema: ${notificationsSnapshot.size}\n`);

    if (notificationsSnapshot.empty) {
      console.log('❌ No hi ha cap notificació al sistema');
      console.log('\nPossibles causes:');
      console.log('1. La Cloud Function pot trigar uns segons més');
      console.log('2. No hi ha àrbitres ACB/FEB registrats');
      console.log('3. Hi ha un error a la Cloud Function');
      console.log('\nComprova els logs:');
      console.log('firebase functions:log --only notifyRefereesOnThreshold');
      return;
    }

    // Mostrar totes les notificacions
    notificationsSnapshot.forEach(doc => {
      const notification = doc.data();
      const createdAt = notification.createdAt?.toDate?.() || notification.createdAt;

      console.log(`📩 ${doc.id}:`);
      console.log(`   Usuari: ${notification.userId}`);
      console.log(`   Tipus: ${notification.type}`);
      console.log(`   Títol: ${notification.title}`);
      console.log(`   Missatge: ${notification.message}`);
      console.log(`   Highlight ID: ${notification.data?.highlightId || 'N/A'}`);
      console.log(`   Match ID: ${notification.data?.matchId || 'N/A'}`);
      console.log(`   Llegida: ${notification.isRead ? 'Sí' : 'No'}`);
      console.log(`   Creada: ${createdAt}`);
      console.log('');
    });

    // Comprovar si hi ha notificacions per Jordi Aliaga
    const jordiNotifications = notificationsSnapshot.docs.filter(doc => {
      const data = doc.data();
      return data.userId === 'cDgEwM2VymQ7vDIjxslSY2aL4cj2';
    });

    console.log(`\n👤 Notificacions per a Jordi Aliaga: ${jordiNotifications.length}`);

  } catch (error) {
    console.error('❌ Error:', error);
  }
}

checkNotifications()
  .then(() => process.exit(0))
  .catch(error => {
    console.error('❌ Error:', error);
    process.exit(1);
  });
