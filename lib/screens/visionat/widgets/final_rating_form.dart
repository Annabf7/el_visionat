import 'package:flutter/material.dart';
import '../../../models/match_models.dart';
import '../../../theme/app_theme.dart';

class FinalRatingForm extends StatelessWidget {
  final OverallMatchRating? selectedRating;
  final Set<String> selectedImprovementAreaIds;
  final ValueChanged<OverallMatchRating?> onRatingChanged;
  final ValueChanged<Set<String>> onImprovementAreasChanged;
  final VoidCallback onSubmit;

  const FinalRatingForm({
    super.key,
    required this.selectedRating,
    required this.selectedImprovementAreaIds,
    required this.onRatingChanged,
    required this.onImprovementAreasChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.mostassa, // Yellow background
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Valoració Final',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.porpraFosc,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Puntuació General',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.porpraFosc,
            ),
          ),
          const SizedBox(height: 8),
          _buildRatingDropdown(context),
          const SizedBox(height: 16),
          Text(
            'Àrees de Millora',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.porpraFosc,
            ),
          ),
          const SizedBox(height: 8),
          _buildImprovementCheckboxes(context),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('ENVIAR ANÀLISI'),
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.porpraFosc,
                foregroundColor: AppTheme.grisPistacho,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingDropdown(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.porpraFosc.withValues(alpha: 0.2)),
      ),
      child: DropdownButtonFormField<OverallMatchRating>(
        initialValue: selectedRating,
        decoration: const InputDecoration(
          hintText: 'Selecciona puntuació...',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: OverallMatchRating.values.map((rating) {
          return DropdownMenuItem(
            value: rating,
            child: Text(rating.displayName),
          );
        }).toList(),
        onChanged: onRatingChanged,
      ),
    );
  }

  Widget _buildImprovementCheckboxes(BuildContext context) {
    return Column(
      children: improvementAreas.map((area) {
        final isSelected = selectedImprovementAreaIds.contains(area.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (bool? value) {
              final newSelection = Set<String>.from(selectedImprovementAreaIds);
              if (value == true) {
                newSelection.add(area.id);
              } else {
                newSelection.remove(area.id);
              }
              onImprovementAreasChanged(newSelection);
            },
            title: Text(
              area.label,
              style: TextStyle(
                color: AppTheme.porpraFosc,
                fontWeight: FontWeight.w500,
              ),
            ),
            activeColor: AppTheme.porpraFosc,
            checkColor: AppTheme.grisPistacho,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        );
      }).toList(),
    );
  }
}
