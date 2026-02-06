/// Tipus de resultat de cerca
enum SearchResultType {
  referee, // Àrbitre o auxiliar de taula
}

/// Model per a un resultat de cerca d'àrbitre
class RefereeSearchResult {
  final String nom;
  final String cognoms;
  final String llissenciaId;
  final String? categoriaRrtt;
  final String? userId; // ID de l'usuari si té compte a l'app
  final bool hasAccount; // Si té compte actiu a l'app

  RefereeSearchResult({
    required this.nom,
    required this.cognoms,
    required this.llissenciaId,
    this.categoriaRrtt,
    this.userId,
    this.hasAccount = false,
  });

  /// Nom complet
  String get fullName => '$nom $cognoms';

  /// Nom per mostrar amb llicència
  String get displayName => '$fullName (#$llissenciaId)';

  /// Crea una instància des de les dades del registre + info d'usuari
  factory RefereeSearchResult.fromRegistryAndUser({
    required Map<String, dynamic> registryData,
    String? userId,
  }) {
    return RefereeSearchResult(
      nom: registryData['nom'] ?? '',
      cognoms: registryData['cognoms'] ?? '',
      llissenciaId: registryData['llissenciaId']?.toString() ?? '',
      categoriaRrtt: registryData['categoriaRrtt'],
      userId: userId,
      hasAccount: userId != null,
    );
  }

  /// Comprova si coincideix amb la cerca
  bool matchesSearch(String query) {
    if (query.isEmpty) return true;

    final queryLower = query.toLowerCase().trim();

    // Cercar per nom complet
    if (fullName.toLowerCase().contains(queryLower)) return true;

    // Cercar per cognoms primer (format "Lopez, Victor")
    final reverseName = '$cognoms, $nom'.toLowerCase();
    if (reverseName.contains(queryLower)) return true;

    // Cercar per número de llicència
    if (llissenciaId.contains(query.trim())) return true;

    return false;
  }
}
