import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vestidor_order.dart';

/// Servei per consultar les comandes de l'usuari a Firestore
class OrdersService {
  static final _db = FirebaseFirestore.instance;

  /// Stream d'una comanda individual per ID
  static Stream<VestidorOrder?> orderStream(String orderId) {
    return _db
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((doc) => doc.exists ? VestidorOrder.fromFirestore(doc) : null);
  }

  /// Stream de comandes d'un usuari, ordenades per data de creació desc
  static Stream<List<VestidorOrder>> ordersStream(String uid) {
    return _db
        .collection('orders')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VestidorOrder.fromFirestore(doc))
            .toList());
  }
}
