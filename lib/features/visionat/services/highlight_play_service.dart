// ============================================================================
// HighlightPlayService - Gestió de jugades destacades amb votació
// ============================================================================
// CRUD de jugades destacades (HighlightPlay)
// Converteix HighlightEntry a HighlightPlay quan s'afegeixen reaccions

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/highlight_play.dart';
import '../models/highlight_reaction.dart';

class HighlightPlayService {
  static final HighlightPlayService _instance = HighlightPlayService._internal();
  factory HighlightPlayService() => _instance;
  HighlightPlayService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Converteix un HighlightEntry a HighlightPlay
  /// S'executa automàticament quan es detecta que un highlight té reaccions
  Future<void> upgradeToHighlightPlay({
    required String matchId,
    required String highlightId,
  }) async {
    try {
      final highlightRef = _firestore
          .collection('entries')
          .doc(matchId)
          .collection('entries')
          .doc(highlightId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(highlightRef);

        if (!snapshot.exists) {
          throw Exception('Highlight no trobat');
        }

        final data = snapshot.data()!;

        // Comprovar si ja és un HighlightPlay
        if (data.containsKey('reactions')) {
          debugPrint('[PlayService] Ja és un HighlightPlay');
          return;
        }

        // Crear camps de HighlightPlay
        final upgradedData = {
          ...data,
          'reactions': [],
          'reactionsSummary': const ReactionsSummary().toJson(),
          'commentCount': 0,
          'status': HighlightPlayStatus.open.value,
        };

        transaction.update(highlightRef, upgradedData);
      });

      debugPrint('[PlayService] ✅ Highlight升級 a HighlightPlay');
    } catch (e) {
      debugPrint('[PlayService] ❌ Error upgrade: $e');
      rethrow;
    }
  }

  /// Obté una jugada com HighlightPlay
  Future<HighlightPlay?> getPlay({
    required String matchId,
    required String highlightId,
  }) async {
    try {
      final doc = await _firestore
          .collection('entries')
          .doc(matchId)
          .collection('entries')
          .doc(highlightId)
          .get();

      if (!doc.exists) return null;

      return HighlightPlay.fromJson(doc.data()!);
    } catch (e) {
      debugPrint('[PlayService] ❌ Error obtenint play: $e');
      return null;
    }
  }

  /// Stream d'una jugada en temps real
  Stream<HighlightPlay?> watchPlay({
    required String matchId,
    required String highlightId,
  }) {
    return _firestore
        .collection('entries')
        .doc(matchId)
        .collection('entries')
        .doc(highlightId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return HighlightPlay.fromJson(snapshot.data()!);
    });
  }

  /// Obté jugades en revisió (threshold assolit)
  Future<List<HighlightPlay>> getPlaysUnderReview({
    required String matchId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('entries')
          .doc(matchId)
          .collection('entries')
          .where('status', isEqualTo: HighlightPlayStatus.underReview.value)
          .orderBy('reviewNotifiedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => HighlightPlay.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[PlayService] ❌ Error obtenint plays en revisió: $e');
      return [];
    }
  }

  /// Obté jugades resoltes
  Future<List<HighlightPlay>> getResolvedPlays({
    required String matchId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('entries')
          .doc(matchId)
          .collection('entries')
          .where('status', isEqualTo: HighlightPlayStatus.resolved.value)
          .orderBy('resolvedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => HighlightPlay.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[PlayService] ❌ Error obtenint plays resoltes: $e');
      return [];
    }
  }

  /// Obté jugades amb més reaccions (trending)
  Future<List<HighlightPlay>> getTrendingPlays({
    required String matchId,
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('entries')
          .doc(matchId)
          .collection('entries')
          .where('reactionsSummary.totalCount', isGreaterThan: 0)
          .orderBy('reactionsSummary.totalCount', descending: true)
          .limit(limit)
          .get();

      final plays = snapshot.docs
          .map((doc) => HighlightPlay.fromJson(doc.data()))
          .toList();

      // Ordenar per prioritat calculada (amb decay temporal)
      plays.sort((a, b) => b.calculatePriority().compareTo(a.calculatePriority()));

      return plays;
    } catch (e) {
      debugPrint('[PlayService] ❌ Error obtenint trending plays: $e');
      return [];
    }
  }

  /// Marca una jugada com resolta manualment (admin)
  Future<void> markAsResolved({
    required String matchId,
    required String highlightId,
    String? officialCommentId,
  }) async {
    try {
      final highlightRef = _firestore
          .collection('entries')
          .doc(matchId)
          .collection('entries')
          .doc(highlightId);

      await highlightRef.update({
        'status': HighlightPlayStatus.resolved.value,
        'resolvedAt': Timestamp.fromDate(DateTime.now()),
        if (officialCommentId != null) 'officialCommentId': officialCommentId,
      });

      debugPrint('[PlayService] ✅ Jugada marcada com resolta');
    } catch (e) {
      debugPrint('[PlayService] ❌ Error marcant com resolta: $e');
      rethrow;
    }
  }

  /// Obre de nou el debat (admin)
  Future<void> reopenDebate({
    required String matchId,
    required String highlightId,
  }) async {
    try {
      final highlightRef = _firestore
          .collection('entries')
          .doc(matchId)
          .collection('entries')
          .doc(highlightId);

      await highlightRef.update({
        'status': HighlightPlayStatus.open.value,
        'resolvedAt': FieldValue.delete(),
        'officialCommentId': FieldValue.delete(),
      });

      debugPrint('[PlayService] ✅ Debat reobert');
    } catch (e) {
      debugPrint('[PlayService] ❌ Error reobrint debat: $e');
      rethrow;
    }
  }

  /// Obté estadístiques d'un partit
  Future<Map<String, dynamic>> getMatchStats({
    required String matchId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('entries')
          .doc(matchId)
          .collection('entries')
          .get();

      int totalPlays = 0;
      int totalReactions = 0;
      int totalComments = 0;
      int underReview = 0;
      int resolved = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('reactions')) {
          totalPlays++;
          final play = HighlightPlay.fromJson(data);
          totalReactions += play.reactionsSummary.totalCount;
          totalComments += play.commentCount;

          if (play.status == HighlightPlayStatus.underReview) underReview++;
          if (play.status == HighlightPlayStatus.resolved) resolved++;
        }
      }

      return {
        'totalPlays': totalPlays,
        'totalReactions': totalReactions,
        'totalComments': totalComments,
        'underReview': underReview,
        'resolved': resolved,
        'open': totalPlays - underReview - resolved,
      };
    } catch (e) {
      debugPrint('[PlayService] ❌ Error obtenint stats: $e');
      return {};
    }
  }
}
