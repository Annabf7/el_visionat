// ============================================================================
// Provider per gestionar l'estat de la botiga de merchandising
// ============================================================================
// Gestiona la llista de productes, el detall del producte seleccionat,
// paginació, selecció de variants i estats de càrrega/error.
// Imatges principals de Firebase Storage, indexades per productId + color.
// ============================================================================

import 'package:flutter/foundation.dart';
import '../models/vestidor_product.dart';
import '../services/vestidor_service.dart';

class VestidorProvider extends ChangeNotifier {
  // --- Imatges de Firebase Storage per producte (clau: sync_product.id) ---
  // Cada producte pot tenir imatges per color (_normalize del nom Printful)
  // o '_default' si no depenen del color.
  static const _localProductAssets = <int, Map<String, List<String>>>{
    // Samarreta_1
    417174810: {
      'white': [
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsamarreta%2Funisex-militar.png?alt=media&token=1a025f63-38c1-456c-9089-029d8d76ddda',
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsamarreta%2Funisex-white.png?alt=media&token=9b8c3952-7d2b-4b5b-9cea-e619ce0014ff',
      ],
      'militarygreen': [
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsamarreta%2Funisex-militar.png?alt=media&token=1a025f63-38c1-456c-9089-029d8d76ddda',
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsamarreta%2Funisex-white.png?alt=media&token=9b8c3952-7d2b-4b5b-9cea-e619ce0014ff',
      ],
    },
    // Sudadera unisex — Caputxa
    417174402: {
      'white': [
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fwhite_women_back.png?alt=media&token=392cd634-ef6d-4d87-a615-0daa83407cb7',
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fwhite_front.png?alt=media&token=97737550-7afa-4916-989e-32bfbc5d76bd',
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fwhite_back_side.png?alt=media&token=c138f648-e4b2-42ef-beaa-308341f3a203',
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fwhite_back.png?alt=media&token=2955da48-bce2-4943-a82b-dfc1329e83e3',
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fwhite-product-details.png?alt=media&token=2cc09c81-1f2c-4ab1-a00a-4b3ab90befe0',
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fwhite-front-smile.png?alt=media&token=609f5524-74c5-4837-99f1-85ae00048796',
      ],
      'militarygreen': [
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fgreen_women_front.png?alt=media&token=123fac38-7535-48b3-9a9b-2ed0b301f159',
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fgreen_front.png?alt=media&token=aac74c23-066d-4149-804d-56be9e9ba1db',
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fgreen_back.png?alt=media&token=bba63d69-6b5c-4291-8fae-872f938790d1',
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fback_green_man.png?alt=media&token=2f28f98c-3b2d-4a7c-9cce-f8dcd2941a35',
      ],
    },
    // Sudadera unisex — Coll rodó
    417175589: {
      'white': [
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fcoll%20rodo%2Fwomen_white_back.png?alt=media&token=1664ff00-ddb8-4f4b-9e54-ac096de5b72a',
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fcoll%20rodo%2Fwhite_front.png?alt=media&token=699f1b66-ff19-48ba-bb2f-065394d8f5a9',
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fcoll%20rodo%2Fwhite_back.png?alt=media&token=76076785-1c79-4909-b376-91b29c4e6c80',
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fcoll%20rodo%2Fback_man_white.png?alt=media&token=3b66bbb5-0ec0-480c-8776-3aee8319c075',
      ],
      'militarygreen': [
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fcoll%20rodo%2Ffront_militar.png?alt=media&token=44b96caa-7bed-4a52-9e28-4503a31d34c4',
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fcoll%20rodo%2Fboth_front_back.png?alt=media&token=136e5c5c-7f12-4148-a838-c65beca92cca',
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fcoll%20rodo%2Fback_militar_man.png?alt=media&token=ab82f114-6888-4c73-9929-5fcbb7fe0ad7',
      ],
    },
    // Swimsuit (peça de bany)
    418002497: {
      '_default': [
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fbany%2Fwhite_front_swim.png?alt=media&token=209f8f2e-fee9-48d5-9873-fec7c3ba2b1a',
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fbany%2Fwhite_back_swim.png?alt=media&token=a4aa48cc-25f6-4662-aa15-a3ea0bd6fcd5',
      ],
    },
    // TimeOut (xanclas)
    416653701: {
      '_default': [
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fxanclas%2Fxanclas_1.png?alt=media&token=26db40ed-d96b-4ab9-bc25-39cbe61325bc',
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fxanclas%2Fxanclas_2.png?alt=media&token=61542a20-bef7-46f2-82fb-b4522a7bdd34',
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fxanclas%2Fxanclas_3.png?alt=media&token=24bbdc33-241f-431e-b977-fca469ca6101',
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fxanclas%2Fxanclas_4.png?alt=media&token=b283e831-3a97-4eb3-86d2-7779dddf9b1f',
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fxanclas%2Fxanclas_5.png?alt=media&token=cc7fcbe8-755d-4fb8-9081-a1cc7e7ef3f5',
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fxanclas%2Fxanclas_6.png?alt=media&token=9fd15905-073c-4f16-a77f-4586164e784b',
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fxanclas%2Fxanclas_7.png?alt=media&token=8caa9454-da25-41cb-8d4e-9d3933b4a0b1',
      ],
    },
    // tassa_1
    416617132: {
      '_default': ['assets/images/merchandising/tasa_1.png'],
    },
    // tassa_2
    416618634: {
      '_default': ['assets/images/merchandising/tasa_2.png'],
    },
  };

  // --- Thumbnails personalitzades per a la llista de productes ---
  static const _customThumbnails = <int, String>{
    417174402:
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fwhite_front.png?alt=media&token=97737550-7afa-4916-989e-32bfbc5d76bd',
    417175589:
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fcoll%20rodo%2Fwomen_white_back.png?alt=media&token=1664ff00-ddb8-4f4b-9e54-ac096de5b72a',
    417174810:
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsamarreta%2Funisex-militar.png?alt=media&token=1a025f63-38c1-456c-9089-029d8d76ddda',
    416653701:
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fxanclas%2Fxanclas_3.png?alt=media&token=24bbdc33-241f-431e-b977-fca469ca6101',
    418002497:
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fbany%2Fwhite_front_swim.png?alt=media&token=209f8f2e-fee9-48d5-9873-fec7c3ba2b1a',
    // Funda resistent MagSafe — male
    418473545:
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Ffundas%20mobil%2Fiphone-16-male.png?alt=media&token=64f0d7dd-511e-47f2-8426-d0fca939a2e0',
    // Funda resistent MagSafe — female
    418462440:
        'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Ffundas%20mobil%2Fiphone-16-female.png?alt=media&token=99bf506d-e877-4483-810a-2321f85b92af',
  };

  /// Retorna la thumbnail personalitzada per a la llista (o la de Printful)
  String? getCustomThumbnail(VestidorProduct product) {
    return _customThumbnails[product.id] ?? product.thumbnailUrl;
  }

  // --- Estat de la llista de productes ---
  List<VestidorProduct> _products = [];
  List<VestidorProduct> get products => _products;

  bool _isLoadingProducts = false;
  bool get isLoadingProducts => _isLoadingProducts;

  int _totalProducts = 0;
  int get totalProducts => _totalProducts;

  bool get hasMoreProducts => _products.length < _totalProducts;

  // --- Estat del producte seleccionat (detall) ---
  VestidorProduct? _selectedProduct;
  VestidorProduct? get selectedProduct => _selectedProduct;

  List<VestidorVariant> _selectedVariants = [];
  List<VestidorVariant> get selectedVariants => _selectedVariants;

  VestidorVariant? _activeVariant;
  VestidorVariant? get activeVariant => _activeVariant;

  bool _isLoadingDetail = false;
  bool get isLoadingDetail => _isLoadingDetail;

  // --- Error ---
  String? _error;
  String? get error => _error;
  bool get hasError => _error != null;

  // --- Normalització ---

  /// Normalitza una cadena (minúscules, sense accents, sense espais ni guions)
  static String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[àáäâ]'), 'a')
        .replaceAll(RegExp(r'[èéëê]'), 'e')
        .replaceAll(RegExp(r'[ìíïî]'), 'i')
        .replaceAll(RegExp(r'[òóöô]'), 'o')
        .replaceAll(RegExp(r'[ùúüû]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[\s_\-—]+'), '');
  }

  // --- Getters computats ---

  /// Colors disponibles (del catàleg Printful, via variants)
  List<String> get availableColors {
    final colors = <String>{};
    for (final v in _selectedVariants) {
      if (v.colorName.isNotEmpty) colors.add(v.colorName);
    }
    return colors.toList();
  }

  /// Talles disponibles (filtrades pel color actiu, ordenades)
  List<String> get availableSizes {
    final activeColor = _activeVariant?.colorName ?? '';
    final sizes = <String>{};
    for (final v in _selectedVariants) {
      if (activeColor.isEmpty || v.colorName == activeColor) {
        if (v.sizeName.isNotEmpty) sizes.add(v.sizeName);
      }
    }
    const sizeOrder = [
      'XXS', 'XS', 'S', 'M', 'L', 'XL', '2XL', '3XL', '4XL', '5XL',
    ];
    return sizes.toList()
      ..sort((a, b) {
        final ia = sizeOrder.indexOf(a);
        final ib = sizeOrder.indexOf(b);
        if (ia != -1 && ib != -1) return ia.compareTo(ib);
        if (ia != -1) return -1;
        if (ib != -1) return 1;
        return a.compareTo(b);
      });
  }

  /// Rang de preus del producte seleccionat (ex: "24,95 - 29,95 EUR")
  String get priceRange {
    if (_selectedVariants.isEmpty) return '';
    final prices = _selectedVariants.map((v) => v.priceAsDouble).toList()
      ..sort();
    final min = prices.first.toStringAsFixed(2).replaceAll('.', ',');
    final max = prices.last.toStringAsFixed(2).replaceAll('.', ',');
    final currency = _selectedVariants.first.currency;
    if (min == max) return '$min $currency';
    return '$min - $max $currency';
  }

  /// Imatges del variant/color actiu (per a galeria).
  /// Prioritat: Firebase Storage locals → bestPreviewUrl → files Printful → thumbnail.
  List<String> get productImages {
    final productId = _selectedProduct?.id;
    final activeColor = _activeVariant?.colorName ?? '';
    final colorKey = _normalize(activeColor);

    // 1. Firebase Storage locals (per productId + color normalitzat)
    final productAssets =
        productId != null ? _localProductAssets[productId] : null;
    if (productAssets != null) {
      final images = productAssets[colorKey] ?? productAssets['_default'];
      if (images != null && images.isNotEmpty) return images;
    }

    // 2. bestPreviewUrl del variant actiu (mockup Printful específic)
    final bestPreview = _activeVariant?.bestPreviewUrl;
    if (bestPreview != null && bestPreview.isNotEmpty) return [bestPreview];

    // 3. Fallback: files Printful del variant actiu
    final mockup = _activeVariant?.mockupUrl;
    if (mockup != null && mockup.isNotEmpty) return [mockup];

    // 4. Fallback final: thumbnail del producte
    final thumb = _selectedProduct?.thumbnailUrl;
    if (thumb != null && thumb.isNotEmpty) return [thumb];

    return [];
  }

  // --- Mètodes d'acció ---

  /// Carrega la llista de productes (amb paginació).
  /// Si [refresh] és true, es neteja la llista i es carrega des del principi.
  Future<void> loadProducts({bool refresh = false}) async {
    if (_isLoadingProducts) return;

    if (refresh) {
      _products = [];
      _totalProducts = 0;
    }

    _isLoadingProducts = true;
    _error = null;
    notifyListeners();

    try {
      final result = await VestidorService.getProducts(
        offset: _products.length,
        limit: 20,
      );
      _products = [..._products, ...result.products];
      _totalProducts = result.total;
      debugPrint(
        '[VestidorProvider] Carregats ${result.products.length} productes (total: $_totalProducts)',
      );
    } catch (e) {
      _error = 'No s\'han pogut carregar els productes';
      debugPrint('[VestidorProvider] Error: $e');
    }

    _isLoadingProducts = false;
    notifyListeners();
  }

  /// Carrega els detalls d'un producte (variants, imatges, talles).
  Future<void> loadProductDetail(int productId) async {
    _isLoadingDetail = true;
    _selectedProduct = null;
    _selectedVariants = [];
    _activeVariant = null;
    _error = null;
    notifyListeners();

    try {
      final result = await VestidorService.getProduct(productId);
      _selectedProduct = result.product;
      _selectedVariants = result.variants;
      if (_selectedVariants.isNotEmpty) {
        _activeVariant = _selectedVariants.first;
      }
      debugPrint(
        '[VestidorProvider] Detall carregat: ${result.product.name} '
        '(${result.variants.length} variants)',
      );
      debugPrint(
        '[VestidorProvider] Colors: ${availableColors.join(", ")} | '
        'Talles: ${availableSizes.join(", ")}',
      );
    } catch (e) {
      _error = 'No s\'han pogut carregar els detalls del producte';
      debugPrint('[VestidorProvider] Error detall: $e');
    }

    _isLoadingDetail = false;
    notifyListeners();
  }

  /// Selecciona un color: busca variant amb color + talla actual, o la primera del color
  void selectColor(String color) {
    final currentSize = _activeVariant?.sizeName ?? '';
    // Prioritat: mateixa talla + nou color
    final match = _selectedVariants.where(
      (v) => v.colorName == color && v.sizeName == currentSize,
    );
    if (match.isNotEmpty) {
      _activeVariant = match.first;
    } else {
      // Fallback: primera variant amb aquest color
      final fallback = _selectedVariants.where((v) => v.colorName == color);
      if (fallback.isNotEmpty) _activeVariant = fallback.first;
    }
    notifyListeners();
  }

  /// Selecciona una talla: busca variant amb talla + color actual
  void selectSize(String size) {
    final currentColor = _activeVariant?.colorName ?? '';
    final match = _selectedVariants.where(
      (v) => v.sizeName == size && v.colorName == currentColor,
    );
    if (match.isNotEmpty) {
      _activeVariant = match.first;
    } else {
      // Fallback: primera variant amb aquesta talla
      final fallback = _selectedVariants.where((v) => v.sizeName == size);
      if (fallback.isNotEmpty) _activeVariant = fallback.first;
    }
    notifyListeners();
  }

  /// Selecciona un variant actiu directament
  void selectVariant(VestidorVariant variant) {
    _activeVariant = variant;
    notifyListeners();
  }

  /// Neteja el producte seleccionat
  void clearSelectedProduct() {
    _selectedProduct = null;
    _selectedVariants = [];
    _activeVariant = null;
    notifyListeners();
  }

  /// Neteja l'error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
