// ============================================================================
// WeeklyFocus Model - Dades del partit guanyador i equip arbitral
// ============================================================================
// Mapeja el document Firestore weekly_focus/current

/// Oficial de taula individual
class TableOfficial {
  final String role;
  final String name;

  const TableOfficial({required this.role, required this.name});

  factory TableOfficial.fromJson(Map<String, dynamic> json) {
    return TableOfficial(
      role: json['role'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

/// Informació dels oficials del partit (extrets de l'acta FCBQ)
class RefereeInfo {
  final String? principal;
  final String? auxiliar;
  final List<TableOfficial> tableOfficials;
  final String? source;
  final String? actaUrl;

  const RefereeInfo({
    this.principal,
    this.auxiliar,
    this.tableOfficials = const [],
    this.source,
    this.actaUrl,
  });

  factory RefereeInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RefereeInfo();

    // Parse tableOfficials array
    final officialsJson = json['tableOfficials'] as List<dynamic>?;
    final officials =
        officialsJson
            ?.map((e) => TableOfficial.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return RefereeInfo(
      principal: json['principal'] as String?,
      auxiliar: json['auxiliar'] as String?,
      tableOfficials: officials,
      source: json['source'] as String?,
      actaUrl: json['actaUrl'] as String?,
    );
  }

  /// Retorna true si tenim almenys l'àrbitre principal
  bool get hasData => principal != null && principal!.isNotEmpty;

  /// Retorna l'anotador si existeix
  String? get anotador =>
      tableOfficials.where((o) => o.role == 'Anotador').firstOrNull?.name;

  /// Retorna el cronometrador si existeix
  String? get cronometrador =>
      tableOfficials.where((o) => o.role == 'Cronometrador').firstOrNull?.name;

  /// Retorna l'operador RLL si existeix
  String? get operadorRll =>
      tableOfficials.where((o) => o.role == 'Operador RLL').firstOrNull?.name;

  /// Retorna el caller si existeix
  String? get caller =>
      tableOfficials.where((o) => o.role == 'Caller').firstOrNull?.name;
}

/// Informació d'un equip dins del partit guanyador
class WinningTeamInfo {
  final String? teamId;
  final String teamNameRaw;
  final String teamNameDisplay;
  final String logoSlug;
  final String? colorHex;

  const WinningTeamInfo({
    this.teamId,
    required this.teamNameRaw,
    required this.teamNameDisplay,
    required this.logoSlug,
    this.colorHex,
  });

  factory WinningTeamInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const WinningTeamInfo(
        teamNameRaw: '',
        teamNameDisplay: 'Desconegut',
        logoSlug: '',
      );
    }
    return WinningTeamInfo(
      teamId: json['teamId'] as String?,
      teamNameRaw: json['teamNameRaw'] as String? ?? '',
      teamNameDisplay: json['teamNameDisplay'] as String? ?? 'Desconegut',
      logoSlug: json['logoSlug'] as String? ?? '',
      colorHex: json['colorHex'] as String?,
    );
  }
}

/// Partit guanyador de la votació
class WinningMatch {
  final String matchId;
  final int jornada;
  final WinningTeamInfo home;
  final WinningTeamInfo away;
  final String dateTime;
  final String dateDisplay;
  final String? location;
  final String status;
  final int? homeScore;
  final int? awayScore;

  const WinningMatch({
    required this.matchId,
    required this.jornada,
    required this.home,
    required this.away,
    required this.dateTime,
    required this.dateDisplay,
    this.location,
    required this.status,
    this.homeScore,
    this.awayScore,
  });

  factory WinningMatch.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return WinningMatch(
        matchId: '',
        jornada: 0,
        home: const WinningTeamInfo(
          teamNameRaw: '',
          teamNameDisplay: 'Desconegut',
          logoSlug: '',
        ),
        away: const WinningTeamInfo(
          teamNameRaw: '',
          teamNameDisplay: 'Desconegut',
          logoSlug: '',
        ),
        dateTime: '',
        dateDisplay: '',
        status: 'unknown',
      );
    }
    return WinningMatch(
      matchId: json['matchId'] as String? ?? '',
      jornada: json['jornada'] as int? ?? 0,
      home: WinningTeamInfo.fromJson(json['home'] as Map<String, dynamic>?),
      away: WinningTeamInfo.fromJson(json['away'] as Map<String, dynamic>?),
      dateTime: json['dateTime'] as String? ?? '',
      dateDisplay: json['dateDisplay'] as String? ?? '',
      location: json['location'] as String?,
      status: json['status'] as String? ?? 'unknown',
      homeScore: json['homeScore'] as int?,
      awayScore: json['awayScore'] as int?,
    );
  }

  /// Retorna el nom del partit formatat: "Local vs Visitant"
  String get matchDisplayName =>
      '${home.teamNameDisplay} vs ${away.teamNameDisplay}';

  /// Retorna el resultat si està disponible: "85 - 72"
  String? get scoreDisplay {
    if (homeScore != null && awayScore != null) {
      return '$homeScore - $awayScore';
    }
    return null;
  }
}

/// Document complet de weekly_focus/current
class WeeklyFocus {
  final int jornada;
  final WinningMatch winningMatch;
  final int totalVotes;
  final RefereeInfo refereeInfo;
  final String votingClosedAt;
  final bool suggestionsOpen;
  final String suggestionsCloseAt;
  final String status; // "minutatge" | "entrevista_pendent" | "completat"
  final String competitionName;

  const WeeklyFocus({
    required this.jornada,
    required this.winningMatch,
    required this.totalVotes,
    required this.refereeInfo,
    required this.votingClosedAt,
    required this.suggestionsOpen,
    required this.suggestionsCloseAt,
    required this.status,
    this.competitionName = 'Super Copa Masculina',
  });

  factory WeeklyFocus.fromJson(Map<String, dynamic> json) {
    return WeeklyFocus(
      jornada: json['jornada'] as int? ?? 0,
      winningMatch: WinningMatch.fromJson(
        json['winningMatch'] as Map<String, dynamic>?,
      ),
      totalVotes: json['totalVotes'] as int? ?? 0,
      refereeInfo: RefereeInfo.fromJson(
        json['refereeInfo'] as Map<String, dynamic>?,
      ),
      votingClosedAt: json['votingClosedAt'] as String? ?? '',
      suggestionsOpen: json['suggestionsOpen'] as bool? ?? false,
      suggestionsCloseAt: json['suggestionsCloseAt'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
      competitionName:
          json['competitionName'] as String? ?? 'Super Copa Masculina',
    );
  }

  /// Retorna true si tenim dades vàlides del focus
  bool get isValid => jornada > 0 && winningMatch.matchId.isNotEmpty;

  /// Retorna l'estat en català
  String get statusDisplay {
    switch (status) {
      case 'minutatge':
        return 'Minutatge en curs';
      case 'entrevista_pendent':
        return 'Entrevista pendent';
      case 'completat':
        return 'Completat';
      default:
        return 'Pendent';
    }
  }
}
