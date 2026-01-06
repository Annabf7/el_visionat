// ============================================================================
// RefereeCommentService - Gestió de comentaris d'àrbitres
// ============================================================================
// Permet als àrbitres comentar jugades destacades
// Gestiona comentaris anònims i veredictes oficials

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:el_visionat/core/constants/referee_category_colors.dart';
import '../models/referee_comment.dart';
import '../models/highlight_play.dart';

class RefereeCommentService {
  static final RefereeCommentService _instance = RefereeCommentService._internal();
  factory RefereeCommentService() => _instance;
  RefereeCommentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Afegeix un nou comentari d'àrbitre
  Future<String> addComment({
    required String matchId,
    required String highlightId,
    required String userId,
    required RefereeCategory category,
    required String comment,
    required bool isAnonymous,
    bool isOfficial = false,
    String? refereeDisplayName,
    String? refereeAvatarUrl,
  }) async {
    try {
      // Validació: mínim 50 caràcters
      if (comment.trim().length < 50) {
        throw Exception('El comentari ha de tenir mínim 50 caràcters');
      }

      // Validació: només ACB i FEB Grup 1 poden marcar com oficial
      if (isOfficial && !RefereeCategoryColors.canCloseDebate(category)) {
        throw Exception('Només àrbitres ACB o FEB Grup 1 poden tancar el debat');
      }

      final commentsRef = _firestore
          .collection('entries')
          .doc(matchId)
          .collection('entries')
          .doc(highlightId)
          .collection('referee_comments');

      // Crear el comentari
      final commentDoc = commentsRef.doc();
      final newComment = RefereeComment(
        id: commentDoc.id,
        highlightId: highlightId,
        matchId: matchId,
        userId: userId,
        category: category,
        comment: comment.trim(),
        isAnonymous: isAnonymous,
        isOfficial: isOfficial,
        createdAt: DateTime.now(),
        refereeDisplayName: isAnonymous ? null : refereeDisplayName,
        refereeAvatarUrl: isAnonymous ? null : refereeAvatarUrl,
      );

      await commentDoc.set(newComment.toJson());

      // Actualitzar comptador de comentaris i estat del highlight
      await _updateHighlightAfterComment(
        matchId: matchId,
        highlightId: highlightId,
        commentId: commentDoc.id,
        isOfficial: isOfficial,
      );

      debugPrint('[CommentService] ✅ Comentari afegit: ${commentDoc.id}');
      return commentDoc.id;
    } catch (e) {
      debugPrint('[CommentService] ❌ Error afegint comentari: $e');
      rethrow;
    }
  }

  /// Actualitza el highlight després d'afegir un comentari
  Future<void> _updateHighlightAfterComment({
    required String matchId,
    required String highlightId,
    required String commentId,
    required bool isOfficial,
  }) async {
    final highlightRef = _firestore
        .collection('entries')
        .doc(matchId)
        .collection('entries')
        .doc(highlightId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(highlightRef);

      if (!snapshot.exists) return;

      final play = HighlightPlay.fromJson(snapshot.data()!);

      final updates = <String, dynamic>{
        'commentCount': play.commentCount + 1,
      };

      // Si és un veredicte oficial, tancar el debat
      if (isOfficial) {
        updates['status'] = HighlightPlayStatus.resolved.value;
        updates['officialCommentId'] = commentId;
        updates['resolvedAt'] = Timestamp.fromDate(DateTime.now());
        debugPrint('[CommentService] 🔒 Debat tancat amb veredicte oficial');
      }

      transaction.update(highlightRef, updates);
    });
  }

  /// Obté tots els comentaris d'una jugada
  Future<List<RefereeComment>> getComments({
    required String matchId,
    required String highlightId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('entries')
          .doc(matchId)
          .collection('entries')
          .doc(highlightId)
          .collection('referee_comments')
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => RefereeComment.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[CommentService] ❌ Error obtenint comentaris: $e');
      return [];
    }
  }

  /// Stream de comentaris en temps real
  Stream<List<RefereeComment>> watchComments({
    required String matchId,
    required String highlightId,
  }) {
    return _firestore
        .collection('entries')
        .doc(matchId)
        .collection('entries')
        .doc(highlightId)
        .collection('referee_comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RefereeComment.fromJson(doc.data()))
          .toList();
    });
  }

  /// Edita un comentari existent
  Future<void> editComment({
    required String matchId,
    required String highlightId,
    required String commentId,
    required String userId,
    required String newComment,
  }) async {
    try {
      // Validació: mínim 50 caràcters
      if (newComment.trim().length < 50) {
        throw Exception('El comentari ha de tenir mínim 50 caràcters');
      }

      final commentRef = _firestore
          .collection('entries')
          .doc(matchId)
          .collection('entries')
          .doc(highlightId)
          .collection('referee_comments')
          .doc(commentId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(commentRef);

        if (!snapshot.exists) {
          throw Exception('Comentari no trobat');
        }

        final comment = RefereeComment.fromJson(snapshot.data()!);

        // Només el creador pot editar
        if (comment.userId != userId) {
          throw Exception('No tens permisos per editar aquest comentari');
        }

        // No es poden editar comentaris oficials
        if (comment.isOfficial) {
          throw Exception('No es poden editar veredictes oficials');
        }

        transaction.update(commentRef, {
          'comment': newComment.trim(),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
          'isEdited': true,
        });
      });

      debugPrint('[CommentService] ✅ Comentari editat: $commentId');
    } catch (e) {
      debugPrint('[CommentService] ❌ Error editant comentari: $e');
      rethrow;
    }
  }

  /// Elimina un comentari
  Future<void> deleteComment({
    required String matchId,
    required String highlightId,
    required String commentId,
    required String userId,
  }) async {
    try {
      final commentRef = _firestore
          .collection('entries')
          .doc(matchId)
          .collection('entries')
          .doc(highlightId)
          .collection('referee_comments')
          .doc(commentId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(commentRef);

        if (!snapshot.exists) {
          throw Exception('Comentari no trobat');
        }

        final comment = RefereeComment.fromJson(snapshot.data()!);

        // Només el creador pot eliminar
        if (comment.userId != userId) {
          throw Exception('No tens permisos per eliminar aquest comentari');
        }

        // No es poden eliminar comentaris oficials
        if (comment.isOfficial) {
          throw Exception('No es poden eliminar veredictes oficials');
        }

        transaction.delete(commentRef);

        // Actualitzar comptador
        final highlightRef = _firestore
            .collection('entries')
            .doc(matchId)
            .collection('entries')
            .doc(highlightId);

        final highlightSnapshot = await transaction.get(highlightRef);
        if (highlightSnapshot.exists) {
          final play = HighlightPlay.fromJson(highlightSnapshot.data()!);
          transaction.update(highlightRef, {
            'commentCount': (play.commentCount - 1).clamp(0, 999999),
          });
        }
      });

      debugPrint('[CommentService] ✅ Comentari eliminat: $commentId');
    } catch (e) {
      debugPrint('[CommentService] ❌ Error eliminant comentari: $e');
      rethrow;
    }
  }

  /// Obté el comentari oficial (veredicte final)
  Future<RefereeComment?> getOfficialComment({
    required String matchId,
    required String highlightId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('entries')
          .doc(matchId)
          .collection('entries')
          .doc(highlightId)
          .collection('referee_comments')
          .where('isOfficial', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return RefereeComment.fromJson(snapshot.docs.first.data());
    } catch (e) {
      debugPrint('[CommentService] ❌ Error obtenint comentari oficial: $e');
      return null;
    }
  }

  /// Obté comentaris d'un àrbitre específic
  Future<List<RefereeComment>> getCommentsByReferee({
    required String userId,
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collectionGroup('referee_comments')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => RefereeComment.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[CommentService] ❌ Error obtenint comentaris d\'àrbitre: $e');
      return [];
    }
  }

  /// Obté la categoria d'àrbitre d'un usuari
  Future<RefereeCategory?> getUserCategory(String userId) async {
    try {
      // Buscar l'usuari a app_users per obtenir llissenciaId
      final userDoc = await _firestore.collection('app_users').doc(userId).get();

      if (!userDoc.exists) {
        debugPrint('[CommentService] Usuari no trobat a app_users');
        return null;
      }

      final userData = userDoc.data();
      final llissenciaId = userData?['llissenciaId'] as String?;

      if (llissenciaId == null) {
        debugPrint('[CommentService] Usuari no té llissenciaId');
        return null;
      }

      // Buscar l'àrbitre a referees_registry
      final refereeSnapshot = await _firestore
          .collection('referees_registry')
          .where('llissenciaId', isEqualTo: llissenciaId)
          .limit(1)
          .get();

      if (refereeSnapshot.docs.isEmpty) {
        debugPrint('[CommentService] Àrbitre no trobat a referees_registry');
        return null;
      }

      final refereeData = refereeSnapshot.docs.first.data();
      final categoriaRrtt = refereeData['categoriaRrtt'] as String?;

      return RefereeCategoryExtension.fromCategoriaRrtt(categoriaRrtt);
    } catch (e) {
      debugPrint('[CommentService] ❌ Error obtenint categoria: $e');
      return null;
    }
  }
}
