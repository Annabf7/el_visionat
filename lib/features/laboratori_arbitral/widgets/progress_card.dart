import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'laboratori_section_card.dart';

class ProgressCard extends StatelessWidget {
  const ProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    return LaboratoriSectionCard(
      title: 'El meu progrés',
      subtitle: 'Puntuació i evolució',
      icon: Icons.show_chart,
      color: AppTheme.mostassa,
      textColor: AppTheme.porpraFosc,
      onTap: () {
        // TODO: Navegar a la pantalla de progrés
        debugPrint('TODO: Navigate to Progress Page');
      },
    );
  }
}
