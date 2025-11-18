import 'package:flutter/foundation.dart';
import '../models/youtube_video.dart';
import '../services/youtube_service.dart';

/// Provider per gestionar l'estat dels vídeos de YouTube
///
/// Responsable de:
/// - Carregar vídeos del canal Club del Árbitro
/// - Gestionar estats de càrrega i errors
/// - Proporcionar interfície reactiva per la UI
class YouTubeProvider extends ChangeNotifier {
  final YouTubeService _service;

  YouTubeProvider(this._service);

  // --- Camps d'estat privats ---
  bool _isLoading = false;
  String? _errorMessage;
  List<YouTubeVideo> _videos = [];
  DateTime? _lastLoadTime;

  // --- Getters públics ---

  /// Indica si s'està carregant contingut
  bool get isLoading => _isLoading;

  /// Missatge d'error actual (null si no hi ha error)
  String? get errorMessage => _errorMessage;

  /// Llista de vídeos ordenats per data de publicació (més recent primer)
  List<YouTubeVideo> get videos => List.unmodifiable(_videos);

  /// Indica si hi ha vídeos disponibles
  bool get hasVideos => _videos.isNotEmpty;

  /// Nombre total de vídeos
  int get videosCount => _videos.length;

  /// Indica si hi ha un error actiu
  bool get hasError => _errorMessage != null;

  /// Indica si s'han carregat les dades almenys una vegada
  bool get hasLoadedOnce => _lastLoadTime != null;

  /// Indica si cal actualitzar (més de 5 minuts des de l'última càrrega)
  bool get needsRefresh {
    if (_lastLoadTime == null) return true;
    final now = DateTime.now();
    final difference = now.difference(_lastLoadTime!);
    return difference.inMinutes > 5;
  }

  // --- Mètodes públics ---

  /// Carrega els vídeos més recents del canal
  ///
  /// Si [forceRefresh] és true, força la càrrega encara que sigui recent.
  /// Retorna true si la càrrega ha estat exitosa.
  Future<bool> loadVideos({bool forceRefresh = false}) async {
    // Evitar càrregues innecessàries
    if (_isLoading) return false;
    if (!forceRefresh && !needsRefresh && hasVideos) return true;

    _setLoading(true);
    _clearError();

    try {
      final videos = await _service.getLatestVideos();
      _videos = videos;
      _lastLoadTime = DateTime.now();

      if (kDebugMode) {
        print('YouTubeProvider: Carregats ${videos.length} vídeos');
      }

      notifyListeners();
      return true;
    } on YouTubeServiceException catch (e) {
      _setError(e.userFriendlyMessage);
      if (kDebugMode) {
        print('YouTubeProvider error: ${e.message}');
      }
      return false;
    } catch (e) {
      _setError('Error inesperat carregant vídeos');
      if (kDebugMode) {
        print('YouTubeProvider unexpected error: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Refresca els vídeos forçant una nova càrrega
  Future<bool> refresh() => loadVideos(forceRefresh: true);

  /// Neteja l'error actual i notifica els listeners
  void clearError() {
    if (_errorMessage != null) {
      _clearError();
      notifyListeners();
    }
  }

  /// Troba un vídeo per ID
  YouTubeVideo? findVideoById(String videoId) {
    try {
      return _videos.firstWhere((video) => video.videoId == videoId);
    } catch (e) {
      return null;
    }
  }

  // --- Mètodes privats ---

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  /// Inicialització lazy - crida automàticament loadVideos si no s'han carregat
  Future<void> ensureInitialized() async {
    if (!hasLoadedOnce && !isLoading) {
      await loadVideos();
    }
  }
}
