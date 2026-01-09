// ============================================================================
// Comment Model - Comentaris per highlights
// ============================================================================
// Permet als usuaris comentar i debatre sobre les jugades

import 'package:cloud_firestore/cloud_firestore.dart';

/// Model per un comentari en un highlight
class Comment {
  final String id;
  final String matchId;
  final String highlightId;
  final String userId;
  final String userName;
  final String userCategory; // ACB, FEB Grup 1, etc.
  final String? userPhotoUrl;
  final String text;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isOfficial; // Si és veredicte oficial d'àrbitre ACB
  final String? parentCommentId; // null si és comentari principal
  final int likesCount;
  final int repliesCount;

  const Comment({
    required this.id,
    required this.matchId,
    required this.highlightId,
    required this.userId,
    required this.userName,
    required this.userCategory,
    this.userPhotoUrl,
    required this.text,
    required this.createdAt,
    this.updatedAt,
    this.isOfficial = false,
    this.parentCommentId,
    this.likesCount = 0,
    this.repliesCount = 0,
  });

  /// Comprova si és un comentari principal (no és resposta)
  bool get isMainComment => parentCommentId == null;

  /// Comprova si és una resposta
  bool get isReply => parentCommentId != null;

  /// Comprova si l'usuari és àrbitre ACB
  bool get isACBReferee => userCategory.toUpperCase().contains('ACB');

  /// Serialització a JSON per Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matchId': matchId,
      'highlightId': highlightId,
      'userId': userId,
      'userName': userName,
      'userCategory': userCategory,
      'userPhotoUrl': userPhotoUrl,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isOfficial': isOfficial,
      'parentCommentId': parentCommentId,
      'likesCount': likesCount,
      'repliesCount': repliesCount,
    };
  }

  /// Deserialització des de JSON de Firestore
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      matchId: json['matchId'] as String,
      highlightId: json['highlightId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userCategory: json['userCategory'] as String,
      userPhotoUrl: json['userPhotoUrl'] as String?,
      text: json['text'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
      isOfficial: json['isOfficial'] as bool? ?? false,
      parentCommentId: json['parentCommentId'] as String?,
      likesCount: json['likesCount'] as int? ?? 0,
      repliesCount: json['repliesCount'] as int? ?? 0,
    );
  }

  /// Crea una còpia amb camps actualitzats
  Comment copyWith({
    String? id,
    String? matchId,
    String? highlightId,
    String? userId,
    String? userName,
    String? userCategory,
    String? userPhotoUrl,
    String? text,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isOfficial,
    String? parentCommentId,
    int? likesCount,
    int? repliesCount,
  }) {
    return Comment(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      highlightId: highlightId ?? this.highlightId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userCategory: userCategory ?? this.userCategory,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isOfficial: isOfficial ?? this.isOfficial,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      likesCount: likesCount ?? this.likesCount,
      repliesCount: repliesCount ?? this.repliesCount,
    );
  }

  /// Helpers per Firestore withConverter
  static Map<String, dynamic> Function(Comment, SetOptions?) get toFirestore =>
      (comment, _) => comment.toJson();

  static Comment Function(
    DocumentSnapshot<Map<String, dynamic>>,
    SnapshotOptions?,
  ) get fromFirestore => (snapshot, _) {
        final data = snapshot.data();
        if (data == null) {
          throw Exception('No data found in Firestore document');
        }
        return Comment.fromJson(data);
      };
}

/// Model per un comentari amb les seves respostes
class CommentWithReplies {
  final Comment comment;
  final List<Comment> replies;
  final bool hasLiked; // Si l'usuari actual ha fet like

  const CommentWithReplies({
    required this.comment,
    this.replies = const [],
    this.hasLiked = false,
  });

  CommentWithReplies copyWith({
    Comment? comment,
    List<Comment>? replies,
    bool? hasLiked,
  }) {
    return CommentWithReplies(
      comment: comment ?? this.comment,
      replies: replies ?? this.replies,
      hasLiked: hasLiked ?? this.hasLiked,
    );
  }
}
