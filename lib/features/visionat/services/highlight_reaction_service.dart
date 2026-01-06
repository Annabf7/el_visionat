// ============================================================================
// HighlightReactionService - Gestió de reaccions a jugades destacades
// ============================================================================
// Permet afegir/eliminar reaccions i sincronitzar amb Firestore
// Les reaccions es guarden dins del document HighlightPlay per optimització

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/highlight_reaction.dart';
import '../models/highlight_play.dart';

class HighlightReactionService {
  static final HighlightReactionService _instance = HighlightReactionService._internal();
  factory HighlightReactionService() => _instance;
  HighlightReactionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Afegeix o elimina una reacció (toggle)
  /// Si l'usuari ja té aquesta reacció, l'elimina
  /// Si l'usuari té una altra reacció, la reemplaça
  Future<void> toggleReaction({
    required String matchId,
    required String highlightId,
    required String userId,
    required ReactionType type,
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
        final play = HighlightPlay.fromJson(data);

        // Comprova si l'usuari ja té aquesta reacció
        final existingReactionIndex = play.reactions.indexWhere(
          (r) => r.userId == userId && r.type == type,
        );

        List<HighlightReaction> updatedReactions = List.from(play.reactions);

        if (existingReactionIndex != -1) {
          // Elimina la reacció existent (toggle off)
          updatedReactions.removeAt(existingReactionIndex);
          debugPrint('[ReactionService] Eliminant reacció $type de $userId');
        } else {
          // Elimina qualsevol altra reacció de l'usuari (només 1 per usuari)
          updatedReactions.removeWhere((r) => r.userId == userId);

          // Afegeix la nova reacció
          updatedReactions.add(HighlightReaction(
            userId: userId,
            type: type,
            createdAt: DateTime.now(),
          ));
          debugPrint('[ReactionService] Afegint reacció $type de $userId');
        }

        // Recalcula el resum
        final newSummary = ReactionsSummary.fromReactions(updatedReactions);

        // Actualitza l'estat si arriba al threshold
        HighlightPlayStatus newStatus = play.status;
        DateTime? reviewNotifiedAt = play.reviewNotifiedAt;

        if (newSummary.totalCount >= 10 && play.status == HighlightPlayStatus.open) {
          newStatus = HighlightPlayStatus.underReview;
          reviewNotifiedAt = DateTime.now();
          debugPrint('[ReactionService] ⚠️ Threshold assolit! Canviant estat a underReview');
        }

        // Actualitza el document
        transaction.update(highlightRef, {
          'reactions': updatedReactions.map((r) => r.toJson()).toList(),
          'reactionsSummary': newSummary.toJson(),
          'status': newStatus.value,
          'reviewNotifiedAt': reviewNotifiedAt != null
              ? Timestamp.fromDate(reviewNotifiedAt)
              : null,
        });
      });

      debugPrint('[ReactionService] ✅ Reacció actualitzada correctament');
    } catch (e) {
      debugPrint('[ReactionService] ❌ Error: $e');
      rethrow;
    }
  }

  /// Obté totes les reaccions d'una jugada
  Future<List<HighlightReaction>> getReactions({
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

      if (!doc.exists) {
        return [];
      }

      final play = HighlightPlay.fromJson(doc.data()!);
      return play.reactions;
    } catch (e) {
      debugPrint('[ReactionService] ❌ Error obtenint reaccions: $e');
      return [];
    }
  }

  /// Stream de reaccions en temps real
  Stream<List<HighlightReaction>> watchReactions({
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
      if (!snapshot.exists) return [];
      final play = HighlightPlay.fromJson(snapshot.data()!);
      return play.reactions;
    });
  }

  /// Obté les reaccions d'un usuari específic
  Future<Set<ReactionType>> getUserReactions({
    required String matchId,
    required String highlightId,
    required String userId,
  }) async {
    try {
      final reactions = await getReactions(
        matchId: matchId,
        highlightId: highlightId,
      );

      return reactions
          .where((r) => r.userId == userId)
          .map((r) => r.type)
          .toSet();
    } catch (e) {
      debugPrint('[ReactionService] ❌ Error obtenint reaccions d\'usuari: $e');
      return {};
    }
  }

  /// Compta el total de reaccions per tipus
  Future<ReactionsSummary> getReactionsSummary({
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

      if (!doc.exists) {
        return const ReactionsSummary();
      }

      final play = HighlightPlay.fromJson(doc.data()!);
      return play.reactionsSummary;
    } catch (e) {
      debugPrint('[ReactionService] ❌ Error obtenint resum: $e');
      return const ReactionsSummary();
    }
  }

  /// Elimina totes les reaccions d'un usuari d'una jugada
  Future<void> removeAllUserReactions({
    required String matchId,
    required String highlightId,
    required String userId,
  }) async {
    try {
      final highlightRef = _firestore
          .collection('entries')
          .doc(matchId)
          .collection('entries')
          .doc(highlightId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(highlightRef);

        if (!snapshot.exists) return;

        final play = HighlightPlay.fromJson(snapshot.data()!);
        final updatedReactions = play.reactions
            .where((r) => r.userId != userId)
            .toList();

        final newSummary = ReactionsSummary.fromReactions(updatedReactions);

        transaction.update(highlightRef, {
          'reactions': updatedReactions.map((r) => r.toJson()).toList(),
          'reactionsSummary': newSummary.toJson(),
        });
      });

      debugPrint('[ReactionService] ✅ Reaccions d\'usuari eliminades');
    } catch (e) {
      debugPrint('[ReactionService] ❌ Error eliminant reaccions: $e');
      rethrow;
    }
  }
}
