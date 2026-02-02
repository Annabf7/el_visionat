// ============================================================================
// Servei per comunicar-se amb les Cloud Functions de Printful
// ============================================================================
// Fa de pont entre el provider Flutter i les Cloud Functions desplegades
// (getPrintfulProducts, getPrintfulProduct). Patró estàtic com GooglePlaces.
// ============================================================================

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../models/vestidor_product.dart';

class VestidorService {
  static final _functions =
      FirebaseFunctions.instanceFor(region: 'europe-west1');

  /// URL base del proxy d'imatges (soluciona CORS per a Flutter web).
  /// Les imatges del CDN de Printful no tenen capçaleres CORS, així que
  /// les redirigim a través de la nostra Cloud Function.
  static const _proxyBase =
      'https://europe-west1-el-visionat.cloudfunctions.net/proxyPrintfulImage';

  /// Transforma una URL del CDN de Printful a una URL del nostre proxy.
  /// Si la URL no és del CDN de Printful, la retorna sense canvis.
  static String? _proxyUrl(String? url) {
    if (url == null || !url.startsWith('https://files.cdn.printful.com/')) {
      return url;
    }
    return '$_proxyBase?url=${Uri.encodeComponent(url)}';
  }

  /// Aplica el proxy a un map de producte (modifica thumbnail_url in-place).
  static Map<String, dynamic> _proxyProductMap(Map<String, dynamic> map) {
    if (map['thumbnail_url'] != null) {
      map['thumbnail_url'] = _proxyUrl(map['thumbnail_url'] as String?);
    }
    return map;
  }

  /// Aplica el proxy a un map de variant (modifica les URLs dels files).
  static Map<String, dynamic> _proxyVariantMap(Map<String, dynamic> map) {
    final files = (map['files'] as List<dynamic>?) ?? [];
    for (int i = 0; i < files.length; i++) {
      final file = Map<String, dynamic>.from(files[i] as Map);
      file['preview_url'] = _proxyUrl(file['preview_url'] as String?);
      file['url'] = _proxyUrl(file['url'] as String?);
      file['thumbnail_url'] = _proxyUrl(file['thumbnail_url'] as String?);
      files[i] = file;
    }
    // Proxy la imatge del catàleg del variant
    final product = map['product'];
    if (product != null) {
      final productMap = Map<String, dynamic>.from(product as Map);
      if (productMap['image'] != null) {
        final img = productMap['image'] as String;
        if (img.startsWith('https://files.cdn.printful.com/')) {
          productMap['image'] = _proxyUrl(img);
        }
      }
      map['product'] = productMap;
    }
    return map;
  }

  /// Obté la llista de productes sincronitzats de la botiga.
  /// Retorna els productes (filtrats: no ignorats) i el total per paginació.
  static Future<({List<VestidorProduct> products, int total})> getProducts({
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final callable = _functions.httpsCallable('getPrintfulProducts');
      final result = await callable.call<Map<String, dynamic>>({
        'offset': offset,
        'limit': limit,
      });

      final data = result.data;
      final productsList = (data['products'] as List<dynamic>?) ?? [];
      final paging = data['paging'] as Map<dynamic, dynamic>?;
      final total = (paging?['total'] ?? 0) as int;

      final products = productsList
          .map((p) {
            final map = Map<String, dynamic>.from(p as Map);
            return VestidorProduct.fromMap(_proxyProductMap(map));
          })
          .where((p) => !p.isIgnored)
          .toList();

      debugPrint(
        '[VestidorService] getProducts: ${products.length} productes (total: $total)',
      );
      return (products: products, total: total);
    } catch (e) {
      debugPrint('[VestidorService] Error obtenint productes: $e');
      rethrow;
    }
  }

  /// Obté els mockups generats per a un producte (un per color).
  /// Retorna un mapa de catalogVariantId → URL de Firebase Storage.
  static Future<Map<int, String>> getMockups(int productId) async {
    try {
      final callable = _functions.httpsCallable('getPrintfulProductMockups');
      final result = await callable.call<Map<String, dynamic>>({
        'productId': productId,
      });

      final data = result.data;
      final mockupsRaw = (data['mockups'] as Map<dynamic, dynamic>?) ?? {};
      final mockups = <int, String>{};
      for (final entry in mockupsRaw.entries) {
        final variantId = int.tryParse(entry.key.toString());
        final url = entry.value.toString();
        if (variantId != null && url.isNotEmpty) {
          mockups[variantId] = url;
        }
      }

      debugPrint(
        '[VestidorService] getMockups($productId): ${mockups.length} mockups',
      );
      return mockups;
    } catch (e) {
      debugPrint('[VestidorService] Error obtenint mockups: $e');
      return {};
    }
  }

  /// Obté els detalls d'un producte amb tots els seus variants.
  static Future<
    ({VestidorProduct product, List<VestidorVariant> variants})
  > getProduct(int productId) async {
    try {
      final callable = _functions.httpsCallable('getPrintfulProduct');
      final result = await callable.call<Map<String, dynamic>>({
        'productId': productId,
      });

      final data = result.data;
      final productMap = Map<String, dynamic>.from(data['product'] as Map);
      final product = VestidorProduct.fromMap(_proxyProductMap(productMap));

      final variantsList = (data['variants'] as List<dynamic>?) ?? [];
      final variants = variantsList
          .map((v) {
            final map = Map<String, dynamic>.from(v as Map);
            return VestidorVariant.fromMap(_proxyVariantMap(map));
          })
          .where((v) => !v.isIgnored)
          .toList();

      debugPrint(
        '[VestidorService] getProduct($productId): ${product.name} (${variants.length} variants)',
      );
      return (product: product, variants: variants);
    } catch (e) {
      debugPrint('[VestidorService] Error obtenint producte $productId: $e');
      rethrow;
    }
  }
}
