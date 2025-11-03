import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:el_visionat/models/team_platform.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:el_visionat/services/isar_service.dart';

class TeamDataService {
  final IsarService _isarService;
  final FirebaseFirestore _firestore;

  TeamDataService(this._isarService, this._firestore);

  Future<List<Team>> getTeams() async {
    // On web we skip Isar (codegen issues) and fetch directly from Firestore.
    if (kIsWeb) {
      final querySnapshot = await _firestore.collection('teams').get();
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

    if (teams.isEmpty) {
      final querySnapshot = await _firestore.collection('teams').get();
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
        await _isarService.saveAll(teams);
      }
    }

    return teams;
  }
}
