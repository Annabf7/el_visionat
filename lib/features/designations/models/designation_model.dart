import 'package:cloud_firestore/cloud_firestore.dart';

/// Model per representar una designació arbitral
class DesignationModel {
  final String id;
  final DateTime date;
  final String category;
  final String competition;
  final String role; // "principal" o "auxiliar"
  final String matchNumber;
  final String localTeam;
  final String visitantTeam;
  final String location;
  final String locationAddress;
  final String?
  originAddress; // Adreça d'origen (opcional, si null s'usa l'adreça de casa)
  final double kilometers;
  final EarningsModel earnings;
  final String? pdfUrl;
  final String? notes;
  final String?
  refereePartner; // Nom del company/companya àrbitre (arbitratge a dobles)
  final String? refereePartnerPhone; // Telèfon del company/companya
  final String?
  refereePartnerNotes; // Anotacions sobre el company/companya àrbitre
  final DateTime createdAt;

  DesignationModel({
    required this.id,
    required this.date,
    required this.category,
    required this.competition,
    required this.role,
    required this.matchNumber,
    required this.localTeam,
    required this.visitantTeam,
    required this.location,
    required this.locationAddress,
    this.originAddress,
    required this.kilometers,
    required this.earnings,
    this.pdfUrl,
    this.notes,
    this.refereePartner,
    this.refereePartnerPhone,
    this.refereePartnerNotes,
    required this.createdAt,
  });

  /// Converteix el model a un Map per guardar a Firestore
  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'category': category,
      'competition': competition,
      'role': role,
      'matchNumber': matchNumber,
      'localTeam': localTeam,
      'visitantTeam': visitantTeam,
      'location': location,
      'locationAddress': locationAddress,
      'originAddress': originAddress,
      'kilometers': kilometers,
      'earnings': earnings.toMap(),
      'pdfUrl': pdfUrl,
      'notes': notes,
      'refereePartnerPhone': refereePartnerPhone,
      'refereePartner': refereePartner,
      'refereePartnerNotes': refereePartnerNotes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Crea un model des d'un DocumentSnapshot de Firestore
  factory DesignationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DesignationModel(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      category: data['category'] ?? '',
      competition: data['competition'] ?? '',
      role: data['role'] ?? '',
      matchNumber: data['matchNumber'] ?? '',
      localTeam: data['localTeam'] ?? '',
      visitantTeam: data['visitantTeam'] ?? '',
      location: data['location'] ?? '',
      locationAddress: data['locationAddress'] ?? '',
      originAddress: data['originAddress'],
      kilometers: (data['kilometers'] ?? 0).toDouble(),
      earnings: EarningsModel.fromMap(
        data['earnings'] ?? {},
        kilometerDistance: (data['kilometers'] ?? 0).toDouble(),
      ),
      pdfUrl: data['pdfUrl'],
      notes: data['notes'],
      refereePartnerPhone: data['refereePartnerPhone'],
      refereePartner: data['refereePartner'],
      refereePartnerNotes: data['refereePartnerNotes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Copia el model amb canvis opcionals
  DesignationModel copyWith({
    String? id,
    DateTime? date,
    String? category,
    String? competition,
    String? role,
    String? matchNumber,
    String? localTeam,
    String? visitantTeam,
    String? location,
    String? locationAddress,
    String? originAddress,
    double? kilometers,
    EarningsModel? earnings,
    String? pdfUrl,
    String? notes,
    String? refereePartner,
    String? refereePartnerPhone,
    String? refereePartnerNotes,
    DateTime? createdAt,
  }) {
    return DesignationModel(
      id: id ?? this.id,
      date: date ?? this.date,
      category: category ?? this.category,
      competition: competition ?? this.competition,
      role: role ?? this.role,
      matchNumber: matchNumber ?? this.matchNumber,
      localTeam: localTeam ?? this.localTeam,
      visitantTeam: visitantTeam ?? this.visitantTeam,
      location: location ?? this.location,
      locationAddress: locationAddress ?? this.locationAddress,
      originAddress: originAddress ?? this.originAddress,
      kilometers: kilometers ?? this.kilometers,
      earnings: earnings ?? this.earnings,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      notes: notes ?? this.notes,
      refereePartner: refereePartner ?? this.refereePartner,
      refereePartnerPhone: refereePartnerPhone ?? this.refereePartnerPhone,
      refereePartnerNotes: refereePartnerNotes ?? this.refereePartnerNotes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Model per representar els ingressos d'una designació
class EarningsModel {
  final double rights; // Drets d'arbitratge (brut)
  final double kilometersAmount; // Quilometratge (brut)
  final double allowance; // Dietes (brut)
  final double total; // Total brut
  final double
  kilometerDistance; // Distància en km (per calcular retenció desplaçament)

  /// Taxa IRPF aplicable (2% per activitats < 15.000€/any)
  static const double irpfRate = 0.02;

  /// Tarifa exempta fiscal de quilometratge (€/km no subjecte a IRPF)
  static const double exemptRatePerKm = 0.25;

  EarningsModel({
    required this.rights,
    required this.kilometersAmount,
    required this.allowance,
    required this.total,
    this.kilometerDistance = 0.0,
  });

  /// Retenció IRPF sobre drets
  double get rightsRetention => _roundToTwo(rights * irpfRate);

  /// Retenció IRPF sobre dietes
  double get allowanceRetention => _roundToTwo(allowance * irpfRate);

  /// Retenció IRPF sobre desplaçament (només l'excés sobre 0.25€/km tributa)
  double get displacementRetention =>
      computeDisplacementRetention(kilometersAmount, kilometerDistance);

  /// Retenció total (drets + dietes + desplaçament)
  double get totalRetention =>
      _roundToTwo(rightsRetention + allowanceRetention + displacementRetention);

  /// Total net (després de totes les retencions)
  double get netTotal => _roundToTwo(total - totalRetention);

  /// Drets nets
  double get netRights => _roundToTwo(rights - rightsRetention);

  /// Dietes netes
  double get netAllowance => _roundToTwo(allowance - allowanceRetention);

  /// Quilometratge net
  double get netKilometersAmount =>
      _roundToTwo(kilometersAmount - displacementRetention);

  // Mantenir getter antic per compatibilitat
  double get irpfRetention => totalRetention;

  /// Calcula la retenció IRPF sobre desplaçament.
  /// Només l'excés sobre la tarifa exempta (0.25€/km) està subjecte a IRPF 2%.
  static double computeDisplacementRetention(double amount, double km) {
    if (amount <= 0 || km <= 0) return 0.0;
    final exemptAmount = km * exemptRatePerKm;
    final taxable = amount - exemptAmount;
    if (taxable <= 0) return 0.0;
    return _roundToTwo(taxable * irpfRate);
  }

  /// Arrodoneix a 2 decimals
  static double _roundToTwo(double value) {
    return (value * 100).roundToDouble() / 100;
  }

  Map<String, dynamic> toMap() {
    return {
      'rights': rights,
      'kilometers': kilometersAmount,
      'allowance': allowance,
      'total': total,
    };
  }

  factory EarningsModel.fromMap(
    Map<String, dynamic> map, {
    double kilometerDistance = 0.0,
  }) {
    return EarningsModel(
      rights: (map['rights'] ?? 0).toDouble(),
      kilometersAmount: (map['kilometers'] ?? 0).toDouble(),
      allowance: (map['allowance'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      kilometerDistance: kilometerDistance,
    );
  }

  EarningsModel copyWith({
    double? rights,
    double? kilometersAmount,
    double? allowance,
    double? total,
    double? kilometerDistance,
  }) {
    return EarningsModel(
      rights: rights ?? this.rights,
      kilometersAmount: kilometersAmount ?? this.kilometersAmount,
      allowance: allowance ?? this.allowance,
      total: total ?? this.total,
      kilometerDistance: kilometerDistance ?? this.kilometerDistance,
    );
  }
}
