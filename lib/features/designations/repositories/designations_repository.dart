import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/designation_model.dart';

/// Repository per gestionar les designacions a Firestore
class DesignationsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Obté l'ID de l'usuari actual
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Puja un PDF a Firebase Storage des d'un File
  Future<String?> uploadPdf(File pdfFile, String designationId) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      return uploadPdfFromBytes(bytes, designationId);
    } catch (e) {
      developer.log('Error uploading PDF from file: $e',
                    name: 'DesignationsRepository');
      return null;
    }
  }

  /// Puja un PDF a Firebase Storage des de bytes
  Future<String?> uploadPdfFromBytes(Uint8List bytes, String designationId) async {
    try {
      if (_currentUserId == null) return null;

      final ref = _storage.ref().child(
          'users/$_currentUserId/designations/$designationId/designation.pdf');

      await ref.putData(bytes);
      final url = await ref.getDownloadURL();

      developer.log('PDF uploaded successfully: $url',
                    name: 'DesignationsRepository');
      return url;
    } catch (e) {
      developer.log('Error uploading PDF from bytes: $e',
                    name: 'DesignationsRepository');
      return null;
    }
  }

  /// Crea una nova designació
  Future<String?> createDesignation(DesignationModel designation) async {
    try {
      if (_currentUserId == null) return null;

      final docRef = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('designations')
          .add(designation.toMap());

      developer.log('Designation created: ${docRef.id}',
                    name: 'DesignationsRepository');
      return docRef.id;
    } catch (e) {
      developer.log('Error creating designation: $e',
                    name: 'DesignationsRepository');
      return null;
    }
  }

  /// Actualitza una designació existent
  Future<bool> updateDesignation(DesignationModel designation) async {
    try {
      if (_currentUserId == null) return false;

      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('designations')
          .doc(designation.id)
          .update(designation.toMap());

      developer.log('Designation updated: ${designation.id}',
                    name: 'DesignationsRepository');
      return true;
    } catch (e) {
      developer.log('Error updating designation: $e',
                    name: 'DesignationsRepository');
      return false;
    }
  }

  /// Actualitza només les notes d'una designació
  Future<bool> updateNotes(String designationId, String notes) async {
    try {
      if (_currentUserId == null) return false;

      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('designations')
          .doc(designationId)
          .update({'notes': notes});

      developer.log('Notes updated for designation: $designationId',
                    name: 'DesignationsRepository');
      return true;
    } catch (e) {
      developer.log('Error updating notes: $e',
                    name: 'DesignationsRepository');
      return false;
    }
  }

  /// Elimina una designació
  Future<bool> deleteDesignation(String designationId) async {
    try {
      if (_currentUserId == null) return false;

      // Eliminar PDF de Storage si existeix
      try {
        final ref = _storage.ref().child(
            'users/$_currentUserId/designations/$designationId/designation.pdf');
        await ref.delete();
      } catch (e) {
        developer.log('PDF not found in storage or error deleting: $e',
                      name: 'DesignationsRepository');
      }

      // Eliminar designació de Firestore
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('designations')
          .doc(designationId)
          .delete();

      developer.log('Designation deleted: $designationId',
                    name: 'DesignationsRepository');
      return true;
    } catch (e) {
      developer.log('Error deleting designation: $e',
                    name: 'DesignationsRepository');
      return false;
    }
  }

  /// Comprova si ja existeix una designació amb el mateix número de partit i data
  Future<bool> designationExists(String matchNumber, DateTime date) async {
    try {
      if (_currentUserId == null) return false;

      // Crear rang de dates per tot el dia (de 00:00 a 23:59)
      final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('designations')
          .where('matchNumber', isEqualTo: matchNumber)
          .where('date',
                 isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      developer.log('Error checking if designation exists: $e',
                    name: 'DesignationsRepository');
      return false;
    }
  }

  /// Obté totes les designacions de l'usuari
  Stream<List<DesignationModel>> getDesignations() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('designations')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DesignationModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Obté les designacions d'un període específic
  Stream<List<DesignationModel>> getDesignationsByPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('designations')
        .where('date',
               isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DesignationModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Obté les designacions per categoria
  Stream<List<DesignationModel>> getDesignationsByCategory(
      String category) {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('designations')
        .where('category', isEqualTo: category)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DesignationModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Obté estadístiques per categoria
  Future<Map<String, int>> getCategoryStats() async {
    try {
      if (_currentUserId == null) return {};

      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('designations')
          .get();

      final Map<String, int> stats = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final category = data['category'] as String?;
        if (category != null) {
          stats[category] = (stats[category] ?? 0) + 1;
        }
      }

      return stats;
    } catch (e) {
      developer.log('Error getting category stats: $e',
                    name: 'DesignationsRepository');
      return {};
    }
  }

  /// Obté el total d'ingressos per període
  Future<double> getTotalEarnings({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (_currentUserId == null) return 0.0;

      Query query = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('designations');

      if (startDate != null) {
        query = query.where('date',
                          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('date',
                          isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();

      double total = 0.0;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final earnings = data['earnings'] as Map<String, dynamic>?;
        if (earnings != null) {
          total += (earnings['total'] as num?)?.toDouble() ?? 0.0;
        }
      }

      return total;
    } catch (e) {
      developer.log('Error getting total earnings: $e',
                    name: 'DesignationsRepository');
      return 0.0;
    }
  }
}