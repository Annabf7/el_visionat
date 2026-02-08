import 'package:cloud_firestore/cloud_firestore.dart';

/// Categories adaptades a la vida d'un àrbitre
enum TimeBlockCategory {
  arbitratge, // Partits, formació arbitral
  gimnas, // Entrenament físic
  feina, // Treball professional
  estudi, // Formació, universitat
  familia, // Temps familiar
  descans, // Recuperació, oci
  amiguis, // Quedades amb amics
  time4me, // Temps per a mi
}

/// Prioritats segons metodologia Eat That Frog
enum TimeBlockPriority {
  frog, // LA granota del dia (1 sola)
  alta, // Tasques importants
  mitja, // Tasques normals
  baixa, // Si queda temps
}

/// Origen del bloc
enum TimeBlockSource {
  manual, // Creat manualment
  nightlyPlanner, // Creat amb "Planifica demà"
  designation, // Auto-importat de designacions (futur)
}

class TimeBlock {
  final String? id;
  final String title;
  final TimeBlockCategory category;
  final TimeBlockPriority priority;
  final DateTime startAt;
  final DateTime endAt;
  final bool done;
  final TimeBlockSource source;
  final bool isRecurring;
  final String? recurringId;
  final DateTime createdAt;
  final DateTime updatedAt;

  TimeBlock({
    this.id,
    required this.title,
    required this.category,
    required this.priority,
    required this.startAt,
    required this.endAt,
    this.done = false,
    this.source = TimeBlockSource.manual,
    this.isRecurring = false,
    this.recurringId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Duració en minuts
  int get durationMinutes => endAt.difference(startAt).inMinutes;

  /// És la granota del dia?
  bool get isFrog => priority == TimeBlockPriority.frog;

  /// Còpia amb modificacions
  TimeBlock copyWith({
    String? id,
    String? title,
    TimeBlockCategory? category,
    TimeBlockPriority? priority,
    DateTime? startAt,
    DateTime? endAt,
    bool? done,
    TimeBlockSource? source,
    bool? isRecurring,
    String? recurringId,
  }) {
    return TimeBlock(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      done: done ?? this.done,
      source: source ?? this.source,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringId: recurringId ?? this.recurringId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Conversió a Map per Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category.name,
      'priority': priority.name,
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'done': done,
      'source': source.name,
      'isRecurring': isRecurring,
      if (recurringId != null) 'recurringId': recurringId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  /// Constructor des de Firestore
  factory TimeBlock.fromMap(String id, Map<String, dynamic> map) {
    return TimeBlock(
      id: id,
      title: map['title'] ?? '',
      category: TimeBlockCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => TimeBlockCategory.feina,
      ),
      priority: TimeBlockPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => TimeBlockPriority.mitja,
      ),
      startAt: (map['startAt'] as Timestamp).toDate(),
      endAt: (map['endAt'] as Timestamp).toDate(),
      done: map['done'] ?? false,
      source: TimeBlockSource.values.firstWhere(
        (e) => e.name == map['source'],
        orElse: () => TimeBlockSource.manual,
      ),
      isRecurring: map['isRecurring'] ?? false,
      recurringId: map['recurringId'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
