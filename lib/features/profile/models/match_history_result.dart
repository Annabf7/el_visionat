import '../../designations/models/designation_model.dart';
import '../../designations/models/referee_from_registry.dart';

/// Model per representar el resultat d'una cerca d'historial
class MatchHistoryResult {
  final String searchTerm;
  final int totalMatches;
  final DateTime? lastMatchDate;
  final List<DesignationModel> matches;
  final RefereeFromRegistry? refereeInfo; // Info de l'àrbitre si es cerca per àrbitre

  MatchHistoryResult({
    required this.searchTerm,
    required this.totalMatches,
    this.lastMatchDate,
    required this.matches,
    this.refereeInfo,
  });

  /// Crea un resultat buit
  factory MatchHistoryResult.empty(String searchTerm, {RefereeFromRegistry? refereeInfo}) {
    return MatchHistoryResult(
      searchTerm: searchTerm,
      totalMatches: 0,
      lastMatchDate: null,
      matches: [],
      refereeInfo: refereeInfo,
    );
  }

  bool get isEmpty => matches.isEmpty;
  bool get isNotEmpty => matches.isNotEmpty;
}