import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

class NeuroTipCard extends StatelessWidget {
  const NeuroTipCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.porpraFosc.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 2, color: AppTheme.mostassa),
              Expanded(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Neuro-tip del dia',
                                style: TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 18,
                                  fontWeight: FontWeight.normal,
                                  color: AppTheme.mostassa,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.psychology_alt,
                              color: AppTheme.mostassa,
                              size: 24,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _getNeuroTip(),
                          style: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.white.withValues(alpha: 0.92),
                            letterSpacing: 0.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
      'Recorda: la ment també s’entrena.\nEntrena el cervell que decideix.',
    ];
    final now = DateTime.now();
    return tips[now.day % tips.length];
  }
}
