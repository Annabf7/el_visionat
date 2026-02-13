import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import '../models/time_block.dart';
import '../providers/schedule_provider.dart';
import 'timeblock_card.dart';
import 'timeblock_editor_dialog.dart';

/// Vista setmanal en graella horària estil Google Calendar
class WeeklyGridView extends StatefulWidget {
  const WeeklyGridView({super.key});

  @override
  State<WeeklyGridView> createState() => _WeeklyGridViewState();
}

class _WeeklyGridViewState extends State<WeeklyGridView> {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  final Map<int, GlobalKey> _dayColumnKeys = {};

  // Configuració de la graella
  static const int startHour = 6; // Comença a les 6:00
  static const int endHour = 23; // Acaba a les 23:00
  static const double hourHeight = 60.0; // Alçada per hora
  static const double timeColumnWidth = 50.0; // Amplada columna d'hores
  static const double minDayWidth = 120.0; // Amplada mínima per dia

  @override
  void initState() {
    super.initState();
    // Scroll inicial a les 8:00 per defecte
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_verticalController.hasClients) {
        _verticalController.jumpTo((8 - startHour) * hourHeight);
      }
    });
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (context, provider, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // Calcular amplada disponible per als dies
            final availableWidth = constraints.maxWidth - timeColumnWidth;
            final isDesktop = constraints.maxWidth > 900;

            // En desktop, 7 dies visibles; en mòbil, scroll horitzontal
            final dayWidth = isDesktop
                ? availableWidth / 7
                : math.max(minDayWidth, availableWidth / 3);

            final summary = provider.getWeeklySummary();
            final gymBlockCount = summary['gymBlockCount'] as int? ?? 0;
            final gymGoalMet = summary['gymGoalMet'] as bool? ?? false;

            return Column(
              children: [
                // Capçalera amb navegació de setmana
                _buildWeekHeader(provider, isDesktop),
                // Banner objectiu gym (si no s'ha arribat a 3 blocs)
                if (!gymGoalMet)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.mostassa.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 14,
                          color: AppTheme.mostassa.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Necessites ${3 - gymBlockCount} entrenament${3 - gymBlockCount > 1 ? 's' : ''} '
                          'mes aquesta setmana',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.mostassa.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                // Graella principal
                Expanded(child: _buildGrid(provider, dayWidth, isDesktop)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildWeekHeader(ScheduleProvider provider, bool isDesktop) {
    final weekStart = provider.weekStart;
    final weekEnd = weekStart.add(const Duration(days: 6));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.porpraFosc,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppTheme.grisPistacho),
            onPressed: () => provider.navigateWeek(-1),
            tooltip: 'Setmana anterior',
          ),
          Expanded(
            child: Text(
              _formatWeekRange(weekStart, weekEnd),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.grisPistacho,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppTheme.grisPistacho),
            onPressed: () => provider.navigateWeek(1),
            tooltip: 'Setmana següent',
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => provider.selectDay(DateTime.now()),
            child: const Text(
              'Avui',
              style: TextStyle(color: AppTheme.mostassa),
            ),
          ),
        ],
      ),
    );
  }

  String _formatWeekRange(DateTime start, DateTime end) {
    final dayFormat = DateFormat('d', 'ca_ES');
    final monthFormat = DateFormat('MMM', 'ca_ES');

    if (start.month == end.month) {
      return '${dayFormat.format(start)} - ${dayFormat.format(end)} ${monthFormat.format(start)} ${start.year}';
    } else {
      return '${dayFormat.format(start)} ${monthFormat.format(start)} - ${dayFormat.format(end)} ${monthFormat.format(end)}';
    }
  }

  Widget _buildGrid(
    ScheduleProvider provider,
    double dayWidth,
    bool isDesktop,
  ) {
    return Row(
      children: [
        // Columna d'hores (fixa)
        SizedBox(width: timeColumnWidth, child: _buildTimeColumn()),
        // Graella de dies (scroll horitzontal en mòbil)
        Expanded(
          child: isDesktop
              ? _buildDaysGrid(provider, dayWidth)
              : SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: dayWidth * 7,
                    child: _buildDaysGrid(provider, dayWidth),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTimeColumn() {
    return SingleChildScrollView(
      controller: _verticalController,
      child: Column(
        children: [
          // Espai per la capçalera dels dies
          const SizedBox(height: 40),
          // Hores
          ...List.generate(endHour - startHour, (index) {
            final hour = startHour + index;
            return SizedBox(
              height: hourHeight,
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, top: 0),
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.grisPistacho.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDaysGrid(ScheduleProvider provider, double dayWidth) {
    final weekStart = provider.weekStart;
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Sincronitzar scroll vertical amb la columna d'hores
        if (notification is ScrollUpdateNotification) {
          _verticalController.jumpTo(notification.metrics.pixels);
        }
        return false;
      },
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Capçalera dels dies
            SizedBox(
              height: 40,
              child: Row(
                children: days.map((day) {
                  return SizedBox(
                    width: dayWidth,
                    child: _buildDayHeader(day, provider),
                  );
                }).toList(),
              ),
            ),
            // Graella horària
            SizedBox(
              height: (endHour - startHour) * hourHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: days.asMap().entries.map((entry) {
                  return SizedBox(
                    width: dayWidth,
                    child: _buildDayColumn(
                      entry.value,
                      provider,
                      dayWidth,
                      entry.key,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayHeader(DateTime day, ScheduleProvider provider) {
    final isToday = DateUtils.isSameDay(day, DateTime.now());
    final isSelected = DateUtils.isSameDay(day, provider.selectedDay);
    final hasDesignation = provider.hasDesignationForDay(day);
    final dayFormat = DateFormat('E', 'ca_ES');
    final dateFormat = DateFormat('d', 'ca_ES');

    return GestureDetector(
      onTap: () => provider.selectDay(day),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.mostassa.withValues(alpha: 0.2)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: AppTheme.grisPistacho.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasDesignation)
                  const Padding(
                    padding: EdgeInsets.only(right: 2),
                    child: Text('🏀', style: TextStyle(fontSize: 8)),
                  ),
                Text(
                  dayFormat.format(day).toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    color: isToday
                        ? AppTheme.verdeEncert
                        : AppTheme.grisPistacho.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isToday ? AppTheme.verdeEncert : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  dateFormat.format(day),
                  style: TextStyle(
                    fontSize: 11,
                    color: isToday ? Colors.white : AppTheme.grisPistacho,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayColumn(
    DateTime day,
    ScheduleProvider provider,
    double dayWidth,
    int dayIndex,
  ) {
    final blocks = provider.getBlocksForDay(day);
    final key = _dayColumnKeys.putIfAbsent(dayIndex, () => GlobalKey());

    return DragTarget<TimeBlock>(
      key: key,
      onWillAcceptWithDetails: (details) {
        return details.data.source != TimeBlockSource.designation;
      },
      onAcceptWithDetails: (details) {
        _handleBlockDrop(details, day, dayIndex);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty
                ? AppTheme.mostassa.withValues(alpha: 0.05)
                : null,
            border: Border(
              left: BorderSide(
                color: AppTheme.grisPistacho.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
          ),
          child: Stack(
            children: [
              // Línies horitzontals (hores)
              ...List.generate(endHour - startHour, (index) {
                return Positioned(
                  top: index * hourHeight,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1,
                    color: AppTheme.grisPistacho.withValues(alpha: 0.1),
                  ),
                );
              }),
              // Línia de l'hora actual (si és avui)
              if (DateUtils.isSameDay(day, DateTime.now()))
                _buildCurrentTimeLine(),
              // Blocs de temps
              ...blocks.map((block) => _buildBlockWidget(block, dayWidth)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentTimeLine() {
    final now = DateTime.now();
    final minutes = (now.hour - startHour) * 60 + now.minute;
    final top = minutes * (hourHeight / 60);

    if (now.hour < startHour || now.hour >= endHour) return const SizedBox();

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(child: Container(height: 2, color: Colors.redAccent)),
        ],
      ),
    );
  }

  Widget _buildBlockWidget(TimeBlock block, double dayWidth) {
    // Calcular posició i alçada
    final startMinutes =
        (block.startAt.hour - startHour) * 60 + block.startAt.minute;
    final top = startMinutes * (hourHeight / 60);

    // Si és una designació, forcem la durada a 1h 45m visualment
    // Això assegura que es vegi correctament encara que la dada antiga tingui 2h
    final isDesignation = block.source == TimeBlockSource.designation;
    final effectiveDuration = isDesignation ? 105 : block.durationMinutes;
    final effectiveEndAt = isDesignation
        ? block.startAt.add(const Duration(hours: 1, minutes: 45))
        : block.endAt;

    final height = (effectiveDuration * (hourHeight / 60)).clamp(
      20.0,
      double.infinity,
    );

    // Si el bloc comença abans de l'hora d'inici visible, no el mostrem
    if (block.startAt.hour < startHour) {
      return const SizedBox();
    }
    final isGym = block.category == TimeBlockCategory.gimnas;
    final color = TimeblockCard.getCategoryColor(block.category);

    // Determinar la vora segons el tipus de bloc
    Border? border;
    if (isDesignation) {
      border = Border.all(color: Colors.orange, width: 2);
    } else if (isGym) {
      border = Border.all(color: AppTheme.verdeEncert, width: 1.5);
    } else if (block.isFrog) {
      border = Border.all(color: AppTheme.verdeEncert, width: 2);
    }

    // Contingut visual del bloc (reutilitzat per feedback del drag)
    Widget blockContent() {
      return Container(
        clipBehavior: isGym ? Clip.antiAlias : Clip.none,
        decoration: BoxDecoration(
          color: isGym
              ? null
              : (block.done
                    ? color.withValues(alpha: 0.3)
                    : color.withValues(alpha: 0.8)),
          image: isGym
              ? DecorationImage(
                  image: CachedNetworkImageProvider(
                    TimeblockCard.gymBackgroundUrl,
                  ),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    AppTheme.verdeEncert.withValues(
                      alpha: block.done ? 0.3 : 0.7,
                    ),
                    BlendMode.multiply,
                  ),
                )
              : null,
          borderRadius: BorderRadius.circular(4),
          border: border,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isGym && !isDesignation)
                        Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: Icon(
                            Icons.fitness_center,
                            size: 10,
                            color: block.done
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.white,
                          ),
                        ),
                      if (block.isFrog && !isDesignation && !isGym)
                        const Padding(
                          padding: EdgeInsets.only(right: 2),
                          child: Text('🐸', style: TextStyle(fontSize: 10)),
                        ),
                      Expanded(
                        child: Text(
                          block.title,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: block.done
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.white,
                            decoration: block.done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: height > 40 ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (block.done && !isDesignation)
                        Icon(
                          Icons.check_circle,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                    ],
                  ),
                  if (height > 35)
                    Text(
                      '${_formatTime(block.startAt)} - ${_formatTime(effectiveEndAt)}',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),

                  // Només Categoria per designacions (la resta al clickar)
                  if (isDesignation && height > 55) ...[
                    const SizedBox(height: 4),
                    if (block.matchCategory != null)
                      Text(
                        block.matchCategory!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ],
              ),
            ),
            if (block.isRecurring && height > 30)
              Positioned(
                right: 3,
                bottom: 2,
                child: Icon(
                  Icons.repeat,
                  size: 8,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
          ],
        ),
      );
    }

    // Blocs de designació: sense drag, només tap
    if (isDesignation) {
      return Positioned(
        top: top,
        left: 2,
        right: 2,
        height: height,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _openBlockEditor(block),
            child: blockContent(),
          ),
        ),
      );
    }

    // Resta de blocs: LongPressDraggable + tap
    return Positioned(
      top: top,
      left: 2,
      right: 2,
      height: height,
      child: LongPressDraggable<TimeBlock>(
        data: block,
        hapticFeedbackOnStart: true,
        feedback: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(4),
          child: Opacity(
            opacity: 0.85,
            child: SizedBox(
              width: dayWidth - 4,
              height: height,
              child: blockContent(),
            ),
          ),
        ),
        childWhenDragging: Container(
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(4),
            color: color.withValues(alpha: 0.1),
          ),
        ),
        child: GestureDetector(
          onTap: () => _openBlockEditor(block),
          child: blockContent(),
        ),
      ),
    );
  }

  void _handleBlockDrop(
    DragTargetDetails<TimeBlock> details,
    DateTime targetDay,
    int dayIndex,
  ) {
    final block = details.data;
    final duration = block.endAt.difference(block.startAt);

    // Obtenir el RenderBox del DragTarget per convertir coordenades globals a locals
    final key = _dayColumnKeys[dayIndex];
    final renderBox = key?.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localOffset = renderBox.globalToLocal(details.offset);

    // Calcular hora des de la posició Y dins la columna
    final totalMinutes = (localOffset.dy / hourHeight * 60).round();
    final snappedMinutes = (totalMinutes ~/ 15) * 15; // Snap a 15 minuts
    final clampedMinutes = snappedMinutes.clamp(
      0,
      (endHour - startHour) * 60 - duration.inMinutes,
    );
    final newHour = startHour + clampedMinutes ~/ 60;
    final newMinute = clampedMinutes % 60;

    final newStart = DateTime(
      targetDay.year,
      targetDay.month,
      targetDay.day,
      newHour,
      newMinute,
    );
    final newEnd = newStart.add(duration);

    // No moure si mateixa posició
    if (newStart == block.startAt) return;

    // No permetre que el bloc sobrepassi el final de la graella
    if (newEnd.hour > endHour ||
        (newEnd.hour == endHour && newEnd.minute > 0)) {
      return;
    }

    final updatedBlock = block.copyWith(startAt: newStart, endAt: newEnd);
    context.read<ScheduleProvider>().updateBlock(updatedBlock);
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _openBlockEditor(TimeBlock block) {
    showDialog(
      context: context,
      builder: (context) => TimeblockEditorDialog(block: block, isNew: false),
    );
  }
}
