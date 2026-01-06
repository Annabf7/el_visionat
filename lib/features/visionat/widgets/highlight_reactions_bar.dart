// ============================================================================
// HighlightReactionsBar - Widget per reaccionar a jugades destacades
// ============================================================================
// Mostra 3 botons de reacció: Like, Important, Controversial
// Permet als usuaris votar jugades per activar revisió d'àrbitres

import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import '../models/highlight_reaction.dart';

/// Callback quan l'usuari clica una reacció
typedef OnReactionTap = void Function(ReactionType type);

/// Barra de reaccions per jugades destacades
class HighlightReactionsBar extends StatelessWidget {
  final ReactionsSummary summary;
  final Set<ReactionType> userReactions; // Reaccions de l'usuari actual
  final OnReactionTap onReactionTap;
  final bool isReadOnly; // Si està resolt, només lectura

  const HighlightReactionsBar({
    super.key,
    required this.summary,
    required this.userReactions,
    required this.onReactionTap,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildReactionButton(
          context: context,
          type: ReactionType.like,
          icon: Icons.thumb_up,
          count: summary.likeCount,
          color: const Color(0xFF50C878), // Verd
        ),
        _buildReactionButton(
          context: context,
          type: ReactionType.important,
          icon: Icons.priority_high,
          count: summary.importantCount,
          color: const Color(0xFFFFA500), // Taronja
        ),
        _buildReactionButton(
          context: context,
          type: ReactionType.controversial,
          icon: Icons.warning,
          count: summary.controversialCount,
          color: const Color(0xFFE74C3C), // Vermell
        ),
      ],
    );
  }

  Widget _buildReactionButton({
    required BuildContext context,
    required ReactionType type,
    required IconData icon,
    required int count,
    required Color color,
  }) {
    final isActive = userReactions.contains(type);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isReadOnly ? null : () => onReactionTap(type),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? color.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive
                    ? color
                    : AppTheme.grisPistacho.withValues(alpha: 0.2),
                width: isActive ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isActive ? color : AppTheme.grisBody.withValues(alpha: 0.6),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive ? color : AppTheme.grisBody,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Versió compacta de la barra de reaccions (només comptadors)
class HighlightReactionsChips extends StatelessWidget {
  final ReactionsSummary summary;
  final bool showEmpty; // Mostrar encara que sigui 0

  const HighlightReactionsChips({
    super.key,
    required this.summary,
    this.showEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (summary.likeCount > 0 || showEmpty) {
      chips.add(_buildChip(
        icon: Icons.thumb_up,
        count: summary.likeCount,
        color: const Color(0xFF50C878),
      ));
    }

    if (summary.importantCount > 0 || showEmpty) {
      chips.add(_buildChip(
        icon: Icons.priority_high,
        count: summary.importantCount,
        color: const Color(0xFFFFA500),
      ));
    }

    if (summary.controversialCount > 0 || showEmpty) {
      chips.add(_buildChip(
        icon: Icons.warning,
        count: summary.controversialCount,
        color: const Color(0xFFE74C3C),
      ));
    }

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: chips,
    );
  }

  Widget _buildChip({
    required IconData icon,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Threshold indicator - mostra progrés cap a les 10 reaccions
class ReactionThresholdIndicator extends StatelessWidget {
  final int totalReactions;
  final int threshold;

  const ReactionThresholdIndicator({
    super.key,
    required this.totalReactions,
    this.threshold = 10,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (totalReactions / threshold).clamp(0.0, 1.0);
    final hasReachedThreshold = totalReactions >= threshold;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppTheme.grisPistacho.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    hasReachedThreshold
                        ? const Color(0xFF50C878) // Verd
                        : AppTheme.mostassa, // Groc
                  ),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$totalReactions/$threshold',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: hasReachedThreshold
                    ? const Color(0xFF50C878)
                    : AppTheme.grisBody,
              ),
            ),
          ],
        ),
        if (hasReachedThreshold) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.notifications_active,
                size: 12,
                color: const Color(0xFF50C878),
              ),
              const SizedBox(width: 4),
              Text(
                'Àrbitres notificats per revisar',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF50C878),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
