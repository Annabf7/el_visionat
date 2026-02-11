import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class NeuroVideoResourcesSection extends StatelessWidget {
  const NeuroVideoResourcesSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Llista de vídeos amb ID, títol i tema
    final videos = [
      _VideoData(
        id: 'vhf8DMYNgi8',
        title: 'QUIET EYE - A Simple Way to IMPROVE PERFORMANCE',
        topic: 'Focus Visual',
      ),
      _VideoData(
        id: 'NK0gXKmRz7w',
        title: 'Eye Exercises for Improved Focus (Andrew Huberman)',
        topic: 'Neurociència Visual',
      ),
      _VideoData(
        id: 'GHnuyJFGVng',
        title: 'Amygdala Hijacks Explanation (Daniel Goleman)',
        topic: 'Gestió Emocional',
      ),
      _VideoData(
        id: 'vJG698U2Mvo',
        title: 'Selective Attention Test (Invisible Gorilla)',
        topic: 'Error Perceptiu',
      ),
      _VideoData(
        id: 'WuyPuH9ojCE',
        title: 'How stress affects your brain (Ted-Ed)',
        topic: 'Estrès i Cervell',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            'Videoteca Neurocientífica',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.grisPistacho,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220, // Alçada fixa per al scroll horitzontal (reduït de 240)
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: videos.length,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return _VideoCard(video: videos[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _VideoData {
  final String id;
  final String title;
  final String topic;

  _VideoData({required this.id, required this.title, required this.topic});

  String get thumbnailUrl => 'https://img.youtube.com/vi/$id/hqdefault.jpg';
  String get videoUrl => 'https://www.youtube.com/watch?v=$id';
}

class _VideoCard extends StatelessWidget {
  final _VideoData video;

  const _VideoCard({required this.video});

  Future<void> _launchUrl() async {
    final uri = Uri.parse(video.videoUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220, // Amplada reduïda de 260 a 200 per encabir més clips
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _launchUrl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thumbnail amb botó de play
              Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    video.thumbnailUrl,
                    height: 112, // 16:9 ratio per width 200
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 112,
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey[500],
                        ),
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(
                      10,
                    ), // Icona una mica més petita
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
              // Informació
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.porpraFosc.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          video.topic,
                          style: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.porpraFosc,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        video.title,
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme
                              .porpraFosc, // Canviat a porpraFosc per contrast
                          height: 1.2,
                        ),
                        maxLines: 3, // Permetre 3 línies ja que és més estret
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
