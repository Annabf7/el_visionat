/// Detalls d'un partit per al panell lateral
class MatchDetails {
  final String refereeName;
  final String league;
  final int matchday;

  const MatchDetails({
    required this.refereeName,
    required this.league,
    required this.matchday,
  });
}

/// Valoració general d'un partit
enum OverallMatchRating {
  excellent,
  veryGood,
  acceptable,
  improvable,
  insufficient,
}

extension OverallMatchRatingExtension on OverallMatchRating {
  String get displayName {
    switch (this) {
      case OverallMatchRating.excellent:
        return 'Excel·lent';
      case OverallMatchRating.veryGood:
        return 'Molt bona';
      case OverallMatchRating.acceptable:
        return 'Correcta';
      case OverallMatchRating.improvable:
        return 'Millorable';
      case OverallMatchRating.insufficient:
        return 'Insuficient';
    }
  }
}

/// Àrea de millora per a l'avaluació final
class ImprovementArea {
  final String id;
  final String label;

  const ImprovementArea({required this.id, required this.label});
}

/// Dades mock per a àrees de millora
const List<ImprovementArea> improvementAreas = [
  ImprovementArea(id: 'positioning', label: 'Posicionament'),
  ImprovementArea(id: 'communication', label: 'Comunicació'),
  ImprovementArea(id: 'conflict_management', label: 'Gestió de conflictes'),
  ImprovementArea(
    id: 'disciplinary_sanctions',
    label: 'Sancions disciplinàries',
  ),
  ImprovementArea(id: 'consistency', label: 'Cohèrencia / consistència'),
  ImprovementArea(id: 'unsportsmanlike', label: 'Antiesportives'),
];
