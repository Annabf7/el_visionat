import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
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
  late bool _isRecurring;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.block.title);
    _category = widget.block.category;
    _priority = widget.block.priority;
    _startAt = widget.block.startAt;
    _endAt = widget.block.endAt;
    _isRecurring = widget.block.isRecurring;
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

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar bloc'),
        content: const Text('Segur que vols eliminar aquest bloc?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel·lar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.mostassa),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final provider = context.read<ScheduleProvider>();
    final success = await provider.deleteBlock(widget.block.id!);

    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    }
  }

  Future<void> _openMap(String address) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error obrint mapa: $e');
    }
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Error trucant: $e');
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

    final isRecurring = _isRecurring;
    final newBlock = widget.block.copyWith(
      title: _titleController.text.trim(),
      category: _category,
      priority: _priority,
      startAt: _startAt,
      endAt: _endAt,
      isRecurring: isRecurring,
      recurringId: isRecurring
          ? (widget.block.recurringId ??
                DateTime.now().millisecondsSinceEpoch.toString())
          : null,
    );

    final provider = context.read<ScheduleProvider>();
    bool success;

    if (widget.isNew) {
      if (isRecurring) {
        success = await provider.createWeeklyBlocks(newBlock);
      } else {
        final id = await provider.createBlock(newBlock);
        success = id != null;
      }
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
    final dateFormat = DateFormat("d MMM", 'ca_ES');
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
                // Títol del diàleg + botó eliminar
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.isNew ? 'Nou bloc' : 'Editar bloc',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (!widget.isNew)
                      IconButton(
                        onPressed: _isSaving ? null : _delete,
                        icon: const Icon(Icons.delete_outline),
                        color: AppTheme.mostassa,
                        tooltip: 'Eliminar bloc',
                      ),
                  ],
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

                // Informació extra per a designacions
                if (widget.block.source == TimeBlockSource.designation) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.lilaClar.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.lilaMitja.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detalls del partit',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.grisPistacho,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Categoria i Rol
                        if (widget.block.matchCategory != null ||
                            widget.block.refereeRole != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.sports_basketball,
                                  size: 14,
                                  color: AppTheme.lilaMitja,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    [
                                      if (widget.block.matchCategory != null)
                                        widget.block.matchCategory,
                                      if (widget.block.refereeRole != null)
                                        widget.block.refereeRole == 'principal'
                                            ? 'Principal'
                                            : 'Auxiliar',
                                    ].join(' • '),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Company/a
                        if (widget.block.refereePartner != null &&
                            widget.block.refereePartner!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.person,
                                    size: 14,
                                    color: AppTheme.lilaMitja,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Company/a: ${widget.block.refereePartner}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      if (widget.block.refereePartnerPhone !=
                                          null)
                                        InkWell(
                                          onTap: () => _callPhone(
                                            widget.block.refereePartnerPhone!,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.phone,
                                                  size: 12,
                                                  color: AppTheme.mostassa,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  widget
                                                      .block
                                                      .refereePartnerPhone!,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppTheme.mostassa,
                                                    decoration: TextDecoration
                                                        .underline,
                                                  ),
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
                        // Adreça / Mapa
                        if (widget.block.location != null ||
                            widget.block.address != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: InkWell(
                              onTap: () {
                                if (widget.block.address != null ||
                                    widget.block.location != null) {
                                  _openMap(
                                    widget.block.address ??
                                        widget.block.location!,
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: AppTheme.mostassa,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (widget.block.location != null)
                                          Text(
                                            widget.block.location!,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.grisPistacho,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        if (widget.block.address != null)
                                          Text(
                                            widget.block.address!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.mostassa,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

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
                    final isGym = cat == TimeBlockCategory.gimnas;
                    return ChoiceChip(
                      avatar: isGym && isSelected
                          ? Icon(Icons.fitness_center, size: 14, color: color)
                          : null,
                      label: Text(
                        isGym ? 'In Shape' : TimeblockCard.getCategoryName(cat),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _category = cat);
                        }
                      },
                      selectedColor: color.withValues(alpha: 0.3),
                      labelStyle: const TextStyle(
                        color: AppTheme.grisPistacho,
                        fontWeight: FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),

                // Toggle bloc fix setmanal (per blocs nous de qualsevol categoria)
                if (widget.isNew) ...[
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Bloc fix setmanal'),
                    subtitle: const Text(
                      'Es crearà de dilluns a divendres al mateix horari',
                    ),
                    value: _isRecurring,
                    onChanged: (value) => setState(() => _isRecurring = value),
                    activeTrackColor: AppTheme.verdeEncert.withValues(
                      alpha: 0.5,
                    ),
                    thumbColor: WidgetStatePropertyAll(AppTheme.verdeEncert),
                    secondary: const Icon(
                      Icons.repeat,
                      color: AppTheme.verdeEncert,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.grisPistacho,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Data
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectDate,
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          dateFormat.format(_startAt),
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.grisPistacho,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Hora inici
                    OutlinedButton(
                      onPressed: _selectStartTime,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.grisPistacho,
                      ),
                      child: Text(timeFormat.format(_startAt)),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('-'),
                    ),
                    // Hora fi
                    OutlinedButton(
                      onPressed: _selectEndTime,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.grisPistacho,
                      ),
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
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.grisPistacho,
                      ),
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
