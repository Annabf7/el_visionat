import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/youtube_provider.dart';
import '../models/youtube_video.dart';

/// Widget que mostra clips de vídeo de YouTube del canal Club del Árbitro
///
/// Inclou miniatures clicables, títols i dates de publicació.
/// Gestiona estats de càrrega, error i llista buida.
class ClipsSection extends StatefulWidget {
  const ClipsSection({super.key});

  @override
  State<ClipsSection> createState() => _ClipsSectionState();
}

class _ClipsSectionState extends State<ClipsSection> {
  @override
  void initState() {
    super.initState();

    // Inicialització lazy per evitar càrregues innecessàries
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<YouTubeProvider>().ensureInitialized();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            Consumer<YouTubeProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && !provider.hasVideos) {
                  return _buildLoadingState();
                }

                if (provider.hasError && !provider.hasVideos) {
                  return _buildErrorState(context, provider);
                }

                if (!provider.hasVideos) {
                  return _buildEmptyState();
                }

                return _buildVideosList(context, provider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.video_library_outlined,
          color: Theme.of(context).colorScheme.primary,
          size: MediaQuery.of(context).size.width < 600 ? 20 : 24,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Clips del Club de l\'Àrbitre',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: MediaQuery.of(context).size.width < 600 ? 16 : 18,
            ),
          ),
        ),
        Consumer<YouTubeProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }

            return IconButton(
              onPressed: () => provider.refresh(),
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Actualitzar clips',
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 120,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            'Carregant clips...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, YouTubeProvider provider) {
    return Container(
      height: 120,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            provider.errorMessage ?? 'Error carregant clips',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () => provider.refresh(),
            child: const Text('Tornar a provar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 120,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'No hi ha clips disponibles',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideosList(BuildContext context, YouTubeProvider provider) {
    return Column(
      children: provider.videos.take(5).map((video) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildVideoTile(context, video),
        );
      }).toList(),
    );
  }

  Widget _buildVideoTile(BuildContext context, YouTubeVideo video) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return InkWell(
      onTap: () => _openVideo(video.youtubeUrl),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnail(context, video, isMobile),
            const SizedBox(width: 12),
            Expanded(child: _buildVideoInfo(context, video, isMobile)),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(
    BuildContext context,
    YouTubeVideo video,
    bool isMobile,
  ) {
    final size = isMobile ? 80.0 : 100.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        children: [
          Image.network(
            video.thumbnailUrl,
            width: size,
            height: size * 0.75, // Aspecte 4:3 típic de YouTube
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: size,
                height: size * 0.75,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: size,
                height: size * 0.75,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
          // Overlay d'icona de reproducció
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Icon(Icons.play_arrow, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoInfo(
    BuildContext context,
    YouTubeVideo video,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          video.displayTitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: isMobile ? 14 : 15,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          video.formattedDate,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: isMobile ? 12 : 13,
          ),
        ),
      ],
    );
  }

  Future<void> _openVideo(String url) async {
    try {
      final uri = Uri.parse(url);

      // Estratègia múltiple per Android: provar diferents modes de llançament
      bool launched = false;

      // 1. Intentar obrir amb app externa específica (YouTube app si està disponible)
      try {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalNonBrowserApplication,
        );
      } catch (e) {
        // Continuar amb la següent estratègia
      }

      // 2. Si no funciona, provar amb aplicació externa general
      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {
          // Continuar amb la següent estratègia
        }
      }

      // 3. Fallback: verificar disponibilitat i obrir en navegador extern
      if (!launched) {
        if (await canLaunchUrl(uri)) {
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      }

      // 4. Si tot falla, mostrar error descriptiu
      if (!launched && mounted) {
        _showError(
          'No es pot obrir YouTube. Assegura\'t que tens una app compatible instal·lada.',
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Error obrint el vídeo: ${e.toString()}');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
