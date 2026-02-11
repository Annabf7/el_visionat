import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

class NeuroCTASection extends StatelessWidget {
  const NeuroCTASection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.porpraFosc,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.psychology, color: AppTheme.mostassa, size: 40),
            const SizedBox(height: 16),
            Text(
              'Entrena la ment, arbitra amb neurociència',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Aplica una rutina neuro-arbitral avui mateix i comparteix la teva experiència amb l’equip. La ment també s’entrena!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 15,
                color: AppTheme.grisPistacho,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: const BorderSide(color: AppTheme.mostassa, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              onPressed: () {
                // Acció: compartir, obrir feedback, etc.
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Sessió d’entrenament iniciada!',
                      style: TextStyle(color: AppTheme.porpraFosc),
                    ),
                    backgroundColor: AppTheme.grisPistacho,
                  ),
                );
              },
              child: Text(
                'Entrena ara',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 16,
                  color: AppTheme.grisPistacho,
                  fontWeight: FontWeight.normal,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
