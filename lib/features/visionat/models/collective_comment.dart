import 'package:cloud_firestore/cloud_firestore.dart';

/// Model per a comentaris de l'anàlisi col·lectiva d'un partit
/// Compatible amb Firestore i amb el codi UI existent
class CollectiveComment {
  final String id;
  final String matchId;
  final String content;
  final String tagId;
  final String tagLabel;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final int likes;
  final List<String> likedBy;
  final bool isEdited;
  final DateTime? editedAt;

  const CollectiveComment({
    required this.id,
    required this.matchId,
    required this.content,
    required this.tagId,
    required this.tagLabel,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.likes,
    required this.likedBy,
    required this.isEdited,
    this.editedAt,
  });

  // Constructor de compatibilitat amb UI existent (sense camps Firestore)
  CollectiveComment.legacy({
    required this.id,
    required String username,
    required String text,
    required bool anonymous,
    required this.createdAt,
  }) : matchId = '',
       content = text,
       tagId = 'general',
       tagLabel = 'General',
       createdBy = '',
       createdByName = anonymous ? 'Anònim' : username,
       likes = 0,
       likedBy = [],
       isEdited = false,
       editedAt = null;

  /// Nom a mostrar (mantenim compatibilitat)
  String get displayName => createdByName;
  
  /// Text del comentari (mantenim compatibilitat)
  String get text => content;
  
  /// Si és anònim (mantenim compatibilitat)
  bool get anonymous => createdByName == 'Anònim';
  
  /// Username (mantenim compatibilitat)
  String get username => createdByName;

  /// Data formatada de forma curta
  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) {
      return 'Ara mateix';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}min';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d';
    } else {
      return '${createdAt.day}/${createdAt.month}';
    }
  }

  /// Indica si l'usuari actual ha donat like
  bool isLikedBy(String userId) {
    return likedBy.contains(userId);
  }

  // Mètode per crear una còpia amb canvis
  CollectiveComment copyWith({
    String? id,
    String? matchId,
    String? content,
    String? tagId,
    String? tagLabel,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    int? likes,
    List<String>? likedBy,
    bool? isEdited,
    DateTime? editedAt,
  }) {
    return CollectiveComment(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      content: content ?? this.content,
      tagId: tagId ?? this.tagId,
      tagLabel: tagLabel ?? this.tagLabel,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? List.from(this.likedBy),
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
    );
  }

  // Serialització a JSON per Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matchId': matchId,
      'content': content,
      'tagId': tagId,
      'tagLabel': tagLabel,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
      'likedBy': likedBy,
      'isEdited': isEdited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
    };
  }

  // Deserialització des de JSON de Firestore
  static CollectiveComment fromJson(Map<String, dynamic> json) {
    return CollectiveComment(
      id: json['id'] as String,
      matchId: json['matchId'] as String,
      content: json['content'] as String,
      tagId: json['tagId'] as String,
      tagLabel: json['tagLabel'] as String,
      createdBy: json['createdBy'] as String,
      createdByName: json['createdByName'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      likes: (json['likes'] as num).toInt(),
      likedBy: List<String>.from(json['likedBy'] as List),
      isEdited: json['isEdited'] as bool,
      editedAt: json['editedAt'] != null 
          ? (json['editedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  // Mètode helper per usar amb withConverter() de Firestore
  static Map<String, dynamic> Function(CollectiveComment, SetOptions?)
  get toFirestore => (comment, _) => comment.toJson();

  static CollectiveComment Function(
    DocumentSnapshot<Map<String, dynamic>>,
    SnapshotOptions?,
  )
  get fromFirestore => (snapshot, _) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception('No data found in Firestore document');
    }
    return CollectiveComment.fromJson(data);
  };
}
