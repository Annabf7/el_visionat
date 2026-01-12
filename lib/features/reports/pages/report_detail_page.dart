import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:el_visionat/core/models/referee_report.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/core/widgets/global_header.dart';
import 'package:el_visionat/core/navigation/side_navigation_menu.dart';

/// Pàgina de detall d'un informe d'arbitratge
class ReportDetailPage extends StatefulWidget {
  final RefereeReport report;

  const ReportDetailPage({
    super.key,
    required this.report,
  });

  @override
  State<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 900;

        if (isLargeScreen) {
          return Scaffold(
            key: _scaffoldKey,
            body: Row(
              children: [
                SizedBox(
                  width: 288,
                  height: double.infinity,
                  child: const SideNavigationMenu(),
                ),
                Expanded(
                  child: Column(
                    children: [
                      GlobalHeader(
                        scaffoldKey: _scaffoldKey,
                        title: 'Detall de l\'Informe',
                        showMenuButton: false,
                      ),
                      Expanded(
                        child: _buildContent(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            key: _scaffoldKey,
            drawer: const SideNavigationMenu(),
            body: Column(
              children: [
                GlobalHeader(
                  scaffoldKey: _scaffoldKey,
                  title: 'Detall de l\'Informe',
                  showMenuButton: true,
                ),
                Expanded(
                  child: _buildContent(context),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header amb informació general
            _buildHeader(context),
            const SizedBox(height: 32),

            // Valoració final
            _buildFinalGrade(context),
            const SizedBox(height: 32),

            // Categories avaluades
            _buildCategories(context),
            const SizedBox(height: 32),

            // Punts de millora
            if (widget.report.improvementPoints.isNotEmpty) ...[
              _buildImprovementPoints(context),
              const SizedBox(height: 32),
            ],

            // Comentaris generals
            if (widget.report.comments.isNotEmpty) ...[
              _buildComments(context),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.report.teams,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.porpraFosc,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.report.competition,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.grisBody,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip(
                  context,
                  icon: Icons.calendar_today,
                  label: DateFormat('dd/MM/yyyy').format(widget.report.date),
                ),
                const SizedBox(width: 16),
                _buildInfoChip(
                  context,
                  icon: Icons.person_outline,
                  label: widget.report.evaluator,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.grisPistacho.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.grisBody),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.grisBody,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalGrade(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Valoració Final',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: _getGradeColor(widget.report.finalGrade)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _getGradeColor(widget.report.finalGrade),
                    width: 2,
                  ),
                ),
                child: Text(
                  widget.report.finalGrade.displayName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getGradeColor(widget.report.finalGrade),
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.checklist_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Categories Avaluades',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...widget.report.categories.map(
              (category) => _buildCategoryItem(context, category),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    AssessmentCategory category,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getGradeColor(category.grade).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getGradeColor(category.grade).withValues(alpha: 0.3),
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
                  category.categoryName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.porpraFosc,
                      ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getGradeColor(category.grade),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  category.grade.displayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          if (category.description != null && category.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              category.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.grisBody,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImprovementPoints(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: AppTheme.mostassa,
                ),
                const SizedBox(width: 12),
                Text(
                  'Punts de Millora Identificats',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...widget.report.improvementPoints.map(
              (point) => _buildImprovementPointItem(context, point),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImprovementPointItem(
    BuildContext context,
    ImprovementPoint point,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.mostassa.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.mostassa.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            point.categoryName,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.porpraFosc,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            point.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.grisBody,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildComments(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.comment_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Comentaris Generals',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.grisPistacho.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.report.comments,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.grisBody,
                      height: 1.6,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(AssessmentGrade grade) {
    switch (grade) {
      case AssessmentGrade.optim:
        return const Color(0xFF50C878); // Verd
      case AssessmentGrade.satisfactori:
        return AppTheme.lilaMitja; // Lila
      case AssessmentGrade.acceptable:
        return AppTheme.mostassa; // Groc
      case AssessmentGrade.millorable:
        return Colors.orange.shade700; // Taronja
      case AssessmentGrade.noValorable:
        return AppTheme.grisBody; // Gris
    }
  }
}
