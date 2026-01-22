import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:el_visionat/core/models/referee_test.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/core/widgets/global_header.dart';
import 'package:el_visionat/core/navigation/side_navigation_menu.dart';

/// Pàgina de detall d'un test teòric o físic
class TestDetailPage extends StatefulWidget {
  final RefereeTest test;
  final VoidCallback? onDelete;

  const TestDetailPage({
    super.key,
    required this.test,
    this.onDelete,
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

            // Totes les preguntes (sense secció conflictives separada)
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
                      : AppTheme.verdeEncert,
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
                                  color: AppTheme.grisPistacho,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.test.isTheoretical ? 'Test Teòric' : 'Test Físic',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.grisPistacho,
                            ),
                      ),
                    ],
                  ),
                ),
                if (widget.onDelete != null)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: AppTheme.mostassa,
                      size: 28,
                    ),
                    onPressed: () => _showDeleteDialog(context),
                    tooltip: 'Eliminar test',
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
          Icon(icon, size: 16, color: AppTheme.grisPistacho),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.grisPistacho,
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
                    color: AppTheme.grisPistacho,
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
                            color: AppTheme.grisPistacho,
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
                    color: AppTheme.verdeEncert,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.cancel_outlined,
                    label: 'Errors',
                    value: widget.test.incorrectAnswers.toString(),
                    color: AppTheme.mostassa,
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
                  color: AppTheme.grisPistacho,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllQuestions(BuildContext context) {
    // Separar preguntes incorrectes i correctes
    final incorrectQuestions =
        widget.test.allQuestions.where((q) => !q.isCorrect).toList();
    final correctQuestions =
        widget.test.allQuestions.where((q) => q.isCorrect).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preguntes INCORRECTES - Sempre expandides amb enunciat
            if (incorrectQuestions.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.cancel,
                    color: AppTheme.mostassa,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Preguntes Incorrectes (${incorrectQuestions.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.mostassa,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...incorrectQuestions.map(
                (question) => _buildExpandedIncorrectQuestion(context, question),
              ),
              const SizedBox(height: 32),
            ],

            // Preguntes CORRECTES - Graella estil calendari
            if (correctQuestions.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.verdeEncert,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Preguntes Correctes (${correctQuestions.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.verdeEncert,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Clica una pregunta per veure l\'enunciat',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.grisPistacho,
                    ),
              ),
              const SizedBox(height: 16),
              _buildCorrectQuestionsGrid(context, correctQuestions),
            ],
          ],
        ),
      ),
    );
  }

  /// Graella de preguntes correctes estil Google Calendar
  Widget _buildCorrectQuestionsGrid(
      BuildContext context, List<TestQuestion> questions) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: questions.map((question) {
        return InkWell(
          onTap: () => _showQuestionDialog(context, question),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.verdeEncert.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.verdeEncert.withValues(alpha: 0.4),
              ),
            ),
            child: Center(
              child: Text(
                '${question.questionNumber}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.verdeEncert,
                    ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Widget per preguntes INCORRECTES - Sempre expandides amb tota la informació
  Widget _buildExpandedIncorrectQuestion(
      BuildContext context, TestQuestion question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.mostassa.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.mostassa.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Capçalera amb número
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.mostassa,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${question.questionNumber}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pregunta ${question.questionNumber}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.grisPistacho,
                      ),
                ),
              ),
            ],
          ),

          // Text de la pregunta (enunciat)
          if (question.questionText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              question.questionText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.grisPistacho,
                  ),
            ),
          ],

          // Respostes: La teva vs Correcta
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.mostassa.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (question.userAnswer != null && question.userAnswer!.isNotEmpty) ...[
                  Text(
                    'La teva resposta:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.grisPistacho,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    question.userAnswer!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.mostassa,
                        ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  'Resposta correcta:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.grisPistacho,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  question.correctAnswer,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.verdeEncert,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Diàleg per mostrar la pregunta completa
  void _showQuestionDialog(BuildContext context, TestQuestion question) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.verdeEncert,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${question.questionNumber}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pregunta ${question.questionNumber}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.grisPistacho,
                      ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Text de la pregunta (enunciat)
                if (question.questionText.isNotEmpty) ...[
                  Text(
                    question.questionText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.grisPistacho,
                        ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Resposta correcta
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.verdeEncert.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.verdeEncert.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resposta correcta:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.grisPistacho,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        question.correctAnswer,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.verdeEncert,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Tancar',
                style: TextStyle(
                  color: AppTheme.grisPistacho,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar test'),
          content: Text(
            'Estàs segur que vols eliminar el test "${widget.test.testName}"?\n\nAquesta acció no es pot desfer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel·lar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tancar diàleg
                Navigator.of(context).pop(); // Tornar a la pàgina anterior
                widget.onDelete?.call();
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

  Color _getScoreColor(double score) {
    if (score >= 9.0) return AppTheme.verdeEncert; // Verd
    if (score >= 7.0) return AppTheme.lilaMitja; // Lila
    if (score >= 5.0) return AppTheme.mostassa; // Groc
    return AppTheme.mostassa; // Groc mostassa per notes baixes
  }
}
