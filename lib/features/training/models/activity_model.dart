import 'question_model.dart';

class ActivityModel {
  /// Identificador únic de l'activitat
  final String id;

  /// Títol de l'activitat
  final String title;

  /// ID del vídeo de YouTube (null si no en té)
  final String? youtubeVideoId;

  /// Llista de preguntes autoavaluatives
  final List<QuestionModel> questions;

  /// Data d'activació (null = sempre disponible)
  final DateTime? availableFrom;

  /// Constructor immutable
  const ActivityModel({
    required this.id,
    required this.title,
    this.youtubeVideoId,
    required this.questions,
    this.availableFrom,
  });

  /// Indica si l'activitat està disponible (segons availableFrom)
  bool get isAvailable {
    if (availableFrom == null) return true;
    final now = DateTime.now();
    return !availableFrom!.isAfter(now);
  }

  /// Crea una instància a partir de JSON
  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] as String,
      title: json['title'] as String,
      youtubeVideoId: json['youtubeVideoId'] as String?,
      questions: (json['questions'] as List)
          .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
          .toList(),
      availableFrom: json['availableFrom'] != null
          ? DateTime.parse(json['availableFrom'] as String)
          : null,
    );
  }

  /// Converteix la instància a JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'youtubeVideoId': youtubeVideoId,
    'questions': questions.map((q) => q.toJson()).toList(),
    'availableFrom': availableFrom?.toIso8601String(),
  };
}
