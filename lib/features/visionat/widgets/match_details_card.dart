import 'package:flutter/material.dart';
import '../models/match_models.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

class MatchDetailsCard extends StatelessWidget {
  final MatchDetails details;

  const MatchDetailsCard({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 260),
      decoration: BoxDecoration(
        color: AppTheme.porpraFosc, // Canvi: fons més fosc per contrast
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.porpraFosc.withValues(
              alpha: 0.3,
            ), // Ombra més marcada
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalls del Partit',
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.grisPistacho,
            ),
          ),
          const SizedBox(height: 20),
          _buildDetailRow(
            icon: Icons.sports_basketball,
            label: 'Àrbitre',
            value: details.refereeName,
          ),
          _buildDivider(),
          _buildDetailRow(
            icon: Icons.emoji_events,
            label: 'Lliga',
            value: details.league,
          ),
          _buildDivider(),
          _buildDetailRow(
            icon: Icons.calendar_month,
            label: 'Jornada',
            value: details.matchday.toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.grisBody.withValues(
                alpha: 0.8,
              ), // Fons més subtil
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppTheme.mostassa),
          ),
          const SizedBox(width: 16),
          // Label and Value
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.grisPistacho,
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        height: 0.5,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.grisPistacho.withValues(alpha: 0.0),
              AppTheme.grisPistacho.withValues(alpha: 0.3),
              AppTheme.grisPistacho.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}
