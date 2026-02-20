import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/features/media/presentation/instagram_reel_webview_page.dart';
import '../models/clip_model.dart';

class FeaturedClipsSection extends StatelessWidget {
  final List<ClipModel> clips;
  final String defaultThumbnail;

  const FeaturedClipsSection({
    super.key,
    required this.clips,
    required this.defaultThumbnail,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Títol de la secció
        Text(
          'Clips destacats',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.grisPistacho,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Selecció setmanal de situacions reals per analitzar',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.grisPistacho.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 8),
        // Indicador de scroll
        Row(
          children: [
            Icon(
              Icons.swipe_right_alt,
              size: 14,
              color: AppTheme.mostassa.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 6),
            Text(
              'Llisca per veure tots els clips',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 11,
                color: AppTheme.grisPistacho.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Carrusel de clips
        SizedBox(
          height: 240,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                  },
                ),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: clips.length,
                  separatorBuilder: (ctx, i) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final clip = clips[index];
                    return _ClipCard(
                      clip: clip,
                      defaultThumbnail: defaultThumbnail,
                    );
                  },
                ),
              ),
              // Fletxa indicadora de scroll (sense degradat, només icona)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    width: 32,
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.grisBody.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        color: AppTheme.mostassa,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClipCard extends StatelessWidget {
  final ClipModel clip;
  final String defaultThumbnail;

  const _ClipCard({required this.clip, required this.defaultThumbnail});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280, // Amplada fixa per clip
      margin: const EdgeInsets.only(bottom: 8, right: 2), // Per l'ombra
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          if (kIsWeb || !clip.isInstagram) {
            final uri = Uri.parse(clip.url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          } else {
            // Gestió especial per Instagram Reels (igual que abans)
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => InstagramReelWebviewPage(
                  reelUrl: clip.url,
                  title: clip.title,
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imatge / Thumbnail
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Image.network(
                      clip.getThumbnailUrl(defaultThumbnail),
                      fit: BoxFit.cover,
                      // Optimització de memòria: redimensionem la imatge al tamany visible aproximat
                      // El widget fa uns 280 d'ample i ~140 d'alt.
                      // CacheWidth 400 és segur per pantalles d'alta densitat.
                      cacheWidth: 400,
                      errorBuilder: (context, error, stackTrace) {
                        final url = clip.getThumbnailUrl(defaultThumbnail);
                        debugPrint('⚠️ Error loading thumbnail: $url');
                        // Provem una alternativa si la imatge hqdefault falla (a vegades passa en videos antics o shorts)
                        if (url.contains('hqdefault.jpg')) {
                          final mqUrl = url.replaceFirst(
                            'hqdefault.jpg',
                            'mqdefault.jpg',
                          );
                          return Image.network(
                            mqUrl,
                            fit: BoxFit.cover,
                            cacheWidth: 400, // També a la imatge de fallback
                            errorBuilder: (_, __, ___) => Container(
                              color: AppTheme.porpraFosc,
                              child: const Center(
                                child: Icon(Icons.movie, color: Colors.white),
                              ),
                            ),
                          );
                        }
                        return Container(
                          color: AppTheme.porpraFosc,
                          child: const Center(
                            child: Icon(Icons.movie, color: Colors.white),
                          ),
                        );
                      },
                    ),
                  ),
                  // Overlay fosc degradat
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Icona Play
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.mostassa.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  // Badge tipus (Instagram/YouTube)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            clip.isInstagram
                                ? Icons.camera_alt_outlined
                                : Icons.ondemand_video,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            clip.isInstagram ? 'Reel' : 'Video',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Text Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      clip.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.porpraFosc,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      clip.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.grisPistacho,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
