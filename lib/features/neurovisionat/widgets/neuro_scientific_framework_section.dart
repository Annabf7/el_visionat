import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

class NeuroScientificFrameworkSection extends StatelessWidget {
  const NeuroScientificFrameworkSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.grisBody,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppTheme.mostassa, width: 1.0),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Marc científic i referències',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.grisPistacho,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'La secció NeuroVisionat es basa en principis de neurociència aplicats a l’arbitratge esportiu, incloent regulació emocional, presa de decisions sota pressió, i co-regulació d’equip. Les fonts principals inclouen:',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 15,
                color: AppTheme.grisPistacho,
              ),
            ),
            const SizedBox(height: 10),
            _ReferenceItem(
              title: 'Flora Davis – La comunicación no verbal',
              description:
                  'Estudi del llenguatge corporal: gestos, postura i com comuniquem sense paraules.',
            ),
            _ReferenceItem(
              title: 'Daniel Kahneman – Thinking, Fast and Slow',
              description: 'Model de presa de decisions i biaixos cognitius.',
            ),
            _ReferenceItem(
              title: 'Joseph LeDoux – The Emotional Brain',
              description: 'Regulació de l’amígdala i resposta emocional.',
            ),
            _ReferenceItem(
              title: 'Andrew Huberman – Huberman Lab Podcast',
              description:
                  'Neurociència aplicada a l’esport i regulació del focus.',
            ),
            _ReferenceItem(
              title: 'James Gross – Emotion Regulation',
              description: 'Estratègies de regulació emocional.',
            ),
            _ReferenceItem(
              title: 'NeuroLeadership Institute',
              description:
                  'Aplicacions de neurociència en lideratge i presa de decisions.',
            ),
            const SizedBox(height: 14),
            Text(
              'Per a més informació, consulta els recursos recomanats o contacta amb el coordinador neuro-arbitral.',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 14,
                color: AppTheme.grisPistacho.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferenceItem extends StatelessWidget {
  final String title;
  final String description;
  const _ReferenceItem({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.bookmark, color: AppTheme.mostassa, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.grisPistacho,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 14,
                    color: AppTheme.grisPistacho.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
