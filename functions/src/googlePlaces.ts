import {onCall, HttpsError} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";

// Secret per la API key de Google Places
const googlePlacesApiKey = defineSecret("GOOGLE_PLACES_API_KEY");

// Interfícies per Google Places API
interface PlacePrediction {
  place_id: string;
  description: string;
}

interface PlacesAutocompleteResponse {
  status: string;
  predictions: PlacePrediction[];
}

interface AddressComponent {
  types: string[];
  long_name: string;
}

interface PlaceDetailsResult {
  address_components: AddressComponent[];
}

interface PlaceDetailsResponse {
  status: string;
  result: PlaceDetailsResult;
}

/**
 * Cloud Function per cercar adreces amb Google Places Autocomplete
 * Evita problemes de CORS en Flutter Web
 */
export const searchAddresses = onCall(
  {region: "europe-west1", secrets: [googlePlacesApiKey]},
  async (request) => {
  // Verificar autenticació
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Cal estar autenticat per utilitzar aquesta funció"
      );
    }

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const body = request.data as any;
    const query = body?.query ?? "";

    if (!query || query.length < 3) {
      return {suggestions: []};
    }

    try {
      const url = new URL("https://maps.googleapis.com/maps/api/place/autocomplete/json");
      url.searchParams.append("input", query);
      url.searchParams.append("key", googlePlacesApiKey.value());
      url.searchParams.append("components", "country:es");
      url.searchParams.append("types", "address");
      url.searchParams.append("language", "ca");

      const response = await fetch(url.toString());
      const result = await response.json() as PlacesAutocompleteResponse;

      if (result.status === "OK") {
        const suggestions = result.predictions.map((p) => ({
          placeId: p.place_id,
          description: p.description,
        }));
        return {suggestions};
      }

      return {suggestions: []};
    } catch (error) {
      console.error("Error cercant adreces:", error);
      throw new HttpsError(
        "internal",
        "Error cercant adreces"
      );
    }
  });

/**
 * Cloud Function per obtenir detalls d'una adreça
 */
export const getPlaceDetails = onCall(
  {region: "europe-west1", secrets: [googlePlacesApiKey]},
  async (request) => {
  // Verificar autenticació
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Cal estar autenticat per utilitzar aquesta funció"
      );
    }

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const body = request.data as any;
    const placeId = body?.placeId ?? "";

    if (!placeId) {
      throw new HttpsError(
        "invalid-argument",
        "El placeId és obligatori"
      );
    }

    try {
      const url = new URL("https://maps.googleapis.com/maps/api/place/details/json");
      url.searchParams.append("place_id", placeId);
      url.searchParams.append("key", googlePlacesApiKey.value());
      url.searchParams.append("fields", "address_components,formatted_address");
      url.searchParams.append("language", "ca");

      const response = await fetch(url.toString());
      const result = await response.json() as PlaceDetailsResponse;

      if (result.status === "OK") {
        const components = result.result.address_components;

        let street = "";
        let streetNumber = "";
        let postalCode = "";
        let city = "";
        let province = "";

        for (const component of components) {
          const types = component.types;
          if (types.includes("route")) {
            street = component.long_name;
          } else if (types.includes("street_number")) {
            streetNumber = component.long_name;
          } else if (types.includes("postal_code")) {
            postalCode = component.long_name;
          } else if (types.includes("locality")) {
            city = component.long_name;
          } else if (types.includes("administrative_area_level_2")) {
            province = component.long_name;
          }
        }

        const fullStreet = streetNumber ? `${street}, ${streetNumber}` : street;

        return {
          street: fullStreet,
          postalCode,
          city,
          province,
        };
      }

      return null;
    } catch (error) {
      console.error("Error obtenint detalls:", error);
      throw new HttpsError(
        "internal",
        "Error obtenint detalls de l'adreça"
      );
    }
  });
