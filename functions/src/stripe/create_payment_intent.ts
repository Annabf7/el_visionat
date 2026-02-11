// ============================================================================
// Cloud Function: createPaymentIntent
// ============================================================================
// Crea un PaymentIntent de Stripe i un document de comanda a Firestore.
// MVP: Confia en els preus del client (validats per getPrintfulProduct).
// ============================================================================

import {onCall, HttpsError} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import * as admin from "firebase-admin";
import {printfulApiKey, pfPost} from "../printful/utils";
import {OrderItem, ShippingAddress, OrderDocument} from "../printful/order_types";

const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");

interface CreatePaymentRequest {
  items: OrderItem[];
  address: ShippingAddress;
  shippingRateId: string;
  platform?: "web" | "mobile";
}

interface PrintfulShippingRate {
  id: string;
  name: string;
  rate: string;
  currency: string;
}

interface ShippingRatesResponse {
  result: PrintfulShippingRate[];
}

export const createPaymentIntent = onCall(
  {
    region: "europe-west1",
    secrets: [stripeSecretKey, printfulApiKey],
    timeoutSeconds: 60,
    memory: "256MiB",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Cal estar autenticat");
    }

    const uid = request.auth.uid;
    const {items, address, shippingRateId, platform} =
      request.data as CreatePaymentRequest;

    // Validació bàsica
    if (!items || items.length === 0) {
      throw new HttpsError("invalid-argument", "El carretó és buit");
    }
    if (!address || !address.address1 || !address.city || !address.zip) {
      throw new HttpsError("invalid-argument", "Adreça incompleta");
    }
    if (!shippingRateId) {
      throw new HttpsError("invalid-argument", "Falta el mètode d'enviament");
    }

    try {
      const {default: Stripe} = await import("stripe");
      const stripe = new Stripe(stripeSecretKey.value());
      const db = admin.firestore();

      // 1. Calcular subtotal dels items
      const subtotalEur = items.reduce((sum, item) => {
        return sum + parseFloat(item.retail_price) * item.quantity;
      }, 0);

      // 2. Obtenir cost d'enviament via Printful
      const apiKey = printfulApiKey.value();
      const shippingResult = await pfPost<ShippingRatesResponse>(
        "/shipping/rates",
        {
          recipient: {
            address1: address.address1,
            address2: address.address2 || undefined,
            city: address.city,
            state_code: address.stateCode || undefined,
            country_code: address.countryCode,
            zip: address.zip,
          },
          items: items.map((i) => ({
            variant_id: i.variant_id,
            quantity: i.quantity,
          })),
          currency: "EUR",
        },
        apiKey
      );

      const selectedRate = shippingResult.result.find(
        (r) => r.id === shippingRateId
      );
      if (!selectedRate) {
        throw new HttpsError(
          "not-found",
          `Tarifa d'enviament '${shippingRateId}' no disponible`
        );
      }

      // 3. Calcular total en cèntims
      const subtotalCents = Math.round(subtotalEur * 100);
      const shippingCents = Math.round(parseFloat(selectedRate.rate) * 100);
      const totalCents = subtotalCents + shippingCents;

      if (totalCents <= 0) {
        throw new HttpsError("invalid-argument", "L'import total ha de ser positiu");
      }

      // 4. Crear document de comanda a Firestore
      const orderRef = db.collection("orders").doc();
      const now = admin.firestore.Timestamp.now();

      const orderDoc: OrderDocument = {
        uid,
        status: "pending_payment",
        items,
        address,
        shippingRateId,
        shippingRate: selectedRate.rate,
        shippingName: selectedRate.name,
        subtotal: subtotalCents,
        shippingCost: shippingCents,
        totalAmount: totalCents,
        currency: "eur",
        stripePaymentIntentId: "",
        createdAt: now,
        updatedAt: now,
      };
      await orderRef.set(orderDoc);

      // 5. Crear PaymentIntent (MVP: sense Customer ni Ephemeral Key)
      const paymentIntent = await stripe.paymentIntents.create({
        amount: totalCents,
        currency: "eur",
        metadata: {
          orderId: orderRef.id,
          uid,
        },
        automatic_payment_methods: {enabled: true},
      });

      // 6. Actualitzar comanda amb PaymentIntent ID
      await orderRef.update({
        stripePaymentIntentId: paymentIntent.id,
      });

      console.log(
        `[Stripe] PaymentIntent ${paymentIntent.id} creat ` +
        `(${(totalCents / 100).toFixed(2)} EUR) per ordre ${orderRef.id}`
      );

      // 7. Si la petició ve de web, crear Checkout Session (redirect)
      let checkoutUrl: string | null = null;
      if (platform === "web") {
        const session = await stripe.checkout.sessions.create({
          mode: "payment",
          payment_intent_data: {
            metadata: {orderId: orderRef.id, uid},
          },
          line_items: items.map((item) => ({
            price_data: {
              currency: "eur",
              product_data: {name: item.name},
              unit_amount: Math.round(parseFloat(item.retail_price) * 100),
            },
            quantity: item.quantity,
          })).concat([{
            price_data: {
              currency: "eur",
              product_data: {name: `Enviament (${selectedRate.name})`},
              unit_amount: shippingCents,
            },
            quantity: 1,
          }]),
          success_url:
            `${request.rawRequest?.headers?.origin || "https://el-visionat.web.app"}` +
            `/checkout-success?orderId=${orderRef.id}`,
          cancel_url:
            `${request.rawRequest?.headers?.origin || "https://el-visionat.web.app"}/cart`,
        });
        checkoutUrl = session.url;

        // Vincular el PaymentIntent de la Session a la comanda
        if (session.payment_intent) {
          let sessionPiId: string;
          if (typeof session.payment_intent === "string") {
            sessionPiId = session.payment_intent;
          } else {
            sessionPiId = session.payment_intent.id;
          }
          await orderRef.update({stripePaymentIntentId: sessionPiId});
        }

        console.log(
          `[Stripe] Checkout Session creada per ordre ${orderRef.id}`
        );
      }

      return {
        clientSecret: paymentIntent.client_secret,
        checkoutUrl,
        orderId: orderRef.id,
        amount: totalCents,
        shippingCents,
      };
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      console.error("[Stripe] Error creant PaymentIntent:", error);
      throw new HttpsError(
        "internal",
        "Error processant el pagament"
      );
    }
  }
);
