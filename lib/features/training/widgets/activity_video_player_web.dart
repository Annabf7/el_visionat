import 'package:flutter/material.dart';
// import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:web/web.dart' as web;

class ActivityVideoPlayerWeb extends StatelessWidget {
  final String videoId;
  final bool autoPlay;
  const ActivityVideoPlayerWeb({
    super.key,
    required this.videoId,
    this.autoPlay = false,
  });

  @override
  Widget build(BuildContext context) {
    if (videoId.isEmpty) return const SizedBox.shrink();
    // Fallback: show a clickable thumbnail that opens YouTube in a new tab (webview_flutter is not supported on Flutter web)
    final thumbUrl = 'https://img.youtube.com/vi/$videoId/0.jpg';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Image.network(
              thumbUrl,
              width: double.infinity,
              height: MediaQuery.of(context).size.width < 600 ? 200 : 220,
              fit: BoxFit.cover,
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _launchYoutube(videoId),
                  child: Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white.withAlpha((0.85 * 255).round()),
                      size: 64,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchYoutube(String videoId) {
    final url = 'https://www.youtube.com/watch?v=$videoId';
    // Use modern web API for web compatibility
    web.window.open(url, '_blank');
  }
}
