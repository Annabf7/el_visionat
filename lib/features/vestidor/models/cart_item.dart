/// Element del carretó de compra
class CartItem {
  final int syncVariantId; // VestidorVariant.id (Printful sync variant)
  final int variantId; // Catalog variant ID (per Printful orders)
  final int syncProductId;
  final String productName;
  final String variantName; // ex: "Samarreta - White / M"
  final String color;
  final String size;
  final double retailPrice; // EUR
  final String currency; // "EUR"
  final String? imageUrl;
  int quantity;

  CartItem({
    required this.syncVariantId,
    required this.variantId,
    required this.syncProductId,
    required this.productName,
    required this.variantName,
    required this.color,
    required this.size,
    required this.retailPrice,
    required this.currency,
    this.imageUrl,
    this.quantity = 1,
  });

  double get totalPrice => retailPrice * quantity;

  /// Serialitza per guardar a Firestore
  Map<String, dynamic> toMap() => {
    'syncVariantId': syncVariantId,
    'variantId': variantId,
    'syncProductId': syncProductId,
    'productName': productName,
    'variantName': variantName,
    'color': color,
    'size': size,
    'retailPrice': retailPrice,
    'currency': currency,
    'imageUrl': imageUrl,
    'quantity': quantity,
  };

  /// Deserialitza des de Firestore
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      syncVariantId: map['syncVariantId'] as int,
      variantId: map['variantId'] as int,
      syncProductId: map['syncProductId'] as int,
      productName: map['productName'] as String,
      variantName: map['variantName'] as String,
      color: (map['color'] ?? '') as String,
      size: (map['size'] ?? '') as String,
      retailPrice: (map['retailPrice'] as num).toDouble(),
      currency: (map['currency'] ?? 'EUR') as String,
      imageUrl: map['imageUrl'] as String?,
      quantity: (map['quantity'] ?? 1) as int,
    );
  }

  /// Converteix a format per enviar a la CF de comanda
  Map<String, dynamic> toOrderItem() => {
    'sync_variant_id': syncVariantId,
    'variant_id': variantId,
    'quantity': quantity,
    'retail_price': retailPrice.toStringAsFixed(2),
    'name': variantName,
  };
}
