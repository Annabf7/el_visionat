import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:el_visionat/features/teams/models/team_platform.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Servei simplificat per obtenir equips des de Firestore
/// (Isar eliminat per simplificar i evitar problemes de compatibilitat)
class TeamDataService {
  final FirebaseFirestore _firestore;

  TeamDataService(this._firestore);

  /// Obté tots els equips des de Firestore
  Future<List<Team>> getTeams() async {
    debugPrint('TeamDataService: getTeams called');

    final querySnapshot = await _firestore.collection('teams').get();
    debugPrint(
      'TeamDataService: Firestore returned ${querySnapshot.docs.length} teams',
    );

    final teams = querySnapshot.docs.map((doc) {
      final data = doc.data();
      return Team()
        ..firestoreId = doc.id
        ..name = data['name'] ?? ''
        ..acronym = data['acronym'] ?? ''
        ..gender = data['gender'] ?? ''
        ..logoUrl = data['logoUrl'];
    }).toList();

    return teams;
  }
}