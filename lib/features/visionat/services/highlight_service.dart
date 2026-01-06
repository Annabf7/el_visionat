import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/highlight_entry.dart';
import '../models/highlight_play.dart';

/// Servei per gestionar highlights de partits a Firestore
///
/// Estructura de col·lecció: highlights/{matchId}/{highlightId}
/// Proporciona operacions CRUD amb streams en temps real
class HighlightService {
  final FirebaseFirestore _firestore;

  HighlightService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Referència a la col·lecció d'highlights d'un partit específic
  CollectionReference<HighlightPlay> _highlightsCollection(String matchId) {
    return _firestore
        .collection('entries')
        .doc(matchId)
        .collection('entries')
        .withConverter<HighlightPlay>(
          fromFirestore: HighlightPlay.fromFirestore,
          toFirestore: HighlightPlay.toFirestore,
        );
  }

  /// Stream d'highlights en temps real per un partit específic
  /// Ordenats per createdAt ascendent (cronològic)
  Stream<List<HighlightPlay>> streamHighlights(String matchId) {
    return _highlightsCollection(
      matchId,
    ).orderBy('createdAt', descending: false).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  /// Afegeix un nou highlight a Firestore
  /// Si entry.id està buit, genera un ID automàticament
  /// Afegeix automàticament els camps per reaccions i comentaris
  Future<void> addHighlight(HighlightEntry entry) async {
    try {
      final collection = _highlightsCollection(entry.matchId);

      // Si no té ID, generar-ne un automàticament
      final docRef = entry.id.isEmpty ? collection.doc() : collection.doc(entry.id);
      final entryWithId = entry.id.isEmpty ? entry.copyWith(id: docRef.id) : entry;

      // Afegir camps de HighlightPlay per suportar reaccions
      final dataWithReactions = {
        ...entryWithId.toJson(),
        'reactions': [],
        'reactionsSummary': {
          'likeCount': 0,
          'importantCount': 0,
          'controversialCount': 0,
          'totalCount': 0,
        },
        'commentCount': 0,
        'status': 'open',
      };

      await _firestore
          .collection('entries')
          .doc(entry.matchId)
          .collection('entries')
          .doc(docRef.id)
          .set(dataWithReactions);
    } catch (e) {
      throw Exception('Error afegint highlight: $e');
    }
  }

  /// Elimina un highlight específic
  Future<void> deleteHighlight(String matchId, String highlightId) async {
    try {
      await _highlightsCollection(matchId).doc(highlightId).delete();
    } catch (e) {
      throw Exception('Error eliminant highlight: $e');
    }
  }

  /// Obté un highlight específic (mètode auxiliar)
  Future<HighlightEntry?> getHighlight(
    String matchId,
    String highlightId,
  ) async {
    try {
      final doc = await _highlightsCollection(matchId).doc(highlightId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      throw Exception('Error obtenint highlight: $e');
    }
  }

  /// Obté tots els highlights d'un partit (snapshot únic, no stream)
  Future<List<HighlightPlay>> getHighlights(String matchId) async {
    try {
      final snapshot = await _highlightsCollection(
        matchId,
      ).orderBy('createdAt', descending: false).get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error obtenint highlights: $e');
    }
  }

  /// Actualitza un highlight existent
  Future<void> updateHighlight(HighlightEntry entry) async {
    try {
      await _highlightsCollection(
        entry.matchId,
      ).doc(entry.id).update(entry.toJson());
    } catch (e) {
      throw Exception('Error actualitzant highlight: $e');
    }
  }

  /// Elimina tots els highlights d'un partit
  Future<void> deleteAllHighlights(String matchId) async {
    try {
      final snapshot = await _highlightsCollection(matchId).get();
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error eliminant tots els highlights: $e');
    }
  }

  /// Compta el nombre d'highlights d'un partit
  Future<int> countHighlights(String matchId) async {
    try {
      final snapshot = await _highlightsCollection(matchId).get();
      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Error comptant highlights: $e');
    }
  }
}
