import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
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
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    final provider = context.watch<HomeProvider>();
    if (isDesktop) {
      return Stack(
        children: [
          Positioned.fill(child: VideoPlayer(_controller)),
          Positioned.fill(
            child: Container(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.featuredVisioningTitle,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 36,
                      color: AppTheme.grisPistacho,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      // Mòbil: mostra el vídeo amb aspect ratio i reprodueix automàticament
      if (!_controller.value.isInitialized) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!_controller.value.isPlaying) {
        _controller.play();
      }
      return AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      );
    }
  }
}
