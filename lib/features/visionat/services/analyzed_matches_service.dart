import 'package:cloud_firestore/cloud_firestore.dart';

/// Servei centralitzat per gestionar el tracking de partits analitzats
///
/// Un partit es considera "analitzat" quan l'usuari fa QUALSEVOL d'aquestes accions:
/// 1. Click a l'enllaç del vídeo del partit
/// 2. Crea un apunt personal
/// 3. Crea un comentari col·lectiu
/// 4. Crea/comparteix un clip del partit
///
/// Aquest servei garanteix que cada partit només es compta UNA vegada,
/// independentment de quantes accions faci l'usuari.
class AnalyzedMatchesService {
  final FirebaseFirestore _firestore;

  AnalyzedMatchesService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Col·lecció per guardar els partits analitzats per cada usuari
  /// Estructura: analyzed_matches/{userId}/matches/{matchId}
  CollectionReference _getCollection(String userId) {
    return _firestore
        .collection('analyzed_matches')
        .doc(userId)
        .collection('entries');
  }

  /// Marca un partit com analitzat per l'usuari
  ///
  /// Aquesta funció:
  /// - Comprova si el partit ja està marcat com analitzat
  /// - Si és nou, l'afegeix a la llista i incrementa el comptador
  /// - Si ja existeix, no fa res (idempotent)
  ///
  /// [userId] - ID de l'usuari
  /// [matchId] - ID del partit
  /// [action] - Acció que va provocar el tracking (per logging/debug)
  Future<void> markMatchAsAnalyzed(
    String userId,
    String matchId, {
    String action = 'unknown',
  }) async {
    try {
      final matchDocRef = _getCollection(userId).doc(matchId);

      // Verificar si el partit ja està marcat
      final matchDoc = await matchDocRef.get();

      if (matchDoc.exists) {
        // El partit ja estava analitzat, no cal fer res
        return;
      }

      // Crear el document del partit analitzat
      await matchDocRef.set({
        'matchId': matchId,
        'analyzedAt': FieldValue.serverTimestamp(),
        'firstAction': action, // Guardem quina acció va marcar-lo primer
      });

      // Incrementar el comptador d'analyzedMatches a l'usuari
      await _firestore.collection('users').doc(userId).update({
        'analyzedMatches': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Error marcant partit com analitzat: ${e.toString()}');
    }
  }

  /// Desmarca un partit com analitzat (útil si s'eliminen TOTES les accions)
  ///
  /// NOTA: Normalment no es crida directament. S'utilitza quan l'usuari
  /// elimina totes les seves interaccions amb un partit.
  Future<void> unmarkMatchAsAnalyzed(String userId, String matchId) async {
    try {
      final matchDocRef = _getCollection(userId).doc(matchId);

      // Verificar si el partit està marcat
      final matchDoc = await matchDocRef.get();

      if (!matchDoc.exists) {
        // El partit no estava analitzat, no cal fer res
        return;
      }

      // Eliminar el document del partit analitzat
      await matchDocRef.delete();

      // Decrementar el comptador d'analyzedMatches a l'usuari
      await _firestore.collection('users').doc(userId).update({
        'analyzedMatches': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Error desmarcant partit com analitzat: ${e.toString()}');
    }
  }

  /// Comprova si un partit ja està marcat com analitzat
  Future<bool> isMatchAnalyzed(String userId, String matchId) async {
    try {
      final matchDoc = await _getCollection(userId).doc(matchId).get();
      return matchDoc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Obté tots els partits analitzats per un usuari
  Future<List<String>> getAnalyzedMatches(String userId) async {
    try {
      final querySnapshot = await _getCollection(userId).get();
      return querySnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      throw Exception('Error obtenint partits analitzats: ${e.toString()}');
    }
  }

  /// Reseteja tots els partits analitzats d'un usuari (útil per testing)
  Future<void> resetAllAnalyzedMatches(String userId) async {
    try {
      final querySnapshot = await _getCollection(userId).get();

      // Eliminar tots els documents
      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Resetear el comptador a 0
      await _firestore.collection('users').doc(userId).update({
        'analyzedMatches': 0,
      });
    } catch (e) {
      throw Exception('Error resetejant partits analitzats: ${e.toString()}');
    }
  }
}
