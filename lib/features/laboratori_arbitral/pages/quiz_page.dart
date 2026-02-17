import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/core/widgets/global_header.dart';
import 'package:el_visionat/core/navigation/side_navigation_menu.dart';
import '../models/quiz_question.dart';
import '../providers/quiz_provider.dart';

class QuizPage extends StatefulWidget {
  final int limit;
  final String? source;
  final int? articleNumber;
  final bool retryFailed;
  final String? gender;

  const QuizPage({
    super.key,
    this.limit = 10,
    this.source,
    this.articleNumber,
    this.retryFailed = false,
    this.gender,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const String _bgMan =
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/EL%20laboratori%20arbitral%2Fbackground_manQuiz.webp?alt=media&token=5a3fe7f8-e43b-4708-9eea-4ae7e13639c0';
  static const String _bgWoman =
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/EL%20laboratori%20arbitral%2Fbackground_womenQuiz.webp?alt=media&token=ef55e3f1-7432-48ec-bd0e-02f05743a09b';

  String get _backgroundUrl => widget.gender == 'male' ? _bgMan : _bgWoman;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QuizProvider()
        ..startQuiz(
          limit: widget.limit,
          source: widget.source,
          articleNumber: widget.articleNumber,
          retryFailed: widget.retryFailed,
        ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 900;

          if (isLargeScreen) {
            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      _backgroundUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: AppTheme.grisBody),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      color: AppTheme.grisBody.withValues(alpha: 0.35),
                    ),
                  ),
                  Row(
                    children: [
                      const SizedBox(
                        width: 288,
                        height: double.infinity,
                        child: SideNavigationMenu(),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            GlobalHeader(
                              scaffoldKey: _scaffoldKey,
                              title: 'Entrenament Setmanal',
                              showMenuButton: false,
                            ),
                            Expanded(child: _buildQuizContent(context)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          } else {
            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: Colors.black,
              drawer: const SideNavigationMenu(),
              body: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      _backgroundUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: AppTheme.grisBody),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      color: AppTheme.grisBody.withValues(alpha: 0.55),
                    ),
                  ),
                  Column(
                    children: [
                      GlobalHeader(
                        scaffoldKey: _scaffoldKey,
                        title: 'Entrenament Setmanal',
                        showMenuButton: true,
                      ),
                      Expanded(child: _buildQuizContent(context)),
                    ],
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildQuizContent(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.mostassa),
          );
        }

        if (provider.errorMessage != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                provider.errorMessage!,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 16,
                  color: AppTheme.mostassa,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (provider.questions.isEmpty) {
          return Center(
            child: Text(
              "No s'han trobat preguntes.",
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 16,
                color: AppTheme.grisPistacho,
              ),
            ),
          );
        }

        if (provider.isQuizCompleted) {
          return _QuizResultView(provider: provider);
        }

        final question = provider.currentQuestion!;
        final isCorrect =
            provider.selectedOptionIndex == question.correctOptionIndex;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Capçalera: tornar + indicador de progrés
                  Row(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => Navigator.of(context).pop(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.arrow_back_ios_rounded,
                                  size: 16,
                                  color: AppTheme.mostassa,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Tornar',
                                  style: TextStyle(
                                    fontFamily: 'Geist',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.mostassa,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Step dots de progrés
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(provider.questions.length, (i) {
                          final isCurrent = i == provider.currentQuestionIndex;
                          final isDone = i < provider.currentQuestionIndex;
                          return Container(
                            width: isCurrent ? 24 : 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: isCurrent
                                  ? AppTheme.mostassa
                                  : isDone
                                  ? AppTheme.verdeEncert
                                  : AppTheme.white.withValues(alpha: 0.15),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Targeta de pregunta amb gradient
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.porpraFosc,
                          AppTheme.porpraFosc.withValues(alpha: 0.85),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.porpraFosc.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          // Cercle decoratiu de fons
                          Positioned(
                            top: -30,
                            right: -30,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.mostassa.withValues(
                                  alpha: 0.06,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Capçalera: badges + timer circular
                                Row(
                                  children: [
                                    // Badge Source / Article
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.mostassa.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        question.articleNumber > 0
                                            ? 'ART. ${question.articleNumber} - ${question.source.toUpperCase()}'
                                            : question.category.name
                                                  .toUpperCase(),
                                        style: TextStyle(
                                          fontFamily: 'Geist',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.2,
                                          color: AppTheme.mostassa.withValues(
                                            alpha: 0.8,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Badge número de pregunta
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.white.withValues(
                                          alpha: 0.06,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${provider.currentQuestionIndex + 1} / ${provider.questions.length}',
                                        style: TextStyle(
                                          fontFamily: 'Geist',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                          color: AppTheme.grisPistacho
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    // Timer circular
                                    _CircularTimer(
                                      secondsLeft: provider.secondsLeft,
                                      totalSeconds: 60,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Barra accent mostassa
                                Container(
                                  width: 40,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: AppTheme.mostassa.withValues(
                                      alpha: 0.4,
                                    ),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Text de la pregunta
                                Text(
                                  question.question,
                                  style: TextStyle(
                                    fontFamily: 'Geist',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.white,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Si només hi ha 1 opció (mode incomplet), mostrem UI d'edició
                  if (question.options.length <= 1)
                    _QuestionEditor(
                      question: question,
                      onSave: (options, correctIndex) {
                        provider.saveEditorOptions(options, correctIndex);
                      },
                    )
                  else
                    // Opcions de resposta normals
                    ...List.generate(question.options.length, (index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < question.options.length - 1 ? 12 : 0,
                        ),
                        child: _QuizOptionCard(
                          letter: String.fromCharCode(65 + index),
                          text: question.options[index],
                          isSelected: provider.selectedOptionIndex == index,
                          isCorrect: index == question.correctOptionIndex,
                          showResult: provider.showExplanation,
                          onTap: () {
                            if (!provider.showExplanation) {
                              provider.answerQuestion(index);
                            }
                          },
                        ),
                      );
                    }),

                  // Explicació i botó següent
                  if (provider.showExplanation ||
                      question.options.length <= 1) ...[
                    const SizedBox(height: 24),
                    _ExplanationCard(
                      isCorrect: isCorrect,
                      isTimeout: provider.selectedOptionIndex == -1,
                      explanation: question.explanation,
                      reference: question.articleNumber > 0
                          ? 'Art. ${question.articleNumber} - ${question.articleTitle}'
                          : question.reference,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => provider.nextQuestion(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.mostassa,
                          foregroundColor: AppTheme.porpraFosc,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          provider.currentQuestionIndex <
                                  provider.questions.length - 1
                              ? 'Següent pregunta'
                              : 'Veure resultats',
                          style: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Widget per editar preguntes incompletes "on the fly"
class _QuestionEditor extends StatefulWidget {
  final QuizQuestion question;
  final Function(List<String> options, int correctIndex) onSave;

  const _QuestionEditor({required this.question, required this.onSave});

  @override
  State<_QuestionEditor> createState() => _QuestionEditorState();
}

class _QuestionEditorState extends State<_QuestionEditor> {
  // Use a map or list to store controllers, but must initialize them based on widget.question
  // To avoid LateInitializationError or recreation issues, better initialize in initState.
  final List<TextEditingController> _controllers = [];
  int _correctIndex = 0;

  @override
  void initState() {
    super.initState();
    _correctIndex = widget.question.correctOptionIndex;

    // Create 4 controllers.
    // Index 0 -> Option A
    // Index 1 -> Option B etc.
    // If the question already has an answer in options[0], we put it in the Correct Index controller

    // Logic:
    // If question.options.length == 1 (The imported answer), we put that text into the CORRESPONDING controller based on correctIndex
    // For now, let's assume if there's only 1 option, it IS the correct answer.
    // So we put that text into controller[_correctIndex].

    for (int i = 0; i < 4; i++) {
      String initialText = '';

      // If this index is the correct one, and we have at least one option (the imported answer)
      if (i == _correctIndex && widget.question.options.isNotEmpty) {
        initialText = widget.question.options[0];
      } else if (i < widget.question.options.length &&
          widget.question.options.length > 1) {
        // If we are editing an already full question (futureproofing)
        initialText = widget.question.options[i];
      }

      _controllers.add(TextEditingController(text: initialText));
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final options = _controllers.map((c) => c.text.trim()).toList();

    // Check if at least 2 options are filled to make it a valid quiz question?
    // User requested to fill distractors.

    if (options.any((o) => o.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Omple totes les 4 opcions per completar la pregunta.'),
        ),
      );
      return;
    }

    widget.onSave(options, _correctIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.porpraFosc,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.mostassa.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, color: AppTheme.mostassa),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mode Edició: Afegeix les opcions que falten',
                  style: TextStyle(
                    color: AppTheme.mostassa,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // We assume 4 options always for now
          // Manually generating widgets since list generator inside Column can be weird if not spread
          _OptionInputRow(
            index: 0,
            controller: _controllers[0],
            isCorrect: _correctIndex == 0,
            onCorrectChanged: (val) {
              if (val != null) setState(() => _correctIndex = val);
            },
          ),
          _OptionInputRow(
            index: 1,
            controller: _controllers[1],
            isCorrect: _correctIndex == 1,
            onCorrectChanged: (val) {
              if (val != null) setState(() => _correctIndex = val);
            },
          ),
          _OptionInputRow(
            index: 2,
            controller: _controllers[2],
            isCorrect: _correctIndex == 2,
            onCorrectChanged: (val) {
              if (val != null) setState(() => _correctIndex = val);
            },
          ),
          _OptionInputRow(
            index: 3,
            controller: _controllers[3],
            isCorrect: _correctIndex == 3,
            onCorrectChanged: (val) {
              if (val != null) setState(() => _correctIndex = val);
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _save(),
            icon: const Icon(Icons.save_as_rounded),
            label: const Text('GUARDAR PREGUNTA'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.verdeEncert,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionInputRow extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final bool isCorrect;
  final ValueChanged<int?> onCorrectChanged;

  const _OptionInputRow({
    required this.index,
    required this.controller,
    required this.isCorrect,
    required this.onCorrectChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Align to top for multiline
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Radio<int>(
              value: index,
              groupValue: isCorrect ? index : null, // Trick to show selected
              activeColor: AppTheme.verdeEncert,
              fillColor: WidgetStateProperty.resolveWith(
                (states) =>
                    isCorrect ? AppTheme.verdeEncert : AppTheme.grisPistacho,
              ),
              onChanged: (val) => onCorrectChanged(index),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null, // Allow multiline
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText:
                    'Opció ${String.fromCharCode(65 + index)} ${isCorrect ? "(Correcta)" : ""}',
                labelStyle: TextStyle(
                  color: isCorrect
                      ? AppTheme.verdeEncert
                      : AppTheme.grisPistacho.withValues(alpha: 0.7),
                  fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isCorrect
                        ? AppTheme.verdeEncert.withValues(alpha: 0.5)
                        : AppTheme.white.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.mostassa),
                ),
                filled: true,
                fillColor: AppTheme.white.withValues(alpha: 0.05),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Timer circular amb anell de progrés
class _CircularTimer extends StatelessWidget {
  final int secondsLeft;
  final int totalSeconds;

  const _CircularTimer({required this.secondsLeft, required this.totalSeconds});

  @override
  Widget build(BuildContext context) {
    final progress = secondsLeft / totalSeconds;
    final isLow = secondsLeft < 10;
    final color = isLow ? Colors.redAccent : AppTheme.mostassa;

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            color: color,
            backgroundColor: AppTheme.white.withValues(alpha: 0.08),
            strokeCap: StrokeCap.round,
          ),
          Center(
            child: Text(
              '$secondsLeft',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Targeta d'opció amb lletra, animació i indicador de resultat
class _QuizOptionCard extends StatelessWidget {
  final String letter;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool showResult;
  final VoidCallback onTap;

  const _QuizOptionCard({
    required this.letter,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.showResult,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color letterBgColor;
    Color letterColor;
    Color textColor = AppTheme.white.withValues(alpha: 0.9);

    if (showResult) {
      if (isCorrect) {
        bgColor = AppTheme.verdeEncert.withValues(alpha: 0.15);
        borderColor = AppTheme.verdeEncert;
        letterBgColor = AppTheme.verdeEncert;
        letterColor = Colors.white;
      } else if (isSelected) {
        bgColor = Colors.redAccent.withValues(alpha: 0.15);
        borderColor = Colors.redAccent;
        letterBgColor = Colors.redAccent;
        letterColor = Colors.white;
      } else {
        bgColor = AppTheme.white.withValues(alpha: 0.03);
        borderColor = AppTheme.white.withValues(alpha: 0.08);
        letterBgColor = AppTheme.white.withValues(alpha: 0.06);
        letterColor = AppTheme.grisPistacho.withValues(alpha: 0.4);
        textColor = AppTheme.grisPistacho.withValues(alpha: 0.4);
      }
    } else {
      bgColor = AppTheme.white.withValues(alpha: 0.04);
      borderColor = AppTheme.mostassa.withValues(alpha: 0.25);
      letterBgColor = AppTheme.mostassa.withValues(alpha: 0.12);
      letterColor = AppTheme.mostassa;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: showResult ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              // Badge amb lletra (A, B, C, D)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: letterBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: letterColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                    height: 1.4,
                  ),
                ),
              ),
              if (showResult && isCorrect)
                Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.verdeEncert,
                  size: 22,
                ),
              if (showResult && isSelected && !isCorrect)
                Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

/// Panell d'explicació amb barra lateral accent (estil NeuroTipCard)
class _ExplanationCard extends StatelessWidget {
  final bool isCorrect;
  final bool isTimeout;
  final String explanation;
  final String reference;

  const _ExplanationCard({
    required this.isCorrect,
    required this.isTimeout,
    required this.explanation,
    required this.reference,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isCorrect ? AppTheme.verdeEncert : Colors.redAccent;
    final headerText = isCorrect
        ? 'Correcte!'
        : isTimeout
        ? 'Temps esgotat!'
        : 'Incorrecte';
    final headerIcon = isCorrect
        ? Icons.check_circle_rounded
        : isTimeout
        ? Icons.timer_off_rounded
        : Icons.cancel_rounded;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: accentColor.withValues(alpha: 0.08),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barra lateral accent
            Container(width: 4, color: accentColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(headerIcon, color: accentColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          headerText,
                          style: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      explanation,
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.white.withValues(alpha: 0.85),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Badge de referència normativa
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.mostassa.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        reference,
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: AppTheme.mostassa.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vista de resultats amb cercle animat i missatge motivacional
class _QuizResultView extends StatelessWidget {
  final QuizProvider provider;

  const _QuizResultView({required this.provider});

  @override
  Widget build(BuildContext context) {
    final percentage = provider.score / provider.questions.length;
    final missatge = _getMissatgeResultat(percentage);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Cercle animat de puntuació
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: percentage),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: value,
                          strokeWidth: 8,
                          color: _getScoreColor(percentage),
                          backgroundColor: AppTheme.white.withValues(
                            alpha: 0.08,
                          ),
                          strokeCap: StrokeCap.round,
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(value * 100).toInt()}%',
                                style: TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.white,
                                ),
                              ),
                              Text(
                                '${provider.score}/${provider.questions.length}',
                                style: TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 14,
                                  color: AppTheme.grisPistacho.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              // Títol
              Text(
                'Entrenament Completat!',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.white,
                ),
              ),
              const SizedBox(height: 16),
              // Missatge motivacional (estil PrincipiClauCard)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: AppTheme.mostassa.withValues(alpha: 0.08),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.mostassa,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(14),
                            bottomLeft: Radius.circular(14),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Text(
                            '«$missatge»',
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.italic,
                              color: AppTheme.mostassa,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Botó repetir
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: provider.restartQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.mostassa,
                    foregroundColor: AppTheme.porpraFosc,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Repetir Entrenament',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Botó tornar
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppTheme.mostassa.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Tornar al Laboratori',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.mostassa,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMissatgeResultat(double percentage) {
    if (percentage >= 0.9) return 'Excel·lent! Dominis la normativa.';
    if (percentage >= 0.7) return 'Molt bé! Estàs en bona forma arbitral.';
    if (percentage >= 0.5) {
      return 'Correcte, però pots millorar. Segueix entrenant!';
    }
    return 'Cal repassar la normativa. No defalleixis!';
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 0.7) return AppTheme.verdeEncert;
    if (percentage >= 0.5) return AppTheme.mostassa;
    return Colors.redAccent;
  }
}
