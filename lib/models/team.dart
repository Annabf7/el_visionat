import 'package:isar_community/isar.dart';

part 'team.g.dart';

@Collection()
class Team {
  /// Isar primary id. Use auto-increment by default. If you need a stable id
  /// derived from `firestoreId`, set it explicitly before saving.
  ///
  /// Note: Isar 3 expects the `Id` type for primary id fields (not `int`).
  Id id = Isar.autoIncrement;

  late String firestoreId;
  late String name;
  late String acronym;
  late String gender;
  String? logoUrl;

  /// Optional: a stable 64-bit FNV-1a hash implementation kept as a helper.
  /// Not used by default; prefer to set `id` explicitly if you require stable ids.
  int fastHash64(String string) {
    // 64-bit FNV-1a
    var hash =
        0xcbf29ce484222325; // FNV offset basis (different constant to avoid large hex literal issues)
    for (var i = 0; i < string.length; i++) {
      final codeUnit = string.codeUnitAt(i);
      hash ^= codeUnit;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash & 0xFFFFFFFFFFFFFFFF;
  }
}
