import 'package:flutter/material.dart';
import 'package:el_visionat/core/models/referee_test.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Card per mostrar un test teòric o físic
class TestCard extends StatelessWidget {
  final RefereeTest test;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TestCard({super.key, required this.test, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        color: AppTheme.grisPistacho,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('dd/MM/yyyy').format(test.date),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.grisPistacho,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildTestTypeBadge(context),
                      if (onDelete != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: AppTheme.mostassa,
                          ),
                          onPressed: () => _showDeleteDialog(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Nom del test
              Text(
                test.testName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.mostassa,
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
                      color: AppTheme.mostassa,
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
                      color: AppTheme.verdeEncert,
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
                      color: AppTheme.mostassa,
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
                      color: AppTheme.mostassa,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${test.conflictiveQuestions.length} pregunta${test.conflictiveQuestions.length > 1 ? 'es' : ''} conflictiva${test.conflictiveQuestions.length > 1 ? 'es' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mostassa,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...test.conflictiveQuestions
                    .take(2)
                    .map(
                      (question) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'P${question.questionNumber}. ',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppTheme.grisPistacho,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Expanded(
                              child: Text(
                                question.category,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppTheme.grisPistacho),
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
                        color: AppTheme.grisPistacho,
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

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar test'),
          content: Text(
            'Estàs segur que vols eliminar el test "${test.testName}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel·lar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDelete?.call();
              },
              style: TextButton.styleFrom(foregroundColor: AppTheme.mostassa),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTestTypeBadge(BuildContext context) {
    final isTheoretical = test.isTheoretical;
    final backgroundColor = isTheoretical
        ? AppTheme.mostassa.withValues(alpha: 0.15)
        : AppTheme.verdeEncert.withValues(alpha: 0.15);
    final textColor = isTheoretical
        ? AppTheme.mostassa
        : AppTheme.verdeEncert;

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
              color: AppTheme.grisPistacho,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
