import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/monthly_battle.dart';
import '../models/quiz_question.dart';

class MonthlyBattleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'monthly_battles';
  static const String _questionsCollection = 'quiz_questions';

  /// Obté la batalla del mes actual (o null si no n'hi ha)
  Future<MonthlyBattle?> getCurrentBattle() async {
    final now = DateTime.now();
    final yearMonth =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final doc = await _firestore.collection(_collection).doc(yearMonth).get();
    if (!doc.exists) return null;
    return MonthlyBattle.fromFirestore(doc);
  }

  /// Comprova si l'usuari ja ha jugat la batalla
  Future<BattleResult?> getUserResult(String battleId, String uid) async {
    final doc = await _firestore
        .collection(_collection)
        .doc(battleId)
        .collection('results')
        .doc(uid)
        .get();

    if (!doc.exists) return null;
    return BattleResult.fromFirestore(doc);
  }

  /// Carrega les preguntes de la batalla pels seus IDs
  Future<List<QuizQuestion>> loadBattleQuestions(
      List<String> questionIds) async {
    final List<QuizQuestion> questions = [];

    final futures = questionIds.map(
      (id) => _firestore.collection(_questionsCollection).doc(id).get(),
    );

    final docs = await Future.wait(futures);

    for (var doc in docs) {
      if (doc.exists) {
        questions.add(QuizQuestion.fromFirestore(doc));
      }
    }

    return questions;
  }

  /// Guarda el resultat i incrementa el comptador de participants
  Future<void> submitResult(String battleId, BattleResult result) async {
    final resultRef = _firestore
        .collection(_collection)
        .doc(battleId)
        .collection('results')
        .doc(result.userId);

    final battleRef = _firestore.collection(_collection).doc(battleId);

    // Transaction per garantir consistència del comptador
    await _firestore.runTransaction((transaction) async {
      final battleSnap = await transaction.get(battleRef);
      if (!battleSnap.exists) return;

      // Verificar que no ha jugat ja (seguretat extra)
      final existingResult = await transaction.get(resultRef);
      if (existingResult.exists) return;

      transaction.set(resultRef, result.toJson());
      transaction.update(battleRef, {
        'participantCount': FieldValue.increment(1),
      });
    });
  }

  /// Crea la batalla del mes actual seleccionant 10 preguntes amb opcions.
  /// Si no hi ha prou preguntes amb opcions, agafa les primeres disponibles.
  Future<void> createCurrentMonthBattle() async {
    final now = DateTime.now();
    final yearMonth =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    // Comprovar si ja existeix
    final existing =
        await _firestore.collection(_collection).doc(yearMonth).get();
    if (existing.exists) return; // Ja existeix, no sobreescrivim

    // Buscar preguntes actives
    final snapshot = await _firestore
        .collection(_questionsCollection)
        .where('active', isEqualTo: true)
        .limit(100)
        .get();

    // Prioritzar preguntes amb opcions (>= 2)
    final withOptions = snapshot.docs.where((doc) {
      final options = doc.data()['options'] as List<dynamic>?;
      return options != null && options.length >= 2;
    }).toList();

    // Si no n'hi ha prou amb opcions, agafem les que hi hagi
    final candidates =
        withOptions.length >= 10 ? withOptions : snapshot.docs.toList();

    candidates.shuffle();
    final selectedIds = candidates.take(10).map((d) => d.id).toList();

    if (selectedIds.isEmpty) return;

    final startsAt = DateTime(now.year, now.month, 1);
    final endsAt = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    const months = [
      '', 'Gener', 'Febrer', 'Març', 'Abril', 'Maig', 'Juny',
      'Juliol', 'Agost', 'Setembre', 'Octubre', 'Novembre', 'Desembre',
    ];

    await _firestore.collection(_collection).doc(yearMonth).set({
      'yearMonth': yearMonth,
      'title': 'Batalla de ${months[now.month]} ${now.year}',
      'questionIds': selectedIds,
      'startsAt': Timestamp.fromDate(startsAt),
      'endsAt': Timestamp.fromDate(endsAt),
      'createdAt': Timestamp.fromDate(now),
      'participantCount': 0,
    });
  }

  /// Obté el rànquing ordenat per score (desc) i temps (asc)
  Future<List<BattleResult>> getRanking(String battleId, {int limit = 50}) async {
    final snapshot = await _firestore
        .collection(_collection)
        .doc(battleId)
        .collection('results')
        .orderBy('score', descending: true)
        .orderBy('totalTimeMs')
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => BattleResult.fromFirestore(doc))
        .toList();
  }
}
