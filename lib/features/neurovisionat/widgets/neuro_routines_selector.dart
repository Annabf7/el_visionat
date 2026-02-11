import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import '../models/neurovisionat_models.dart';

class NeuroRoutinesSelector extends StatefulWidget {
  final List<NeuroRoutine> routines;
  const NeuroRoutinesSelector({super.key, required this.routines});

  @override
  State<NeuroRoutinesSelector> createState() => _NeuroRoutinesSelectorState();
}

class _NeuroRoutinesSelectorState extends State<NeuroRoutinesSelector> {
  int? _selected;
  final Map<int, bool> _hoverStates = {};

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecciona una rutina',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.grisPistacho,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(widget.routines.length, (i) {
                  final routine = widget.routines[i];
                  final selected = _selected == i;
                  final isHovered = _hoverStates[i] ?? false;

                  // Calculate width for 2 columns (accounting for spacing)
                  final double itemWidth = (constraints.maxWidth - 12) / 2;

                  return MouseRegion(
                    onEnter: (_) => setState(() => _hoverStates[i] = true),
                    onExit: (_) => setState(() => _hoverStates[i] = false),
                    cursor: SystemMouseCursors.click,
                    child: SizedBox(
                      width: itemWidth,
                      height: 75,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selected = selected ? null : i;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 0,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.mostassa
                                : (isHovered
                                      ? AppTheme.mostassa.withValues(alpha: 0.1)
                                      : Colors.transparent),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.mostassa,
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            routine.nom,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: selected
                                  ? AppTheme.porpraFosc
                                  : AppTheme.grisPistacho,
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
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _selected != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.grisPistacho,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.psychology,
                            color: AppTheme.porpraFosc,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              widget.routines[_selected!].descripcio,
                              style: TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 15,
                                color: AppTheme.porpraFosc,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
