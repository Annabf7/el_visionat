// ============================================================================
// HighlightReaction - Model per reaccions a jugades destacades
// ============================================================================
// Representa una reacció (like, important, controversial) d'un usuari
// a una jugada destacada del minutatge

import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipus de reacció a una jugada destacada
enum ReactionType {
  like, // M'agrada
  important, // Important per revisar
  controversial, // Controv èrsia / Debat
}

extension ReactionTypeExtension on ReactionType {
  String get value {
    switch (this) {
      case ReactionType.like:
        return 'like';
      case ReactionType.important:
        return 'important';
      case ReactionType.controversial:
        return 'controversial';
    }
  }

  String get displayName {
    switch (this) {
      case ReactionType.like:
        return 'M\'agrada';
      case ReactionType.important:
        return 'Important';
      case ReactionType.controversial:
        return 'Controvèrsia';
    }
  }

  String get iconName {
    switch (this) {
      case ReactionType.like:
        return 'thumb_up';
      case ReactionType.important:
        return 'priority_high';
      case ReactionType.controversial:
        return 'warning';
    }
  }

  static ReactionType fromValue(String value) {
    switch (value) {
      case 'like':
        return ReactionType.like;
      case 'important':
        return ReactionType.important;
      case 'controversial':
        return ReactionType.controversial;
      default:
        return ReactionType.like;
    }
  }
}

/// Reacció individual d'un usuari a una jugada
class HighlightReaction {
  final String userId;
  final ReactionType type;
  final DateTime createdAt;

  const HighlightReaction({
    required this.userId,
    required this.type,
    required this.createdAt,
  });

  /// Serialització a JSON per Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'type': type.value,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Deserialització des de JSON de Firestore
  static HighlightReaction fromJson(Map<String, dynamic> json) {
    return HighlightReaction(
      userId: json['userId'] as String,
      type: ReactionTypeExtension.fromValue(json['type'] as String),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  HighlightReaction copyWith({
    String? userId,
    ReactionType? type,
    DateTime? createdAt,
  }) {
    return HighlightReaction(
      userId: userId ?? this.userId,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Resum de totes les reaccions d'una jugada
/// S'emmagatzema dins de HighlightPlay per optimització
class ReactionsSummary {
  final int likeCount;
  final int importantCount;
  final int controversialCount;
  final int totalCount;

  const ReactionsSummary({
    this.likeCount = 0,
    this.importantCount = 0,
    this.controversialCount = 0,
    this.totalCount = 0,
  });

  /// Calcula el resum a partir d'una llista de reaccions
  static ReactionsSummary fromReactions(List<HighlightReaction> reactions) {
    int likes = 0;
    int important = 0;
    int controversial = 0;

    for (final reaction in reactions) {
      switch (reaction.type) {
        case ReactionType.like:
          likes++;
          break;
        case ReactionType.important:
          important++;
          break;
        case ReactionType.controversial:
          controversial++;
          break;
      }
    }

    return ReactionsSummary(
      likeCount: likes,
      importantCount: important,
      controversialCount: controversial,
      totalCount: reactions.length,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'likeCount': likeCount,
      'importantCount': importantCount,
      'controversialCount': controversialCount,
      'totalCount': totalCount,
    };
  }

  static ReactionsSummary fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ReactionsSummary();
    return ReactionsSummary(
      likeCount: json['likeCount'] as int? ?? 0,
      importantCount: json['importantCount'] as int? ?? 0,
      controversialCount: json['controversialCount'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? 0,
    );
  }
}
