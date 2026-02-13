import 'package:flutter/material.dart';
import 'package:el_visionat/core/models/improvement_tracking.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Widget per mostrar un punt de millora recurrent (tema fosc, estil NeuroVisionat)
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppTheme.mostassa,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        improvement.categoryName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildOccurrenceBadge(),
            ],
          ),
          if (improvement.descriptions.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...improvement.descriptions.take(2).map(
                  (description) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 14),
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppTheme.grisPistacho.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            description,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 13,
                color: AppTheme.grisPistacho.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                'Última: ${DateFormat('dd/MM/yyyy').format(improvement.lastOccurrence)}',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.grisPistacho.withValues(alpha: 0.6),
                ),
              ),
              if (improvement.isImproving) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.verdeEncert.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.verdeEncert.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.trending_down_rounded,
                        size: 13,
                        color: AppTheme.verdeEncert,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Millorant',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.verdeEncert,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOccurrenceBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.mostassa.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.mostassa.withValues(alpha: 0.15),
        ),
      ),
      child: Text(
        '${improvement.occurrences}x',
        style: TextStyle(
          color: AppTheme.mostassa,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Widget per mostrar una àrea feble detectada en tests (tema fosc, estil NeuroVisionat)
class WeakAreaItem extends StatelessWidget {
  final WeakArea weakArea;

  const WeakAreaItem({
    super.key,
    required this.weakArea,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor =
        weakArea.errorRate >= 50 ? Colors.redAccent : AppTheme.mostassa;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        weakArea.category,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildErrorRateBadge(badgeColor),
            ],
          ),
          const SizedBox(height: 12),
          // Estadístiques en una fila
          Row(
            children: [
              const SizedBox(width: 14),
              _buildStat(
                label: 'Errors',
                value: '${weakArea.incorrectAnswers}/${weakArea.totalQuestions}',
                color: AppTheme.grisPistacho.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 24),
              _buildStat(
                label: 'Taxa d\'error',
                value: '${weakArea.errorRate.toStringAsFixed(0)}%',
                color: badgeColor,
              ),
            ],
          ),
          if (weakArea.conflictiveTopics.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: AppTheme.grisPistacho.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.mostassa.withValues(alpha: 0.6),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Temes conflictius',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.grisPistacho.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...weakArea.conflictiveTopics.take(3).map(
                  (topic) => Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppTheme.grisPistacho.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            topic,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                              height: 1.4,
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

  Widget _buildErrorRateBadge(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.trending_down_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${weakArea.errorRate.toStringAsFixed(0)}%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.grisPistacho.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
