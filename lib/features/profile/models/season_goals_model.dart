/// Estats possibles per a un objectiu (només 2: actiu o completat)
enum GoalStatus {
  active('Actiu'),
  completed('Completat');

  const GoalStatus(this.displayName);
  final String displayName;

  static GoalStatus fromString(String? value) {
    switch (value) {
      case 'completed':
        return GoalStatus.completed;
      case 'active':
      default:
        return GoalStatus.active;
    }
  }

  String toJson() => name;
}

/// Model per a un objectiu individual amb estat
class Goal {
  final String text;
  final GoalStatus status;
  final DateTime? lastModified;

  const Goal({
    this.text = '',
    this.status = GoalStatus.active,
    this.lastModified,
  });

  factory Goal.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const Goal();

    return Goal(
      text: data['text'] as String? ?? '',
      status: GoalStatus.fromString(data['status'] as String?),
      lastModified: data['lastModified'] != null
          ? DateTime.tryParse(data['lastModified'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'text': text,
        'status': status.toJson(),
        'lastModified': lastModified?.toIso8601String(),
      };

  Goal copyWith({
    String? text,
    GoalStatus? status,
    DateTime? lastModified,
  }) {
    return Goal(
      text: text ?? this.text,
      status: status ?? this.status,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  bool get isEmpty => text.trim().isEmpty;
}

/// Entry de l'historial d'objectius assolits
class GoalHistoryEntry {
  final String text;
  final DateTime achievedDate;
  final String category; // 'puntsMillorar', 'objectiusTrimestrals', 'objectiuTemporada'

  const GoalHistoryEntry({
    required this.text,
    required this.achievedDate,
    required this.category,
  });

  factory GoalHistoryEntry.fromMap(Map<String, dynamic> data) {
    return GoalHistoryEntry(
      text: data['text'] as String? ?? '',
      achievedDate: DateTime.tryParse(data['achievedDate'] as String) ??
          DateTime.now(),
      category: data['category'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'text': text,
        'achievedDate': achievedDate.toIso8601String(),
        'category': category,
      };
}

/// Model de dades per als objectius de temporada de l'usuari
class SeasonGoals {
  // Els punts forts no tenen evolució, són descriptius estàtics
  final List<String> puntsForts;

  // Objectius amb estat i evolució
  final List<Goal> puntsMillorar;
  final List<Goal> objectiusTrimestrals;
  final Goal objectiuTemporada;

  // Historial d'objectius assolits
  final List<GoalHistoryEntry> history;

  const SeasonGoals({
    this.puntsForts = const ['', '', ''],
    this.puntsMillorar = const [Goal(), Goal(), Goal()],
    this.objectiusTrimestrals = const [Goal(), Goal(), Goal()],
    this.objectiuTemporada = const Goal(),
    this.history = const [],
  });

  /// Constructor des de Map (Firestore)
  factory SeasonGoals.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const SeasonGoals();

    return SeasonGoals(
      puntsForts: _parseStringList(data['puntsForts'], 3),
      puntsMillorar: _parseGoalList(data['puntsMillorar'], 3),
      objectiusTrimestrals: _parseGoalList(data['objectiusTrimestrals'], 3),
      objectiuTemporada: Goal.fromMap(data['objectiuTemporada'] as Map<String, dynamic>?),
      history: _parseHistoryList(data['history']),
    );
  }

  /// Converteix a Map per guardar a Firestore
  Map<String, dynamic> toMap() => {
        'puntsForts': puntsForts,
        'puntsMillorar': puntsMillorar.map((g) => g.toMap()).toList(),
        'objectiusTrimestrals': objectiusTrimestrals.map((g) => g.toMap()).toList(),
        'objectiuTemporada': objectiuTemporada.toMap(),
        'history': history.map((h) => h.toMap()).toList(),
      };

  /// Helper per parsejar llistes de strings amb longitud fixa
  static List<String> _parseStringList(dynamic data, int expectedLength) {
    if (data is List) {
      final list = data.map((e) => e.toString()).toList();
      while (list.length < expectedLength) {
        list.add('');
      }
      return list.take(expectedLength).toList();
    }
    return List.filled(expectedLength, '');
  }

  /// Helper per parsejar llistes de Goals amb longitud fixa
  static List<Goal> _parseGoalList(dynamic data, int expectedLength) {
    if (data is List) {
      final list = data
          .map((e) => Goal.fromMap(e is Map<String, dynamic> ? e : null))
          .toList();
      while (list.length < expectedLength) {
        list.add(const Goal());
      }
      return list.take(expectedLength).toList();
    }
    return List.filled(expectedLength, const Goal());
  }

  /// Helper per parsejar l'historial
  static List<GoalHistoryEntry> _parseHistoryList(dynamic data) {
    if (data is List) {
      return data
          .map((e) => GoalHistoryEntry.fromMap(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Copia amb modificacions
  SeasonGoals copyWith({
    List<String>? puntsForts,
    List<Goal>? puntsMillorar,
    List<Goal>? objectiusTrimestrals,
    Goal? objectiuTemporada,
    List<GoalHistoryEntry>? history,
  }) {
    return SeasonGoals(
      puntsForts: puntsForts ?? this.puntsForts,
      puntsMillorar: puntsMillorar ?? this.puntsMillorar,
      objectiusTrimestrals: objectiusTrimestrals ?? this.objectiusTrimestrals,
      objectiuTemporada: objectiuTemporada ?? this.objectiuTemporada,
      history: history ?? this.history,
    );
  }

  /// Indica si tots els camps estan buits
  bool get isEmpty =>
      puntsForts.every((e) => e.trim().isEmpty) &&
      puntsMillorar.every((g) => g.isEmpty) &&
      objectiusTrimestrals.every((g) => g.isEmpty) &&
      objectiuTemporada.isEmpty;

  /// Obté l'historial filtrat per categoria
  List<GoalHistoryEntry> getHistoryByCategory(String category) {
    return history
        .where((entry) => entry.category == category)
        .toList()
      ..sort((a, b) => b.achievedDate.compareTo(a.achievedDate));
  }

  /// Nombre d'objectius completats
  int get completedGoalsCount {
    return puntsMillorar.where((g) => g.status == GoalStatus.completed).length +
        objectiusTrimestrals.where((g) => g.status == GoalStatus.completed).length +
        (objectiuTemporada.status == GoalStatus.completed ? 1 : 0);
  }
}