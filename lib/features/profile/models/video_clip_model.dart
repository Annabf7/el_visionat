/// Model de VideoClip per a clips de videoinformes arbitrals
/// Col·lecció Firestore: /video_clips/{clipId}
///
/// NOTA: Reutilitzem AnalysisCategory i AnalysisTag de personal_analysis.dart
/// per evitar duplicació de dades i mantenir consistència.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:el_visionat/features/visionat/models/personal_analysis.dart';

/// Resultat de la decisió arbitral
enum ClipOutcome {
  encert('encert', 'Encert ✅'),
  errada('errada', 'Errada ❌'),
  dubte('dubte', 'Dubte 🤔');

  const ClipOutcome(this.value, this.label);
  final String value;
  final String label;

  static ClipOutcome fromValue(String value) {
    return ClipOutcome.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ClipOutcome.dubte,
    );
  }
}

/// Model de dades per als clips de videoinformes
class VideoClip {
  /// ID del document
  final String id;

  /// UID de l'usuari propietari del clip
  final String userId;

  /// Informació del partit (text lliure)
  final String matchInfo;

  /// Data del partit (opcional)
  final DateTime? matchDate;

  /// Categoria del partit (ex: "Primera Catalana", "Lliga EBA")
  final String? matchCategory;

  /// URL del vídeo a Firebase Storage
  final String videoUrl;

  /// URL del thumbnail
  final String? thumbnailUrl;

  /// Durada del vídeo en segons
  final int durationSeconds;

  /// Mida del fitxer en bytes
  final int fileSizeBytes;

  /// Tipus d'acció arbitral (reutilitzem AnalysisTag)
  final AnalysisTag actionType;

  /// Resultat de la decisió
  final ClipOutcome outcome;

  /// Descripció personal
  final String personalDescription;

  /// Feedback del tècnic
  final String? technicalFeedback;

  /// Reflexió/Aprenentatge
  final String? learningNotes;

  /// Si el clip és públic
  final bool isPublic;

  /// Comptador de visualitzacions
  final int viewCount;

  /// Comptador de "útil"
  final int helpfulCount;

  /// Data de creació
  final DateTime createdAt;

  /// Data d'última actualització
  final DateTime? updatedAt;

  VideoClip({
    required this.id,
    required this.userId,
    required this.matchInfo,
    this.matchDate,
    this.matchCategory,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.durationSeconds,
    required this.fileSizeBytes,
    required this.actionType,
    required this.outcome,
    required this.personalDescription,
    this.technicalFeedback,
    this.learningNotes,
    required this.isPublic,
    this.viewCount = 0,
    this.helpfulCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  /// Constructor des de Firestore
  factory VideoClip.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VideoClip(
      id: doc.id,
      userId: data['userId'] as String,
      matchInfo: data['matchInfo'] as String,
      matchDate: (data['matchDate'] as Timestamp?)?.toDate(),
      matchCategory: data['matchCategory'] as String?,
      videoUrl: data['videoUrl'] as String,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      durationSeconds: data['durationSeconds'] as int,
      fileSizeBytes: data['fileSizeBytes'] as int,
      actionType: AnalysisTag.fromValue(data['actionType'] as String),
      outcome: ClipOutcome.fromValue(data['outcome'] as String),
      personalDescription: data['personalDescription'] as String,
      technicalFeedback: data['technicalFeedback'] as String?,
      learningNotes: data['learningNotes'] as String?,
      isPublic: data['isPublic'] as bool? ?? false,
      viewCount: data['viewCount'] as int? ?? 0,
      helpfulCount: data['helpfulCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convertir a Map per guardar a Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'matchInfo': matchInfo,
      if (matchDate != null) 'matchDate': Timestamp.fromDate(matchDate!),
      if (matchCategory != null) 'matchCategory': matchCategory,
      'videoUrl': videoUrl,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      'durationSeconds': durationSeconds,
      'fileSizeBytes': fileSizeBytes,
      'actionType': actionType.value,
      'outcome': outcome.value,
      'personalDescription': personalDescription,
      if (technicalFeedback != null) 'technicalFeedback': technicalFeedback,
      if (learningNotes != null) 'learningNotes': learningNotes,
      'isPublic': isPublic,
      'viewCount': viewCount,
      'helpfulCount': helpfulCount,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  /// Durada formatada (ex: "0:45", "1:23")
  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Mida formatada (ex: "12.5 MB")
  String get formattedSize {
    final mb = fileSizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Còpia amb modificacions
  VideoClip copyWith({
    String? id,
    String? userId,
    String? matchInfo,
    DateTime? matchDate,
    String? matchCategory,
    String? videoUrl,
    String? thumbnailUrl,
    int? durationSeconds,
    int? fileSizeBytes,
    AnalysisTag? actionType,
    ClipOutcome? outcome,
    String? personalDescription,
    String? technicalFeedback,
    String? learningNotes,
    bool? isPublic,
    int? viewCount,
    int? helpfulCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VideoClip(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      matchInfo: matchInfo ?? this.matchInfo,
      matchDate: matchDate ?? this.matchDate,
      matchCategory: matchCategory ?? this.matchCategory,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      actionType: actionType ?? this.actionType,
      outcome: outcome ?? this.outcome,
      personalDescription: personalDescription ?? this.personalDescription,
      technicalFeedback: technicalFeedback ?? this.technicalFeedback,
      learningNotes: learningNotes ?? this.learningNotes,
      isPublic: isPublic ?? this.isPublic,
      viewCount: viewCount ?? this.viewCount,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Constants per validació
class VideoClipLimits {
  /// Durada màxima en segons (60s)
  static const int maxDurationSeconds = 60;

  /// Mida màxima en bytes (25MB)
  static const int maxFileSizeBytes = 25 * 1024 * 1024;

  /// Longitud màxima de la descripció personal
  static const int maxDescriptionLength = 500;

  /// Longitud màxima del feedback tècnic
  static const int maxFeedbackLength = 500;

  /// Longitud màxima de les notes d'aprenentatge
  static const int maxLearningNotesLength = 300;
}
