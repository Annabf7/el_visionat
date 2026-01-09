// ============================================================================
// WatchedClip - Model per fer seguiment de clips vistos per l'usuari
// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class WatchedClip {
  final String userId;
  final String videoId;
  final DateTime watchedAt;

  WatchedClip({
    required this.userId,
    required this.videoId,
    required this.watchedAt,
  });

  /// Constructor desde Firestore
  factory WatchedClip.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WatchedClip(
      userId: data['userId'] as String,
      videoId: data['videoId'] as String,
      watchedAt: (data['watchedAt'] as Timestamp).toDate(),
    );
  }

  /// Converteix a Map per Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'videoId': videoId,
      'watchedAt': Timestamp.fromDate(watchedAt),
    };
  }

  /// Constructor desde JSON
  factory WatchedClip.fromJson(Map<String, dynamic> json) {
    return WatchedClip(
      userId: json['userId'] as String,
      videoId: json['videoId'] as String,
      watchedAt: (json['watchedAt'] as Timestamp).toDate(),
    );
  }

  /// Converteix a JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'videoId': videoId,
      'watchedAt': Timestamp.fromDate(watchedAt),
    };
  }
}
