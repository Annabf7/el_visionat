import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../models/designation_model.dart';
import '../repositories/designations_repository.dart';
import '../services/distance_calculator_service.dart';
import '../services/tariff_calculator_service.dart';

/// Diàleg per editar una designació existent
class EditDesignationDialog extends StatefulWidget {
  final DesignationModel designation;
  final String userHomeAddress;

  const EditDesignationDialog({
    super.key,
    required this.designation,
    required this.userHomeAddress,
  });

  @override
  State<EditDesignationDialog> createState() => _EditDesignationDialogState();
}

class _EditDesignationDialogState extends State<EditDesignationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _repository = DesignationsRepository();

  late TextEditingController _originAddressController;
  late TextEditingController _venueAddressController;
  late TextEditingController _kilometersController;
  late TextEditingController _notesController;

  bool _isLoading = false;
  bool _useCustomOrigin = false;

  @override
  void initState() {
    super.initState();

    // Inicialitzar controllers
    _originAddressController = TextEditingController(
      text: widget.designation.originAddress ?? widget.userHomeAddress,
    );
    _venueAddressController = TextEditingController(
      text: widget.designation.locationAddress,
    );
    _kilometersController = TextEditingController(
      text: widget.designation.kilometers.toStringAsFixed(2),
    );
    _notesController = TextEditingController(
      text: widget.designation.notes ?? '',
    );

    // Si hi ha una adreça d'origen personalitzada, marcar el checkbox
    _useCustomOrigin = widget.designation.originAddress != null;
  }

  @override
  void dispose() {
    _originAddressController.dispose();
    _venueAddressController.dispose();
    _kilometersController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _recalculateDistance() async {
    if (_venueAddressController.text.isEmpty || _originAddressController.text.isEmpty) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final oneWayKm = await DistanceCalculatorService.calculateDistance(
        originAddress: _originAddressController.text,
        destinationAddress: _venueAddressController.text,
      );

      final roundTripKm = oneWayKm * 2;
      _kilometersController.text = roundTripKm.toStringAsFixed(2);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Distància recalculada: ${roundTripKm.toStringAsFixed(2)} km'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error calculant la distància: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Obtenir els nous valors
      final newOriginAddress = _useCustomOrigin ? _originAddressController.text : null;
      final newVenueAddress = _venueAddressController.text;
      final newKilometers = double.parse(_kilometersController.text);
      final newNotes = _notesController.text.isEmpty ? null : _notesController.text;

      // Recalcular ingressos amb els nous quilòmetres
      final newEarnings = TariffCalculatorService.calculateEarnings(
        category: widget.designation.category,
        role: widget.designation.role,
        kilometers: newKilometers,
        matchDate: widget.designation.date,
        matchTime: '${widget.designation.date.hour}:${widget.designation.date.minute.toString().padLeft(2, '0')}',
      );

      // Crear designació actualitzada
      final updatedDesignation = widget.designation.copyWith(
        originAddress: newOriginAddress,
        locationAddress: newVenueAddress,
        kilometers: newKilometers,
        earnings: newEarnings,
        notes: newNotes,
      );

      // Guardar a Firestore
      final success = await _repository.updateDesignation(updatedDesignation);

      if (mounted) {
        if (success) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Designació actualitzada correctament'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error actualitzant la designació'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Títol
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.lilaMitja.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: AppTheme.lilaMitja,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Editar designació',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.porpraFosc,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Info del partit
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.grisBody.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Partit #${widget.designation.matchNumber}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.porpraFosc,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.designation.localTeam} vs ${widget.designation.visitantTeam}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textBlackLow,
                        ),
                      ),
                      Text(
                        widget.designation.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textBlackLow,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Adreça d'origen
                CheckboxListTile(
                  title: const Text('Utilitzar adreça d\'origen personalitzada'),
                  subtitle: Text(
                    _useCustomOrigin
                        ? 'Adreça personalitzada'
                        : 'Adreça de casa: ${widget.userHomeAddress}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: _useCustomOrigin,
                  onChanged: (value) {
                    setState(() {
                      _useCustomOrigin = value ?? false;
                      if (!_useCustomOrigin) {
                        _originAddressController.text = widget.userHomeAddress;
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (_useCustomOrigin) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _originAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Adreça d\'origen',
                      hintText: 'Ex: Plaça Catalunya, Barcelona',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Introdueix una adreça d\'origen';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),

                // Adreça del pavelló
                TextFormField(
                  controller: _venueAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Adreça del pavelló',
                    hintText: 'Ex: Carrer Faraday, 33, Terrassa',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Introdueix l\'adreça del pavelló';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Botó recalcular distància
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _recalculateDistance,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Recalcular distància'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.lilaMitja,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Quilòmetres
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _kilometersController,
                        decoration: const InputDecoration(
                          labelText: 'Quilòmetres (anada i tornada)',
                          hintText: '0.00',
                          border: OutlineInputBorder(),
                          suffixText: 'km',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Introdueix els quilòmetres';
                          }
                          final km = double.tryParse(value);
                          if (km == null || km < 0) {
                            return 'Valor invàlid';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (opcional)',
                    hintText: 'Afegeix notes sobre aquesta designació',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Botons d'acció
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel·lar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.lilaMitja,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Guardar canvis'),
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