import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import '../providers/schedule_provider.dart';

/// Vista del calendari setmanal amb navegació
class WeeklyCalendarView extends StatelessWidget {
  const WeeklyCalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (context, provider, child) {
        return Card(
          color: AppTheme.porpraFosc,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TableCalendar(
              locale: 'ca_ES',
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: provider.selectedDay,
              selectedDayPredicate: (day) => isSameDay(day, provider.selectedDay),
              calendarFormat: CalendarFormat.week,
              availableCalendarFormats: const {
                CalendarFormat.week: 'Setmana',
              },
              startingDayOfWeek: StartingDayOfWeek.monday,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: AppTheme.grisPistacho,
                  fontWeight: FontWeight.bold,
                ),
                leftChevronIcon: const Icon(
                  Icons.chevron_left,
                  color: AppTheme.grisPistacho,
                ),
                rightChevronIcon: const Icon(
                  Icons.chevron_right,
                  color: AppTheme.grisPistacho,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
                weekendStyle: TextStyle(
                  color: AppTheme.lilaMitja.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              calendarStyle: CalendarStyle(
                // Dia seleccionat
                selectedDecoration: const BoxDecoration(
                  color: AppTheme.mostassa,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(
                  color: AppTheme.porpraFosc,
                  fontWeight: FontWeight.bold,
                ),
                // Dia actual
                todayDecoration: BoxDecoration(
                  color: AppTheme.verdeEncert.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  color: AppTheme.verdeEncert,
                  fontWeight: FontWeight.bold,
                ),
                // Dies normals
                defaultTextStyle: const TextStyle(color: AppTheme.grisPistacho),
                weekendTextStyle: const TextStyle(color: AppTheme.lilaMitja),
                // Markers per als blocs
                markerDecoration: const BoxDecoration(
                  color: AppTheme.lilaClar,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
              ),
              // Events (blocs del dia)
              eventLoader: (day) {
                return provider.getBlocksForDay(day);
              },
              // Quan es selecciona un dia
              onDaySelected: (selectedDay, focusedDay) {
                provider.selectDay(selectedDay);
              },
              // Builder per mostrar la granota
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return null;

                  final hasFrog = provider.hasFrogForDay(day);

                  return Positioned(
                    bottom: 1,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasFrog)
                          const Text(
                            '🐸',
                            style: TextStyle(fontSize: 10),
                          )
                        else
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppTheme.lilaClar,
                              shape: BoxShape.circle,
                            ),
                          ),
                        if (events.length > 1) ...[
                          const SizedBox(width: 2),
                          Text(
                            '+${events.length - 1}',
                            style: TextStyle(
                              fontSize: 8,
                              color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
