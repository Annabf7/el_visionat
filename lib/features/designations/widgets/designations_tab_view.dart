import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

import '../../../core/theme/app_theme.dart';
import '../models/designation_model.dart';
import '../repositories/designations_repository.dart';

/// Widget que mostra l'historial de designacions per període
class DesignationsTabView extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;

  const DesignationsTabView({super.key, this.startDate, this.endDate});

  @override
  Widget build(BuildContext context) {
    final repository = DesignationsRepository();

    return StreamBuilder<List<DesignationModel>>(
      stream: startDate != null && endDate != null
          ? repository.getDesignationsByPeriod(
              startDate: startDate!,
              endDate: endDate!,
            )
          : repository.getDesignations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Error carregant designacions: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final designations = snapshot.data ?? [];

        if (designations.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppTheme.grisPistacho.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.sports_basketball_outlined,
                      size: 72,
                      color: AppTheme.grisBody.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Encara no tens designacions',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.textBlackLow,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Puja el teu primer PDF amb el botó inferior',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.grisBody.withValues(alpha: 0.7),
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Agrupar designacions per data (sense hora)
        final groupedByDate = groupBy<DesignationModel, String>(
          designations,
          (designation) => DateFormat('yyyy-MM-dd').format(designation.date),
        );

        // Ordenar dates de més recent a més antic
        final sortedDates = groupedByDate.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 900;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final dateKey = sortedDates[index];
                final dateDesignations = groupedByDate[dateKey]!;
                final date = DateTime.parse(dateKey);

                return _DateGroup(
                  date: date,
                  designations: dateDesignations,
                  isDesktop: isDesktop,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _DateGroup extends StatelessWidget {
  final DateTime date;
  final List<DesignationModel> designations;
  final bool isDesktop;

  const _DateGroup({
    required this.date,
    required this.designations,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE d MMMM', 'ca_ES');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Data header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.porpraFosc,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  dateFormat.format(date),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.mostassa.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.mostassa.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  '${designations.length} ${designations.length == 1 ? "partit" : "partits"}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.porpraFosc,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Designacions
        if (isDesktop)
          // Layout horitzontal per desktop
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: designations.map((designation) {
                return Container(
                  width: 380,
                  constraints: const BoxConstraints(
                    minHeight: 280,
                    maxHeight: 280,
                  ),
                  margin: const EdgeInsets.only(right: 14, bottom: 20),
                  child: _DesignationCard(designation: designation),
                );
              }).toList(),
            ),
          )
        else
          // Layout vertical per mòbil
          ...designations.map((designation) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _DesignationCard(designation: designation),
            );
          }),

        const SizedBox(height: 8),
      ],
    );
  }
}

class _DesignationCard extends StatelessWidget {
  final DesignationModel designation;

  const _DesignationCard({required this.designation});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm', 'ca_ES');
    final currencyFormat = NumberFormat.currency(locale: 'ca_ES', symbol: '€');

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.porpraFosc.withValues(alpha: 0.15),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.porpraFosc.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showDesignationDetails(context),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header amb hora
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.lilaClar.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.lilaClar.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: AppTheme.porpraFosc,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeFormat.format(designation.date),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.porpraFosc,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Equips
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          designation.localTeam,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.porpraFosc,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.grisBody.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'vs',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.grisBody,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          designation.visitantTeam,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.porpraFosc,
                            letterSpacing: -0.2,
                          ),
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Categoria i rol
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _InfoChip(
                        icon: Icons.category_rounded,
                        label: designation.category,
                        color: AppTheme.lilaMitja,
                      ),
                      _InfoChip(
                        icon: Icons.person_rounded,
                        label: designation.role == 'principal'
                            ? 'Principal'
                            : 'Auxiliar',
                        color: AppTheme.lilaMitja,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Localització
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 15,
                        color: AppTheme.grisBody.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          designation.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.grisBody.withValues(alpha: 0.8),
                            letterSpacing: 0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  Divider(
                    height: 24,
                    color: AppTheme.grisPistacho.withValues(alpha: 0.4),
                  ),

                  // Informació econòmica
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _EarningDetail(
                        label: 'Drets',
                        amount: currencyFormat.format(
                          designation.earnings.rights,
                        ),
                        color: AppTheme.lilaMitja,
                      ),
                      _EarningDetail(
                        label: 'Km',
                        amount: currencyFormat.format(
                          designation.earnings.kilometersAmount,
                        ),
                        color: AppTheme.lilaMitja,
                      ),
                      _EarningDetail(
                        label: 'Dietes',
                        amount: currencyFormat.format(
                          designation.earnings.allowance,
                        ),
                        color: AppTheme.lilaMitja,
                      ),
                      _EarningDetail(
                        label: 'Total',
                        amount: currencyFormat.format(
                          designation.earnings.total,
                        ),
                        color: AppTheme.lilaMitja,
                        isTotal: true,
                      ),
                    ],
                  ),

                  // Apunts si n'hi ha
                  if (designation.notes != null &&
                      designation.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.lilaClar.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.note_rounded,
                            size: 14,
                            color: AppTheme.lilaMitja,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              designation.notes!,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textBlackLow,
                                fontStyle: FontStyle.italic,
                                letterSpacing: 0.1,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDesignationDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _DesignationDetailsSheet(designation: designation),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningDetail extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final bool isTotal;

  const _EarningDetail({
    required this.label,
    required this.amount,
    required this.color,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 14 : 12,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _DesignationDetailsSheet extends StatefulWidget {
  final DesignationModel designation;

  const _DesignationDetailsSheet({required this.designation});

  @override
  State<_DesignationDetailsSheet> createState() =>
      _DesignationDetailsSheetState();
}

class _DesignationDetailsSheetState extends State<_DesignationDetailsSheet> {
  late TextEditingController _notesController;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.designation.notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveNotes() async {
    setState(() => _isSaving = true);

    final repository = DesignationsRepository();
    final success = await repository.updateNotes(
      widget.designation.id,
      _notesController.text,
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
        _isEditing = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Apunts guardats correctament'),
            backgroundColor: AppTheme.mostassa,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error guardant els apunts'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, d MMMM yyyy - HH:mm', 'ca_ES');
    final currencyFormat = NumberFormat.currency(locale: 'ca_ES', symbol: '€');

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Detalls de la designació',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.porpraFosc,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: AppTheme.grisBody),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Data i hora
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.grisPistacho.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.lilaMitja.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_rounded,
                      color: AppTheme.lilaMitja,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      dateFormat.format(widget.designation.date),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lilaMitja,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Partit
              _DetailRow(
                label: 'Partit',
                value:
                    '${widget.designation.localTeam} vs ${widget.designation.visitantTeam}',
              ),
              _DetailRow(
                label: 'Número de partit',
                value: widget.designation.matchNumber,
              ),
              _DetailRow(
                label: 'Categoria',
                value: widget.designation.category,
              ),
              _DetailRow(
                label: 'Competició',
                value: widget.designation.competition,
              ),
              _DetailRow(
                label: 'Rol',
                value: widget.designation.role == 'principal'
                    ? 'Àrbitre Principal'
                    : 'Àrbitre Auxiliar',
              ),
              _DetailRow(
                label: 'Localització',
                value: widget.designation.location,
              ),
              _DetailRow(
                label: 'Adreça',
                value: widget.designation.locationAddress,
              ),
              _DetailRow(
                label: 'Quilòmetres',
                value: '${widget.designation.kilometers.toStringAsFixed(1)} km',
              ),

              const Divider(height: 32),

              // Informació econòmica
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.mostassa.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.euro_rounded,
                      color: AppTheme.mostassa,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Detall econòmic',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.porpraFosc,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _DetailRow(
                label: 'Drets d\'arbitratge',
                value: currencyFormat.format(
                  widget.designation.earnings.rights,
                ),
              ),
              _DetailRow(
                label: 'Quilometratge',
                value: currencyFormat.format(
                  widget.designation.earnings.kilometersAmount,
                ),
              ),
              _DetailRow(
                label: 'Dietes',
                value: currencyFormat.format(
                  widget.designation.earnings.allowance,
                ),
              ),
              _DetailRow(
                label: 'TOTAL',
                value: currencyFormat.format(widget.designation.earnings.total),
                isTotal: true,
              ),

              const Divider(height: 32),

              // Apunts personals
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.lilaClar.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.note_rounded,
                      color: AppTheme.lilaMitja,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Apunts personals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.porpraFosc,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  if (!_isEditing)
                    TextButton.icon(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: Icon(
                        Icons.edit_rounded,
                        size: 18,
                        color: AppTheme.lilaMitja,
                      ),
                      label: Text(
                        'Editar',
                        style: TextStyle(color: AppTheme.lilaMitja),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_isEditing)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _notesController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Afegeix apunts sobre aquest partit...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSaving
                                ? null
                                : () {
                                    setState(() {
                                      _isEditing = false;
                                      _notesController.text =
                                          widget.designation.notes ?? '';
                                    });
                                  },
                            child: const Text('Cancel·lar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveNotes,
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Guardar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.grisPistacho.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.lilaClar.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    widget.designation.notes?.isEmpty ?? true
                        ? 'Encara no hi ha apunts per aquest partit'
                        : widget.designation.notes!,
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.designation.notes?.isEmpty ?? true
                          ? AppTheme.grisBody.withValues(alpha: 0.6)
                          : AppTheme.textBlackLow,
                      fontStyle: widget.designation.notes?.isEmpty ?? true
                          ? FontStyle.italic
                          : FontStyle.normal,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),

              const SizedBox(height: 32),

              // Botó d'eliminar
              OutlinedButton.icon(
                onPressed: () => _confirmDelete(context),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Eliminar designació',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar designació'),
        content: const Text(
          'Estàs segur que vols eliminar aquesta designació? '
          'Aquesta acció no es pot desfer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel·lar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final repository = DesignationsRepository();
      final success = await repository.deleteDesignation(widget.designation.id);

      if (context.mounted) {
        Navigator.pop(context); // Tancar el bottom sheet

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Designació eliminada correctament'
                  : 'Error eliminant la designació',
            ),
            backgroundColor: success ? AppTheme.mostassa : Colors.red,
          ),
        );
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 15 : 14,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
                color: AppTheme.grisBody.withValues(alpha: 0.7),
                letterSpacing: 0.1,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTotal ? 17 : 14,
                fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
                color: isTotal ? AppTheme.mostassa : AppTheme.textBlackLow,
                letterSpacing: isTotal ? -0.3 : 0,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
