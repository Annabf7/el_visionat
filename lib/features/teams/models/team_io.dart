// Simple Team model (Isar eliminat per simplicitat)
class Team {
  String firestoreId = '';
  String name = '';
  String acronym = '';
  String gender = '';
  String? logoUrl;

  int get id => firestoreId.hashCode;
}