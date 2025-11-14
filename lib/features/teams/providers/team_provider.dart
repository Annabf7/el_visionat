import 'package:flutter/material.dart';
import 'package:el_visionat/features/teams/models/team_platform.dart';
import 'package:el_visionat/features/teams/services/team_data_service.dart';

/// Provider per gestionar l'estat dels equips de bàsquet
/// Segueix els estàndards d'arquitectura del projecte:
/// - No conté lògica de negoci pesada
/// - Delega totes les operacions al TeamDataService
/// - Proporciona estat reactiu a la UI
class TeamProvider extends ChangeNotifier {
  final TeamDataService _teamDataService;

  TeamProvider({required TeamDataService teamDataService})
    : _teamDataService = teamDataService;

  // --- Estat ---
  List<Team> _teams = [];
  bool _isLoading = false;
  String? _error;

  // --- Getters ---
  List<Team> get teams => _teams;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasTeams => _teams.isNotEmpty;

  // --- Filtres ---
  List<Team> get masculineTeams =>
      _teams.where((team) => team.gender == 'masculí').toList();
  List<Team> get feminineTeams =>
      _teams.where((team) => team.gender == 'femení').toList();

  /// Carrega tots els equips des del servei
  Future<void> loadTeams() async {
    if (_isLoading) return; // Evita cridades duplicades

    _setLoading(true);
    _error = null;

    try {
      _teams = await _teamDataService.getTeams();
      debugPrint('TeamProvider: loaded ${_teams.length} teams');
    } catch (e) {
      _error = 'Error carregant equips: ${e.toString()}';
      debugPrint('TeamProvider error: $_error');
    } finally {
      _setLoading(false);
    }
  }

  /// Refresca els equips forçant una nova càrrega
  Future<void> refreshTeams() async {
    _teams.clear();
    await loadTeams();
  }

  /// Cerca equips per nom o acrònim
  List<Team> searchTeams(String query) {
    if (query.isEmpty) return _teams;

    final lowercaseQuery = query.toLowerCase();
    return _teams.where((team) {
      return team.name.toLowerCase().contains(lowercaseQuery) ||
          team.acronym.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Filtra equips per gènere
  List<Team> getTeamsByGender(String gender) {
    return _teams.where((team) => team.gender == gender).toList();
  }

  // --- Mètodes privats ---
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
