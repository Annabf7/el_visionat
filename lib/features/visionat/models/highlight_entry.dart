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
}

/// Entrada/highlight del minutatge d'un partit
class HighlightEntry {
  final String id;
  final Duration timestamp;
  final String title;
  final HighlightTagType tag;
  final String category; // Nova categoria basada en text FIBA

  const HighlightEntry({
    required this.id,
    required this.timestamp,
    required this.title,
    required this.tag,
    required this.category,
  });

  // Mètode per crear una còpia amb canvis
  HighlightEntry copyWith({
    String? id,
    Duration? timestamp,
    String? title,
    HighlightTagType? tag,
    String? category,
  }) {
    return HighlightEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      title: title ?? this.title,
      tag: tag ?? this.tag,
      category: category ?? this.category,
    );
  }
}
