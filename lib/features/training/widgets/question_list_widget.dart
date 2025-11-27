import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question_model.dart';
import '../providers/activity_controller.dart';
import 'activity_video_player.dart';

/// Widget QuestionListWidget
/// Mostra la llista de preguntes amb opcions interactives i feedback instantani.
class QuestionListWidget extends StatelessWidget {
  final List<QuestionModel> questions;
  final String activityId;
  const QuestionListWidget({
    super.key,
    required this.questions,
    required this.activityId,
  });

  @override
  Widget build(BuildContext context) {
    // Obtenim el youtubeVideoId de l'activitat principal (si existeix)
    final activityController = Provider.of<ActivityControllerProvider>(
      context,
      listen: false,
    );
    String? mainVideoId;
    try {
      final activity = activityController.activities.firstWhere(
        (a) => a.id == activityId,
      );
      mainVideoId = activity.youtubeVideoId;
    } catch (_) {
      mainVideoId = null;
    }
    return Column(
      children: [
        for (int qIndex = 0; qIndex < questions.length; qIndex++) ...[
          if (qIndex > 0) const SizedBox(height: 16),
          _QuestionCard(
            question: questions[qIndex],
            activityId: activityId,
            qIndex: qIndex,
            mainVideoId: mainVideoId,
          ),
        ],
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final QuestionModel question;
  final String activityId;
  final int qIndex;
  final String? mainVideoId;
  const _QuestionCard({
    required this.question,
    required this.activityId,
    required this.qIndex,
    this.mainVideoId,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ActivityControllerProvider>(context);
    final answerStatus = controller.getAnswerStatus(activityId, qIndex);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (question.youtubeVideoId != null &&
                question.youtubeVideoId != mainVideoId)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: SizedBox(
                  height: 180,
                  child: ActivityVideoPlayer(videoId: question.youtubeVideoId!),
                ),
              ),
            Text(
              'Q${qIndex + 1}: ${question.enunciat}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...List.generate(question.opcions.length, (oIndex) {
              final isAnswered = answerStatus != null;
              final isSelected =
                  isAnswered && question.respostaCorrectaIndex == oIndex;
              Color? color;
              if (isAnswered) {
                if (question.respostaCorrectaIndex == oIndex &&
                    answerStatus == true) {
                  color = Colors.green[100];
                } else if (answerStatus == false &&
                    oIndex == question.respostaCorrectaIndex) {
                  color = Colors.green[50];
                } else if (answerStatus == false &&
                    oIndex != question.respostaCorrectaIndex) {
                  color = Colors.red[50];
                }
              }
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: isSelected ? 2 : 0,
                  ),
                  onPressed: isAnswered
                      ? null
                      : () =>
                            controller.checkAnswer(activityId, qIndex, oIndex),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      question.opcions[oIndex],
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isAnswered
                            ? (question.respostaCorrectaIndex == oIndex
                                  ? Colors.green[900]
                                  : Colors.red[900])
                            : Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            }),
            if (answerStatus != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  answerStatus == true ? 'Correcte!' : 'Incorrecte',
                  style: TextStyle(
                    color: answerStatus == true
                        ? Colors.green[800]
                        : Colors.red[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
