import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import '../models/neurovisionat_models.dart';

class NeuroMiniQuiz extends StatefulWidget {
  final List<NeuroQuizQuestion> questions;
  const NeuroMiniQuiz({super.key, required this.questions});

  @override
  State<NeuroMiniQuiz> createState() => _NeuroMiniQuizState();
}

class _NeuroMiniQuizState extends State<NeuroMiniQuiz> {
  int _current = 0;
  int _score = 0;
  bool _answered = false;
  int? _selected;
  final Map<int, bool> _hoverStates = {};

  @override
  Widget build(BuildContext context) {
    final q = widget.questions[_current];
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: 0,
      ), // Removed excess padding
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: AppTheme.grisBody,
        elevation:
            0, // Flat inside parent container if needed, or keeping it clean
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(0), // Controlled by parent
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mini Quiz NeuroVisionat',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 20, // Increased slightly to standalone
                  fontWeight: FontWeight.bold,
                  color: AppTheme.grisPistacho,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                q.question,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 15, // Matched with Pillars body text
                  fontWeight: FontWeight.w500,
                  color: AppTheme.grisPistacho,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  // Grid 2x2 logic
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: List.generate(q.options.length, (i) {
                      final isSelected = _selected == i;
                      final isCorrect = _answered && i == q.correctIndex;
                      final isHovered = _hoverStates[i] ?? false;

                      // Calculate width for 2 columns (accounting for spacing)
                      final double itemWidth = (constraints.maxWidth - 12) / 2;

                      return MouseRegion(
                        onEnter: (_) => setState(() => _hoverStates[i] = true),
                        onExit: (_) => setState(() => _hoverStates[i] = false),
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: !_answered
                              ? () {
                                  setState(() {
                                    _selected = i;
                                    _answered = true;
                                    if (i == q.correctIndex) _score++;
                                  });
                                }
                              : null,
                          child: SizedBox(
                            width: itemWidth,
                            height: 75, // Fixed height for consistency
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 0, // Center vertically via alignment
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isCorrect
                                          ? AppTheme.verdeEncert
                                          : Colors.redAccent)
                                    : (isHovered
                                          ? AppTheme.mostassa.withValues(
                                              alpha: 0.1,
                                            )
                                          : Colors.transparent),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? (isCorrect
                                            ? AppTheme.verdeEncert
                                            : Colors.redAccent)
                                      : AppTheme.mostassa,
                                  width: 1, // Thin stroke
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                q.options[i],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal, // Sense bold
                                  color: isSelected
                                      ? AppTheme.white
                                      : AppTheme
                                            .grisPistacho, // Gris pistacho text
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 18),
              if (_answered)
                Row(
                  children: [
                    Icon(
                      _selected == q.correctIndex
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: _selected == q.correctIndex
                          ? AppTheme.grisPistacho
                          : Colors.redAccent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selected == q.correctIndex ? 'Correcte!' : 'Incorrecte',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _selected == q.correctIndex
                            ? AppTheme.grisPistacho
                            : Colors.redAccent,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.mostassa, // Button highlight
                        foregroundColor: AppTheme.porpraFosc,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _current < widget.questions.length - 1
                          ? () {
                              setState(() {
                                _current++;
                                _answered = false;
                                _selected = null;
                              });
                            }
                          : null,
                      child: Text(
                        _current < widget.questions.length - 1
                            ? 'Següent'
                            : 'Finalitza',
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              if (_current == widget.questions.length - 1 && _answered)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Puntuació: $_score / ${widget.questions.length}',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          AppTheme.grisPistacho, // Changed to improve contrast
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
