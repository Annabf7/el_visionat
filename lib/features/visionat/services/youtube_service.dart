import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/youtube_video.dart';

/// Excepció específica per errors del servei de YouTube
class YouTubeServiceException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalException;

  const YouTubeServiceException(
    this.message, {
    this.statusCode,
    this.originalException,
  });

  @override
  String toString() => 'YouTubeServiceException: $message';

  /// Missatge d'error amigable per mostrar a l'usuari
  String get userFriendlyMessage {
    if (statusCode == 404) {
      return 'No s\'han pogut trobar els vídeos. Torna-ho a provar més tard.';
    }
    if (statusCode != null && statusCode! >= 500) {
      return 'Error del servidor. Torna-ho a provar en uns minuts.';
    }
    return 'No s\'han pogut carregar els vídeos. Comprova la connexió a Internet.';
  }
}

/// Servei per obtenir vídeos de YouTube del canal Club del Árbitro
///
/// Crida a la Cloud Function getYouTubeVideos que gestiona
/// l'autenticació amb l'API de YouTube i retorna els 5 vídeos més recents.
class YouTubeService {
  static const String _baseUrl =
      'https://europe-west1-el-visionat.cloudfunctions.net';
  static const String _endpoint = '/getYouTubeVideos';

  final http.Client _httpClient;

  YouTubeService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  /// Obté els vídeos més recents del canal Club del Árbitro
  ///
  /// Retorna una llista de [YouTubeVideo] ordenada cronològicament
  /// (més recent primer).
  ///
  /// Llança [YouTubeServiceException] en cas d'error.
  Future<List<YouTubeVideo>> getLatestVideos() async {
    try {
      final uri = Uri.parse('$_baseUrl$_endpoint');

      final response = await _httpClient.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw YouTubeServiceException(
          'Error HTTP ${response.statusCode}: ${response.reasonPhrase}',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> data = json.decode(response.body);

      // Verificar estructura de resposta
      if (data['success'] != true) {
        throw YouTubeServiceException(
          'La resposta de l\'API no indica èxit: ${data['error'] ?? 'Error desconegut'}',
        );
      }

      final List<dynamic> videosJson = data['videos'] ?? [];

      final videos = videosJson
          .map((json) => YouTubeVideo.fromJson(json as Map<String, dynamic>))
          .toList();

      // Ordenar per data de publicació (més recent primer)
      videos.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

      return videos;
    } on YouTubeServiceException {
      rethrow;
    } catch (e) {
      throw YouTubeServiceException(
        'Error inesperat obtenint vídeos: $e',
        originalException: e,
      );
    }
  }

  /// Allibera recursos del client HTTP
  void dispose() {
    _httpClient.close();
  }
}
