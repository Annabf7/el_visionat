/// ProfileModel: Model de dades per a la informació de perfil d'usuari
/// Centralitza la lògica de fallback i validació per a la UI
// ignore: unnecessary_library_name
library profile_model;

class ProfileModel {
  final String? displayName;
  final String? email;
  final String? refereeCategory;
  final int? anysArbitrats;
  final String? portraitImageUrl;

  ProfileModel({
    this.displayName,
    this.email,
    this.refereeCategory,
    this.anysArbitrats,
    this.portraitImageUrl,
  });

  /// Getter segur per al nom a mostrar
  String get displayNameSafe => (displayName?.trim().isNotEmpty == true)
      ? displayName!
      : (email?.trim().isNotEmpty == true)
      ? email!
      : 'Usuari';

  /// Getter segur per a la categoria
  String get categoriaSafe => (refereeCategory?.trim().isNotEmpty == true)
      ? refereeCategory!
      : 'Defineix la teva categoria';

  /// Getter segur per a l'experiència
  String get anysArbitratsSafe =>
      (anysArbitrats != null) ? '$anysArbitrats anys arbitrats' : '-';

  /// Constructor des de Map (Firestore)
  factory ProfileModel.fromMap(Map<String, dynamic>? data) {
    if (data == null) return ProfileModel();
    // Accepta refereeCategory o categoriaRrtt (prioritza refereeCategory)
    String? category = data['refereeCategory'] as String?;
    if (category == null || category.trim().isEmpty) {
      category = data['categoriaRrtt'] as String?;
    }
    return ProfileModel(
      displayName: data['displayName'] as String?,
      email: data['email'] as String?,
      refereeCategory: category,
      anysArbitrats: data['anysArbitrats'] as int?,
      portraitImageUrl: data['portraitImageUrl'] as String?,
    );
  }
}
