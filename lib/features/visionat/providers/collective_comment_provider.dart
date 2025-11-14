import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/collective_comment.dart';
import '../services/collective_comment_service.dart';

/// Provider per gestionar l'estat dels comentaris col·lectius d'un partit
///
/// Responsable de:
/// - Estat reactiu dels comentaris col·lectius
/// - Gestió de streams en temps real
/// - Interfície amb CollectiveCommentService
/// - Loading states i error handling
/// - Funcionalitats de likes i filtres per categoria
class VisionatCollectiveCommentProvider extends ChangeNotifier {
  final CollectiveCommentService _service;

  VisionatCollectiveCommentProvider(this._service);

  // --- Camps d'estat privats ---
  String? _matchId;
  bool _isLoading = false;
  String? _errorMessage;
  List<CollectiveComment> _comments = [];
  String? _selectedCategory; // tagId seleccionat (null = tots)
  StreamSubscription<List<CollectiveComment>>? _streamSubscription;

  // --- Getters públics ---

  /// ID del partit actualment carregat
  String? get matchId => _matchId;

  /// Indica si s'està carregant contingut
  bool get isLoading => _isLoading;

  /// Missatge d'error actual (null si no hi ha error)
  String? get errorMessage => _errorMessage;

  /// Llista de comentaris ordenats cronològicament
  List<CollectiveComment> get comments => List.unmodifiable(_comments);

  /// Categoria seleccionada (tagId) per filtrar
  String? get selectedCategory => _selectedCategory;

  /// Llista de comentaris filtrats per categoria (tagId)
  List<CollectiveComment> get filteredComments {
    if (_selectedCategory == null) return comments;
    return _comments.where((c) => c.tagId == _selectedCategory).toList();
  }

  /// Indica si hi ha comentaris disponibles (filtrats)
  bool get hasComments => filteredComments.isNotEmpty;

  /// Nombre total de comentaris (filtrats)
  int get commentsCount => filteredComments.length;

  /// Indica si hi ha un error actiu
  bool get hasError => _errorMessage != null;

  // --- Mètodes públics ---

  /// Estableix el partit a gestionar
  /// NOMÉS estableix el matchId, NO carrega automàticament
  void setMatch(String matchId) {
    if (_matchId == matchId) return; // No canvis si és el mateix partit

    // Cancel·lar stream anterior
    _cancelStream();

    // Assignar nou matchId
    _matchId = matchId;

    // Reinicialitzar estat
    _comments.clear();
    _selectedCategory = null;
    _clearError();

    // Carregar comentaris del nou partit
    loadInitial();
  }

  /// Carrega els comentaris inicials i activa el stream en temps real
  /// Prevé múltiples càrregues simultànies
  Future<void> loadInitial() async {
    if (_matchId == null) {
      _setError('No s\'ha especificat un partit');
      return;
    }

    if (_isLoading) return; // Prevenir múltiples cărgues

    _setLoading(true);
    _clearError();

    try {
      // Càrrega inicial (snapshot)
      final initialComments = await _service.getComments(_matchId!);

      // Change detection i mounted check
      if (hasListeners) {
        _comments = _sortComments(initialComments);

        // Activar stream en temps real només una vegada
        if (_streamSubscription == null) {
          _listenRealTime();
        }
      }
    } catch (e) {
      if (hasListeners) {
        _setError('Error carregant comentaris: ${e.toString()}');
      }
    } finally {
      if (hasListeners) {
        _setLoading(false);
      }
    }
  }

  /// Activa l'escolta en temps real dels comentaris
  void _listenRealTime() {
    if (_matchId == null) return;

    _streamSubscription = _service
        .streamComments(_matchId!)
        .listen(
          (comments) {
            // Change detection per evitar rebuilds innecessaris
            final sortedComments = _sortComments(comments);
            if (!listEquals(_comments, sortedComments)) {
              _comments = sortedComments;
              _clearError();
              // Mounted check per evitar calls després de dispose
              if (hasListeners) {
                notifyListeners();
              }
            }
          },
          onError: (error) {
            _setError('Error en temps real: ${error.toString()}');
          },
        );
  }

  /// Afegeix un nou comentari
  Future<void> addComment(CollectiveComment comment) async {
    if (_matchId == null) {
      _setError('No s\'ha especificat un partit');
      return;
    }

    if (!hasListeners) return; // Mounted check

    _setLoading(true);
    _clearError();

    try {
      await _service.addComment(comment);
      // El stream s'actualitzarà automàticament
    } catch (e) {
      if (hasListeners) {
        _setError('Error afegint comentari: ${e.toString()}');
      }
    } finally {
      if (hasListeners) {
        _setLoading(false);
      }
    }
  }

  /// Elimina un comentari per ID
  Future<void> deleteComment(String commentId) async {
    if (_matchId == null) {
      _setError('No s\'ha especificat un partit');
      return;
    }

    if (!hasListeners) return; // Mounted check

    _setLoading(true);
    _clearError();

    try {
      await _service.deleteComment(_matchId!, commentId);
      // El stream s'actualitzarà automàticament
    } catch (e) {
      if (hasListeners) {
        _setError('Error eliminant comentari: ${e.toString()}');
      }
    } finally {
      if (hasListeners) {
        _setLoading(false);
      }
    }
  }

  /// Edita un comentari existent
  Future<void> editComment(CollectiveComment updatedComment) async {
    if (_matchId == null) {
      _setError('No s\'ha especificat un partit');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      await _service.updateComment(updatedComment);
      // El stream s'actualitzarà automàticament
    } catch (e) {
      _setError('Error editant comentari: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Canvia l'estat de like d'un usuari per un comentari
  Future<void> toggleLike(String commentId, String userId) async {
    if (_matchId == null) {
      _setError('No s\'ha especificat un partit');
      return;
    }

    if (!hasListeners) return; // Mounted check

    try {
      await _service.toggleLike(_matchId!, commentId, userId);
      // El stream s'actualitzarà automàticament amb els nous likes
    } catch (e) {
      if (hasListeners) {
        _setError('Error canviant like: ${e.toString()}');
      }
    }
  }

  /// Estableix la categoria de filtre (tagId)
  void setCategory(String? tagId) {
    if (_selectedCategory != tagId) {
      _selectedCategory = tagId;
      if (hasListeners) {
        notifyListeners();
      }
    }
  }

  /// Recarrega manualment l'estat dels comentaris
  Future<void> refresh() async {
    if (_matchId == null) return;

    await loadInitial();
  }

  /// Neteja l'error actual
  void clearError() {
    _clearError();
  }

  // --- Mètodes privats de gestió d'estat ---

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      if (hasListeners) {
        notifyListeners();
      }
    }
  }

  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    if (hasListeners) {
      notifyListeners();
    }
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      if (hasListeners) {
        notifyListeners();
      }
    }
  }

  void _cancelStream() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
  }

  /// Ordena els comentaris cronològicament (per createdAt)
  List<CollectiveComment> _sortComments(List<CollectiveComment> comments) {
    final sorted = List<CollectiveComment>.from(comments);
    sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sorted;
  }

  // --- Mètodes auxiliars ---

  /// Obté un comentari específic per ID
  CollectiveComment? getCommentById(String commentId) {
    try {
      return _comments.firstWhere((comment) => comment.id == commentId);
    } catch (e) {
      return null;
    }
  }

  /// Obté comentaris d'un usuari específic
  List<CollectiveComment> getCommentsByUser(String userId) {
    return _comments.where((comment) => comment.createdBy == userId).toList();
  }

  /// Obté els comentaris més populars (amb més likes)
  List<CollectiveComment> getTopComments({int limit = 5}) {
    final sorted = List<CollectiveComment>.from(_comments);
    sorted.sort((a, b) => b.likes.compareTo(a.likes));
    return sorted.take(limit).toList();
  }

  /// Obté categories úniques dels comentaris actuals
  List<String> getAvailableCategories() {
    final categories = _comments.map((c) => c.tagId).toSet().toList();
    categories.sort();
    return categories;
  }

  // --- Cleanup ---

  @override
  void dispose() {
    _cancelStream();
    super.dispose();
  }
}
