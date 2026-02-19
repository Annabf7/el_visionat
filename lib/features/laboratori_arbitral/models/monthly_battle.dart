import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa una batalla mensual de reglament
class MonthlyBattle {
  final String yearMonth; // "2026-02"
  final String title;
  final List<String> questionIds; // 10 IDs fixes per a tots els participants
  final DateTime startsAt;
  final DateTime endsAt;
  final DateTime createdAt;
  final int participantCount;

  const MonthlyBattle({
    required this.yearMonth,
    required this.title,
    required this.questionIds,
    required this.startsAt,
    required this.endsAt,
    required this.createdAt,
    this.participantCount = 0,
  });

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startsAt) && now.isBefore(endsAt);
  }

  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endsAt)) return 0;
    return endsAt.difference(now).inDays;
  }

  factory MonthlyBattle.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MonthlyBattle(
      yearMonth: data['yearMonth'] ?? doc.id,
      title: data['title'] ?? '',
      questionIds: List<String>.from(data['questionIds'] ?? []),
      startsAt: (data['startsAt'] as Timestamp).toDate(),
      endsAt: (data['endsAt'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      participantCount: data['participantCount'] ?? 0,
    );
  }
}

/// Resultat d'un participant a la batalla
class BattleResult {
  final String userId;
  final String displayName;
  final int score; // Encerts sobre 10
  final int totalTimeMs; // Temps total en mil·lisegons
  final List<BattleAnswer> answers;
  final DateTime completedAt;

  const BattleResult({
    required this.userId,
    required this.displayName,
    required this.score,
    required this.totalTimeMs,
    required this.answers,
    required this.completedAt,
  });

  String get formattedTime {
    final seconds = totalTimeMs ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }

  factory BattleResult.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BattleResult(
      userId: data['userId'] ?? doc.id,
      displayName: data['displayName'] ?? 'Àrbitre',
      score: data['score'] ?? 0,
      totalTimeMs: data['totalTimeMs'] ?? 0,
      answers: (data['answers'] as List<dynamic>?)
              ?.map((a) => BattleAnswer.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      completedAt:
          (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'score': score,
      'totalTimeMs': totalTimeMs,
      'answers': answers.map((a) => a.toJson()).toList(),
      'completedAt': Timestamp.fromDate(completedAt),
    };
  }
}

/// Resposta individual dins d'una batalla
class BattleAnswer {
  final String questionId;
  final int selectedIndex;
  final bool correct;
  final int timeMs;

  const BattleAnswer({
    required this.questionId,
    required this.selectedIndex,
    required this.correct,
    required this.timeMs,
  });

  factory BattleAnswer.fromJson(Map<String, dynamic> json) {
    return BattleAnswer(
      questionId: json['questionId'] ?? '',
      selectedIndex: json['selectedIndex'] ?? -1,
      correct: json['correct'] ?? false,
      timeMs: json['timeMs'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'selectedIndex': selectedIndex,
      'correct': correct,
      'timeMs': timeMs,
    };
  }
}
