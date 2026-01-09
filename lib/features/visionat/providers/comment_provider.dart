// ============================================================================
// CommentProvider - Gestió d'estat de comentaris per highlights
// ============================================================================
// Provider per gestionar comentaris en temps real amb streams de Firestore

import 'package:flutter/foundation.dart';
import 'package:el_visionat/features/visionat/models/comment.dart';
import 'package:el_visionat/features/visionat/services/comment_service.dart';
import 'dart:async';

/// Provider per gestionar comentaris d'un highlight específic
class CommentProvider extends ChangeNotifier {
  final CommentService _commentService = CommentService();

  // State
  List<CommentWithReplies> _commentsWithReplies = [];
  bool _isLoading = false;
  String? _error;

  // Current context
  String? _currentMatchId;
  String? _currentHighlightId;
  String? _currentUserId;

  // Stream subscriptions
  StreamSubscription<List<Comment>>? _mainCommentsSubscription;
  final Map<String, StreamSubscription<List<Comment>>> _repliesSubscriptions = {};

  // Track user likes
  final Set<String> _userLikedComments = {};

  // Getters
  List<CommentWithReplies> get commentsWithReplies => List.unmodifiable(_commentsWithReplies);
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalCommentsCount => _commentsWithReplies.fold(
    0,
    (sum, c) => sum + 1 + c.replies.length,
  );

  /// Inicialitza el provider per un highlight específic
  Future<void> initialize({
    required String matchId,
    required String highlightId,
    required String userId,
  }) async {
    debugPrint('[CommentProvider] initialize: $matchId/$highlightId for user $userId');

    // Si ja està inicialitzat per aquest highlight, no fer res
    if (_currentMatchId == matchId &&
        _currentHighlightId == highlightId &&
        _currentUserId == userId) {
      debugPrint('[CommentProvider] Ja inicialitzat per aquest highlight');
      return;
    }

    // Cancel·lar subscripcions anteriors
    await _cancelSubscriptions();

    // Actualitzar context
    _currentMatchId = matchId;
    _currentHighlightId = highlightId;
    _currentUserId = userId;

    // Reset state
    _commentsWithReplies = [];
    _userLikedComments.clear();
    _error = null;

    // Començar a escoltar comentaris principals
    _startListeningToMainComments();
  }

  /// Escolta comentaris principals en temps real
  void _startListeningToMainComments() {
    if (_currentMatchId == null || _currentHighlightId == null) return;

    _isLoading = true;
    notifyListeners();

    _mainCommentsSubscription = _commentService
        .watchMainComments(
          matchId: _currentMatchId!,
          highlightId: _currentHighlightId!,
        )
        .listen(
          (mainComments) async {
            debugPrint('[CommentProvider] Rebuts ${mainComments.length} comentaris principals');

            // Per cada comentari principal, escoltar les seves respostes
            for (final comment in mainComments) {
              _startListeningToReplies(comment.id);

              // Comprovar si l'usuari ha fet like
              if (_currentUserId != null) {
                final hasLiked = await _commentService.hasUserLiked(
                  matchId: _currentMatchId!,
                  highlightId: _currentHighlightId!,
                  commentId: comment.id,
                  userId: _currentUserId!,
                );
                if (hasLiked) {
                  _userLikedComments.add(comment.id);
                }
              }
            }

            // Actualitzar la llista de comentaris principals
            _updateMainComments(mainComments);

            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (error, stackTrace) {
            debugPrint('[CommentProvider] Error carregant comentaris: $error');
            debugPrint('[CommentProvider] StackTrace: $stackTrace');
            _error = 'Error carregant comentaris: ${error.toString()}';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  /// Escolta respostes d'un comentari específic
  void _startListeningToReplies(String parentCommentId) {
    if (_currentMatchId == null || _currentHighlightId == null) return;

    // Si ja estem escoltant aquest comentari, no fer res
    if (_repliesSubscriptions.containsKey(parentCommentId)) return;

    _repliesSubscriptions[parentCommentId] = _commentService
        .watchReplies(
          matchId: _currentMatchId!,
          highlightId: _currentHighlightId!,
          parentCommentId: parentCommentId,
        )
        .listen(
          (replies) async {
            debugPrint('[CommentProvider] Rebudes ${replies.length} respostes per $parentCommentId');

            // Comprovar likes per cada resposta
            if (_currentUserId != null) {
              for (final reply in replies) {
                final hasLiked = await _commentService.hasUserLiked(
                  matchId: _currentMatchId!,
                  highlightId: _currentHighlightId!,
                  commentId: reply.id,
                  userId: _currentUserId!,
                );
                if (hasLiked) {
                  _userLikedComments.add(reply.id);
                } else {
                  _userLikedComments.remove(reply.id);
                }
              }
            }

            // Actualitzar respostes per aquest comentari
            _updateRepliesForComment(parentCommentId, replies);
            notifyListeners();
          },
          onError: (error, stackTrace) {
            debugPrint('[CommentProvider] Error carregant respostes per $parentCommentId: $error');
            debugPrint('[CommentProvider] StackTrace: $stackTrace');
          },
        );
  }

  /// Actualitza la llista de comentaris principals
  void _updateMainComments(List<Comment> mainComments) {
    // Mantenir respostes existents per cada comentari
    final repliesMap = <String, List<Comment>>{};
    for (final cwm in _commentsWithReplies) {
      repliesMap[cwm.comment.id] = cwm.replies;
    }

    _commentsWithReplies = mainComments.map((comment) {
      final replies = repliesMap[comment.id] ?? [];
      final hasLiked = _userLikedComments.contains(comment.id);

      return CommentWithReplies(
        comment: comment,
        replies: replies,
        hasLiked: hasLiked,
      );
    }).toList();
  }

  /// Actualitza respostes per un comentari específic
  void _updateRepliesForComment(String commentId, List<Comment> replies) {
    final index = _commentsWithReplies.indexWhere((c) => c.comment.id == commentId);
    if (index == -1) return;

    _commentsWithReplies[index] = _commentsWithReplies[index].copyWith(
      replies: replies,
    );
  }

  /// Afegeix un comentari principal
  Future<void> addComment({
    required String text,
    required String userName,
    required String userCategory,
    String? userPhotoUrl,
    bool isOfficial = false,
  }) async {
    if (_currentMatchId == null ||
        _currentHighlightId == null ||
        _currentUserId == null) {
      _error = 'Context no inicialitzat';
      notifyListeners();
      return;
    }

    try {
      await _commentService.addComment(
        matchId: _currentMatchId!,
        highlightId: _currentHighlightId!,
        userId: _currentUserId!,
        userName: userName,
        userCategory: userCategory,
        userPhotoUrl: userPhotoUrl,
        text: text,
        isOfficial: isOfficial,
      );

      _error = null;
      // El stream actualitzarà automàticament
    } catch (e) {
      debugPrint('[CommentProvider] Error afegint comentari: $e');
      _error = 'Error afegint comentari';
      notifyListeners();
    }
  }

  /// Afegeix una resposta a un comentari
  Future<void> addReply({
    required String parentCommentId,
    required String text,
    required String userName,
    required String userCategory,
    String? userPhotoUrl,
    bool isOfficial = false,
  }) async {
    if (_currentMatchId == null ||
        _currentHighlightId == null ||
        _currentUserId == null) {
      _error = 'Context no inicialitzat';
      notifyListeners();
      return;
    }

    try {
      await _commentService.addReply(
        matchId: _currentMatchId!,
        highlightId: _currentHighlightId!,
        parentCommentId: parentCommentId,
        userId: _currentUserId!,
        userName: userName,
        userCategory: userCategory,
        userPhotoUrl: userPhotoUrl,
        text: text,
        isOfficial: isOfficial,
      );

      _error = null;
      // El stream actualitzarà automàticament
    } catch (e) {
      debugPrint('[CommentProvider] Error afegint resposta: $e');
      _error = 'Error afegint resposta';
      notifyListeners();
    }
  }

  /// Edita un comentari
  Future<void> updateComment({
    required String commentId,
    required String text,
  }) async {
    if (_currentMatchId == null || _currentHighlightId == null) {
      _error = 'Context no inicialitzat';
      notifyListeners();
      return;
    }

    try {
      await _commentService.updateComment(
        matchId: _currentMatchId!,
        highlightId: _currentHighlightId!,
        commentId: commentId,
        text: text,
      );

      _error = null;
      // El stream actualitzarà automàticament
    } catch (e) {
      debugPrint('[CommentProvider] Error actualitzant comentari: $e');
      _error = 'Error actualitzant comentari';
      notifyListeners();
    }
  }

  /// Elimina un comentari
  Future<void> deleteComment({
    required String commentId,
    required bool isReply,
    String? parentCommentId,
  }) async {
    if (_currentMatchId == null || _currentHighlightId == null) {
      _error = 'Context no inicialitzat';
      notifyListeners();
      return;
    }

    try {
      await _commentService.deleteComment(
        matchId: _currentMatchId!,
        highlightId: _currentHighlightId!,
        commentId: commentId,
        isReply: isReply,
        parentCommentId: parentCommentId,
      );

      _error = null;
      _userLikedComments.remove(commentId);
      // El stream actualitzarà automàticament
    } catch (e) {
      debugPrint('[CommentProvider] Error eliminant comentari: $e');
      _error = 'Error eliminant comentari';
      notifyListeners();
    }
  }

  /// Toggle like en un comentari
  Future<void> toggleLike(String commentId) async {
    if (_currentMatchId == null ||
        _currentHighlightId == null ||
        _currentUserId == null) {
      _error = 'Context no inicialitzat';
      notifyListeners();
      return;
    }

    final hasLiked = _userLikedComments.contains(commentId);

    try {
      if (hasLiked) {
        await _commentService.unlikeComment(
          matchId: _currentMatchId!,
          highlightId: _currentHighlightId!,
          commentId: commentId,
          userId: _currentUserId!,
        );
        _userLikedComments.remove(commentId);
      } else {
        await _commentService.likeComment(
          matchId: _currentMatchId!,
          highlightId: _currentHighlightId!,
          commentId: commentId,
          userId: _currentUserId!,
        );
        _userLikedComments.add(commentId);
      }

      _error = null;
      notifyListeners();
      // El stream actualitzarà automàticament els counts
    } catch (e) {
      debugPrint('[CommentProvider] Error toggle like: $e');
      _error = 'Error amb el like';
      notifyListeners();
    }
  }

  /// Comprova si l'usuari ha fet like a un comentari
  bool hasUserLiked(String commentId) {
    return _userLikedComments.contains(commentId);
  }

  /// Cancel·la totes les subscripcions
  Future<void> _cancelSubscriptions() async {
    await _mainCommentsSubscription?.cancel();
    _mainCommentsSubscription = null;

    for (final subscription in _repliesSubscriptions.values) {
      await subscription.cancel();
    }
    _repliesSubscriptions.clear();
  }

  /// Neteja l'error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset provider state
  void reset() {
    _cancelSubscriptions();
    _commentsWithReplies = [];
    _userLikedComments.clear();
    _currentMatchId = null;
    _currentHighlightId = null;
    _currentUserId = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}
