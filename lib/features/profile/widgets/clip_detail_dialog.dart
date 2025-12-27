import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import '../models/video_clip_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'edit_clip_dialog.dart';

/// Diàleg de detall del clip amb reproductor de vídeo
class ClipDetailDialog extends StatefulWidget {
  final VideoClip clip;

  const ClipDetailDialog({
    super.key,
    required this.clip,
  });

  @override
  State<ClipDetailDialog> createState() => _ClipDetailDialogState();
}

class _ClipDetailDialogState extends State<ClipDetailDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 900,
          maxHeight: 700,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header amb títol i botó de tancar
            _buildHeader(),

            // Contingut amb scroll
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reproductor de vídeo
                    _buildVideoPlayer(),
                    const SizedBox(height: 24),

                    // Informació del partit
                    _buildMatchInfo(),
                    const SizedBox(height: 24),

                    // Tags (tipus d'acció i resultat)
                    _buildTags(),
                    const SizedBox(height: 24),

                    // Descripció personal
                    if (widget.clip.personalDescription.isNotEmpty) ...[
                      _buildSection(
                        'Descripció personal',
                        widget.clip.personalDescription,
                        Icons.description,
                        AppTheme.porpraFosc,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Feedback tècnic
                    if (widget.clip.technicalFeedback != null &&
                        widget.clip.technicalFeedback!.isNotEmpty) ...[
                      _buildSection(
                        'Feedback del tècnic',
                        widget.clip.technicalFeedback!,
                        Icons.feedback,
                        Colors.blue,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Aprenentatge
                    if (widget.clip.learningNotes != null &&
                        widget.clip.learningNotes!.isNotEmpty) ...[
                      _buildSection(
                        'Reflexió i aprenentatge',
                        widget.clip.learningNotes!,
                        Icons.lightbulb,
                        Colors.orange,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Estadístiques
                    _buildStats(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.grisPistacho.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.clip.isPublic ? Icons.public : Icons.lock,
            color: widget.clip.isPublic ? AppTheme.mostassa : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.clip.matchInfo,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textBlackLow,
              ),
            ),
          ),
          // Botó editar
          IconButton(
            onPressed: () => _handleEdit(),
            icon: const Icon(Icons.edit),
            color: AppTheme.porpraFosc,
            tooltip: 'Editar clip',
          ),
          // Botó eliminar
          IconButton(
            onPressed: () => _handleDelete(),
            icon: const Icon(Icons.delete),
            color: Colors.red.shade700,
            tooltip: 'Eliminar clip',
          ),
          // Botó tancar
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            color: AppTheme.textBlackLow,
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    // Detectar si és un enllaç extern
    final isExternalUrl = _isExternalUrl(widget.clip.videoUrl);

    return Container(
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Thumbnail si existeix
          if (widget.clip.thumbnailUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.clip.thumbnailUrl!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),

          // Botó de reproducció
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openVideo(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.mostassa,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.black,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Badge amb tipus d'enllaç
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isExternalUrl ? Icons.link : Icons.cloud_upload,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isExternalUrl ? 'Enllaç extern' : 'Arxiu pujat',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchInfo() {
    return Row(
      children: [
        // Data del partit
        if (widget.clip.matchDate != null) ...[
          Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            _formatDate(widget.clip.matchDate!),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 24),
        ],

        // Categoria
        if (widget.clip.matchCategory != null) ...[
          Icon(Icons.sports_basketball, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            widget.clip.matchCategory!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 24),
        ],

        // Durada i mida
        Icon(Icons.timer, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '${widget.clip.formattedDuration} · ${widget.clip.formattedSize}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildTags() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildTag(
          widget.clip.actionType.displayName,
          AppTheme.porpraFosc,
          Icons.category,
        ),
        _buildTag(
          widget.clip.outcome.label,
          _getOutcomeColor(widget.clip.outcome),
          _getOutcomeIcon(widget.clip.outcome),
        ),
      ],
    );
  }

  Widget _buildTag(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.grisPistacho.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.visibility,
            widget.clip.viewCount.toString(),
            'Visualitzacions',
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade300,
          ),
          _buildStatItem(
            Icons.thumb_up,
            widget.clip.helpfulCount.toString(),
            'Útils',
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade300,
          ),
          _buildStatItem(
            Icons.access_time,
            _formatDate(widget.clip.createdAt),
            'Publicat',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 24, color: AppTheme.porpraFosc),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textBlackLow,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  bool _isExternalUrl(String url) {
    return url.contains('youtube.com') ||
        url.contains('youtu.be') ||
        url.contains('drive.google.com') ||
        url.contains('vimeo.com') ||
        url.contains('streamable.com');
  }

  Future<void> _openVideo() async {
    final url = Uri.parse(widget.clip.videoUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No es pot obrir el vídeo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getOutcomeColor(ClipOutcome outcome) {
    switch (outcome) {
      case ClipOutcome.encert:
        return Colors.green.shade700;
      case ClipOutcome.errada:
        return Colors.red.shade700;
      case ClipOutcome.dubte:
        return Colors.orange.shade700;
    }
  }

  IconData _getOutcomeIcon(ClipOutcome outcome) {
    switch (outcome) {
      case ClipOutcome.encert:
        return Icons.check_circle;
      case ClipOutcome.errada:
        return Icons.cancel;
      case ClipOutcome.dubte:
        return Icons.help;
    }
  }

  void _handleEdit() {
    // Tancar el diàleg actual
    Navigator.pop(context);

    // Obrir el diàleg d'edició (creat a continuació)
    showDialog(
      context: context,
      builder: (context) => EditClipDialog(clip: widget.clip),
    ).then((result) {
      if (result == 'success' && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clip actualitzat correctament!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Eliminar clip'),
          ],
        ),
        content: const Text(
          'Estàs segur que vols eliminar aquest clip? '
          'Aquesta acció no es pot desfer i s\'eliminarà tant el vídeo com el thumbnail.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel·lar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Eliminar de Firestore
        await FirebaseFirestore.instance
            .collection('video_clips')
            .doc(widget.clip.id)
            .delete();

        // TODO: Eliminar vídeo i thumbnail de Storage (opcional)
        // await FirebaseStorage.instance.refFromURL(widget.clip.videoUrl).delete();
        // if (widget.clip.thumbnailUrl != null) {
        //   await FirebaseStorage.instance.refFromURL(widget.clip.thumbnailUrl!).delete();
        // }

        // Actualitzar comptador si era públic
        if (widget.clip.isPublic) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.clip.userId)
              .update({'sharedClipsCount': FieldValue.increment(-1)});
        }

        if (mounted) {
          Navigator.pop(context); // Tancar el diàleg de detall
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Clip eliminat correctament'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error eliminant clip: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}