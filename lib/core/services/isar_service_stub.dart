// No-op IsarService for Web: keeps the same API surface but doesn't require
// Isar or generated code. This avoids compilation/codegen issues on web.
import 'package:el_visionat/features/teams/models/team_stub.dart';

class IsarService {
  // Provide a dummy future so callers can await db, but it will throw if used.
  late Future<void> db;

  IsarService() {
    db = Future.value();
  }

  static final IsarService _instance = IsarService();
  static IsarService get instance => _instance;

  Future<void> openDB() async {
    // No-op on web
    return Future.value();
  }

  Future<void> saveAll(List<Team> teams) async {
    // No-op on web
    return Future.value();
  }

  Future<List<Team>> getAllTeams() async {
    // No local cache on web; callers should fetch from Firestore instead.
    return Future.value(<Team>[]);
  }
}
