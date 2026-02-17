import 'dart:async';
import 'package:flutter/material.dart';
import '../models/quiz_question.dart';
import '../services/question_service.dart';
import '../services/stats_service.dart';

class QuizProvider extends ChangeNotifier {
  final QuestionService _questionService = QuestionService();
  final StatsService _statsService = StatsService();

  List<QuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Estat de la pregunta actual
  bool _showExplanation = false;
  int? _selectedOptionIndex;
  bool _isAnswerCorrect = false;

  // Timer logic
  Timer? _timer;
  static const int _questionDuration = 60; // 60 segons per pregunta
  int _secondsLeft = _questionDuration;

  // Getters
  List<QuizQuestion> get questions => _questions;
  int get currentQuestionIndex => _currentQuestionIndex;
  QuizQuestion? get currentQuestion =>
      (_questions.isNotEmpty && _currentQuestionIndex < _questions.length)
      ? _questions[_currentQuestionIndex]
      : null;
  int get score => _score;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get showExplanation => _showExplanation;
  int? get selectedOptionIndex => _selectedOptionIndex;
  bool get isAnswerCorrect => _isAnswerCorrect;
  int get secondsLeft => _secondsLeft;

  bool get isQuizCompleted =>
      _questions.isNotEmpty && _currentQuestionIndex >= _questions.length;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // -- Inicialització --

  /// Inicia un nou quiz amb els filtres especificats
  Future<void> startQuiz({
    int limit = 10,
    String? source,
    int? articleNumber,
    bool retryFailed = false, // Opció per fer "més fallades"
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _questions = [];
    notifyListeners();

    try {
      if (retryFailed) {
        _questions = await _questionService.getMostFailedQuestions(
          limit: limit,
        );
      } else if (source != null || articleNumber != null) {
        _questions = await _questionService.getQuestionsByFilter(
          source: source,
          articleNumber: articleNumber,
          limit: limit,
        );
      } else {
        _questions = await _questionService.getMixedQuestions(limit: limit);
      }

      if (_questions.isEmpty) {
        _errorMessage = "No s'han trobat preguntes amb aquest criteri.";
      } else {
        _resetQuizState();
        _startTimer();
      }
    } catch (e) {
      _errorMessage = "Error carregant preguntes: $e";
      debugPrint("Quiz error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _resetQuizState() {
    _currentQuestionIndex = 0;
    _score = 0;
    _resetQuestionState();
  }

  void _resetQuestionState() {
    _showExplanation = false;
    _selectedOptionIndex = null;
    _isAnswerCorrect = false;
    _secondsLeft = _questionDuration;
  }

  // -- Lògica de Joc --

  void answerQuestion(int optionIndex) {
    if (_showExplanation || isQuizCompleted || currentQuestion == null) return;

    _timer?.cancel();
    _selectedOptionIndex = optionIndex;
    final question = currentQuestion!;

    _isAnswerCorrect = (question.correctOptionIndex == optionIndex);
    _showExplanation = true;

    if (_isAnswerCorrect) {
      _score++;
    }

    // Capturem errors silenciosament per no bloquejar l'UI
    _statsService
        .logAnswer(
          questionId: question.id,
          isCorrect: _isAnswerCorrect,
          articleNumber: question.articleNumber > 0
              ? question.articleNumber.toString()
              : null,
        )
        .catchError((e) => debugPrint("Error logging stats: $e"));

    notifyListeners();
  }

  void nextQuestion() {
    if (_currentQuestionIndex < _questions.length) {
      _currentQuestionIndex++;
      if (!isQuizCompleted) {
        _resetQuestionState();
        _startTimer();
      } else {
        _timer?.cancel();
      }
      notifyListeners();
    }
  }

  void restartQuiz() {
    _resetQuizState();
    if (_questions.isNotEmpty) {
      _startTimer();
    }
    notifyListeners();
  }

  // -- Mode Edició --

  /// Guarda noves opcions per a la pregunta actual directament a Firestore
  Future<void> saveEditorOptions(
    List<String> newOptions,
    int correctIndex,
  ) async {
    final q = currentQuestion;
    if (q == null) return;

    try {
      await _questionService.updateQuestionOptions(
        questionId: q.id,
        options: newOptions,
        correctIndex: correctIndex,
      );

      // Actualitzar l'estat localment també
      final updatedQ = _questions[_currentQuestionIndex].copyWith(
        options: newOptions,
        correctOptionIndex: correctIndex,
      );

      _questions[_currentQuestionIndex] = updatedQ;
      notifyListeners();
    } catch (e) {
      _errorMessage = "Error guardant opcions: $e";
      notifyListeners();
    }
  }

  // -- Timer --

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = _questionDuration;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        _secondsLeft--;
        notifyListeners();
      } else {
        _handleTimeout();
      }
    });
  }

  void _handleTimeout() {
    _timer?.cancel();
    // Temps esgotat: marquem com incorrecte (sense selecció) i mostrem explicació
    _showExplanation = true;
    _selectedOptionIndex = -1; // -1 indica temps esgotat/cap resposta
    _isAnswerCorrect = false;

    // Log timeout as incorrect
    if (currentQuestion != null) {
      _statsService
          .logAnswer(
            questionId: currentQuestion!.id,
            isCorrect: false,
            articleNumber: currentQuestion!.articleNumber > 0
                ? currentQuestion!.articleNumber.toString()
                : null,
          )
          .catchError((e) => debugPrint("Error logging stats: $e"));
    }

    notifyListeners();
  }
}
