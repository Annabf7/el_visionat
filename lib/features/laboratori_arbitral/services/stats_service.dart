import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class StatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> logAnswer({
    required String questionId,
    required bool isCorrect,
    required String? articleNumber, // Opcional, per tracking per article
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final batch = _firestore.batch();
    final timestamp = FieldValue.serverTimestamp();

    // 1. Log individual answer (History)
    final historyRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('quiz_history')
        .doc(); // Auto-id

    batch.set(historyRef, {
      'questionId': questionId,
      'isCorrect': isCorrect,
      'timestamp': timestamp,
      'articleNumber': articleNumber,
    });

    // 2. Update Global Question Stats (Transaction for computed fields)
    final globalStatsRef = _firestore
        .collection('questions_stats')
        .doc(questionId);

    _firestore
        .runTransaction((transaction) async {
          final snapshot = await transaction.get(globalStatsRef);

          int total = 0;
          int correct = 0;
          int incorrect = 0;

          if (snapshot.exists) {
            final data = snapshot.data() as Map<String, dynamic>;
            total = data['totalAnswers'] ?? 0;
            correct = data['correctAnswers'] ?? 0;
            incorrect = data['incorrectAnswers'] ?? 0;
          }

          total++;
          if (isCorrect) {
            correct++;
          } else {
            incorrect++;
          }

          double incorrectRate = (total > 0) ? (incorrect / total) : 0.0;

          transaction.set(globalStatsRef, {
            'totalAnswers': total,
            'correctAnswers': correct,
            'incorrectAnswers': incorrect,
            'incorrectRate': incorrectRate,
            'lastUpdated': timestamp,
          }, SetOptions(merge: true));
        })
        .then(
          (_) => debugPrint("Stats updated successfully"),
          onError: (e) => debugPrint("Transaction failed: $e"),
        );

    // 3. Update User Article Stats (si tenim article)
    if (articleNumber != null) {
      final userArticleStatsRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('quiz_stats_by_article')
          .doc(articleNumber.toString());

      batch.set(userArticleStatsRef, {
        'articleNumber': articleNumber,
        'totalAnswers': FieldValue.increment(1),
        if (isCorrect) 'correctAnswers': FieldValue.increment(1),
        if (!isCorrect) 'incorrectAnswers': FieldValue.increment(1),
        'lastUpdated': timestamp,
      }, SetOptions(merge: true));
    }

    // 4. Update User Global Stats
    final userGlobalStatsRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('quiz_stats_global')
        .doc('summary');

    batch.set(userGlobalStatsRef, {
      'totalAnswers': FieldValue.increment(1),
      if (isCorrect) 'correctAnswers': FieldValue.increment(1),
      'streak': isCorrect ? FieldValue.increment(1) : 0, // Reset si falla
    }, SetOptions(merge: true));

    await batch.commit();
  }

  // Mètode per obtenir el % d'encert per article de l'usuari actual
  Future<Map<String, double>> getUserPerformanceByArticle() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('quiz_stats_by_article')
        .get();

    final Map<String, double> stats = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final total = data['totalAnswers'] as int? ?? 0;
      final correct = data['correctAnswers'] as int? ?? 0;

      if (total > 0) {
        stats[doc.id] = (correct / total) * 100; // Percentatge
      }
    }

    return stats;
  }
}
