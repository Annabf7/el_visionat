import 'package:cloud_firestore/cloud_firestore.dart';

/// Grau d'assoliment d'una valoració
enum AssessmentGrade {
  optim,
  satisfactori,
  acceptable,
  millorable,
  noValorable;

  String get displayName {
    switch (this) {
      case AssessmentGrade.optim:
        return 'Òptim';
      case AssessmentGrade.satisfactori:
        return 'Satisfactori';
      case AssessmentGrade.acceptable:
        return 'Acceptable';
      case AssessmentGrade.millorable:
        return 'Millorable';
      case AssessmentGrade.noValorable:
        return 'No valorable';
    }
  }

  static AssessmentGrade fromString(String value) {
    switch (value.toLowerCase()) {
      case 'òptim':
      case 'optim':
        return AssessmentGrade.optim;
      case 'satisfactori':
        return AssessmentGrade.satisfactori;
      case 'acceptable':
        return AssessmentGrade.acceptable;
      case 'millorable':
        return AssessmentGrade.millorable;
      default:
        return AssessmentGrade.noValorable;
    }
  }
}

/// Categoria d'avaluació dins d'un informe
class AssessmentCategory {
  final String categoryName;
  final AssessmentGrade grade;
  final String? description;

  AssessmentCategory({
    required this.categoryName,
    required this.grade,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'categoryName': categoryName,
      'grade': grade.name,
      'description': description,
    };
  }

  factory AssessmentCategory.fromMap(Map<String, dynamic> map) {
    return AssessmentCategory(
      categoryName: map['categoryName'] ?? '',
      grade: AssessmentGrade.fromString(map['grade'] ?? ''),
      description: map['description'],
    );
  }
}

/// Punt de millora identificat en un informe
class ImprovementPoint {
  final String categoryName;
  final String description;
  final AssessmentGrade currentGrade;
  final bool isResolved;

  ImprovementPoint({
    required this.categoryName,
    required this.description,
    required this.currentGrade,
    this.isResolved = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'categoryName': categoryName,
      'description': description,
      'currentGrade': currentGrade.name,
      'isResolved': isResolved,
    };
  }

  factory ImprovementPoint.fromMap(Map<String, dynamic> map) {
    return ImprovementPoint(
      categoryName: map['categoryName'] ?? '',
      description: map['description'] ?? '',
      currentGrade: AssessmentGrade.fromString(map['currentGrade'] ?? ''),
      isResolved: map['isResolved'] ?? false,
    );
  }
}

/// Model per un informe d'arbitratge
class RefereeReport {
  final String id;
  final String userId;
  final String? matchId;
  final DateTime date;
  final String competition;
  final String teams;
  final String evaluator;
  final AssessmentGrade finalGrade;
  final List<AssessmentCategory> categories;
  final List<ImprovementPoint> improvementPoints;
  final String comments;
  final String? pdfUrl;
  final DateTime createdAt;

  RefereeReport({
    required this.id,
    required this.userId,
    this.matchId,
    required this.date,
    required this.competition,
    required this.teams,
    required this.evaluator,
    required this.finalGrade,
    required this.categories,
    required this.improvementPoints,
    required this.comments,
    this.pdfUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'matchId': matchId,
      'date': Timestamp.fromDate(date),
      'competition': competition,
      'teams': teams,
      'evaluator': evaluator,
      'finalGrade': finalGrade.name,
      'categories': categories.map((c) => c.toMap()).toList(),
      'improvementPoints': improvementPoints.map((p) => p.toMap()).toList(),
      'comments': comments,
      'pdfUrl': pdfUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory RefereeReport.fromMap(Map<String, dynamic> map, String documentId) {
    return RefereeReport(
      id: documentId,
      userId: map['userId'] ?? '',
      matchId: map['matchId'],
      date: (map['date'] as Timestamp).toDate(),
      competition: map['competition'] ?? '',
      teams: map['teams'] ?? '',
      evaluator: map['evaluator'] ?? '',
      finalGrade: AssessmentGrade.fromString(map['finalGrade'] ?? ''),
      categories: (map['categories'] as List<dynamic>? ?? [])
          .map((c) => AssessmentCategory.fromMap(c as Map<String, dynamic>))
          .toList(),
      improvementPoints: (map['improvementPoints'] as List<dynamic>? ?? [])
          .map((p) => ImprovementPoint.fromMap(p as Map<String, dynamic>))
          .toList(),
      comments: map['comments'] ?? '',
      pdfUrl: map['pdfUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  factory RefereeReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RefereeReport.fromMap(data, doc.id);
  }
}
