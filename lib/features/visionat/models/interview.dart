import 'package:cloud_firestore/cloud_firestore.dart';

/// Model per representar una entrevista amb l'àrbitre principal
///
/// Cada entrevista està associada a un partit setmanal i conté:
/// - Enllaç al vídeo de l'entrevista
/// - Snapshot de les jugades polèmiques analitzades
/// - Informació del partit i àrbitre
class Interview {
  final String id;
  final String matchId;
  final int jornada;
  final String competitionName;
  final String refereeName;
  final String matchTitle; // Ex: "Barça vs Madrid"
  final String videoUrl;
  final DateTime publishedAt;
  final List<ControversialHighlightSnapshot> controversialHighlights;
  final bool isPublished;

  const Interview({
    required this.id,
    required this.matchId,
    required this.jornada,
    required this.competitionName,
    required this.refereeName,
    required this.matchTitle,
    required this.videoUrl,
    required this.publishedAt,
    this.controversialHighlights = const [],
    this.isPublished = true,
  });

  /// Títol formatat per mostrar
  String get displayTitle => 'Entrevista Jornada $jornada';

  /// Subtítol amb àrbitre
  String get displaySubtitle => 'Àrbitre: $refereeName';

  /// Descripció completa
  String get fullDescription => '$matchTitle · $competitionName';

  /// Serialització a JSON per Firestore
  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'jornada': jornada,
      'competitionName': competitionName,
      'refereeName': refereeName,
      'matchTitle': matchTitle,
      'videoUrl': videoUrl,
      'publishedAt': Timestamp.fromDate(publishedAt),
      'controversialHighlights': controversialHighlights.map((h) => h.toJson()).toList(),
      'isPublished': isPublished,
    };
  }

  /// Deserialització des de JSON de Firestore
  factory Interview.fromJson(Map<String, dynamic> json, {String? id}) {
    return Interview(
      id: id ?? json['id'] as String? ?? '',
      matchId: json['matchId'] as String? ?? '',
      jornada: json['jornada'] as int? ?? 0,
      competitionName: json['competitionName'] as String? ?? '',
      refereeName: json['refereeName'] as String? ?? '',
      matchTitle: json['matchTitle'] as String? ?? '',
      videoUrl: json['videoUrl'] as String? ?? '',
      publishedAt: json['publishedAt'] != null
          ? (json['publishedAt'] as Timestamp).toDate()
          : DateTime.now(),
      controversialHighlights: (json['controversialHighlights'] as List<dynamic>?)
              ?.map((h) => ControversialHighlightSnapshot.fromJson(h as Map<String, dynamic>))
              .toList() ??
          [],
      isPublished: json['isPublished'] as bool? ?? true,
    );
  }

  /// Factory per crear des de Firestore DocumentSnapshot
  factory Interview.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('No data found in Interview document');
    }
    return Interview.fromJson(data, id: doc.id);
  }

  Interview copyWith({
    String? id,
    String? matchId,
    int? jornada,
    String? competitionName,
    String? refereeName,
    String? matchTitle,
    String? videoUrl,
    DateTime? publishedAt,
    List<ControversialHighlightSnapshot>? controversialHighlights,
    bool? isPublished,
  }) {
    return Interview(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      jornada: jornada ?? this.jornada,
      competitionName: competitionName ?? this.competitionName,
      refereeName: refereeName ?? this.refereeName,
      matchTitle: matchTitle ?? this.matchTitle,
      videoUrl: videoUrl ?? this.videoUrl,
      publishedAt: publishedAt ?? this.publishedAt,
      controversialHighlights: controversialHighlights ?? this.controversialHighlights,
      isPublished: isPublished ?? this.isPublished,
    );
  }
}

/// Snapshot d'una jugada polèmica per guardar a l'entrevista
/// Versió simplificada per no duplicar totes les dades
class ControversialHighlightSnapshot {
  final String highlightId;
  final String title;
  final String category;
  final Duration timestamp;
  final int totalReactions;

  const ControversialHighlightSnapshot({
    required this.highlightId,
    required this.title,
    required this.category,
    required this.timestamp,
    required this.totalReactions,
  });

  /// Minutatge formatat
  String get minutatgeDisplay {
    final minutes = timestamp.inMinutes;
    final seconds = timestamp.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() {
    return {
      'highlightId': highlightId,
      'title': title,
      'category': category,
      'timestampSeconds': timestamp.inSeconds,
      'totalReactions': totalReactions,
    };
  }

  factory ControversialHighlightSnapshot.fromJson(Map<String, dynamic> json) {
    return ControversialHighlightSnapshot(
      highlightId: json['highlightId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      timestamp: Duration(seconds: json['timestampSeconds'] as int? ?? 0),
      totalReactions: json['totalReactions'] as int? ?? 0,
    );
  }
}
