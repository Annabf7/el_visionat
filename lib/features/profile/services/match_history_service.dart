import '../../designations/repositories/designations_repository.dart';
import '../models/match_history_result.dart';

/// Service per buscar i filtrar l'historial de partits
class MatchHistoryService {
  final _repository = DesignationsRepository();

  /// Cerca partits per nom d'àrbitre
  Future<MatchHistoryResult> searchByReferee({
    required String refereeName,
  }) async {
    if (refereeName.trim().isEmpty) {
      return MatchHistoryResult.empty('');
    }

    // Obtenir totes les designacions de l'usuari (agafem la primera emissió del stream)
    final allDesignations = await _repository.getDesignations().first;

    // Filtrar per àrbitre
    final queryLower = refereeName.toLowerCase().trim();
    final matches = allDesignations.where((designation) {
      if (designation.refereePartner == null) return false;

      // Buscar al camp refereePartner
      // Format: "Nom Cognoms (Rol)" o "Nom1 (Rol1), Nom2 (Rol2)"
      final partnerLower = designation.refereePartner!.toLowerCase();
      return partnerLower.contains(queryLower);
    }).toList();

    // Ordenar per data (més recent primer)
    matches.sort((a, b) => b.date.compareTo(a.date));

    // Trobar data de l'últim partit
    final lastMatchDate = matches.isNotEmpty ? matches.first.date : null;

    return MatchHistoryResult(
      searchTerm: refereeName,
      totalMatches: matches.length,
      lastMatchDate: lastMatchDate,
      matches: matches,
    );
  }

  /// Cerca partits per nom d'equip
  Future<MatchHistoryResult> searchByTeam({
    required String teamName,
  }) async {
    if (teamName.trim().isEmpty) {
      return MatchHistoryResult.empty('');
    }

    // Obtenir totes les designacions de l'usuari (agafem la primera emissió del stream)
    final allDesignations = await _repository.getDesignations().first;

    // Filtrar per equip (local o visitant)
    final queryLower = teamName.toLowerCase().trim();
    final matches = allDesignations.where((designation) {
      final localLower = designation.localTeam.toLowerCase();
      final visitantLower = designation.visitantTeam.toLowerCase();

      return localLower.contains(queryLower) ||
          visitantLower.contains(queryLower);
    }).toList();

    // Ordenar per data (més recent primer)
    matches.sort((a, b) => b.date.compareTo(a.date));

    // Trobar data de l'últim partit
    final lastMatchDate = matches.isNotEmpty ? matches.first.date : null;

    return MatchHistoryResult(
      searchTerm: teamName,
      totalMatches: matches.length,
      lastMatchDate: lastMatchDate,
      matches: matches,
    );
  }
}