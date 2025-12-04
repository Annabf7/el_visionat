import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:el_visionat/core/widgets/visibility_detector_mixin.dart';

/// Mobile implementation of ActivityVideoPlayer
/// Uses youtube_player_flutter which works on Android/iOS
///
/// Implementació nativa/mòbil d'ActivityVideoPlayer
class ActivityVideoPlayerWeb extends StatefulWidget {
  final String videoId;
  final bool autoPlay;

  const ActivityVideoPlayerWeb({
    super.key,
    required this.videoId,
    this.autoPlay = false,
  });

  @override
  State<ActivityVideoPlayerWeb> createState() => _ActivityVideoPlayerWebState();
}

class _ActivityVideoPlayerWebState extends State<ActivityVideoPlayerWeb>
    with WidgetsBindingObserver, VisibilityAndLifecycleDetectorMixin {
  YoutubePlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  void _initializePlayer() {
    if (isDisposed) return;

    try {
      _controller = YoutubePlayerController(
        initialVideoId: widget.videoId,
        flags: YoutubePlayerFlags(
          autoPlay: widget.autoPlay && isWidgetVisible,
          mute: false,
          enableCaption: false,
        ),
      );

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing YouTube player: $e');
    }
  }

  @override
  void onVisibilityChanged(bool isVisible) {
    if (!_isInitialized || _controller == null) return;

    if (isVisible) {
      // Només reprodueix si estava en reproducció abans
      if (_controller!.value.playerState == PlayerState.paused) {
        _controller!.play();
        debugPrint('ActivityVideoPlayer: resumed YouTube playback');
      }
    } else {
      // Pausa el vídeo quan no és visible
      if (_controller!.value.playerState == PlayerState.playing) {
        _controller!.pause();
        debugPrint('ActivityVideoPlayer: paused YouTube to save resources');
      }
    }
  }

  @override
  void onAppResumed() {
    if (_isInitialized && isWidgetVisible && _controller != null) {
      // Només reprodueix si ho estava fent abans
      if (_controller!.value.playerState == PlayerState.paused) {
        _controller!.play();
      }
    }
  }

  @override
  void onAppPaused() {
    _controller?.pause();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoId.isEmpty) return const SizedBox.shrink();

    return buildWithVisibilityDetection(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: MediaQuery.of(context).size.width < 600 ? 200 : 220,
            child: _isInitialized && _controller != null
                ? YoutubePlayer(
                    controller: _controller!,
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: Theme.of(
                      context,
                    ).colorScheme.primary,
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }
}
