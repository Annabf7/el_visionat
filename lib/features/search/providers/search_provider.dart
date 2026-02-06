import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/search_result.dart';

/// Provider per gestionar la cerca global d'àrbitres
class SearchProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Estat de la cerca
  String _query = '';
  bool _isSearching = false;
  bool _isLoading = false;
  List<RefereeSearchResult> _results = [];
  List<RefereeSearchResult> _allReferees = [];
  bool _refereesLoaded = false;

  // Getters
  String get query => _query;
  bool get isSearching => _isSearching;
  bool get isLoading => _isLoading;
  List<RefereeSearchResult> get results => _results;
  bool get hasResults => _results.isNotEmpty;

  /// Inicia el mode cerca (quan l'usuari fa focus al camp)
  void startSearch() {
    _isSearching = true;
    notifyListeners();

    // Carregar àrbitres si no estan carregats
    if (!_refereesLoaded) {
      _loadAllReferees();
    }
  }

  /// Tanca el mode cerca
  void closeSearch() {
    _isSearching = false;
    _query = '';
    _results = [];
    notifyListeners();
  }

  /// Actualitza la cerca amb un nou query
  void updateSearch(String newQuery) {
    _query = newQuery;

    if (newQuery.trim().isEmpty) {
      _results = [];
      notifyListeners();
      return;
    }

    // Filtrar localment si ja tenim els àrbitres
    if (_refereesLoaded) {
      _filterResults(newQuery);
    }
  }

  /// Carrega tots els àrbitres del registre amb info d'usuari
  Future<void> _loadAllReferees() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Obtenir tots els àrbitres del registre
      final registrySnapshot = await _firestore
          .collection('referees_registry')
          .orderBy('cognoms')
          .get();

      // 2. Obtenir tots els usuaris amb llissenciaId per fer el mapping
      final usersSnapshot = await _firestore
          .collection('users')
          .where('llissenciaId', isNotEqualTo: null)
          .get();

      // Crear mapa de llissenciaId -> userId
      final Map<String, String> licenseToUserId = {};
      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        final licenseId = data['llissenciaId']?.toString();
        if (licenseId != null && licenseId.isNotEmpty) {
          licenseToUserId[licenseId] = doc.id;
        }
      }

      // 3. Crear els resultats combinant les dues fonts
      _allReferees = registrySnapshot.docs.map((doc) {
        final data = doc.data();
        final licenseId = data['llissenciaId']?.toString() ?? '';
        final userId = licenseToUserId[licenseId];

        return RefereeSearchResult.fromRegistryAndUser(
          registryData: data,
          userId: userId,
        );
      }).toList();

      _refereesLoaded = true;

      // Aplicar filtre si hi ha query actiu
      if (_query.isNotEmpty) {
        _filterResults(_query);
      }
    } catch (e) {
      debugPrint('Error carregant àrbitres: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filtra els resultats segons el query
  void _filterResults(String query) {
    if (query.trim().length < 2) {
      _results = [];
      notifyListeners();
      return;
    }

    final matches = _allReferees
        .where((referee) => referee.matchesSearch(query))
        .toList();

    // Ordenar per rellevància
    matches.sort((a, b) {
      final queryLower = query.toLowerCase().trim();

      // Prioritzar coincidències exactes de llicència
      if (a.llissenciaId == query.trim()) return -1;
      if (b.llissenciaId == query.trim()) return 1;

      // Prioritzar els que tenen compte a l'app
      if (a.hasAccount && !b.hasAccount) return -1;
      if (!a.hasAccount && b.hasAccount) return 1;

      // Prioritzar coincidències que comencen amb el query
      final aStartsWith = a.fullName.toLowerCase().startsWith(queryLower);
      final bStartsWith = b.fullName.toLowerCase().startsWith(queryLower);

      if (aStartsWith && !bStartsWith) return -1;
      if (!aStartsWith && bStartsWith) return 1;

      // Ordenar alfabèticament
      return a.cognoms.compareTo(b.cognoms);
    });

    // Limitar a 10 resultats
    _results = matches.take(10).toList();
    notifyListeners();
  }

  /// Força recarregar els àrbitres (per si s'afegeixen nous)
  Future<void> refresh() async {
    _refereesLoaded = false;
    await _loadAllReferees();
  }
}
