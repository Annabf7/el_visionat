import 'package:intl/intl.dart';

/// Model per representar un vídeo de YouTube del canal Club del Árbitro
///
/// Conté la informació necessària per mostrar i enllaçar els vídeos
/// a la interfície d'usuari de l'aplicació El Visionat.
class YouTubeVideo {
  final String videoId;
  final String title;
  final String thumbnailUrl;
  final DateTime publishedAt;

  const YouTubeVideo({
    required this.videoId,
    required this.title,
    required this.thumbnailUrl,
    required this.publishedAt,
  });

  /// Crea una instància des de JSON (resposta de l'API)
  factory YouTubeVideo.fromJson(Map<String, dynamic> json) {
    return YouTubeVideo(
      videoId: json['videoId'] as String,
      title: json['title'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
    );
  }

  /// Converteix a JSON per serialització
  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'publishedAt': publishedAt.toIso8601String(),
    };
  }

  /// URL completa del vídeo a YouTube
  String get youtubeUrl => 'https://www.youtube.com/watch?v=$videoId';

  /// Data formatada per mostrar a la interfície
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);

    if (difference.inDays > 30) {
      return DateFormat('d MMM yyyy').format(publishedAt);
    } else if (difference.inDays > 0) {
      return 'fa ${difference.inDays} ${difference.inDays == 1 ? 'dia' : 'dies'}';
    } else if (difference.inHours > 0) {
      return 'fa ${difference.inHours} ${difference.inHours == 1 ? 'hora' : 'hores'}';
    } else {
      return 'fa ${difference.inMinutes} minuts';
    }
  }

  /// Títol truncat per evitar overflow en UI
  String get displayTitle {
    if (title.length <= 50) return title;
    return '${title.substring(0, 47)}...';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is YouTubeVideo && other.videoId == videoId;
  }

  @override
  int get hashCode => videoId.hashCode;

  @override
  String toString() => 'YouTubeVideo(videoId: $videoId, title: $title)';

  /// Crea una còpia amb valors modificats
  YouTubeVideo copyWith({
    String? videoId,
    String? title,
    String? thumbnailUrl,
    DateTime? publishedAt,
  }) {
    return YouTubeVideo(
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }
}