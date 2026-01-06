// ============================================================================
// RefereeCategoryBadge - Badge visual per mostrar categoria d'àrbitre
// ============================================================================
// Mostra un badge amb circumferència de color segons la categoria
// Utilitzat en comentaris anònims per identificar el nivell de l'àrbitre

import 'package:flutter/material.dart';
import 'package:el_visionat/core/constants/referee_category_colors.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

/// Badge que mostra la categoria d'un àrbitre amb color visual
class RefereeCategoryBadge extends StatelessWidget {
  final RefereeCategory category;
  final bool isAnonymous;
  final String? displayName; // Només si NO és anònim
  final bool showIcon;
  final bool compact; // Versió compacta (només icona + color)

  const RefereeCategoryBadge({
    super.key,
    required this.category,
    this.isAnonymous = true,
    this.displayName,
    this.showIcon = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = RefereeCategoryColors.getColorForCategory(category);

    if (compact) {
      return _buildCompactBadge(categoryColor);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(
          color: categoryColor,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(20),
        color: categoryColor.withValues(alpha: 0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              Icons.verified_user,
              size: 16,
              color: categoryColor,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            _getDisplayText(),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: categoryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Versió compacta: només circumferència de color amb icona
  Widget _buildCompactBadge(Color categoryColor) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: categoryColor,
          width: 2.5,
        ),
        color: categoryColor.withValues(alpha: 0.15),
      ),
      child: Center(
        child: Icon(
          Icons.verified_user,
          size: 14,
          color: categoryColor,
        ),
      ),
    );
  }

  String _getDisplayText() {
    if (isAnonymous) {
      // Format: "Àrbitre Verificat" o "Àrbitre ACB" segons preferència
      return 'Àrbitre ${category.displayName}';
    } else {
      // Mostra nom real + categoria
      return displayName ?? category.displayName;
    }
  }
}

/// Badge informatiu que explica el sistema de colors
/// Útil per mostrar en ajuda o primera vegada
class RefereeCategoryLegend extends StatelessWidget {
  const RefereeCategoryLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grisPistacho.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: AppTheme.porpraFosc),
              const SizedBox(width: 8),
              Text(
                'Categories Arbitrals',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.porpraFosc,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildLegendItem(RefereeCategory.acb, 'Màxima autoritat'),
          _buildLegendItem(RefereeCategory.febGrup1, 'Pot tancar debats'),
          _buildLegendItem(RefereeCategory.febGrup2, ''),
          _buildLegendItem(RefereeCategory.febGrup3, ''),
          _buildLegendItem(RefereeCategory.fcbqA1, 'Màxima categoria autonòmica'),
          _buildLegendItem(RefereeCategory.fcbqOther, ''),
        ],
      ),
    );
  }

  Widget _buildLegendItem(RefereeCategory category, String note) {
    final color = RefereeCategoryColors.getColorForCategory(category);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
              color: color.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              category.displayName,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppTheme.grisBody,
              ),
            ),
          ),
          if (note.isNotEmpty)
            Text(
              note,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: AppTheme.grisBody.withValues(alpha: 0.6),
              ),
            ),
        ],
      ),
    );
  }
}
