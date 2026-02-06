import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
                : minDayWidth.clamp(minDayWidth, availableWidth / 3);

            return Column(
              children: [
                // Capçalera amb navegació de setmana
                _buildWeekHeader(provider, isDesktop),
                const SizedBox(height: 8),
                // Graella principal
                Expanded(
                  child: _buildGrid(provider, dayWidth, isDesktop),
                ),
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
            child: const Text('Avui', style: TextStyle(color: AppTheme.mostassa)),
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

  Widget _buildGrid(ScheduleProvider provider, double dayWidth, bool isDesktop) {
    return Row(
      children: [
        // Columna d'hores (fixa)
        SizedBox(
          width: timeColumnWidth,
          child: _buildTimeColumn(),
        ),
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
                children: days.map((day) {
                  return SizedBox(
                    width: dayWidth,
                    child: _buildDayColumn(day, provider, dayWidth),
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

  Widget _buildDayColumn(DateTime day, ScheduleProvider provider, double dayWidth) {
    final blocks = provider.getBlocksForDay(day);

    return Container(
      decoration: BoxDecoration(
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
          if (DateUtils.isSameDay(day, DateTime.now())) _buildCurrentTimeLine(),
          // Blocs de temps
          ...blocks.map((block) => _buildBlockWidget(block, dayWidth)),
        ],
      ),
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
          Expanded(
            child: Container(
              height: 2,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockWidget(TimeBlock block, double dayWidth) {
    // Calcular posició i alçada
    final startMinutes = (block.startAt.hour - startHour) * 60 + block.startAt.minute;
    final top = startMinutes * (hourHeight / 60);
    final height = (block.durationMinutes * (hourHeight / 60)).clamp(20.0, double.infinity);

    // Si el bloc comença abans de l'hora d'inici visible, no el mostrem
    if (block.startAt.hour < startHour) return const SizedBox();

    final isDesignation = block.source == TimeBlockSource.designation;
    final color = TimeblockCard.getCategoryColor(block.category);

    // Determinar la vora segons el tipus de bloc
    Border? border;
    if (isDesignation) {
      border = Border.all(color: Colors.orange, width: 2);
    } else if (block.isFrog) {
      border = Border.all(color: AppTheme.verdeEncert, width: 2);
    }

    return Positioned(
      top: top,
      left: 2,
      right: 2,
      height: height,
      child: GestureDetector(
        onTap: () => isDesignation ? _showDesignationInfo(block) : _openBlockEditor(block),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: block.done
                ? color.withValues(alpha: 0.3)
                : color.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(4),
            border: border,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Títol amb icona segons tipus
              Row(
                children: [
                  if (block.isFrog && !isDesignation)
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
                        decoration: block.done ? TextDecoration.lineThrough : null,
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
              // Hora (si hi ha espai)
              if (height > 35)
                Text(
                  '${_formatTime(block.startAt)} - ${_formatTime(block.endAt)}',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDesignationInfo(TimeBlock block) {
    // Navegar a la pàgina de designacions per veure més detalls
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Partit: ${block.title.replaceFirst('🏀 ', '')}'),
        action: SnackBarAction(
          label: 'Veure detalls',
          onPressed: () => Navigator.pushNamed(context, '/designations'),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _openBlockEditor(TimeBlock block) {
    showDialog(
      context: context,
      builder: (context) => TimeblockEditorDialog(
        block: block,
        isNew: false,
      ),
    );
  }
}
