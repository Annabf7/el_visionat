import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipus de tags/etiquetes per a highlights del minutatge
enum HighlightTagType {
  faltaTecnica,
  decisioClau,
  posicio,
  comunicacio,
  gestio,
}

extension HighlightTagTypeExtension on HighlightTagType {
  String get displayName {
    switch (this) {
      case HighlightTagType.faltaTecnica:
        return 'Falta Tècnica';
      case HighlightTagType.decisioClau:
        return 'Decisió Clau';
      case HighlightTagType.posicio:
        return 'Posició';
      case HighlightTagType.comunicacio:
        return 'Comunicació';
      case HighlightTagType.gestio:
        return 'Gestió';
    }
  }

  String get iconName {
    switch (this) {
      case HighlightTagType.faltaTecnica:
        return 'card';
      case HighlightTagType.decisioClau:
        return 'warning';
      case HighlightTagType.posicio:
        return 'location';
      case HighlightTagType.comunicacio:
        return 'chat';
      case HighlightTagType.gestio:
        return 'settings';
    }
  }

  // Conversió a String per serialització
  String get value {
    switch (this) {
      case HighlightTagType.faltaTecnica:
        return 'falta_tecnica';
      case HighlightTagType.decisioClau:
        return 'decisio_clau';
      case HighlightTagType.posicio:
        return 'posicio';
      case HighlightTagType.comunicacio:
        return 'comunicacio';
      case HighlightTagType.gestio:
        return 'gestio';
    }
  }

  // Conversió des de String per deserialització
  static HighlightTagType fromValue(String value) {
    switch (value) {
      case 'falta_tecnica':
        return HighlightTagType.faltaTecnica;
      case 'decisio_clau':
        return HighlightTagType.decisioClau;
      case 'posicio':
        return HighlightTagType.posicio;
      case 'comunicacio':
        return HighlightTagType.comunicacio;
      case 'gestio':
        return HighlightTagType.gestio;
      default:
        return HighlightTagType.decisioClau; // default fallback
    }
  }
}

/// Entrada/highlight del minutatge d'un partit
/// Compatible amb Firestore i amb el codi UI existent
class HighlightEntry {
  final String id;
  final String matchId;
  final Duration timestamp; // Mantenim Duration per compatibilitat UI
  final String title; // title = description per compatibilitat
  final HighlightTagType tag;
  final String category; // Categoria FIBA (mantenim per compatibilitat)
  final String tagId; // ID del tag per Firestore
  final String tagLabel; // Label del tag per Firestore
  final String description; // Descripció completa
  final String createdBy; // UID de l'usuari creador
  final DateTime createdAt; // Timestamp de creació

  const HighlightEntry({
    required this.id,
    required this.matchId,
    required this.timestamp,
    required this.title,
    required this.tag,
    required this.category,
    required this.tagId,
    required this.tagLabel,
    required this.description,
    required this.createdBy,
    required this.createdAt,
  });

  // Constructor de compatibilitat amb UI existent (sense camps Firestore)
  HighlightEntry.legacy({
    required this.id,
    required this.timestamp,
    required this.title,
    required this.tag,
    required this.category,
  }) : matchId = '',
       tagId = tag.value,
       tagLabel = tag.displayName,
       description = title,
       createdBy = '',
       createdAt = DateTime.now();

  // Mètode per crear una còpia amb canvis
  HighlightEntry copyWith({
    String? id,
    String? matchId,
    Duration? timestamp,
    String? title,
    HighlightTagType? tag,
    String? category,
    String? tagId,
    String? tagLabel,
    String? description,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return HighlightEntry(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      timestamp: timestamp ?? this.timestamp,
      title: title ?? this.title,
      tag: tag ?? this.tag,
      category: category ?? this.category,
      tagId: tagId ?? this.tagId,
      tagLabel: tagLabel ?? this.tagLabel,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Serialització a JSON per Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matchId': matchId,
      'timestamp': timestamp.inSeconds, // Guardem com segons
      'title': title,
      'tag': tag.value, // Guardem com string
      'category': category,
      'tagId': tagId,
      'tagLabel': tagLabel,
      'description': description,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Deserialització des de JSON de Firestore
  static HighlightEntry fromJson(Map<String, dynamic> json) {
    return HighlightEntry(
      id: json['id'] as String,
      matchId: json['matchId'] as String,
      timestamp: Duration(seconds: (json['timestamp'] as num).toInt()),
      title: json['title'] as String,
      tag: HighlightTagTypeExtension.fromValue(json['tag'] as String),
      category: json['category'] as String,
      tagId: json['tagId'] as String,
      tagLabel: json['tagLabel'] as String,
      description: json['description'] as String,
      createdBy: json['createdBy'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  // Mètode helper per usar amb withConverter() de Firestore
  static Map<String, dynamic> Function(HighlightEntry, SetOptions?)
  get toFirestore =>
      (highlight, _) => highlight.toJson();

  static HighlightEntry Function(
    DocumentSnapshot<Map<String, dynamic>>,
    SnapshotOptions?,
  )
  get fromFirestore => (snapshot, _) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception('No data found in Firestore document');
    }
    return HighlightEntry.fromJson(data);
  };
}
