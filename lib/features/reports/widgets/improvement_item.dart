import 'package:flutter/material.dart';
import 'package:el_visionat/core/models/improvement_tracking.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Widget per mostrar un punt de millora recurrent
class ImprovementItem extends StatelessWidget {
  final CategoryImprovement improvement;

  const ImprovementItem({
    super.key,
    required this.improvement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.mostassa.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.mostassa.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  improvement.categoryName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.porpraFosc,
                      ),
                ),
              ),
              _buildOccurrenceBadge(context),
            ],
          ),
          const SizedBox(height: 8),
          if (improvement.descriptions.isNotEmpty) ...[
            ...improvement.descriptions.take(2).map(
                  (description) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.arrow_right,
                          size: 16,
                          color: AppTheme.grisBody,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            description,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.grisBody,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: AppTheme.grisBody,
              ),
              const SizedBox(width: 4),
              Text(
                'Última vegada: ${DateFormat('dd/MM/yyyy').format(improvement.lastOccurrence)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.grisBody,
                      fontSize: 11,
                    ),
              ),
              if (improvement.isImproving) ...[
                const Spacer(),
                Icon(
                  Icons.trending_down,
                  size: 14,
                  color: const Color(0xFF50C878),
                ),
                const SizedBox(width: 4),
                Text(
                  'Millorant',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF50C878),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOccurrenceBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.mostassa,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${improvement.occurrences}x',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
      ),
    );
  }
}

/// Widget per mostrar una àrea feble detectada en tests
class WeakAreaItem extends StatelessWidget {
  final WeakArea weakArea;

  const WeakAreaItem({
    super.key,
    required this.weakArea,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  weakArea.category,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.porpraFosc,
                      ),
                ),
              ),
              _buildErrorRateBadge(context),
            ],
          ),
          const SizedBox(height: 12),
          // Estadístiques
          Row(
            children: [
              _buildStat(
                context,
                label: 'Errors',
                value: '${weakArea.incorrectAnswers}/${weakArea.totalQuestions}',
                color: Colors.orange.shade700,
              ),
              const SizedBox(width: 16),
              _buildStat(
                context,
                label: 'Taxa d\'error',
                value: '${weakArea.errorRate.toStringAsFixed(0)}%',
                color: Colors.orange.shade700,
              ),
            ],
          ),
          if (weakArea.conflictiveTopics.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Temes conflictius:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.grisBody,
                  ),
            ),
            const SizedBox(height: 6),
            ...weakArea.conflictiveTopics.take(3).map(
                  (topic) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.arrow_right,
                          size: 16,
                          color: AppTheme.grisBody,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            topic,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.grisBody,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorRateBadge(BuildContext context) {
    final color = weakArea.errorRate >= 50
        ? Colors.red.shade700
        : Colors.orange.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.trending_down,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            '${weakArea.errorRate.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.grisBody,
                fontSize: 11,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }
}
