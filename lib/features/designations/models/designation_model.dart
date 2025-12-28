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
  final double kilometers;
  final EarningsModel earnings;
  final String? pdfUrl;
  final String? notes;
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
    required this.kilometers,
    required this.earnings,
    this.pdfUrl,
    this.notes,
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
      'kilometers': kilometers,
      'earnings': earnings.toMap(),
      'pdfUrl': pdfUrl,
      'notes': notes,
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
      kilometers: (data['kilometers'] ?? 0).toDouble(),
      earnings: EarningsModel.fromMap(data['earnings'] ?? {}),
      pdfUrl: data['pdfUrl'],
      notes: data['notes'],
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
    double? kilometers,
    EarningsModel? earnings,
    String? pdfUrl,
    String? notes,
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
      kilometers: kilometers ?? this.kilometers,
      earnings: earnings ?? this.earnings,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Model per representar els ingressos d'una designació
class EarningsModel {
  final double rights; // Drets d'arbitratge
  final double kilometersAmount; // Quilometratge
  final double allowance; // Dietes
  final double total;

  EarningsModel({
    required this.rights,
    required this.kilometersAmount,
    required this.allowance,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'rights': rights,
      'kilometers': kilometersAmount,
      'allowance': allowance,
      'total': total,
    };
  }

  factory EarningsModel.fromMap(Map<String, dynamic> map) {
    return EarningsModel(
      rights: (map['rights'] ?? 0).toDouble(),
      kilometersAmount: (map['kilometers'] ?? 0).toDouble(),
      allowance: (map['allowance'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
    );
  }

  EarningsModel copyWith({
    double? rights,
    double? kilometersAmount,
    double? allowance,
    double? total,
  }) {
    return EarningsModel(
      rights: rights ?? this.rights,
      kilometersAmount: kilometersAmount ?? this.kilometersAmount,
      allowance: allowance ?? this.allowance,
      total: total ?? this.total,
    );
  }
}