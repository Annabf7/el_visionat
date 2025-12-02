import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question_model.dart';
import '../providers/activity_controller.dart';
import 'activity_video_player.dart';
import '../../../core/theme/app_theme.dart';

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
                  child: ActivityVideoPlayer(
                    key: Key('video_${question.youtubeVideoId!}'),
                    videoId: question.youtubeVideoId!,
                  ),
                ),
              ),
            Text(
              'Q${qIndex + 1}: ${question.enunciat}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...List.generate(question.opcions.length, (oIndex) {
              final isAnswered = answerStatus != null;
              final selectedIndex = controller.getSelectedAnswer(
                activityId,
                qIndex,
              );

              // If not answered, all borders are mostassa
              // If answered and correct, only correct option is green
              // If answered and incorrect, only selected option is red
              bool isSelected = false;
              if (isAnswered) {
                if (answerStatus == true) {
                  isSelected = question.respostaCorrectaIndex == oIndex;
                } else {
                  // Find which option was tapped (incorrect)
                  isSelected = selectedIndex == oIndex;
                }
              }
              Color borderColor = AppTheme.mostassa;
              if (isAnswered && isSelected) {
                borderColor = answerStatus == true
                    ? Colors.green[700]!
                    : Colors.red[700]!;
              }
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.ease,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: AppTheme.mostassa,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                  ),
                  onPressed: isAnswered
                      ? null
                      : () =>
                            controller.checkAnswer(activityId, qIndex, oIndex),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      question.opcions[oIndex],
                      style: const TextStyle(
                        fontWeight: FontWeight.normal,
                        color: AppTheme.mostassa,
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
                  answerStatus == true ? 'Correcte' : 'Incorrecte',
                  style: TextStyle(
                    color: answerStatus == true
                        ? Colors.green[700]
                        : Colors.red[700],
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
