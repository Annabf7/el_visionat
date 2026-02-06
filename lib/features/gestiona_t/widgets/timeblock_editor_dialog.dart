import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import '../models/time_block.dart';
import '../providers/schedule_provider.dart';
import 'timeblock_card.dart';

/// Diàleg per crear o editar un bloc de temps
class TimeblockEditorDialog extends StatefulWidget {
  final TimeBlock block;
  final bool isNew;

  const TimeblockEditorDialog({
    super.key,
    required this.block,
    required this.isNew,
  });

  @override
  State<TimeblockEditorDialog> createState() => _TimeblockEditorDialogState();
}

class _TimeblockEditorDialogState extends State<TimeblockEditorDialog> {
  late TextEditingController _titleController;
  late TimeBlockCategory _category;
  late TimeBlockPriority _priority;
  late DateTime _startAt;
  late DateTime _endAt;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.block.title);
    _category = widget.block.category;
    _priority = widget.block.priority;
    _startAt = widget.block.startAt;
    _endAt = widget.block.endAt;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ca', 'ES'),
    );
    if (!mounted) return;
    if (date != null) {
      setState(() {
        _startAt = DateTime(
          date.year,
          date.month,
          date.day,
          _startAt.hour,
          _startAt.minute,
        );
        _endAt = DateTime(
          date.year,
          date.month,
          date.day,
          _endAt.hour,
          _endAt.minute,
        );
      });
    }
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startAt),
    );
    if (!mounted) return;
    if (time != null) {
      setState(() {
        _startAt = DateTime(
          _startAt.year,
          _startAt.month,
          _startAt.day,
          time.hour,
          time.minute,
        );
        // Ajusta l'hora de fi si és anterior a l'inici
        if (_endAt.isBefore(_startAt) || _endAt.isAtSameMomentAs(_startAt)) {
          _endAt = _startAt.add(const Duration(hours: 1));
        }
      });
    }
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endAt),
    );
    if (!mounted) return;
    if (time != null) {
      final newEndAt = DateTime(
        _endAt.year,
        _endAt.month,
        _endAt.day,
        time.hour,
        time.minute,
      );
      if (newEndAt.isAfter(_startAt)) {
        setState(() {
          _endAt = newEndAt;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("L'hora de fi ha de ser posterior a l'inici"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Has d\'escriure un títol'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final newBlock = widget.block.copyWith(
      title: _titleController.text.trim(),
      category: _category,
      priority: _priority,
      startAt: _startAt,
      endAt: _endAt,
    );

    final provider = context.read<ScheduleProvider>();
    bool success;

    if (widget.isNew) {
      final id = await provider.createBlock(newBlock);
      success = id != null;
    } else {
      success = await provider.updateBlock(newBlock);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context);
    } else if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: Colors.redAccent,
        ),
      );
      provider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat("EEE, d MMM", 'ca_ES');
    final timeFormat = DateFormat('HH:mm', 'ca_ES');

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Títol del diàleg
                Text(
                  widget.isNew ? 'Nou bloc' : 'Editar bloc',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),

                // Camp del títol
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Títol',
                    hintText: 'Què has de fer?',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: widget.isNew,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),

                // Selecció de categoria
                Text(
                  'Categoria',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TimeBlockCategory.values.map((cat) {
                    final isSelected = _category == cat;
                    final color = TimeblockCard.getCategoryColor(cat);
                    return ChoiceChip(
                      label: Text(TimeblockCard.getCategoryName(cat)),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _category = cat);
                      },
                      selectedColor: color.withValues(alpha: 0.3),
                      labelStyle: TextStyle(
                        color: isSelected ? color : AppTheme.grisPistacho,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Selecció de prioritat
                Text(
                  'Prioritat',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TimeBlockPriority.values.map((pri) {
                    final isSelected = _priority == pri;
                    return ChoiceChip(
                      label: Text(TimeblockCard.getPriorityName(pri)),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _priority = pri);
                      },
                      selectedColor: pri == TimeBlockPriority.frog
                          ? AppTheme.verdeEncert.withValues(alpha: 0.3)
                          : AppTheme.mostassa.withValues(alpha: 0.3),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Selecció de data i hora
                Text(
                  'Quan',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Data
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectDate,
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(dateFormat.format(_startAt)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Hora inici
                    OutlinedButton(
                      onPressed: _selectStartTime,
                      child: Text(timeFormat.format(_startAt)),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('-'),
                    ),
                    // Hora fi
                    OutlinedButton(
                      onPressed: _selectEndTime,
                      child: Text(timeFormat.format(_endAt)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Duració
                Text(
                  'Duració: ${_endAt.difference(_startAt).inMinutes} minuts',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 24),

                // Botons d'acció
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel·lar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.isNew ? 'Crear' : 'Desar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
