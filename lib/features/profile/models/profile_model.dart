/// ProfileModel: Model de dades per a la informació de perfil d'usuari
/// Centralitza la lògica de fallback i validació per a la UI
// ignore: unnecessary_library_name
library profile_model;

/// URLs per defecte segons el gènere (Firebase Storage)
class ProfileDefaults {
  // Avatar per defecte - Dona
  static const String avatarFemale =
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/pefil%2Favatar_profileWomen.webp?alt=media&token=1176dbdd-3047-4add-b042-2a251b5b57c5';

  // Avatar per defecte - Home
  static const String avatarMale =
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/pefil%2Favatar_profileMan.webp?alt=media&token=5b682ac7-5e7d-4342-b0f3-a5d4bed785ce';

  // Header per defecte - Dona
  static const String headerFemale =
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/pefil%2Fwomen_profile.webp?alt=media&token=acb07d68-11c5-4d85-90dd-e14134bb31bc';

  // Header per defecte - Home
  static const String headerMale =
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/pefil%2Fmen_profile.webp?alt=media&token=697dc317-bd89-46d3-9e90-9e4f79bc91e7';

  /// Retorna l'avatar per defecte segons el gènere
  static String getDefaultAvatar(String? gender) {
    return gender == 'female' ? avatarFemale : avatarMale;
  }

  /// Retorna el header per defecte segons el gènere
  static String getDefaultHeader(String? gender) {
    return gender == 'female' ? headerFemale : headerMale;
  }
}

class ProfileModel {
  final String? displayName;
  final String? email;
  final String? refereeCategory;
  final int? anysArbitrats;
  final String? portraitImageUrl;
  final String? headerImageUrl;
  final String? gender; // 'male' | 'female'

  ProfileModel({
    this.displayName,
    this.email,
    this.refereeCategory,
    this.anysArbitrats,
    this.portraitImageUrl,
    this.headerImageUrl,
    this.gender,
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

  /// Getter que resol l'avatar: personalitzat o per defecte segons gènere
  /// Si l'usuari té avatarUrl personalitzat, l'usa. Sinó, retorna el default segons gender.
  String get resolvedAvatarUrl {
    if (portraitImageUrl != null && portraitImageUrl!.trim().isNotEmpty) {
      return portraitImageUrl!;
    }
    return ProfileDefaults.getDefaultAvatar(gender);
  }

  /// Getter que resol el header: personalitzat o per defecte segons gènere
  /// Si l'usuari té headerImageUrl personalitzat, l'usa. Sinó, retorna el default segons gender.
  String get resolvedHeaderUrl {
    if (headerImageUrl != null && headerImageUrl!.trim().isNotEmpty) {
      return headerImageUrl!;
    }
    return ProfileDefaults.getDefaultHeader(gender);
  }

  /// Indica si l'usuari té un avatar personalitzat (no el default)
  bool get hasCustomAvatar =>
      portraitImageUrl != null && portraitImageUrl!.trim().isNotEmpty;

  /// Indica si l'usuari té un header personalitzat (no el default)
  bool get hasCustomHeader =>
      headerImageUrl != null && headerImageUrl!.trim().isNotEmpty;

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
      headerImageUrl: data['headerImageUrl'] as String?,
      gender: data['gender'] as String?, // Fallback a 'male' es fa als getters
    );
  }
}
