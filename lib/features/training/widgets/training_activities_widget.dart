import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/activity_controller.dart';
import 'activity_tab_selector.dart';
import 'activity_video_player.dart';
import 'question_list_widget.dart';

/// 🧠 Widget principal: TrainingActivitiesWidget
///
/// Mostra pestanyes, vídeo (si n'hi ha) i preguntes autoavaluatives.
class TrainingActivitiesWidget extends StatelessWidget {
  const TrainingActivitiesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityControllerProvider>(
      builder: (context, controller, _) {
        final activity = controller.currentActivity;
        return DefaultTabController(
          length: controller.activities.length,
          initialIndex: controller.selectedActivityIndex,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ActivityTabSelector(),
              if (activity.youtubeVideoId != null &&
                  activity.youtubeVideoId!.isNotEmpty)
                ActivityVideoPlayer(videoId: activity.youtubeVideoId!),
              // Remove Expanded: let QuestionListWidget size naturally
              QuestionListWidget(
                questions: activity.questions,
                activityId: activity.id,
              ),
            ],
          ),
        );
      },
    );
  }
}
