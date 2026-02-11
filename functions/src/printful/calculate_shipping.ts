// ============================================================================
// Cloud Function: calculateShipping
// ============================================================================
// Calcula les tarifes d'enviament via Printful POST /shipping/rates
// onRequest amb CORS per compatibilitat web + mobile
// ============================================================================

import {onRequest} from "firebase-functions/v2/https";
import {printfulApiKey, pfPost} from "./utils";

interface PrintfulShippingRate {
  id: string;
  name: string;
  rate: string;
  currency: string;
  minDeliveryDays: number;
  maxDeliveryDays: number;
  minDeliveryDate: string;
  maxDeliveryDate: string;
}

interface ShippingRatesResponse {
  result: PrintfulShippingRate[];
}

export const calculateShipping = onRequest(
  {
    region: "europe-west1",
    secrets: [printfulApiKey],
    timeoutSeconds: 30,
    memory: "256MiB",
    cors: true,
  },
  async (req, res) => {
    // Només acceptem POST
    if (req.method !== "POST") {
      res.status(405).json({error: "Mètode no permès"});
      return;
    }

    const {recipient, items} = req.body as {
      recipient: {
        address1: string;
        address2?: string;
        city: string;
        stateCode?: string;
        countryCode: string;
        zip: string;
      };
      items: Array<{variant_id: number; quantity: number}>;
    };

    if (!recipient || !items || items.length === 0) {
      res.status(400).json({
        error: "Falten dades: recipient i items són obligatoris",
      });
      return;
    }

    try {
      const apiKey = printfulApiKey.value();

      const pfRequestBody = {
        recipient: {
          address1: recipient.address1,
          address2: recipient.address2 || undefined,
          city: recipient.city,
          state_code: recipient.stateCode || undefined,
          country_code: recipient.countryCode,
          zip: recipient.zip,
        },
        items: items.map((i) => ({
          variant_id: i.variant_id,
          quantity: i.quantity,
        })),
        currency: "EUR",
      };

      // LOG: Request complet enviat a Printful
      console.log(
        "[Shipping] REQUEST a Printful /shipping/rates:",
        JSON.stringify(pfRequestBody, null, 2)
      );

      const result = await pfPost<ShippingRatesResponse>(
        "/shipping/rates",
        pfRequestBody,
        apiKey
      );

      // LOG: Response complet de Printful
      console.log(
        "[Shipping] RESPONSE de Printful:",
        JSON.stringify(result, null, 2)
      );

      const rates = result.result.map((r) => ({
        id: r.id,
        name: r.name,
        rate: r.rate,
        currency: r.currency,
        minDeliveryDays: r.minDeliveryDays,
        maxDeliveryDays: r.maxDeliveryDays,
      }));

      console.log(
        `[Shipping] ${rates.length} tarifes per ${recipient.countryCode} ` +
        `(${items.length} items) → STANDARD: ${rates.find((r) => r.id === "STANDARD")?.rate ?? "N/A"} EUR`
      );

      res.status(200).json({rates});
    } catch (error) {
      console.error("[Shipping] Error calculant enviament:", error);
      res.status(500).json({error: "Error calculant les tarifes d'enviament"});
    }
  }
);
