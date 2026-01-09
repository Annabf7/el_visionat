/**
 * Script per netejar les dades de test del sistema de notificacions
 * Elimina:
 * - Notificacions de test
 * - Reaccions fictícies del highlight
 * - Opcionalment, l'usuari de test Jordi Aliaga
 *
 * Ús: node cleanup_test_data.mjs [--delete-user]
 */

import admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

const JORDI_UID = 'cDgEwM2VymQ7vDIjxslSY2aL4cj2';
const TEST_MATCH_ID = 'match_123';
const TEST_HIGHLIGHT_ID = 'F2kg0A6KIsJhMgjzUFva';

async function cleanupTestData(deleteUser = false) {
  console.log('🧹 Iniciant neteja de dades de test...\n');

  try {
    // 1. Eliminar notificacions de Jordi Aliaga
    console.log('📬 Eliminant notificacions de Jordi Aliaga...');
    const notificationsSnapshot = await db.collection('notifications')
      .where('userId', '==', JORDI_UID)
      .get();

    if (!notificationsSnapshot.empty) {
      const batch = db.batch();
      notificationsSnapshot.forEach(doc => {
        batch.delete(doc.ref);
      });
      await batch.commit();
      console.log(`✅ ${notificationsSnapshot.size} notificacions eliminades`);
    } else {
      console.log('ℹ️  No hi ha notificacions per eliminar');
    }

    // 2. Restaurar l'estat del highlight
    console.log('\n🎯 Restaurant highlight de test...');
    const highlightRef = db
      .collection('entries')
      .doc(TEST_MATCH_ID)
      .collection('entries')
      .doc(TEST_HIGHLIGHT_ID);

    const highlightDoc = await highlightRef.get();

    if (highlightDoc.exists) {
      const data = highlightDoc.data();

      // Filtrar només les reaccions reals (les que NO tenen userId que comenci amb "test_user_")
      const realReactions = (data.reactions || []).filter(reaction =>
        !reaction.userId.startsWith('test_user_')
      );

      // Recalcular el resum
      let importantCount = 0;
      let likeCount = 0;
      let controversialCount = 0;

      realReactions.forEach(reaction => {
        if (reaction.type === 'important') importantCount++;
        else if (reaction.type === 'like') likeCount++;
        else if (reaction.type === 'controversial') controversialCount++;
      });

      const newSummary = {
        totalCount: realReactions.length,
        importantCount,
        likeCount,
        controversialCount
      };

      // Determinar nou estat
      const newStatus = realReactions.length >= 10 ? 'under_review' : 'open';

      await highlightRef.update({
        reactions: realReactions,
        reactionsSummary: newSummary,
        status: newStatus,
        reviewNotifiedAt: realReactions.length >= 10 ? admin.firestore.FieldValue.serverTimestamp() : admin.firestore.FieldValue.delete()
      });

      console.log(`✅ Highlight restaurat:`);
      console.log(`   Reaccions: ${data.reactions?.length} → ${realReactions.length}`);
      console.log(`   Estat: ${data.status} → ${newStatus}`);
    } else {
      console.log('⚠️  Highlight no trobat');
    }

    // 3. Opcionalment eliminar l'usuari Jordi Aliaga
    if (deleteUser) {
      console.log('\n👤 Eliminant usuari Jordi Aliaga...');

      // Eliminar de users
      const userDoc = await db.collection('users').doc(JORDI_UID).get();
      if (userDoc.exists) {
        await db.collection('users').doc(JORDI_UID).delete();
        console.log('✅ Usuari eliminat de users');
      }

      // Eliminar de registration_requests
      const registrationSnapshot = await db.collection('registration_requests')
        .where('llissenciaId', '==', '1771')
        .get();

      if (!registrationSnapshot.empty) {
        const batch = db.batch();
        registrationSnapshot.forEach(doc => {
          batch.delete(doc.ref);
        });
        await batch.commit();
        console.log('✅ Registre eliminat de registration_requests');
      }

      // Nota: NO eliminem de referees_registry perquè és data real de la FCBQ
      console.log('ℹ️  referees_registry NO s\'ha tocat (data real)');

      // Eliminar l'usuari de Firebase Auth
      try {
        await admin.auth().deleteUser(JORDI_UID);
        console.log('✅ Usuari eliminat de Firebase Auth');
      } catch (error) {
        if (error.code === 'auth/user-not-found') {
          console.log('ℹ️  Usuari ja no existeix a Firebase Auth');
        } else {
          console.error('❌ Error eliminant usuari de Firebase Auth:', error.message);
        }
      }
    } else {
      console.log('\nℹ️  Usuari Jordi Aliaga mantingut (usa --delete-user per eliminar-lo)');
    }

    console.log('\n✅ Neteja completada!');

  } catch (error) {
    console.error('\n❌ Error durant la neteja:', error);
  }
}

// Llegir arguments
const deleteUser = process.argv.includes('--delete-user');

if (deleteUser) {
  console.log('⚠️  ADVERTÈNCIA: S\'eliminarà l\'usuari Jordi Aliaga completament!\n');
}

cleanupTestData(deleteUser)
  .then(() => process.exit(0))
  .catch(error => {
    console.error('❌ Error:', error);
    process.exit(1);
  });
