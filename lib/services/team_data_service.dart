import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:el_visionat/models/team_platform.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:el_visionat/services/isar_service.dart';

class TeamDataService {
  final IsarService _isarService;
  final FirebaseFirestore _firestore;

  TeamDataService(this._isarService, this._firestore);

  Future<List<Team>> getTeams() async {
    debugPrint('TeamDataService: getTeams called');
    // On web we skip Isar (codegen issues) and fetch directly from Firestore.
    if (kIsWeb) {
      debugPrint(
        'TeamDataService: running on web — fetching teams from Firestore directly',
      );
      final querySnapshot = await _firestore.collection('teams').get();
      debugPrint(
        'TeamDataService: Firestore returned ${querySnapshot.docs.length} docs (web)',
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

    List<Team> teams = await _isarService.getAllTeams();
    debugPrint('TeamDataService: Isar returned ${teams.length} teams');

    if (teams.isEmpty) {
      debugPrint('TeamDataService: Isar empty — fetching from Firestore');
      final querySnapshot = await _firestore.collection('teams').get();
      debugPrint(
        'TeamDataService: Firestore returned ${querySnapshot.docs.length} docs',
      );
      teams = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Team()
          ..firestoreId = doc.id
          ..name = data['name'] ?? ''
          ..acronym = data['acronym'] ?? ''
          ..gender = data['gender'] ?? ''
          ..logoUrl = data['logoUrl'];
      }).toList();

      if (teams.isNotEmpty) {
        debugPrint('TeamDataService: saving ${teams.length} teams into Isar');
        await _isarService.saveAll(teams);
        debugPrint('TeamDataService: saved teams into Isar');
      }
    }

    return teams;
  }
}
