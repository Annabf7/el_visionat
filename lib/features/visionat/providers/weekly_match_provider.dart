import 'package:flutter/foundation.dart';
import 'package:el_visionat/features/voting/models/weekly_focus.dart';
import 'package:el_visionat/features/voting/services/weekly_focus_service.dart';

/// Provider per gestionar la informació del partit de la setmana
///
/// Ara llegeix des de weekly_focus/current de Firestore
class WeeklyMatchProvider extends ChangeNotifier {
  final WeeklyFocusService _focusService = WeeklyFocusService();

  WeeklyMatchProvider() {
    // Auto-inicialitzar quan es crea el provider
    _autoInitialize();
  }

  // --- ESTAT INTERN ---
  WeeklyFocus? _weeklyFocus;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  // --- GETTERS PÚBLICS ---

  /// Dades completes del focus setmanal
  WeeklyFocus? get weeklyFocus => _weeklyFocus;

  /// ID únic del partit setmanal (per associar highlights)
  String get matchId => _weeklyFocus?.winningMatch.matchId ?? '';

  /// Nom de l'àrbitre principal
  String get refereeName =>
      _weeklyFocus?.refereeInfo.principal ?? 'Carregant àrbitre...';

  /// Categoria (usem la competició com a categoria)
  String get refereeCategory => _weeklyFocus?.competitionName ?? '';

  /// Jornada actual
  int get matchday => _weeklyFocus?.jornada ?? 0;

  /// Competició
  String get league => _weeklyFocus?.competitionName ?? 'Super Copa Masculina';

  /// Equip local
  String get homeTeam =>
      _weeklyFocus?.winningMatch.home.teamNameDisplay ?? 'Local';

  /// Equip visitant
  String get awayTeam =>
      _weeklyFocus?.winningMatch.away.teamNameDisplay ?? 'Visitant';

  /// Títol del partit
  String get matchTitle => '$homeTeam vs $awayTeam';

  /// Resultat del partit
  String? get matchScore => _weeklyFocus?.winningMatch.scoreDisplay;

  /// Puntuació local
  int? get homeScore => _weeklyFocus?.winningMatch.homeScore;

  /// Puntuació visitant
  int? get awayScore => _weeklyFocus?.winningMatch.awayScore;

  /// Data i hora formatada
  String get dateDisplay => _weeklyFocus?.winningMatch.dateDisplay ?? '';

  /// Data ISO
  String get dateTime => _weeklyFocus?.winningMatch.dateTime ?? '';

  /// Lloc/pavelló
  String? get location => _weeklyFocus?.winningMatch.location;

  /// Informació dels àrbitres
  RefereeInfo? get refereeInfo => _weeklyFocus?.refereeInfo;

  /// Estats de càrrega
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isInitialized => _isInitialized;
  bool get hasData => _weeklyFocus != null && _weeklyFocus!.isValid;

  // --- MÈTODES PÚBLICS ---

  /// Inicialitza el provider carregant les dades del weekly_focus
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadWeeklyFocus();
    _isInitialized = true;
  }

  /// Força la recàrrega de les dades
  Future<void> refresh() async {
    await _loadWeeklyFocus(forceRefresh: true);
  }

  // --- MÈTODES PRIVATS ---

  void _autoInitialize() {
    Future.microtask(() {
      if (!_isInitialized) {
        initialize();
      }
    });
  }

  Future<void> _loadWeeklyFocus({bool forceRefresh = false}) async {
    _setLoading(true);
    _clearError();

    try {
      final focus = await _focusService.getCurrentFocus(
        forceRefresh: forceRefresh,
      );

      if (focus != null) {
        _weeklyFocus = focus;
        debugPrint(
          '✅ Weekly focus carregat: ${focus.winningMatch.matchDisplayName}',
        );
        debugPrint(
          '   Àrbitre: ${focus.refereeInfo.principal ?? "no disponible"}',
        );
      } else {
        _setError('No hi ha partit de la setmana configurat');
      }
    } catch (e) {
      _setError('Error carregant dades: ${e.toString()}');
      debugPrint('❌ Error en WeeklyMatchProvider: $e');
    }

    _setLoading(false);
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}
