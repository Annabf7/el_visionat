import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Model per les dades de l'àrbitre del partit
class MatchReferee {
  final String licenseId;
  final String fullName;
  final String category;
  final String displayName;

  const MatchReferee({
    required this.licenseId,
    required this.fullName,
    required this.category,
    required this.displayName,
  });

  factory MatchReferee.fromFirestore(
    Map<String, dynamic> data,
    String licenseId,
  ) {
    return MatchReferee(
      licenseId: licenseId,
      fullName: '${data['nom'] ?? ''} ${data['cognoms'] ?? ''}'.trim(),
      category: data['categoriaRrtt'] ?? 'N/A',
      displayName: data['nom'] ?? 'Àrbitre',
    );
  }
}

/// Servei per obtenir informació d'àrbitres des del registre
class MatchRefereeService {
  final FirebaseFirestore _firestore;

  MatchRefereeService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Obté les dades d'un àrbitre per número de llicència
  ///
  /// Retorna null si no es troba o si hi ha error
  Future<MatchReferee?> getRefereeByLicense(String licenseId) async {
    try {
      if (licenseId.trim().isEmpty) return null;

      final doc = await _firestore
          .collection('referees_registry')
          .doc(licenseId.trim())
          .get();

      if (!doc.exists) {
        debugPrint('⚠️ Àrbitre amb llicència $licenseId no trobat al registre');
        return null;
      }

      final data = doc.data();
      if (data == null) return null;

      return MatchReferee.fromFirestore(data, licenseId);
    } catch (e) {
      debugPrint('❌ Error carregant àrbitre $licenseId: $e');
      return null;
    }
  }
}
