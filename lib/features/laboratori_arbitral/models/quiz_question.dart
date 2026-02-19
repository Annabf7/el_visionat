import 'package:cloud_firestore/cloud_firestore.dart';

enum QuizCategory {
  reglament, // Preguntes teòriques del llibre de regles
  interpretacions, // Situacions de joc del llibre d'interpretacions
  reglamentBase, // Base
  reglamentJurisdiccional, // Jurisdiccional
  general, // Altres (Legacy, preferible no usar)
  mecanica, // Legacy
}

class QuizQuestion {
  final String id;
  final String question; // La "Situació" o pregunta tècnica
  final List<String> options; // Possibles decisions
  final int correctOptionIndex;
  final String explanation; // La "Interpretació" oficial
  final String reference; // Legacy reference string
  final QuizCategory category;
  final bool active;
  final int difficulty;
  final List<String> tags;

  // Nous camps per a la versió 2.0 (Estructura Oficial)
  final String source; // "reglament", "interpretacions", etc.
  final int ruleNumber;
  final int articleNumber;
  final String articleTitle;
  final String? caseNumber;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
    required this.reference,
    required this.category,
    this.active = true,
    this.difficulty = 1,
    this.tags = const [],
    this.source = 'general',
    this.ruleNumber = 0,
    this.articleNumber = 0,
    this.articleTitle = '',
    this.caseNumber,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as String,
      question: json['question'] as String,
      options: List<String>.from(json['options'] ?? []),
      correctOptionIndex: json['correctOptionIndex'] as int,
      explanation: json['explanation'] as String,
      reference: json['reference'] ?? '',
      category: QuizCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => QuizCategory.general,
      ),
      active: json['active'] ?? true,
      difficulty: json['difficulty'] ?? 1,
      tags: List<String>.from(json['tags'] ?? []),
      source: json['source'] ?? 'general',
      ruleNumber: json['ruleNumber'] ?? 0,
      articleNumber: json['articleNumber'] ?? 0,
      articleTitle: json['articleTitle'] ?? '',
      caseNumber: json['caseNumber'],
    );
  }

  factory QuizQuestion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuizQuestion.fromJson({...data, 'id': doc.id});
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'explanation': explanation,
      'reference': reference,
      'category': category.name,
      'active': active,
      'difficulty': difficulty,
      'tags': tags,
      'source': source,
      'ruleNumber': ruleNumber,
      'articleNumber': articleNumber,
      'articleTitle': articleTitle,
      'caseNumber': caseNumber,
    };
  }

  QuizQuestion copyWith({List<String>? options, int? correctOptionIndex}) {
    return QuizQuestion(
      id: id,
      question: question,
      options: options ?? this.options,
      correctOptionIndex: correctOptionIndex ?? this.correctOptionIndex,
      explanation: explanation,
      reference: reference,
      category: category,
      active: active,
      source: source,
      articleNumber: articleNumber,
      articleTitle: articleTitle,
      caseNumber: caseNumber,
    );
  }
}
