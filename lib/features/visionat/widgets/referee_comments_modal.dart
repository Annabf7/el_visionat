// ============================================================================
// RefereeCommentsModal - Modal per veure i afegir comentaris d'àrbitres
// ============================================================================
// Permet als àrbitres comentar jugades destacades amb opció d'anonimitat
// Mostra tots els comentaris ordenats per categoria (màxima autoritat primer)

import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/core/constants/referee_category_colors.dart';
import '../models/referee_comment.dart';
import '../models/highlight_play.dart';
import 'referee_category_badge.dart';

/// Callback per afegir un nou comentari
typedef OnCommentAdded = Future<void> Function(String comment, bool isAnonymous);

/// Modal per mostrar comentaris d'àrbitres sobre una jugada
void showRefereeCommentsModal({
  required BuildContext context,
  required HighlightPlay play,
  required List<RefereeComment> comments,
  required RefereeCategory currentUserCategory,
  required OnCommentAdded onCommentAdded,
  VoidCallback? onClose,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => RefereeCommentsModal(
      play: play,
      comments: comments,
      currentUserCategory: currentUserCategory,
      onCommentAdded: onCommentAdded,
      onClose: onClose,
    ),
  );
}

class RefereeCommentsModal extends StatefulWidget {
  final HighlightPlay play;
  final List<RefereeComment> comments;
  final RefereeCategory currentUserCategory;
  final OnCommentAdded onCommentAdded;
  final VoidCallback? onClose;

  const RefereeCommentsModal({
    super.key,
    required this.play,
    required this.comments,
    required this.currentUserCategory,
    required this.onCommentAdded,
    this.onClose,
  });

  @override
  State<RefereeCommentsModal> createState() => _RefereeCommentsModalState();
}

class _RefereeCommentsModalState extends State<RefereeCommentsModal> {
  final TextEditingController _commentController = TextEditingController();
  bool _isAnonymous = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || text.length < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El comentari ha de tenir mínim 50 caràcters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.onCommentAdded(text, _isAnonymous);
      _commentController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comentari afegit correctament'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedComments = _sortCommentsByHierarchy(widget.comments);
    final canAddComment = !widget.play.isResolved;
    final canCloseDebate = RefereeCategoryColors.canCloseDebate(widget.currentUserCategory);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(context),

          // Info de la jugada
          _buildPlayInfo(),

          // Llista de comentaris
          Expanded(
            child: sortedComments.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedComments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildCommentCard(sortedComments[index]);
                    },
                  ),
          ),

          // Input per afegir comentari (només si no està resolt)
          if (canAddComment) _buildCommentInput(canCloseDebate),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.porpraFosc,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.comment, color: AppTheme.grisPistacho, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Comentaris d\'Àrbitres',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.grisPistacho,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: AppTheme.grisPistacho),
            onPressed: () {
              widget.onClose?.call();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlayInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE8E7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.play.title,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.porpraFosc,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Minutatge: ${_formatDuration(widget.play.timestamp)} • ${widget.play.category}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppTheme.grisBody,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.play.description,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppTheme.grisBody.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.comment_outlined,
            size: 64,
            color: AppTheme.grisPistacho.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Encara no hi ha comentaris',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: AppTheme.grisBody.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sigues el primer en comentar!',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppTheme.grisBody.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(RefereeComment comment) {
    final isOfficial = comment.isOfficial;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOfficial
            ? const Color(0xFF50C878).withValues(alpha: 0.1)
            : const Color(0xFFEDE8E7),
        borderRadius: BorderRadius.circular(12),
        border: isOfficial
            ? Border.all(color: const Color(0xFF50C878), width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: badge + temps
          Row(
            children: [
              RefereeCategoryBadge(
                category: comment.category,
                isAnonymous: comment.isAnonymous,
                displayName: comment.refereeDisplayName,
              ),
              const Spacer(),
              Text(
                _formatTimeAgo(comment.createdAt),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppTheme.grisBody.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),

          if (isOfficial) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF50C878).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, size: 12, color: const Color(0xFF50C878)),
                  const SizedBox(width: 4),
                  Text(
                    'Veredicte Oficial',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF50C878),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Comentari
          Text(
            comment.comment,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppTheme.grisBody,
              height: 1.5,
            ),
          ),

          if (comment.isEdited) ...[
            const SizedBox(height: 8),
            Text(
              'Editat',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppTheme.grisBody.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentInput(bool canCloseDebate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        border: Border(
          top: BorderSide(color: AppTheme.grisPistacho.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Opcions
          Row(
            children: [
              Checkbox(
                value: _isAnonymous,
                onChanged: (val) => setState(() => _isAnonymous = val ?? true),
                activeColor: AppTheme.porpraFosc,
              ),
              Text(
                'Comentari anònim',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppTheme.grisBody,
                ),
              ),
              const Spacer(),
              if (canCloseDebate)
                TextButton.icon(
                  onPressed: () {
                    // TODO: Marcar com a veredicte oficial
                  },
                  icon: Icon(Icons.verified, size: 16),
                  label: Text('Tancar debat'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF50C878),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Input
          TextField(
            controller: _commentController,
            maxLines: 3,
            enabled: !_isSubmitting,
            decoration: InputDecoration(
              hintText: 'Escriu el teu comentari (mínim 50 caràcters)...',
              hintStyle: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppTheme.grisBody.withValues(alpha: 0.5),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.grisPistacho.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.porpraFosc, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Botó enviar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitComment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.porpraFosc,
                foregroundColor: AppTheme.grisPistacho,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.grisPistacho,
                      ),
                    )
                  : Text(
                      'Publicar comentari',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Ordena comentaris per jerarquia (màxima autoritat primer)
  List<RefereeComment> _sortCommentsByHierarchy(List<RefereeComment> comments) {
    final sorted = List<RefereeComment>.from(comments);
    sorted.sort((a, b) {
      // Oficials primer
      if (a.isOfficial && !b.isOfficial) return -1;
      if (!a.isOfficial && b.isOfficial) return 1;

      // Després per jerarquia
      final hierarchyA = RefereeCategoryColors.getHierarchyLevel(a.category);
      final hierarchyB = RefereeCategoryColors.getHierarchyLevel(b.category);
      if (hierarchyA != hierarchyB) return hierarchyA.compareTo(hierarchyB);

      // Finalment per data (més recents primer)
      return b.createdAt.compareTo(a.createdAt);
    });
    return sorted;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'Fa ${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return 'Fa ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'Fa ${difference.inMinutes}min';
    } else {
      return 'Ara mateix';
    }
  }
}
