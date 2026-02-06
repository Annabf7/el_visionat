import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/time_block.dart';

/// Servei per gestionar els TimeBlocks a Firestore
/// Ruta: users/{uid}/timeblocks/{id}
class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Referència a la col·lecció de timeblocks d'un usuari
  CollectionReference<Map<String, dynamic>> _timeblocksRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('timeblocks');
  }

  /// Obté un stream dels blocs d'una setmana
  Stream<List<TimeBlock>> getBlocksForWeek(String uid, DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));

    return _timeblocksRef(uid)
        .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
        .where('startAt', isLessThan: Timestamp.fromDate(weekEnd))
        .orderBy('startAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TimeBlock.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Obté un stream dels blocs d'un dia específic
  Stream<List<TimeBlock>> getBlocksForDay(String uid, DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    return _timeblocksRef(uid)
        .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
        .where('startAt', isLessThan: Timestamp.fromDate(dayEnd))
        .orderBy('startAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TimeBlock.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Crea un nou bloc i retorna l'ID
  Future<String> createBlock(String uid, TimeBlock block) async {
    final docRef = await _timeblocksRef(uid).add(block.toMap());
    return docRef.id;
  }

  /// Actualitza un bloc existent
  Future<void> updateBlock(String uid, TimeBlock block) async {
    if (block.id == null) {
      throw ArgumentError('El bloc ha de tenir un ID per actualitzar-lo');
    }
    await _timeblocksRef(uid).doc(block.id).update(block.toMap());
  }

  /// Elimina un bloc
  Future<void> deleteBlock(String uid, String blockId) async {
    await _timeblocksRef(uid).doc(blockId).delete();
  }

  /// Canvia l'estat de completat d'un bloc
  Future<void> toggleDone(String uid, String blockId, bool done) async {
    await _timeblocksRef(uid).doc(blockId).update({
      'done': done,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Obté la granota (FROG) d'un dia específic
  /// Filtra al client per evitar necessitat d'índex compost
  Future<TimeBlock?> getFrogForDay(String uid, DateTime day) async {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final snapshot = await _timeblocksRef(uid)
        .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
        .where('startAt', isLessThan: Timestamp.fromDate(dayEnd))
        .get();

    // Filtrem al client per priority
    final frogs = snapshot.docs
        .map((doc) => TimeBlock.fromMap(doc.id, doc.data()))
        .where((block) => block.priority == TimeBlockPriority.frog)
        .toList();

    return frogs.isEmpty ? null : frogs.first;
  }

  /// Verifica si ja existeix una granota per a un dia
  /// Filtra al client per evitar necessitat d'índex compost
  Future<bool> hasFrogForDay(String uid, DateTime day, {String? excludeBlockId}) async {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final snapshot = await _timeblocksRef(uid)
        .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
        .where('startAt', isLessThan: Timestamp.fromDate(dayEnd))
        .get();

    // Filtrem al client per priority
    final frogs = snapshot.docs
        .where((doc) {
          if (excludeBlockId != null && doc.id == excludeBlockId) return false;
          return doc.data()['priority'] == TimeBlockPriority.frog.name;
        })
        .toList();

    return frogs.isNotEmpty;
  }

  /// Obté tots els blocs d'un mes (per al calendari)
  Stream<List<TimeBlock>> getBlocksForMonth(String uid, DateTime month) {
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 1);

    return _timeblocksRef(uid)
        .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
        .where('startAt', isLessThan: Timestamp.fromDate(monthEnd))
        .orderBy('startAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TimeBlock.fromMap(doc.id, doc.data()))
            .toList());
  }
}
