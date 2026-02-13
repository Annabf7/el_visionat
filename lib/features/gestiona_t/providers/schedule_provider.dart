import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/time_block.dart';
import '../services/schedule_service.dart';
import 'package:el_visionat/features/designations/repositories/designations_repository.dart';
import 'package:el_visionat/features/designations/models/designation_model.dart';

/// Provider per gestionar l'estat de la planificació
class ScheduleProvider with ChangeNotifier {
  final ScheduleService _service = ScheduleService();
  final DesignationsRepository _designationsRepo = DesignationsRepository();

  String? _userId;
  DateTime _selectedDay = DateTime.now();
  DateTime _weekStart = _getWeekStart(DateTime.now());
  List<TimeBlock> _weekBlocks = [];
  List<TimeBlock> _designationBlocks = []; // Blocs generats de designacions
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<TimeBlock>>? _weekSubscription;
  StreamSubscription<List<DesignationModel>>? _designationsSubscription;

  // Getters
  String? get userId => _userId;
  DateTime get selectedDay => _selectedDay;
  DateTime get weekStart => _weekStart;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Retorna tots els blocs de la setmana (manuals + designacions)
  List<TimeBlock> get weekBlocks => [..._weekBlocks, ..._designationBlocks];

  /// Blocs del dia seleccionat (incloent designacions)
  List<TimeBlock> get selectedDayBlocks {
    return weekBlocks.where((block) {
      final blockDay = DateTime(
        block.startAt.year,
        block.startAt.month,
        block.startAt.day,
      );
      final selectedDayStart = DateTime(
        _selectedDay.year,
        _selectedDay.month,
        _selectedDay.day,
      );
      return blockDay.isAtSameMomentAs(selectedDayStart);
    }).toList()..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  /// Calcula l'inici de la setmana (dilluns)
  static DateTime _getWeekStart(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  /// Inicialitza el provider amb l'ID d'usuari
  void initialize(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    _subscribeToWeek();
  }

  /// Subscriu als canvis de la setmana actual (blocs manuals i designacions)
  void _subscribeToWeek() {
    if (_userId == null) return;

    _weekSubscription?.cancel();
    _designationsSubscription?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Subscriu als blocs manuals
    _weekSubscription = _service
        .getBlocksForWeek(_userId!, _weekStart)
        .listen(
          (blocks) {
            _weekBlocks = blocks;
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (e) {
            _error = 'Error carregant els blocs: $e';
            _isLoading = false;
            notifyListeners();
          },
        );

    // Subscriu a les designacions de la setmana
    final weekEnd = _weekStart.add(const Duration(days: 7));
    _designationsSubscription = _designationsRepo
        .getDesignationsByPeriod(startDate: _weekStart, endDate: weekEnd)
        .listen(
          (designations) {
            _designationBlocks = designations
                .map(_designationToTimeBlock)
                .toList();
            notifyListeners();
          },
          onError: (e) {
            // No mostrar error si falla les designacions, no és crític
            debugPrint('Error carregant designacions: $e');
          },
        );
  }

  /// Converteix una designació a un TimeBlock
  TimeBlock _designationToTimeBlock(DesignationModel designation) {
    // Les designacions duren 1h 45m (105 minuts) per evitar solapaments en partits consecutius
    final endAt = designation.date.add(const Duration(hours: 1, minutes: 45));
    final roleText = designation.role == 'principal' ? '(P)' : '(A)';

    return TimeBlock(
      id: 'designation_${designation.id}', // Prefix per identificar-lo
      title:
          '🏀 $roleText ${designation.localTeam} vs ${designation.visitantTeam}',
      category: TimeBlockCategory.arbitratge,
      priority: TimeBlockPriority.alta,
      startAt: designation.date,
      endAt: endAt,
      source: TimeBlockSource.designation,
      done: designation.date.isBefore(
        DateTime.now(),
      ), // Marcat com a fet si ja ha passat
      location: designation.location,
      address: designation.locationAddress,
      matchCategory: designation.category,
      refereePartner: designation.refereePartner,
      refereePartnerPhone: designation.refereePartnerPhone,
      refereeRole: designation.role,
    );
  }

  /// Crea blocs de dilluns a divendres a la setmana del bloc donat
  Future<bool> createWeeklyBlocks(TimeBlock template) async {
    if (_userId == null) return false;
    try {
      final recurringId = DateTime.now().millisecondsSinceEpoch.toString();
      final weekStart = _getWeekStart(template.startAt);

      for (int dayOffset = 0; dayOffset < 5; dayOffset++) {
        final targetDate = weekStart.add(Duration(days: dayOffset));

        final block = TimeBlock(
          title: template.title,
          category: template.category,
          priority: template.priority,
          startAt: DateTime(
            targetDate.year,
            targetDate.month,
            targetDate.day,
            template.startAt.hour,
            template.startAt.minute,
          ),
          endAt: DateTime(
            targetDate.year,
            targetDate.month,
            targetDate.day,
            template.endAt.hour,
            template.endAt.minute,
          ),
          source: template.source,
          isRecurring: true,
          recurringId: recurringId,
        );

        await _service.createBlock(_userId!, block);
      }
      return true;
    } catch (e) {
      _error = 'Error creant els blocs setmanals: $e';
      notifyListeners();
      return false;
    }
  }

  /// Selecciona un dia
  void selectDay(DateTime day) {
    _selectedDay = day;

    // Si el dia seleccionat està fora de la setmana visible, canvia de setmana
    final newWeekStart = _getWeekStart(day);
    if (!newWeekStart.isAtSameMomentAs(_weekStart)) {
      _weekStart = newWeekStart;
      _subscribeToWeek();
    } else {
      notifyListeners();
    }
  }

  /// Navega entre setmanes (-1 anterior, +1 següent)
  void navigateWeek(int delta) {
    _weekStart = _weekStart.add(Duration(days: 7 * delta));
    // Actualitza el dia seleccionat si cal
    if (delta < 0) {
      _selectedDay = _weekStart.add(const Duration(days: 6));
    } else {
      _selectedDay = _weekStart;
    }
    _subscribeToWeek();
  }

  /// Crea un nou bloc
  Future<String?> createBlock(TimeBlock block) async {
    if (_userId == null) return null;
    try {
      // Valida que no hi hagi més d'una granota per dia
      if (block.isFrog) {
        final hasFrog = await _service.hasFrogForDay(_userId!, block.startAt);
        if (hasFrog) {
          _error = 'Ja tens una granota per aquest dia!';
          notifyListeners();
          return null;
        }
      }
      return await _service.createBlock(_userId!, block);
    } catch (e) {
      _error = 'Error creant el bloc: $e';
      notifyListeners();
      return null;
    }
  }

  /// Actualitza un bloc
  Future<bool> updateBlock(TimeBlock block) async {
    if (_userId == null) return false;
    try {
      // Valida que no hi hagi més d'una granota per dia
      if (block.isFrog) {
        final hasFrog = await _service.hasFrogForDay(
          _userId!,
          block.startAt,
          excludeBlockId: block.id,
        );
        if (hasFrog) {
          _error = 'Ja tens una granota per aquest dia!';
          notifyListeners();
          return false;
        }
      }
      await _service.updateBlock(_userId!, block);
      return true;
    } catch (e) {
      _error = 'Error actualitzant el bloc: $e';
      notifyListeners();
      return false;
    }
  }

  /// Elimina un bloc
  Future<bool> deleteBlock(String blockId) async {
    if (_userId == null) return false;
    try {
      await _service.deleteBlock(_userId!, blockId);
      return true;
    } catch (e) {
      _error = 'Error eliminant el bloc: $e';
      notifyListeners();
      return false;
    }
  }

  /// Canvia l'estat de completat d'un bloc
  Future<bool> toggleBlockDone(String blockId) async {
    if (_userId == null) return false;
    // No permetre canviar l'estat de blocs de designacions
    if (blockId.startsWith('designation_')) {
      return false;
    }
    try {
      final block = _weekBlocks.firstWhere((b) => b.id == blockId);
      await _service.toggleDone(_userId!, blockId, !block.done);
      return true;
    } catch (e) {
      _error = 'Error canviant l\'estat: $e';
      notifyListeners();
      return false;
    }
  }

  /// Obté la granota d'avui
  TimeBlock? getTodayFrog() {
    final today = DateTime.now();
    return weekBlocks.cast<TimeBlock?>().firstWhere((block) {
      if (block == null || !block.isFrog) return false;
      final blockDay = DateTime(
        block.startAt.year,
        block.startAt.month,
        block.startAt.day,
      );
      final todayStart = DateTime(today.year, today.month, today.day);
      return blockDay.isAtSameMomentAs(todayStart);
    }, orElse: () => null);
  }

  /// Obté el resum setmanal (només blocs manuals, no designacions)
  Map<String, dynamic> getWeeklySummary() {
    final manualBlocks = _weekBlocks; // Només blocs manuals
    final total = manualBlocks.length;
    final done = manualBlocks.where((b) => b.done).length;
    final gymMinutes = manualBlocks
        .where((b) => b.category == TimeBlockCategory.gimnas && b.done)
        .fold<int>(0, (sum, b) => sum + b.durationMinutes);
    final gymBlockCount = manualBlocks
        .where((b) => b.category == TimeBlockCategory.gimnas)
        .length;
    final frogsCompleted = manualBlocks.where((b) => b.isFrog && b.done).length;
    final frogsTotal = manualBlocks.where((b) => b.isFrog).length;
    final designationsCount = _designationBlocks.length;

    return {
      'total': total,
      'done': done,
      'percentage': total > 0 ? (done / total * 100).round() : 0,
      'gymMinutes': gymMinutes,
      'gymBlockCount': gymBlockCount,
      'gymGoalMet': gymBlockCount >= 3,
      'frogsCompleted': frogsCompleted,
      'frogsTotal': frogsTotal,
      'designationsCount': designationsCount,
    };
  }

  /// Obté els blocs d'un dia específic (per al calendari)
  List<TimeBlock> getBlocksForDay(DateTime day) {
    return weekBlocks.where((block) {
      final blockDay = DateTime(
        block.startAt.year,
        block.startAt.month,
        block.startAt.day,
      );
      final dayStart = DateTime(day.year, day.month, day.day);
      return blockDay.isAtSameMomentAs(dayStart);
    }).toList();
  }

  /// Comprova si un dia té blocs
  bool hasBlocsForDay(DateTime day) {
    return getBlocksForDay(day).isNotEmpty;
  }

  /// Comprova si un dia té una granota
  bool hasFrogForDay(DateTime day) {
    return getBlocksForDay(day).any((b) => b.isFrog);
  }

  /// Comprova si un dia té designacions
  bool hasDesignationForDay(DateTime day) {
    return getBlocksForDay(
      day,
    ).any((b) => b.source == TimeBlockSource.designation);
  }

  /// Neteja l'error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _weekSubscription?.cancel();
    _designationsSubscription?.cancel();
    super.dispose();
  }
}
