// ============================================================================
// Provider per gestionar l'estat de la botiga de merchandising
// ============================================================================
// Gestiona la llista de productes, el detall del producte seleccionat,
// paginació, selecció de variants i estats de càrrega/error.
// ============================================================================

import 'package:flutter/foundation.dart';
import '../models/vestidor_product.dart';
import '../services/vestidor_service.dart';

class VestidorProvider extends ChangeNotifier {
  // --- Imatges locals addicionals per producte (diferents plans/angles) ---
  // Clau: patró que ha de coincidir amb el nom del producte (normalitzat)
  // Valor: llista de paths d'assets locals
  static const _localProductAssets = <String, List<String>>{
    // Samarreta_1 (personalitzades per color, optimitzades)
    'samarreta_1_white': [
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsamarreta%2Fwhite_front.png?alt=media&token=1a851494-8279-44c4-8d00-342465210157',
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsamarreta%2Fwhite-front-and-back_2.png?alt=media&token=6ed2b42e-93fa-42e9-a0cf-bb2945979424',
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsamarreta%2Fwhite-back.png?alt=media&token=1d42336c-55ab-4125-86b7-73483bd95a12',
    ],
    'samarreta_1_militar': [
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsamarreta%2Fgreen-front-and-back.png?alt=media&token=e87deb1d-94e1-48dc-a43f-6a4d9deab16e',
    ],
    'tasa_1': ['assets/images/merchandising/tasa_1.png'],
    'tasa_2': ['assets/images/merchandising/tasa_2.png'],
    // Sudadera unisex — Caputxa (personalitzades per color, optimitzades)
    // Color: blanc
    'sudadera unisex — caputxa_white': [
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fwhite_women_back.png?alt=media&token=392cd634-ef6d-4d87-a615-0daa83407cb7',
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fwhite_front.png?alt=media&token=97737550-7afa-4916-989e-32bfbc5d76bd',
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fwhite_back_side.png?alt=media&token=c138f648-e4b2-42ef-beaa-308341f3a203',
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fwhite_back.png?alt=media&token=2955da48-bce2-4943-a82b-dfc1329e83e3',
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fwhite-product-details.png?alt=media&token=2cc09c81-1f2c-4ab1-a00a-4b3ab90befe0',
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fwhite-front-smile.png?alt=media&token=609f5524-74c5-4837-99f1-85ae00048796',
    ],
    // Color: militar
    'sudadera unisex — caputxa_militar': [
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fgreen_women_front.png?alt=media&token=123fac38-7535-48b3-9a9b-2ed0b301f159',
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fgreen_front.png?alt=media&token=aac74c23-066d-4149-804d-56be9e9ba1db',
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fgreen_back.png?alt=media&token=bba63d69-6b5c-4291-8fae-872f938790d1',
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fback_green_man.png?alt=media&token=2f28f98c-3b2d-4a7c-9cce-f8dcd2941a35',
    ],
    // Sudadera unisex — coll rodo (personalitzades per color, optimitzades)
    'sudadera unisex — coll rodo_white': [
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fcoll%20rodo%2Fwomen_white_back.png?alt=media&token=1664ff00-ddb8-4f4b-9e54-ac096de5b72a',
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fcoll%20rodo%2Fwhite_front.png?alt=media&token=699f1b66-ff19-48ba-bb2f-065394d8f5a9',
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fcoll%20rodo%2Fwhite_back.png?alt=media&token=76076785-1c79-4909-b376-91b29c4e6c80',
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fcoll%20rodo%2Fback_man_white.png?alt=media&token=3b66bbb5-0ec0-480c-8776-3aee8319c075',
    ],
    'sudadera unisex — coll rodo_militar': [
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fcoll%20rodo%2Ffront_militar.png?alt=media&token=44b96caa-7bed-4a52-9e28-4503a31d34c4',
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fcoll%20rodo%2Fboth_front_back.png?alt=media&token=136e5c5c-7f12-4148-a838-c65beca92cca',
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fcoll%20rodo%2Fback_militar_man.png?alt=media&token=ab82f114-6888-4c73-9929-5fcbb7fe0ad7',
    ],
    // TimeOut (xanclas) - personalitzades en ordre
    'timeout_xanclas': [
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fxanclas%2Fxanclas_1.png?alt=media&token=26db40ed-d96b-4ab9-bc25-39cbe61325bc',
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fxanclas%2Fxanclas_2.png?alt=media&token=61542a20-bef7-46f2-82fb-b4522a7bdd34',
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fxanclas%2Fxanclas_3.png?alt=media&token=24bbdc33-241f-431e-b977-fca469ca6101',
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fxanclas%2Fxanclas_4.png?alt=media&token=b283e831-3a97-4eb3-86d2-7779dddf9b1f',
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fxanclas%2Fxanclas_5.png?alt=media&token=cc7fcbe8-755d-4fb8-9081-a1cc7e7ef3f5',
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fxanclas%2Fxanclas_6.png?alt=media&token=9fd15905-073c-4f16-a77f-4586164e784b',
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fxanclas%2Fxanclas_7.png?alt=media&token=8caa9454-da25-41cb-8d4e-9d3933b4a0b1',
    ],
  };

  // --- Estat de la llista de productes ---
  List<VestidorProduct> _products = [];
  List<VestidorProduct> get products => _products;
  // Thumbnail personalitzada per a Sudadera unisex — Caputxa
  static const _caputxaCustomThumbnail =
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fwhite_front.png?alt=media&token=97737550-7afa-4916-989e-32bfbc5d76bd';

  /// Retorna la thumbnail personalitzada si el producte és Sudadera unisex — Caputxa
  String? getCustomThumbnail(VestidorProduct product) {
    String normalize(String s) {
      final withNoAccents = s
          .toLowerCase()
          .replaceAll(RegExp(r'[àáäâ]'), 'a')
          .replaceAll(RegExp(r'[èéëê]'), 'e')
          .replaceAll(RegExp(r'[ìíïî]'), 'i')
          .replaceAll(RegExp(r'[òóöô]'), 'o')
          .replaceAll(RegExp(r'[ùúüû]'), 'u')
          .replaceAll(RegExp(r'[ç]'), 'c');
      return withNoAccents.replaceAll(RegExp(r'[\s_-]+'), '');
    }

    final normalizedName = normalize(product.name);
    if (normalizedName == normalize('sudadera unisex — caputxa')) {
      return _caputxaCustomThumbnail;
    }
    if (normalizedName == normalize('sudadera unisex — coll rodo')) {
      return 'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsudaderas%2Fcoll%20rodo%2Fwomen_white_back.png?alt=media&token=1664ff00-ddb8-4f4b-9e54-ac096de5b72a';
    }
    if (normalizedName == normalize('samarreta_1')) {
      // Sempre mostra la imatge militar, independentment del color
      return 'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fsamarreta%2Fgreen-front-and-back.png?alt=media&token=e87deb1d-94e1-48dc-a43f-6a4d9deab16e';
    }
    if (normalizedName == normalize('timeout')) {
      // Thumbnail de TimeOut (xanclas)
      return 'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/El%20vestidor%2Froba%2Fxanclas%2Fxanclas_3.png?alt=media&token=24bbdc33-241f-431e-b977-fca469ca6101';
    }
    return product.thumbnailUrl;
  }

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

  // --- Mockups per color (catalogVariantId → Storage URL) ---
  Map<int, String> _mockups = {};
  Map<int, String> get mockups => _mockups;

  bool _isLoadingMockups = false;
  bool get isLoadingMockups => _isLoadingMockups;

  // --- Error ---
  String? _error;
  String? get error => _error;
  bool get hasError => _error != null;

  // --- Getters computats ---

  /// Colors disponibles
  List<String> get availableColors {
    final colors = <String>{};
    for (final v in _selectedVariants) {
      final color = v.colorName;
      if (color.isNotEmpty) colors.add(color);
    }
    return colors.toList();
  }

  /// Talles disponibles
  List<String> get availableSizes {
    final sizes = <String>{};
    for (final v in _selectedVariants) {
      final size = v.sizeName;
      if (size.isNotEmpty) sizes.add(size);
    }
    return sizes.toList();
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
  /// Aquesta funció segueix la documentació de Printful per prioritzar imatges.
  List<String> get productImages {
    final urls = <String>[];
    final seen = <String>{};

    // Normalitza una cadena (minuscules, sense accents, sense espais ni guions)
    String normalize(String s) {
      final withNoAccents = s
          .toLowerCase()
          .replaceAll(RegExp(r'[àáäâ]'), 'a')
          .replaceAll(RegExp(r'[èéëê]'), 'e')
          .replaceAll(RegExp(r'[ìíïî]'), 'i')
          .replaceAll(RegExp(r'[òóöô]'), 'o')
          .replaceAll(RegExp(r'[ùúüû]'), 'u')
          .replaceAll(RegExp(r'[ç]'), 'c');
      return withNoAccents.replaceAll(RegExp(r'[\s_-]+'), '');
    }

    final productName = _selectedProduct?.name ?? '';
    final normalizedProductName = normalize(productName);
    final activeColor = _activeVariant?.colorName ?? '';
    final normalizedColor = normalize(activeColor);

    // DEBUG: print keys and colors
    debugPrint(
      '[VestidorProvider] productName: "$productName" normalized: "$normalizedProductName"',
    );
    debugPrint(
      '[VestidorProvider] activeColor: "$activeColor" normalized: "$normalizedColor"',
    );
    debugPrint(
      '[VestidorProvider] availableColors: ${availableColors.join(", ")}',
    );

    // Si el producte és Sudadera unisex — Caputxa, Sudadera unisex — coll rodo o Samarreta_1, mostra totes les imatges personalitzades de blanc i militar (carrousel)
    if (normalizedProductName == normalize('sudadera unisex — caputxa') ||
        normalizedProductName == normalize('sudadera unisex — coll rodo') ||
        normalizedProductName == normalize('samarreta_1')) {
      final keys =
          normalizedProductName == normalize('sudadera unisex — caputxa')
          ? [
              'sudadera unisex — caputxa_white',
              'sudadera unisex — caputxa_militar',
            ]
          : normalizedProductName == normalize('sudadera unisex — coll rodo')
          ? [
              'sudadera unisex — coll rodo_white',
              'sudadera unisex — coll rodo_militar',
            ]
          : ['samarreta_1_white', 'samarreta_1_militar'];
      for (final key in keys) {
        final localImages = _localProductAssets[key];
        if (localImages != null && localImages.isNotEmpty) {
          for (final url in localImages) {
            if (seen.add(url)) {
              urls.add(url);
            }
          }
        }
      }
      if (urls.isNotEmpty) return urls;
    }
    // Si el producte és Sudadera unisex — Caputxa, Sudadera unisex — coll rodo, Samarreta_1 o TimeOut, mostra les imatges personalitzades corresponents (carrousel)
    if (normalizedProductName == normalize('sudadera unisex — caputxa') ||
        normalizedProductName == normalize('sudadera unisex — coll rodo') ||
        normalizedProductName == normalize('samarreta_1') ||
        normalizedProductName == normalize('timeout')) {
      final keys =
          normalizedProductName == normalize('sudadera unisex — caputxa')
          ? [
              'sudadera unisex — caputxa_white',
              'sudadera unisex — caputxa_militar',
            ]
          : normalizedProductName == normalize('sudadera unisex — coll rodo')
          ? [
              'sudadera unisex — coll rodo_white',
              'sudadera unisex — coll rodo_militar',
            ]
          : normalizedProductName == normalize('samarreta_1')
          ? ['samarreta_1_white', 'samarreta_1_militar']
          : ['timeout_xanclas'];
      for (final key in keys) {
        final localImages = _localProductAssets[key];
        if (localImages != null && localImages.isNotEmpty) {
          for (final url in localImages) {
            if (seen.add(url)) {
              urls.add(url);
            }
          }
        }
      }
      if (urls.isNotEmpty) return urls;
    }

    // Lògica general (altres productes)
    final variantsToShow = (activeColor.isNotEmpty)
        ? _selectedVariants.where((v) => v.colorName == activeColor)
        : _selectedVariants;

    for (final variant in variantsToShow) {
      // Prioritat 1: Mockup generat manualment (si existeix)
      final generatedMockupUrl = _mockups[variant.variantId];
      if (generatedMockupUrl != null && seen.add(generatedMockupUrl)) {
        urls.add(generatedMockupUrl);
      }

      // Prioritat 2: mockupUrl del model (personalitzada, ja fa la lògica de fallback)
      final best = variant.mockupUrl;
      if (best != null && best.isNotEmpty && seen.add(best)) {
        urls.add(best);
      }
    }

    // Prioritat 3: Imatges locals del projecte (altres productes)
    if (productName.isNotEmpty) {
      // Si el producte és Sudadera unisex — Caputxa, Sudadera unisex — coll rodo o Samarreta_1, mostra totes les imatges personalitzades de blanc i militar (carrousel)
      if (normalizedProductName == normalize('sudadera unisex — caputxa') ||
          normalizedProductName == normalize('sudadera unisex — coll rodo') ||
          normalizedProductName == normalize('samarreta_1')) {
        final keys =
            normalizedProductName == normalize('sudadera unisex — caputxa')
            ? [
                'sudadera unisex — caputxa_white',
                'sudadera unisex — caputxa_militar',
              ]
            : normalizedProductName == normalize('sudadera unisex — coll rodo')
            ? [
                'sudadera unisex — coll rodo_white',
                'sudadera unisex — coll rodo_militar',
              ]
            : ['samarreta_1_white', 'samarreta_1_militar'];
        for (final key in keys) {
          final localImages = _localProductAssets[key];
          if (localImages != null && localImages.isNotEmpty) {
            for (final url in localImages) {
              if (seen.add(url)) {
                urls.add(url);
              }
            }
          }
        }
        if (urls.isNotEmpty) return urls;
      }
    }
    return urls;
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
  /// Després de carregar el detall, llança la generació de mockups en segon pla.
  Future<void> loadProductDetail(int productId) async {
    _isLoadingDetail = true;
    _selectedProduct = null;
    _selectedVariants = [];
    _activeVariant = null;
    _mockups = {};
    _error = null;
    notifyListeners();

    try {
      final result = await VestidorService.getProduct(productId);
      _selectedProduct = result.product;
      _selectedVariants = result.variants;
      if (_selectedVariants.isNotEmpty) {
        // Si el producte és Sudadera Unisex — Caputxa, selecciona el primer color disponible
        final productName = result.product.name.toLowerCase();
        if (productName == 'sudadera unisex — caputxa') {
          final firstColor = _selectedVariants.first.colorName;
          final variantWithColor = _selectedVariants.firstWhere(
            (v) => v.colorName == firstColor,
            orElse: () => _selectedVariants.first,
          );
          _activeVariant = variantWithColor;
        } else {
          _activeVariant = _selectedVariants.first;
        }
      }
      debugPrint(
        '[VestidorProvider] Detall carregat: ${result.product.name} (${result.variants.length} variants)',
      );
      // Debug: mostrar fitxers i imatges de cada variant per diagnosticar
      for (final v in result.variants) {
        final filesSummary = v.files
            .map(
              (f) =>
                  '${f.type}(preview:${f.previewUrl != null}, url:${f.url != null})',
            )
            .join(', ');
        debugPrint(
          '[VestidorProvider] Variant "${v.name}" (catId:${v.variantId}) → '
          'catalogImg: ${v.product.image.isNotEmpty ? "SÍ" : "NO"}, '
          'files: [$filesSummary]',
        );
      }
    } catch (e) {
      _error = 'No s\'han pogut carregar els detalls del producte';
      debugPrint('[VestidorProvider] Error detall: $e');
    }

    _isLoadingDetail = false;
    notifyListeners();

    // Carregar mockups per color en segon pla (no bloqueja la UI)
    _loadMockups(productId);
  }

  /// Carrega els mockups generats per a un producte.
  /// Actualitza la galeria automàticament quan estan llestos.
  Future<void> _loadMockups(int productId) async {
    _isLoadingMockups = true;

    try {
      final result = await VestidorService.getMockups(productId);

      // Verificar que seguim mostrant el mateix producte
      if (_selectedProduct?.id == productId) {
        _mockups = result;
        debugPrint(
          '[VestidorProvider] Mockups carregats: ${result.length} per producte $productId',
        );
      }
    } catch (e) {
      debugPrint('[VestidorProvider] Error mockups: $e');
    }

    _isLoadingMockups = false;
    if (_selectedProduct?.id == productId) {
      notifyListeners();
    }
  }

  /// Selecciona un variant actiu (quan l'usuari clica un chip de talla/color)
  void selectVariant(VestidorVariant variant) {
    _activeVariant = variant;
    notifyListeners();
  }

  /// Neteja el producte seleccionat
  void clearSelectedProduct() {
    _selectedProduct = null;
    _selectedVariants = [];
    _activeVariant = null;
    _mockups = {};
    notifyListeners();
  }

  /// Neteja l'error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
