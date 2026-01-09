// ============================================================================
// WatchedClipService - Servei per gestionar clips vistos per l'usuari
// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/watched_clip.dart';

class WatchedClipService {
  final FirebaseFirestore _firestore;

  static final WatchedClipService _instance = WatchedClipService._internal(
    FirebaseFirestore.instance,
  );

  factory WatchedClipService() => _instance;

  WatchedClipService._internal(this._firestore);

  /// Referència a la col·lecció de watched_clips
  CollectionReference get _watchedClipsCollection =>
      _firestore.collection('watched_clips');

  /// Marca un clip com a vist
  Future<void> markAsWatched({
    required String userId,
    required String videoId,
  }) async {
    try {
      // Document ID = userId_videoId per evitar duplicats
      final docId = '${userId}_$videoId';

      await _watchedClipsCollection.doc(docId).set(
        WatchedClip(
          userId: userId,
          videoId: videoId,
          watchedAt: DateTime.now(),
        ).toFirestore(),
      );

      debugPrint('[WatchedClipService] ✅ Clip marcat com a vist: $videoId');
    } catch (e) {
      debugPrint('[WatchedClipService] ❌ Error marcant clip: $e');
      rethrow;
    }
  }

  /// Desmarca un clip com a vist (opcional, per si l'usuari ho vol desfer)
  Future<void> unmarkAsWatched({
    required String userId,
    required String videoId,
  }) async {
    try {
      final docId = '${userId}_$videoId';
      await _watchedClipsCollection.doc(docId).delete();

      debugPrint('[WatchedClipService] ✅ Clip desmarcat: $videoId');
    } catch (e) {
      debugPrint('[WatchedClipService] ❌ Error desmarcant clip: $e');
      rethrow;
    }
  }

  /// Comprova si un clip ha estat vist
  Future<bool> isWatched({
    required String userId,
    required String videoId,
  }) async {
    try {
      final docId = '${userId}_$videoId';
      final doc = await _watchedClipsCollection.doc(docId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('[WatchedClipService] ❌ Error comprovant clip: $e');
      return false;
    }
  }

  /// Obté tots els clips vistos per un usuari
  Future<List<String>> getWatchedVideoIds(String userId) async {
    try {
      final snapshot = await _watchedClipsCollection
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .map((data) => data['videoId'] as String)
          .toList();
    } catch (e) {
      debugPrint('[WatchedClipService] ❌ Error obtenint clips vistos: $e');
      return [];
    }
  }

  /// Stream de clips vistos per un usuari (temps real)
  Stream<List<String>> watchWatchedVideoIds(String userId) {
    return _watchedClipsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .map((data) => data['videoId'] as String)
          .toList();
    });
  }

  /// Obté el nombre total de clips vistos per un usuari
  Future<int> getWatchedCount(String userId) async {
    try {
      final snapshot = await _watchedClipsCollection
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.size;
    } catch (e) {
      debugPrint('[WatchedClipService] ❌ Error obtenint count: $e');
      return 0;
    }
  }
}
