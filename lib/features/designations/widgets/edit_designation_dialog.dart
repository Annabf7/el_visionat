import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/google_places_service.dart';
import '../models/designation_model.dart';
import '../models/referee_from_registry.dart';
import '../repositories/designations_repository.dart';
import '../services/distance_calculator_service.dart';
import '../services/tariff_calculator_service.dart';
import '../services/referee_registry_service.dart';

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
  late TextEditingController _refereePartnerController;
  late TextEditingController _originSearchController;
  late TextEditingController _venueSearchController;

  bool _isLoading = false;
  bool _useCustomOrigin = false;

  // Estat per autocompletat d'origen
  List<PlaceSuggestion> _originSuggestions = [];
  bool _isOriginSearching = false;
  bool _showOriginSuggestions = false;

  // Estat per autocompletat de pavelló
  List<PlaceSuggestion> _venueSuggestions = [];
  bool _isVenueSearching = false;
  bool _showVenueSuggestions = false;

  // Estat per autocompletat d'àrbitres
  final _refereeRegistryService = RefereeRegistryService();
  List<RefereeFromRegistry> _allReferees = [];
  bool _isLoadingReferees = true;

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
    _refereePartnerController = TextEditingController(
      text: widget.designation.refereePartner ?? '',
    );
    _originSearchController = TextEditingController();
    _venueSearchController = TextEditingController();

    // Si hi ha una adreça d'origen personalitzada, marcar el checkbox
    _useCustomOrigin = widget.designation.originAddress != null;

    // Listeners per autocompletat
    _originSearchController.addListener(_onOriginSearchChanged);
    _venueSearchController.addListener(_onVenueSearchChanged);

    // Carregar àrbitres del registre
    _loadReferees();
  }

  Future<void> _loadReferees() async {
    final referees = await _refereeRegistryService.getAllReferees();
    setState(() {
      _allReferees = referees;
      _isLoadingReferees = false;
    });
  }

  @override
  void dispose() {
    _originAddressController.dispose();
    _venueAddressController.dispose();
    _kilometersController.dispose();
    _notesController.dispose();
    _refereePartnerController.dispose();
    _originSearchController.dispose();
    _venueSearchController.dispose();
    super.dispose();
  }

  void _onOriginSearchChanged() async {
    final query = _originSearchController.text;

    if (query.length < 3) {
      setState(() {
        _originSuggestions = [];
        _showOriginSuggestions = false;
      });
      return;
    }

    setState(() {
      _isOriginSearching = true;
      _showOriginSuggestions = true;
    });

    final suggestions = await GooglePlacesService.searchAddresses(query);

    setState(() {
      _originSuggestions = suggestions;
      _isOriginSearching = false;
    });
  }

  void _onVenueSearchChanged() async {
    final query = _venueSearchController.text;

    if (query.length < 3) {
      setState(() {
        _venueSuggestions = [];
        _showVenueSuggestions = false;
      });
      return;
    }

    setState(() {
      _isVenueSearching = true;
      _showVenueSuggestions = true;
    });

    final suggestions = await GooglePlacesService.searchAddresses(query);

    setState(() {
      _venueSuggestions = suggestions;
      _isVenueSearching = false;
    });
  }

  Future<void> _selectOriginPlace(PlaceSuggestion suggestion) async {
    setState(() {
      _isOriginSearching = true;
      _showOriginSuggestions = false;
    });

    // Per adreces, utilitzem directament la descripció completa
    setState(() {
      _originAddressController.text = suggestion.description;
      _originSearchController.clear();
      _isOriginSearching = false;
    });
  }

  Future<void> _selectVenuePlace(PlaceSuggestion suggestion) async {
    setState(() {
      _isVenueSearching = true;
      _showVenueSuggestions = false;
    });

    // Per adreces, utilitzem directament la descripció completa
    setState(() {
      _venueAddressController.text = suggestion.description;
      _venueSearchController.clear();
      _isVenueSearching = false;
    });
  }

  Future<void> _recalculateDistance() async {
    if (_venueAddressController.text.isEmpty || _originAddressController.text.isEmpty) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Netejar l'adreça del pavelló per millorar la geocodificació
      final cleanedVenueAddress = DistanceCalculatorService.cleanVenueAddress(
        _venueAddressController.text,
      );

      // Debug: mostrar adreces que s'envien
      debugPrint('=== RECALCULATE DISTANCE DEBUG ===');
      debugPrint('Origin: ${_originAddressController.text}');
      debugPrint('Venue (original): ${_venueAddressController.text}');
      debugPrint('Venue (cleaned): $cleanedVenueAddress');

      final oneWayKm = await DistanceCalculatorService.calculateDistance(
        originAddress: _originAddressController.text,
        destinationAddress: cleanedVenueAddress,
      );

      debugPrint('One-way km: $oneWayKm');
      final roundTripKm = oneWayKm * 2;
      debugPrint('Round-trip km: $roundTripKm');
      debugPrint('=================================');
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
      final newRefereePartner = _refereePartnerController.text.isEmpty ? null : _refereePartnerController.text;

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
        refereePartner: newRefereePartner,
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
                          fontWeight: FontWeight.w500,
                          color: AppTheme.grisPistacho,
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
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.grisPistacho.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.grisPistacho.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Partit #${widget.designation.matchNumber}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.porpraFosc,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${widget.designation.localTeam} vs ${widget.designation.visitantTeam}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.grisPistacho,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.designation.category,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.grisPistacho,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
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
                  // Camp de cerca d'adreça d'origen
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _originSearchController,
                        decoration: InputDecoration(
                          labelText: 'Cerca adreça d\'origen',
                          hintText: 'Comença a escriure...',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _isOriginSearching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      // Llista de suggeriments d'origen
                      if (_showOriginSuggestions && _originSuggestions.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.lilaMitja.withValues(alpha: 0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _originSuggestions.length,
                            itemBuilder: (context, index) {
                              final suggestion = _originSuggestions[index];
                              return InkWell(
                                onTap: () => _selectOriginPlace(suggestion),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: index < _originSuggestions.length - 1
                                        ? Border(
                                            bottom: BorderSide(
                                              color: AppTheme.grisBody.withValues(alpha: 0.2),
                                            ),
                                          )
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 18,
                                        color: AppTheme.lilaMitja,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          suggestion.description,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 12),
                      // Camp amb l'adreça seleccionada
                      TextFormField(
                        controller: _originAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Adreça d\'origen seleccionada',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.check_circle, color: AppTheme.lilaMitja),
                        ),
                        readOnly: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Cerca i selecciona una adreça d\'origen';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                // Camp de cerca d'adreça del pavelló
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _venueSearchController,
                      decoration: InputDecoration(
                        labelText: 'Cerca adreça del pavelló',
                        hintText: 'Comença a escriure...',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _isVenueSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                      ),
                    ),
                    // Llista de suggeriments de pavelló
                    if (_showVenueSuggestions && _venueSuggestions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.lilaMitja.withValues(alpha: 0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _venueSuggestions.length,
                          itemBuilder: (context, index) {
                            final suggestion = _venueSuggestions[index];
                            return InkWell(
                              onTap: () => _selectVenuePlace(suggestion),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: index < _venueSuggestions.length - 1
                                      ? Border(
                                          bottom: BorderSide(
                                            color: AppTheme.grisBody.withValues(alpha: 0.2),
                                          ),
                                        )
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 18,
                                      color: AppTheme.lilaMitja,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        suggestion.description,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 12),
                    // Camp amb l'adreça del pavelló seleccionada
                    TextFormField(
                      controller: _venueAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Adreça del pavelló seleccionada',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.check_circle, color: AppTheme.lilaMitja),
                      ),
                      readOnly: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Cerca i selecciona l\'adreça del pavelló';
                        }
                        return null;
                      },
                    ),
                  ],
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

                // Company/companya àrbitre amb autocompletat
                TypeAheadField<RefereeFromRegistry>(
                  controller: _refereePartnerController,
                  builder: (context, controller, focusNode) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Company/companya àrbitre (opcional)',
                        hintText: _isLoadingReferees
                            ? 'Carregant àrbitres...'
                            : 'Escriu el nom o número de llicència',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.people_rounded),
                        suffixIcon: _isLoadingReferees
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                  suggestionsCallback: (search) {
                    if (_isLoadingReferees) return [];

                    final matches = _refereeRegistryService.searchReferees(
                      _allReferees,
                      search,
                    );

                    // Limitar a 15 resultats
                    return matches.take(15).toList();
                  },
                  itemBuilder: (context, referee) {
                    return ListTile(
                      leading: const Icon(
                        Icons.person,
                        color: AppTheme.lilaMitja,
                      ),
                      title: Text(
                        referee.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Llicència: ${referee.llissenciaId}${referee.categoriaRrtt != null ? ' • ${referee.categoriaRrtt}' : ''}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                  onSelected: (referee) {
                    // Només guardar el nom complet, sense el rol
                    // El rol ja està guardat al camp refereePartner amb format "Nom (Rol)"
                    // Aquí només actualitzem el nom
                    _refereePartnerController.text = referee.fullName;
                  },
                  emptyBuilder: (context) => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No s\'han trobat àrbitres. Pots escriure el nom manualment.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.grisPistacho,
                      ),
                    ),
                  ),
                  decorationBuilder: (context, child) {
                    return Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      child: child,
                    );
                  },
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
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.grisPistacho,
                      ),
                      child: const Text(
                        'Cancel·lar',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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