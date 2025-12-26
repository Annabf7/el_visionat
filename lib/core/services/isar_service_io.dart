import 'package:el_visionat/models/team.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

class IsarService {
  late Future<Isar> db;

  IsarService() {
    db = openDB();
  }

  static final IsarService _instance = IsarService();
  static IsarService get instance => _instance;

  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      if (kIsWeb) {
        return await Isar.open([TeamSchema], directory: '', inspector: true);
      } else {
        final dir = await getApplicationDocumentsDirectory();
        return await Isar.open(
          [TeamSchema],
          directory: dir.path,
          inspector: true,
        );
      }
    }
    return Future.value(Isar.getInstance());
  }

  Future<void> saveAll(List<Team> teams) async {
    final isar = await db;
    await isar.writeTxn(() async {
      for (final team in teams) {
        await isar.teams.put(team);
      }
    });
  }

  Future<List<Team>> getAllTeams() async {
    final isar = await db;
    return await isar.teams.where().findAll();
  }

  Future<void> clearAllTeams() async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.teams.clear();
    });
  }

  Future<void> deleteTeam(Team team) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.teams.delete(team.id);
    });
  }
}
