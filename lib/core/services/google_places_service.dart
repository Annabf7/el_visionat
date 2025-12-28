import 'dart:developer' as developer;

import 'package:cloud_functions/cloud_functions.dart';

/// Servei per autocomplete d'adreces amb Google Places API
/// Utilitza Cloud Functions per evitar problemes de CORS en Flutter Web
class GooglePlacesService {
  static final _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');

  /// Cerca adreces a Catalunya
  static Future<List<PlaceSuggestion>> searchAddresses(String query) async {
    if (query.isEmpty) return [];

    try {
      developer.log('Cercant adreces per: $query', name: 'GooglePlacesService');
      final callable = _functions.httpsCallable('searchAddresses');
      final result = await callable.call({'query': query});

      developer.log('Resposta rebuda: ${result.data}', name: 'GooglePlacesService');

      final suggestions = result.data['suggestions'] as List;
      developer.log('Suggeriments trobats: ${suggestions.length}', name: 'GooglePlacesService');

      return suggestions
          .map((s) => PlaceSuggestion(
                placeId: s['placeId'],
                description: s['description'],
              ))
          .toList();
    } catch (e) {
      developer.log('Error cercant adreces: $e', name: 'GooglePlacesService');
      return [];
    }
  }

  /// Obté els detalls d'una adreça seleccionada
  static Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      final callable = _functions.httpsCallable('getPlaceDetails');
      final result = await callable.call({'placeId': placeId});

      if (result.data == null) return null;

      final data = result.data as Map<String, dynamic>;
      return PlaceDetails(
        street: data['street'] ?? '',
        postalCode: data['postalCode'] ?? '',
        city: data['city'] ?? '',
        province: data['province'] ?? '',
      );
    } catch (e) {
      developer.log('Error obtenint detalls: $e', name: 'GooglePlacesService');
      return null;
    }
  }
}

/// Suggeriment d'adreça
class PlaceSuggestion {
  final String placeId;
  final String description;

  PlaceSuggestion({
    required this.placeId,
    required this.description,
  });
}

/// Detalls complets d'una adreça
class PlaceDetails {
  final String street;
  final String postalCode;
  final String city;
  final String province;

  PlaceDetails({
    required this.street,
    required this.postalCode,
    required this.city,
    required this.province,
  });
}