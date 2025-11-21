import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

/// Widget per mostrar un thumbnail animat del partit que redirigeix al vídeo real
class MatchThumbnailVideo extends StatefulWidget {
  final String thumbnailClipUrl;
  final String realMatchUrl;
  final double height;

  const MatchThumbnailVideo({
    super.key,
    required this.thumbnailClipUrl,
    required this.realMatchUrl,
    this.height = 240,
  });

  @override
  State<MatchThumbnailVideo> createState() => _MatchThumbnailVideoState();
}

class _MatchThumbnailVideoState extends State<MatchThumbnailVideo>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isVisible = true;
  bool _isDisposed = false;

  @override
  bool get wantKeepAlive => false; // No mantenir viu quan surt de vista

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Inicialització diferida per evitar càrrega immediata si no és visible
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        _checkVisibility();
        // Només inicialitzar si és visible o després d'un petit retard
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !_isDisposed && (_isVisible || !_isInitialized)) {
            _initializeVideoPlayer();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _disposeController();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (_isDisposed) return;
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
        _pauseVideo();
        break;
      case AppLifecycleState.resumed:
        if (_isVisible && _isInitialized && !_hasError) {
          _resumeVideo();
        }
        break;
      case AppLifecycleState.hidden:
        _pauseVideo();
        break;
    }
  }

  void _disposeController() {
    if (_controller != null) {
      _controller!.pause();
      _controller!.dispose();
      _controller = null;
    }
  }

  void _pauseVideo() {
    if (!_isDisposed && _controller != null && _controller!.value.isInitialized) {
      _controller!.pause();
    }
  }

  void _resumeVideo() {
    if (!_isDisposed && _controller != null && _controller!.value.isInitialized && _isVisible) {
      _controller!.play();
    }
  }

  Future<void> _initializeVideoPlayer() async {
    if (_isDisposed) return;
    
    try {
      // Verificar que la URL és vàlida
      if (widget.thumbnailClipUrl.isEmpty) {
        throw Exception('URL del thumbnail està buida');
      }

      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.thumbnailClipUrl),
      );

      await _controller!.initialize();

      if (mounted && !_isDisposed) {
        // Configure for animated thumbnail: loop, muted
        await _controller!.setLooping(true);
        await _controller!.setVolume(0.0);
        
        // Només reproduir si el widget és visible
        if (_isVisible) {
          await _controller!.play();
        }

        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint('Error inicialitzant video player: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          _hasError = true;
          _isInitialized = false;
        });
        // Netejar controller defectuós
        _disposeController();
      }
    }
  }

  Future<void> _openRealMatch() async {
    try {
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
    if (_controller == null || !_controller!.value.isInitialized || _isDisposed) {
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

          // Indicador de estat de reproducció (debug - es pot eliminar en producció)
          if (!_isVisible)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PAUSAT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
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
                    'CB Salt vs CB Martorell',
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
    super.build(context); // Necessari per AutomaticKeepAliveClientMixin
    
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        // Detectar canvis de scroll per gestionar visibilitat
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _checkVisibility();
        });
        return false; // Permetre que la notificació continuï propagant-se
      },
      child: LayoutBuilder(
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: _buildVideoContent(),
            ),
          );
        },
      ),
    );
  }

  void _checkVisibility() {
    if (_isDisposed || !mounted) return;
    
    try {
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.attached) return;
      
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      final screenHeight = MediaQuery.of(context).size.height;
      
      // Calcular si el widget és visible a la pantalla
      final isCurrentlyVisible = position.dy < screenHeight && 
                                position.dy + size.height > 0;
      
      if (_isVisible != isCurrentlyVisible) {
        _isVisible = isCurrentlyVisible;
        debugPrint('Video visibility changed: $_isVisible');
        
        if (_isVisible) {
          // Widget ara visible - resumir reproducció si està inicialitzat
          if (_isInitialized && !_hasError) {
            _resumeVideo();
          }
        } else {
          // Widget no visible - pausar per economitzar recursos
          _pauseVideo();
        }
      }
    } catch (e) {
      debugPrint('Error checking visibility: $e');
    }
  }
}

class MatchVideoSection extends StatelessWidget {
  /// URL del clip thumbnail animat (Firebase Storage)
  static const String kThumbnailClipUrl =
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/el_visionat.mp4?alt=media&token=7e1f8cd2-3c56-4f1e-8989-c2d9edb2075a';

  /// URL del partit real (exemple temporal)
  static const String kRealMatchUrl = 'https://www.twitch.tv/clubbasquetsalt';

  const MatchVideoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MatchThumbnailVideo(
            thumbnailClipUrl: kThumbnailClipUrl,
            realMatchUrl: kRealMatchUrl,
            height: 240,
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
