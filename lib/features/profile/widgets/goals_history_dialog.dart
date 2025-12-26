import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../models/season_goals_model.dart';

/// Dialog que mostra l'historial d'objectius assolits
/// Permet eliminar i restaurar objectius de l'historial
class GoalsHistoryDialog extends StatelessWidget {
  final List<GoalHistoryEntry> history;
  final String categoryFilter; // '', 'puntsMillorar', 'objectiusTrimestrals', 'objectiuTemporada'
  final Function(GoalHistoryEntry)? onDelete;
  final Function(GoalHistoryEntry)? onRestore;

  const GoalsHistoryDialog({
    super.key,
    required this.history,
    this.categoryFilter = '',
    this.onDelete,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final filteredHistory = categoryFilter.isEmpty
        ? history
        : history.where((entry) => entry.category == categoryFilter).toList()
      ..sort((a, b) => b.achievedDate.compareTo(a.achievedDate));

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.mostassa.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.mostassa.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.history,
                    color: AppTheme.mostassa,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getCategoryTitle(),
                          style: const TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textBlackLow,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${filteredHistory.length} ${filteredHistory.length == 1 ? "objectiu assolit" : "objectius assolits"}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textBlackLow.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    color: AppTheme.textBlackLow,
                  ),
                ],
              ),
            ),

            // Body amb llista d'historial
            Flexible(
              child: filteredHistory.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: filteredHistory.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildHistoryItem(
                          context,
                          filteredHistory[index],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryTitle() {
    switch (categoryFilter) {
      case 'puntsMillorar':
        return 'Evolució - Punts Millorats';
      case 'objectiusTrimestrals':
        return 'Evolució - Objectius Trimestrals';
      case 'objectiuTemporada':
        return 'Evolució - Objectius de Temporada';
      default:
        return 'Historial d\'Objectius Assolits';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: AppTheme.textBlackLow.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Encara no hi ha objectius assolits',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textBlackLow.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Marca els teus objectius com a completats\ni arxiva\'ls per veure\'ls aquí',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppTheme.textBlackLow.withValues(alpha: 0.5),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, GoalHistoryEntry entry) {
    final dateFormat = DateFormat('d MMM yyyy', 'ca_ES');
    final formattedDate = dateFormat.format(entry.achievedDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.grisPistacho.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.mostassa.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icona de checkmark
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.mostassa.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: AppTheme.mostassa,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Contingut
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.text,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textBlackLow,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.event,
                      size: 14,
                      color: AppTheme.textBlackLow.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Assolit: $formattedDate',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textBlackLow.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Botons d'acció
          Column(
            children: [
              // Botó restaurar
              if (onRestore != null)
                IconButton(
                  icon: const Icon(Icons.restore, size: 18),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onRestore!(entry);
                  },
                  color: AppTheme.mostassa,
                  tooltip: 'Restaurar objectiu',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              const SizedBox(height: 8),
              // Botó eliminar
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => _confirmDelete(context, entry),
                  color: Colors.red,
                  tooltip: 'Eliminar de l\'historial',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, GoalHistoryEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar de l\'historial'),
        content: Text(
          'Vols eliminar permanentment "${entry.text}" de l\'historial?\n\nAquesta acció no es pot desfer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel·lar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Tancar diàleg de confirmació
              Navigator.of(context).pop(); // Tancar diàleg d'historial
              onDelete!(entry);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}