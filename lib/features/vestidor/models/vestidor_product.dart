// ============================================================================
// Models Dart per als productes de Printful
// ============================================================================
// Mapeig de les respostes de les Cloud Functions getPrintfulProducts
// i getPrintfulProduct a classes Dart immutables.
// ============================================================================

/// Producte sincronitzat de la botiga Printful (llistat)
class VestidorProduct {
  final int id;
  final String externalId;
  final String name;
  final int variantsCount;
  final int synced;
  final String? thumbnailUrl;
  final bool isIgnored;

  const VestidorProduct({
    required this.id,
    required this.externalId,
    required this.name,
    required this.variantsCount,
    required this.synced,
    this.thumbnailUrl,
    required this.isIgnored,
  });

  factory VestidorProduct.fromMap(Map<String, dynamic> map) {
    return VestidorProduct(
      id: map['id'] as int,
      externalId: (map['external_id'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      variantsCount: (map['variants'] ?? 0) as int,
      synced: (map['synced'] ?? 0) as int,
      thumbnailUrl: map['thumbnail_url'] as String?,
      isIgnored: (map['is_ignored'] ?? false) as bool,
    );
  }

  @override
  String toString() => 'VestidorProduct(id: $id, name: $name)';
}

/// Variant sincronitzada d'un producte
class VestidorVariant {
  final int id;
  final String externalId;
  final int syncProductId;
  final String name;
  final bool synced;
  final int variantId;
  final String retailPrice;
  final String currency;
  final bool isIgnored;
  final String? sku;
  final CatalogVariantInfo product;
  final List<PrintfulFile> files;
  final List<PrintfulOption> options;
  final String availabilityStatus;
  final String color;
  final String size;
  final String? bestPreviewUrl;

  const VestidorVariant({
    required this.id,
    required this.externalId,
    required this.syncProductId,
    required this.name,
    required this.synced,
    required this.variantId,
    required this.retailPrice,
    required this.currency,
    required this.isIgnored,
    this.sku,
    required this.product,
    required this.files,
    required this.options,
    required this.availabilityStatus,
    required this.color,
    required this.size,
    this.bestPreviewUrl,
  });

  factory VestidorVariant.fromMap(Map<String, dynamic> map) {
    return VestidorVariant(
      id: map['id'] as int,
      externalId: (map['external_id'] ?? '') as String,
      syncProductId: (map['sync_product_id'] ?? 0) as int,
      name: (map['name'] ?? '') as String,
      synced: (map['synced'] ?? false) as bool,
      variantId: (map['variant_id'] ?? 0) as int,
      retailPrice: (map['retail_price'] ?? '0') as String,
      currency: (map['currency'] ?? 'EUR') as String,
      isIgnored: (map['is_ignored'] ?? false) as bool,
      sku: map['sku'] as String?,
      product: CatalogVariantInfo.fromMap(
        Map<String, dynamic>.from((map['product'] ?? {}) as Map),
      ),
      files: ((map['files'] ?? []) as List<dynamic>)
          .map((f) => PrintfulFile.fromMap(Map<String, dynamic>.from(f as Map)))
          .toList(),
      options: ((map['options'] ?? []) as List<dynamic>)
          .map(
            (o) => PrintfulOption.fromMap(Map<String, dynamic>.from(o as Map)),
          )
          .toList(),
      availabilityStatus: (map['availability_status'] ?? '') as String,
      color: (map['color'] ?? '') as String,
      size: (map['size'] ?? '') as String,
      bestPreviewUrl: map['bestPreviewUrl'] as String?,
    );
  }

  /// Preu com a double per a comparacions i ordenació
  double get priceAsDouble => double.tryParse(retailPrice) ?? 0.0;

  /// Talla: product.size (enriquit del catàleg) → variant.size (sync) → ''
  String get sizeName {
    if (product.size.isNotEmpty) return product.size;
    if (size.isNotEmpty) return size;
    return '';
  }

  /// Color: product.color (enriquit del catàleg) → variant.color (sync) → ''
  String get colorName {
    if (product.color.isNotEmpty) return product.color;
    if (color.isNotEmpty) return color;
    return '';
  }

  /// Codi hex del color (ex: "#FFFFFF")
  String get colorCode => product.colorCode;

  /// Retorna la millor URL d'imatge personalitzada (mockup) per aquest variant.
  /// Prioritza: mockupUrl > previewUrl > url > thumbnailUrl dins de PrintfulFile amb type 'preview' o 'default'.
  String? get mockupUrl {
    for (final file in files) {
      if (file.type == 'preview' || file.type == 'default') {
        if (file.mockupUrl != null && file.mockupUrl!.isNotEmpty) return file.mockupUrl;
        if (file.previewUrl != null && file.previewUrl!.isNotEmpty) return file.previewUrl;
        if (file.url != null && file.url!.isNotEmpty) return file.url;
        if (file.thumbnailUrl != null && file.thumbnailUrl!.isNotEmpty) return file.thumbnailUrl;
      }
    }
    // Si no hi ha cap file de tipus preview/default, retorna la millor URL de qualsevol file
    for (final file in files) {
      if (file.mockupUrl != null && file.mockupUrl!.isNotEmpty) return file.mockupUrl;
      if (file.previewUrl != null && file.previewUrl!.isNotEmpty) return file.previewUrl;
      if (file.url != null && file.url!.isNotEmpty) return file.url;
      if (file.thumbnailUrl != null && file.thumbnailUrl!.isNotEmpty) return file.thumbnailUrl;
    }
    // Si no hi ha res, retorna la imatge base del catàleg
    return product.image;
  }

  @override
  String toString() =>
      'VestidorVariant(id: $id, name: $name, price: $retailPrice)';
}

/// Informació bàsica del variant del catàleg Printful
class CatalogVariantInfo {
  final int variantId;
  final int productId;
  final String image;
  final String name;
  final String color;
  final String size;
  final String colorCode;

  const CatalogVariantInfo({
    required this.variantId,
    required this.productId,
    required this.image,
    required this.name,
    required this.color,
    required this.size,
    required this.colorCode,
  });

  factory CatalogVariantInfo.fromMap(Map<String, dynamic> map) {
    return CatalogVariantInfo(
      variantId: (map['variant_id'] ?? 0) as int,
      productId: (map['product_id'] ?? 0) as int,
      image: (map['image'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      color: (map['color'] ?? '') as String,
      size: (map['size'] ?? '') as String,
      colorCode: (map['color_code'] ?? '') as String,
    );
  }
}

/// Fitxer associat a un variant (mockup, imatge de producte, etc.)
class PrintfulFile {
  final int id;
  final String type;
  final String? hash;
  final String? url;
  final String? filename;
  final String? mimeType;
  final int size;
  final int width;
  final int height;
  final int? dpi;
  final String status;
  final int created;
  final String? thumbnailUrl;
  final String? previewUrl;
  final String? mockupUrl; // <-- CAMP AFEGIT
  final bool visible;
  final bool isTemporary;

  const PrintfulFile({
    required this.id,
    required this.type,
    this.hash,
    this.url,
    this.filename,
    this.mimeType,
    required this.size,
    required this.width,
    required this.height,
    this.dpi,
    required this.status,
    required this.created,
    this.thumbnailUrl,
    this.previewUrl,
    this.mockupUrl, // <-- CAMP AFEGIT
    required this.visible,
    required this.isTemporary,
  });

  factory PrintfulFile.fromMap(Map<String, dynamic> map) {
    return PrintfulFile(
      id: (map['id'] ?? 0) as int,
      type: (map['type'] ?? '') as String,
      hash: map['hash'] as String?,
      url: map['url'] as String?,
      filename: map['filename'] as String?,
      mimeType: map['mime_type'] as String?,
      size: (map['size'] ?? 0) as int,
      width: (map['width'] ?? 0) as int,
      height: (map['height'] ?? 0) as int,
      dpi: map['dpi'] as int?,
      status: (map['status'] ?? '') as String,
      created: (map['created'] ?? 0) as int,
      thumbnailUrl: map['thumbnail_url'] as String?,
      previewUrl: map['preview_url'] as String?,
      mockupUrl: map['mockup_url'] as String?, // Printful API retorna 'mockup_url'
      visible: (map['visible'] ?? false) as bool,
      isTemporary: (map['is_temporary'] ?? false) as bool,
    );
  }

  /// URL de millor qualitat disponible, prioritzant el mockup.
  String? get bestUrl => mockupUrl ?? previewUrl ?? url ?? thumbnailUrl;
}

/// Opció de configuració d'un variant
class PrintfulOption {
  final String id;
  final dynamic value;

  const PrintfulOption({
    required this.id,
    required this.value,
  });

  factory PrintfulOption.fromMap(Map<String, dynamic> map) {
    return PrintfulOption(
      id: (map['id'] ?? '') as String,
      value: map['value'],
    );
  }
}
