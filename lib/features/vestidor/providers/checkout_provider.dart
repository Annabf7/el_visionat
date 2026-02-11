import 'package:flutter/foundation.dart';
import '../models/shipping_address.dart';
import '../models/shipping_rate.dart';
import '../models/cart_item.dart';
import '../services/checkout_service.dart';

/// Estat del pas actual del checkout
enum CheckoutStep { address, shipping, payment, confirmation }

/// Provider per al flux de checkout multi-step
class CheckoutProvider extends ChangeNotifier {
  CheckoutStep _currentStep = CheckoutStep.address;
  ShippingAddress? _address;
  List<ShippingRate> _rates = [];
  ShippingRate? _selectedRate;
  String? _clientSecret;
  String? _checkoutUrl;
  String? _orderId;
  int? _totalAmount;
  bool _isLoading = false;
  String? _error;

  /// Signatura del carretó de l'últim càlcul de shipping
  String _lastCartSignature = '';

  /// Diferència de tarifa entre UI i servidor (null = sense canvi)
  double? _shippingRateDiff;

  /// Cèntims d'enviament del servidor (per mostrar el preu real)
  int? _serverShippingCents;

  // Getters
  CheckoutStep get currentStep => _currentStep;
  ShippingAddress? get address => _address;
  List<ShippingRate> get rates => _rates;
  ShippingRate? get selectedRate => _selectedRate;
  String? get clientSecret => _clientSecret;
  String? get checkoutUrl => _checkoutUrl;
  String? get orderId => _orderId;
  int? get totalAmount => _totalAmount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double? get shippingRateDiff => _shippingRateDiff;
  int? get serverShippingCents => _serverShippingCents;

  /// Genera signatura del carretó per detectar canvis d'items
  static String _cartSignature(List<CartItem> items) {
    final parts = items
        .map((i) => '${i.variantId}:${i.quantity}')
        .toList()
      ..sort();
    return parts.join(',');
  }

  /// Entra/torna al checkout. Preserva l'adreça, recalcula shipping si els items han canviat.
  void enterCheckout(List<CartItem> cartItems) {
    // Neteja estat de pagament (sempre s'ha de refer)
    _clientSecret = null;
    _checkoutUrl = null;
    _orderId = null;
    _totalAmount = null;
    _error = null;
    _shippingRateDiff = null;
    _serverShippingCents = null;

    if (_address == null) {
      // No tenim adreça → pas adreça
      _currentStep = CheckoutStep.address;
      notifyListeners();
      return;
    }

    // Tenim adreça → comprovem si els items han canviat
    final newSignature = _cartSignature(cartItems);
    if (newSignature != _lastCartSignature || _rates.isEmpty) {
      // Items canviats o no tenim rates → recalcular
      _currentStep = CheckoutStep.shipping;
      notifyListeners();
      fetchShippingRates(cartItems);
    } else {
      // Mateixos items i rates existents → tornar a shipping amb rates cacheades
      _currentStep = CheckoutStep.shipping;
      notifyListeners();
    }
  }

  /// Estableix l'adreça i avança a selecció d'enviament
  void setAddress(ShippingAddress address) {
    _address = address;
    _error = null;
    _currentStep = CheckoutStep.shipping;
    notifyListeners();
  }

  /// Obté les tarifes d'enviament de Printful
  Future<void> fetchShippingRates(List<CartItem> cartItems) async {
    if (_address == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final items = cartItems
          .map((i) => {
                'variant_id': i.variantId,
                'quantity': i.quantity,
              })
          .toList();

      _rates = await CheckoutService.calculateShipping(
        address: _address!,
        items: items,
      );

      // Pre-selecciona la primera tarifa
      if (_rates.isNotEmpty) {
        _selectedRate = _rates.first;
      }

      // Guardar signatura del carretó
      _lastCartSignature = _cartSignature(cartItems);
    } catch (e) {
      _error = 'Error obtenint tarifes d\'enviament: $e';
      debugPrint('[CheckoutProvider] $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Selecciona una tarifa d'enviament
  void selectRate(ShippingRate rate) {
    _selectedRate = rate;
    _error = null;
    notifyListeners();
  }

  /// Prepara el pagament: crea PaymentIntent i avança al pas de pagament
  Future<void> preparePayment(List<CartItem> cartItems) async {
    if (_address == null || _selectedRate == null) return;

    _isLoading = true;
    _error = null;
    _shippingRateDiff = null;
    _serverShippingCents = null;
    notifyListeners();

    try {
      final items = cartItems.map((i) => i.toOrderItem()).toList();

      final result = await CheckoutService.createPaymentIntent(
        items: items,
        address: _address!,
        shippingRateId: _selectedRate!.id,
      );

      _clientSecret = result.clientSecret;
      _checkoutUrl = result.checkoutUrl;
      _orderId = result.orderId;
      _totalAmount = result.amount;

      // Detectar si la tarifa d'enviament ha canviat entre UI i servidor
      final uiShippingCents = (_selectedRate!.rateAsDouble * 100).round();
      if ((result.shippingCents - uiShippingCents).abs() > 1) {
        // Diferència > 1 cèntim → canvi real (no rounding)
        _shippingRateDiff = (result.shippingCents - uiShippingCents) / 100;
        _serverShippingCents = result.shippingCents;
        debugPrint(
          '[CheckoutProvider] Tarifa actualitzada: '
          'UI=${uiShippingCents}c vs Server=${result.shippingCents}c '
          '(diff: ${_shippingRateDiff!.toStringAsFixed(2)} EUR)',
        );
      }

      _currentStep = CheckoutStep.payment;
    } catch (e) {
      _error = 'Error preparant el pagament: $e';
      debugPrint('[CheckoutProvider] $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Marca el pagament com a completat i avança a confirmació
  void confirmPayment() {
    _currentStep = CheckoutStep.confirmation;
    _error = null;
    notifyListeners();
  }

  /// Torna al pas anterior
  void goBack() {
    switch (_currentStep) {
      case CheckoutStep.shipping:
        _currentStep = CheckoutStep.address;
        break;
      case CheckoutStep.payment:
        _currentStep = CheckoutStep.shipping;
        break;
      default:
        break;
    }
    _error = null;
    notifyListeners();
  }

  /// Reinicia tot l'estat del checkout
  void reset() {
    _currentStep = CheckoutStep.address;
    _address = null;
    _rates = [];
    _selectedRate = null;
    _clientSecret = null;
    _checkoutUrl = null;
    _orderId = null;
    _totalAmount = null;
    _isLoading = false;
    _error = null;
    _lastCartSignature = '';
    _shippingRateDiff = null;
    _serverShippingCents = null;
    notifyListeners();
  }
}
