import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// Mobile implementation of ActivityVideoPlayer
/// Uses youtube_player_flutter which works on Android/iOS
///
/// Note: This class is named ActivityVideoPlayerWeb for compatibility
/// with conditional imports, even though it's the mobile implementation
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

class _ActivityVideoPlayerWebState extends State<ActivityVideoPlayerWeb> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: YoutubePlayerFlags(autoPlay: widget.autoPlay, mute: false),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoId.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: MediaQuery.of(context).size.width < 600 ? 200 : 220,
          child: YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
