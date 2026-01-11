import 'package:cloud_firestore/cloud_firestore.dart';

/// Pregunta conflictiva (fallada) en un test
class ConflictiveQuestion {
  final int questionNumber;
  final String questionText;
  final String userAnswer;
  final String correctAnswer;
  final String explanation;
  final String category;

  ConflictiveQuestion({
    required this.questionNumber,
    required this.questionText,
    required this.userAnswer,
    required this.correctAnswer,
    required this.explanation,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionNumber': questionNumber,
      'questionText': questionText,
      'userAnswer': userAnswer,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'category': category,
    };
  }

  factory ConflictiveQuestion.fromMap(Map<String, dynamic> map) {
    return ConflictiveQuestion(
      questionNumber: map['questionNumber'] ?? 0,
      questionText: map['questionText'] ?? '',
      userAnswer: map['userAnswer'] ?? '',
      correctAnswer: map['correctAnswer'] ?? '',
      explanation: map['explanation'] ?? '',
      category: map['category'] ?? '',
    );
  }
}

/// Pregunta individual d'un test (per guardar totes les preguntes)
class TestQuestion {
  final int questionNumber;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final String? userAnswer;
  final bool isCorrect;
  final String explanation;
  final String category;

  TestQuestion({
    required this.questionNumber,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    this.userAnswer,
    required this.isCorrect,
    required this.explanation,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionNumber': questionNumber,
      'questionText': questionText,
      'options': options,
      'correctAnswer': correctAnswer,
      'userAnswer': userAnswer,
      'isCorrect': isCorrect,
      'explanation': explanation,
      'category': category,
    };
  }

  factory TestQuestion.fromMap(Map<String, dynamic> map) {
    return TestQuestion(
      questionNumber: map['questionNumber'] ?? 0,
      questionText: map['questionText'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correctAnswer'] ?? '',
      userAnswer: map['userAnswer'],
      isCorrect: map['isCorrect'] ?? false,
      explanation: map['explanation'] ?? '',
      category: map['category'] ?? '',
    );
  }
}

/// Model per un test teòric o físic
class RefereeTest {
  final String id;
  final String userId;
  final String testName;
  final DateTime date;
  final double score;
  final int timeSpentMinutes;
  final int totalQuestions;
  final int correctAnswers;
  final List<ConflictiveQuestion> conflictiveQuestions;
  final List<TestQuestion> allQuestions;
  final String? pdfUrl;
  final DateTime createdAt;
  final bool isTheoretical; // true = teòric, false = físic

  RefereeTest({
    required this.id,
    required this.userId,
    required this.testName,
    required this.date,
    required this.score,
    required this.timeSpentMinutes,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.conflictiveQuestions,
    required this.allQuestions,
    this.pdfUrl,
    required this.createdAt,
    this.isTheoretical = true,
  });

  /// Percentatge d'encert
  double get successRate => (correctAnswers / totalQuestions) * 100;

  /// Nombre de preguntes fallades
  int get incorrectAnswers => totalQuestions - correctAnswers;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'testName': testName,
      'date': Timestamp.fromDate(date),
      'score': score,
      'timeSpentMinutes': timeSpentMinutes,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'conflictiveQuestions':
          conflictiveQuestions.map((q) => q.toMap()).toList(),
      'allQuestions': allQuestions.map((q) => q.toMap()).toList(),
      'pdfUrl': pdfUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'isTheoretical': isTheoretical,
    };
  }

  factory RefereeTest.fromMap(Map<String, dynamic> map, String documentId) {
    return RefereeTest(
      id: documentId,
      userId: map['userId'] ?? '',
      testName: map['testName'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      score: (map['score'] ?? 0.0).toDouble(),
      timeSpentMinutes: map['timeSpentMinutes'] ?? 0,
      totalQuestions: map['totalQuestions'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
      conflictiveQuestions: (map['conflictiveQuestions'] as List<dynamic>? ?? [])
          .map((q) => ConflictiveQuestion.fromMap(q as Map<String, dynamic>))
          .toList(),
      allQuestions: (map['allQuestions'] as List<dynamic>? ?? [])
          .map((q) => TestQuestion.fromMap(q as Map<String, dynamic>))
          .toList(),
      pdfUrl: map['pdfUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isTheoretical: map['isTheoretical'] ?? true,
    );
  }

  factory RefereeTest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RefereeTest.fromMap(data, doc.id);
  }
}
