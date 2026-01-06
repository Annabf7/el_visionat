// ============================================================================
// HighlightPlay - Jugada destacada amb sistema de votació i comentaris
// ============================================================================
// Estén HighlightEntry afegint reaccions i comentaris d'àrbitres
// Quan arriba a 10 reaccions, es notifica a àrbitres de màxima categoria

import 'package:cloud_firestore/cloud_firestore.dart';
import 'highlight_entry.dart';
import 'highlight_reaction.dart';

/// Estat d'una jugada destacada en el procés de revisió
enum HighlightPlayStatus {
  open, // Obert a reaccions i comentaris
  underReview, // >= 10 reaccions, àrbitres notificats
  resolved, // Veredicte final d'àrbitre ACB/FEB Grup 1
}

extension HighlightPlayStatusExtension on HighlightPlayStatus {
  String get value {
    switch (this) {
      case HighlightPlayStatus.open:
        return 'open';
      case HighlightPlayStatus.underReview:
        return 'under_review';
      case HighlightPlayStatus.resolved:
        return 'resolved';
    }
  }

  String get displayName {
    switch (this) {
      case HighlightPlayStatus.open:
        return 'Obert';
      case HighlightPlayStatus.underReview:
        return 'En revisió';
      case HighlightPlayStatus.resolved:
        return 'Resolt';
    }
  }

  static HighlightPlayStatus fromValue(String value) {
    switch (value) {
      case 'open':
        return HighlightPlayStatus.open;
      case 'under_review':
        return HighlightPlayStatus.underReview;
      case 'resolved':
        return HighlightPlayStatus.resolved;
      default:
        return HighlightPlayStatus.open;
    }
  }
}

/// Jugada destacada amb sistema complet de reaccions i comentaris
class HighlightPlay extends HighlightEntry {
  // Sistema de reaccions
  final List<HighlightReaction> reactions;
  final ReactionsSummary reactionsSummary;

  // Sistema de comentaris d'àrbitres
  final int commentCount; // Nombre total de comentaris
  final String? officialCommentId; // ID del comentari oficial (veredicte final)

  // Estat i metadades
  final HighlightPlayStatus status;
  final DateTime? reviewNotifiedAt; // Quan es va notificar als àrbitres
  final DateTime? resolvedAt; // Quan es va resoldre

  const HighlightPlay({
    required super.id,
    required super.matchId,
    required super.timestamp,
    required super.title,
    required super.tag,
    required super.category,
    required super.tagId,
    required super.tagLabel,
    required super.description,
    required super.createdBy,
    required super.createdAt,
    this.reactions = const [],
    this.reactionsSummary = const ReactionsSummary(),
    this.commentCount = 0,
    this.officialCommentId,
    this.status = HighlightPlayStatus.open,
    this.reviewNotifiedAt,
    this.resolvedAt,
  });

  /// Factory per crear des de HighlightEntry
  factory HighlightPlay.fromHighlightEntry(HighlightEntry entry) {
    return HighlightPlay(
      id: entry.id,
      matchId: entry.matchId,
      timestamp: entry.timestamp,
      title: entry.title,
      tag: entry.tag,
      category: entry.category,
      tagId: entry.tagId,
      tagLabel: entry.tagLabel,
      description: entry.description,
      createdBy: entry.createdBy,
      createdAt: entry.createdAt,
    );
  }

  @override
  HighlightPlay copyWith({
    String? id,
    String? matchId,
    Duration? timestamp,
    String? title,
    HighlightTagType? tag,
    String? category,
    String? tagId,
    String? tagLabel,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    List<HighlightReaction>? reactions,
    ReactionsSummary? reactionsSummary,
    int? commentCount,
    String? officialCommentId,
    HighlightPlayStatus? status,
    DateTime? reviewNotifiedAt,
    DateTime? resolvedAt,
  }) {
    return HighlightPlay(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      timestamp: timestamp ?? this.timestamp,
      title: title ?? this.title,
      tag: tag ?? this.tag,
      category: category ?? this.category,
      tagId: tagId ?? this.tagId,
      tagLabel: tagLabel ?? this.tagLabel,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      reactions: reactions ?? this.reactions,
      reactionsSummary: reactionsSummary ?? this.reactionsSummary,
      commentCount: commentCount ?? this.commentCount,
      officialCommentId: officialCommentId ?? this.officialCommentId,
      status: status ?? this.status,
      reviewNotifiedAt: reviewNotifiedAt ?? this.reviewNotifiedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  /// Serialització a JSON per Firestore
  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'reactions': reactions.map((r) => r.toJson()).toList(),
      'reactionsSummary': reactionsSummary.toJson(),
      'commentCount': commentCount,
      'officialCommentId': officialCommentId,
      'status': status.value,
      'reviewNotifiedAt':
          reviewNotifiedAt != null ? Timestamp.fromDate(reviewNotifiedAt!) : null,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }

  /// Deserialització des de JSON de Firestore
  static HighlightPlay fromJson(Map<String, dynamic> json) {
    final baseEntry = HighlightEntry.fromJson(json);

    // Parse reactions
    final List<HighlightReaction> reactions = [];
    if (json['reactions'] != null) {
      for (final reactionJson in json['reactions'] as List) {
        reactions.add(HighlightReaction.fromJson(reactionJson as Map<String, dynamic>));
      }
    }

    return HighlightPlay(
      id: baseEntry.id,
      matchId: baseEntry.matchId,
      timestamp: baseEntry.timestamp,
      title: baseEntry.title,
      tag: baseEntry.tag,
      category: baseEntry.category,
      tagId: baseEntry.tagId,
      tagLabel: baseEntry.tagLabel,
      description: baseEntry.description,
      createdBy: baseEntry.createdBy,
      createdAt: baseEntry.createdAt,
      reactions: reactions,
      reactionsSummary: ReactionsSummary.fromJson(json['reactionsSummary'] as Map<String, dynamic>?),
      commentCount: json['commentCount'] as int? ?? 0,
      officialCommentId: json['officialCommentId'] as String?,
      status: HighlightPlayStatusExtension.fromValue(json['status'] as String? ?? 'open'),
      reviewNotifiedAt: json['reviewNotifiedAt'] != null
          ? (json['reviewNotifiedAt'] as Timestamp).toDate()
          : null,
      resolvedAt: json['resolvedAt'] != null ? (json['resolvedAt'] as Timestamp).toDate() : null,
    );
  }

  /// Helpers per Firestore withConverter
  static Map<String, dynamic> Function(HighlightPlay, SetOptions?)
      get toFirestore => (play, _) => play.toJson();

  static HighlightPlay Function(
    DocumentSnapshot<Map<String, dynamic>>,
    SnapshotOptions?,
  ) get fromFirestore => (snapshot, _) {
        final data = snapshot.data();
        if (data == null) {
          throw Exception('No data found in Firestore document');
        }
        return HighlightPlay.fromJson(data);
      };

  /// Comprova si la jugada ha arribat al llindar de reaccions (10)
  bool get hasReachedReactionThreshold => reactionsSummary.totalCount >= 10;

  /// Comprova si està resolta
  bool get isResolved => status == HighlightPlayStatus.resolved;

  /// Comprova si està en revisió
  bool get isUnderReview => status == HighlightPlayStatus.underReview;

  /// Calcula prioritat per ordenar (més reaccions controvertides = més prioritat)
  double calculatePriority() {
    final reactionCount = reactionsSummary.totalCount;
    final controversialCount = reactionsSummary.controversialCount;
    final hoursOld = DateTime.now().difference(createdAt).inHours;

    // Decay temporal: perd prioritat amb el temps
    final timeDecay = hoursOld > 0 ? 1.0 / (1 + (hoursOld / 24.0)) : 1.0;

    return (reactionCount * 2.0 + controversialCount * 5.0) * timeDecay;
  }
}
