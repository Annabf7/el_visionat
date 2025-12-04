import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

class FeaturedVideo extends StatefulWidget {
  const FeaturedVideo({super.key});

  @override
  State<FeaturedVideo> createState() => _FeaturedVideoState();
}

class _FeaturedVideoState extends State<FeaturedVideo> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _controller?.dispose();
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
                child: const Text(
                  'El visionat que et fa crèixer',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 32,
                    color: AppTheme.grisPistacho,
                    fontWeight: FontWeight.normal,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
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
              child: Text(
                'El visionat que et fa crèixer',
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 22,
                  color: AppTheme.grisPistacho,
                  fontWeight: FontWeight.normal,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
