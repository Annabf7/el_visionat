import 'package:flutter/material.dart';
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

class _MatchThumbnailVideoState extends State<MatchThumbnailVideo> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.thumbnailClipUrl),
      );

      await _controller!.initialize();

      if (mounted) {
        // Configure for animated thumbnail: loop, muted, autoplay
        _controller!
          ..setLooping(true)
          ..setVolume(0.0)
          ..play();

        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
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
    return GestureDetector(
      onTap: _openRealMatch,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'https://via.placeholder.com/640x360/2F313C/FFFFFF?text=CB+Salt+vs+CB+Martorell',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white70,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Toca per veure el partit',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Decorative play button
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
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
    );
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
