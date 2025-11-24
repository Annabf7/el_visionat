import 'package:flutter/material.dart';

/// Widget de banner amb imatge gran del perfil (només desktop)
class ProfileBannerWidget extends StatelessWidget {
  const ProfileBannerWidget({super.key});

  static const String _bannerImageUrl =
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/grandma_profile.webp?alt=media&token=fd59db9e-1b1b-47cf-a687-3306f80fd450';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: NetworkImage(_bannerImageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
