import 'package:flutter/foundation.dart';
import '../services/match_referee_service.dart';
import '../models/match_models.dart';

/// Provider per gestionar la informació del partit de la setmana
///
/// Permet actualitzar l'àrbitre només canviant el número de llicència
class WeeklyMatchProvider extends ChangeNotifier {
  final MatchRefereeService _refereeService;

  WeeklyMatchProvider(this._refereeService) {
    // Auto-inicialitzar quan es crea el provider
    _autoInitialize();
  }

  // --- CONFIGURACIÓ DEL PARTIT (només canviar aquestes variables) ---

  /// ⚙️ VARIABLE PRINCIPAL: Només cal canviar aquest número!
  static const String _currentRefereeLicense = "40177"; // 🔧 CANVIAR AQUÍ

  /// Altres dades del partit (configurables)
  static const String _currentLeague = "Super copa Catalunya";
  static const int _currentMatchday = 14;
  static const String _homeTeam = "CB Salt";
  static const String _awayTeam = "CB Martorell";

  // --- ESTAT INTERN ---
  MatchReferee? _currentReferee;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  // --- GETTERS PÚBLICS ---

  /// Dades de l'àrbitre actual (carregades des de Firestore)
  MatchReferee? get currentReferee => _currentReferee;

  /// Nom de l'àrbitre per mostrar a la UI
  String get refereeName => _currentReferee?.fullName ?? 'Carregant àrbitre...';

  /// Categoria de l'àrbitre
  String get refereeCategory => _currentReferee?.category ?? '';

  /// Detalls del partit per al widget MatchDetailsCard
  MatchDetails get matchDetails => MatchDetails(
    refereeName: refereeName,
    league: _currentLeague,
    matchday: _currentMatchday,
  );

  /// Equips del partit
  String get homeTeam => _homeTeam;
  String get awayTeam => _awayTeam;
  String get matchTitle => '$_homeTeam vs $_awayTeam';

  /// Estats de càrrega
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isInitialized => _isInitialized;

  // --- MÈTODES PÚBLICS ---

  /// Inicialitza el provider carregant les dades de l'àrbitre
  ///
  /// Crida això des d'initState() o addPostFrameCallback()
  Future<void> initialize() async {
    if (_isInitialized) return; // Evitar múltiples inicialitzacions

    await _loadCurrentReferee();
    _isInitialized = true;
  }

  /// Força la recàrrega de les dades de l'àrbitre
  ///
  /// Útil si canvies _currentRefereeLicense i vols recarregar
  Future<void> refreshReferee() async {
    await _loadCurrentReferee();
  }

  // --- MÈTODES PRIVATS ---

  /// Inicialitzar automàticament quan es crea el provider
  void _autoInitialize() {
    // Executar en el següent microtask per evitar problemes de constructors
    Future.microtask(() {
      if (!_isInitialized) {
        initialize();
      }
    });
  }

  Future<void> _loadCurrentReferee() async {
    _setLoading(true);
    _clearError();

    try {
      final referee = await _refereeService.getRefereeByLicense(
        _currentRefereeLicense,
      );

      if (referee != null) {
        _currentReferee = referee;
        debugPrint(
          '✅ Àrbitre carregat: ${referee.fullName} (${referee.licenseId})',
        );
      } else {
        _setError(
          'No s\'ha pogut carregar l\'àrbitre amb llicència $_currentRefereeLicense',
        );
      }
    } catch (e) {
      _setError('Error carregant àrbitre: ${e.toString()}');
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
