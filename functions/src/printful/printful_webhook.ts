// ============================================================================
// Cloud Function: printfulWebhook
// ============================================================================
// Webhook HTTP que rep events de Printful (package_shipped, order_failed, etc.)
// Actualitza l'estat de la comanda a Firestore amb tracking info.
// ============================================================================

import {onRequest} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

interface PrintfulWebhookPayload {
  type: string;
  data: {
    order: {
      id: number;
      external_id?: string;
      status: string;
    };
    shipment?: {
      carrier: string;
      service: string;
      tracking_number: string;
      tracking_url: string;
    };
  };
}

// Mapeig d'estats Printful → estats interns
const STATUS_MAP: Record<string, string> = {
  "draft": "submitted_to_printful",
  "pending": "submitted_to_printful",
  "failed": "failed",
  "canceled": "cancelled",
  "inprocess": "in_production",
  "onhold": "in_production",
  "partial": "shipped",
  "fulfilled": "shipped",
};

export const printfulWebhook = onRequest(
  {
    region: "europe-west1",
    timeoutSeconds: 30,
    memory: "256MiB",
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Mètode no permès");
      return;
    }

    const payload = req.body as PrintfulWebhookPayload;
    const db = admin.firestore();

    try {
      const pfOrderId = payload.data?.order?.id?.toString();

      if (!pfOrderId) {
        console.warn("[Printful Webhook] Payload sense order ID");
        res.status(200).json({received: true});
        return;
      }

      console.log(
        `[Printful Webhook] Event '${payload.type}' per ordre Printful ${pfOrderId}`
      );

      // Buscar la comanda per printfulOrderId
      const ordersQuery = await db
        .collection("orders")
        .where("printfulOrderId", "==", pfOrderId)
        .limit(1)
        .get();

      if (ordersQuery.empty) {
        console.warn(
          `[Printful Webhook] Ordre amb PF ID ${pfOrderId} no trobada a Firestore`
        );
        res.status(200).json({received: true});
        return;
      }

      const orderDoc = ordersQuery.docs[0];
      const updateData: Record<string, unknown> = {
        updatedAt: admin.firestore.Timestamp.now(),
      };

      switch (payload.type) {
      case "package_shipped": {
        updateData.status = "shipped";
        updateData.shippedAt = admin.firestore.Timestamp.now();

        if (payload.data.shipment) {
          updateData.trackingNumber = payload.data.shipment.tracking_number;
          updateData.trackingUrl = payload.data.shipment.tracking_url;
          updateData.carrier = payload.data.shipment.carrier;
        }

        console.log(
          `[Printful Webhook] Ordre ${orderDoc.id} enviada ` +
            `(tracking: ${payload.data.shipment?.tracking_number || "N/A"})`
        );
        break;
      }

      case "order_updated": {
        const pfStatus = payload.data.order.status;
        const mappedStatus = STATUS_MAP[pfStatus];

        if (mappedStatus) {
          updateData.status = mappedStatus;
          console.log(
            `[Printful Webhook] Ordre ${orderDoc.id} actualitzada: ${pfStatus} → ${mappedStatus}`
          );
        } else {
          console.log(
            `[Printful Webhook] Ordre ${orderDoc.id} estat PF desconegut: ${pfStatus}`
          );
        }
        break;
      }

      case "order_failed": {
        updateData.status = "failed";
        updateData.error = "Ordre fallada a Printful";
        console.error(
          `[Printful Webhook] Ordre ${orderDoc.id} ha fallat a Printful`
        );
        break;
      }

      case "order_canceled": {
        updateData.status = "cancelled";
        console.log(
          `[Printful Webhook] Ordre ${orderDoc.id} cancel·lada a Printful`
        );
        break;
      }

      default:
        console.log(
          `[Printful Webhook] Event no gestionat: ${payload.type}`
        );
      }

      await orderDoc.ref.update(updateData);
    } catch (error) {
      console.error("[Printful Webhook] Error processant event:", error);
    }

    res.status(200).json({received: true});
  }
);
