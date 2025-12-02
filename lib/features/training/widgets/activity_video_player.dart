import 'package:flutter/material.dart';
import 'activity_video_player_web.dart'
    if (dart.library.io) 'activity_video_player_mobile.dart';

/// Widget ActivityVideoPlayer
/// Mostra un vídeo de YouTube embedit si es proporciona un videoId.
///
/// Aquesta implementació usa conditional imports per proporcionar
/// implementacions diferents per web i mobile/natiu:
/// - Web: ActivityVideoPlayerWeb (amb dart:html)
/// - Mobile/Native: ActivityVideoPlayerMobile (amb youtube_player_flutter)

class ActivityVideoPlayer extends StatelessWidget {
  final String videoId;

  /// Si true, el vídeo es reprodueix automàticament
  final bool autoPlay;

  const ActivityVideoPlayer({
    super.key,
    required this.videoId,
    this.autoPlay = false,
  });

  @override
  Widget build(BuildContext context) {
    if (videoId.isEmpty) return const SizedBox.shrink();

    // El conditional import automàticament selecciona la implementació correcta
    // El conditional import automàticament selecciona la implementació correcta
    return ActivityVideoPlayerWeb(videoId: videoId, autoPlay: autoPlay);
  }
}
