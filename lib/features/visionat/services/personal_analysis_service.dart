import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/personal_analysis.dart';
import 'analyzed_matches_service.dart';

/// Servei per gestionar les operacions d'anàlisi personal amb Firestore
///
/// Responsable de:
/// - CRUD d'apunts personals d'usuaris
/// - Streams en temps real per categoria d'usuari
/// - Validacions i transformacions de dades
/// - Gestió d'errors i transaccions
class PersonalAnalysisService {
  final FirebaseFirestore _firestore;

  PersonalAnalysisService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Col·lecció base per anàlisi personal: personal_analysis/{userId}/entries/{analysisId}
  CollectionReference<PersonalAnalysis> _getCollection(String userId) {
    return _firestore
        .collection('personal_analysis')
        .doc(userId)
        .collection('entries')
        .withConverter<PersonalAnalysis>(
          fromFirestore: PersonalAnalysis.fromFirestore,
          toFirestore: PersonalAnalysis.toFirestore,
        );
  }

  /// Obté stream d'apunts personals d'un usuari ordenats per data de creació
  Stream<List<PersonalAnalysis>> streamForUser(String userId) {
    return _getCollection(userId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Obté tots els apunts personals d'un usuari
  Future<List<PersonalAnalysis>> getForUser(String userId) async {
    try {
      final querySnapshot = await _getCollection(
        userId,
      ).orderBy('createdAt', descending: false).get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error obtenint apunts personals: ${e.toString()}');
    }
  }

  /// Obté apunts personals d'un usuari per a un partit específic
  Future<List<PersonalAnalysis>> getForUserAndMatch(
    String userId,
    String matchId,
  ) async {
    try {
      final querySnapshot = await _getCollection(userId)
          .where('matchId', isEqualTo: matchId)
          .orderBy('createdAt', descending: false)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error obtenint apunts del partit: ${e.toString()}');
    }
  }

  /// Afegeix un nou apunt personal
  Future<void> addAnalysis(PersonalAnalysis analysis) async {
    if (!analysis.isValid) {
      throw Exception('L\'apunt personal no té les dades mínimes requerides');
    }

    try {
      // Generar ID únic si no en té
      final docRef = analysis.id.isEmpty
          ? _getCollection(analysis.userId).doc()
          : _getCollection(analysis.userId).doc(analysis.id);

      final analysisWithId = analysis.copyWith(id: docRef.id);

      await docRef.set(analysisWithId);

      // Incrementar comptador d'apunts personals
      await _firestore.collection('users').doc(analysis.userId).update({
        'personalNotesCount': FieldValue.increment(1),
      });

      // Tracking: Marcar partit com analitzat (gestiona automàticament si és nou)
      final analyzedMatchesService = AnalyzedMatchesService();
      await analyzedMatchesService.markMatchAsAnalyzed(
        analysis.userId,
        analysis.matchId,
        action: 'personal_note',
      );
    } catch (e) {
      throw Exception('Error afegint apunt personal: ${e.toString()}');
    }
  }

  /// Actualitza un apunt personal existent amb transacció
  Future<void> updateAnalysis(PersonalAnalysis analysis) async {
    if (!analysis.isValid) {
      throw Exception('L\'apunt personal no té les dades mínimes requerides');
    }

    try {
      final docRef = _getCollection(analysis.userId).doc(analysis.id);

      await _firestore.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);

        if (!docSnapshot.exists) {
          throw Exception('L\'apunt personal no existeix');
        }

        final existingAnalysis = docSnapshot.data()!;

        // Verificar que l'usuari és el propietari
        if (existingAnalysis.userId != analysis.userId) {
          throw Exception('No tens permisos per editar aquest apunt');
        }

        // Marcar com editat si el contingut ha canviat
        final updatedAnalysis = analysis.copyWith(
          createdAt: existingAnalysis.createdAt, // Mantenir data original
          isEdited:
              analysis.text != existingAnalysis.text ||
              !_listEquals(analysis.tags, existingAnalysis.tags),
          editedAt: DateTime.now(),
        );

        transaction.update(docRef, updatedAnalysis.toJson());
      });
    } catch (e) {
      throw Exception('Error actualitzant apunt personal: ${e.toString()}');
    }
  }

  /// Elimina un apunt personal específic
  Future<void> deleteAnalysis(String userId, String analysisId) async {
    try {
      final docRef = _getCollection(userId).doc(analysisId);

      // Primer obtenir l'apunt per saber el matchId
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        throw Exception('L\'apunt personal no existeix');
      }

      final analysis = docSnapshot.data()!;

      // Verificar que l'usuari és el propietari
      if (analysis.userId != userId) {
        throw Exception('No tens permisos per eliminar aquest apunt');
      }

      await _firestore.runTransaction((transaction) async {
        transaction.delete(docRef);

        // Decrementar només el comptador d'apunts personals
        // NOTA: No desmarquem el partit com analitzat perquè l'usuari
        // realment el va analitzar. Un cop analitzat, es manté així.
        final userRef = _firestore.collection('users').doc(userId);
        transaction.update(userRef, {
          'personalNotesCount': FieldValue.increment(-1),
        });
      });
    } catch (e) {
      throw Exception('Error eliminant apunt personal: ${e.toString()}');
    }
  }

  /// Elimina tots els apunts personals d'un usuari
  Future<void> deleteAllForUser(String userId) async {
    try {
      final collection = _getCollection(userId);
      final querySnapshot = await collection.get();
      final totalCount = querySnapshot.docs.length;

      // Eliminar en batches per evitar límits de Firestore
      const batchSize = 500;
      final batches = <WriteBatch>[];
      var currentBatch = _firestore.batch();
      var operationsInBatch = 0;

      for (final doc in querySnapshot.docs) {
        if (operationsInBatch >= batchSize) {
          batches.add(currentBatch);
          currentBatch = _firestore.batch();
          operationsInBatch = 0;
        }

        currentBatch.delete(doc.reference);
        operationsInBatch++;
      }

      if (operationsInBatch > 0) {
        batches.add(currentBatch);
      }

      // Executar tots els batches
      for (final batch in batches) {
        await batch.commit();
      }

      // Resetejar el comptador d'apunts personals a 0
      // NOTA: No resetegem analyzedMatches perquè els partits analitzats
      // es mantenen (l'usuari realment els va analitzar)
      if (totalCount > 0) {
        await _firestore.collection('users').doc(userId).update({
          'personalNotesCount': 0,
        });
      }
    } catch (e) {
      throw Exception('Error eliminant tots els apunts: ${e.toString()}');
    }
  }

  /// Obté estadístiques d'apunts per usuari
  Future<Map<String, dynamic>> getStatsForUser(String userId) async {
    try {
      final analyses = await getForUser(userId);

      final tagCount = <AnalysisTag, int>{};
      final categoryCount = <AnalysisCategory, int>{};
      final monthlyCount = <String, int>{};

      for (final analysis in analyses) {
        // Comptar tags
        for (final tag in analysis.tags) {
          tagCount[tag] = (tagCount[tag] ?? 0) + 1;
          categoryCount[tag.category] = (categoryCount[tag.category] ?? 0) + 1;
        }

        // Comptar per mes
        final monthKey =
            '${analysis.createdAt.year}-${analysis.createdAt.month.toString().padLeft(2, '0')}';
        monthlyCount[monthKey] = (monthlyCount[monthKey] ?? 0) + 1;
      }

      return {
        'totalAnalyses': analyses.length,
        'tagCount': tagCount.map((tag, countValue) => MapEntry(tag.value, countValue)),
        'categoryCount': categoryCount.map(
          (cat, countValue) => MapEntry(cat.value, countValue),
        ),
        'monthlyCount': monthlyCount,
        'averageWordsPerAnalysis': analyses.isEmpty
            ? 0
            : analyses
                      .map((a) => a.text.split(' ').length)
                      .reduce((a, b) => a + b) /
                  analyses.length,
      };
    } catch (e) {
      throw Exception('Error obtenint estadístiques: ${e.toString()}');
    }
  }

  /// Helper per comparar llistes de tags
  bool _listEquals(List<AnalysisTag> a, List<AnalysisTag> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Neteja recursos (cancel·la streams actius si n'hi ha)
  void dispose() {
    // En aquest servei no hi ha streams persistents per netegar
    // però es manté el mètode per consistència amb altres serveis
  }
}
