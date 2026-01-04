/// Model per representar un àrbitre del registre oficial (referees_registry)
class RefereeFromRegistry {
  final String nom;
  final String cognoms;
  final String llissenciaId;
  final String? categoriaRrtt;
  final String? accountStatus;

  RefereeFromRegistry({
    required this.nom,
    required this.cognoms,
    required this.llissenciaId,
    this.categoriaRrtt,
    this.accountStatus,
  });

  /// Retorna el nom complet (nom + cognoms)
  String get fullName => '$nom $cognoms';

  /// Retorna el nom complet amb número de llicència
  String get displayName => '$fullName (#$llissenciaId)';

  /// Crea una instància des d'un document de Firestore
  factory RefereeFromRegistry.fromFirestore(Map<String, dynamic> data) {
    return RefereeFromRegistry(
      nom: data['nom'] ?? '',
      cognoms: data['cognoms'] ?? '',
      llissenciaId: data['llissenciaId']?.toString() ?? '',
      categoriaRrtt: data['categoriaRrtt'],
      accountStatus: data['accountStatus'],
    );
  }

  /// Comprova si aquest àrbitre coincideix amb la cerca
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

  @override
  String toString() => displayName;
}