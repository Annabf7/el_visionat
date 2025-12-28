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
  /// - Map<String, double>: Map amb clau = adreça destinació, valor = km
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
}