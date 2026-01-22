import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:el_visionat/core/models/referee_report.dart';
import 'package:el_visionat/core/models/referee_test.dart';
import 'package:el_visionat/core/models/improvement_tracking.dart';

class ReportsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Subscriptions per escoltar canvis en temps real
  StreamSubscription<QuerySnapshot>? _reportsSubscription;
  StreamSubscription<QuerySnapshot>? _testsSubscription;
  StreamSubscription<DocumentSnapshot>? _trackingSubscription;

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
    // Cancel·lar subscripcions anteriors si n'hi ha
    _cancelSubscriptions();

    // Iniciar listeners en temps real
    _listenToReports(userId);
    _listenToTests(userId);
    _listenToTracking(userId);
  }

  /// Cancel·la totes les subscripcions actives
  void _cancelSubscriptions() {
    _reportsSubscription?.cancel();
    _testsSubscription?.cancel();
    _trackingSubscription?.cancel();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }

  /// Escolta els informes de l'usuari en temps real
  void _listenToReports(String userId) {
    _isLoadingReports = true;
    notifyListeners();

    _reportsSubscription = _firestore
        .collection('reports')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(20)
        .snapshots()
        .listen(
      (snapshot) {
        _reports = snapshot.docs
            .map((doc) => RefereeReport.fromFirestore(doc))
            .toList();

        _isLoadingReports = false;
        debugPrint('[ReportsProvider] Actualitzats ${_reports.length} informes');
        notifyListeners();
      },
      onError: (e) {
        _error = 'Error escoltant informes: $e';
        _isLoadingReports = false;
        debugPrint('[ReportsProvider] Error: $_error');
        notifyListeners();
      },
    );
  }

  /// Escolta els tests de l'usuari en temps real
  void _listenToTests(String userId) {
    _isLoadingTests = true;
    notifyListeners();

    _testsSubscription = _firestore
        .collection('tests')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(20)
        .snapshots()
        .listen(
      (snapshot) {
        _tests =
            snapshot.docs.map((doc) => RefereeTest.fromFirestore(doc)).toList();

        _isLoadingTests = false;
        debugPrint('[ReportsProvider] Actualitzats ${_tests.length} tests');
        notifyListeners();
      },
      onError: (e) {
        _error = 'Error escoltant tests: $e';
        _isLoadingTests = false;
        debugPrint('[ReportsProvider] Error: $_error');
        notifyListeners();
      },
    );
  }

  /// Escolta el tracking de la temporada actual en temps real
  void _listenToTracking(String userId) {
    _isLoadingTracking = true;
    notifyListeners();

    final trackingId = '${userId}_$_selectedSeason';
    _trackingSubscription = _firestore
        .collection('improvement_tracking')
        .doc(trackingId)
        .snapshots()
        .listen(
      (doc) {
        if (doc.exists) {
          _currentSeasonTracking = ImprovementTracking.fromFirestore(doc);
          debugPrint(
            '[ReportsProvider] Tracking actualitzat per temporada $_selectedSeason',
          );
        } else {
          _currentSeasonTracking = null;
          debugPrint(
            '[ReportsProvider] No hi ha tracking per temporada $_selectedSeason',
          );
        }

        _isLoadingTracking = false;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Error escoltant tracking: $e';
        _isLoadingTracking = false;
        debugPrint('[ReportsProvider] Error: $_error');
        notifyListeners();
      },
    );
  }

  /// Carrega els informes de l'usuari (manté compatibilitat)
  Future<void> loadReports(String userId) async {
    _listenToReports(userId);
  }

  /// Carrega els tests de l'usuari (manté compatibilitat)
  Future<void> loadTests(String userId) async {
    _listenToTests(userId);
  }

  /// Carrega el tracking de la temporada actual (manté compatibilitat)
  Future<void> loadCurrentSeasonTracking(String userId) async {
    _listenToTracking(userId);
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

  /// Elimina un informe
  Future<void> deleteReport(String reportId) async {
    try {
      await _firestore.collection('reports').doc(reportId).delete();

      debugPrint('[ReportsProvider] Informe eliminat: $reportId');

      // Els listeners de Firestore actualitzaran automàticament la llista
      // No cal cridar notifyListeners() ni removeWhere() manualment
    } catch (e) {
      _error = 'Error eliminant informe: $e';
      debugPrint('[ReportsProvider] Error: $_error');
      rethrow;
    }
  }

  /// Elimina un test
  Future<void> deleteTest(String testId) async {
    try {
      await _firestore.collection('tests').doc(testId).delete();

      debugPrint('[ReportsProvider] Test eliminat: $testId');

      // Els listeners de Firestore actualitzaran automàticament la llista
      // No cal cridar notifyListeners() ni removeWhere() manualment
    } catch (e) {
      _error = 'Error eliminant test: $e';
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
