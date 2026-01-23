import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import '../models/highlight_play.dart';
import '../providers/highlight_provider.dart';

class RefereeCommentCard extends StatelessWidget {
  const RefereeCommentCard({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Consumer<VisionatHighlightProvider>(
      builder: (context, provider, child) {
        final controversialHighlights = provider.topControversialHighlights;

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.grisBody,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.white, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppTheme.porpraFosc.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Títol
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: AppTheme.mostassa,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Jugades més polèmiques',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Les jugades amb més reaccions de la comunitat',
                style: textTheme.bodySmall?.copyWith(
                  color: AppTheme.grisPistacho,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),

              // Llista de jugades o estat buit
              if (controversialHighlights.isEmpty)
                _buildEmptyState(textTheme)
              else
                ...controversialHighlights.asMap().entries.map((entry) {
                  final index = entry.key;
                  final highlight = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < controversialHighlights.length - 1 ? 12 : 0,
                    ),
                    child: _buildControversialItem(
                      context,
                      highlight,
                      index + 1,
                      textTheme,
                    ),
                  );
                }),

              const SizedBox(height: 12),

              // Peu informatiu
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: AppTheme.mostassa),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Basat en les reaccions dels àrbitres al minutatge.',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppTheme.mostassa,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.porpraFosc.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.porpraFosc.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.hourglass_empty,
            color: AppTheme.grisPistacho,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Encara no hi ha jugades destacades',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppTheme.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quan els àrbitres reaccionin a les jugades del minutatge, apareixeran aquí.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppTheme.grisPistacho,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControversialItem(
    BuildContext context,
    HighlightPlay highlight,
    int position,
    TextTheme textTheme,
  ) {
    // Formatem el minutatge
    final minutes = highlight.timestamp.inMinutes;
    final seconds = highlight.timestamp.inSeconds % 60;
    final minutatgeText = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    // Color segons posició (1r = més destacat)
    final positionColor = position == 1
        ? AppTheme.mostassa
        : position == 2
            ? AppTheme.white
            : AppTheme.grisPistacho;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.grisBody,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: position == 1
              ? AppTheme.mostassa.withValues(alpha: 0.5)
              : AppTheme.porpraFosc.withValues(alpha: 0.4),
          width: position == 1 ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Número de posició
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: positionColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: positionColor, width: 1.5),
            ),
            child: Center(
              child: Text(
                '$position',
                style: TextStyle(
                  color: positionColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Contingut
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Títol i minutatge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.porpraFosc,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        minutatgeText,
                        style: textTheme.labelSmall?.copyWith(
                          color: AppTheme.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        highlight.title,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppTheme.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Categoria i reaccions
                Row(
                  children: [
                    // Categoria/Tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.mostassa.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        highlight.category,
                        style: textTheme.labelSmall?.copyWith(
                          color: AppTheme.mostassa,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Icones de reaccions
                    _buildReactionBadge(
                      Icons.thumb_up,
                      highlight.reactionsSummary.likeCount,
                      Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _buildReactionBadge(
                      Icons.priority_high,
                      highlight.reactionsSummary.importantCount,
                      Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    _buildReactionBadge(
                      Icons.warning,
                      highlight.reactionsSummary.controversialCount,
                      Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionBadge(IconData icon, int count, Color color) {
    if (count == 0) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
