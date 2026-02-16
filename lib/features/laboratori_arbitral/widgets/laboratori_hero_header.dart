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
    // Si el vídeo està carregat, utilitzem el seu aspect ratio original
    // Si no, usem una proporció per defecte de 16:9
    double aspectRatio = 16 / 9;
    if (_initialized &&
        !_hasError &&
        _controller != null &&
        _controller!.value.aspectRatio > 0) {
      aspectRatio = _controller!.value.aspectRatio;
    }

    // Usem AspectRatio per desktop per mantenir la proporció perfecta.
    // Però en MÒBIL (o pantalles estretes), l'AspectRatio pot fer que l'alçada sigui massa
    // petita per contenir el text, provocant overflow.

    // MILLOR ESTRATÈGIA HÍBRIDA:
    // En lloc de AspectRatio rígid, usem un Container que intenta respectar el ratio
    // però creix si cal (minHeight).
    //
    // Com que AspectRatio és rígid, el traiem i calculem l'alçada nosaltres.
    // MOD: Use local variable for ratio
    double effectiveRatio = aspectRatio;
    if (MediaQuery.of(context).size.width <= 600) {
      effectiveRatio = 1.1; // Make it more square on mobile
    }

    return AspectRatio(
      aspectRatio: effectiveRatio,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(color: Colors.black),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Capa 1: Fons (Imatge)
            Image.network(
              widget.fallbackImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.black),
            ),

            // Capa 2: Fons (Vídeo)
            if (_initialized && !_hasError && _controller != null)
              FadeTransition(
                opacity: const AlwaysStoppedAnimation(1.0),
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: _controller!.value.size.width,
                      height: _controller!.value.size.height,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                ),
              ),

            // Capa 3: Overlay Gradient fosc
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.9), // Més opac a baix
                    ],
                  ),
                ),
              ),
            ),

            // Capa 4: Contingut text a sobre
            Align(alignment: Alignment.bottomLeft, child: widget.child),
          ],
        ),
      ),
    );
  }
}
