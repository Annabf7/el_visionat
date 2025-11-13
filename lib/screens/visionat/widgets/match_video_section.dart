import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class MatchVideoSection extends StatelessWidget {
  const MatchVideoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVideoThumbnail(context),
          const SizedBox(height: 12),
          _buildActaButton(context),
        ],
      ),
    );
  }

  Widget _buildVideoThumbnail(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        image: const DecorationImage(
          image: NetworkImage(
            'https://via.placeholder.com/640x360/2F313C/FFFFFF?text=CB+Salt+vs+CB+Martorell',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Play button
          Center(
            child: GestureDetector(
              onTap: () => debugPrint('Play clicked'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
          // Progress bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                widthFactor: 0.75, // 75% progress
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          // Duration
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '67:32 / 90:00',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActaButton(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 600;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: isWideScreen ? Alignment.centerRight : Alignment.center,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.mostassa, // Yellow background
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppTheme.porpraFosc.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _onActaButtonPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      color: AppTheme.porpraFosc,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Acta del partit',
                      style: TextStyle(
                        color: AppTheme.porpraFosc,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onActaButtonPressed() {
    const url =
        'https://www.basquetcatala.cat/estadistiques/video/aibasket/?matchCallUuid=1efe419f-97ab-4a6b-83f6-5daedc915057';
    debugPrint('Opening external URL: $url');
    // In a real implementation, would use url_launcher package
  }
}
