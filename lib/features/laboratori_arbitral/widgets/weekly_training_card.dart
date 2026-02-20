import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/features/laboratori_arbitral/pages/quiz_setup_page.dart';
import 'laboratori_section_card.dart';

class WeeklyTrainingCard extends StatelessWidget {
  const WeeklyTrainingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return LaboratoriSectionCard(
      title: 'Entrenament setmanal',
      subtitle: 'Casos curts + reflexió',
      badge: 'ACTIU',
      icon: Icons.calendar_today,
      color: AppTheme.porpraFosc,
      textColor: AppTheme.grisPistacho,
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const QuizSetupPage()));
      },
    );
  }
}
