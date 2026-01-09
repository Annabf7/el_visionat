import 'package:flutter/material.dart';
import 'package:el_visionat/core/models/app_notification.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Widget per mostrar un item de notificació individual
class NotificationItem extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Configurar timeago en català
    timeago.setLocaleMessages('ca', timeago.CaMessages());

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.transparent
                : AppTheme.lilaMitja.withValues(alpha: 0.08),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.grisPistacho.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icona segons el tipus de notificació
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getIconBackgroundColor(),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIcon(),
                  size: 20,
                  color: _getIconColor(),
                ),
              ),
              const SizedBox(width: 12),

              // Contingut
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Títol
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: notification.isRead
                            ? FontWeight.w500
                            : FontWeight.w700,
                        color: AppTheme.porpraFosc,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Descripció
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.grisBody,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Temps relatiu
                    Text(
                      timeago.format(
                        notification.createdAt,
                        locale: 'ca',
                      ),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.grisBody.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Indicador de no llegida
              if (!notification.isRead)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.mostassa,
                    shape: BoxShape.circle,
                  ),
                ),

              // Botó eliminar (opcional)
              if (onDelete != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: AppTheme.grisBody.withValues(alpha: 0.5),
                  ),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Obté la icona segons el tipus de notificació
  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.highlightReviewRequested:
        return Icons.trending_up;
      case NotificationType.debateClosed:
        return Icons.check_circle_outline;
      case NotificationType.commentReply:
        return Icons.comment;
      case NotificationType.newReaction:
        return Icons.thumb_up_outlined;
      case NotificationType.unwatchedClipsReminder:
        return Icons.video_library_outlined;
      default:
        return Icons.notifications;
    }
  }

  /// Obté el color de la icona
  Color _getIconColor() {
    switch (notification.type) {
      case NotificationType.highlightReviewRequested:
        return AppTheme.mostassa;
      case NotificationType.debateClosed:
        return const Color(0xFF50C878); // Verd
      case NotificationType.commentReply:
        return AppTheme.lilaMitja;
      case NotificationType.newReaction:
        return AppTheme.porpraFosc;
      case NotificationType.unwatchedClipsReminder:
        return AppTheme.mostassa;
      default:
        return AppTheme.grisBody;
    }
  }

  /// Obté el color de fons de la icona
  Color _getIconBackgroundColor() {
    switch (notification.type) {
      case NotificationType.highlightReviewRequested:
        return AppTheme.mostassa.withValues(alpha: 0.15);
      case NotificationType.debateClosed:
        return const Color(0xFF50C878).withValues(alpha: 0.15);
      case NotificationType.commentReply:
        return AppTheme.lilaMitja.withValues(alpha: 0.15);
      case NotificationType.newReaction:
        return AppTheme.porpraFosc.withValues(alpha: 0.15);
      case NotificationType.unwatchedClipsReminder:
        return AppTheme.mostassa.withValues(alpha: 0.15);
      default:
        return AppTheme.grisPistacho.withValues(alpha: 0.1);
    }
  }
}
