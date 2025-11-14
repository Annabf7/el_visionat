import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../models/collective_comment.dart';

class CollectiveAnalysisModal extends StatefulWidget {
  final List<CollectiveComment> comments;
  final Function(String text, bool isAnonymous) onCommentAdded;

  const CollectiveAnalysisModal({
    super.key,
    required this.comments,
    required this.onCommentAdded,
  });

  @override
  State<CollectiveAnalysisModal> createState() =>
      _CollectiveAnalysisModalState();
}

class _CollectiveAnalysisModalState extends State<CollectiveAnalysisModal> {
  final _commentController = TextEditingController();
  bool _isAnonymous = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() {
    if (_commentController.text.trim().isNotEmpty) {
      widget.onCommentAdded(_commentController.text.trim(), _isAnonymous);
      _commentController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Comentari enviat correctament!'),
          backgroundColor: AppTheme.lilaMitja,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isWideScreen = MediaQuery.of(context).size.width >= 900;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        maxWidth: isWideScreen ? 700 : double.infinity,
      ),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: isWideScreen
            ? BorderRadius.circular(16)
            : const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.lilaMitja,
              borderRadius: isWideScreen
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    )
                  : const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
            ),
            child: Row(
              children: [
                Icon(Icons.forum, color: AppTheme.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Anàlisi col·lectiva del partit',
                    style: textTheme.titleLarge?.copyWith(
                      color: AppTheme.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: AppTheme.white),
                ),
              ],
            ),
          ),

          // Llista de comentaris
          Expanded(
            child: widget.comments.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.comments.length,
                    itemBuilder: (context, index) {
                      final comment = widget.comments[index];
                      return _buildCommentItem(comment);
                    },
                  ),
          ),

          // Formulari per afegir comentari
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.white,
              border: Border(
                top: BorderSide(
                  color: AppTheme.grisBody.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Toggle anònim/públic
                Row(
                  children: [
                    Icon(Icons.visibility, size: 18, color: AppTheme.lilaMitja),
                    const SizedBox(width: 8),
                    Text(
                      'Comentari:',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.porpraFosc,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isAnonymous = !_isAnonymous;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _isAnonymous
                              ? AppTheme.grisBody.withValues(alpha: 0.1)
                              : AppTheme.lilaMitja.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isAnonymous
                                ? AppTheme.grisBody
                                : AppTheme.lilaMitja,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isAnonymous
                                  ? Icons.visibility_off
                                  : Icons.person,
                              size: 14,
                              color: _isAnonymous
                                  ? AppTheme.grisBody
                                  : AppTheme.lilaMitja,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isAnonymous ? 'Anònim' : 'Públic',
                              style: TextStyle(
                                color: _isAnonymous
                                    ? AppTheme.grisBody
                                    : AppTheme.lilaMitja,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // TextField per comentari
                TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText:
                        'Comparteix la teva opinió sobre l\'arbitratge...',
                    hintStyle: TextStyle(
                      color: AppTheme.grisBody.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.lilaMitja),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppTheme.lilaMitja,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  maxLines: 3,
                  style: TextStyle(color: AppTheme.porpraFosc, fontSize: 14),
                ),
                const SizedBox(height: 12),

                // Botó enviar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitComment,
                    icon: const Icon(Icons.send),
                    label: const Text(
                      'Enviar comentari',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.lilaMitja,
                      foregroundColor: AppTheme.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 48,
              color: AppTheme.grisBody.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Encara no hi ha comentaris',
              style: TextStyle(
                color: AppTheme.grisBody,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sigues el primer a compartir la teva opinió!',
              style: TextStyle(
                color: AppTheme.grisBody.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(CollectiveComment comment) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.grisBody.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del comentari
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: comment.anonymous
                      ? AppTheme.grisBody.withValues(alpha: 0.1)
                      : AppTheme.lilaMitja.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  comment.anonymous ? Icons.visibility_off : Icons.person,
                  size: 12,
                  color: comment.anonymous
                      ? AppTheme.grisBody
                      : AppTheme.lilaMitja,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                comment.displayName,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.porpraFosc,
                ),
              ),
              const Spacer(),
              Text(
                comment.formattedDate,
                style: textTheme.bodySmall?.copyWith(
                  color: AppTheme.grisBody.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Text del comentari
          Text(
            comment.text,
            style: textTheme.bodyMedium?.copyWith(
              color: AppTheme.porpraFosc,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Funció helper per mostrar el modal
Future<void> showCollectiveAnalysisModal(
  BuildContext context, {
  required List<CollectiveComment> comments,
  required Function(String text, bool isAnonymous) onCommentAdded,
}) async {
  final isWideScreen = MediaQuery.of(context).size.width >= 900;

  if (isWideScreen) {
    // Desktop: Dialog centrat
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: CollectiveAnalysisModal(
          comments: comments,
          onCommentAdded: onCommentAdded,
        ),
      ),
    );
  } else {
    // Mòbil: Bottom sheet fullscreen
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CollectiveAnalysisModal(
        comments: comments,
        onCommentAdded: onCommentAdded,
      ),
    );
  }
}
