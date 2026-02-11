/// Tarifa d'enviament retornada per la CF calculateShipping
class ShippingRate {
  final String id;
  final String name;
  final String rate; // preu com a string (ex: "4.99")
  final String currency;
  final int? minDeliveryDays;
  final int? maxDeliveryDays;

  const ShippingRate({
    required this.id,
    required this.name,
    required this.rate,
    required this.currency,
    this.minDeliveryDays,
    this.maxDeliveryDays,
  });

  double get rateAsDouble => double.tryParse(rate) ?? 0.0;

  /// Text descriptiu dels dies d'entrega
  String get deliveryEstimate {
    if (minDeliveryDays != null && maxDeliveryDays != null) {
      if (minDeliveryDays == maxDeliveryDays) {
        return '$minDeliveryDays dies';
      }
      return '$minDeliveryDays–$maxDeliveryDays dies';
    }
    return '';
  }

  factory ShippingRate.fromMap(Map<String, dynamic> map) {
    return ShippingRate(
      id: (map['id'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      rate: (map['rate'] ?? '0') as String,
      currency: (map['currency'] ?? 'EUR') as String,
      minDeliveryDays: map['minDeliveryDays'] as int?,
      maxDeliveryDays: map['maxDeliveryDays'] as int?,
    );
  }
}
