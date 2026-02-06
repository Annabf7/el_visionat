import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import '../providers/schedule_provider.dart';

/// Card compacta amb estadístiques setmanals
class WeeklySummaryCard extends StatelessWidget {
  const WeeklySummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (context, provider, child) {
        final summary = provider.getWeeklySummary();

        return Card(
          color: AppTheme.porpraFosc,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                  icon: Icons.check_circle_outline,
                  value: '${summary['done']}/${summary['total']}',
                  label: 'Completats',
                  color: AppTheme.verdeEncert,
                ),
                _SummaryItem(
                  icon: Icons.percent,
                  value: '${summary['percentage']}%',
                  label: 'Progrés',
                  color: AppTheme.mostassa,
                ),
                _SummaryItem(
                  icon: Icons.fitness_center,
                  value: '${summary['gymMinutes']}',
                  label: 'Min gimnàs',
                  color: AppTheme.lilaMitja,
                ),
                _SummaryItem(
                  icon: null,
                  emoji: '🐸',
                  value: '${summary['frogsCompleted']}/${summary['frogsTotal']}',
                  label: 'Granotes',
                  color: AppTheme.verdeEncert,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData? icon;
  final String? emoji;
  final String value;
  final String label;
  final Color color;

  const _SummaryItem({
    this.icon,
    this.emoji,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (emoji != null)
          Text(emoji!, style: const TextStyle(fontSize: 20))
        else if (icon != null)
          Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.grisPistacho.withValues(alpha: 0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
