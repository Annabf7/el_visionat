// ============================================================================
// AppNotification - Model per notificacions in-app
// ============================================================================
// Sistema de notificacions intern de l'aplicació
// Tipus: highlight_review_requested, debate_closed, etc.

import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipus de notificació
enum NotificationType {
  highlightReviewRequested, // Jugada arriba a 10 reaccions, necessita revisió
  debateClosed, // Veredicte oficial, debat tancat
  commentReply, // Algú ha respost al teu comentari
  newReaction, // Algú ha reaccionat a la teva jugada
  other, // Altres tipus
}

extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.highlightReviewRequested:
        return 'highlight_review_requested';
      case NotificationType.debateClosed:
        return 'debate_closed';
      case NotificationType.commentReply:
        return 'comment_reply';
      case NotificationType.newReaction:
        return 'new_reaction';
      case NotificationType.other:
        return 'other';
    }
  }

  static NotificationType fromValue(String value) {
    switch (value) {
      case 'highlight_review_requested':
        return NotificationType.highlightReviewRequested;
      case 'debate_closed':
        return NotificationType.debateClosed;
      case 'comment_reply':
        return NotificationType.commentReply;
      case 'new_reaction':
        return NotificationType.newReaction;
      default:
        return NotificationType.other;
    }
  }
}

/// Model de notificació in-app
class AppNotification {
  final String id;
  final String userId; // A qui va dirigida
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic> data; // Dades addicionals (matchId, highlightId, etc.)
  final bool isRead;
  final DateTime createdAt;
  final DateTime? expiresAt; // Data d'expiració (opcional)

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
    this.expiresAt,
  });

  /// Serialització a JSON per Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.value,
      'title': title,
      'message': message,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }

  /// Deserialització des de JSON de Firestore
  static AppNotification fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: NotificationTypeExtension.fromValue(json['type'] as String),
      title: json['title'] as String,
      message: json['message'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      isRead: json['isRead'] as bool? ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      expiresAt: json['expiresAt'] != null
          ? (json['expiresAt'] as Timestamp).toDate()
          : null,
    );
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  /// Comprova si la notificació ha expirat
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Helpers per Firestore withConverter
  static Map<String, dynamic> Function(AppNotification, SetOptions?)
      get toFirestore => (notification, _) => notification.toJson();

  static AppNotification Function(
    DocumentSnapshot<Map<String, dynamic>>,
    SnapshotOptions?,
  ) get fromFirestore => (snapshot, _) {
        final data = snapshot.data();
        if (data == null) {
          throw Exception('No data found in Firestore document');
        }
        return AppNotification.fromJson(data);
      };
}
