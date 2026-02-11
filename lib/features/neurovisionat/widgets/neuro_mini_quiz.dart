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

  @override
  Widget build(BuildContext context) {
    final q = widget.questions[_current];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: AppTheme.grisBody,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mini Quiz NeuroVisionat',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.porpraFosc,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                q.question,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.porpraFosc,
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(q.options.length, (i) {
                final isSelected = _selected == i;
                final isCorrect = _answered && i == q.correctIndex;
                return GestureDetector(
                  onTap: !_answered
                      ? () {
                          setState(() {
                            _selected = i;
                            _answered = true;
                            if (i == q.correctIndex) _score++;
                          });
                        }
                      : null,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isCorrect
                                ? AppTheme.grisPistacho
                                : AppTheme.porpraFosc.withValues(alpha: 0.15))
                          : AppTheme.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? (isCorrect
                                  ? AppTheme.grisPistacho
                                  : AppTheme.porpraFosc)
                            : AppTheme.porpraFosc.withValues(alpha: 0.18),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      q.options[i],
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: isSelected
                            ? (isCorrect
                                  ? AppTheme.porpraFosc
                                  : AppTheme.porpraFosc)
                            : AppTheme.porpraFosc,
                      ),
                    ),
                  ),
                );
              }),
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
                        backgroundColor: AppTheme.porpraFosc,
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
                          color: AppTheme.white,
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
                      color: AppTheme.porpraFosc,
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
