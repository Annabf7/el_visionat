// ============================================================================
// Printful - Utilitats compartides (pfGet, pfPost)
// ============================================================================

import {defineSecret} from "firebase-functions/params";

export const printfulApiKey = defineSecret("PRINTFUL_API_KEY");
export const PRINTFUL_BASE_URL = "https://api.printful.com";

/** GET genèric a l'API de Printful */
export async function pfGet<T>(path: string, apiKey: string): Promise<T> {
  const res = await fetch(`${PRINTFUL_BASE_URL}${path}`, {
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Printful GET ${path}: ${res.status} - ${text}`);
  }
  return (await res.json()) as T;
}

/** POST genèric a l'API de Printful */
export async function pfPost<T>(
  path: string,
  body: unknown,
  apiKey: string
): Promise<T> {
  const res = await fetch(`${PRINTFUL_BASE_URL}${path}`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Printful POST ${path}: ${res.status} - ${text}`);
  }
  return (await res.json()) as T;
}
