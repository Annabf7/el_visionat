import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/mentorship_session.dart';

class MentoriaCalendar extends StatefulWidget {
  final List<String> mentoredIds;

  const MentoriaCalendar({super.key, required this.mentoredIds});

  @override
  State<MentoriaCalendar> createState() => _MentoriaCalendarState();
}

class _MentoriaCalendarState extends State<MentoriaCalendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<MentorshipSession>> _events = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('mentorship_sessions')
          .orderBy('date', descending: false)
          .get();

      final List<MentorshipSession> sessions = snapshot.docs.map((doc) {
        return MentorshipSession.fromMap(doc.data(), doc.id);
      }).toList();

      final Map<DateTime, List<MentorshipSession>> events = {};
      for (var session in sessions) {
        // Normalize date to UTC midnight for TableCalendar
        final date = DateTime.utc(
          session.date.year,
          session.date.month,
          session.date.day,
        );
        if (events[date] == null) {
          events[date] = [];
        }
        events[date]!.add(session);
      }

      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching sessions: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<MentorshipSession> _getEventsForDay(DateTime day) {
    // Normalize day to UTC midnight
    final date = DateTime.utc(day.year, day.month, day.day);
    return _events[date] ?? [];
  }

  // Helper to get display name from ID (manual or fetch)
  Future<String> _getMenteeName(String id) async {
    if (id.startsWith('manual:')) {
      final parts = id.split(':');
      if (parts.length >= 4) {
        return '${parts[2]} ${parts[3]}';
      }
      return 'Desconegut';
    } else {
      // Try to fetch from Firestore
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(id)
            .get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null && data.containsKey('displayName')) {
            return data['displayName'];
          }
        }
      } catch (e) {
        debugPrint('Error fetching name for $id: $e');
      }
      return 'Usuari App';
    }
  }

  void _showAddSessionDialog() async {
    if (widget.mentoredIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primer has d\'afegir mentoritzats a la llista.'),
          backgroundColor: AppTheme.mostassa,
        ),
      );
      return;
    }

    // Preparar llista de noms per al dropdown
    Map<String, String> namesMap = {};
    for (var id in widget.mentoredIds) {
      namesMap[id] = await _getMenteeName(id);
    }

    if (!mounted) return;

    String? selectedMenteeId = widget.mentoredIds.first;
    final notesController = TextEditingController();
    // Default time: now
    TimeOfDay selectedTime = TimeOfDay.now();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Nova Sessió',
                style: TextStyle(color: AppTheme.porpraFosc),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Programa una sessió de mentoria:',
                      style: TextStyle(color: AppTheme.grisBody),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Mentoritzat',
                        border: OutlineInputBorder(),
                      ),
                      // The 'value' property is deprecated in favor of 'initialValue' or internal state management.
                      // Since we update `selectedMenteeId` via setState, we can rely on `value` if we want to force it,
                      // but to respect the warning, we'll try setting initialValue and let the widget manage its state
                      // internally, or just rebuild with a Key if we really need to force updates.
                      // For this dialog, initialValue is sufficient.
                      initialValue: selectedMenteeId,
                      items: widget.mentoredIds.map((id) {
                        return DropdownMenuItem(
                          value: id,
                          child: Text(
                            namesMap[id] ?? 'Carregant...',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedMenteeId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Tema / Notes',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: Revisió de partit, objectius...',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Hora'),
                      trailing: Text(selectedTime.format(context)),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (time != null) {
                          setState(() {
                            selectedTime = time;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel·lar',
                    style: TextStyle(color: AppTheme.grisBody),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.porpraFosc,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (selectedMenteeId == null) return;

                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;

                    // Combine selected day with selected time
                    final DateTime baseDate = _selectedDay ?? DateTime.now();
                    final DateTime finalDate = DateTime(
                      baseDate.year,
                      baseDate.month,
                      baseDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );

                    try {
                      final newSession = {
                        'mentorId': user.uid,
                        'menteeId': selectedMenteeId,
                        'menteeName':
                            namesMap[selectedMenteeId!] ?? 'Desconegut',
                        'date': Timestamp.fromDate(finalDate),
                        'notes': notesController.text.trim(),
                        'isCompleted': false,
                      };

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('mentorship_sessions')
                          .add(newSession);

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                      await _fetchSessions(); // Refresh

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sessió programada correctament!'),
                            backgroundColor: AppTheme.verdeEncert,
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('Error adding session: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grisPistacho.withAlpha(50)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Calendari de Sessions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.porpraFosc,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _showAddSessionDialog,
                icon: const Icon(Icons.add_circle, color: AppTheme.porpraFosc),
                tooltip: 'Afegir sessió',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: AppTheme.porpraFosc),
              ),
            )
          else ...[
            TableCalendar<MentorshipSession>(
              firstDay: DateTime.utc(2023, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                }
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              eventLoader: _getEventsForDay,
              calendarStyle: CalendarStyle(
                todayDecoration: const BoxDecoration(
                  color: AppTheme.lilaMitja,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppTheme.porpraFosc,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: AppTheme.mostassa,
                  shape: BoxShape.circle,
                ),
                // Use safe area for text styles if needed
                defaultTextStyle: const TextStyle(color: AppTheme.grisBody),
                weekendTextStyle: const TextStyle(color: AppTheme.grisBody),
                outsideTextStyle: TextStyle(
                  color: AppTheme.grisPistacho.withValues(alpha: 0.5),
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              locale: 'ca_ES', // Set locale to Catalan
            ),
            const SizedBox(height: 16),
            const Divider(),
            if (_selectedDay != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  DateFormat('EEEE, d MMMM', 'ca_ES').format(_selectedDay!),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.porpraFosc,
                    fontSize: 16,
                  ),
                ),
              ),
              ..._getEventsForDay(_selectedDay!).map((event) {
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: event.isCompleted
                          ? AppTheme.verdeEncert
                          : AppTheme.lilaMitja,
                      child: Icon(
                        event.isCompleted ? Icons.check : Icons.schedule,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      event.menteeName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat('HH:mm').format(event.date)),
                        if (event.notes != null && event.notes!.isNotEmpty)
                          Text(
                            event.notes!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        event.isCompleted
                            ? Icons.undo
                            : Icons.check_circle_outline,
                        color: AppTheme.porpraFosc,
                      ),
                      onPressed: () async {
                        // Toggle completion status
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;

                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('mentorship_sessions')
                            .doc(event.id)
                            .update({'isCompleted': !event.isCompleted});

                        _fetchSessions();
                      },
                    ),
                  ),
                );
              }),
              if (_getEventsForDay(_selectedDay!).isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Cap sessió programada per aquest dia.',
                      style: TextStyle(color: AppTheme.grisBody),
                    ),
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}
