import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/monthly_battle.dart';
import '../models/quiz_question.dart';
import '../services/monthly_battle_service.dart';

class MonthlyBattleProvider extends ChangeNotifier {
  final MonthlyBattleService _service = MonthlyBattleService();

  // Estat de la batalla
  MonthlyBattle? _battle;
  BattleResult? _userResult; // null si no ha jugat
  List<BattleResult> _ranking = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Estat del joc en curs
  List<QuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isPlaying = false;
  bool _showExplanation = false;
  int? _selectedOptionIndex;
  bool _isAnswerCorrect = false;

  // Timer global
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _uiTimer;
  List<BattleAnswer> _answers = [];
  int _questionStartMs = 0;

  // Getters
  MonthlyBattle? get battle => _battle;
  BattleResult? get userResult => _userResult;
  List<BattleResult> get ranking => _ranking;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasPlayed => _userResult != null;

  List<QuizQuestion> get questions => _questions;
  int get currentQuestionIndex => _currentQuestionIndex;
  QuizQuestion? get currentQuestion =>
      (_questions.isNotEmpty && _currentQuestionIndex < _questions.length)
          ? _questions[_currentQuestionIndex]
          : null;
  int get score => _score;
  bool get isPlaying => _isPlaying;
  bool get showExplanation => _showExplanation;
  int? get selectedOptionIndex => _selectedOptionIndex;
  bool get isAnswerCorrect => _isAnswerCorrect;
  int get elapsedMs => _stopwatch.elapsedMilliseconds;
  bool get isBattleCompleted =>
      _questions.isNotEmpty && _currentQuestionIndex >= _questions.length;

  String get elapsedFormatted {
    final seconds = _stopwatch.elapsed.inSeconds;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  /// Carrega la batalla del mes actual i el resultat de l'usuari
  Future<void> loadCurrentBattle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _battle = await _service.getCurrentBattle();

      // Si no existeix, la creem automàticament
      if (_battle == null) {
        await _service.createCurrentMonthBattle();
        _battle = await _service.getCurrentBattle();
      }

      if (_battle != null) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          _userResult =
              await _service.getUserResult(_battle!.yearMonth, uid);
        }
        // Carreguem el rànquing
        _ranking = await _service.getRanking(_battle!.yearMonth, limit: 50);
      }
    } catch (e) {
      _errorMessage = 'Error carregant la batalla: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Inicia la batalla: carrega preguntes i arrenca el cronòmetre
  Future<void> startBattle() async {
    if (_battle == null || hasPlayed) return;

    _isLoading = true;
    notifyListeners();

    try {
      _questions =
          await _service.loadBattleQuestions(_battle!.questionIds);

      if (_questions.isEmpty) {
        _errorMessage = 'No s\'han trobat les preguntes de la batalla.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _currentQuestionIndex = 0;
      _score = 0;
      _answers = [];
      _isPlaying = true;
      _showExplanation = false;
      _selectedOptionIndex = null;
      _isAnswerCorrect = false;

      // Iniciem cronòmetre global
      _stopwatch.reset();
      _stopwatch.start();
      _questionStartMs = 0;

      // Timer per actualitzar la UI cada segon
      _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = 'Error iniciant la batalla: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Respon la pregunta actual
  void answerQuestion(int optionIndex) {
    if (_showExplanation || isBattleCompleted || currentQuestion == null) return;

    _selectedOptionIndex = optionIndex;
    final question = currentQuestion!;

    _isAnswerCorrect = (question.correctOptionIndex == optionIndex);
    _showExplanation = true;

    if (_isAnswerCorrect) _score++;

    // Registrem la resposta amb el temps parcial
    final questionTimeMs = _stopwatch.elapsedMilliseconds - _questionStartMs;
    _answers.add(BattleAnswer(
      questionId: question.id,
      selectedIndex: optionIndex,
      correct: _isAnswerCorrect,
      timeMs: questionTimeMs,
    ));

    notifyListeners();
  }

  /// Avança a la següent pregunta o finalitza
  Future<void> nextQuestion() async {
    if (_currentQuestionIndex < _questions.length) {
      _currentQuestionIndex++;

      if (isBattleCompleted) {
        await _finishBattle();
      } else {
        _showExplanation = false;
        _selectedOptionIndex = null;
        _isAnswerCorrect = false;
        _questionStartMs = _stopwatch.elapsedMilliseconds;
      }
      notifyListeners();
    }
  }

  /// Finalitza la batalla: para timer, guarda resultat
  Future<void> _finishBattle() async {
    _stopwatch.stop();
    _uiTimer?.cancel();
    _isPlaying = false;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _battle == null) return;

    // Obtenim el nom de l'usuari des de Firestore
    String displayName = user.displayName ?? 'Àrbitre';

    final result = BattleResult(
      userId: user.uid,
      displayName: displayName,
      score: _score,
      totalTimeMs: _stopwatch.elapsedMilliseconds,
      answers: _answers,
      completedAt: DateTime.now(),
    );

    try {
      await _service.submitResult(_battle!.yearMonth, result);
      _userResult = result;
      // Recarreguem el rànquing
      _ranking = await _service.getRanking(_battle!.yearMonth, limit: 50);
    } catch (e) {
      _errorMessage = 'Error guardant el resultat: $e';
      debugPrint(_errorMessage);
    }

    notifyListeners();
  }

  /// Obté la posició de l'usuari al rànquing (1-indexed)
  int? getUserPosition() {
    if (_userResult == null) return null;
    final index = _ranking.indexWhere((r) => r.userId == _userResult!.userId);
    return index >= 0 ? index + 1 : null;
  }
}
