import 'package:cloud_firestore/cloud_firestore.dart';
import '../../designations/repositories/designations_repository.dart';
import '../../designations/models/referee_from_registry.dart';
import '../models/match_history_result.dart';

/// Service per buscar i filtrar l'historial de partits
class MatchHistoryService {
  final _repository = DesignationsRepository();
  final _firestore = FirebaseFirestore.instance;

  /// Cerca partits per nom d'àrbitre
  /// Busca a TOTS els àrbitres de referees_registry i retorna els partits amb ells
  Future<MatchHistoryResult> searchByReferee({
    required String refereeName,
  }) async {
    if (refereeName.trim().isEmpty) {
      return MatchHistoryResult.empty('');
    }

    // 1. Cercar àrbitres que coincideixin amb la query a referees_registry
    final refereesSnapshot = await _firestore
        .collection('referees_registry')
        .get();

    final matchingReferees = refereesSnapshot.docs
        .map((doc) => RefereeFromRegistry.fromFirestore(doc.data()))
        .where((referee) => referee.matchesSearch(refereeName))
        .toList();

    if (matchingReferees.isEmpty) {
      return MatchHistoryResult.empty(refereeName);
    }

    // Agafem el primer àrbitre trobat per mostrar la seva info
    final refereeInfo = matchingReferees.first;

    // 2. Obtenir totes les designacions de l'usuari
    final allDesignations = await _repository.getDesignations().first;

    // 3. Filtrar designacions que continguin qualsevol dels àrbitres trobats
    final matches = allDesignations.where((designation) {
      if (designation.refereePartner == null) {
        return false;
      }

      final partnerLower = designation.refereePartner!.toLowerCase();

      // Comprovar si algún dels àrbitres trobats apareix en el camp refereePartner
      return matchingReferees.any((referee) {
        final refereeFullName = referee.fullName.toLowerCase();
        final refereeCognoms = referee.cognoms.toLowerCase();
        final refereeNom = referee.nom.toLowerCase();

        return partnerLower.contains(refereeFullName) ||
               partnerLower.contains(refereeCognoms) ||
               partnerLower.contains(refereeNom);
      });
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
      refereeInfo: refereeInfo,
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