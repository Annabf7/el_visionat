import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/highlight_entry.dart';
import '../services/highlight_service.dart';

/// Provider per gestionar l'estat dels highlights d'un partit
///
/// Responsable de:
/// - Estat reactiu dels highlights
/// - Gestió de streams en temps real
/// - Interfície amb HighlightService
/// - Loading states i error handling
class VisionatHighlightProvider extends ChangeNotifier {
  final HighlightService _service;

  VisionatHighlightProvider(this._service);

  // --- Camps d'estat privats ---
  String? _matchId;
  bool _isLoading = false;
  String? _errorMessage;
  List<HighlightEntry> _highlights = [];
  StreamSubscription<List<HighlightEntry>>? _streamSubscription;
  String? _selectedCategory;

  // --- Getters públics ---

  /// ID del partit actualment carregat
  String? get matchId => _matchId;

  /// Indica si s'està carregant contingut
  bool get isLoading => _isLoading;

  /// Missatge d'error actual (null si no hi ha error)
  String? get errorMessage => _errorMessage;

  /// Llista d'highlights ordenats cronològicament
  List<HighlightEntry> get highlights => List.unmodifiable(_highlights);

  /// Categoria seleccionada per filtrar
  String? get selectedCategory => _selectedCategory;

  /// Llista d'highlights filtrats per categoria
  List<HighlightEntry> get filteredHighlights {
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
  /// Cancel·la streams anteriors i inicia la càrrega del nou partit
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
  Future<void> loadInitial() async {
    if (_matchId == null) {
      _setError('No s\'ha especificat un partit');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      // Càrrega inicial (snapshot)
      final initialHighlights = await _service.getHighlights(_matchId!);
      _highlights = _sortHighlights(initialHighlights);

      // Activar stream en temps real
      _listenRealTime();
    } catch (e) {
      _setError('Error carregant highlights: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Activa l'escolta en temps real dels highlights
  void _listenRealTime() {
    if (_matchId == null) return;

    _streamSubscription = _service
        .streamHighlights(_matchId!)
        .listen(
          (highlights) {
            _highlights = _sortHighlights(highlights);
            _clearError();
            notifyListeners();
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

    _setLoading(true);
    _clearError();

    try {
      await _service.addHighlight(entry);
      // El stream s'actualitzarà automàticament
    } catch (e) {
      _setError('Error afegint highlight: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Elimina un highlight per ID
  Future<void> deleteHighlight(String highlightId) async {
    if (_matchId == null) {
      _setError('No s\'ha especificat un partit');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      await _service.deleteHighlight(_matchId!, highlightId);
      // El stream s'actualitzarà automàticament
    } catch (e) {
      _setError('Error eliminant highlight: ${e.toString()}');
    } finally {
      _setLoading(false);
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
      notifyListeners();
    }
  }

  // --- Mètodes privats de gestió d'estat ---

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _cancelStream() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
  }

  /// Ordena els highlights cronològicament (per timestamp)
  List<HighlightEntry> _sortHighlights(List<HighlightEntry> highlights) {
    final sorted = List<HighlightEntry>.from(highlights);
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
