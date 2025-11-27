class QuestionModel {
  /// Enunciat de la pregunta
  final String enunciat;

  /// Opcions de resposta
  final List<String> opcions;

  /// Índex de la resposta correcta dins d'opcions
  final int respostaCorrectaIndex;

  /// (Opcional) ID de vídeo de YouTube per a la jugada específica
  final String? youtubeVideoId;

  /// (Opcional) Comentari tècnic per explicar la resposta
  final String? comment;

  /// Constructor immutable
  const QuestionModel({
    required this.enunciat,
    required this.opcions,
    required this.respostaCorrectaIndex,
    this.youtubeVideoId,
    this.comment,
  });

  /// Crea una instància a partir de JSON
  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      enunciat: json['enunciat'] as String,
      opcions: List<String>.from(json['opcions'] as List),
      respostaCorrectaIndex: json['respostaCorrectaIndex'] as int,
      youtubeVideoId: json['youtubeVideoId'] as String?,
      comment: json['comment'] as String?,
    );
  }

  /// Converteix la instància a JSON
  Map<String, dynamic> toJson() => {
    'enunciat': enunciat,
    'opcions': opcions,
    'respostaCorrectaIndex': respostaCorrectaIndex,
    if (youtubeVideoId != null) 'youtubeVideoId': youtubeVideoId,
    if (comment != null) 'comment': comment,
  };
}
