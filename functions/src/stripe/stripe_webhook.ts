// ============================================================================
// Cloud Function: stripeWebhook
// ============================================================================
// Webhook HTTP que rep events de Stripe (payment_intent.succeeded, etc.)
// Verifica la signatura, actualitza la comanda i crea l'ordre a Printful.
// ============================================================================

import {onRequest} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import * as admin from "firebase-admin";
import type Stripe from "stripe";
import {printfulApiKey, pfPost} from "../printful/utils";

const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");
const stripeWebhookSecret = defineSecret("STRIPE_WEBHOOK_SECRET");

interface PrintfulOrderResponse {
  result: {
    id: number;
    status: string;
  };
}

export const stripeWebhook = onRequest(
  {
    region: "europe-west1",
    secrets: [stripeSecretKey, stripeWebhookSecret, printfulApiKey],
    timeoutSeconds: 60,
    memory: "256MiB",
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Mètode no permès");
      return;
    }

    const {default: StripeSdk} = await import("stripe");
    const stripe = new StripeSdk(stripeSecretKey.value());
    const sig = req.headers["stripe-signature"] as string;

    let event: Stripe.Event;

    try {
      // CRÍTIC: req.rawBody és proporcionat per Firebase Functions v2
      event = stripe.webhooks.constructEvent(
        req.rawBody,
        sig,
        stripeWebhookSecret.value()
      );
    } catch (err) {
      console.error("[Stripe Webhook] Error verificant signatura:", err);
      res.status(400).send("Signatura invàlida");
      return;
    }

    const db = admin.firestore();

    try {
      switch (event.type) {
      case "payment_intent.succeeded": {
        const paymentIntent = event.data.object as Stripe.PaymentIntent;
        const orderId = paymentIntent.metadata.orderId;

        if (!orderId) {
          console.warn("[Stripe Webhook] PaymentIntent sense orderId:", paymentIntent.id);
          break;
        }

        console.log(
          `[Stripe Webhook] Pagament confirmat: ${paymentIntent.id} → ordre ${orderId}`
        );

        const orderRef = db.collection("orders").doc(orderId);
        const orderSnap = await orderRef.get();

        if (!orderSnap.exists) {
          console.error(`[Stripe Webhook] Ordre ${orderId} no trobada`);
          break;
        }

        const order = orderSnap.data()!;

        // Actualitzar status a 'paid'
        await orderRef.update({
          status: "paid",
          paidAt: admin.firestore.Timestamp.now(),
          updatedAt: admin.firestore.Timestamp.now(),
        });

        // Crear comanda a Printful
        try {
          const printfulItems = order.items.map((item: {
              sync_variant_id: number;
              quantity: number;
              retail_price: string;
              name: string;
            }) => ({
            sync_variant_id: item.sync_variant_id,
            quantity: item.quantity,
            retail_price: item.retail_price,
            name: item.name,
          }));

          const pfOrder = await pfPost<PrintfulOrderResponse>(
            "/orders",
            {
              recipient: {
                name: order.address.name,
                address1: order.address.address1,
                address2: order.address.address2 || undefined,
                city: order.address.city,
                state_code: order.address.stateCode || undefined,
                country_code: order.address.countryCode,
                zip: order.address.zip,
                phone: order.address.phone || undefined,
                email: order.address.email || undefined,
              },
              items: printfulItems,
            },
            printfulApiKey.value()
          );

          await orderRef.update({
            status: "submitted_to_printful",
            printfulOrderId: pfOrder.result.id.toString(),
            updatedAt: admin.firestore.Timestamp.now(),
          });

          console.log(
            `[Stripe Webhook] Ordre ${orderId} enviada a Printful ` +
              `(PF ID: ${pfOrder.result.id})`
          );
        } catch (pfError) {
          console.error(
            `[Stripe Webhook] Error creant ordre Printful per ${orderId}:`,
            pfError
          );
          await orderRef.update({
            status: "failed",
            error: `Error Printful: ${pfError}`,
            updatedAt: admin.firestore.Timestamp.now(),
          });
        }

        break;
      }

      case "payment_intent.payment_failed": {
        const paymentIntent = event.data.object as Stripe.PaymentIntent;
        const orderId = paymentIntent.metadata.orderId;

        if (orderId) {
          await db.collection("orders").doc(orderId).update({
            status: "failed",
            error: "Pagament rebutjat per Stripe",
            updatedAt: admin.firestore.Timestamp.now(),
          });
          console.log(
            `[Stripe Webhook] Pagament fallat: ${paymentIntent.id} → ordre ${orderId}`
          );
        }
        break;
      }

      default:
        console.log(`[Stripe Webhook] Event no gestionat: ${event.type}`);
      }
    } catch (error) {
      console.error("[Stripe Webhook] Error processant event:", error);
      // Sempre retornar 200 per evitar reintents infinits
    }

    res.status(200).json({received: true});
  }
);
