/// Model que representa l'adreça de casa de l'àrbitre
/// Aquesta adreça s'utilitza com a punt de sortida per calcular quilometratge
class HomeAddress {
  final String street; // Carrer i número (ex: "Genís i Sagrera, 9")
  final String postalCode; // Codi postal (ex: "17200")
  final String city; // Ciutat (ex: "Palafrugell")
  final String province; // Província (ex: "Girona")
  final String fullAddress; // Adreça completa per geocoding

  HomeAddress({
    required this.street,
    required this.postalCode,
    required this.city,
    required this.province,
  }) : fullAddress = '$street, $postalCode $city, $province';

  /// Constructor buit per defecte
  HomeAddress.empty()
      : street = '',
        postalCode = '',
        city = '',
        province = '',
        fullAddress = '';

  /// Converteix el model a Map per guardar a Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'street': street,
      'postalCode': postalCode,
      'city': city,
      'province': province,
      'fullAddress': fullAddress,
    };
  }

  /// Crea un model des de Firestore
  factory HomeAddress.fromFirestore(Map<String, dynamic> data) {
    return HomeAddress(
      street: data['street'] ?? '',
      postalCode: data['postalCode'] ?? '',
      city: data['city'] ?? '',
      province: data['province'] ?? '',
    );
  }

  /// Verifica si l'adreça està buida
  bool get isEmpty =>
      street.isEmpty &&
      postalCode.isEmpty &&
      city.isEmpty &&
      province.isEmpty;

  /// Verifica si l'adreça està completa
  bool get isComplete =>
      street.isNotEmpty &&
      postalCode.isNotEmpty &&
      city.isNotEmpty &&
      province.isNotEmpty;

  /// Còpia amb modificacions
  HomeAddress copyWith({
    String? street,
    String? postalCode,
    String? city,
    String? province,
  }) {
    return HomeAddress(
      street: street ?? this.street,
      postalCode: postalCode ?? this.postalCode,
      city: city ?? this.city,
      province: province ?? this.province,
    );
  }

  @override
  String toString() => fullAddress;
}