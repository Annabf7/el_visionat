import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:el_visionat/core/models/app_notification.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/features/notifications/providers/notification_provider.dart';
import 'package:el_visionat/features/notifications/widgets/notification_item.dart';

/// Dropdown amb la llista de notificacions
class NotificationDropdown extends StatelessWidget {
  final Function(AppNotification)? onNotificationTap;

  const NotificationDropdown({
    super.key,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        final notifications = provider.notifications;

        return Container(
          width: 380,
          constraints: const BoxConstraints(maxHeight: 500),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.porpraFosc.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Capçalera
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.grisPistacho.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notificacions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.porpraFosc,
                      ),
                    ),
                    if (provider.unreadCount > 0)
                      TextButton(
                        onPressed: () => provider.markAllAsRead(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Marcar totes com llegides',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.lilaMitja,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Llista de notificacions
              if (provider.isLoading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                )
              else if (notifications.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 48,
                        color: AppTheme.grisBody.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No tens notificacions',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.grisBody,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return NotificationItem(
                        notification: notification,
                        onTap: () {
                          _handleNotificationTap(
                            context,
                            provider,
                            notification,
                          );
                        },
                        onDelete: () {
                          provider.deleteNotification(notification.id);
                        },
                      );
                    },
                  ),
                ),

              // Error
              if (provider.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    border: Border(
                      top: BorderSide(
                        color: Colors.red.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.error!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: provider.clearError,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Gestiona el tap en una notificació
  void _handleNotificationTap(
    BuildContext context,
    NotificationProvider provider,
    AppNotification notification,
  ) {
    // Marcar com llegida si no ho està
    if (!notification.isRead) {
      provider.markAsRead(notification.id);
    }

    // Tancar el dropdown
    Navigator.of(context).pop();

    // Navegar segons el tipus
    if (onNotificationTap != null) {
      onNotificationTap!(notification);
    } else {
      _navigateToNotification(context, notification);
    }
  }

  /// Navega a la pantalla corresponent segons el tipus de notificació
  void _navigateToNotification(
    BuildContext context,
    AppNotification notification,
  ) {
    debugPrint('[NotificationDropdown] Navegant a notificació tipus: ${notification.type}');
    debugPrint('[NotificationDropdown] Data: ${notification.data}');

    switch (notification.type) {
      case NotificationType.highlightReviewRequested:
      case NotificationType.debateClosed:
      case NotificationType.commentReply:
      case NotificationType.newReaction:
        // Navegar al visionat del match amb el highlight
        final matchId = notification.data['matchId'] as String?;
        final highlightId = notification.data['highlightId'] as String?;

        debugPrint('[NotificationDropdown] matchId: $matchId, highlightId: $highlightId');

        if (matchId != null) {
          // Navegar a /visionat amb els arguments
          Navigator.pushNamed(
            context,
            '/visionat',
            arguments: {
              'matchId': matchId,
              'highlightId': highlightId,
            },
          );
          debugPrint('[NotificationDropdown] Navegació iniciada a /visionat');
        } else {
          debugPrint('[NotificationDropdown] matchId és null, no es pot navegar');
        }
        break;

      case NotificationType.other:
        // Gestionar altres tipus en el futur
        debugPrint('[NotificationDropdown] Tipus "other", no hi ha navegació definida');
        break;
    }
  }
}
