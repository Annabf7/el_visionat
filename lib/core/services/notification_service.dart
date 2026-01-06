// ============================================================================
// NotificationService - Gestió de notificacions in-app
// ============================================================================
// Servei per llegir, marcar com llegides i eliminar notificacions

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obté notificacions d'un usuari
  Future<List<AppNotification>> getNotifications({
    required String userId,
    bool onlyUnread = false,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (onlyUnread) {
        query = query.where('isRead', isEqualTo: false);
      }

      final snapshot = await query.get();

      final notifications = snapshot.docs
          .map((doc) => AppNotification.fromJson(doc.data() as Map<String, dynamic>))
          .where((notif) => !notif.isExpired) // Filtrar expirades
          .toList();

      debugPrint('[NotificationService] Obtingudes ${notifications.length} notificacions');
      return notifications;
    } catch (e) {
      debugPrint('[NotificationService] ❌ Error obtenint notificacions: $e');
      return [];
    }
  }

  /// Stream de notificacions en temps real
  Stream<List<AppNotification>> watchNotifications({
    required String userId,
    bool onlyUnread = false,
  }) {
    Query query = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50);

    if (onlyUnread) {
      query = query.where('isRead', isEqualTo: false);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AppNotification.fromJson(doc.data() as Map<String, dynamic>))
          .where((notif) => !notif.isExpired)
          .toList();
    });
  }

  /// Marca una notificació com llegida
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });

      debugPrint('[NotificationService] ✅ Notificació marcada com llegida: $notificationId');
    } catch (e) {
      debugPrint('[NotificationService] ❌ Error marcant com llegida: $e');
      rethrow;
    }
  }

  /// Marca totes les notificacions com llegides
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      debugPrint('[NotificationService] ✅ ${snapshot.docs.length} notificacions marcades com llegides');
    } catch (e) {
      debugPrint('[NotificationService] ❌ Error marcant totes com llegides: $e');
      rethrow;
    }
  }

  /// Elimina una notificació
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();

      debugPrint('[NotificationService] ✅ Notificació eliminada: $notificationId');
    } catch (e) {
      debugPrint('[NotificationService] ❌ Error eliminant notificació: $e');
      rethrow;
    }
  }

  /// Elimina notificacions expirades d'un usuari
  Future<void> cleanExpiredNotifications(String userId) async {
    try {
      final now = Timestamp.now();

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('expiresAt', isLessThan: now)
          .get();

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      debugPrint('[NotificationService] ✅ ${snapshot.docs.length} notificacions expirades eliminades');
    } catch (e) {
      debugPrint('[NotificationService] ❌ Error netejant notificacions: $e');
      rethrow;
    }
  }

  /// Compta notificacions no llegides
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('[NotificationService] ❌ Error comptant no llegides: $e');
      return 0;
    }
  }

  /// Stream del comptador de notificacions no llegides
  Stream<int> watchUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
