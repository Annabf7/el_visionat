import 'package:flutter/material.dart';
import '../models/activity_model.dart';

/// Provider per gestionar l'estat i la lògica de les activitats autoavaluatives
class ActivityControllerProvider extends ChangeNotifier {
  /// Llista d'activitats disponibles
  final List<ActivityModel> activities;

  /// Índex de l'activitat seleccionada
  int selectedActivityIndex;

  /// Estat de les respostes: clau = "activityId_q{index}", valor = true/false/null
  final Map<String, bool?> answersState = {};

  /// Constructor
  ActivityControllerProvider({
    required this.activities,
    this.selectedActivityIndex = 0,
  });

  /// Retorna l'activitat seleccionada actualment
  ActivityModel get currentActivity => activities[selectedActivityIndex];

  /// Selecciona una activitat per índex
  void selectActivity(int index) {
    if (index < 0 || index >= activities.length) return;
    selectedActivityIndex = index;
    notifyListeners();
  }

  /// Verifica la resposta d'una pregunta i actualitza l'estat
  void checkAnswer(String activityId, int questionIndex, int answerIndex) {
    final activity = activities.firstWhere(
      (a) => a.id == activityId,
      orElse: () => currentActivity,
    );
    final isCorrect =
        activity.questions[questionIndex].respostaCorrectaIndex == answerIndex;
    answersState['${activityId}_q$questionIndex'] = isCorrect;
    notifyListeners();
  }

  /// Retorna l'estat de la resposta d'una pregunta (true/false/null)
  bool? getAnswerStatus(String activityId, int questionIndex) {
    return answersState['${activityId}_q$questionIndex'];
  }

  /// Reinicia totes les respostes d'una activitat
  void resetActivityAnswers(String activityId) {
    for (var i = 0; i < currentActivity.questions.length; i++) {
      answersState.remove('${activityId}_q$i');
    }
    notifyListeners();
  }
}
