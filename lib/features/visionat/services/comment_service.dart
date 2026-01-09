// ============================================================================
// CommentService - Gestió de comentaris per highlights
// ============================================================================
// Operacions CRUD per comentaris i likes

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/comment.dart';

class CommentService {
  static final CommentService _instance = CommentService._internal();
  factory CommentService() => _instance;
  CommentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obté la referència d'un highlight
  DocumentReference _highlightRef(String matchId, String highlightId) {
    return _firestore
        .collection('entries')
        .doc(matchId)
        .collection('entries')
        .doc(highlightId);
  }

  /// Obté la col·lecció de comentaris d'un highlight
  CollectionReference _commentsCollection(String matchId, String highlightId) {
    return _highlightRef(matchId, highlightId).collection('comments');
  }

  /// Stream de comentaris principals (no respostes) ordenats per data
  Stream<List<Comment>> watchMainComments({
    required String matchId,
    required String highlightId,
  }) {
    debugPrint('[CommentService] watchMainComments: $matchId/$highlightId');

    return _commentsCollection(matchId, highlightId)
        .where('parentCommentId', isNull: true)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Comment.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  /// Stream de respostes d'un comentari específic
  Stream<List<Comment>> watchReplies({
    required String matchId,
    required String highlightId,
    required String parentCommentId,
  }) {
    return _commentsCollection(matchId, highlightId)
        .where('parentCommentId', isEqualTo: parentCommentId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Comment.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  /// Afegeix un comentari principal
  Future<Comment> addComment({
    required String matchId,
    required String highlightId,
    required String userId,
    required String userName,
    required String userCategory,
    String? userPhotoUrl,
    required String text,
    bool isOfficial = false,
  }) async {
    try {
      final commentRef = _commentsCollection(matchId, highlightId).doc();

      final comment = Comment(
        id: commentRef.id,
        matchId: matchId,
        highlightId: highlightId,
        userId: userId,
        userName: userName,
        userCategory: userCategory,
        userPhotoUrl: userPhotoUrl,
        text: text,
        createdAt: DateTime.now(),
        isOfficial: isOfficial,
      );

      await commentRef.set(comment.toJson());

      // Actualitzar commentCount del highlight
      await _updateHighlightCommentCount(matchId, highlightId, increment: 1);

      debugPrint('[CommentService] ✅ Comentari afegit: ${comment.id}');
      return comment;
    } catch (e) {
      debugPrint('[CommentService] ❌ Error afegint comentari: $e');
      rethrow;
    }
  }

  /// Afegeix una resposta a un comentari
  Future<Comment> addReply({
    required String matchId,
    required String highlightId,
    required String parentCommentId,
    required String userId,
    required String userName,
    required String userCategory,
    String? userPhotoUrl,
    required String text,
    bool isOfficial = false,
  }) async {
    try {
      final commentRef = _commentsCollection(matchId, highlightId).doc();

      final reply = Comment(
        id: commentRef.id,
        matchId: matchId,
        highlightId: highlightId,
        userId: userId,
        userName: userName,
        userCategory: userCategory,
        userPhotoUrl: userPhotoUrl,
        text: text,
        createdAt: DateTime.now(),
        isOfficial: isOfficial,
        parentCommentId: parentCommentId,
      );

      await commentRef.set(reply.toJson());

      // Incrementar repliesCount del comentari pare
      await _updateCommentRepliesCount(
        matchId,
        highlightId,
        parentCommentId,
        increment: 1,
      );

      // Actualitzar commentCount del highlight
      await _updateHighlightCommentCount(matchId, highlightId, increment: 1);

      debugPrint('[CommentService] ✅ Resposta afegida: ${reply.id}');
      return reply;
    } catch (e) {
      debugPrint('[CommentService] ❌ Error afegint resposta: $e');
      rethrow;
    }
  }

  /// Edita un comentari
  Future<void> updateComment({
    required String matchId,
    required String highlightId,
    required String commentId,
    required String text,
  }) async {
    try {
      await _commentsCollection(matchId, highlightId).doc(commentId).update({
        'text': text,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[CommentService] ✅ Comentari actualitzat: $commentId');
    } catch (e) {
      debugPrint('[CommentService] ❌ Error actualitzant comentari: $e');
      rethrow;
    }
  }

  /// Elimina un comentari
  Future<void> deleteComment({
    required String matchId,
    required String highlightId,
    required String commentId,
    required bool isReply,
    String? parentCommentId,
  }) async {
    try {
      // Obtenir comentari per saber quantes respostes té
      final commentDoc = await _commentsCollection(matchId, highlightId)
          .doc(commentId)
          .get();

      if (!commentDoc.exists) return;

      final comment = Comment.fromJson(commentDoc.data() as Map<String, dynamic>);

      // Eliminar totes les respostes si n'hi ha
      if (!isReply && comment.repliesCount > 0) {
        final repliesSnapshot = await _commentsCollection(matchId, highlightId)
            .where('parentCommentId', isEqualTo: commentId)
            .get();

        final batch = _firestore.batch();
        for (final doc in repliesSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        // Decrementar commentCount per cada resposta eliminada
        await _updateHighlightCommentCount(
          matchId,
          highlightId,
          increment: -comment.repliesCount,
        );
      }

      // Eliminar el comentari
      await _commentsCollection(matchId, highlightId).doc(commentId).delete();

      // Si és una resposta, decrementar repliesCount del pare
      if (isReply && parentCommentId != null) {
        await _updateCommentRepliesCount(
          matchId,
          highlightId,
          parentCommentId,
          increment: -1,
        );
      }

      // Decrementar commentCount del highlight
      await _updateHighlightCommentCount(matchId, highlightId, increment: -1);

      debugPrint('[CommentService] ✅ Comentari eliminat: $commentId');
    } catch (e) {
      debugPrint('[CommentService] ❌ Error eliminant comentari: $e');
      rethrow;
    }
  }

  /// Fa like a un comentari
  Future<void> likeComment({
    required String matchId,
    required String highlightId,
    required String commentId,
    required String userId,
  }) async {
    try {
      final likeRef = _commentsCollection(matchId, highlightId)
          .doc(commentId)
          .collection('likes')
          .doc(userId);

      await likeRef.set({
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Incrementar likesCount
      await _commentsCollection(matchId, highlightId).doc(commentId).update({
        'likesCount': FieldValue.increment(1),
      });

      debugPrint('[CommentService] ✅ Like afegit al comentari $commentId');
    } catch (e) {
      debugPrint('[CommentService] ❌ Error afegint like: $e');
      rethrow;
    }
  }

  /// Treu el like d'un comentari
  Future<void> unlikeComment({
    required String matchId,
    required String highlightId,
    required String commentId,
    required String userId,
  }) async {
    try {
      final likeRef = _commentsCollection(matchId, highlightId)
          .doc(commentId)
          .collection('likes')
          .doc(userId);

      await likeRef.delete();

      // Decrementar likesCount
      await _commentsCollection(matchId, highlightId).doc(commentId).update({
        'likesCount': FieldValue.increment(-1),
      });

      debugPrint('[CommentService] ✅ Like eliminat del comentari $commentId');
    } catch (e) {
      debugPrint('[CommentService] ❌ Error eliminant like: $e');
      rethrow;
    }
  }

  /// Comprova si l'usuari ha fet like al comentari
  Future<bool> hasUserLiked({
    required String matchId,
    required String highlightId,
    required String commentId,
    required String userId,
  }) async {
    try {
      final likeDoc = await _commentsCollection(matchId, highlightId)
          .doc(commentId)
          .collection('likes')
          .doc(userId)
          .get();

      return likeDoc.exists;
    } catch (e) {
      debugPrint('[CommentService] ❌ Error comprovant like: $e');
      return false;
    }
  }

  /// Actualitza el comptador de comentaris del highlight
  Future<void> _updateHighlightCommentCount(
    String matchId,
    String highlightId, {
    required int increment,
  }) async {
    try {
      await _highlightRef(matchId, highlightId).update({
        'commentCount': FieldValue.increment(increment),
      });
    } catch (e) {
      debugPrint('[CommentService] ⚠️ Error actualitzant commentCount: $e');
    }
  }

  /// Actualitza el comptador de respostes d'un comentari
  Future<void> _updateCommentRepliesCount(
    String matchId,
    String highlightId,
    String commentId, {
    required int increment,
  }) async {
    try {
      await _commentsCollection(matchId, highlightId).doc(commentId).update({
        'repliesCount': FieldValue.increment(increment),
      });
    } catch (e) {
      debugPrint('[CommentService] ⚠️ Error actualitzant repliesCount: $e');
    }
  }

  /// Obté el comptador total de comentaris d'un highlight
  Future<int> getCommentCount({
    required String matchId,
    required String highlightId,
  }) async {
    try {
      final snapshot =
          await _commentsCollection(matchId, highlightId).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('[CommentService] ❌ Error obtenint commentCount: $e');
      return 0;
    }
  }
}
