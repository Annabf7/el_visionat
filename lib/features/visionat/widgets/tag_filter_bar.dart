import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class TagFilterBar extends StatelessWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;

  const TagFilterBar({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  static const List<String> categories = [
    'Faltes personals',
    'Violacions',
    'Faltes tècniques',
    'Antiesportives i desqualificants',
    'Gestió i posicionament',
    'Situacions especials',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTagChip(
            context,
            label: 'Tots',
            isSelected: selectedCategory == null,
            onTap: () => onCategoryChanged(null),
          ),
          const SizedBox(width: 8),
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildTagChip(
                context,
                label: category,
                isSelected: selectedCategory == category,
                onTap: () => onCategoryChanged(category),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.lilaMitja : AppTheme.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppTheme.lilaMitja
                : AppTheme.grisBody.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.grisPistacho : AppTheme.grisBody,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
