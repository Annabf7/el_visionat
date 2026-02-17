// ============================================================================
// Jornada Service - Obtenció de dades de jornades des de Firestore
// ============================================================================
// Aquest service proporciona accés a les dades de jornades de votació
// llegint directament de Firestore (col·leccions voting_meta i voting_jornades).
//
// Arquitectura:
// - Backend (Cloud Functions): syncWeeklyVoting pobla Firestore cada dilluns
// - Frontend (aquest service): només llegeix de Firestore, sense scraping
//
// Col·leccions Firestore:
// - /voting_meta/current -> { activeJornada, weekendStart, weekendEnd, ... }
// - /voting_jornades/{jornada} -> { matches[], classification[], ... }
// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../widgets/voting_section.dart' show MatchSeed;
import 'package:el_visionat/core/services/team_mapping_service.dart';

// ============================================================================
// Excepcions personalitzades
// ============================================================================

/// Excepció quan no hi ha jornada activa configurada
class NoActiveJornadaException implements Exception {
  final String message;
  NoActiveJornadaException([this.message = 'No hi ha jornada activa configurada']);

  @override
  String toString() => 'NoActiveJornadaException: $message';
}

/// Excepció quan el document de jornada no existeix
class JornadaNotFoundException implements Exception {
  final int jornada;
  final String message;
  JornadaNotFoundException(this.jornada, [String? customMessage])
      : message = customMessage ?? 'Jornada $jornada no trobada a Firestore';

  @override
  String toString() => 'JornadaNotFoundException: $message';
}

/// Excepció per errors de xarxa
class JornadaNetworkException implements Exception {
  final String message;
  final Object? originalError;
  JornadaNetworkException(this.message, [this.originalError]);

  @override
  String toString() => 'JornadaNetworkException: $message';
}

// ============================================================================
// Models
// ============================================================================

/// Representa la classificació d'un equip
class StandingEntry {
  final int position;
  final String teamName;
  final String? teamId;
  final int played;
  final int won;
  final int lost;
  final int notPlayed;
  final int pointsFor;
  final int pointsAgainst;
  final int points;
  final String? streak;

  StandingEntry({
    required this.position,
    required this.teamName,
    this.teamId,
    required this.played,
    required this.won,
    required this.lost,
    required this.notPlayed,
    required this.pointsFor,
    required this.pointsAgainst,
    required this.points,
    this.streak,
  });

  factory StandingEntry.fromJson(Map<String, dynamic> json) {
    return StandingEntry(
      position: json['position'] as int? ?? 0,
      teamName: json['teamName'] as String? ?? '',
      teamId: json['teamId'] as String?,
      played: json['played'] as int? ?? 0,
      won: json['won'] as int? ?? 0,
      lost: json['lost'] as int? ?? 0,
      notPlayed: json['notPlayed'] as int? ?? 0,
      pointsFor: json['pointsFor'] as int? ?? 0,
      pointsAgainst: json['pointsAgainst'] as int? ?? 0,
      points: json['points'] as int? ?? 0,
      streak: json['streak'] as String?,
    );
  }
}

/// Metadades de votació activa
class VotingMetadata {
  final int activeJornada;
  final DateTime weekendStart;
  final DateTime weekendEnd;
  final DateTime publishedAt;
  final int matchCount;
  final bool restWeek;
  final String? restWeekMessage;
  final DateTime? nextVotingDate;

  VotingMetadata({
    required this.activeJornada,
    required this.weekendStart,
    required this.weekendEnd,
    required this.publishedAt,
    required this.matchCount,
    this.restWeek = false,
    this.restWeekMessage,
    this.nextVotingDate,
  });

  factory VotingMetadata.fromFirestore(Map<String, dynamic> data) {
    return VotingMetadata(
      activeJornada: data['activeJornada'] as int? ?? 0,
      weekendStart: _parseDateTime(data['weekendStart']),
      weekendEnd: _parseDateTime(data['weekendEnd']),
      publishedAt: _parseDateTime(data['publishedAt']),
      matchCount: data['matchCount'] as int? ?? 0,
      restWeek: data['restWeek'] as bool? ?? false,
      restWeekMessage: data['restWeekMessage'] as String?,
      nextVotingDate: data['nextVotingDate'] != null
          ? _parseDateTime(data['nextVotingDate'])
          : null,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}

/// Resposta completa d'una jornada
class JornadaData {
  final int jornada;
  final String competitionId;
  final String competitionName;
  final List<MatchSeed> partits;
  final List<StandingEntry> classificacio;
  final DateTime fetchedAt;
  final String source;
  final DateTime? weekendStart;
  final DateTime? weekendEnd;
  final bool restWeek;
  final String? restWeekMessage;
  final DateTime? nextVotingDate;

  JornadaData({
    required this.jornada,
    required this.competitionId,
    required this.competitionName,
    required this.partits,
    required this.classificacio,
    required this.fetchedAt,
    required this.source,
    this.weekendStart,
    this.weekendEnd,
    this.restWeek = false,
    this.restWeekMessage,
    this.nextVotingDate,
  });

  /// Crea un JornadaData buit (per a estats d'error o sense dades)
  factory JornadaData.empty({int jornada = 0, String reason = 'empty'}) {
    return JornadaData(
      jornada: jornada,
      competitionId: '19795',
      competitionName: 'Super Copa Masculina',
      partits: [],
      classificacio: [],
      fetchedAt: DateTime.now(),
      source: reason,
    );
  }

  factory JornadaData.fromFirestore(Map<String, dynamic> data) {
    // Parsejar partits des del format Firestore
    final matchesRaw = data['matches'] as List<dynamic>? ?? [];
    final partits = matchesRaw.map((m) {
      final match = m as Map<String, dynamic>;
      return _convertFirestoreMatchToMatchSeed(match);
    }).toList();

    // Parsejar classificació
    final classificationRaw = data['classification'] as List<dynamic>? ?? [];
    final classificacio = classificationRaw
        .map((c) => StandingEntry.fromJson(c as Map<String, dynamic>))
        .toList();

    return JornadaData(
      jornada: data['jornada'] as int? ?? 0,
      competitionId: data['competitionId'] as String? ?? '19795',
      competitionName: data['competitionName'] as String? ?? 'Super Copa Masculina',
      partits: partits,
      classificacio: classificacio,
      fetchedAt: _parseDateTime(data['updatedAt'] ?? data['publishedAt']),
      source: data['source'] as String? ?? 'firestore',
      weekendStart: _parseDateTime(data['weekendStart']),
      weekendEnd: _parseDateTime(data['weekendEnd']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  /// Converteix el format de Firestore (VotingMatch) al format MatchSeed
  static MatchSeed _convertFirestoreMatchToMatchSeed(Map<String, dynamic> match) {
    final home = match['home'] as Map<String, dynamic>? ?? {};
    final away = match['away'] as Map<String, dynamic>? ?? {};

    // Obtenim noms
    final homeName = home['teamNameDisplay'] as String? ??
        home['teamNameRaw'] as String? ??
        '';
    final awayName = away['teamNameDisplay'] as String? ??
        away['teamNameRaw'] as String? ??
        '';

    // Obtenim logos del backend o resolem localment
    String homeLogo = home['logoSlug'] as String? ?? '';
    String awayLogo = away['logoSlug'] as String? ?? '';

    // Si el logo és buit, intentem resolució local
    if (homeLogo.isEmpty) {
      final result = TeamMappingService.instance.findTeamSync(homeName);
      homeLogo = result.logoFilename ?? homeLogo;
    }
    if (awayLogo.isEmpty) {
      final result = TeamMappingService.instance.findTeamSync(awayName);
      awayLogo = result.logoFilename ?? awayLogo;
    }

    return MatchSeed(
      jornada: match['jornada'] as int? ?? 0,
      homeName: homeName,
      homeLogo: homeLogo,
      awayName: awayName,
      awayLogo: awayLogo,
      dateTime: match['dateTime'] as String? ?? DateTime.now().toIso8601String(),
      timezone: 'Europe/Madrid',
      gender: 'male',
      source: 'firestore',
    );
  }

  /// Comprova si les dades estan buides
  bool get isEmpty => partits.isEmpty;

  /// Comprova si les dades són vàlides (tenen partits)
  bool get isValid => partits.isNotEmpty;
}

// ============================================================================
// Service
// ============================================================================

/// Service per obtenir dades de jornades de votació des de Firestore
///
/// Estratègia:
/// 1. Llegeix /voting_meta/current per obtenir activeJornada
/// 2. Llegeix /voting_jornades/{activeJornada} per obtenir partits i classificació
/// 3. Gestiona errors: sense jornada activa, document inexistent, errors de xarxa
class JornadaService {
  final FirebaseFirestore _firestore;

  /// Cache local per evitar lectures repetides
  JornadaData? _cachedJornada;
  VotingMetadata? _cachedMetadata;
  DateTime? _cacheTimestamp;

  /// Durada del cache local (5 minuts)
  static const Duration _cacheDuration = Duration(minutes: 5);

  JornadaService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Comprova si el cache és vàlid
  bool get _isCacheValid {
    if (_cacheTimestamp == null || _cachedJornada == null) return false;
    return DateTime.now().difference(_cacheTimestamp!) < _cacheDuration;
  }

  /// Invalida el cache (útil per forçar recàrrega)
  void invalidateCache() {
    _cachedJornada = null;
    _cachedMetadata = null;
    _cacheTimestamp = null;
    debugPrint('[JornadaService] Cache invalidat');
  }

  /// Obté les metadades de votació activa
  ///
  /// Llança [NoActiveJornadaException] si no hi ha jornada configurada
  /// Llança [JornadaNetworkException] en cas d'errors de xarxa
  Future<VotingMetadata> getActiveVotingMetadata({bool forceRefresh = false}) async {
    // Retorna cache si és vàlid
    if (!forceRefresh && _cachedMetadata != null && _isCacheValid) {
      debugPrint('[JornadaService] Retornant metadata des del cache');
      return _cachedMetadata!;
    }

    try {
      debugPrint('[JornadaService] Llegint voting_meta/current...');

      final docRef = _firestore.collection('voting_meta').doc('current');
      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        debugPrint('[JornadaService] Document voting_meta/current no existeix');
        throw NoActiveJornadaException(
          'No hi ha votació activa configurada. El backend encara no ha sincronitzat les dades.',
        );
      }

      final data = snapshot.data();
      if (data == null || data['activeJornada'] == null) {
        debugPrint('[JornadaService] activeJornada és null');
        throw NoActiveJornadaException(
          'El document voting_meta/current no conté activeJornada vàlida.',
        );
      }

      final metadata = VotingMetadata.fromFirestore(data);
      _cachedMetadata = metadata;

      debugPrint(
        '[JornadaService] Metadata carregada: jornada ${metadata.activeJornada}, '
        '${metadata.matchCount} partits',
      );

      return metadata;
    } on FirebaseException catch (e) {
      debugPrint('[JornadaService] Error Firestore: ${e.code} - ${e.message}');
      throw JornadaNetworkException(
        'Error de connexió amb Firestore: ${e.message}',
        e,
      );
    } catch (e) {
      if (e is NoActiveJornadaException) rethrow;
      debugPrint('[JornadaService] Error inesperat: $e');
      throw JornadaNetworkException('Error inesperat: $e', e);
    }
  }

  /// Obté la jornada activa de votació
  ///
  /// Aquesta és la funció principal que s'ha d'usar des de la UI.
  /// Llegeix primer voting_meta/current i després voting_jornades/{jornada}.
  ///
  /// [forceRefresh] - Si és true, ignora el cache local
  ///
  /// Llança:
  /// - [NoActiveJornadaException] si no hi ha jornada activa
  /// - [JornadaNotFoundException] si el document de jornada no existeix
  /// - [JornadaNetworkException] en cas d'errors de xarxa
  Future<JornadaData> fetchActiveJornada({bool forceRefresh = false}) async {
    // Retorna cache si és vàlid
    if (!forceRefresh && _isCacheValid && _cachedJornada != null) {
      debugPrint('[JornadaService] Retornant jornada des del cache');
      return _cachedJornada!;
    }

    try {
      // 1. Obtenim les metadades per saber quina jornada és activa
      final metadata = await getActiveVotingMetadata(forceRefresh: forceRefresh);

      // 2. Llegim el document de la jornada
      JornadaData jornadaData;
      try {
        jornadaData = await fetchJornada(
          metadata.activeJornada,
          forceRefresh: forceRefresh,
        );
      } on JornadaNotFoundException {
        // Si és setmana de descans i la jornada no existeix, retornem buit
        if (metadata.restWeek) {
          debugPrint(
            '[JornadaService] Setmana de descans: jornada ${metadata.activeJornada} '
            'no trobada, retornant JornadaData buit amb info de descans',
          );
          jornadaData = JornadaData.empty(
            jornada: metadata.activeJornada,
            reason: 'rest-week',
          );
        } else {
          rethrow;
        }
      }

      // 3. Propagar info de setmana de descans si cal
      if (metadata.restWeek) {
        jornadaData = JornadaData(
          jornada: jornadaData.jornada,
          competitionId: jornadaData.competitionId,
          competitionName: jornadaData.competitionName,
          partits: jornadaData.partits,
          classificacio: jornadaData.classificacio,
          fetchedAt: jornadaData.fetchedAt,
          source: jornadaData.source,
          weekendStart: jornadaData.weekendStart,
          weekendEnd: jornadaData.weekendEnd,
          restWeek: true,
          restWeekMessage: metadata.restWeekMessage,
          nextVotingDate: metadata.nextVotingDate,
        );
      }

      // Actualitzem cache
      _cachedJornada = jornadaData;
      _cacheTimestamp = DateTime.now();

      return jornadaData;
    } catch (e) {
      debugPrint('[JornadaService] Error fetchActiveJornada: $e');
      rethrow;
    }
  }

  /// Obté les dades d'una jornada específica
  ///
  /// [jornada] - Número de jornada (1-30)
  /// [forceRefresh] - Si és true, ignora el cache local
  Future<JornadaData> fetchJornada(int jornada, {bool forceRefresh = false}) async {
    // Validació bàsica
    if (jornada < 1 || jornada > 30) {
      throw ArgumentError('La jornada ha de ser entre 1 i 30');
    }

    // Comprova cache si és la mateixa jornada
    if (!forceRefresh &&
        _cachedJornada != null &&
        _cachedJornada!.jornada == jornada &&
        _isCacheValid) {
      debugPrint('[JornadaService] Retornant jornada $jornada des del cache');
      return _cachedJornada!;
    }

    try {
      debugPrint('[JornadaService] Llegint voting_jornades/$jornada...');

      final docRef = _firestore.collection('voting_jornades').doc(jornada.toString());
      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        debugPrint('[JornadaService] Document voting_jornades/$jornada no existeix');
        throw JornadaNotFoundException(
          jornada,
          'La jornada $jornada no s\'ha sincronitzat encara. '
              'Espera que el backend executi syncWeeklyVoting.',
        );
      }

      final data = snapshot.data();
      if (data == null) {
        throw JornadaNotFoundException(jornada, 'Document buit per a jornada $jornada');
      }

      final jornadaData = JornadaData.fromFirestore(data);

      debugPrint(
        '[JornadaService] Jornada $jornada carregada: ${jornadaData.partits.length} partits, '
        '${jornadaData.classificacio.length} equips a classificació',
      );

      return jornadaData;
    } on FirebaseException catch (e) {
      debugPrint('[JornadaService] Error Firestore: ${e.code} - ${e.message}');
      throw JornadaNetworkException(
        'Error de connexió amb Firestore: ${e.message}',
        e,
      );
    } catch (e) {
      if (e is JornadaNotFoundException) rethrow;
      debugPrint('[JornadaService] Error inesperat: $e');
      throw JornadaNetworkException('Error inesperat: $e', e);
    }
  }

  /// Obté només els partits de la jornada activa (compatibilitat)
  ///
  /// Aquest mètode manté compatibilitat amb el codi existent.
  Future<List<MatchSeed>> fetchMatches({bool forceRefresh = false}) async {
    try {
      final data = await fetchActiveJornada(forceRefresh: forceRefresh);
      return data.partits;
    } catch (e) {
      debugPrint('[JornadaService] Error fetchMatches: $e');
      return [];
    }
  }

  /// Obté el número de jornada activa actual
  ///
  /// Retorna null si no hi ha jornada activa configurada.
  Future<int?> getActiveJornadaNumber() async {
    try {
      final metadata = await getActiveVotingMetadata();
      return metadata.activeJornada;
    } catch (e) {
      debugPrint('[JornadaService] Error getActiveJornadaNumber: $e');
      return null;
    }
  }

  /// Versió síncrona per compatibilitat (retorna 0 si no hi ha cache)
  ///
  /// NOTA: Prefereix usar [getActiveJornadaNumber] que és async.
  int getCurrentJornadaSync() {
    return _cachedMetadata?.activeJornada ?? 0;
  }

  /// Deprecated: usa fetchActiveJornada() en lloc d'aquest mètode
  @Deprecated('Usa fetchActiveJornada() per obtenir dades des de Firestore')
  Future<int> getCurrentJornada() async {
    final number = await getActiveJornadaNumber();
    return number ?? 0;
  }
}
