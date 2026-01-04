import '../../designations/models/designation_model.dart';

/// Model per representar el resultat d'una cerca d'historial
class MatchHistoryResult {
  final String searchTerm;
  final int totalMatches;
  final DateTime? lastMatchDate;
  final List<DesignationModel> matches;

  MatchHistoryResult({
    required this.searchTerm,
    required this.totalMatches,
    this.lastMatchDate,
    required this.matches,
  });

  /// Crea un resultat buit
  factory MatchHistoryResult.empty(String searchTerm) {
    return MatchHistoryResult(
      searchTerm: searchTerm,
      totalMatches: 0,
      lastMatchDate: null,
      matches: [],
    );
  }

  bool get isEmpty => matches.isEmpty;
  bool get isNotEmpty => matches.isNotEmpty;
}