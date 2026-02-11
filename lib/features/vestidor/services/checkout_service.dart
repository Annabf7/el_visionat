import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/shipping_address.dart';
import '../models/shipping_rate.dart';

/// Servei per comunicar-se amb les CFs de checkout (calculateShipping, createPaymentIntent)
class CheckoutService {
  static final _functions =
      FirebaseFunctions.instanceFor(region: 'europe-west1');

  /// URL base de les Cloud Functions desplegades
  static const _baseUrl =
      'https://europe-west1-el-visionat.cloudfunctions.net';

  /// Calcula les tarifes d'enviament disponibles via Printful (HTTP POST)
  static Future<List<ShippingRate>> calculateShipping({
    required ShippingAddress address,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/calculateShipping'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'recipient': address.toMap(),
          'items': items,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final ratesList = (data['rates'] as List<dynamic>?) ?? [];

      final rates = ratesList
          .map((r) => ShippingRate.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList();

      debugPrint(
        '[CheckoutService] ${rates.length} tarifes d\'enviament obtingudes',
      );
      return rates;
    } catch (e) {
      debugPrint('[CheckoutService] Error calculant enviament: $e');
      rethrow;
    }
  }

  /// Crea un PaymentIntent (+ Checkout Session si web) i una comanda a Firestore.
  /// Retorna clientSecret (mòbil), checkoutUrl (web), orderId, amount i shippingCents.
  static Future<({String clientSecret, String? checkoutUrl, String orderId, int amount, int shippingCents})>
      createPaymentIntent({
    required List<Map<String, dynamic>> items,
    required ShippingAddress address,
    required String shippingRateId,
  }) async {
    try {
      final callable = _functions.httpsCallable('createPaymentIntent');
      final result = await callable.call<Map<String, dynamic>>({
        'items': items,
        'address': address.toMap(),
        'shippingRateId': shippingRateId,
        'platform': kIsWeb ? 'web' : 'mobile',
      });

      final data = result.data;
      final clientSecret = data['clientSecret'] as String;
      final checkoutUrl = data['checkoutUrl'] as String?;
      final orderId = data['orderId'] as String;
      final amount = data['amount'] as int;
      final shippingCents = (data['shippingCents'] as num?)?.toInt() ?? 0;

      debugPrint(
        '[CheckoutService] PaymentIntent creat: ordre $orderId '
        '(${(amount / 100).toStringAsFixed(2)} EUR, '
        'shipping: ${(shippingCents / 100).toStringAsFixed(2)} EUR)'
        '${checkoutUrl != null ? ' [web checkout]' : ''}',
      );
      return (
        clientSecret: clientSecret,
        checkoutUrl: checkoutUrl,
        orderId: orderId,
        amount: amount,
        shippingCents: shippingCents,
      );
    } catch (e) {
      debugPrint('[CheckoutService] Error creant PaymentIntent: $e');
      rethrow;
    }
  }
}
