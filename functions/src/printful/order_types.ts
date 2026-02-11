// ============================================================================
// Tipus per a comandes (Printful + Stripe + Firestore)
// ============================================================================

import {Timestamp} from "firebase-admin/firestore";

/** Adreça d'enviament */
export interface ShippingAddress {
  name: string;
  address1: string;
  address2?: string;
  city: string;
  stateCode?: string;
  countryCode: string; // ISO 3166-1 alpha-2 (ex: "ES")
  zip: string;
  phone?: string;
  email: string;
}

/** Element d'una comanda */
export interface OrderItem {
  sync_variant_id: number;
  variant_id: number;
  quantity: number;
  retail_price: string; // ex: "24.95"
  name: string;
}

/** Tarifa d'enviament retornada per Printful */
export interface ShippingRate {
  id: string;
  name: string;
  rate: string; // ex: "5.50"
  currency: string; // "EUR"
  minDeliveryDays: number;
  maxDeliveryDays: number;
}

/** Document de comanda a Firestore (orders/{orderId}) */
export interface OrderDocument {
  uid: string;
  status:
    | "pending_payment"
    | "paid"
    | "submitted_to_printful"
    | "in_production"
    | "shipped"
    | "delivered"
    | "cancelled"
    | "failed";
  items: OrderItem[];
  address: ShippingAddress;
  shippingRateId: string;
  shippingRate: string;
  shippingName: string;
  subtotal: number; // cèntims
  shippingCost: number; // cèntims
  totalAmount: number; // cèntims (subtotal + shipping)
  currency: string;
  stripePaymentIntentId: string;
  printfulOrderId?: number;
  printfulStatus?: string;
  trackingNumber?: string;
  trackingUrl?: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  paidAt?: Timestamp;
  shippedAt?: Timestamp;
}
