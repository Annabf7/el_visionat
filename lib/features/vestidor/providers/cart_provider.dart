import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/vestidor_product.dart';

/// Provider del carretó de compra amb sync a Firestore (debounce 500ms).
/// Path Firestore: users/{uid}/cart/current
class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  String? _uid;
  Timer? _syncTimer;

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => _items.isEmpty;
  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// Carrega el carretó des de Firestore quan l'usuari fa login
  Future<void> loadCart(String uid) async {
    _uid = uid;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('cart')
          .doc('current')
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        final itemsList = (data['items'] as List<dynamic>?) ?? [];
        _items.clear();
        for (final item in itemsList) {
          _items.add(CartItem.fromMap(Map<String, dynamic>.from(item as Map)));
        }
        debugPrint('[CartProvider] Carretó carregat: ${_items.length} items');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[CartProvider] Error carregant carretó: $e');
    }
  }

  /// Afegeix un producte al carretó (incrementa quantitat si ja existeix)
  void addItem(VestidorVariant variant, VestidorProduct product) {
    final existing = _items.where((i) => i.syncVariantId == variant.id);
    if (existing.isNotEmpty) {
      existing.first.quantity++;
    } else {
      // Construeix el nom del variant
      final parts = <String>[product.name];
      if (variant.colorName.isNotEmpty) parts.add(variant.colorName);
      if (variant.sizeName.isNotEmpty) parts.add(variant.sizeName);

      _items.add(CartItem(
        syncVariantId: variant.id,
        variantId: variant.variantId,
        syncProductId: variant.syncProductId,
        productName: product.name,
        variantName: parts.join(' - '),
        color: variant.colorName,
        size: variant.sizeName,
        retailPrice: variant.priceAsDouble,
        currency: variant.currency,
        imageUrl: variant.bestPreviewUrl ?? variant.mockupUrl ?? product.thumbnailUrl,
      ));
    }
    notifyListeners();
    _scheduleSyncToFirestore();
  }

  /// Elimina un item del carretó
  void removeItem(int syncVariantId) {
    _items.removeWhere((i) => i.syncVariantId == syncVariantId);
    notifyListeners();
    _scheduleSyncToFirestore();
  }

  /// Actualitza la quantitat d'un item
  void updateQuantity(int syncVariantId, int quantity) {
    if (quantity <= 0) {
      removeItem(syncVariantId);
      return;
    }
    final item = _items.where((i) => i.syncVariantId == syncVariantId);
    if (item.isNotEmpty) {
      item.first.quantity = quantity;
      notifyListeners();
      _scheduleSyncToFirestore();
    }
  }

  /// Buida el carretó
  void clear() {
    _items.clear();
    notifyListeners();
    _scheduleSyncToFirestore();
  }

  /// Programa sync a Firestore amb debounce de 500ms
  void _scheduleSyncToFirestore() {
    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(milliseconds: 500), _syncToFirestore);
  }

  /// Escriu el carretó complet a Firestore
  Future<void> _syncToFirestore() async {
    if (_uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('cart')
          .doc('current')
          .set({
        'items': _items.map((i) => i.toMap()).toList(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      debugPrint('[CartProvider] Carretó sincronitzat (${_items.length} items)');
    } catch (e) {
      debugPrint('[CartProvider] Error sincronitzant carretó: $e');
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}
