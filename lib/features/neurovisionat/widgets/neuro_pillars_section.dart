import 'package:flutter/material.dart';
import '../models/neurovisionat_models.dart';
import 'neuro_exercise_modal.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

/// Icones representatives de cada pilar
const _pillarIcons = [
  Icons.psychology_outlined,
  Icons.self_improvement,
  Icons.center_focus_strong_outlined,
  Icons.record_voice_over_outlined,
];

/// Bloc principal: 4 pilars amb cards refinades
class NeuroPillarsSection extends StatelessWidget {
  final List<NeuroSection> sections;
  const NeuroPillarsSection({required this.sections, super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

        if (isWide) {
          // Desktop: grid 2x2 amb espaiat uniforme (top = entre files)
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 4),
            itemCount: sections.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              mainAxisExtent: 580,
            ),
            itemBuilder: (context, index) {
              return NeuroPillarTile(
                section: sections[index],
                index: index,
              );
            },
          );
        }

        // Mòbil
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: List.generate(
              sections.length,
              (i) => Padding(
                padding:
                    EdgeInsets.only(bottom: i < sections.length - 1 ? 16 : 0),
                child: NeuroPillarTile(section: sections[i], index: i),
              ),
            ),
          ),
        );
      },
    );
  }
}

class NeuroPillarTile extends StatelessWidget {
  final NeuroSection section;
  final int index;
  const NeuroPillarTile({
    required this.section,
    required this.index,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final s = section;
    final icon = index < _pillarIcons.length
        ? _pillarIcons[index]
        : Icons.auto_awesome;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.porpraFosc,
            AppTheme.porpraFosc.withValues(alpha: 0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.porpraFosc.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Cercle decoratiu de fons (subtil)
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.mostassa.withValues(alpha: 0.06),
                ),
              ),
            ),
            // Contingut principal
            Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Capçalera: número + icona
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.mostassa.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.mostassa,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          icon,
                          color: AppTheme.mostassa.withValues(alpha: 0.7),
                          size: 22,
                        ),
                        const Spacer(),
                        // Badge "Pilar"
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.mostassa.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'PILAR ${index + 1}',
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: AppTheme.mostassa.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Títol
                    Text(
                      s.titol,
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Subtítol
                    Text(
                      s.subtitol,
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 13,
                        color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Separador subtil
                    Container(
                      width: 40,
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppTheme.mostassa.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Paràgrafs
                    ...s.paragrafs.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          p,
                          style: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 14,
                            color: AppTheme.white.withValues(alpha: 0.85),
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Principi clau
                    _PrincipiClauCard(principi: s.principiClau),
                    // Biaixos
                    if (s.biaixos.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppTheme.mostassa.withValues(alpha: 0.6),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Biaixos / Errors típics',
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.grisPistacho.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: s.biaixos.map(
                          (b) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.mostassa.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.mostassa.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Text(
                              b,
                              style: TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 12,
                                color: AppTheme.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ).toList(),
                      ),
                    ],
                    // Exercicis
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(
                          Icons.fitness_center_rounded,
                          color: AppTheme.mostassa.withValues(alpha: 0.6),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Exercicis per entrenar-ho',
                          style: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.grisPistacho.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...s.exercicis.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => DraggableScrollableSheet(
                                  initialChildSize: 0.45,
                                  minChildSize: 0.3,
                                  maxChildSize: 0.85,
                                  expand: false,
                                  builder: (context, scrollController) =>
                                      SingleChildScrollView(
                                        controller: scrollController,
                                        child: NeuroExerciseModal(exercise: e),
                                      ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppTheme.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppTheme.mostassa.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.play_arrow_rounded,
                                      color: AppTheme.mostassa,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      e.titol,
                                      style: TextStyle(
                                        fontFamily: 'Geist',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppTheme.grisPistacho.withValues(alpha: 0.4),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card per al principi clau — estil cita amb barra lateral
class _PrincipiClauCard extends StatelessWidget {
  final String principi;
  const _PrincipiClauCard({required this.principi});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppTheme.mostassa.withValues(alpha: 0.08),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Barra lateral mostassa
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: AppTheme.mostassa,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            // Contingut
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRINCIPI CLAU',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppTheme.mostassa.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '«$principi»',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.mostassa,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
