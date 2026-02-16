import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'laboratori_section_card.dart';

class WeeklyTrainingCard extends StatelessWidget {
  const WeeklyTrainingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return LaboratoriSectionCard(
      title: 'Entrenament setmanal',
      subtitle: 'Casos curts + reflexió',
      icon: Icons.calendar_today,
      color: AppTheme.porpraFosc.withValues(alpha: 0.95),
      onTap: () {
        // TODO: Navegar a la pantalla de entrenament setmanal
        debugPrint('TODO: Navigate to Weekly Training Page');
      },
    );
  }
}
