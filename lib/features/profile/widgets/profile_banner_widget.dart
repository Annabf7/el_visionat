import 'package:flutter/material.dart';

/// Widget de banner amb imatge gran del perfil (només desktop)
/// Mostra una imatge fixa (NO editable per l'usuari)
class ProfileBannerWidget extends StatelessWidget {
  const ProfileBannerWidget({super.key});

  // Imatge fixa del banner (NO editable)
  static const String _fixedBannerImageUrl =
      'https://firebasestorage.googleapis.com/v0/b/el-visionat.firebasestorage.app/o/grandma_gemini.webp?alt=media&token=c2531356-518a-45b5-8c08-480326b06337';

  @override
  Widget build(BuildContext context) {
    return Image.network(
      _fixedBannerImageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      alignment: const Alignment(0, 1), // Centrada cap amunt
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // Si falla la càrrega, mostra un placeholder
        return Container(
          color: Colors.grey[300],
          child: const Center(
            child: Icon(Icons.image, size: 64, color: Colors.grey),
          ),
        );
      },
    );
  }
}
