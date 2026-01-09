// ============================================================================
// CommentItem - Widget per mostrar un comentari individual
// ============================================================================

import 'package:flutter/material.dart';
import 'package:el_visionat/features/visionat/models/comment.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentItem extends StatelessWidget {
  final Comment comment;
  final bool hasLiked;
  final bool isCurrentUser;
  final bool isReply;
  final VoidCallback? onReply;
  final VoidCallback? onLike;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CommentItem({
    super.key,
    required this.comment,
    required this.hasLiked,
    required this.isCurrentUser,
    this.isReply = false,
    this.onReply,
    this.onLike,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: isReply ? 40 : 16,
        right: 16,
        top: 12,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: comment.isOfficial
            ? AppTheme.mostassa.withValues(alpha: 0.05)
            : Colors.transparent,
        border: comment.isOfficial
            ? Border(
                left: BorderSide(
                  color: AppTheme.mostassa,
                  width: 3,
                ),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar, nom, categoria, temps
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: isReply ? 14 : 18,
                backgroundImage: comment.userPhotoUrl != null
                    ? NetworkImage(comment.userPhotoUrl!)
                    : null,
                backgroundColor: AppTheme.lilaMitja,
                child: comment.userPhotoUrl == null
                    ? Text(
                        comment.userName.isNotEmpty
                            ? comment.userName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isReply ? 12 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),

              // Nom i metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Nom d'usuari
                        Text(
                          comment.userName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isReply ? 13 : 14,
                            color: Colors.grey[900],
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Badge de categoria
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: comment.isACBReferee
                                ? AppTheme.mostassa
                                : AppTheme.lilaMitja.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            comment.userCategory,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: comment.isACBReferee
                                  ? Colors.white
                                  : AppTheme.lilaMitja,
                            ),
                          ),
                        ),

                        // Badge de veredicte oficial
                        if (comment.isOfficial) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.mostassa,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.gavel,
                                  size: 10,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'OFICIAL',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Temps i editat
                    Row(
                      children: [
                        Text(
                          timeago.format(comment.createdAt, locale: 'ca'),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (comment.updatedAt != null) ...[
                          Text(
                            ' · editat',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Menú d'opcions per l'usuari
              if (isCurrentUser)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'edit' && onEdit != null) {
                      onEdit!();
                    } else if (value == 'delete' && onDelete != null) {
                      onDelete!();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Eliminar',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Text del comentari
          Text(
            comment.text,
            style: TextStyle(
              fontSize: isReply ? 13 : 14,
              color: Colors.grey[800],
              height: 1.4,
            ),
          ),

          const SizedBox(height: 8),

          // Accions: like, reply
          Row(
            children: [
              // Botó de like
              InkWell(
                onTap: onLike,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasLiked ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: hasLiked ? Colors.red[400] : Colors.grey[600],
                      ),
                      if (comment.likesCount > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          '${comment.likesCount}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                hasLiked ? FontWeight.bold : FontWeight.normal,
                            color: hasLiked ? Colors.red[400] : Colors.grey[700],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Botó de reply (només per comentaris principals)
              if (!isReply && onReply != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: onReply,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.reply,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        if (comment.repliesCount > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${comment.repliesCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
