import 'package:flutter/foundation.dart';
import '../models/youtube_video.dart';
import '../services/youtube_service.dart';
import '../services/watched_clip_service.dart';
import 'dart:async';

/// Provider per gestionar l'estat dels vídeos de YouTube
///
/// Responsable de:
/// - Carregar vídeos del canal Club del Árbitro
/// - Gestionar estats de càrrega i errors
/// - Tracking de clips vistos per l'usuari
/// - Proporcionar interfície reactiva per la UI
class YouTubeProvider extends ChangeNotifier {
  final YouTubeService _service;
  final WatchedClipService _watchedClipService;

  YouTubeProvider(this._service)
      : _watchedClipService = WatchedClipService();

  // --- Camps d'estat privats ---
  bool _isLoading = false;
  String? _errorMessage;
  List<YouTubeVideo> _videos = [];
  DateTime? _lastLoadTime;

  // Tracking de clips vistos
  String? _currentUserId;
  Set<String> _watchedVideoIds = {};
  StreamSubscription<List<String>>? _watchedVideosSubscription;

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

  /// Comprova si un vídeo ha estat vist per l'usuari actual
  bool isVideoWatched(String videoId) {
    return _watchedVideoIds.contains(videoId);
  }

  /// Nombre de vídeos vistos per l'usuari actual
  int get watchedVideosCount => _watchedVideoIds.length;

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
    _watchedVideosSubscription?.cancel();
    _service.dispose();
    super.dispose();
  }

  /// Inicialització lazy - crida automàticament loadVideos si no s'han carregat
  Future<void> ensureInitialized() async {
    if (!hasLoadedOnce && !isLoading) {
      await loadVideos();
    }
  }

  // --- Mètodes de tracking de clips vistos ---

  /// Inicialitza el tracking de clips vistos per un usuari específic
  ///
  /// Comença a escoltar en temps real els clips vistos per l'usuari.
  /// Si ja s'està fent tracking per aquest usuari, no fa res.
  Future<void> initializeWatchedTracking(String userId) async {
    // Si ja estem fent tracking per aquest usuari, no fer res
    if (_currentUserId == userId && _watchedVideosSubscription != null) {
      return;
    }

    // Cancel·lar subscripció anterior si n'hi ha
    await _watchedVideosSubscription?.cancel();

    // Actualitzar l'usuari actual
    _currentUserId = userId;
    _watchedVideoIds.clear();

    // Començar a escoltar clips vistos en temps real
    _watchedVideosSubscription = _watchedClipService
        .watchWatchedVideoIds(userId)
        .listen((watchedIds) {
      _watchedVideoIds = watchedIds.toSet();
      notifyListeners();

      if (kDebugMode) {
        print('YouTubeProvider: Actualitzats ${_watchedVideoIds.length} clips vistos');
      }
    }, onError: (error) {
      if (kDebugMode) {
        print('YouTubeProvider: Error escoltant clips vistos: $error');
      }
    });

    if (kDebugMode) {
      print('YouTubeProvider: Tracking inicialitzat per usuari $userId');
    }
  }

  /// Marca un vídeo com a vist o no vist
  Future<void> toggleWatchedStatus(String videoId) async {
    if (_currentUserId == null) {
      if (kDebugMode) {
        print('YouTubeProvider: No hi ha usuari per fer tracking');
      }
      return;
    }

    try {
      final isWatched = _watchedVideoIds.contains(videoId);

      if (isWatched) {
        await _watchedClipService.unmarkAsWatched(
          userId: _currentUserId!,
          videoId: videoId,
        );
      } else {
        await _watchedClipService.markAsWatched(
          userId: _currentUserId!,
          videoId: videoId,
        );
      }

      if (kDebugMode) {
        print('YouTubeProvider: Vídeo $videoId marcat com ${isWatched ? 'no vist' : 'vist'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('YouTubeProvider: Error togglejant estat vist: $e');
      }
      rethrow;
    }
  }

  /// Atura el tracking de clips vistos
  Future<void> stopWatchedTracking() async {
    await _watchedVideosSubscription?.cancel();
    _watchedVideosSubscription = null;
    _currentUserId = null;
    _watchedVideoIds.clear();
    notifyListeners();

    if (kDebugMode) {
      print('YouTubeProvider: Tracking aturat');
    }
  }
}
