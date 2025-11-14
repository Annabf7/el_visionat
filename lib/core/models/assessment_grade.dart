/// Nivells de valoració utilitzats en diferents blocs d'avaluació arbitral.
/// (En una fase futura, es faran servir per GeneralAspects, TechniqueAspects, etc.)
enum AssessmentGrade {
  optima,
  optim,
  acceptable,
  millorables,
  satisfactori,
  adequada,
  normal,
  noValorable,
  insuficient,
  inadecuada,
  si,
  no,
}

/// Classe base per a futurs desenvolupaments d'avaluació arbitral
class RefereeAssessmentDraft {
  final String matchId;
  final AssessmentGrade? overallGrade;
  final String? notes;

  const RefereeAssessmentDraft({
    required this.matchId,
    this.overallGrade,
    this.notes,
  });
}
