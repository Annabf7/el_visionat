// Lightweight Team model used on Web (no Isar annotations or codegen required)
class Team {
  String firestoreId = '';
  String name = '';
  String acronym = '';
  String gender = '';
  String? logoUrl;

  // Provide a simple id for compatibility; actual Isar id is not used on web
  int get id => firestoreId.hashCode;
}
