// ============================================================================
// Team Mapping Service - Mapatge d'equips FCBQ a dades locals
// ============================================================================
// Proporciona funcions per resoldre noms d'equip de la FCBQ als equips
// del diccionari local (supercopa_teams.json), incloent logos i colors.
//
// Estratègia de matching:
// 1. Match exacte per nom
// 2. Match normalitzat (lowercase, trim, sense accents)
// 3. Match per aliases
// 4. Fallback amb logoSlug generat (no bloqueja)
// ============================================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Representa un equip amb totes les seves dades
class TeamInfo {
  final String id;
  final String name;
  final String acronym;
  final String gender;
  final String colorHex;
  final String? logoAssetPath;
  final List<String> aliases;

  const TeamInfo({
    required this.id,
    required this.name,
    required this.acronym,
    required this.gender,
    required this.colorHex,
    this.logoAssetPath,
    this.aliases = const [],
  });

  factory TeamInfo.fromJson(Map<String, dynamic> json) {
    return TeamInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      acronym: json['acronym'] as String? ?? '',
      gender: json['gender'] as String? ?? 'Masculina',
      colorHex: json['colorHex'] as String? ?? '#808080',
      logoAssetPath: json['logoAssetPath'] as String?,
      aliases:
          (json['aliases'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  /// Retorna només el nom del fitxer del logo (sense el path complet)
  /// ex: "cb-artes.webp" o null si no hi ha logo
  String? get logoFilename {
    if (logoAssetPath == null) return null;
    return logoAssetPath!.split('/').last;
  }

  @override
  String toString() => 'TeamInfo($id: $name)';
}

/// Resultat del mapping d'un equip
class TeamMappingResult {
  final String originalName;
  final TeamInfo? team;
  final String? logoAssetPath;
  final String? logoFilename;
  final String? colorHex;
  final bool wasFound;
  final String matchType; // "exact", "normalized", "alias", "not-found"

  const TeamMappingResult({
    required this.originalName,
    this.team,
    this.logoAssetPath,
    this.logoFilename,
    this.colorHex,
    required this.wasFound,
    required this.matchType,
  });

  /// Resultat "safe" quan no es troba l'equip
  factory TeamMappingResult.notFound(String originalName) {
    final generatedSlug = _generateLogoSlug(originalName);
    return TeamMappingResult(
      originalName: originalName,
      team: null,
      logoAssetPath: null,
      logoFilename: generatedSlug,
      colorHex: '#808080', // Gris per defecte
      wasFound: false,
      matchType: 'not-found',
    );
  }

  /// Genera un slug de logo a partir del nom de l'equip
  /// Ex: "CB ARTÉS" -> "cb-artes.webp"
  static String _generateLogoSlug(String teamName) {
    return '${_normalizeToSlug(teamName)}.webp';
  }
}

/// Service singleton per gestionar el mapping d'equips
class TeamMappingService {
  static TeamMappingService? _instance;
  static TeamMappingService get instance =>
      _instance ??= TeamMappingService._();

  TeamMappingService._();

  List<TeamInfo>? _teams;
  Map<String, TeamInfo>? _exactNameMap;
  Map<String, TeamInfo>? _normalizedNameMap;
  Map<String, TeamInfo>? _aliasMap;

  bool _isInitialized = false;

  /// Inicialitza el servei carregant el diccionari d'equips
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final raw = await rootBundle.loadString(
        'assets/data/supercopa_teams.json',
      );
      final decoded = jsonDecode(raw) as List<dynamic>;
      _teams = decoded
          .map((e) => TeamInfo.fromJson(e as Map<String, dynamic>))
          .toList();

      _buildMaps();
      _isInitialized = true;
      debugPrint(
        '[TeamMappingService] Inicialitzat amb ${_teams!.length} equips',
      );
    } catch (e) {
      debugPrint('[TeamMappingService] Error inicialitzant: $e');
      _teams = [];
      _exactNameMap = {};
      _normalizedNameMap = {};
      _aliasMap = {};
      _isInitialized = true;
    }
  }

  /// Construeix els mapes de cerca
  void _buildMaps() {
    _exactNameMap = {};
    _normalizedNameMap = {};
    _aliasMap = {};

    for (final team in _teams!) {
      // Map exacte per nom
      _exactNameMap![team.name] = team;

      // Map normalitzat per nom
      final normalizedName = _normalizeString(team.name);
      _normalizedNameMap![normalizedName] = team;

      // Map per aliases
      for (final alias in team.aliases) {
        _aliasMap![alias] = team;
        _aliasMap![_normalizeString(alias)] = team;
      }
    }
  }

  /// Cerca un equip pel nom i retorna les seves dades
  ///
  /// Estratègia de cerca:
  /// 1. Match exacte per nom
  /// 2. Match normalitzat (lowercase, trim, sense accents, collapse spaces)
  /// 3. Match per aliases (exacte i normalitzat)
  /// 4. Si no es troba, retorna resultat "safe" amb warning
  Future<TeamMappingResult> findTeam(String teamName) async {
    await initialize();

    if (teamName.isEmpty) {
      return TeamMappingResult.notFound(teamName);
    }

    final trimmedName = teamName.trim();

    // 1. Match exacte
    if (_exactNameMap!.containsKey(trimmedName)) {
      final team = _exactNameMap![trimmedName]!;
      return _createResult(trimmedName, team, 'exact');
    }

    // 2. Match normalitzat
    final normalized = _normalizeString(trimmedName);
    if (_normalizedNameMap!.containsKey(normalized)) {
      final team = _normalizedNameMap![normalized]!;
      return _createResult(trimmedName, team, 'normalized');
    }

    // 3. Match per alias (exacte)
    if (_aliasMap!.containsKey(trimmedName)) {
      final team = _aliasMap![trimmedName]!;
      return _createResult(trimmedName, team, 'alias');
    }

    // 4. Match per alias (normalitzat)
    if (_aliasMap!.containsKey(normalized)) {
      final team = _aliasMap![normalized]!;
      return _createResult(trimmedName, team, 'alias');
    }

    // 5. No trobat - log warning però no petar
    debugPrint(
      '[TeamMappingService] ⚠️ Equip no trobat: "$trimmedName" (normalitzat: "$normalized")',
    );
    return TeamMappingResult.notFound(trimmedName);
  }

  /// Versió síncrona de findTeam (requereix que el servei ja estigui inicialitzat)
  TeamMappingResult findTeamSync(String teamName) {
    if (!_isInitialized) {
      debugPrint(
        '[TeamMappingService] ⚠️ Servei no inicialitzat, retornant not-found',
      );
      return TeamMappingResult.notFound(teamName);
    }

    if (teamName.isEmpty) {
      return TeamMappingResult.notFound(teamName);
    }

    final trimmedName = teamName.trim();

    // 1. Match exacte
    if (_exactNameMap!.containsKey(trimmedName)) {
      final team = _exactNameMap![trimmedName]!;
      return _createResult(trimmedName, team, 'exact');
    }

    // 2. Match normalitzat
    final normalized = _normalizeString(trimmedName);
    if (_normalizedNameMap!.containsKey(normalized)) {
      final team = _normalizedNameMap![normalized]!;
      return _createResult(trimmedName, team, 'normalized');
    }

    // 3. Match per alias (exacte)
    if (_aliasMap!.containsKey(trimmedName)) {
      final team = _aliasMap![trimmedName]!;
      return _createResult(trimmedName, team, 'alias');
    }

    // 4. Match per alias (normalitzat)
    if (_aliasMap!.containsKey(normalized)) {
      final team = _aliasMap![normalized]!;
      return _createResult(trimmedName, team, 'alias');
    }

    // 5. No trobat
    debugPrint(
      '[TeamMappingService] ⚠️ Equip no trobat (sync): "$trimmedName"',
    );
    return TeamMappingResult.notFound(trimmedName);
  }

  /// Crea un resultat de mapping exitós
  TeamMappingResult _createResult(
    String originalName,
    TeamInfo team,
    String matchType,
  ) {
    return TeamMappingResult(
      originalName: originalName,
      team: team,
      logoAssetPath: team.logoAssetPath,
      logoFilename: team.logoFilename,
      colorHex: team.colorHex,
      wasFound: true,
      matchType: matchType,
    );
  }

  /// Obté tots els equips carregats
  Future<List<TeamInfo>> getAllTeams() async {
    await initialize();
    return List.unmodifiable(_teams ?? []);
  }

  /// Obté equips per gènere
  Future<List<TeamInfo>> getTeamsByGender(String gender) async {
    await initialize();
    return _teams?.where((t) => t.gender == gender).toList() ?? [];
  }

  /// Neteja el cache i força reinicialització
  void reset() {
    _isInitialized = false;
    _teams = null;
    _exactNameMap = null;
    _normalizedNameMap = null;
    _aliasMap = null;
  }

  /// Retorna estadístiques del servei
  Map<String, dynamic> getStats() {
    return {
      'initialized': _isInitialized,
      'totalTeams': _teams?.length ?? 0,
      'exactNames': _exactNameMap?.length ?? 0,
      'normalizedNames': _normalizedNameMap?.length ?? 0,
      'aliases': _aliasMap?.length ?? 0,
    };
  }
}

// ============================================================================
// Funcions de normalització (a nivell de mòdul per reutilització)
// ============================================================================

/// Normalitza un string per comparació:
/// - lowercase
/// - trim
/// - elimina accents
/// - col·lapsa espais múltiples
/// - elimina puntuació bàsica
String _normalizeString(String input) {
  return input
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[áàäâã]'), 'a')
      .replaceAll(RegExp(r'[éèëê]'), 'e')
      .replaceAll(RegExp(r'[íìïî]'), 'i')
      .replaceAll(RegExp(r'[óòöôõ]'), 'o')
      .replaceAll(RegExp(r'[úùüû]'), 'u')
      .replaceAll(RegExp(r'[ç]'), 'c')
      .replaceAll(RegExp(r'[ñ]'), 'n')
      .replaceAll(RegExp(r"[''`]"), '')
      .replaceAll(RegExp(r'[.\-_,]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Genera un slug per nom de fitxer:
/// - lowercase
/// - elimina accents
/// - substitueix espais i puntuació per guions
/// - col·lapsa guions múltiples
String _normalizeToSlug(String input) {
  return input
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[áàäâã]'), 'a')
      .replaceAll(RegExp(r'[éèëê]'), 'e')
      .replaceAll(RegExp(r'[íìïî]'), 'i')
      .replaceAll(RegExp(r'[óòöôõ]'), 'o')
      .replaceAll(RegExp(r'[úùüû]'), 'u')
      .replaceAll(RegExp(r'[ç]'), 'c')
      .replaceAll(RegExp(r'[ñ]'), 'n')
      .replaceAll(RegExp(r"[''`]"), '')
      .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}
