import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/collective_comment.dart';
import 'analyzed_matches_service.dart';

/// Servei per gestionar comentaris col·lectius de partits a Firestore
/// 
/// Estructura de col·lecció: collective_comments/{matchId}/entries/{commentId}
/// Proporciona operacions CRUD amb streams en temps real i funcionalitats de likes
class CollectiveCommentService {
  final FirebaseFirestore _firestore;

  CollectiveCommentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Referència a la col·lecció de comentaris d'un partit específic
  CollectionReference<CollectiveComment> _commentsCollection(String matchId) {
    return _firestore
        .collection('collective_comments')
        .doc(matchId)
        .collection('entries')
        .withConverter<CollectiveComment>(
          fromFirestore: CollectiveComment.fromFirestore,
          toFirestore: CollectiveComment.toFirestore,
        );
  }

  /// Stream de comentaris en temps real per un partit específic
  /// Ordenats per createdAt ascendent (cronològic)
  Stream<List<CollectiveComment>> streamComments(String matchId) {
    return _commentsCollection(matchId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  /// Obté tots els comentaris d'un partit (snapshot únic, no stream)
  /// Ordenats per createdAt ascendent (cronològic)
  Future<List<CollectiveComment>> getComments(String matchId) async {
    try {
      final snapshot = await _commentsCollection(matchId)
          .orderBy('createdAt', descending: false)
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error obtenint comentaris: $e');
    }
  }

  /// Afegeix un nou comentari a Firestore
  /// Si comment.id està buit, genera un ID automàticament
  Future<void> addComment(CollectiveComment comment) async {
    try {
      final collection = _commentsCollection(comment.matchId);

      // Si no té ID, generar-ne un automàticament
      if (comment.id.isEmpty) {
        final docRef = collection.doc();
        final commentWithId = comment.copyWith(id: docRef.id);
        await docRef.set(commentWithId);
      } else {
        // Usar l'ID existent
        await collection.doc(comment.id).set(comment);
      }

      // Tracking: Marcar partit com analitzat
      final analyzedMatchesService = AnalyzedMatchesService();
      await analyzedMatchesService.markMatchAsAnalyzed(
        comment.createdBy,
        comment.matchId,
        action: 'collective_comment',
      );
    } catch (e) {
      throw Exception('Error afegint comentari: $e');
    }
  }

  /// Actualitza un comentari existent
  /// Marca el comentari com editat i actualitza editedAt
  Future<void> updateComment(CollectiveComment comment) async {
    try {
      final updatedComment = comment.copyWith(
        isEdited: true,
        editedAt: DateTime.now(),
      );
      await _commentsCollection(comment.matchId)
          .doc(comment.id)
          .update(updatedComment.toJson());
    } catch (e) {
      throw Exception('Error actualitzant comentari: $e');
    }
  }

  /// Elimina un comentari específic
  Future<void> deleteComment(String matchId, String commentId) async {
    try {
      await _commentsCollection(matchId).doc(commentId).delete();
    } catch (e) {
      throw Exception('Error eliminant comentari: $e');
    }
  }

  /// Canvia l'estat de like d'un usuari per un comentari
  /// Si userId està a likedBy → el treu i decrementa likes
  /// Si userId no està a likedBy → l'afegeix i incrementa likes
  Future<void> toggleLike(String matchId, String commentId, String userId) async {
    try {
      final docRef = _commentsCollection(matchId).doc(commentId);
      
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        
        if (!snapshot.exists) {
          throw Exception('El comentari no existeix');
        }
        
        final comment = snapshot.data()!;
        final likedBy = List<String>.from(comment.likedBy);
        int likes = comment.likes;
        
        if (likedBy.contains(userId)) {
          // Usuari ja ha donat like → treure like
          likedBy.remove(userId);
          likes = (likes - 1).clamp(0, double.infinity).toInt();
        } else {
          // Usuari no ha donat like → afegir like
          likedBy.add(userId);
          likes += 1;
        }
        
        final updatedComment = comment.copyWith(
          likes: likes,
          likedBy: likedBy,
        );
        
        transaction.update(docRef, updatedComment.toJson());
      });
    } catch (e) {
      throw Exception('Error canviant like: $e');
    }
  }

  /// Compta el nombre de comentaris d'un partit
  Future<int> countComments(String matchId) async {
    try {
      final snapshot = await _commentsCollection(matchId).get();
      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Error comptant comentaris: $e');
    }
  }

  /// Obté un comentari específic (mètode auxiliar)
  Future<CollectiveComment?> getComment(String matchId, String commentId) async {
    try {
      final doc = await _commentsCollection(matchId).doc(commentId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      throw Exception('Error obtenint comentari: $e');
    }
  }

  /// Elimina tots els comentaris d'un partit
  /// Utilitza batch operation per eficiència
  Future<void> deleteAllComments(String matchId) async {
    try {
      final snapshot = await _commentsCollection(matchId).get();
      final batch = _firestore.batch();
      
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Error eliminant tots els comentaris: $e');
    }
  }

  /// Obté comentaris d'un usuari específic dins un partit
  Future<List<CollectiveComment>> getCommentsByUser(String matchId, String userId) async {
    try {
      final snapshot = await _commentsCollection(matchId)
          .where('createdBy', isEqualTo: userId)
          .orderBy('createdAt', descending: false)
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error obtenint comentaris de l\'usuari: $e');
    }
  }

  /// Obté els comentaris més populars (amb més likes)
  Future<List<CollectiveComment>> getTopComments(String matchId, {int limit = 10}) async {
    try {
      final snapshot = await _commentsCollection(matchId)
          .orderBy('likes', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error obtenint comentaris populars: $e');
    }
  }
}