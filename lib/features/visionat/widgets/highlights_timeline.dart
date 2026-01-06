import 'package:flutter/material.dart';
import '../models/highlight_play.dart';
import '../models/highlight_reaction.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/highlight_provider.dart';

class HighlightsTimeline extends StatelessWidget {
  final List<HighlightPlay> entries;
  final String? selectedCategory;
  final VoidCallback? onHighlightTap;
  final Function(String highlightId, ReactionType type)? onReactionTap;
  final String? currentUserId; // Per determinar quines reaccions té l'usuari

  const HighlightsTimeline({
    super.key,
    required this.entries,
    this.selectedCategory,
    this.onHighlightTap,
    this.onReactionTap,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white, // D9D9D9
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Minutatge',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppTheme.porpraFosc),
          ),
          const SizedBox(height: 24),
          _buildTimelineList(context),
        ],
      ),
    );
  }

  Widget _buildTimelineList(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline vertical line - hidden on mobile
          if (!isMobile) ...[
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: const BorderRadius.all(Radius.circular(2)),
              ),
            ),
            const SizedBox(width: 16),
          ],
          // Timeline entries
          Expanded(
            child: Column(
              children: entries.asMap().entries.map((mapEntry) {
                final index = mapEntry.key;
                final entry = mapEntry.value;
                return _buildTimelineEntry(
                  context,
                  entry,
                  index == entries.length - 1,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineEntry(
    BuildContext context,
    HighlightPlay entry,
    bool isLast,
  ) {
    final highlightPlay = entry;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE8E7),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.porpraFosc.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila principal: timestamp, title, reactions (desktop), play button
                Row(
                  children: [
                    // Timestamp
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.lilaMitja,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatDuration(entry.timestamp),
                        style: TextStyle(
                          color: AppTheme.grisPistacho,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Title
                    Expanded(
                      child: Text(
                        entry.title,
                        style: TextStyle(
                          color: AppTheme.grisBody,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),

                    // DESKTOP: Reaccions compactes en línia
                    if (!isMobile && onReactionTap != null) ...[
                      const SizedBox(width: 16),
                      _buildCompactReactions(highlightPlay),
                    ],

                    const SizedBox(width: 12),

                    // Play button (en mòbil obre modal, en desktop només reprodueix)
                    GestureDetector(
                      onTap: () {
                        if (isMobile && onReactionTap != null) {
                          _showMobileReactionsModal(context, highlightPlay);
                        } else {
                          debugPrint('Go to ${_formatDuration(entry.timestamp)}');
                          onHighlightTap?.call();
                        }
                      },
                      child: Icon(
                        isMobile && onReactionTap != null
                          ? Icons.more_vert
                          : Icons.play_arrow,
                        color: const Color(0xFFE08B7B),
                        size: 24,
                      ),
                    ),
                  ],
                ),

                // Badge d'estat si està en revisió o resolt (ambdues versions)
                if (highlightPlay.status != HighlightPlayStatus.open) ...[
                  const SizedBox(height: 8),
                  _buildStatusBadge(highlightPlay.status),
                ],
              ],
            ),
          ),
        ),
        if (!isLast) const SizedBox(height: 8),
      ],
    );
  }

  /// Reaccions compactes per desktop (en línia)
  Widget _buildCompactReactions(HighlightPlay play) {
    final totalReactions = play.reactionsSummary.totalCount;
    final userReactions = _getUserReactions(play);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botó M'agrada
        _buildCompactReactionButton(
          icon: Icons.thumb_up,
          count: play.reactionsSummary.likeCount,
          isActive: userReactions.contains(ReactionType.like),
          color: AppTheme.lilaMitja,
          onTap: () => onReactionTap!(play.id, ReactionType.like),
        ),
        const SizedBox(width: 8),

        // Botó Important
        _buildCompactReactionButton(
          icon: Icons.priority_high,
          count: play.reactionsSummary.importantCount,
          isActive: userReactions.contains(ReactionType.important),
          color: AppTheme.lilaMitja,
          onTap: () => onReactionTap!(play.id, ReactionType.important),
        ),
        const SizedBox(width: 8),

        // Botó Controvertida
        _buildCompactReactionButton(
          icon: Icons.help_outline,
          count: play.reactionsSummary.controversialCount,
          isActive: userReactions.contains(ReactionType.controversial),
          color: AppTheme.lilaMitja,
          onTap: () => onReactionTap!(play.id, ReactionType.controversial),
        ),

        // Indicador de progrés cap a 10
        if (totalReactions > 0) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: totalReactions >= 10
                ? AppTheme.mostassa.withValues(alpha: 0.2)
                : AppTheme.grisPistacho.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: totalReactions >= 10
                  ? AppTheme.mostassa
                  : AppTheme.grisPistacho.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              '$totalReactions/10',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: totalReactions >= 10
                  ? AppTheme.mostassa
                  : AppTheme.grisBody,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Botó de reacció compacte per desktop
  Widget _buildCompactReactionButton({
    required IconData icon,
    required int count,
    required bool isActive,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
            ? color.withValues(alpha: 0.15)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
              ? color
              : AppTheme.grisPistacho.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? color : AppTheme.grisBody,
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? color : AppTheme.grisBody,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Modal per mòbil amb opcions de reacció
  void _showMobileReactionsModal(BuildContext context, HighlightPlay play) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) {
        // Utilitzar Consumer per escoltar canvis del provider
        return Consumer<VisionatHighlightProvider>(
          builder: (context, provider, child) {
            // Obtenir la última versió del highlight des del provider
            final currentPlay = provider.filteredHighlights.firstWhere(
              (e) => e.id == play.id,
              orElse: () => play,
            );
            final userReactions = _getUserReactions(currentPlay);
            final totalReactions = currentPlay.reactionsSummary.totalCount;

            return Container(
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Fila superior: Títol + Botó tancar
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          currentPlay.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.porpraFosc,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.grisPistacho.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: AppTheme.grisBody,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Categoria
                  Text(
                    currentPlay.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.grisBody,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Barra de progrés cap a 10 reaccions
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Reaccions totals',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.grisBody,
                            ),
                          ),
                          Text(
                            '$totalReactions / 10',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: totalReactions >= 10
                                ? AppTheme.mostassa
                                : AppTheme.porpraFosc,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: totalReactions / 10,
                          minHeight: 8,
                          backgroundColor: AppTheme.grisPistacho.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation(
                            totalReactions >= 10
                              ? AppTheme.mostassa
                              : AppTheme.lilaMitja,
                          ),
                        ),
                      ),
                      if (totalReactions >= 10) ...[
                        const SizedBox(height: 8),
                        Text(
                          '✓ Àrbitres de màxima categoria notificats',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.mostassa,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Botons de reacció (grans per mòbil)
                  Text(
                    'La teva reacció:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.grisBody,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildMobileReactionButton(
                          context: context,
                          label: 'M\'agrada',
                          icon: Icons.thumb_up,
                          count: currentPlay.reactionsSummary.likeCount,
                          isActive: userReactions.contains(ReactionType.like),
                          color: AppTheme.lilaMitja,
                          onTap: () async {
                            onReactionTap!(currentPlay.id, ReactionType.like);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMobileReactionButton(
                          context: context,
                          label: 'Important',
                          icon: Icons.priority_high,
                          count: currentPlay.reactionsSummary.importantCount,
                          isActive: userReactions.contains(ReactionType.important),
                          color: AppTheme.lilaMitja,
                          onTap: () async {
                            onReactionTap!(currentPlay.id, ReactionType.important);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMobileReactionButton(
                          context: context,
                          label: 'Dubtosa',
                          icon: Icons.help_outline,
                          count: currentPlay.reactionsSummary.controversialCount,
                          isActive: userReactions.contains(ReactionType.controversial),
                          color: AppTheme.lilaMitja,
                          onTap: () async {
                            onReactionTap!(currentPlay.id, ReactionType.controversial);
                          },
                        ),
                      ),
                    ],
                  ),

                  // Badge d'estat
                  if (currentPlay.status != HighlightPlayStatus.open) ...[
                    const SizedBox(height: 16),
                    _buildStatusBadge(currentPlay.status),
                  ],

                  // Botó per reproduir
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onHighlightTap?.call();
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Reproduir jugada'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.lilaMitja,
                      side: BorderSide(color: AppTheme.lilaMitja, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Botó de reacció per mòbil (gran i tàctil)
  Widget _buildMobileReactionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required int count,
    required bool isActive,
    required Color color,
    required Future<void> Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive
            ? color.withValues(alpha: 0.2)
            : AppTheme.grisPistacho.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : AppTheme.grisPistacho.withValues(alpha: 0.3),
            width: isActive ? 2.5 : 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isActive ? color : AppTheme.grisBody,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isActive ? color : AppTheme.grisBody,
              ),
              textAlign: TextAlign.center,
            ),
            if (count > 0) ...[
              const SizedBox(height: 2),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isActive ? color : AppTheme.grisBody,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Obté les reaccions de l'usuari actual
  Set<ReactionType> _getUserReactions(HighlightPlay play) {
    if (currentUserId == null) return {};

    return play.reactions
        .where((r) => r.userId == currentUserId)
        .map((r) => r.type)
        .toSet();
  }

  /// Badge d'estat (en revisió / resolt)
  Widget _buildStatusBadge(HighlightPlayStatus status) {
    Color badgeColor;
    String label;
    IconData icon;

    switch (status) {
      case HighlightPlayStatus.underReview:
        badgeColor = const Color(0xFFFFA500); // Taronja
        label = 'En revisió';
        icon = Icons.visibility;
        break;
      case HighlightPlayStatus.resolved:
        badgeColor = const Color(0xFF50C878); // Verd
        label = 'Resolt';
        icon = Icons.check_circle;
        break;
      default:
        badgeColor = AppTheme.grisPistacho;
        label = 'Obert';
        icon = Icons.lock_open;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: badgeColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
