// ============================================================================
// Printful API - Interfícies TypeScript
// ============================================================================
// Definicions de tipus per a les respostes de l'API REST de Printful (v1).
// Referència: https://developers.printful.com/docs/
// ============================================================================

/** Resposta genèrica de l'API Printful */
export interface PrintfulResponse<T> {
  code: number;
  result: T;
  paging?: PrintfulPaging;
  extra?: unknown[];
}

/** Informació de paginació */
export interface PrintfulPaging {
  total: number;
  offset: number;
  limit: number;
}

/** Producte sincronitzat amb la botiga (llistat) */
export interface SyncProduct {
  id: number;
  external_id: string;
  name: string;
  variants: number;
  synced: number;
  thumbnail_url: string | null;
  is_ignored: boolean;
}

/** Producte sincronitzat amb detalls complets */
export interface SyncProductDetail {
  sync_product: SyncProduct;
  sync_variants: SyncVariant[];
}

/** Variant sincronitzada d'un producte */
export interface SyncVariant {
  id: number;
  external_id: string;
  sync_product_id: number;
  name: string;
  synced: boolean;
  variant_id: number;
  retail_price: string;
  currency: string;
  is_ignored: boolean;
  sku: string | null;
  product: CatalogVariantInfo;
  files: PrintfulFile[];
  options: PrintfulOption[];
  availability_status: string;
}

/** Informació bàsica del variant del catàleg Printful */
export interface CatalogVariantInfo {
  variant_id: number;
  product_id: number;
  image: string;
  name: string;
}

/** Fitxer associat a un variant (mockup, imatge de producte, etc.) */
export interface PrintfulFile {
  id: number;
  type: string;
  hash: string | null;
  url: string | null;
  filename: string | null;
  mime_type: string | null;
  size: number;
  width: number;
  height: number;
  dpi: number | null;
  status: string;
  created: number;
  thumbnail_url: string | null;
  preview_url: string | null;
  visible: boolean;
  is_temporary: boolean;
}

/** Opció de configuració d'un variant */
export interface PrintfulOption {
  id: string;
  value: unknown;
}
