import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import '../models/time_block.dart';
import '../providers/schedule_provider.dart';
import 'timeblock_editor_dialog.dart';

/// Card individual d'un bloc de temps
class TimeblockCard extends StatelessWidget {
  final TimeBlock block;

  const TimeblockCard({super.key, required this.block});

  /// Retorna el color associat a cada categoria
  static Color getCategoryColor(TimeBlockCategory category) {
    switch (category) {
      case TimeBlockCategory.arbitratge:
        return AppTheme.porpraFosc;
      case TimeBlockCategory.gimnas:
        return AppTheme.verdeEncert;
      case TimeBlockCategory.feina:
        return AppTheme.mostassa;
      case TimeBlockCategory.estudi:
        return AppTheme.lilaMitja;
      case TimeBlockCategory.familia:
        return Colors.pink.shade300;
      case TimeBlockCategory.descans:
        return AppTheme.grisPistacho;
    }
  }

  /// Retorna el nom en català de la categoria
  static String getCategoryName(TimeBlockCategory category) {
    switch (category) {
      case TimeBlockCategory.arbitratge:
        return 'Arbitratge';
      case TimeBlockCategory.gimnas:
        return 'Gimnàs';
      case TimeBlockCategory.feina:
        return 'Feina';
      case TimeBlockCategory.estudi:
        return 'Estudi';
      case TimeBlockCategory.familia:
        return 'Família';
      case TimeBlockCategory.descans:
        return 'Descans';
    }
  }

  /// Retorna el nom en català de la prioritat
  static String getPriorityName(TimeBlockPriority priority) {
    switch (priority) {
      case TimeBlockPriority.frog:
        return '🐸 Granota';
      case TimeBlockPriority.alta:
        return 'Alta';
      case TimeBlockPriority.mitja:
        return 'Mitjana';
      case TimeBlockPriority.baixa:
        return 'Baixa';
    }
  }

  void _openEditor(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => TimeblockEditorDialog(
        block: block,
        isNew: false,
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar bloc'),
        content: Text('Segur que vols eliminar "${block.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel·lar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () {
              context.read<ScheduleProvider>().deleteBlock(block.id!);
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm', 'ca_ES');
    final categoryColor = getCategoryColor(block.category);

    return GestureDetector(
      onTap: () => _openEditor(context),
      onLongPress: () => _confirmDelete(context),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Barra lateral de color per categoria
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              // Contingut del bloc
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Checkbox per marcar com a fet
                      Checkbox(
                        value: block.done,
                        onChanged: (value) {
                          context.read<ScheduleProvider>().toggleBlockDone(block.id!);
                        },
                        activeColor: AppTheme.verdeEncert,
                      ),
                      // Informació del bloc
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Títol amb decoració si està fet
                            Row(
                              children: [
                                if (block.isFrog)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 4),
                                    child: Text('🐸', style: TextStyle(fontSize: 16)),
                                  ),
                                Expanded(
                                  child: Text(
                                    block.title,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      decoration: block.done
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: block.done
                                          ? AppTheme.grisPistacho.withValues(alpha: 0.5)
                                          : null,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Hora i categoria
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${timeFormat.format(block.startAt)} - ${timeFormat.format(block.endAt)}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: categoryColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    getCategoryName(block.category),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: categoryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Duració
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${block.durationMinutes}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.mostassa,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'min',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
