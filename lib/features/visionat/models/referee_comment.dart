// ============================================================================
// RefereeComment - Comentari d'àrbitre sobre una jugada destacada
// ============================================================================
// Permet als àrbitres comentar jugades destacades del minutatge
// amb opció d'anonimitat però mostrant sempre el color de la seva categoria

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:el_visionat/core/constants/referee_category_colors.dart';

/// Comentari d'un àrbitre sobre una jugada destacada
class RefereeComment {
  final String id;
  final String highlightId; // ID de la jugada comentada
  final String matchId; // Per indexació
  final String userId; // UID de l'àrbitre
  final RefereeCategory category; // Categoria de l'àrbitre
  final String comment; // Text del comentari
  final bool isAnonymous; // Si l'àrbitre vol romandre anònim
  final bool isOfficial; // Si és el veredicte final (tanca debat)
  final DateTime createdAt;
  final DateTime? updatedAt; // Si s'edita
  final bool isEdited; // Indica si s'ha editat

  // Dades opcionals de l'àrbitre (si NO és anònim)
  final String? refereeDisplayName;
  final String? refereeAvatarUrl;

  const RefereeComment({
    required this.id,
    required this.highlightId,
    required this.matchId,
    required this.userId,
    required this.category,
    required this.comment,
    this.isAnonymous = false,
    this.isOfficial = false,
    required this.createdAt,
    this.updatedAt,
    this.isEdited = false,
    this.refereeDisplayName,
    this.refereeAvatarUrl,
  });

  /// Serialització a JSON per Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'highlightId': highlightId,
      'matchId': matchId,
      'userId': userId,
      'category': category.value,
      'comment': comment,
      'isAnonymous': isAnonymous,
      'isOfficial': isOfficial,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isEdited': isEdited,
      'refereeDisplayName': refereeDisplayName,
      'refereeAvatarUrl': refereeAvatarUrl,
    };
  }

  /// Deserialització des de JSON de Firestore
  static RefereeComment fromJson(Map<String, dynamic> json) {
    return RefereeComment(
      id: json['id'] as String,
      highlightId: json['highlightId'] as String,
      matchId: json['matchId'] as String,
      userId: json['userId'] as String,
      category: RefereeCategoryExtension.fromValue(json['category'] as String),
      comment: json['comment'] as String,
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      isOfficial: json['isOfficial'] as bool? ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
      isEdited: json['isEdited'] as bool? ?? false,
      refereeDisplayName: json['refereeDisplayName'] as String?,
      refereeAvatarUrl: json['refereeAvatarUrl'] as String?,
    );
  }

  RefereeComment copyWith({
    String? id,
    String? highlightId,
    String? matchId,
    String? userId,
    RefereeCategory? category,
    String? comment,
    bool? isAnonymous,
    bool? isOfficial,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEdited,
    String? refereeDisplayName,
    String? refereeAvatarUrl,
  }) {
    return RefereeComment(
      id: id ?? this.id,
      highlightId: highlightId ?? this.highlightId,
      matchId: matchId ?? this.matchId,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      comment: comment ?? this.comment,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isOfficial: isOfficial ?? this.isOfficial,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
      refereeDisplayName: refereeDisplayName ?? this.refereeDisplayName,
      refereeAvatarUrl: refereeAvatarUrl ?? this.refereeAvatarUrl,
    );
  }

  /// Retorna el nom a mostrar (anònim o real)
  String getDisplayName() {
    if (isAnonymous) {
      return 'Àrbitre ${category.displayName}';
    }
    return refereeDisplayName ?? 'Àrbitre Verificat';
  }

  /// Helpers per Firestore withConverter
  static Map<String, dynamic> Function(RefereeComment, SetOptions?)
      get toFirestore => (comment, _) => comment.toJson();

  static RefereeComment Function(
    DocumentSnapshot<Map<String, dynamic>>,
    SnapshotOptions?,
  ) get fromFirestore => (snapshot, _) {
        final data = snapshot.data();
        if (data == null) {
          throw Exception('No data found in Firestore document');
        }
        return RefereeComment.fromJson(data);
      };
}
