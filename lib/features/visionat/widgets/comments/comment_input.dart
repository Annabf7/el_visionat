// ============================================================================
// CommentInput - Widget per escriure comentaris i respostes
// ============================================================================

import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

class CommentInput extends StatefulWidget {
  final String? parentCommentId;
  final String? replyingToName;
  final bool isOfficial;
  final Function(String text) onSubmit;
  final VoidCallback? onCancel;

  const CommentInput({
    super.key,
    this.parentCommentId,
    this.replyingToName,
    this.isOfficial = false,
    required this.onSubmit,
    this.onCancel,
  });

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus quan és una resposta
    if (widget.parentCommentId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmit(text);
      _controller.clear();
      if (widget.onCancel != null) {
        widget.onCancel!();
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReply = widget.parentCommentId != null;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isReply ? 8 : 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: widget.isOfficial
            ? AppTheme.lilaMitja.withValues(alpha: 0.05)
            : Colors.grey[50],
        border: Border(
          top: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header per respostes
          if (isReply && widget.replyingToName != null) ...[
            Row(
              children: [
                Icon(
                  Icons.reply,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Responent a ${widget.replyingToName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Spacer(),
                if (widget.onCancel != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: widget.onCancel,
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Banner per veredictes oficials
          if (widget.isOfficial) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.mostassa.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppTheme.mostassa,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.gavel,
                    size: 16,
                    color: AppTheme.mostassa,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Veredicte oficial ACB - Aquest comentari tancarà el debat',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.mostassa,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Input field
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: isReply
                        ? 'Escriu una resposta...'
                        : 'Afegeix un comentari...',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: widget.isOfficial
                            ? AppTheme.mostassa
                            : AppTheme.porpraFosc,
                        width: 2,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _handleSubmit(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                icon: _isSubmitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: widget.isOfficial
                              ? AppTheme.mostassa
                              : AppTheme.porpraFosc,
                        ),
                      )
                    : Icon(
                        Icons.send,
                        color: widget.isOfficial
                            ? AppTheme.mostassa
                            : AppTheme.porpraFosc,
                      ),
                tooltip: 'Enviar',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
