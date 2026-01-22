import 'package:flutter/material.dart';
import 'package:el_visionat/core/models/referee_report.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Card per mostrar un informe d'arbitratge
class ReportCard extends StatelessWidget {
  final RefereeReport report;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ReportCard({
    super.key,
    required this.report,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
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
              // Header: Data i Valoració final
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
                        DateFormat('dd/MM/yyyy').format(report.date),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.grisPistacho,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildGradeBadge(context, report.finalGrade),
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

              // Competició
              Text(
                report.competition,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.grisPistacho,
                    ),
              ),
              const SizedBox(height: 4),

              // Equips
              Text(
                report.teams,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.mostassa,
                    ),
              ),
              const SizedBox(height: 12),

              // Informador
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppTheme.grisPistacho,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Informador: ${report.evaluator}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.grisPistacho,
                        ),
                  ),
                ],
              ),

              // Estadístiques de categories
              if (report.categories.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        icon: Icons.category,
                        label: 'Categories',
                        value: '${report.categories.length}',
                        color: AppTheme.mostassa,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        icon: Icons.check_circle_outline,
                        label: 'Òptims',
                        value: '${report.categories.where((c) => c.grade == AssessmentGrade.optim).length}',
                        color: AppTheme.verdeEncert,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        icon: Icons.trending_up,
                        label: 'Millorables',
                        value: '${report.categories.where((c) => c.grade == AssessmentGrade.millorable || c.grade == AssessmentGrade.acceptable).length}',
                        color: AppTheme.mostassa,
                      ),
                    ),
                  ],
                ),
              ],

              // Punts de millora (si n'hi ha)
              if (report.improvementPoints.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 16,
                      color: AppTheme.mostassa,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${report.improvementPoints.length} punt${report.improvementPoints.length > 1 ? 's' : ''} de millora',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.mostassa,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...report.improvementPoints.map(
                      (point) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• ',
                              style: TextStyle(
                                color: AppTheme.grisPistacho,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                point.categoryName,
                                style:
                                    Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.grisPistacho,
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
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar informe'),
          content: Text(
            'Estàs segur que vols eliminar l\'informe "${report.teams}"?',
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
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.mostassa,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
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

  Widget _buildGradeBadge(BuildContext context, AssessmentGrade grade) {
    Color backgroundColor;
    Color textColor;

    switch (grade) {
      case AssessmentGrade.optim:
        backgroundColor = AppTheme.verdeEncert.withValues(alpha: 0.15);
        textColor = AppTheme.verdeEncert;
        break;
      case AssessmentGrade.acceptable:
        backgroundColor = AppTheme.lilaMitja.withValues(alpha: 0.15);
        textColor = AppTheme.lilaMitja;
        break;
      case AssessmentGrade.millorable:
        backgroundColor = AppTheme.mostassa.withValues(alpha: 0.15);
        textColor = AppTheme.mostassa;
        break;
      case AssessmentGrade.noSatisfactori:
        backgroundColor = Colors.redAccent.withValues(alpha: 0.15);
        textColor = Colors.redAccent;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        grade.displayName,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
      ),
    );
  }
}
