import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/personal_analysis.dart';
import '../services/personal_analysis_service.dart';

/// Provider per gestionar l'estat dels apunts personals d'un usuari
///
/// Responsable de:
/// - Estat reactiu dels apunts personals
/// - Gestió de streams en temps real per usuari
/// - Interfície amb PersonalAnalysisService
/// - Loading states i error handling
/// - Funcionalitats CRUD amb change detection
class PersonalAnalysisProvider extends ChangeNotifier {
  final PersonalAnalysisService _service;

  PersonalAnalysisProvider(this._service);

  // --- Camps d'estat privats ---
  String? _userId;
  bool _isLoading = false;
  String? _errorMessage;
  List<PersonalAnalysis> _analyses = [];
  StreamSubscription<List<PersonalAnalysis>>? _streamSubscription;

  // --- Getters públics ---

  /// ID de l'usuari actualment carregat
  String? get userId => _userId;

  /// Indica si s'està carregant contingut
  bool get isLoading => _isLoading;

  /// Missatge d'error actual (null si no hi ha error)
  String? get errorMessage => _errorMessage;

  /// Llista d'apunts personals ordenats cronològicament
  List<PersonalAnalysis> get analyses => List.unmodifiable(_analyses);

  /// Indica si hi ha apunts disponibles
  bool get hasAnalyses => _analyses.isNotEmpty;

  /// Nombre total d'apunts
  int get analysesCount => _analyses.length;

  /// Indica si hi ha un error actiu
  bool get hasError => _errorMessage != null;

  // --- Mètodes públics ---

  /// Estableix l'usuari a gestionar
  /// Cancel·la streams anteriors i inicia la càrrega del nou usuari
  void setUser(String userId) {
    if (_userId == userId) return; // No canvis si és el mateix usuari

    // Cancel·lar stream anterior
    _cancelStream();

    // Assignar nou userId
    _userId = userId;

    // Reinicialitzar estat
    _analyses.clear();
    _clearError();

    // Carregar apunts del nou usuari
    loadInitial();
  }

  /// Carrega els apunts inicials i activa el stream en temps real
  /// Prevé múltiples càrregues simultànies
  Future<void> loadInitial() async {
    if (_userId == null) {
      _setError('No s\'ha especificat un usuari');
      return;
    }

    if (_isLoading) return; // Prevenir múltiples càrregues

    _setLoading(true);
    _clearError();

    try {
      // Càrrega inicial (snapshot)
      final initialAnalyses = await _service.getForUser(_userId!);

      // Change detection i mounted check
      if (hasListeners) {
        _analyses = _sortAnalyses(initialAnalyses);

        // Activar stream en temps real només una vegada
        if (_streamSubscription == null) {
          _listenRealTime();
        }
      }
    } catch (e) {
      if (hasListeners) {
        _setError('Error carregant apunts personals: ${e.toString()}');
      }
    } finally {
      if (hasListeners) {
        _setLoading(false);
      }
    }
  }

  /// Activa l'escolta en temps real dels apunts personals
  void _listenRealTime() {
    if (_userId == null) return;

    _streamSubscription = _service
        .streamForUser(_userId!)
        .listen(
          (analyses) {
            // Change detection per evitar rebuilds innecessaris
            final sortedAnalyses = _sortAnalyses(analyses);
            if (!listEquals(_analyses, sortedAnalyses)) {
              _analyses = sortedAnalyses;
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

  /// Afegeix un nou apunt personal
  Future<void> addAnalysis(PersonalAnalysis analysis) async {
    if (_userId == null) {
      _setError('No s\'ha especificat un usuari');
      return;
    }

    if (!hasListeners) return; // Mounted check

    _setLoading(true);
    _clearError();

    try {
      await _service.addAnalysis(analysis);
      // El stream s'actualitzarà automàticament
    } catch (e) {
      if (hasListeners) {
        _setError('Error afegint apunt personal: ${e.toString()}');
      }
    } finally {
      if (hasListeners) {
        _setLoading(false);
      }
    }
  }

  /// Actualitza un apunt personal existent
  Future<void> updateAnalysis(PersonalAnalysis analysis) async {
    if (_userId == null) {
      _setError('No s\'ha especificat un usuari');
      return;
    }

    if (!hasListeners) return; // Mounted check

    _setLoading(true);
    _clearError();

    try {
      await _service.updateAnalysis(analysis);
      // El stream s'actualitzarà automàticament
    } catch (e) {
      if (hasListeners) {
        _setError('Error actualitzant apunt personal: ${e.toString()}');
      }
    } finally {
      if (hasListeners) {
        _setLoading(false);
      }
    }
  }

  /// Elimina un apunt personal per ID
  Future<void> deleteAnalysis(String analysisId) async {
    if (_userId == null) {
      _setError('No s\'ha especificat un usuari');
      return;
    }

    if (!hasListeners) return; // Mounted check

    _setLoading(true);
    _clearError();

    try {
      await _service.deleteAnalysis(_userId!, analysisId);
      // El stream s'actualitzarà automàticament
    } catch (e) {
      if (hasListeners) {
        _setError('Error eliminant apunt personal: ${e.toString()}');
      }
    } finally {
      if (hasListeners) {
        _setLoading(false);
      }
    }
  }

  /// Elimina tots els apunts personals de l'usuari actual
  Future<void> deleteAllAnalyses() async {
    if (_userId == null) {
      _setError('No s\'ha especificat un usuari');
      return;
    }

    if (!hasListeners) return; // Mounted check

    _setLoading(true);
    _clearError();

    try {
      await _service.deleteAllForUser(_userId!);
      // El stream s'actualitzarà automàticament
    } catch (e) {
      if (hasListeners) {
        _setError('Error eliminant tots els apunts: ${e.toString()}');
      }
    } finally {
      if (hasListeners) {
        _setLoading(false);
      }
    }
  }

  /// Obté apunts d'un partit específic
  Future<List<PersonalAnalysis>> getAnalysesForMatch(String matchId) async {
    if (_userId == null) {
      throw Exception('No s\'ha especificat un usuari');
    }

    try {
      return await _service.getForUserAndMatch(_userId!, matchId);
    } catch (e) {
      _setError('Error obtenint apunts del partit: ${e.toString()}');
      return [];
    }
  }

  /// Obté estadístiques dels apunts de l'usuari
  Future<Map<String, dynamic>> getStats() async {
    if (_userId == null) {
      throw Exception('No s\'ha especificat un usuari');
    }

    try {
      return await _service.getStatsForUser(_userId!);
    } catch (e) {
      _setError('Error obtenint estadístiques: ${e.toString()}');
      return {};
    }
  }

  /// Recarrega manualment l'estat dels apunts
  Future<void> refresh() async {
    if (_userId == null) return;

    await loadInitial();
  }

  /// Neteja l'error actual
  void clearError() {
    _clearError();
  }

  // --- Mètodes privats ---

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

  /// Ordena els apunts cronològicament (més antics primer)
  List<PersonalAnalysis> _sortAnalyses(List<PersonalAnalysis> analyses) {
    final sorted = List<PersonalAnalysis>.from(analyses);
    sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sorted;
  }

  // --- Mètodes auxiliars ---

  /// Obté un apunt específic per ID
  PersonalAnalysis? getAnalysisById(String analysisId) {
    try {
      return _analyses.firstWhere((analysis) => analysis.id == analysisId);
    } catch (e) {
      return null;
    }
  }

  /// Obté apunts que contenen un tag específic
  List<PersonalAnalysis> getAnalysesWithTag(AnalysisTag tag) {
    return _analyses.where((analysis) => analysis.tags.contains(tag)).toList();
  }

  /// Obté apunts d'una categoria específica
  List<PersonalAnalysis> getAnalysesByCategory(AnalysisCategory category) {
    return _analyses
        .where(
          (analysis) => analysis.tags.any((tag) => tag.category == category),
        )
        .toList();
  }

  /// Obté els apunts més recents (límit configurable)
  List<PersonalAnalysis> getRecentAnalyses({int limit = 5}) {
    final sorted = List<PersonalAnalysis>.from(_analyses);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(limit).toList();
  }

  /// Filtra apunts per text (cerca simple)
  List<PersonalAnalysis> searchAnalyses(String query) {
    if (query.trim().isEmpty) return _analyses;

    final lowerQuery = query.toLowerCase();
    return _analyses
        .where(
          (analysis) =>
              analysis.text.toLowerCase().contains(lowerQuery) ||
              analysis.userDisplayName.toLowerCase().contains(lowerQuery) ||
              analysis.tags.any(
                (tag) => tag.displayName.toLowerCase().contains(lowerQuery),
              ),
        )
        .toList();
  }

  @override
  void dispose() {
    _cancelStream();
    super.dispose();
  }
}
