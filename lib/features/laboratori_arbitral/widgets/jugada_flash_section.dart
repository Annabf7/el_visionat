import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/features/media/presentation/instagram_reel_webview_page.dart';
import '../models/clip_model.dart';

class JugadaFlashSection extends StatelessWidget {
  final List<ClipModel> jugades;

  const JugadaFlashSection({super.key, required this.jugades});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Títol
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.mostassa.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, color: AppTheme.mostassa, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'FCBQ',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: AppTheme.mostassa.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Jugada Flash 2025-2026',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.grisPistacho,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Directives de la FCBQ sobre situacions específiques de joc',
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
              'Llisca per veure totes les jugades',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 11,
                color: AppTheme.grisPistacho.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Carrusel de jugades
        SizedBox(
          height: 160,
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
                  itemCount: jugades.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return _FlashCard(clip: jugades[index], number: index + 1);
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

class _FlashCard extends StatelessWidget {
  final ClipModel clip;
  final int number;

  const _FlashCard({required this.clip, required this.number});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (kIsWeb) {
          final uri = Uri.parse(clip.url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } else {
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
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: AppTheme.porpraFosc,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.mostassa.withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.bolt, color: AppTheme.mostassa, size: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.mostassa.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'FCBQ',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppTheme.mostassa.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '#$number',
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Jugada Flash',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Obrir post',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 10,
                      color: AppTheme.mostassa.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_forward,
                    size: 10,
                    color: AppTheme.mostassa.withValues(alpha: 0.8),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
