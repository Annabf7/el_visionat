import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

class NeuroCTASection extends StatelessWidget {
  const NeuroCTASection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Card(
        color: AppTheme.porpraFosc,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.psychology, color: AppTheme.grisPistacho, size: 40),
              const SizedBox(height: 12),
              Text(
                'Entrena la ment, arbitra amb neurociència',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.white,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Aplica una rutina neuro-arbitral avui mateix i comparteix la teva experiència amb l’equip. La ment també s’entrena!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 15,
                  color: AppTheme.grisPistacho,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.grisPistacho,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                ),
                onPressed: () {
                  // Acció: compartir, obrir feedback, etc.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gràcies per entrenar la ment!'),
                      backgroundColor: AppTheme.porpraFosc,
                    ),
                  );
                },
                child: Text(
                  'Entrena ara',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 16,
                    color: AppTheme.porpraFosc,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
