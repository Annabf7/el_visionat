import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import '../models/time_block.dart';
import '../providers/schedule_provider.dart';
import 'timeblock_card.dart';

/// Bottom sheet "Planifica demà" amb 3 passos
class NightlyPlannerSheet extends StatefulWidget {
  const NightlyPlannerSheet({super.key});

  @override
  State<NightlyPlannerSheet> createState() => _NightlyPlannerSheetState();
}

class _NightlyPlannerSheetState extends State<NightlyPlannerSheet> {
  int _currentStep = 0;
  bool _isSaving = false;

  // Pas 1: La granota
  final TextEditingController _frogTitleController = TextEditingController();
  TimeBlockCategory _frogCategory = TimeBlockCategory.feina;
  int _frogDuration = 60; // minuts

  // Pas 2: Tasques secundàries
  final List<_SecondaryTask> _secondaryTasks = [];

  // Pas 3: Horaris proposats
  DateTime _frogStartTime = DateTime.now();
  final Map<int, DateTime> _taskStartTimes = {};

  @override
  void initState() {
    super.initState();
    _initializeDefaultTimes();
  }

  void _initializeDefaultTimes() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _frogStartTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
  }

  @override
  void dispose() {
    _frogTitleController.dispose();
    for (final task in _secondaryTasks) {
      task.controller.dispose();
    }
    super.dispose();
  }

  void _addSecondaryTask() {
    if (_secondaryTasks.length >= 3) return;
    setState(() {
      _secondaryTasks.add(_SecondaryTask(
        controller: TextEditingController(),
        category: TimeBlockCategory.feina,
        priority: TimeBlockPriority.alta,
        duration: 30,
      ));
    });
  }

  void _removeSecondaryTask(int index) {
    setState(() {
      _secondaryTasks[index].controller.dispose();
      _secondaryTasks.removeAt(index);
    });
  }

  void _nextStep() {
    if (_currentStep == 0 && _frogTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Has d\'escriure la teva granota del dia!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
        if (_currentStep == 2) {
          _calculateProposedTimes();
        }
      });
    } else {
      _saveAllBlocks();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _calculateProposedTimes() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    var currentTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);

    // Assigna hora a la granota
    _frogStartTime = currentTime;
    currentTime = currentTime.add(Duration(minutes: _frogDuration + 15)); // +15 min pausa

    // Assigna hores a les tasques secundàries
    for (int i = 0; i < _secondaryTasks.length; i++) {
      _taskStartTimes[i] = currentTime;
      currentTime = currentTime.add(Duration(minutes: _secondaryTasks[i].duration + 10));
    }
  }

  Future<void> _saveAllBlocks() async {
    setState(() => _isSaving = true);

    final provider = context.read<ScheduleProvider>();
    bool allSuccess = true;

    // Crear la granota
    final frogBlock = TimeBlock(
      title: _frogTitleController.text.trim(),
      category: _frogCategory,
      priority: TimeBlockPriority.frog,
      startAt: _frogStartTime,
      endAt: _frogStartTime.add(Duration(minutes: _frogDuration)),
      source: TimeBlockSource.nightlyPlanner,
    );

    final frogId = await provider.createBlock(frogBlock);
    if (frogId == null) allSuccess = false;

    // Crear les tasques secundàries
    for (int i = 0; i < _secondaryTasks.length; i++) {
      final task = _secondaryTasks[i];
      if (task.controller.text.trim().isEmpty) continue;

      final startTime = _taskStartTimes[i] ?? _frogStartTime.add(Duration(minutes: _frogDuration + 15 + (i * 45)));

      final taskBlock = TimeBlock(
        title: task.controller.text.trim(),
        category: task.category,
        priority: task.priority,
        startAt: startTime,
        endAt: startTime.add(Duration(minutes: task.duration)),
        source: TimeBlockSource.nightlyPlanner,
      );

      final taskId = await provider.createBlock(taskBlock);
      if (taskId == null) allSuccess = false;
    }

    setState(() => _isSaving = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            allSuccess
                ? '✅ Demà planificat correctament!'
                : '⚠️ Alguns blocs no s\'han pogut crear',
          ),
          backgroundColor: allSuccess ? AppTheme.verdeEncert : Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final dateFormat = DateFormat("EEEE, d 'de' MMMM", 'ca_ES');

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.grisBody,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.grisPistacho.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Títol
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('🌙', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Planifica demà',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          dateFormat.format(tomorrow),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // Indicador de pas
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: List.generate(3, (index) {
                    final isActive = index <= _currentStep;
                    final isCurrent = index == _currentStep;
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: isActive
                              ? (isCurrent ? AppTheme.mostassa : AppTheme.verdeEncert)
                              : AppTheme.grisPistacho.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              // Contingut del pas
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: _buildCurrentStep(),
                ),
              ),
              // Botons de navegació
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      TextButton.icon(
                        onPressed: _previousStep,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Anterior'),
                      ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _nextStep,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(_currentStep == 2 ? Icons.check : Icons.arrow_forward),
                      label: Text(_currentStep == 2 ? 'Confirmar' : 'Següent'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildFrogStep();
      case 1:
        return _buildSecondaryTasksStep();
      case 2:
        return _buildScheduleStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildFrogStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Explicació
        Card(
          color: AppTheme.verdeEncert.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('🐸', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tria la teva granota!',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.verdeEncert,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'La tasca més important del dia. Fes-la primer!',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Títol de la granota
        TextField(
          controller: _frogTitleController,
          decoration: const InputDecoration(
            labelText: 'Què és el més important de demà?',
            hintText: 'Ex: Preparar la formació arbitral',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.star),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 16),

        // Categoria
        Text('Categoria', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TimeBlockCategory.values.map((cat) {
            final isSelected = _frogCategory == cat;
            final color = TimeblockCard.getCategoryColor(cat);
            return ChoiceChip(
              label: Text(TimeblockCard.getCategoryName(cat)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _frogCategory = cat);
              },
              selectedColor: color.withValues(alpha: 0.3),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Duració estimada
        Text('Duració estimada', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [30, 45, 60, 90, 120].map((mins) {
            final isSelected = _frogDuration == mins;
            return ChoiceChip(
              label: Text('$mins min'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _frogDuration = mins);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSecondaryTasksStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Explicació
        Card(
          color: AppTheme.mostassa.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.list_alt, size: 32, color: AppTheme.mostassa),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tasques secundàries',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.mostassa,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Afegeix 2-3 tasques més per completar el dia',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Llista de tasques
        ..._secondaryTasks.asMap().entries.map((entry) {
          final index = entry.key;
          final task = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Tasca ${index + 1}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _removeSecondaryTask(index),
                        color: Colors.redAccent,
                      ),
                    ],
                  ),
                  TextField(
                    controller: task.controller,
                    decoration: const InputDecoration(
                      hintText: 'Què has de fer?',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Categoria
                      Expanded(
                        child: DropdownButtonFormField<TimeBlockCategory>(
                          key: ValueKey('cat_${index}_${task.category}'),
                          initialValue: task.category,
                          decoration: const InputDecoration(
                            labelText: 'Categoria',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          items: TimeBlockCategory.values.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text(TimeblockCard.getCategoryName(cat)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => task.category = value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Duració
                      SizedBox(
                        width: 100,
                        child: DropdownButtonFormField<int>(
                          key: ValueKey('dur_${index}_${task.duration}'),
                          initialValue: task.duration,
                          decoration: const InputDecoration(
                            labelText: 'Minuts',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          items: [15, 30, 45, 60].map((mins) {
                            return DropdownMenuItem(
                              value: mins,
                              child: Text('$mins'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => task.duration = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),

        // Botó per afegir
        if (_secondaryTasks.length < 3)
          Center(
            child: TextButton.icon(
              onPressed: _addSecondaryTask,
              icon: const Icon(Icons.add),
              label: const Text('Afegir tasca'),
            ),
          ),

        if (_secondaryTasks.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Pots saltar aquest pas si només vols planificar la granota',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildScheduleStep() {
    final timeFormat = DateFormat('HH:mm', 'ca_ES');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Explicació
        Card(
          color: AppTheme.lilaMitja.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.schedule, size: 32, color: AppTheme.lilaMitja),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Revisa els horaris',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.lilaMitja,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Toca per ajustar les hores si cal',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Granota
        Card(
          color: AppTheme.verdeEncert.withValues(alpha: 0.1),
          child: ListTile(
            leading: const Text('🐸', style: TextStyle(fontSize: 24)),
            title: Text(_frogTitleController.text),
            subtitle: Text(
              '${timeFormat.format(_frogStartTime)} - ${timeFormat.format(_frogStartTime.add(Duration(minutes: _frogDuration)))} · $_frogDuration min',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_frogStartTime),
                );
                if (time != null) {
                  setState(() {
                    _frogStartTime = DateTime(
                      _frogStartTime.year,
                      _frogStartTime.month,
                      _frogStartTime.day,
                      time.hour,
                      time.minute,
                    );
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Tasques secundàries
        ..._secondaryTasks.asMap().entries.map((entry) {
          final index = entry.key;
          final task = entry.value;
          final startTime = _taskStartTimes[index] ?? _frogStartTime.add(const Duration(hours: 2));

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: TimeblockCard.getCategoryColor(task.category),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              title: Text(task.controller.text),
              subtitle: Text(
                '${timeFormat.format(startTime)} - ${timeFormat.format(startTime.add(Duration(minutes: task.duration)))} · ${task.duration} min',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(startTime),
                  );
                  if (time != null) {
                    setState(() {
                      _taskStartTimes[index] = DateTime(
                        startTime.year,
                        startTime.month,
                        startTime.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                },
              ),
            ),
          );
        }),

        const SizedBox(height: 24),
        Center(
          child: Text(
            'Es crearan ${1 + _secondaryTasks.where((t) => t.controller.text.isNotEmpty).length} blocs',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.grisPistacho.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }
}

/// Classe auxiliar per a les tasques secundàries
class _SecondaryTask {
  final TextEditingController controller;
  TimeBlockCategory category;
  TimeBlockPriority priority;
  int duration;

  _SecondaryTask({
    required this.controller,
    required this.category,
    required this.priority,
    required this.duration,
  });
}
