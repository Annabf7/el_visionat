/// ProfileModel: Model de dades per a la informació de perfil d'usuari
/// Centralitza la lògica de fallback i validació per a la UI
// ignore: unnecessary_library_name
library profile_model;

import 'season_goals_model.dart';
import 'home_address_model.dart';

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

/// Configuració de visibilitat del perfil públic
class ProfileVisibility {
  final bool showYearsExperience;
  final bool showAnalyzedMatches;
  final bool showPersonalNotes;
  final bool showSeasonGoals;

  const ProfileVisibility({
    this.showYearsExperience = true,
    this.showAnalyzedMatches = true,
    this.showPersonalNotes = false,
    this.showSeasonGoals = false,
  });

  factory ProfileVisibility.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const ProfileVisibility();
    return ProfileVisibility(
      showYearsExperience: data['showYearsExperience'] as bool? ?? true,
      showAnalyzedMatches: data['showAnalyzedMatches'] as bool? ?? true,
      showPersonalNotes: data['showPersonalNotes'] as bool? ?? false,
      showSeasonGoals: data['showSeasonGoals'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'showYearsExperience': showYearsExperience,
    'showAnalyzedMatches': showAnalyzedMatches,
    'showPersonalNotes': showPersonalNotes,
    'showSeasonGoals': showSeasonGoals,
  };

  ProfileVisibility copyWith({
    bool? showYearsExperience,
    bool? showAnalyzedMatches,
    bool? showPersonalNotes,
    bool? showSeasonGoals,
  }) {
    return ProfileVisibility(
      showYearsExperience: showYearsExperience ?? this.showYearsExperience,
      showAnalyzedMatches: showAnalyzedMatches ?? this.showAnalyzedMatches,
      showPersonalNotes: showPersonalNotes ?? this.showPersonalNotes,
      showSeasonGoals: showSeasonGoals ?? this.showSeasonGoals,
    );
  }
}

class ProfileModel {
  final String? displayName;
  final String? email;
  final String? refereeCategory;
  final int? startYear; // Any d'inici com a àrbitre
  final String? portraitImageUrl;
  final String? headerImageUrl;
  final String? gender; // 'male' | 'female'
  final bool isMentor; // Indica si l'usuari és mentor

  // Llista d'IDs d'àrbitres mentoritzats.
  // Pot ser un UID d'usuari (si té compte) o un String JSON-like "license:12345:Nom Cognom"
  final List<String> mentoredReferees;

  // Estadístiques
  final int analyzedMatches;
  final int personalNotesCount;
  final int sharedClipsCount;

  // Configuració de visibilitat
  final ProfileVisibility visibility;

  // Objectius de temporada
  final SeasonGoals seasonGoals;

  // Adreça de casa de l'àrbitre (per càlcul de quilometratge)
  final HomeAddress homeAddress;

  ProfileModel({
    this.displayName,
    this.email,
    this.refereeCategory,
    this.startYear,
    this.portraitImageUrl,
    this.headerImageUrl,
    this.gender,
    this.isMentor = false,
    this.mentoredReferees = const [],
    this.analyzedMatches = 0,
    this.personalNotesCount = 0,
    this.sharedClipsCount = 0,
    this.visibility = const ProfileVisibility(),
    this.seasonGoals = const SeasonGoals(),
    HomeAddress? homeAddress,
  }) : homeAddress = homeAddress ?? HomeAddress.empty();

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

  /// Anys d'experiència calculats des de startYear
  int? get yearsExperience {
    if (startYear == null) return null;
    return DateTime.now().year - startYear!;
  }

  /// Getter segur per a l'experiència
  String get anysArbitratsSafe {
    final years = yearsExperience;
    if (years == null) return '-';
    if (years == 0) return 'Primer any';
    if (years == 1) return '1 any arbitrant';
    return '$years anys arbitrant';
  }

  /// Nivell d'accés a clips de la comunitat basat en clips compartits
  /// 0 clips = només veus els teus
  /// 1-2 clips = veus 5 clips de companys
  /// 3-5 clips = veus tots els de la teva categoria
  /// 6+ clips = veus TOTS els clips
  int get communityAccessLevel {
    if (sharedClipsCount >= 6) return 3; // Accés total
    if (sharedClipsCount >= 3) return 2; // Categoria
    if (sharedClipsCount >= 1) return 1; // Limitat
    return 0; // Només propis
  }

  String get communityAccessDescription {
    switch (communityAccessLevel) {
      case 3:
        return 'Accés total a clips de la comunitat';
      case 2:
        return 'Accés a clips de la teva categoria';
      case 1:
        return 'Accés limitat (5 clips)';
      default:
        return 'Comparteix clips per veure els dels companys';
    }
  }

  /// Getter que resol l'avatar: personalitzat o per defecte segons gènere
  String get resolvedAvatarUrl {
    if (portraitImageUrl != null && portraitImageUrl!.trim().isNotEmpty) {
      return portraitImageUrl!;
    }
    return ProfileDefaults.getDefaultAvatar(gender);
  }

  /// Getter que resol el header: personalitzat o per defecte segons gènere
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
      startYear: data['startYear'] as int?,
      portraitImageUrl: data['portraitImageUrl'] as String?,
      headerImageUrl: data['headerImageUrl'] as String?,
      gender: data['gender'] as String?,
      isMentor: data['isMentor'] as bool? ?? false,
      mentoredReferees:
          (data['mentoredReferees'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      analyzedMatches: data['analyzedMatches'] as int? ?? 0,
      personalNotesCount: data['personalNotesCount'] as int? ?? 0,
      sharedClipsCount: data['sharedClipsCount'] as int? ?? 0,
      visibility: ProfileVisibility.fromMap(
        data['profileVisibility'] as Map<String, dynamic>?,
      ),
      seasonGoals: SeasonGoals.fromMap(
        data['seasonGoals'] as Map<String, dynamic>?,
      ),
      homeAddress: data['homeAddress'] != null
          ? HomeAddress.fromFirestore(
              data['homeAddress'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
