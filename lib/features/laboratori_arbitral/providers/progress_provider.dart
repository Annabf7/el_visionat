import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/monthly_battle.dart';
import '../services/monthly_battle_service.dart';

class ProgressProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MonthlyBattleService _battleService = MonthlyBattleService();

  bool _isLoading = true;
  String? _errorMessage;

  // Stats globals
  int _totalAnswers = 0;
  int _correctAnswers = 0;
  int _streak = 0;

  // Stats per article
  List<ArticleStat> _articleStats = [];

  // Última batalla
  BattleResult? _lastBattleResult;
  int? _lastBattlePosition;
  String? _lastBattleTitle;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalAnswers => _totalAnswers;
  int get correctAnswers => _correctAnswers;
  int get streak => _streak;
  double get accuracyPercent =>
      _totalAnswers > 0 ? (_correctAnswers / _totalAnswers) * 100 : 0;
  List<ArticleStat> get articleStats => _articleStats;
  BattleResult? get lastBattleResult => _lastBattleResult;
  int? get lastBattlePosition => _lastBattlePosition;
  String? get lastBattleTitle => _lastBattleTitle;

  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        _errorMessage = 'No autenticat';
        _isLoading = false;
        notifyListeners();
        return;
      }

      await Future.wait([
        _loadGlobalStats(uid),
        _loadArticleStats(uid),
        _loadLastBattle(uid),
      ]);
    } catch (e) {
      debugPrint('Error carregant progrés: $e');
      _errorMessage = 'Error carregant les estadístiques';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadGlobalStats(String uid) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('quiz_stats_global')
        .doc('summary')
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      _totalAnswers = data['totalAnswers'] as int? ?? 0;
      _correctAnswers = data['correctAnswers'] as int? ?? 0;
      _streak = data['streak'] as int? ?? 0;
    }
  }

  Future<void> _loadArticleStats(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('quiz_stats_by_article')
        .get();

    _articleStats = snapshot.docs.map((doc) {
      final data = doc.data();
      final total = data['totalAnswers'] as int? ?? 0;
      final correct = data['correctAnswers'] as int? ?? 0;
      return ArticleStat(
        articleNumber: doc.id,
        totalAnswers: total,
        correctAnswers: correct,
        accuracyPercent: total > 0 ? (correct / total) * 100 : 0,
      );
    }).toList();

    // Ordenar per número d'article
    _articleStats.sort((a, b) {
      final aNum = int.tryParse(a.articleNumber) ?? 999;
      final bNum = int.tryParse(b.articleNumber) ?? 999;
      return aNum.compareTo(bNum);
    });
  }

  Future<void> _loadLastBattle(String uid) async {
    try {
      final battle = await _battleService.getCurrentBattle();
      if (battle == null) return;

      final result = await _battleService.getUserResult(
        battle.yearMonth,
        uid,
      );

      if (result != null) {
        _lastBattleResult = result;
        _lastBattleTitle = battle.title;

        final ranking = await _battleService.getRanking(battle.yearMonth);
        final idx = ranking.indexWhere((r) => r.userId == uid);
        if (idx >= 0) _lastBattlePosition = idx + 1;
      }
    } catch (e) {
      debugPrint('Error carregant batalla: $e');
    }
  }
}

/// Estadística d'un article individual
class ArticleStat {
  final String articleNumber;
  final int totalAnswers;
  final int correctAnswers;
  final double accuracyPercent;

  const ArticleStat({
    required this.articleNumber,
    required this.totalAnswers,
    required this.correctAnswers,
    required this.accuracyPercent,
  });
}
