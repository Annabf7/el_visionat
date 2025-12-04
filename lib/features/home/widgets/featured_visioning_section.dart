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
      // En mòbil: mostra la imatge amb proporció vertical professional
      return AspectRatio(
        aspectRatio: 744 / 1320,
        child: FeaturedVideo(),
      );
    }
  }
}
