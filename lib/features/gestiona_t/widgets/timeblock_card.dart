import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import '../models/time_block.dart';
import '../providers/schedule_provider.dart';
import 'timeblock_editor_dialog.dart';

/// Card individual d'un bloc de temps
class TimeblockCard extends StatelessWidget {
  final TimeBlock block;

  const TimeblockCard({super.key, required this.block});

  /// URL de la imatge de fons per als blocs d'esport
  static const String gymBackgroundUrl =
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/organitzat%2FinShape.webp?alt=media&token=ac46b684-bcdf-4d3f-a82c-c510e4e7a081';

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
      case TimeBlockCategory.amiguis:
        return Colors.orange.shade400;
      case TimeBlockCategory.time4me:
        return Colors.teal.shade400;
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
      case TimeBlockCategory.amiguis:
        return 'Amiguis';
      case TimeBlockCategory.time4me:
        return 'Time4Me';
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
    final isGym = block.category == TimeBlockCategory.gimnas;

    return GestureDetector(
      onTap: () => _openEditor(context),
      onLongPress: () => _confirmDelete(context),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        clipBehavior: isGym ? Clip.antiAlias : Clip.none,
        child: Stack(
          children: [
            // Imatge de fons per blocs d'esport
            if (isGym)
              Positioned.fill(
                child: Opacity(
                  opacity: block.done ? 0.15 : 0.3,
                  child: CachedNetworkImage(
                    imageUrl: gymBackgroundUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppTheme.verdeEncert.withValues(alpha: 0.1),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppTheme.verdeEncert.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),
            // Overlay fosc per llegibilitat
            if (isGym)
              Positioned.fill(
                child: Container(
                  color: AppTheme.porpraFosc.withValues(alpha: block.done ? 0.8 : 0.65),
                ),
              ),
            // Contingut
            IntrinsicHeight(
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
                                    // Badge de categoria (especial per gimnàs)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: categoryColor.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isGym)
                                            const Padding(
                                              padding: EdgeInsets.only(right: 4),
                                              child: Icon(
                                                Icons.fitness_center,
                                                size: 12,
                                                color: AppTheme.verdeEncert,
                                              ),
                                            ),
                                          Text(
                                            isGym ? 'In Shape' : getCategoryName(block.category),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: categoryColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Indicador recurrent
                                    if (block.isRecurring)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 6),
                                        child: Icon(
                                          Icons.repeat,
                                          size: 12,
                                          color: AppTheme.grisPistacho.withValues(alpha: 0.6),
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
          ],
        ),
      ),
    );
  }
}
