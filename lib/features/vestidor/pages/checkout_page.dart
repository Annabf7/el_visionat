import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/core/navigation/side_navigation_menu.dart';
import 'package:el_visionat/core/widgets/global_header.dart';
import 'package:el_visionat/features/auth/index.dart';
import 'package:el_visionat/core/services/google_places_service.dart';
import '../providers/checkout_provider.dart';
import '../providers/cart_provider.dart';
import '../models/shipping_address.dart';
import '../models/shipping_rate.dart';

/// Pàgina de checkout multi-step: Adreça → Enviament → Pagament → Confirmació
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cart = context.read<CartProvider>();
      context.read<CheckoutProvider>().enterCheckout(cart.items);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 900;

        if (isLargeScreen) {
          return Scaffold(
            key: _scaffoldKey,
            body: Row(
              children: [
                const SizedBox(
                  width: 288,
                  height: double.infinity,
                  child: SideNavigationMenu(),
                ),
                Expanded(
                  child: Column(
                    children: [
                      GlobalHeader(
                        scaffoldKey: _scaffoldKey,
                        title: 'Checkout',
                        showMenuButton: false,
                      ),
                      Expanded(child: _buildContent(context)),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            key: _scaffoldKey,
            drawer: const SideNavigationMenu(),
            body: Column(
              children: [
                GlobalHeader(
                  scaffoldKey: _scaffoldKey,
                  title: 'Checkout',
                  showMenuButton: true,
                ),
                Expanded(child: _buildContent(context)),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    final checkout = context.watch<CheckoutProvider>();
    final cart = context.watch<CartProvider>();
    final isDesktop = MediaQuery.of(context).size.width > 1100;
    final showSidebar =
        isDesktop && checkout.currentStep != CheckoutStep.confirmation;

    final stepWidget = switch (checkout.currentStep) {
      CheckoutStep.address => _AddressStep(),
      CheckoutStep.shipping => _ShippingStep(),
      CheckoutStep.payment => _PaymentStep(),
      CheckoutStep.confirmation => _ConfirmationStep(),
    };

    return Column(
      children: [
        _buildStepIndicator(checkout.currentStep),
        Expanded(
          child: showSidebar
              ? Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Formulari
                          Expanded(flex: 3, child: stepWidget),
                          // Sidebar resum
                          SizedBox(
                            width: 490,
                            child: _buildCheckoutSidebar(cart, checkout),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : stepWidget,
        ),
      ],
    );
  }

  /// Elimina un producte del carretó i recalcula enviament si cal
  void _removeCartItem(int syncVariantId) {
    final cart = context.read<CartProvider>();
    final checkout = context.read<CheckoutProvider>();
    cart.removeItem(syncVariantId);

    // Si el carretó queda buit, tornem a la pàgina del carretó
    if (cart.isEmpty) {
      Navigator.pushReplacementNamed(context, '/cart');
      return;
    }

    // Recalcular enviament si estem en shipping o payment
    if (checkout.currentStep == CheckoutStep.shipping) {
      checkout.fetchShippingRates(cart.items);
    } else if (checkout.currentStep == CheckoutStep.payment) {
      // El PaymentIntent ja no és vàlid, tornem a shipping
      checkout.goBack();
      checkout.fetchShippingRates(cart.items);
    }
  }

  Widget _buildCheckoutSidebar(CartProvider cart, CheckoutProvider checkout) {
    final shippingPrice = checkout.selectedRate?.rateAsDouble ?? 0.0;
    final total = cart.subtotal + shippingPrice;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 24, 24, 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.porpraFosc.withValues(alpha: 0.1),
            width: 8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Capçalera: Articles al carretó
            Text(
              'Articles al carretó (${cart.itemCount})',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.porpraFosc,
              ),
            ),
            const SizedBox(height: 20),
            // Llista de productes amb opció d'eliminar
            ...cart.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imatge producte
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.grisPistacho.withValues(alpha: 0.15),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child:
                            (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                            ? Image.network(
                                item.imageUrl!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 80,
                                  height: 80,
                                  color: AppTheme.grisPistacho.withValues(
                                    alpha: 0.06,
                                  ),
                                  child: const Icon(
                                    Icons.checkroom_rounded,
                                    color: AppTheme.grisPistacho,
                                    size: 28,
                                  ),
                                ),
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                color: AppTheme.grisPistacho.withValues(
                                  alpha: 0.06,
                                ),
                                child: const Icon(
                                  Icons.checkroom_rounded,
                                  color: AppTheme.grisPistacho,
                                  size: 28,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Detalls + preu
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nom + preu + botó eliminar
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.porpraFosc,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '\u20ac${item.totalPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.porpraFosc,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Variant: color / talla + eliminar
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  [
                                    if (item.color.isNotEmpty) item.color,
                                    if (item.size.isNotEmpty) item.size,
                                    if (item.quantity > 1)
                                      'Qty: ${item.quantity}',
                                  ].join(' / '),
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: AppTheme.grisPistacho.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                              ),
                              // Botó eliminar (recalcula enviament)
                              InkWell(
                                onTap: () =>
                                    _removeCartItem(item.syncVariantId),
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Text(
                                    'Eliminar',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.redAccent.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Separador + Summary
            const Divider(height: 32),
            const Text(
              'Resum',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.porpraFosc,
              ),
            ),
            const SizedBox(height: 14),
            _sidebarRow(
              'Articles del carretó',
              '\u20ac${cart.subtotal.toStringAsFixed(2).replaceAll('.', ',')}',
            ),
            const SizedBox(height: 10),
            _sidebarRow(
              'Enviament (estimat)',
              checkout.selectedRate != null
                  ? '\u20ac${shippingPrice.toStringAsFixed(2).replaceAll('.', ',')}'
                  : 'Es calcularà a l\'enviament',
              isSubtle: checkout.selectedRate == null,
            ),
            const Divider(height: 28),
            _sidebarRow(
              'Total estimat',
              '\u20ac${total.toStringAsFixed(2).replaceAll('.', ',')}',
              isBold: true,
              fontSize: 16,
            ),
            const SizedBox(height: 24),
            // Nota de moneda (estil prototip)
            Text(
              'Nota sobre la moneda',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.porpraFosc.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tots els pagaments es processen en EUR. '
              'L\'import total cobrat serà en euros. '
              'No hi ha comissions addicionals ni càrrecs ocults.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppTheme.grisPistacho.withValues(alpha: 0.65),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            // Enllaç a El Vestidor
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/vestidor'),
                icon: const Icon(Icons.checkroom_rounded, size: 28),
                label: const Text('Continuar comprant'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.porpraFosc,
                  foregroundColor: AppTheme.mostassa,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidebarRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 14,
    bool isSubtle = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: isBold ? AppTheme.porpraFosc : AppTheme.grisPistacho,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: isSubtle ? 12 : fontSize,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            fontStyle: isSubtle ? FontStyle.italic : FontStyle.normal,
            color: isSubtle
                ? AppTheme.grisPistacho.withValues(alpha: 0.5)
                : AppTheme.porpraFosc,
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(CheckoutStep current) {
    final steps = [
      ('Adreça', CheckoutStep.address),
      ('Enviament', CheckoutStep.shipping),
      ('Pagament', CheckoutStep.payment),
      ('Confirmació', CheckoutStep.confirmation),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  color: steps[i].$2.index <= current.index
                      ? AppTheme.porpraFosc
                      : AppTheme.grisPistacho.withValues(alpha: 0.2),
                ),
              ),
            _buildStepDot(
              label: steps[i].$1,
              isActive: steps[i].$2 == current,
              isCompleted: steps[i].$2.index < current.index,
              stepNumber: i + 1,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepDot({
    required String label,
    required bool isActive,
    required bool isCompleted,
    required int stepNumber,
  }) {
    final color = isCompleted
        ? AppTheme.verdeEncert
        : isActive
        ? AppTheme.porpraFosc
        : AppTheme.grisPistacho.withValues(alpha: 0.3);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isCompleted || isActive ? color : Colors.transparent,
            border: Border.all(color: color, width: 2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '$stepNumber',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : color,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive
                ? AppTheme.porpraFosc
                : AppTheme.grisPistacho.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Step 1: Adreça d'enviament
// =============================================================================
class _AddressStep extends StatefulWidget {
  @override
  State<_AddressStep> createState() => _AddressStepState();
}

class _AddressStepState extends State<_AddressStep> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _searchController = TextEditingController();
  String _countryCode = 'ES';

  List<PlaceSuggestion> _suggestions = [];
  bool _isSearching = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Pre-omplir camps des del provider (si l'usuari ja havia omplert l'adreça)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final checkout = context.read<CheckoutProvider>();
      if (checkout.address != null) {
        final addr = checkout.address!;
        _nameController.text = addr.name;
        _address1Controller.text = addr.address1;
        _address2Controller.text = addr.address2 ?? '';
        _cityController.text = addr.city;
        _zipController.text = addr.zip;
        _phoneController.text = addr.phone ?? '';
        _emailController.text = addr.email ?? '';
        setState(() => _countryCode = addr.countryCode);
      } else {
        final auth = context.read<AuthProvider>();
        if (auth.currentUserEmail != null) {
          _emailController.text = auth.currentUserEmail!;
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
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
    if (!mounted) return;
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
    final details = await GooglePlacesService.getPlaceDetails(
      suggestion.placeId,
    );
    if (!mounted) return;
    if (details != null) {
      setState(() {
        _address1Controller.text = details.street;
        _cityController.text = details.city;
        _zipController.text = details.postalCode;
        _searchController.clear();
        _isSearching = false;
      });
    } else {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cerca d'adreça amb autocompletat
            _buildAddressSearch(),
            const SizedBox(height: 28),
            // Secció: Informació d'enviament
            const Text(
              'Informació d\'enviament',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                color: AppTheme.mostassa,
              ),
            ),
            const SizedBox(height: 16),
            // Email (ample complet)
            _buildField(
              controller: _emailController,
              label: 'Email',
              hint: 'anna@exemple.com',
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  v == null || v.isEmpty ? 'L\'email és obligatori' : null,
            ),
            const SizedBox(height: 12),
            // Nom complet (ample complet)
            _buildField(
              controller: _nameController,
              label: 'Nom complet',
              hint: 'Anna Benet',
              validator: (v) =>
                  v == null || v.isEmpty ? 'El nom és obligatori' : null,
            ),
            const SizedBox(height: 12),
            // Adreça (ample complet)
            _buildField(
              controller: _address1Controller,
              label: 'Adreça',
              hint: 'Carrer Major 12, 2n 1a',
              validator: (v) =>
                  v == null || v.isEmpty ? 'L\'adreça és obligatòria' : null,
            ),
            const SizedBox(height: 12),
            // Adreça línia 2 (opcional)
            _buildField(
              controller: _address2Controller,
              label: 'Pis, porta, escala (opcional)',
              hint: '2n 1a',
            ),
            const SizedBox(height: 12),
            // País + Ciutat (fila de 2)
            Row(
              children: [
                Expanded(child: _buildCountryDropdown()),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _cityController,
                    label: 'Ciutat',
                    hint: 'Barcelona',
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Obligatori' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // CP + Telèfon (fila de 2)
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _zipController,
                    label: 'Codi postal',
                    hint: '08001',
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Obligatori' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _phoneController,
                    label: 'Telèfon',
                    hint: '+34 600 123 456',
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            // Botó continuar (mostassa)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.mostassa,
                  foregroundColor: AppTheme.porpraFosc,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  elevation: 0,
                ),
                child: const Text('Continuar amb l\'enviament'),
              ),
            ),
            const SizedBox(height: 4),
            // Nota de seguretat
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 14,
                  color: AppTheme.grisPistacho.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  'La teva informació és segura',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppTheme.grisPistacho.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Cerca la teva adreça',
            hintText: 'Comença a escriure...',
            prefixIcon: const Icon(Icons.search, color: AppTheme.grisPistacho),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.porpraFosc,
                      ),
                    ),
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.grisPistacho.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return InkWell(
                  onTap: () => _selectPlace(suggestion),
                  borderRadius: index == 0
                      ? const BorderRadius.vertical(top: Radius.circular(12))
                      : index == _suggestions.length - 1
                      ? const BorderRadius.vertical(bottom: Radius.circular(12))
                      : BorderRadius.zero,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: index < _suggestions.length - 1
                          ? Border(
                              bottom: BorderSide(
                                color: AppTheme.grisPistacho.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 18,
                          color: AppTheme.porpraFosc,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            suggestion.description,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: AppTheme.porpraFosc,
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
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildCountryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _countryCode,
      decoration: InputDecoration(
        labelText: 'País',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'ES', child: Text('Espanya')),
        DropdownMenuItem(value: 'AD', child: Text('Andorra')),
        DropdownMenuItem(value: 'FR', child: Text('França')),
        DropdownMenuItem(value: 'PT', child: Text('Portugal')),
        DropdownMenuItem(value: 'IT', child: Text('Itàlia')),
        DropdownMenuItem(value: 'DE', child: Text('Alemanya')),
        DropdownMenuItem(value: 'GB', child: Text('Regne Unit')),
      ],
      onChanged: (v) => setState(() => _countryCode = v ?? 'ES'),
    );
  }

  void _onContinue() {
    if (!_formKey.currentState!.validate()) return;

    final address = ShippingAddress(
      name: _nameController.text.trim(),
      address1: _address1Controller.text.trim(),
      address2: _address2Controller.text.trim(),
      city: _cityController.text.trim(),
      countryCode: _countryCode,
      zip: _zipController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
    );

    final checkout = context.read<CheckoutProvider>();
    final cart = context.read<CartProvider>();
    checkout.setAddress(address);
    checkout.fetchShippingRates(cart.items);
  }
}

// =============================================================================
// Step 2: Selecció d'enviament
// =============================================================================
class _ShippingStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final checkout = context.watch<CheckoutProvider>();
    final cart = context.watch<CartProvider>();

    if (checkout.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.porpraFosc),
            SizedBox(height: 16),
            Text(
              'Calculant enviament...',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppTheme.grisPistacho,
              ),
            ),
          ],
        ),
      );
    }

    if (checkout.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                checkout.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => checkout.goBack(),
                child: const Text('Tornar'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mètode d\'enviament',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.mostassa,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selecciona com vols rebre la comanda',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              if (checkout.rates.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No hi ha tarifes d\'enviament disponibles per aquesta adreça.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppTheme.grisPistacho,
                    ),
                  ),
                )
              else
                ...checkout.rates.map(
                  (rate) => _buildRateCard(context, rate, checkout),
                ),
              if (checkout.rates.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Les tarifes d\'enviament són estimades i poden variar lleugerament al moment del pagament.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.grisPistacho.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              // Resum
              _buildSummaryCard(cart, checkout),
              const SizedBox(height: 24),
              // Botons
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => checkout.goBack(),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                    ),
                    label: Text(
                      'Tornar',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: checkout.selectedRate != null
                          ? () => checkout.preparePayment(cart.items)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.mostassa,
                        foregroundColor: AppTheme.porpraFosc,
                        disabledBackgroundColor: AppTheme.mostassa.withValues(
                          alpha: 0.3,
                        ),
                        disabledForegroundColor: AppTheme.porpraFosc.withValues(
                          alpha: 0.4,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Continuar al pagament'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRateCard(
    BuildContext context,
    ShippingRate rate,
    CheckoutProvider checkout,
  ) {
    final isSelected = checkout.selectedRate?.id == rate.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => checkout.selectRate(rate),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppTheme.porpraFosc
                  : AppTheme.grisPistacho.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
            color: isSelected
                ? AppTheme.porpraFosc.withValues(alpha: 0.04)
                : Colors.white,
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected
                    ? AppTheme.porpraFosc
                    : AppTheme.porpraFosc.withValues(alpha: 0.4),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rate.name,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.grisPistacho,
                      ),
                    ),
                    if (rate.deliveryEstimate.isNotEmpty)
                      Text(
                        rate.deliveryEstimate,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '${rate.rateAsDouble.toStringAsFixed(2).replaceAll('.', ',')} EUR',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.grisPistacho,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(CartProvider cart, CheckoutProvider checkout) {
    final shippingPrice = checkout.selectedRate?.rateAsDouble ?? 0.0;
    final total = cart.subtotal + shippingPrice;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppTheme.grisPistacho.withValues(alpha: 0.06),
      ),
      child: Column(
        children: [
          _summaryRow(
            'Subtotal (${cart.itemCount} articles)',
            '${cart.subtotal.toStringAsFixed(2).replaceAll('.', ',')} EUR',
          ),
          const SizedBox(height: 8),
          _summaryRow(
            'Enviament (estimat)',
            checkout.selectedRate != null
                ? '${shippingPrice.toStringAsFixed(2).replaceAll('.', ',')} EUR'
                : '—',
          ),
          const Divider(height: 24),
          _summaryRow(
            'Total',
            '${total.toStringAsFixed(2).replaceAll('.', ',')} EUR',
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: AppTheme.grisPistacho,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: AppTheme.grisPistacho,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Step 3: Pagament (Stripe Payment Sheet)
// =============================================================================
class _PaymentStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final checkout = context.watch<CheckoutProvider>();
    final cart = context.watch<CartProvider>();

    if (checkout.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.porpraFosc),
            SizedBox(height: 16),
            Text(
              'Preparant el pagament...',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppTheme.grisPistacho,
              ),
            ),
          ],
        ),
      );
    }

    if (checkout.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                checkout.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => checkout.goBack(),
                child: const Text('Tornar'),
              ),
            ],
          ),
        ),
      );
    }

    final totalEur = (checkout.totalAmount ?? 0) / 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resum de la comanda',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.mostassa,
                ),
              ),
              const SizedBox(height: 24),
              // Llista d'articles amb opció d'eliminar
              ...cart.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Imatge producte
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.grisPistacho.withValues(alpha: 0.12),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: (item.imageUrl != null &&
                                  item.imageUrl!.isNotEmpty)
                              ? Image.network(
                                  item.imageUrl!,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 56,
                                    height: 56,
                                    color: AppTheme.grisPistacho
                                        .withValues(alpha: 0.06),
                                    child: const Icon(
                                      Icons.checkroom_rounded,
                                      color: AppTheme.grisPistacho,
                                      size: 22,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 56,
                                  height: 56,
                                  color: AppTheme.grisPistacho
                                      .withValues(alpha: 0.06),
                                  child: const Icon(
                                    Icons.checkroom_rounded,
                                    color: AppTheme.grisPistacho,
                                    size: 22,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Detalls del producte
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.grisPistacho,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              [
                                if (item.color.isNotEmpty) item.color,
                                if (item.size.isNotEmpty) item.size,
                                if (item.quantity > 1) 'x${item.quantity}',
                              ].join(' / '),
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppTheme.grisPistacho
                                    .withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Preu + eliminar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${item.totalPrice.toStringAsFixed(2).replaceAll('.', ',')} \u20ac',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.grisPistacho,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Botó eliminar — torna a shipping per recalcular
                          InkWell(
                            onTap: () {
                              cart.removeItem(item.syncVariantId);
                              if (cart.isEmpty) {
                                Navigator.pushReplacementNamed(
                                    context, '/cart');
                              } else {
                                checkout.goBack();
                                checkout.fetchShippingRates(cart.items);
                              }
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppTheme.grisPistacho
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 24),
              // Enviament (preu real del servidor si ha canviat)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Enviament (${checkout.selectedRate?.name ?? ''})',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.grisPistacho,
                    ),
                  ),
                  Text(
                    checkout.serverShippingCents != null
                        ? '${(checkout.serverShippingCents! / 100).toStringAsFixed(2).replaceAll('.', ',')} EUR'
                        : '${(checkout.selectedRate?.rateAsDouble ?? 0).toStringAsFixed(2).replaceAll('.', ',')} EUR',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.grisPistacho,
                    ),
                  ),
                ],
              ),
              // Avís si la tarifa d'enviament ha canviat
              if (checkout.shippingRateDiff != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.mostassa.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.mostassa.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppTheme.mostassa,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'La tarifa d\'enviament s\'ha actualitzat respecte l\'estimació inicial '
                          '(${checkout.shippingRateDiff! > 0 ? '+' : ''}${checkout.shippingRateDiff!.toStringAsFixed(2).replaceAll('.', ',')} €). '
                          'El preu final reflecteix el cost real.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppTheme.mostassa.withValues(alpha: 0.9),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Total
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.porpraFosc.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.grisPistacho,
                      ),
                    ),
                    Text(
                      '${totalEur.toStringAsFixed(2).replaceAll('.', ',')} EUR',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.grisPistacho,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Botó pagar — estil mostassa com les altres pantalles
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handlePayment(context),
                  icon: const Icon(Icons.lock_rounded, size: 20),
                  label: Text(
                    'Pagar ${totalEur.toStringAsFixed(2).replaceAll('.', ',')} EUR',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.mostassa,
                    foregroundColor: AppTheme.porpraFosc,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Nota de seguretat
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: AppTheme.grisPistacho.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Pagament segur amb Stripe',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppTheme.grisPistacho.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => context.read<CheckoutProvider>().goBack(),
                icon: Icon(
                  Icons.arrow_back_rounded,
                  size: 18,
                  color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                ),
                label: Text(
                  'Tornar',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePayment(BuildContext context) async {
    final checkout = context.read<CheckoutProvider>();
    final cart = context.read<CartProvider>();

    if (kIsWeb) {
      // Web: redirigir a Stripe Checkout
      final url = checkout.checkoutUrl;
      if (url == null) return;
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        // Buidem el carretó abans de redirigir (el webhook s'encarrega de la resta)
        cart.clear();
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    // Mòbil: PaymentSheet nativa
    if (checkout.clientSecret == null) return;

    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: checkout.clientSecret!,
          merchantDisplayName: 'El Visionat',
          style: ThemeMode.light,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      checkout.confirmPayment();
      cart.clear();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pagament completat!'),
            backgroundColor: AppTheme.verdeEncert,
          ),
        );
      }
    } on StripeException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.error.localizedMessage ?? 'Error en el pagament'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}

// =============================================================================
// Step 4: Confirmació
// =============================================================================
class _ConfirmationStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final checkout = context.watch<CheckoutProvider>();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppTheme.verdeEncert,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Comanda confirmada!',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.porpraFosc,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Gràcies per la teva compra. Rebràs un email\nde confirmació quan la comanda estigui en camí.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            if (checkout.orderId != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppTheme.grisPistacho.withValues(alpha: 0.06),
                ),
                child: Text(
                  'ID comanda: ${checkout.orderId}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.grisPistacho,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                checkout.reset();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/vestidor',
                  (route) => route.settings.name == '/home' || route.isFirst,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.porpraFosc,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Tornar a la botiga'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                checkout.reset();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/orders',
                  (route) => route.settings.name == '/home' || route.isFirst,
                );
              },
              child: const Text(
                'Veure les meves comandes',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mostassa,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
