class ClipModel {
  final String title;
  final String subtitle;
  final String url;
  final bool isInstagram;
  final String? thumbnailUrl;

  const ClipModel({
    required this.title,
    required this.subtitle,
    required this.url,
    this.isInstagram = false,
    this.thumbnailUrl,
  });

  String getThumbnailUrl(String defaultUrl) {
    if (thumbnailUrl != null) return thumbnailUrl!;
    if (isInstagram) return defaultUrl;

    // Extracció bàsica de l'ID de YouTube
    try {
      final uri = Uri.parse(url);
      String? videoId;

      if (uri.host.contains('youtu.be')) {
        // En youtu.be, l'ID és el primer segment del path
        if (uri.pathSegments.isNotEmpty) {
          videoId = uri.pathSegments.first;
        }
      } else if (uri.host.contains('youtube.com')) {
        if (uri.pathSegments.contains('shorts')) {
          // Cas youtube.com/shorts/VIDEO_ID
          final shortsIndex = uri.pathSegments.indexOf('shorts');
          if (shortsIndex + 1 < uri.pathSegments.length) {
            videoId = uri.pathSegments[shortsIndex + 1];
          }
        } else {
          // Cas clàssic youtube.com/watch?v=VIDEO_ID
          videoId = uri.queryParameters['v'];
        }
      }

      if (videoId != null && videoId.isNotEmpty) {
        // Netejar un cop més per seguretat (per si de cas)
        if (videoId.contains('&')) videoId = videoId.split('&').first;
        if (videoId.contains('?')) videoId = videoId.split('?').first;

        return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
      }
    } catch (e) {
      // Ignorem errors de parsing
    }

    return defaultUrl;
  }
}
