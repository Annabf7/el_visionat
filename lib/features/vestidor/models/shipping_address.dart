/// Adreça d'enviament per al checkout
class ShippingAddress {
  final String name;
  final String address1;
  final String? address2;
  final String city;
  final String? stateCode;
  final String countryCode;
  final String zip;
  final String? phone;
  final String? email;

  const ShippingAddress({
    required this.name,
    required this.address1,
    this.address2,
    required this.city,
    this.stateCode,
    required this.countryCode,
    required this.zip,
    this.phone,
    this.email,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'address1': address1,
    if (address2 != null && address2!.isNotEmpty) 'address2': address2,
    'city': city,
    if (stateCode != null && stateCode!.isNotEmpty) 'stateCode': stateCode,
    'countryCode': countryCode,
    'zip': zip,
    if (phone != null && phone!.isNotEmpty) 'phone': phone,
    if (email != null && email!.isNotEmpty) 'email': email,
  };

  factory ShippingAddress.fromMap(Map<String, dynamic> map) {
    return ShippingAddress(
      name: (map['name'] ?? '') as String,
      address1: (map['address1'] ?? '') as String,
      address2: map['address2'] as String?,
      city: (map['city'] ?? '') as String,
      stateCode: map['stateCode'] as String?,
      countryCode: (map['countryCode'] ?? 'ES') as String,
      zip: (map['zip'] ?? '') as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
    );
  }
}
