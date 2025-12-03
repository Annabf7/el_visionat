import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
import './_featured_video.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

class FeaturedVisioningSection extends StatelessWidget {
  const FeaturedVisioningSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();

    return Container(
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: AppTheme.porpraFosc, // Placeholder color
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            provider.featuredVisioningTitle,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 36,
              color: AppTheme.grisPistacho,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            provider.featuredVisioningSubtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              color: AppTheme.grisPistacho,
            ),
          ),
          const SizedBox(height: 32),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FeaturedVideo(),
            ),
          ),
        ],
      ),
    );
  }
}
