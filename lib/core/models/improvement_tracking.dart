import 'package:cloud_firestore/cloud_firestore.dart';

/// Punt de millora agrupat per categoria (per seguiment temporal)
class CategoryImprovement {
  final String categoryName;
  final int occurrences;
  final List<String> descriptions;
  final DateTime lastOccurrence;
  final bool isImproving;

  CategoryImprovement({
    required this.categoryName,
    required this.occurrences,
    required this.descriptions,
    required this.lastOccurrence,
    this.isImproving = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'categoryName': categoryName,
      'occurrences': occurrences,
      'descriptions': descriptions,
      'lastOccurrence': Timestamp.fromDate(lastOccurrence),
      'isImproving': isImproving,
    };
  }

  factory CategoryImprovement.fromMap(Map<String, dynamic> map) {
    return CategoryImprovement(
      categoryName: map['categoryName'] ?? '',
      occurrences: map['occurrences'] ?? 0,
      descriptions: List<String>.from(map['descriptions'] ?? []),
      lastOccurrence: (map['lastOccurrence'] as Timestamp).toDate(),
      isImproving: map['isImproving'] ?? false,
    );
  }
}

/// Àrea feble detectada en tests
class WeakArea {
  final String category;
  final int totalQuestions;
  final int incorrectAnswers;
  final List<String> conflictiveTopics;
  final DateTime lastTest;

  WeakArea({
    required this.category,
    required this.totalQuestions,
    required this.incorrectAnswers,
    required this.conflictiveTopics,
    required this.lastTest,
  });

  /// Percentatge d'error en aquesta categoria
  double get errorRate => (incorrectAnswers / totalQuestions) * 100;

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'totalQuestions': totalQuestions,
      'incorrectAnswers': incorrectAnswers,
      'conflictiveTopics': conflictiveTopics,
      'lastTest': Timestamp.fromDate(lastTest),
    };
  }

  factory WeakArea.fromMap(Map<String, dynamic> map) {
    return WeakArea(
      category: map['category'] ?? '',
      totalQuestions: map['totalQuestions'] ?? 0,
      incorrectAnswers: map['incorrectAnswers'] ?? 0,
      conflictiveTopics: List<String>.from(map['conflictiveTopics'] ?? []),
      lastTest: (map['lastTest'] as Timestamp).toDate(),
    );
  }
}

/// Material d'estudi generat automàticament
class StudyMaterial {
  final String id;
  final String title;
  final String category;
  final String content;
  final List<String> relatedImprovements;
  final List<String> relatedQuestions;
  final DateTime generatedAt;

  StudyMaterial({
    required this.id,
    required this.title,
    required this.category,
    required this.content,
    required this.relatedImprovements,
    required this.relatedQuestions,
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'content': content,
      'relatedImprovements': relatedImprovements,
      'relatedQuestions': relatedQuestions,
      'generatedAt': Timestamp.fromDate(generatedAt),
    };
  }

  factory StudyMaterial.fromMap(Map<String, dynamic> map) {
    return StudyMaterial(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      content: map['content'] ?? '',
      relatedImprovements: List<String>.from(map['relatedImprovements'] ?? []),
      relatedQuestions: List<String>.from(map['relatedQuestions'] ?? []),
      generatedAt: (map['generatedAt'] as Timestamp).toDate(),
    );
  }
}

/// Seguiment d'evolució per temporada
class ImprovementTracking {
  final String id;
  final String userId;
  final String season;
  final List<CategoryImprovement> reportImprovements;
  final List<WeakArea> testWeakAreas;
  final List<StudyMaterial> studyMaterials;
  final DateTime updatedAt;

  ImprovementTracking({
    required this.id,
    required this.userId,
    required this.season,
    required this.reportImprovements,
    required this.testWeakAreas,
    required this.studyMaterials,
    required this.updatedAt,
  });

  /// Nombre total de punts de millora actius
  int get totalImprovementPoints {
    return reportImprovements.fold(
      0,
      (total, item) => total + item.occurrences,
    );
  }

  /// Nombre total d'àrees febles
  int get totalWeakAreas => testWeakAreas.length;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'season': season,
      'reportImprovements':
          reportImprovements.map((i) => i.toMap()).toList(),
      'testWeakAreas': testWeakAreas.map((w) => w.toMap()).toList(),
      'studyMaterials': studyMaterials.map((s) => s.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ImprovementTracking.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return ImprovementTracking(
      id: documentId,
      userId: map['userId'] ?? '',
      season: map['season'] ?? '',
      reportImprovements: (map['reportImprovements'] as List<dynamic>? ?? [])
          .map((i) => CategoryImprovement.fromMap(i as Map<String, dynamic>))
          .toList(),
      testWeakAreas: (map['testWeakAreas'] as List<dynamic>? ?? [])
          .map((w) => WeakArea.fromMap(w as Map<String, dynamic>))
          .toList(),
      studyMaterials: (map['studyMaterials'] as List<dynamic>? ?? [])
          .map((s) => StudyMaterial.fromMap(s as Map<String, dynamic>))
          .toList(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory ImprovementTracking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ImprovementTracking.fromMap(data, doc.id);
  }
}
