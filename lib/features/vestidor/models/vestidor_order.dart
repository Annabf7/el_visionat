import 'package:cloud_firestore/cloud_firestore.dart';

/// Comanda del vestidor (merchandising) guardada a Firestore
class VestidorOrder {
  final String id;
  final String uid;
  final String status;
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic> address;
  final String shippingRateId;
  final String shippingRate;
  final String shippingName;
  final int subtotal; // cèntims
  final int shippingCost; // cèntims
  final int totalAmount; // cèntims
  final String currency;
  final String stripePaymentIntentId;
  final String? printfulOrderId;
  final String? trackingNumber;
  final String? trackingUrl;
  final String? error;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? shippedAt;

  const VestidorOrder({
    required this.id,
    required this.uid,
    required this.status,
    required this.items,
    required this.address,
    required this.shippingRateId,
    required this.shippingRate,
    required this.shippingName,
    required this.subtotal,
    required this.shippingCost,
    required this.totalAmount,
    required this.currency,
    required this.stripePaymentIntentId,
    this.printfulOrderId,
    this.trackingNumber,
    this.trackingUrl,
    this.error,
    required this.createdAt,
    this.paidAt,
    this.shippedAt,
  });

  /// Subtotal formatat (EUR)
  String get subtotalFormatted =>
      '${(subtotal / 100).toStringAsFixed(2).replaceAll('.', ',')} EUR';

  /// Enviament formatat
  String get shippingFormatted =>
      '${(shippingCost / 100).toStringAsFixed(2).replaceAll('.', ',')} EUR';

  /// Total formatat
  String get totalFormatted =>
      '${(totalAmount / 100).toStringAsFixed(2).replaceAll('.', ',')} EUR';

  /// Etiqueta d'estat en català
  String get statusLabel {
    switch (status) {
      case 'pending_payment':
        return 'Pendent de pagament';
      case 'paid':
        return 'Pagada';
      case 'submitted_to_printful':
        return 'En processament';
      case 'in_production':
        return 'En producció';
      case 'shipped':
        return 'Enviada';
      case 'delivered':
        return 'Lliurada';
      case 'cancelled':
        return 'Cancel·lada';
      case 'failed':
        return 'Error';
      default:
        return status;
    }
  }

  factory VestidorOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VestidorOrder(
      id: doc.id,
      uid: (data['uid'] ?? '') as String,
      status: (data['status'] ?? '') as String,
      items: ((data['items'] ?? []) as List<dynamic>)
          .map((i) => Map<String, dynamic>.from(i as Map))
          .toList(),
      address: Map<String, dynamic>.from((data['address'] ?? {}) as Map),
      shippingRateId: (data['shippingRateId'] ?? '') as String,
      shippingRate: (data['shippingRate'] ?? '0') as String,
      shippingName: (data['shippingName'] ?? '') as String,
      subtotal: (data['subtotal'] ?? 0) as int,
      shippingCost: (data['shippingCost'] ?? 0) as int,
      totalAmount: (data['totalAmount'] ?? 0) as int,
      currency: (data['currency'] ?? 'eur') as String,
      stripePaymentIntentId: (data['stripePaymentIntentId'] ?? '') as String,
      printfulOrderId: data['printfulOrderId'] as String?,
      trackingNumber: data['trackingNumber'] as String?,
      trackingUrl: data['trackingUrl'] as String?,
      error: data['error'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
      shippedAt: (data['shippedAt'] as Timestamp?)?.toDate(),
    );
  }
}
