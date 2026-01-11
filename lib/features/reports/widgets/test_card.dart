import 'package:flutter/material.dart';
import 'package:el_visionat/core/models/referee_test.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Card per mostrar un test teòric o físic
class TestCard extends StatelessWidget {
  final RefereeTest test;
  final VoidCallback? onTap;

  const TestCard({
    super.key,
    required this.test,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Data i Tipus de test
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppTheme.grisBody,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('dd/MM/yyyy').format(test.date),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.grisBody,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                  _buildTestTypeBadge(context),
                ],
              ),
              const SizedBox(height: 12),

              // Nom del test
              Text(
                test.testName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.porpraFosc,
                    ),
              ),
              const SizedBox(height: 12),

              // Puntuació i estadístiques
              Row(
                children: [
                  // Nota
                  Expanded(
                    child: _buildStatItem(
                      context,
                      icon: Icons.grade,
                      label: 'Nota',
                      value: test.score.toStringAsFixed(1),
                      color: _getScoreColor(test.score),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Encerts
                  Expanded(
                    child: _buildStatItem(
                      context,
                      icon: Icons.check_circle_outline,
                      label: 'Encerts',
                      value: '${test.correctAnswers}/${test.totalQuestions}',
                      color: const Color(0xFF50C878),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Temps
                  Expanded(
                    child: _buildStatItem(
                      context,
                      icon: Icons.access_time,
                      label: 'Temps',
                      value: '${test.timeSpentMinutes}\'',
                      color: AppTheme.lilaMitja,
                    ),
                  ),
                ],
              ),

              // Preguntes conflictives (si n'hi ha)
              if (test.conflictiveQuestions.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${test.conflictiveQuestions.length} pregunta${test.conflictiveQuestions.length > 1 ? 'es' : ''} conflictiva${test.conflictiveQuestions.length > 1 ? 'es' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...test.conflictiveQuestions.take(2).map(
                      (question) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'P${question.questionNumber}. ',
                              style:
                                  Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.grisBody,
                                        fontWeight: FontWeight.bold,
                                      ),
                            ),
                            Expanded(
                              child: Text(
                                question.category,
                                style:
                                    Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.grisBody,
                                        ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                if (test.conflictiveQuestions.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${test.conflictiveQuestions.length - 2} més...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.grisBody,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestTypeBadge(BuildContext context) {
    final isTheoretical = test.isTheoretical;
    final backgroundColor = isTheoretical
        ? AppTheme.lilaMitja.withValues(alpha: 0.15)
        : const Color(0xFF50C878).withValues(alpha: 0.15);
    final textColor = isTheoretical
        ? AppTheme.lilaMitja
        : const Color(0xFF50C878);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isTheoretical ? Icons.menu_book : Icons.fitness_center,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            isTheoretical ? 'Teòric' : 'Físic',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.grisBody,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 9.0) return const Color(0xFF50C878); // Verd
    if (score >= 7.0) return AppTheme.lilaMitja; // Lila
    if (score >= 5.0) return AppTheme.mostassa; // Groc
    return Colors.orange.shade700; // Taronja
  }
}
