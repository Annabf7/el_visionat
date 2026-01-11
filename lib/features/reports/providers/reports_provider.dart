import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:el_visionat/core/models/referee_report.dart';
import 'package:el_visionat/core/models/referee_test.dart';
import 'package:el_visionat/core/models/improvement_tracking.dart';

class ReportsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reports
  List<RefereeReport> _reports = [];
  List<RefereeReport> get reports => _reports;

  // Tests
  List<RefereeTest> _tests = [];
  List<RefereeTest> get tests => _tests;

  // Improvement Tracking
  ImprovementTracking? _currentSeasonTracking;
  ImprovementTracking? get currentSeasonTracking => _currentSeasonTracking;

  // Loading states
  bool _isLoadingReports = false;
  bool get isLoadingReports => _isLoadingReports;

  bool _isLoadingTests = false;
  bool get isLoadingTests => _isLoadingTests;

  bool _isLoadingTracking = false;
  bool get isLoadingTracking => _isLoadingTracking;

  // Error state
  String? _error;
  String? get error => _error;

  // Temporada seleccionada
  String _selectedSeason = '2025-2026';
  String get selectedSeason => _selectedSeason;

  /// Canvia la temporada seleccionada i recarrega les dades
  void selectSeason(String season) {
    _selectedSeason = season;
    notifyListeners();
    // Recarregar dades per la nova temporada
    // TODO: Implementar filtre per temporada
  }

  /// Inicialitza el provider amb l'UID de l'usuari
  Future<void> initialize(String userId) async {
    await Future.wait([
      loadReports(userId),
      loadTests(userId),
      loadCurrentSeasonTracking(userId),
    ]);
  }

  /// Carrega els informes de l'usuari
  Future<void> loadReports(String userId) async {
    _isLoadingReports = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('reports')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(20) // Limitem a els últims 20 informes
          .get();

      _reports = snapshot.docs
          .map((doc) => RefereeReport.fromFirestore(doc))
          .toList();

      debugPrint('[ReportsProvider] Carregats ${_reports.length} informes');
    } catch (e) {
      _error = 'Error carregant informes: $e';
      debugPrint('[ReportsProvider] Error: $_error');
    } finally {
      _isLoadingReports = false;
      notifyListeners();
    }
  }

  /// Carrega els tests de l'usuari
  Future<void> loadTests(String userId) async {
    _isLoadingTests = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('tests')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(20) // Limitem a els últims 20 tests
          .get();

      _tests =
          snapshot.docs.map((doc) => RefereeTest.fromFirestore(doc)).toList();

      debugPrint('[ReportsProvider] Carregats ${_tests.length} tests');
    } catch (e) {
      _error = 'Error carregant tests: $e';
      debugPrint('[ReportsProvider] Error: $_error');
    } finally {
      _isLoadingTests = false;
      notifyListeners();
    }
  }

  /// Carrega el tracking de la temporada actual
  Future<void> loadCurrentSeasonTracking(String userId) async {
    _isLoadingTracking = true;
    _error = null;
    notifyListeners();

    try {
      final trackingId = '${userId}_$_selectedSeason';
      final doc = await _firestore
          .collection('improvement_tracking')
          .doc(trackingId)
          .get();

      if (doc.exists) {
        _currentSeasonTracking = ImprovementTracking.fromFirestore(doc);
        debugPrint(
          '[ReportsProvider] Tracking carregat per temporada $_selectedSeason',
        );
      } else {
        _currentSeasonTracking = null;
        debugPrint(
          '[ReportsProvider] No hi ha tracking per temporada $_selectedSeason',
        );
      }
    } catch (e) {
      _error = 'Error carregant tracking: $e';
      debugPrint('[ReportsProvider] Error: $_error');
    } finally {
      _isLoadingTracking = false;
      notifyListeners();
    }
  }

  /// Afegeix un nou informe
  Future<void> addReport(RefereeReport report) async {
    try {
      await _firestore.collection('reports').doc(report.id).set(report.toMap());

      _reports.insert(0, report);
      notifyListeners();

      debugPrint('[ReportsProvider] Informe afegit: ${report.id}');
    } catch (e) {
      _error = 'Error afegint informe: $e';
      debugPrint('[ReportsProvider] Error: $_error');
      rethrow;
    }
  }

  /// Afegeix un nou test
  Future<void> addTest(RefereeTest test) async {
    try {
      await _firestore.collection('tests').doc(test.id).set(test.toMap());

      _tests.insert(0, test);
      notifyListeners();

      debugPrint('[ReportsProvider] Test afegit: ${test.id}');
    } catch (e) {
      _error = 'Error afegint test: $e';
      debugPrint('[ReportsProvider] Error: $_error');
      rethrow;
    }
  }

  /// Actualitza el tracking de millores
  Future<void> updateTracking(ImprovementTracking tracking) async {
    try {
      await _firestore
          .collection('improvement_tracking')
          .doc(tracking.id)
          .set(tracking.toMap());

      _currentSeasonTracking = tracking;
      notifyListeners();

      debugPrint('[ReportsProvider] Tracking actualitzat: ${tracking.id}');
    } catch (e) {
      _error = 'Error actualitzant tracking: $e';
      debugPrint('[ReportsProvider] Error: $_error');
      rethrow;
    }
  }

  /// Neteja l'error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Estadístiques de resum
  int get totalReports => _reports.length;
  int get totalTests => _tests.length;

  double get averageTestScore {
    if (_tests.isEmpty) return 0.0;
    final sum = _tests.fold<double>(0.0, (sum, test) => sum + test.score);
    return sum / _tests.length;
  }

  int get totalImprovementPoints {
    return _currentSeasonTracking?.totalImprovementPoints ?? 0;
  }

  int get totalWeakAreas {
    return _currentSeasonTracking?.totalWeakAreas ?? 0;
  }

  /// Obté els reports més recents (últims 5)
  List<RefereeReport> get recentReports => _reports.take(5).toList();

  /// Obté els tests més recents (últims 5)
  List<RefereeTest> get recentTests => _tests.take(5).toList();

  /// Obté els punts de millora més recurrents
  List<CategoryImprovement> get topImprovements {
    if (_currentSeasonTracking == null) return [];

    final improvements = List<CategoryImprovement>.from(
      _currentSeasonTracking!.reportImprovements,
    );

    improvements.sort((a, b) => b.occurrences.compareTo(a.occurrences));
    return improvements.take(5).toList();
  }

  /// Obté les àrees febles en tests
  List<WeakArea> get topWeakAreas {
    if (_currentSeasonTracking == null) return [];

    final weakAreas = List<WeakArea>.from(
      _currentSeasonTracking!.testWeakAreas,
    );

    weakAreas.sort((a, b) => b.errorRate.compareTo(a.errorRate));
    return weakAreas.take(5).toList();
  }
}
