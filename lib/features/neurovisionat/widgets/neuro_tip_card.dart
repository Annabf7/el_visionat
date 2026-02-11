import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

class NeuroTipCard extends StatelessWidget {
  const NeuroTipCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: AppTheme.porpraFosc.withValues(alpha: 0.92),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.psychology_alt,
                  color: AppTheme.grisPistacho,
                  size: 36,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Neuro-tip del dia',
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.grisPistacho,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getNeuroTip(),
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.white.withValues(alpha: 0.92),
                          letterSpacing: 1.05,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getNeuroTip() {
    final tips = [
      'Respira profundament abans de cada decisió clau: el cervell necessita oxigen per regular l’impuls.',
      'Visualitza el play abans d’actuar: la neurociència demostra que la visualització millora la resposta.',
      'Després d’un error, aplica un micro-reset: una paraula clau o gest pot trencar la cadena d’errors.',
      'Simplifica el focus en moments de pressió: menys informació, millor decisió.',
      'La postura corporal influeix en la percepció d’autoritat i regula el sistema nerviós.',
      'Recorda: la ment també s’entrena. Entrena el cervell que decideix.',
    ];
    final now = DateTime.now();
    return tips[now.day % tips.length];
  }
}
