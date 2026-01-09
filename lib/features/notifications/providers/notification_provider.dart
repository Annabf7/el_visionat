import 'package:flutter/foundation.dart';
import 'package:el_visionat/core/models/app_notification.dart';
import 'package:el_visionat/core/services/notification_service.dart';
import 'dart:async';

/// Provider per gestionar les notificacions de l'usuari
class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<AppNotification>>? _streamSubscription;
  String? _currentUserId;

  // Getters
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasUnreadNotifications => _unreadCount > 0;

  /// Inicialitza el provider amb l'usuari actual
  void initialize(String userId) {
    debugPrint('[NotificationProvider] initialize called with userId: $userId');
    debugPrint('[NotificationProvider] _currentUserId: $_currentUserId');

    if (_currentUserId == userId) {
      debugPrint('[NotificationProvider] Ja està inicialitzat amb aquest userId');
      return; // Ja està inicialitzat
    }

    _currentUserId = userId;
    debugPrint('[NotificationProvider] Starting listener for userId: $userId');
    _startListening();
  }

  /// Escolta les notificacions en temps real
  void _startListening() {
    if (_currentUserId == null) {
      debugPrint('[NotificationProvider] _currentUserId is null, cannot start listening');
      return;
    }

    debugPrint('[NotificationProvider] Starting stream subscription for userId: $_currentUserId');
    _isLoading = true;
    notifyListeners();

    _streamSubscription?.cancel();
    _streamSubscription = _notificationService
        .watchNotifications(userId: _currentUserId!)
        .listen(
          (notifications) {
            debugPrint('[NotificationProvider] Received ${notifications.length} notifications');
            debugPrint('[NotificationProvider] Unread: ${notifications.where((n) => !n.isRead).length}');

            _notifications = notifications;
            _unreadCount = notifications.where((n) => !n.isRead).length;
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('[NotificationProvider] Error: $error');
            _error = 'Error carregant notificacions';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  /// Marca una notificació com llegida
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      // El stream actualitzarà automàticament la llista
    } catch (e) {
      debugPrint('[NotificationProvider] Error marcant com llegida: $e');
      _error = 'Error marcant notificació com llegida';
      notifyListeners();
    }
  }

  /// Marca totes les notificacions com llegides
  Future<void> markAllAsRead() async {
    if (_currentUserId == null) return;

    try {
      await _notificationService.markAllAsRead(_currentUserId!);
      // El stream actualitzarà automàticament la llista
    } catch (e) {
      debugPrint('[NotificationProvider] Error marcant totes com llegides: $e');
      _error = 'Error marcant notificacions com llegides';
      notifyListeners();
    }
  }

  /// Elimina una notificació
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      // El stream actualitzarà automàticament la llista
    } catch (e) {
      debugPrint('[NotificationProvider] Error eliminant notificació: $e');
      _error = 'Error eliminant notificació';
      notifyListeners();
    }
  }

  /// Neteja l'error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
