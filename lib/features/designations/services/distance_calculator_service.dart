import 'dart:developer' as developer;
import 'package:cloud_functions/cloud_functions.dart';

/// Servei per calcular distàncies entre adreces utilitzant Google Maps Distance Matrix API
/// via Firebase Cloud Functions per mantenir la clau API segura
class DistanceCalculatorService {
  /// Calcula la distància en quilòmetres entre dues adreces
  ///
  /// Utilitza Firebase Cloud Function 'calculateDistance' que crida
  /// a Google Maps Distance Matrix API amb la clau API guardada a Firebase Secrets
  ///
  /// Returns:
  /// - double: Distància en quilòmetres
  /// - 0.0 si hi ha algun error o no es pot calcular
  static Future<double> calculateDistance({
    required String originAddress,
    required String destinationAddress,
  }) async {
    try {
      // Validar que les adreces no estiguin buides
      if (originAddress.trim().isEmpty || destinationAddress.trim().isEmpty) {
        developer.log(
          'Error: Origin or destination address is empty',
          name: 'DistanceCalculatorService',
        );
        return 0.0;
      }

      developer.log(
        'Requesting distance from: "$originAddress" to "$destinationAddress"',
        name: 'DistanceCalculatorService',
      );

      // Cridar a la Firebase Cloud Function
      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('calculateDistance');

      final result = await callable.call({
        'originAddress': originAddress,
        'destinationAddress': destinationAddress,
      });

      // Extreure els quilòmetres de la resposta
      final data = result.data as Map<String, dynamic>?;
      if (data == null) {
        developer.log(
          'Error: No data returned from Cloud Function',
          name: 'DistanceCalculatorService',
        );
        return 0.0;
      }

      final kilometers = (data['kilometers'] as num?)?.toDouble() ?? 0.0;

      developer.log(
        'Distance calculated: ${kilometers.toStringAsFixed(2)} km (${data['distanceText']})',
        name: 'DistanceCalculatorService',
      );

      return kilometers;
    } catch (e) {
      developer.log(
        'Error calculating distance: $e',
        name: 'DistanceCalculatorService',
      );
      return 0.0;
    }
  }

  /// Calcula la distància per a múltiples destinacions
  /// Útil per processar múltiples designacions d'un mateix PDF
  ///
  /// Returns:
  /// - `Map<String, double>`: Map amb clau = adreça destinació, valor = km
  static Future<Map<String, double>> calculateDistances({
    required String originAddress,
    required List<String> destinationAddresses,
  }) async {
    final Map<String, double> results = {};

    for (final destination in destinationAddresses) {
      final distance = await calculateDistance(
        originAddress: originAddress,
        destinationAddress: destination,
      );
      results[destination] = distance;
    }

    return results;
  }

  /// Neteja una adreça de pavelló per millorar la geocodificació de Google Maps
  ///
  /// Expandeix abreviatures comunes (PAV.MUN., POL., C.E., etc.),
  /// elimina "S/N", converteix separadors, i afegeix "Spain" si cal.
  static String cleanVenueAddress(String address) {
    developer.log(
      'cleanVenueAddress input: "$address"',
      name: 'DistanceCalculatorService',
    );
    String cleaned = address;

    // 1a. Normalitzar paraules completes a capitalització correcta
    // (fer-ho ABANS d'expandir abreviatures per evitar matches parcials)
    cleaned = cleaned
        .replaceAll(RegExp(r'\bPAVELL[OÓ]\b', caseSensitive: false), 'Pavelló')
        .replaceAll(RegExp(r'\bMUNICIPAL\b', caseSensitive: false), 'Municipal')
        .replaceAll(RegExp(r'\bPOLIESPORTIU\b', caseSensitive: false), 'Poliesportiu')
        .replaceAll(RegExp(r'\bESPORTIU\b', caseSensitive: false), 'Esportiu');

    // 1b. Expandir abreviatures (requereixen punt per no trencar paraules completes)
    cleaned = cleaned
        // Pavellons
        .replaceAll(RegExp(r'\bPAV\.\s*MUN\.\s*DE\s+', caseSensitive: false), 'Pavelló Municipal de ')
        .replaceAll(RegExp(r'\bPAV\.\s*MUN\.?\s*', caseSensitive: false), 'Pavelló Municipal ')
        .replaceAll(RegExp(r'\bPAV\.\s*ESP\.?\s*', caseSensitive: false), 'Pavelló Esportiu ')
        .replaceAll(RegExp(r'\bPAV\.\s*POL\.?\s*', caseSensitive: false), 'Pavelló Poliesportiu ')
        .replaceAll(RegExp(r'\bPAV\.\s*', caseSensitive: false), 'Pavelló ')
        // Poliesportius
        .replaceAll(RegExp(r'\bPOL\.\s*MUN\.?\s*', caseSensitive: false), 'Poliesportiu Municipal ')
        .replaceAll(RegExp(r'\bPOLIESP\.\s*', caseSensitive: false), 'Poliesportiu ')
        .replaceAll(RegExp(r'\bPOL\.\s+', caseSensitive: false), 'Poliesportiu ')
        // Centres esportius
        .replaceAll(RegExp(r'\bC\.\s*E\.\s*M\.?\s*', caseSensitive: false), 'Centre Esportiu Municipal ')
        .replaceAll(RegExp(r'\bC\.\s*E\.\s+', caseSensitive: false), 'Centre Esportiu ')
        // Altres
        .replaceAll(RegExp(r'\bMPAL\.?\s*', caseSensitive: false), 'Municipal ')
        .replaceAll(RegExp(r'\bMUNI\.\s*', caseSensitive: false), 'Municipal ')
        .replaceAll(RegExp(r'\bESP\.\s+', caseSensitive: false), 'Esportiu ')
        .replaceAll(RegExp(r'\bINST\.\s*ESP\.?\s*', caseSensitive: false), 'Instal·lacions Esportives ')
        .replaceAll(RegExp(r'\bCOMPLEX\s+ESP\.?\s*', caseSensitive: false), 'Complex Esportiu ');

    // 2. Eliminar "S/N" (sense número)
    cleaned = cleaned
        .replaceAll('S/N', '')
        .replaceAll('s/n', '')
        .replaceAll('S / N', '')
        .replaceAll('s / n', '');

    // 3. Convertir separadors "·" a comes
    cleaned = cleaned
        .replaceAll(' · ', ', ')
        .replaceAll('·', ', ');

    // 4. Netejar comes i espais múltiples
    cleaned = cleaned
        .replaceAll(RegExp(r'\s+,\s*'), ', ')
        .replaceAll(RegExp(r',\s*,'), ',')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // 5. Si l'adreça comença amb coma, eliminar-la
    if (cleaned.startsWith(',')) {
      cleaned = cleaned.substring(1).trim();
    }

    // 6. Si l'adreça acaba amb coma, eliminar-la
    if (cleaned.endsWith(',')) {
      cleaned = cleaned.substring(0, cleaned.length - 1).trim();
    }

    // 7. Afegir "Catalunya, Spain" al final si no hi és cap referència geogràfica
    final upperCleaned = cleaned.toUpperCase();
    final hasSpain = upperCleaned.contains('SPAIN') ||
        upperCleaned.contains('ESPAÑA') ||
        upperCleaned.contains('ESPANYA');
    final hasCatalunya = upperCleaned.contains('CATALUNYA') ||
        upperCleaned.contains('CATALUÑA') ||
        upperCleaned.contains('CATALONIA');
    final hasProvince = upperCleaned.contains('BARCELONA') ||
        upperCleaned.contains('GIRONA') ||
        upperCleaned.contains('LLEIDA') ||
        upperCleaned.contains('TARRAGONA');

    if (!hasSpain && !hasCatalunya && !hasProvince) {
      // Afegir Catalunya i Spain per millorar la geocodificació
      cleaned = '$cleaned, Catalunya, Spain';
    } else if (!hasSpain) {
      // Ja té Catalunya o província, afegir només Spain
      cleaned = '$cleaned, Spain';
    }

    developer.log(
      'cleanVenueAddress output: "$cleaned"',
      name: 'DistanceCalculatorService',
    );
    return cleaned;
  }
}