import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

class FeaturedVideo extends StatefulWidget {
  const FeaturedVideo({super.key});

  @override
  State<FeaturedVideo> createState() => _FeaturedVideoState();
}

class _FeaturedVideoState extends State<FeaturedVideo> {
  late final VideoPlayerController
  _controller = VideoPlayerController.networkUrl(
    Uri.parse(
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/home_page%2Freferee_home.mp4?alt=media&token=359fbbd2-971e-4b0f-aa6e-198c3bdc3724',
    ),
  )..setLooping(true);

  @override
  void initState() {
    super.initState();
    _controller.initialize().then((_) {
      _controller.play();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    if (isDesktop) {
      if (!_controller.value.isInitialized) {
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
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
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
    } else {
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
}
