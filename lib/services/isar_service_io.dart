import 'package:el_visionat/models/team_platform.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
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
    try {
      debugPrint('IsarService: saving ${teams.length} teams to Isar');
      await isar.writeTxn(() async {
        await isar.teams.putAll(teams);
      });
      debugPrint('IsarService: saved ${teams.length} teams to Isar');
    } catch (e, st) {
      debugPrint('IsarService: error saving teams to Isar: $e\n$st');
      rethrow;
    }
  }

  Future<List<Team>> getAllTeams() async {
    final isar = await db;
    final list = await isar.teams.where().findAll();
    debugPrint('IsarService: getAllTeams returned ${list.length} records');
    return list;
  }
}
