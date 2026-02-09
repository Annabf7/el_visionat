import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

class FeaturedVideo extends StatefulWidget {
  const FeaturedVideo({super.key});

  @override
  State<FeaturedVideo> createState() => _FeaturedVideoState();
}

class _FeaturedVideoState extends State<FeaturedVideo>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  AnimationController? _textAnimController;

  static const _words = ['El', 'visionat', 'que', 'et', 'fa', 'crèixer'];

  @override
  void initState() {
    super.initState();
    _textAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _initializeVideo();
    // Inicia l'animació del text després d'un breu retard
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _textAnimController?.forward();
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textAnimController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(
          'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/home_page%2Freferee_home.mp4?alt=media&token=359fbbd2-971e-4b0f-aa6e-198c3bdc3724',
        ),
      );

      await _controller!.initialize();
      await _controller!.setLooping(true);
      await _controller!.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }

      debugPrint('FeaturedVideo: initialized and playing in loop');
    } catch (e) {
      debugPrint('Error initializing featured video: $e');
    }
  }

  /// Text animat paraula per paraula amb fade-in + lliscament vertical
  Widget _buildAnimatedTagline({required double fontSize}) {
    final controller = _textAnimController;
    if (controller == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Wrap(
          alignment: WrapAlignment.center,
          children: List.generate(_words.length, (i) {
            // Cada paraula té un interval esgraonat dins l'animació global
            final start = i / (_words.length + 2);
            final end = ((i + 3) / (_words.length + 2)).clamp(0.0, 1.0);

            final t = controller.value;
            final raw = ((t - start) / (end - start)).clamp(0.0, 1.0);
            final progress = Curves.easeOutCubic.transform(raw);

            return Opacity(
              opacity: progress,
              child: Transform.translate(
                offset: Offset(0, 14 * (1 - progress)),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: fontSize * 0.08),
                  child: Text(
                    _words[i],
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: fontSize,
                      color: AppTheme.grisPistacho,
                      fontWeight: FontWeight.normal,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    return isDesktop ? _buildDesktopView() : _buildMobileView();
  }

  Widget _buildDesktopView() {
    if (!_isInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              ),
              Center(
                child: _buildAnimatedTagline(fontSize: 32),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileView() {
    // Mòbil: mostra la imatge amb el text
    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/home_page/referee_home_page.jpeg',
            fit: BoxFit.cover,
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 84.0),
              child: _buildAnimatedTagline(fontSize: 22),
            ),
          ),
        ],
      ),
    );
  }
}
