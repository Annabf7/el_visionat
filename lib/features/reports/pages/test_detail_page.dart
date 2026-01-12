import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:el_visionat/core/models/referee_test.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/core/widgets/global_header.dart';
import 'package:el_visionat/core/navigation/side_navigation_menu.dart';

/// Pàgina de detall d'un test teòric o físic
class TestDetailPage extends StatefulWidget {
  final RefereeTest test;

  const TestDetailPage({
    super.key,
    required this.test,
  });

  @override
  State<TestDetailPage> createState() => _TestDetailPageState();
}

class _TestDetailPageState extends State<TestDetailPage> {
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
                        title: 'Detall del Test',
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
                  title: 'Detall del Test',
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

            // Resultats del test
            _buildResults(context),
            const SizedBox(height: 32),

            // Preguntes conflictives
            if (widget.test.conflictiveQuestions.isNotEmpty) ...[
              _buildConflictiveQuestions(context),
              const SizedBox(height: 32),
            ],

            // Totes les preguntes (opcional, amb collapse)
            if (widget.test.allQuestions.isNotEmpty) ...[
              _buildAllQuestions(context),
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
                  widget.test.isTheoretical
                      ? Icons.menu_book
                      : Icons.fitness_center,
                  size: 32,
                  color: widget.test.isTheoretical
                      ? AppTheme.lilaMitja
                      : const Color(0xFF50C878),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.test.testName,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.porpraFosc,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.test.isTheoretical ? 'Test Teòric' : 'Test Físic',
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
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _buildInfoChip(
                  context,
                  icon: Icons.calendar_today,
                  label: DateFormat('dd/MM/yyyy').format(widget.test.date),
                ),
                _buildInfoChip(
                  context,
                  icon: Icons.access_time,
                  label: '${widget.test.timeSpentMinutes} minuts',
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

  Widget _buildResults(BuildContext context) {
    final successRate = widget.test.successRate;
    final scoreColor = _getScoreColor(widget.test.score);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resultats',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            // Nota principal
            Center(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scoreColor.withValues(alpha: 0.15),
                  border: Border.all(
                    color: scoreColor,
                    width: 4,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.test.score.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                          ),
                    ),
                    Text(
                      '/ 10',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.grisBody,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Estadístiques
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.check_circle_outline,
                    label: 'Encerts',
                    value:
                        '${widget.test.correctAnswers}/${widget.test.totalQuestions}',
                    color: const Color(0xFF50C878),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.cancel_outlined,
                    label: 'Errors',
                    value: widget.test.incorrectAnswers.toString(),
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.percent,
                    label: 'Percentatge',
                    value: '${successRate.toStringAsFixed(1)}%',
                    color: AppTheme.lilaMitja,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.timer_outlined,
                    label: 'Temps',
                    value: '${widget.test.timeSpentMinutes}\'',
                    color: AppTheme.mostassa,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.grisBody,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictiveQuestions(BuildContext context) {
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
                  Icons.error_outline,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 12),
                Text(
                  'Preguntes Conflictives',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Aquestes són les preguntes on has tingut errors o dificultats',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.grisBody,
                  ),
            ),
            const SizedBox(height: 20),
            ...widget.test.conflictiveQuestions.map(
              (question) => _buildConflictiveQuestionItem(context, question),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConflictiveQuestionItem(
    BuildContext context,
    ConflictiveQuestion question,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'P${question.questionNumber}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question.category,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.porpraFosc,
                      ),
                ),
              ),
            ],
          ),
          if (question.explanation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              question.explanation,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.grisBody,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAllQuestions(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        leading: Icon(
          Icons.list_alt,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          'Totes les Preguntes (${widget.test.allQuestions.length})',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        children: [
          const SizedBox(height: 12),
          ...widget.test.allQuestions.map(
            (question) => _buildQuestionItem(context, question),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionItem(BuildContext context, TestQuestion question) {
    final isCorrect = question.isCorrect;
    final color = isCorrect ? const Color(0xFF50C878) : Colors.orange.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Pregunta ${question.questionNumber}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.porpraFosc,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question.category,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.grisBody,
                  fontStyle: FontStyle.italic,
                ),
          ),
          if (question.questionText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              question.questionText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.grisBody,
                  ),
            ),
          ],
          if (!isCorrect) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Resposta correcta: ',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.grisBody,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  question.correctAnswer,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF50C878),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 16),
                Text(
                  'La teva: ',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.grisBody,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  question.userAnswer ?? '-',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
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
