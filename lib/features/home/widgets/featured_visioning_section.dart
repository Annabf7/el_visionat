import 'package:flutter/material.dart';
import './_featured_video.dart';

class FeaturedVisioningSection extends StatelessWidget {
  const FeaturedVisioningSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    if (isDesktop) {
      // En desktop: retalla per la dreta i desplaça a l'esquerra
      return ClipRect(
        child: Transform.translate(
          offset: const Offset(-18, 0),
          child: const SizedBox.expand(child: FeaturedVideo()),
        ),
      );
    } else {
      // En mòbil: manté l'aspect ratio 16:9
      return AspectRatio(aspectRatio: 16 / 9, child: FeaturedVideo());
    }
  }
}
