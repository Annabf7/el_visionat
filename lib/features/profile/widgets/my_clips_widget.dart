import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import '../models/video_clip_model.dart';
import 'add_clip_dialog.dart';

/// Widget que mostra la llista de clips de l'usuari
/// Inclou botó per afegir nous clips
class MyClipsWidget extends StatelessWidget {
  const MyClipsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('video_clips')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final hasError = snapshot.hasError;
        final docs = snapshot.data?.docs ?? [];
        final hasClips = !isLoading && !hasError && docs.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header amb títol (i botó només si ja té clips)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Els meus clips',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    color: AppTheme.textBlackLow,
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                  ),
                ),
                if (hasClips)
                  ElevatedButton.icon(
                    onPressed: () => _showAddClipDialog(context),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Afegir clip'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.mostassa,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Contingut
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (hasError || docs.isEmpty)
              _buildEmptyState(context)
            else
              Column(
                children: docs.map((doc) {
                  final clip = VideoClip.fromFirestore(doc);
                  return _buildClipCard(context, clip);
                }).toList(),
              ),
          ],
        );
      },
    );
  }

  void _showAddClipDialog(BuildContext context) {
    showDialog<String>(
      context: context,
      builder: (dialogContext) => const AddClipDialog(),
    ).then((result) {
      if (result == 'success' && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clip afegit correctament!')),
        );
      }
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.mostassa.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.mostassa.withValues(alpha: 0.3),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.mostassa.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.video_library_outlined,
              size: 48,
              color: AppTheme.porpraFosc,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Puja el teu primer clip',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textBlackLow,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Comparteix moments clau dels teus videoinformes.\nAprèn dels teus encerts i errors, i ajuda als companys!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppTheme.textBlackLow.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),

          // Botó principal per pujar
          ElevatedButton.icon(
            onPressed: () => _showAddClipDialog(context),
            icon: const Icon(Icons.upload, size: 20),
            label: const Text('Pujar clip des del dispositiu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.mostassa,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Info sobre formats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Màx. 60 segons · 25MB · Format MP4',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClipCard(BuildContext context, VideoClip clip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showClipDetails(context, clip),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Thumbnail placeholder
              Container(
                width: 80,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.grisPistacho.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: clip.thumbnailUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          clip.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.play_circle_outline, size: 32),
                        ),
                      )
                    : const Icon(Icons.play_circle_outline, size: 32),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clip.matchInfo,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildTag(
                          clip.actionType.displayName,
                          AppTheme.porpraFosc,
                        ),
                        const SizedBox(width: 8),
                        _buildTag(
                          clip.outcome.label,
                          _getOutcomeColor(clip.outcome),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${clip.formattedDuration} · ${clip.formattedSize}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Visibilitat i més
              Column(
                children: [
                  Icon(
                    clip.isPublic ? Icons.public : Icons.lock,
                    size: 20,
                    color: clip.isPublic ? AppTheme.mostassa : Colors.grey,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    clip.isPublic ? 'Públic' : 'Privat',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
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

  void _showClipDetails(BuildContext context, VideoClip clip) {
    // TODO: Implementar vista detallada del clip amb reproductor
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Obrint clip: ${clip.matchInfo}')));
  }
}
