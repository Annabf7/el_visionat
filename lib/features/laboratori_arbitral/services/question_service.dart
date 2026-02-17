import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quiz_question.dart';

class QuestionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'quiz_questions';
  static const String _statsCollection = 'questions_stats';

  /// Recupera preguntes específiques d'un Article o Font
  Future<List<QuizQuestion>> getQuestionsByFilter({
    String? source,
    int? articleNumber,
    int limit = 10,
  }) async {
    Query query = _firestore
        .collection(_collection)
        .where('active', isEqualTo: true);

    if (source != null && source != 'general') {
      query = query.where('source', isEqualTo: source);
    }

    if (articleNumber != null) {
      query = query.where('articleNumber', isEqualTo: articleNumber);
    }

    // Nota: Firestore requereix índexs compostos per filtres múltiples + limit
    // Si no existeix l'índex, llençarà error amb URL per crear-lo.

    // Si filtrem per source/article, no podem fer shuffle directe a la query
    // sense un camp randòmic. Per simplicitat:
    // 1. Agafem un lot més gran (ex: 50)
    // 2. Barregem localment
    // 3. Tornem 'limit'

    // Però com diu el prompt "lazy loading", potser millor no agafar-ne moltes.
    // L'ideal seria fer servir un camp 'randomId' però usem l'estratègia simple ara.

    final snapshot = await query.limit(50).get(); // Agafem fins a 50 candidates

    final questions = snapshot.docs
        .map((doc) => QuizQuestion.fromFirestore(doc))
        .toList();

    questions.shuffle();
    return questions.take(limit).toList();
  }

  /// Recupera preguntes variades de qualsevol font
  Future<List<QuizQuestion>> getMixedQuestions({int limit = 10}) async {
    // Per obtenir varietat real sense un índex aleatori complex:
    // Fem 2 queries paral·leles petites a diferents punts o simplement
    // agafem les últimes/primeres (o random seed si tinguéssim).

    // Estratègia simple: Agafar les 50 primeres actives i barrejar.
    // Millora futura: Afegeix camp 'random' a cada document (0..1)

    return getQuestionsByFilter(limit: limit);
  }

  /// Recupera les preguntes més fallades globalment
  Future<List<QuizQuestion>> getMostFailedQuestions({int limit = 25}) async {
    // 1. Obternir IDs de les preguntes més fallades des de 'questions_stats'
    final statsSnapshot = await _firestore
        .collection(_statsCollection)
        .orderBy('incorrectRate', descending: true)
        .where(
          'totalAnswers',
          isGreaterThan: 5,
        ) // Mínim de dades significatives
        .limit(limit)
        .get();

    if (statsSnapshot.docs.isEmpty) {
      // Fallback: Si no hi ha prou dades, retornem aleatòries
      return getMixedQuestions(limit: limit);
    }

    // 2. Recuperar els detalls de les preguntes (IDs)
    // Firestore no permet "whereIn" amb més de 10 IDs fàcilment si volem preservar ordre
    // o si són molts. Amb 25, podem fer:
    // a) 25 gets individuals (en paral·lel) -> Més ràpid que sembla
    // b) where('id', whereIn: ids) -> Màxim 30 items

    final ids = statsSnapshot.docs.map((doc) => doc.id).toList();

    if (ids.isEmpty) return [];

    // Usem chunks de 10 per whereIn o split
    // Però sent <30, podem fer whereIn directament (límit és 30)
    // NOTA: whereIn NO garanteix ordre. Haurem reordenar si volem l'ordre de dificultat.

    // Per assegurar consistència i simplicitat:
    final List<QuizQuestion> questions = [];

    // Opció A: Gets individuals (garanteix ordre del statsSnapshot)
    // Futures wait
    final futures = ids.map(
      (id) => _firestore.collection(_collection).doc(id).get(),
    );

    final docs = await Future.wait(futures);

    for (var doc in docs) {
      if (doc.exists) {
        questions.add(QuizQuestion.fromFirestore(doc));
      }
    }

    return questions;
  }

  /// Actualitza les opcions d'una pregunta (Mode Edició)
  Future<void> updateQuestionOptions({
    required String questionId,
    required List<String> options,
    required int correctIndex,
  }) async {
    await _firestore.collection(_collection).doc(questionId).update({
      'options': options,
      'correctOptionIndex': correctIndex,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
