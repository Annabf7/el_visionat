import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weekly_match_provider.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

/// Card que mostra els detalls del partit de la setmana
/// Llegeix les dades de WeeklyMatchProvider
class MatchDetailsCard extends StatelessWidget {
  const MatchDetailsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeeklyMatchProvider>(
      builder: (context, provider, child) {
        return Container(
          constraints: const BoxConstraints(minHeight: 260),
          decoration: BoxDecoration(
            color: AppTheme.porpraFosc,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.porpraFosc.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detalls del Partit',
                style: TextStyle(
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
                value: provider.refereeName,
              ),
              _buildDivider(),
              _buildDetailRow(
                icon: Icons.emoji_events,
                label: 'Competició',
                value: provider.league,
              ),
              _buildDivider(),
              _buildDetailRow(
                icon: Icons.calendar_month,
                label: 'Jornada',
                value: provider.matchday.toString(),
              ),
              if (provider.location != null &&
                  provider.location!.isNotEmpty) ...[
                _buildDivider(),
                _buildDetailRow(
                  icon: Icons.location_on,
                  label: 'Pavelló',
                  value: provider.location!,
                ),
              ],
            ],
          ),
        );
      },
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
