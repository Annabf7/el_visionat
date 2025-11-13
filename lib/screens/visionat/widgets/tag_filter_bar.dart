import 'package:flutter/material.dart';
import '../../../models/highlight_entry.dart';
import '../../../theme/app_theme.dart';

class TagFilterBar extends StatelessWidget {
  final HighlightTagType? selectedTag;
  final ValueChanged<HighlightTagType?> onTagChanged;
  final bool showIcons;

  const TagFilterBar({
    super.key,
    required this.selectedTag,
    required this.onTagChanged,
    this.showIcons = true,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTagChip(
            context,
            label: 'Tots',
            isSelected: selectedTag == null,
            onTap: () => onTagChanged(null),
            icon: showIcons ? Icons.all_inclusive : null,
          ),
          const SizedBox(width: 8),
          ...HighlightTagType.values.map(
            (tag) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildTagChip(
                context,
                label: tag.displayName,
                isSelected: selectedTag == tag,
                onTap: () => onTagChanged(tag),
                icon: showIcons ? _getIconForTag(tag) : null,
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
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.lilaMitja : AppTheme.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.lilaMitja
                : AppTheme.grisBody.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? AppTheme.grisPistacho : AppTheme.grisBody,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.grisPistacho : AppTheme.grisBody,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForTag(HighlightTagType tag) {
    switch (tag) {
      case HighlightTagType.faltaTecnica:
        return Icons.card_membership;
      case HighlightTagType.decisioClau:
        return Icons.warning;
      case HighlightTagType.posicio:
        return Icons.person_pin_circle;
      case HighlightTagType.comunicacio:
        return Icons.chat;
      case HighlightTagType.gestio:
        return Icons.settings;
    }
  }
}
