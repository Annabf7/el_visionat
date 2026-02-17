import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/mentorship_session.dart';
import '../services/google_calendar_service.dart';

class MentoriaCalendar extends StatefulWidget {
  final List<String> mentoredIds;
  final Set<String> selectedTopics;

  const MentoriaCalendar({
    super.key,
    required this.mentoredIds,
    this.selectedTopics = const {},
  });

  @override
  State<MentoriaCalendar> createState() => _MentoriaCalendarState();
}

class _MentoriaCalendarState extends State<MentoriaCalendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<MentorshipSession>> _events = {};
  bool _isLoading = true;
  final GoogleCalendarService _calendarService = GoogleCalendarService();

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

    // Valors per defecte
    DateTime selectedDate = _selectedDay ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    Duration selectedDuration = const Duration(hours: 1);
    bool createMeet = false;
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: !isSaving,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Nova Sessió',
                style: TextStyle(color: AppTheme.mostassa),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Mentoritzat',
                        prefixIcon: Icon(
                          Icons.person,
                          color: AppTheme.porpraFosc,
                        ),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                      ),
                      value: selectedMenteeId,
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
                        prefixIcon: Icon(
                          Icons.edit_note,
                          color: AppTheme.porpraFosc,
                        ),
                        border: OutlineInputBorder(),
                        hintText: 'Ex: Revisió de partit...',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    // Fila Data i Hora
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 365),
                                ),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                                locale: const Locale('ca', 'ES'),
                              );
                              if (picked != null) {
                                setState(() => selectedDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Data',
                                prefixIcon: Icon(
                                  Icons.calendar_today,
                                  size: 18,
                                  color: AppTheme.porpraFosc,
                                ),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 8,
                                ),
                              ),
                              child: Text(
                                DateFormat('dd/MM/yyyy').format(selectedDate),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (picked != null) {
                                setState(() => selectedTime = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Hora',
                                prefixIcon: Icon(
                                  Icons.access_time,
                                  size: 18,
                                  color: AppTheme.porpraFosc,
                                ),
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 8,
                                ),
                              ),
                              child: Text(
                                selectedTime.format(context),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Durada
                    DropdownButtonFormField<Duration>(
                      decoration: const InputDecoration(
                        labelText: 'Durada estimada',
                        prefixIcon: Icon(
                          Icons.timer_outlined,
                          color: AppTheme.porpraFosc,
                        ),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                      ),
                      value: selectedDuration,
                      items: [
                        const DropdownMenuItem(
                          value: Duration(minutes: 30),
                          child: Text('30 min'),
                        ),
                        const DropdownMenuItem(
                          value: Duration(minutes: 45),
                          child: Text('45 min'),
                        ),
                        const DropdownMenuItem(
                          value: Duration(hours: 1),
                          child: Text('1 hora'),
                        ),
                        const DropdownMenuItem(
                          value: Duration(hours: 1, minutes: 30),
                          child: Text('1h 30min'),
                        ),
                        const DropdownMenuItem(
                          value: Duration(hours: 2),
                          child: Text('2 hores'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => selectedDuration = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text(
                        'Crear reunió de Google Meet',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: const Text(
                        'S\'afegirà al teu calendari i es guardarà l\'enllaç.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      value: createMeet,
                      activeColor: AppTheme.porpraFosc,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => createMeet = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Cancel·lar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.porpraFosc,
                    foregroundColor: AppTheme.mostassa, // Canviat a Mostassa
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (selectedMenteeId == null) return;
                          setState(() => isSaving = true);

                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            setState(() => isSaving = false);
                            return;
                          }

                          // Combinar data seleccionada i hora
                          final DateTime finalStart = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );
                          final DateTime finalEnd = finalStart.add(
                            selectedDuration,
                          );

                          try {
                            String? meetLink;
                            String? googleEventId;

                            if (createMeet) {
                              try {
                                final result = await _calendarService
                                    .createMeetEvent(
                                      title:
                                          'Mentoria: ${namesMap[selectedMenteeId] ?? 'Mentee'}',
                                      description:
                                          notesController.text.trim().isEmpty
                                          ? 'Sessió de mentoria'
                                          : notesController.text.trim(),
                                      startTime: finalStart,
                                      endTime: finalEnd,
                                    );

                                if (result != null) {
                                  meetLink = result['meetLink'];
                                  googleEventId = result['eventId'];
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'No s\'ha pogut connectar amb Google. Revisa popups/permisos.',
                                        ),
                                        backgroundColor: AppTheme.mostassa,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                debugPrint('Error Google: $e');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Error tècnic creant Meet. Es guardarà sense reunió.',
                                      ),
                                      backgroundColor: AppTheme.mostassa,
                                    ),
                                  );
                                }
                              }
                            }

                            final newSession = {
                              'mentorId': user.uid,
                              'menteeId': selectedMenteeId,
                              'menteeName':
                                  namesMap[selectedMenteeId!] ?? 'Desconegut',
                              'date': Timestamp.fromDate(finalStart),
                              'notes': notesController.text.trim(),
                              'isCompleted': false,
                              'meetLink': meetLink,
                              'googleEventId': googleEventId,
                            };

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .collection('mentorship_sessions')
                                .add(newSession);

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    meetLink != null
                                        ? 'Sessió i Meet creats correctament!'
                                        : 'Sessió programada correctament!',
                                  ),
                                  backgroundColor: AppTheme.verdeEncert,
                                ),
                              );
                            }
                            await _fetchSessions();
                          } catch (e) {
                            debugPrint('Error adding session: $e');
                            if (context.mounted) {
                              setState(() => isSaving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Error guardant sessió. Prova-ho més tard.',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.mostassa,
                          ),
                        )
                      : const Text('Guardar'),
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
                        if (event.meetLink != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 4.0,
                              bottom: 4.0,
                            ),
                            child: InkWell(
                              onTap: () async {
                                final uri = Uri.parse(event.meetLink!);
                                try {
                                  if (!await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  )) {
                                    throw 'Could not launch $uri';
                                  }
                                } catch (e) {
                                  debugPrint('Error launching URL: $e');
                                }
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.video_camera_front,
                                    size: 18,
                                    color: AppTheme.mostassa,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Unir-se a Google Meet',
                                    style: TextStyle(
                                      color: AppTheme.mostassa,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (event.notes != null && event.notes!.isNotEmpty)
                          Text(
                            event.notes!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.grisBody,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.playlist_add,
                            color: AppTheme.mostassa,
                          ),
                          tooltip: 'Afegir temes seleccionats',
                          onPressed: () async {
                            if (widget.selectedTopics.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Selecciona primer els temes del panell lateral.',
                                  ),
                                  backgroundColor: AppTheme.mostassa,
                                ),
                              );
                              return;
                            }

                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Afegir temes a la sessió?'),
                                content: Text(
                                  'S\'afegiran els següents temes a la sessió:\n\n- ${widget.selectedTopics.join('\n- ')}\n\nTambé s\'actualitzarà l\'esdeveniment de Google Calendar si existeix.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel·lar'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      'Afegir',
                                      style: TextStyle(
                                        color: AppTheme.porpraFosc,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null) return;

                              final currentNotes = event.notes ?? '';
                              final newTopicsStr =
                                  '\n\nTemes tractats:\n- ${widget.selectedTopics.join('\n- ')}';
                              final updatedNotes = '$currentNotes$newTopicsStr'
                                  .trim();

                              // 1. Update Firestore
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .collection('mentorship_sessions')
                                  .doc(event.id)
                                  .update({'notes': updatedNotes});

                              // 2. Update Google Calendar
                              if (event.googleEventId != null) {
                                final success = await _calendarService
                                    .updateEventDescription(
                                      eventId: event.googleEventId!,
                                      description: updatedNotes,
                                    );
                                if (!success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'No s\'ha pogut actualitzar Google Calendar, però s\'ha guardat a l\'app.',
                                      ),
                                      backgroundColor: AppTheme.mostassa,
                                    ),
                                  );
                                }
                              }

                              _fetchSessions();

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Temes afegits correctament!',
                                    ),
                                    backgroundColor: AppTheme.verdeEncert,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            event.isCompleted
                                ? Icons.undo
                                : Icons.check_circle_outline,
                            color: event.isCompleted
                                ? AppTheme.grisPistacho
                                : AppTheme.mostassa,
                          ),
                          tooltip: event.isCompleted
                              ? 'Marcar com pendent'
                              : 'Marcar com completada',
                          onPressed: () async {
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
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          tooltip: 'Eliminar sessió',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Eliminar sessió?'),
                                content: const Text(
                                  'Aquesta acció només elimina la sessió de l\'app. Si hi ha una reunió de Google Meet, l\'hauràs d\'esborrar manualment del teu calendari.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel·lar'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      'Eliminar',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null) return;

                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .collection('mentorship_sessions')
                                  .doc(event.id)
                                  .delete();

                              _fetchSessions();

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Sessió eliminada'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
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
