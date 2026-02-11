import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import '../models/neurovisionat_models.dart';

class NeuroExerciseModal extends StatelessWidget {
  final NeuroExercise exercise;
  const NeuroExerciseModal({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exercise.titol,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.porpraFosc,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 18),
          ...exercise.passos.map(
            (pas) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.grisPistacho,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      pas,
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 15,
                        color: AppTheme.porpraFosc,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
