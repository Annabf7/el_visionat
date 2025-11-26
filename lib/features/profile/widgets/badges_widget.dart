import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

/// Widget que mostra els badges/assoliments de l'usuari
class BadgesWidget extends StatelessWidget {
  const BadgesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBadgeCard(
          '10 VISIONATS',
          'Primer objectiu assolit. Bona constància.',
          AppTheme.mostassa,
          'V',
        ),
        const SizedBox(height: 12),
        _buildBadgeCard(
          '50 APUNTS PERSONALS',
          'La teva dedicació és extraordinària.',
          AppTheme.lilaMitja,
          '✏',
        ),
        const SizedBox(height: 12),
        _buildBadgeCard(
          '1 MES DE RUTINA SETMANAL',
          'Excel·lent compromís i esforç.',
          Colors.orange,
          '🔥',
        ),
      ],
    );
  }

  Widget _buildBadgeCard(
    String title,
    String description,
    Color color,
    String icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(
                  color: AppTheme.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.grisBody,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
