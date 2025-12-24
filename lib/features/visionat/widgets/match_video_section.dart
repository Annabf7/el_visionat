import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/core/widgets/visibility_detector_mixin.dart';
import '../providers/weekly_match_provider.dart';
import '../services/analyzed_matches_service.dart';

/// Widget per mostrar un thumbnail animat del partit que redirigeix al vídeo real
class MatchThumbnailVideo extends StatefulWidget {
  final String thumbnailClipUrl;
  final String realMatchUrl;
  final double height;
  final String? matchTitle;
  final String matchId; // ID del partit per tracking

  const MatchThumbnailVideo({
    super.key,
    required this.thumbnailClipUrl,
    required this.realMatchUrl,
    required this.matchId,
    this.height = 240,
    this.matchTitle,
  });

  @override
  State<MatchThumbnailVideo> createState() => _MatchThumbnailVideoState();
}

class _MatchThumbnailVideoState extends State<MatchThumbnailVideo>
    with WidgetsBindingObserver, VisibilityAndLifecycleDetectorMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    // Inicialització diferida per evitar càrrega immediata si no és visible
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && !isDisposed) {
        _initializeVideoPlayer();
      }
    });
  }

  @override
  void dispose() {
    _controller?.pause();
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  void onVisibilityChanged(bool isVisible) {
    if (!_isInitialized || _controller == null) return;

    if (isVisible) {
      _controller?.play();
      debugPrint('MatchThumbnailVideo: resumed playback');
    } else {
      _controller?.pause();
      debugPrint('MatchThumbnailVideo: paused to save resources');
    }
  }

  @override
  void onAppResumed() {
    if (_isInitialized &&
        isWidgetVisible &&
        _controller != null &&
        !_hasError) {
      _controller!.play();
    }
  }

  @override
  void onAppPaused() {
    _controller?.pause();
  }

  Future<void> _initializeVideoPlayer() async {
    if (isDisposed) return;

    // En mode debug mòbil (emulador Android), no fem autoplay per evitar warnings d'ImageReader
    // En web debug sí que fem autoplay perquè no té aquest problema
    if (kDebugMode && !kIsWeb) {
      debugPrint('MatchThumbnailVideo: autoplay desactivat en mode debug mòbil');
      if (mounted && !isDisposed) {
        setState(() {
          _isInitialized = false;
          _hasError = false;
        });
      }
      return;
    }

    try {
      // Verificar que la URL és vàlida
      if (widget.thumbnailClipUrl.isEmpty) {
        throw Exception('URL del thumbnail està buida');
      }

      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.thumbnailClipUrl),
      );

      await _controller!.initialize();

      if (mounted && !isDisposed) {
        // Configure for animated thumbnail: loop, muted
        await _controller!.setLooping(true);
        await _controller!.setVolume(0.0);

        // Només reproduir si el widget és visible
        if (isWidgetVisible) {
          await _controller!.play();
        }

        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint('Error inicialitzant match video player: $e');
      if (mounted && !isDisposed) {
        setState(() {
          _hasError = true;
          _isInitialized = false;
        });
        // Netejar controller defectuós
        _controller?.dispose();
        _controller = null;
      }
    }
  }

  Future<void> _openRealMatch() async {
    try {
      // Tracking: Marcar partit com analitzat abans d'obrir l'enllaç
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final analyzedMatchesService = AnalyzedMatchesService();
        await analyzedMatchesService.markMatchAsAnalyzed(
          user.uid,
          widget.matchId,
          action: 'video_click',
        );
        debugPrint('✅ Partit ${widget.matchId} marcat com analitzat (video_click)');
      }

      // Obrir el vídeo del partit
      final Uri url = Uri.parse(widget.realMatchUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  Widget _buildVideoContent() {
    if (_hasError) {
      return _buildErrorFallback();
    }

    if (!_isInitialized) {
      return _buildLoadingState();
    }

    return _buildVideoPlayer();
  }

  Widget _buildVideoPlayer() {
    // Verificacions de seguretat addicionals
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        isDisposed) {
      return _buildLoadingState();
    }

    return GestureDetector(
      onTap: _openRealMatch,
      child: Stack(
        children: [
          // Animated thumbnail video (looping, muted) - fills container
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),

          // Decorative play button overlay (always visible)
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator(color: Colors.white));
  }

  Widget _buildErrorFallback() {
    // Obtenir el títol del provider o usar el paràmetre
    final matchTitle = widget.matchTitle ?? 'Partit de la setmana';

    return GestureDetector(
      onTap: _openRealMatch,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.grisBody,
              AppTheme.porpraFosc.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Fallback estàtic sense NetworkImage per evitar més errors de xarxa
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sports_basketball,
                    color: AppTheme.mostassa,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    matchTitle,
                    style: TextStyle(
                      color: AppTheme.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toca per veure el partit',
                    style: TextStyle(
                      color: AppTheme.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Decorative play button
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.mostassa.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.play_arrow,
                  color: AppTheme.porpraFosc,
                  size: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildWithVisibilityDetection(
      LayoutBuilder(
        builder: (context, constraints) {
          // Responsive height calculation
          final double containerHeight;
          if (constraints.maxWidth > 900) {
            // Web/desktop: proportional height based on width
            containerHeight = constraints.maxWidth * 0.35;
          } else {
            // Mobile: fixed height
            containerHeight = widget.height;
          }

          return Container(
            height: containerHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: _buildVideoContent(),
            ),
          );
        },
      ),
    );
  }
}

class MatchVideoSection extends StatelessWidget {
  /// URL del clip thumbnail animat (Firebase Storage)
  static const String kThumbnailClipUrl =
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/el_visionat.mp4?alt=media&token=7e1f8cd2-3c56-4f1e-8989-c2d9edb2075a';

  /// URL del partit real (exemple temporal)
  static const String kRealMatchUrl = 'https://www.twitch.tv/clubbasquetsalt';

  final String matchId; // ID del partit per tracking

  const MatchVideoSection({
    super.key,
    required this.matchId,
  });

  @override
  Widget build(BuildContext context) {
    final matchProvider = context.watch<WeeklyMatchProvider>();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MatchThumbnailVideo(
            thumbnailClipUrl: kThumbnailClipUrl,
            realMatchUrl: kRealMatchUrl,
            matchId: matchId,
            height: 240,
            matchTitle: matchProvider.matchTitle,
          ),
          const SizedBox(height: 4),
          _buildActaButton(context),
        ],
      ),
    );
  }

  Widget _buildActaButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 12, top: 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.mostassa, // Yellow background
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: AppTheme.porpraFosc.withValues(alpha: 0.1),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: _onActaButtonPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      color: AppTheme.porpraFosc,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Acta',
                      style: TextStyle(
                        color: AppTheme.porpraFosc,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onActaButtonPressed() {
    const url =
        'https://www.basquetcatala.cat/estadistiques/video/aibasket/?matchCallUuid=1efe419f-97ab-4a6b-83f6-5daedc915057';
    debugPrint('Opening external URL: $url');
    // In a real implementation, would use url_launcher package
  }
}
