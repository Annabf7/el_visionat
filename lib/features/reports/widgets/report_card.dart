import 'package:flutter/material.dart';
import 'package:el_visionat/core/models/referee_report.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

/// Card per mostrar un informe d'arbitratge
class ReportCard extends StatelessWidget {
  final RefereeReport report;
  final VoidCallback? onTap;

  const ReportCard({
    super.key,
    required this.report,
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
              // Header: Data i Valoració final
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
                        DateFormat('dd/MM/yyyy').format(report.date),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.grisBody,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                  _buildGradeBadge(context, report.finalGrade),
                ],
              ),
              const SizedBox(height: 12),

              // Competició
              Text(
                report.competition,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.grisBody,
                    ),
              ),
              const SizedBox(height: 4),

              // Equips
              Text(
                report.teams,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.porpraFosc,
                    ),
              ),
              const SizedBox(height: 12),

              // Informador
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppTheme.grisBody,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Informador: ${report.evaluator}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.grisBody,
                        ),
                  ),
                ],
              ),

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
                ...report.improvementPoints.take(2).map(
                      (point) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• ',
                              style: TextStyle(
                                color: AppTheme.grisBody,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                point.categoryName,
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
                if (report.improvementPoints.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${report.improvementPoints.length - 2} més...',
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

  Widget _buildGradeBadge(BuildContext context, AssessmentGrade grade) {
    Color backgroundColor;
    Color textColor;

    switch (grade) {
      case AssessmentGrade.optim:
        backgroundColor = const Color(0xFF50C878).withValues(alpha: 0.15);
        textColor = const Color(0xFF50C878);
        break;
      case AssessmentGrade.satisfactori:
        backgroundColor = AppTheme.lilaMitja.withValues(alpha: 0.15);
        textColor = AppTheme.lilaMitja;
        break;
      case AssessmentGrade.acceptable:
        backgroundColor = AppTheme.mostassa.withValues(alpha: 0.15);
        textColor = AppTheme.mostassa;
        break;
      case AssessmentGrade.millorable:
        backgroundColor = Colors.orange.withValues(alpha: 0.15);
        textColor = Colors.orange.shade700;
        break;
      case AssessmentGrade.noValorable:
        backgroundColor = AppTheme.grisPistacho.withValues(alpha: 0.15);
        textColor = AppTheme.grisBody;
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
