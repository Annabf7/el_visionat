import 'package:flutter/material.dart';
import '../models/highlight_entry.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

class HighlightsTimeline extends StatelessWidget {
  final List<HighlightEntry> entries;
  final String? selectedCategory;
  final VoidCallback? onHighlightTap;

  const HighlightsTimeline({
    super.key,
    required this.entries,
    this.selectedCategory,
    this.onHighlightTap,
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
    HighlightEntry entry,
    bool isLast,
  ) {
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
            child: Row(
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
                const SizedBox(width: 12),
                // Play button - triangular icon like in prototype
                GestureDetector(
                  onTap: () {
                    debugPrint('Go to ${_formatDuration(entry.timestamp)}');
                    onHighlightTap?.call();
                  },
                  child: Icon(
                    Icons.play_arrow,
                    color: const Color(0xFFE08B7B),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isLast) const SizedBox(height: 8),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
