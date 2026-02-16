import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'laboratori_section_card.dart';

class MonthlyBattleCard extends StatelessWidget {
  const MonthlyBattleCard({super.key});

  @override
  Widget build(BuildContext context) {
    return LaboratoriSectionCard(
      title: 'Batalla mensual de reglament',
      subtitle: '10 casos sorpresa + rànquing',
      icon: Icons.emoji_events,
      color: AppTheme.lilaMitja,
      textColor: AppTheme.porpraFosc,
      onTap: () {
        // TODO: Navegar a la pantalla de batalla mensual
        debugPrint('TODO: Navigate to Monthly Battle Page');
      },
    );
  }
}
