import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/core/services/google_places_service.dart';
import '../models/home_address_model.dart';

/// Diàleg per editar l'adreça de casa de l'àrbitre
/// Aquesta adreça s'utilitza com a punt de sortida per calcular quilometratge
class EditHomeAddressDialog extends StatefulWidget {
  final HomeAddress? currentAddress;

  const EditHomeAddressDialog({
    super.key,
    this.currentAddress,
  });

  @override
  State<EditHomeAddressDialog> createState() => _EditHomeAddressDialogState();
}

class _EditHomeAddressDialogState extends State<EditHomeAddressDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _streetController;
  late TextEditingController _postalCodeController;
  late TextEditingController _cityController;
  late TextEditingController _provinceController;
  late TextEditingController _searchController;

  List<PlaceSuggestion> _suggestions = [];
  bool _isSearching = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    final address = widget.currentAddress ?? HomeAddress.empty();
    _streetController = TextEditingController(text: address.street);
    _postalCodeController = TextEditingController(text: address.postalCode);
    _cityController = TextEditingController(text: address.city);
    _provinceController = TextEditingController(text: address.province);
    _searchController = TextEditingController();

    // Listener per autocompletat
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _streetController.dispose();
    _postalCodeController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() async {
    final query = _searchController.text;

    if (query.length < 3) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showSuggestions = true;
    });

    final suggestions = await GooglePlacesService.searchAddresses(query);

    setState(() {
      _suggestions = suggestions;
      _isSearching = false;
    });
  }

  Future<void> _selectPlace(PlaceSuggestion suggestion) async {
    setState(() {
      _isSearching = true;
      _showSuggestions = false;
    });

    final details = await GooglePlacesService.getPlaceDetails(suggestion.placeId);

    if (details != null) {
      setState(() {
        _streetController.text = details.street;
        _postalCodeController.text = details.postalCode;
        _cityController.text = details.city;
        _provinceController.text = details.province;
        _searchController.clear();
        _isSearching = false;
      });
    } else {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _saveAddress() {
    if (_formKey.currentState!.validate()) {
      final newAddress = HomeAddress(
        street: _streetController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        city: _cityController.text.trim(),
        province: _provinceController.text.trim(),
      );
      Navigator.of(context).pop(newAddress);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.porpraFosc,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
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
                      color: AppTheme.mostassa.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.home_outlined,
                      color: AppTheme.mostassa,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Adreça de casa',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        color: AppTheme.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppTheme.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Aquesta adreça s\'utilitzarà per calcular els quilòmetres als pavellons',
                style: TextStyle(
                  fontFamily: 'Geist',
                  color: AppTheme.white.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),

              // Camp de cerca amb autocompletat
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cerca la teva adreça',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      color: AppTheme.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      color: AppTheme.white,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Comença a escriure la teva adreça...',
                      hintStyle: TextStyle(
                        fontFamily: 'Geist',
                        color: AppTheme.white.withValues(alpha: 0.4),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppTheme.mostassa.withValues(alpha: 0.7),
                        size: 20,
                      ),
                      suffixIcon: _isSearching
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.mostassa,
                                ),
                              ),
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: AppTheme.white.withValues(alpha: 0.2),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: AppTheme.white.withValues(alpha: 0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppTheme.mostassa,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  // Llista de suggeriments
                  if (_showSuggestions && _suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.mostassa.withValues(alpha: 0.3),
                        ),
                      ),
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _suggestions[index];
                          return InkWell(
                            onTap: () => _selectPlace(suggestion),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: index < _suggestions.length - 1
                                    ? Border(
                                        bottom: BorderSide(
                                          color: AppTheme.white.withValues(alpha: 0.1),
                                        ),
                                      )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 18,
                                    color: AppTheme.mostassa,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      suggestion.description,
                                      style: const TextStyle(
                                        fontFamily: 'Geist',
                                        color: AppTheme.white,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Divisor "o emplena manualment"
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: AppTheme.white.withValues(alpha: 0.2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'o emplena manualment',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        color: AppTheme.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: AppTheme.white.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Camp: Carrer i número
              _buildTextField(
                controller: _streetController,
                label: 'Carrer i número',
                hint: 'Ex: Carrer de la Pau, 15',
                icon: Icons.location_on_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El carrer és obligatori';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Fila: Codi postal i Ciutat
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      controller: _postalCodeController,
                      label: 'Codi postal',
                      hint: '17200',
                      icon: Icons.pin_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Obligatori';
                        }
                        if (value.trim().length != 5) {
                          return 'Ha de tenir 5 dígits';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: _buildTextField(
                      controller: _cityController,
                      label: 'Ciutat',
                      hint: 'Palafrugell',
                      icon: Icons.location_city_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La ciutat és obligatòria';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Camp: Província
              _buildTextField(
                controller: _provinceController,
                label: 'Província',
                hint: 'Girona',
                icon: Icons.map_outlined,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La província és obligatòria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Botons d'acció
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel·lar',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        color: AppTheme.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saveAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.mostassa,
                      foregroundColor: AppTheme.porpraFosc,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Guardar',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Geist',
            color: AppTheme.white.withValues(alpha: 0.9),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontFamily: 'Geist',
            color: AppTheme.white,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: 'Geist',
              color: AppTheme.white.withValues(alpha: 0.4),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: AppTheme.mostassa.withValues(alpha: 0.7),
              size: 20,
            ),
            filled: true,
            fillColor: AppTheme.white.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppTheme.white.withValues(alpha: 0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppTheme.white.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppTheme.mostassa,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}