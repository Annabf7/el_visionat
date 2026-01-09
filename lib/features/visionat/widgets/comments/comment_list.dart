// ============================================================================
// CommentList - Widget per mostrar llista de comentaris amb respostes
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:el_visionat/features/visionat/models/comment.dart';
import 'package:el_visionat/features/visionat/providers/comment_provider.dart';
import 'package:el_visionat/features/auth/providers/auth_provider.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'comment_item.dart';
import 'comment_input.dart';

class CommentList extends StatefulWidget {
  final String matchId;
  final String highlightId;

  const CommentList({
    super.key,
    required this.matchId,
    required this.highlightId,
  });

  @override
  State<CommentList> createState() => _CommentListState();
}

class _CommentListState extends State<CommentList> {
  String? _replyingToCommentId;
  String? _replyingToUserName;
  String? _editingCommentId;
  final TextEditingController _editController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeComments();
  }

  void _initializeComments() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final commentProvider = context.read<CommentProvider>();

      if (auth.isAuthenticated && auth.currentUserUid != null) {
        commentProvider.initialize(
          matchId: widget.matchId,
          highlightId: widget.highlightId,
          userId: auth.currentUserUid!,
        );
      }
    });
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _startReply(String commentId, String userName) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUserName = userName;
      _editingCommentId = null;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserName = null;
    });
  }

  void _startEdit(Comment comment) {
    setState(() {
      _editingCommentId = comment.id;
      _editController.text = comment.text;
      _replyingToCommentId = null;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingCommentId = null;
      _editController.clear();
    });
  }

  Future<void> _submitComment(BuildContext context, String text) async {
    final auth = context.read<AuthProvider>();
    final commentProvider = context.read<CommentProvider>();

    if (!auth.isAuthenticated) return;

    // TODO: Obtenir categoria i nom d'usuari de Firestore
    await commentProvider.addComment(
      text: text,
      userName: auth.currentUserDisplayName ?? 'Anònim',
      userCategory: 'Usuari', // TODO: Obtenir de Firestore
      userPhotoUrl: auth.currentUserPhotoUrl,
      isOfficial: false, // TODO: Comprovar categoria
    );
  }

  Future<void> _submitReply(BuildContext context, String text) async {
    if (_replyingToCommentId == null) return;

    final auth = context.read<AuthProvider>();
    final commentProvider = context.read<CommentProvider>();

    if (!auth.isAuthenticated) return;

    await commentProvider.addReply(
      parentCommentId: _replyingToCommentId!,
      text: text,
      userName: auth.currentUserDisplayName ?? 'Anònim',
      userCategory: 'Usuari',
      userPhotoUrl: auth.currentUserPhotoUrl,
      isOfficial: false,
    );

    _cancelReply();
  }

  Future<void> _submitEdit(BuildContext context) async {
    if (_editingCommentId == null) return;

    final commentProvider = context.read<CommentProvider>();
    await commentProvider.updateComment(
      commentId: _editingCommentId!,
      text: _editController.text.trim(),
    );

    _cancelEdit();
  }

  Future<void> _deleteComment(BuildContext context, Comment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar comentari'),
        content: Text(
          comment.isReply
              ? 'Estàs segur que vols eliminar aquesta resposta?'
              : 'Estàs segur que vols eliminar aquest comentari? També s\'eliminaran totes les respostes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel·lar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final commentProvider = context.read<CommentProvider>();
      await commentProvider.deleteComment(
        commentId: comment.id,
        isReply: comment.isReply,
        parentCommentId: comment.parentCommentId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final commentProvider = context.watch<CommentProvider>();

    if (!auth.isAuthenticated) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('Inicia sessió per veure i escriure comentaris'),
        ),
      );
    }

    if (commentProvider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (commentProvider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                commentProvider.error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeComments,
                child: const Text('Tornar a intentar'),
              ),
            ],
          ),
        ),
      );
    }

    final comments = commentProvider.commentsWithReplies;
    final currentUserId = auth.currentUserUid;
    final isACBReferee = false; // TODO: Obtenir categoria de Firestore

    return Column(
      children: [
        // Header amb comptador
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.comment_outlined,
                size: 20,
                color: Colors.grey[700],
              ),
              const SizedBox(width: 8),
              Text(
                '${commentProvider.totalCommentsCount} comentaris',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),

        // Llista de comentaris
        Expanded(
          child: comments.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Encara no hi ha comentaris',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sigues el primer en comentar!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final commentWithReplies = comments[index];
                    final comment = commentWithReplies.comment;
                    final isCurrentUser = comment.userId == currentUserId;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Comentari principal
                        _editingCommentId == comment.id
                            ? _buildEditMode(context, comment)
                            : CommentItem(
                                comment: comment,
                                hasLiked: commentWithReplies.hasLiked,
                                isCurrentUser: isCurrentUser,
                                onReply: () => _startReply(
                                  comment.id,
                                  comment.userName,
                                ),
                                onLike: () => commentProvider.toggleLike(comment.id),
                                onEdit: () => _startEdit(comment),
                                onDelete: () => _deleteComment(context, comment),
                              ),

                        // Respostes
                        ...commentWithReplies.replies.map((reply) {
                          final isReplyOwner = reply.userId == currentUserId;
                          final hasLikedReply =
                              commentProvider.hasUserLiked(reply.id);

                          return _editingCommentId == reply.id
                              ? _buildEditMode(context, reply)
                              : CommentItem(
                                  comment: reply,
                                  hasLiked: hasLikedReply,
                                  isCurrentUser: isReplyOwner,
                                  isReply: true,
                                  onLike: () =>
                                      commentProvider.toggleLike(reply.id),
                                  onEdit: () => _startEdit(reply),
                                  onDelete: () =>
                                      _deleteComment(context, reply),
                                );
                        }),

                        // Input per respondre
                        if (_replyingToCommentId == comment.id)
                          CommentInput(
                            parentCommentId: comment.id,
                            replyingToName: _replyingToUserName,
                            isOfficial: isACBReferee,
                            onSubmit: (text) => _submitReply(context, text),
                            onCancel: _cancelReply,
                          ),

                        // Separador
                        Divider(
                          height: 1,
                          color: Colors.grey[300],
                        ),
                      ],
                    );
                  },
                ),
        ),

        // Input per comentari nou
        if (_editingCommentId == null)
          CommentInput(
            isOfficial: isACBReferee,
            onSubmit: (text) => _submitComment(context, text),
          ),
      ],
    );
  }

  Widget _buildEditMode(BuildContext context, Comment comment) {
    return Container(
      padding: EdgeInsets.only(
        left: comment.isReply ? 40 : 16,
        right: 16,
        top: 12,
        bottom: 12,
      ),
      color: AppTheme.lilaMitja.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                'Editant comentari',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _editController,
            maxLines: null,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Edita el teu comentari...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _cancelEdit,
                child: const Text('Cancel·lar'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _submitEdit(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.porpraFosc,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Desar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
