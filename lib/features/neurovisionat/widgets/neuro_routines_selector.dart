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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecciona una rutina neuro-arbitral',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.porpraFosc,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: List.generate(widget.routines.length, (i) {
              final routine = widget.routines[i];
              final selected = _selected == i;
              return ChoiceChip(
                label: Text(
                  routine.nom,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 15,
                    color: selected ? AppTheme.white : AppTheme.porpraFosc,
                  ),
                ),
                selected: selected,
                onSelected: (val) {
                  setState(() {
                    _selected = val ? i : null;
                  });
                },
                backgroundColor: AppTheme.white,
                selectedColor: AppTheme.porpraFosc,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: selected
                        ? AppTheme.porpraFosc
                        : AppTheme.porpraFosc.withValues(alpha: 0.18),
                    width: 2,
                  ),
                ),
                elevation: selected ? 4 : 0,
              );
            }),
          ),
          const SizedBox(height: 18),
          if (_selected != null)
            Card(
              color: AppTheme.grisBody,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.routines[_selected!].descripcio,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 15,
                    color: AppTheme.porpraFosc,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
