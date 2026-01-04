import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/referee_from_registry.dart';
import 'dart:developer' as developer;

/// Service per obtenir i gestionar àrbitres del registre oficial
class RefereeRegistryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obté tots els àrbitres del registre oficial
  ///
  /// Retorna una llista de [RefereeFromRegistry] ordenada alfabèticament per cognoms
  Future<List<RefereeFromRegistry>> getAllReferees() async {
    try {
      developer.log('Fetching all referees from registry', name: 'RefereeRegistryService');

      final snapshot = await _firestore
          .collection('referees_registry')
          .orderBy('cognoms')
          .get();

      final referees = snapshot.docs
          .map((doc) => RefereeFromRegistry.fromFirestore(doc.data()))
          .toList();

      developer.log('Fetched ${referees.length} referees', name: 'RefereeRegistryService');

      return referees;
    } catch (e) {
      developer.log('Error fetching referees: $e', name: 'RefereeRegistryService', error: e);
      return [];
    }
  }

  /// Cerca àrbitres que coincideixin amb el query
  ///
  /// Filtra localment els àrbitres per nom, cognoms o número de llicència
  List<RefereeFromRegistry> searchReferees(
    List<RefereeFromRegistry> referees,
    String query,
  ) {
    if (query.isEmpty) return referees;

    final matches = referees.where((referee) => referee.matchesSearch(query)).toList();

    // Ordenar per rellevància: exactes primer
    matches.sort((a, b) {
      final queryLower = query.toLowerCase().trim();

      // Prioritzar coincidències exactes de llicència
      if (a.llissenciaId == query.trim()) return -1;
      if (b.llissenciaId == query.trim()) return 1;

      // Prioritzar coincidències que comencen amb el query
      final aStartsWith = a.fullName.toLowerCase().startsWith(queryLower);
      final bStartsWith = b.fullName.toLowerCase().startsWith(queryLower);

      if (aStartsWith && !bStartsWith) return -1;
      if (!aStartsWith && bStartsWith) return 1;

      // Ordenar alfabèticament
      return a.cognoms.compareTo(b.cognoms);
    });

    return matches;
  }
}