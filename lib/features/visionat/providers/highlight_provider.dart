import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/highlight_entry.dart';
import '../models/highlight_play.dart';
import '../models/highlight_reaction.dart';
import '../models/referee_comment.dart';
import '../services/highlight_service.dart';
import '../services/highlight_reaction_service.dart';
import '../services/referee_comment_service.dart';
import 'package:el_visionat/core/constants/referee_category_colors.dart';

/// Provider per gestionar l'estat dels highlights d'un partit
///
/// Responsable de:
/// - Estat reactiu dels highlights
/// - Gestió de streams en temps real
/// - Interfície amb HighlightService
/// - Loading states i error handling
/// - Gestió de reaccions i comentaris d'àrbitres
class VisionatHighlightProvider extends ChangeNotifier {
  final HighlightService _service;
  final HighlightReactionService _reactionService;
  final RefereeCommentService _commentService;

  VisionatHighlightProvider(
    this._service, {
    HighlightReactionService? reactionService,
    RefereeCommentService? commentService,
  })  : _reactionService = reactionService ?? HighlightReactionService(),
        _commentService = commentService ?? RefereeCommentService();

  // --- Camps d'estat privats ---
  String? _matchId;
  bool _isLoading = false;
  String? _errorMessage;
  List<HighlightPlay> _highlights = [];
  StreamSubscription<List<HighlightPlay>>? _streamSubscription;
  String? _selectedCategory;

  // --- Getters públics ---

  /// ID del partit actualment carregat
  String? get matchId => _matchId;

  /// Indica si s'està carregant contingut
  bool get isLoading => _isLoading;

  /// Missatge d'error actual (null si no hi ha error)
  String? get errorMessage => _errorMessage;

  /// Llista d'highlights ordenats cronològicament
  List<HighlightPlay> get highlights => List.unmodifiable(_highlights);

  /// Categoria seleccionada per filtrar
  String? get selectedCategory => _selectedCategory;

  /// Llista d'highlights filtrats per categoria
  List<HighlightPlay> get filteredHighlights {
    if (_selectedCategory == null) return highlights;
    return _highlights.where((h) => h.category == _selectedCategory).toList();
  }

  /// Indica si hi ha highlights disponibles (filtrats)
  bool get hasHighlights => filteredHighlights.isNotEmpty;

  /// Nombre total d'highlights (filtrats)
  int get highlightsCount => filteredHighlights.length;

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
    _highlights.clear();
    _selectedCategory = null;
    _clearError();

    // Carregar highlights del nou partit
    loadInitial();
  }

  /// Carrega els highlights inicials i activa el stream en temps real
  /// Prevé múltiples càrregues simultànies
  Future<void> loadInitial() async {
    if (_matchId == null) {
      _setError('No s\'ha especificat un partit');
      return;
    }

    if (_isLoading) return; // Prevenir múltiples càrregues

    _setLoading(true);
    _clearError();

    try {
      // Càrrega inicial (snapshot)
      final initialHighlights = await _service.getHighlights(_matchId!);

      // Change detection i mounted check
      if (hasListeners) {
        _highlights = _sortHighlights(initialHighlights);

        // Activar stream en temps real només una vegada
        if (_streamSubscription == null) {
          _listenRealTime();
        }
      }
    } catch (e) {
      if (hasListeners) {
        _setError('Error carregant highlights: ${e.toString()}');
      }
    } finally {
      if (hasListeners) {
        _setLoading(false);
      }
    }
  }

  /// Activa l'escolta en temps real dels highlights
  void _listenRealTime() {
    if (_matchId == null) return;

    _streamSubscription = _service
        .streamHighlights(_matchId!)
        .listen(
          (highlights) {
            // Change detection per evitar rebuilds innecessaris
            final sortedHighlights = _sortHighlights(highlights);
            if (!listEquals(_highlights, sortedHighlights)) {
              _highlights = sortedHighlights;
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

  /// Afegeix un nou highlight
  Future<void> addHighlight(HighlightEntry entry) async {
    if (_matchId == null) {
      _setError('No s\'ha especificat un partit');
      return;
    }

    if (!hasListeners) return; // Mounted check

    _setLoading(true);
    _clearError();

    try {
      await _service.addHighlight(entry);
      // El stream s'actualitzarà automàticament
    } catch (e) {
      if (hasListeners) {
        _setError('Error afegint highlight: ${e.toString()}');
      }
    } finally {
      if (hasListeners) {
        _setLoading(false);
      }
    }
  }

  /// Elimina un highlight per ID
  Future<void> deleteHighlight(String highlightId) async {
    if (_matchId == null) {
      _setError('No s\'ha especificat un partit');
      return;
    }

    if (!hasListeners) return; // Mounted check

    _setLoading(true);
    _clearError();

    try {
      await _service.deleteHighlight(_matchId!, highlightId);
      // El stream s'actualitzarà automàticament
    } catch (e) {
      if (hasListeners) {
        _setError('Error eliminant highlight: ${e.toString()}');
      }
    } finally {
      if (hasListeners) {
        _setLoading(false);
      }
    }
  }

  /// Recarrega manualment l'estat dels highlights
  Future<void> refresh() async {
    if (_matchId == null) return;

    await loadInitial();
  }

  /// Neteja l'error actual
  void clearError() {
    _clearError();
  }

  /// Estableix la categoria de filtre
  void setCategory(String? category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      if (hasListeners) {
        notifyListeners();
      }
    }
  }

  // --- Mètodes de reaccions ---

  /// Alterna una reacció de l'usuari actual en un highlight
  Future<void> toggleReaction(String highlightId, ReactionType type) async {
    if (_matchId == null) {
      _setError('No s\'ha especificat un partit');
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _setError('Cal iniciar sessió per reaccionar');
      return;
    }

    // Validar que no sigui el creador del highlight
    final highlight = _highlights.firstWhere(
      (h) => h.id == highlightId,
      orElse: () => _highlights.first,
    );

    if (highlight.createdBy == currentUser.uid) {
      _setError('No pots reaccionar al teu propi highlight');
      return;
    }

    if (!hasListeners) return;

    try {
      await _reactionService.toggleReaction(
        matchId: _matchId!,
        highlightId: highlightId,
        userId: currentUser.uid,
        type: type,
      );
      // El stream s'actualitzarà automàticament
    } catch (e) {
      if (hasListeners) {
        _setError('Error gestionant reacció: ${e.toString()}');
      }
    }
  }

  /// Obté les reaccions de l'usuari actual per un highlight
  Set<ReactionType> getUserReactions(String highlightId) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return {};

    final highlight = _highlights.firstWhere(
      (h) => h.id == highlightId,
      orElse: () => _highlights.first,
    );

    return highlight.reactions
        .where((r) => r.userId == currentUser.uid)
        .map((r) => r.type)
        .toSet();
  }

  // --- Mètodes de comentaris d'àrbitres ---

  /// Afegeix un comentari d'àrbitre
  Future<void> addRefereeComment({
    required String highlightId,
    required String comment,
    required bool isAnonymous,
    bool isOfficial = false,
  }) async {
    if (_matchId == null) {
      _setError('No s\'ha especificat un partit');
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _setError('Cal iniciar sessió per comentar');
      return;
    }

    if (!hasListeners) return;

    _setLoading(true);
    _clearError();

    try {
      // Obtenir categoria de l'usuari actual
      final category = await getCurrentUserCategory();
      if (category == null) {
        throw Exception('No s\'ha pogut verificar la categoria d\'àrbitre');
      }

      await _commentService.addComment(
        matchId: _matchId!,
        highlightId: highlightId,
        userId: currentUser.uid,
        category: category,
        comment: comment,
        isAnonymous: isAnonymous,
        isOfficial: isOfficial,
      );
      // Èxit - el stream s'actualitzarà automàticament
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

  /// Stream de comentaris d'un highlight
  Stream<List<RefereeComment>> watchComments(String highlightId) {
    if (_matchId == null) {
      return Stream.value([]);
    }

    return _commentService.watchComments(
      matchId: _matchId!,
      highlightId: highlightId,
    );
  }

  /// Obté la categoria d'àrbitre de l'usuari actual
  Future<RefereeCategory?> getCurrentUserCategory() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;

    try {
      return await _commentService.getUserCategory(currentUser.uid);
    } catch (e) {
      debugPrint('[HighlightProvider] Error obtenint categoria: $e');
      return null;
    }
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

  /// Ordena els highlights cronològicament (per timestamp)
  List<HighlightPlay> _sortHighlights(List<HighlightPlay> highlights) {
    final sorted = List<HighlightPlay>.from(highlights);
    sorted.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return sorted;
  }

  // --- Cleanup ---

  @override
  void dispose() {
    _cancelStream();
    super.dispose();
  }
}
