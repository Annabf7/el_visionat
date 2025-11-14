import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/highlight_entry.dart';

/// Servei per gestionar highlights de partits a Firestore
///
/// Estructura de col·lecció: highlights/{matchId}/{highlightId}
/// Proporciona operacions CRUD amb streams en temps real
class HighlightService {
  final FirebaseFirestore _firestore;

  HighlightService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Referència a la col·lecció d'highlights d'un partit específic
  CollectionReference<HighlightEntry> _highlightsCollection(String matchId) {
    return _firestore
        .collection('highlights')
        .doc(matchId)
        .collection('entries')
        .withConverter<HighlightEntry>(
          fromFirestore: HighlightEntry.fromFirestore,
          toFirestore: HighlightEntry.toFirestore,
        );
  }

  /// Stream d'highlights en temps real per un partit específic
  /// Ordenats per createdAt ascendent (cronològic)
  Stream<List<HighlightEntry>> streamHighlights(String matchId) {
    return _highlightsCollection(
      matchId,
    ).orderBy('createdAt', descending: false).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  /// Afegeix un nou highlight a Firestore
  /// Si entry.id està buit, genera un ID automàticament
  Future<void> addHighlight(HighlightEntry entry) async {
    try {
      final collection = _highlightsCollection(entry.matchId);

      // Si no té ID, generar-ne un automàticament
      if (entry.id.isEmpty) {
        final docRef = collection.doc();
        final entryWithId = entry.copyWith(id: docRef.id);
        await docRef.set(entryWithId);
      } else {
        // Usar l'ID existent
        await collection.doc(entry.id).set(entry);
      }
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
  Future<List<HighlightEntry>> getHighlights(String matchId) async {
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
