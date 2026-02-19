import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class LaboratoriHeroHeader extends StatefulWidget {
  final String? gender;
  final String fallbackImageUrl;
  final Widget child;

  const LaboratoriHeroHeader({
    super.key,
    required this.gender,
    required this.fallbackImageUrl,
    required this.child,
  });

  @override
  State<LaboratoriHeroHeader> createState() => _LaboratoriHeroHeaderState();
}

class _LaboratoriHeroHeaderState extends State<LaboratoriHeroHeader> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _hasError = false;

  static const String _videoMan =
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/EL%20laboratori%20arbitral%2FComp%201_2_man.mp4?alt=media&token=59248f4e-13a0-44c9-8d43-5e2a59ad10cd';
  static const String _videoWoman =
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/EL%20laboratori%20arbitral%2FComp%201_3_women.mp4?alt=media&token=0d46731e-a0d3-4560-ab0d-36f93f643d96';

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(LaboratoriHeroHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gender != oldWidget.gender) {
      final oldUrl = oldWidget.gender == 'male' ? _videoMan : _videoWoman;
      final newUrl = widget.gender == 'male' ? _videoMan : _videoWoman;
      if (oldUrl != newUrl) {
        _disposeController();
        _initializeVideo();
      }
    }
  }

  Future<void> _initializeVideo() async {
    final videoUrl = widget.gender == 'male' ? _videoMan : _videoWoman;

    if (!mounted) return;

    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      await _controller!.initialize();
      // Optimització: Volume 0 abans de play
      await _controller!.setVolume(0.0);
      await _controller!.setLooping(true);
      await _controller!.play();

      if (mounted) {
        setState(() {
          _initialized = true;
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video header: \$e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _initialized = false;
        });
      }
    }
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _initialized = false;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool videoReady = _initialized && !_hasError && _controller != null;

    // Alçada fixa estàndard per a un header global
    const double headerHeight = 350.0;

    return Container(
      height: headerHeight,
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(color: Colors.black),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Capa 1: Imatge poster
          Positioned.fill(
            child: Image.network(
              widget.fallbackImageUrl,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),

          // Capa 2: Vídeo amb crossfade suau
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: videoReady ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeIn,
              child: videoReady
                  ? FittedBox(
                      fit: BoxFit.cover,
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        width: _controller!.value.size.width,
                        height: _controller!.value.size.height,
                        child: VideoPlayer(_controller!),
                      ),
                    )
                  : const SizedBox(),
            ),
          ),

          // Capa 3: Overlay gradient fosc
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
          ),

          // Capa 4: Contingut text a sobre
          Align(alignment: Alignment.bottomLeft, child: widget.child),
        ],
      ),
    );
  }
}
