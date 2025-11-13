/// Model per a comentaris de l'anàlisi col·lectiva
class CollectiveComment {
  final String id;
  final String username;
  final String text;
  final bool anonymous;
  final DateTime createdAt;

  const CollectiveComment({
    required this.id,
    required this.username,
    required this.text,
    required this.anonymous,
    required this.createdAt,
  });

  /// Nom a mostrar (anònim o real)
  String get displayName => anonymous ? 'Anònim' : username;

  /// Data formatada de forma curta
  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) {
      return 'Ara mateix';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}min';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d';
    } else {
      return '${createdAt.day}/${createdAt.month}';
    }
  }
}
