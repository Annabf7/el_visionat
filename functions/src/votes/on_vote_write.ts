/**
 * 🔄 on_vote_write.ts
 *
 * Cloud Function trigger per al sistema de votacions de **El Visionat**.
 *
 * Aquesta funció manté sincronitzada la col·lecció `vote_counts` amb els documents de `votes`:
 *  - Quan un usuari crea un document de vot → incrementa el comptador corresponent al partit.
 *  - Quan un usuari actualitza el seu vot cap a un altre partit → decrementa el comptador de l’antic i incrementa el del nou.
 *  - Quan un usuari elimina el seu vot → decrementa el comptador del partit corresponent.
 *
 * La funció garanteix:
 *  ✅ Actualitzacions atòmiques mitjançant transaccions de Firestore.
 *  ✅ Els comptadors no poden quedar mai per sota de zero.
 *  ✅ No es produeixen dobles increments si el matchId no canvia.
 *
 * Camí del trigger:
 *   votes/{voteId}   on voteId = <jornada>_<userId>
 *
 * Documents afectats:
 *   vote_counts/{jornada}_{matchId}  → { jornada, matchId, count }
 *
 * Exemple:
 *   L’usuari test123 vota pel partit A → vote_counts/14_matchA.count = 1
 *   El mateix usuari canvia al partit B → A es decrementa, B s’incrementa.
 *   L’usuari elimina el seu vot → B es decrementa fins tornar a 0.
 */



import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { getFirestore } from 'firebase-admin/firestore';

const db = getFirestore();

/**
 * Firestore trigger: keeps vote_counts in sync whenever a vote document is created, updated or deleted.
 * One vote per (user, jornada). Each change adjusts counters for the affected matches.
 */
export const onVoteWrite = onDocumentWritten('votes/{voteId}', async (event) => {
  const before = event.data?.before?.data() as Record<string, any> | undefined;
  const after = event.data?.after?.data() as Record<string, any> | undefined;

  // Helper to extract jornada + matchId
  const parse = (d?: Record<string, any>) => {
    if (!d) return null;
    const jornada = typeof d.jornada === 'number' ? d.jornada : Number(d.jornada);
    const matchId = typeof d.matchId === 'string' ? d.matchId : null;
    if (!jornada || !matchId) return null;
    return { jornada, matchId };
  };

  const beforeInfo = parse(before);
  const afterInfo = parse(after);

  // If nothing meaningful -> skip
  if (!beforeInfo && !afterInfo) {
    console.log('[onVoteWrite] No relevant data, skipping.');
    return;
  }

  // 🧠 Avoid doing anything if the matchId didn't actually change
  if (
    beforeInfo &&
    afterInfo &&
    beforeInfo.jornada === afterInfo.jornada &&
    beforeInfo.matchId === afterInfo.matchId
  ) {
    console.log('[onVoteWrite] matchId unchanged, skipping.');
    return;
  }

  await db.runTransaction(async (tx) => {
    // Read all needed docs first (Firestore requires all reads before writes in a transaction)
    const refsToRead: Array<import('firebase-admin/firestore').DocumentReference> = [];
    let beforeRef = null;
    let afterRef = null;
    if (beforeInfo) {
      const id = `${beforeInfo.jornada}_${beforeInfo.matchId}`;
      beforeRef = db.collection('vote_counts').doc(id);
      refsToRead.push(beforeRef);
    }
    if (afterInfo) {
      const id = `${afterInfo.jornada}_${afterInfo.matchId}`;
      afterRef = db.collection('vote_counts').doc(id);
      // avoid duplicate read if same as beforeRef (shouldn't happen because we skip unchanged above)
      if (!beforeRef || beforeRef.path !== afterRef.path) refsToRead.push(afterRef);
    }

    const snaps = await Promise.all(refsToRead.map((r) => tx.get(r)));

    // Map snaps back to before/after
    const snapMap = new Map<string, import('firebase-admin/firestore').DocumentSnapshot>();
    refsToRead.forEach((r, i) => snapMap.set(r.path, snaps[i]));

    // 1️⃣ Decrement old match if exists
    if (beforeInfo && beforeRef) {
      const snap = snapMap.get(beforeRef.path)!;
      const current = snap.exists ? (snap.data()?.count || 0) : 0;
      const next = Math.max(0, current - 1);
      if (snap.exists) {
        tx.update(beforeRef, { count: next });
      } else {
        tx.set(beforeRef, { jornada: beforeInfo.jornada, matchId: beforeInfo.matchId, count: next });
      }
      console.log(`[onVoteWrite] decremented ${beforeRef.id} -> ${next}`);
    }

    // 2️⃣ Increment new match if exists
    if (afterInfo && afterRef) {
      const snap = snapMap.get(afterRef.path)!;
      const current = snap.exists ? (snap.data()?.count || 0) : 0;
      const next = current + 1;
      if (snap.exists) {
        tx.update(afterRef, { count: next });
      } else {
        tx.set(afterRef, { jornada: afterInfo.jornada, matchId: afterInfo.matchId, count: next });
      }
      console.log(`[onVoteWrite] incremented ${afterRef.id} -> ${next}`);
    }
  });
});
