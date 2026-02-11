import 'package:flutter/material.dart';
import '../models/neurovisionat_models.dart';
import 'neuro_exercise_modal.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

/// Bloc principal: 4 pilars amb ExpansionTiles i cards
class NeuroPillarsSection extends StatelessWidget {
  final List<NeuroSection> sections;
  const NeuroPillarsSection({required this.sections, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: sections
            .map((section) => _NeuroPillarTile(section: section))
            .toList(),
      ),
    );
  }
}

class _NeuroPillarTile extends StatefulWidget {
  final NeuroSection section;
  const _NeuroPillarTile({required this.section});

  @override
  State<_NeuroPillarTile> createState() => _NeuroPillarTileState();
}

class _NeuroPillarTileState extends State<_NeuroPillarTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.section;
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Card(
        elevation: _expanded ? 8 : 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        color: AppTheme.porpraFosc,
        child: ExpansionTile(
          onExpansionChanged: (v) => setState(() => _expanded = v),
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          childrenPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          title: Text(
            s.titol,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.white,
            ),
          ),
          subtitle: Text(
            s.subtitol,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 15,
              color: AppTheme.grisPistacho,
            ),
          ),
          children: [
            ...s.paragrafs.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  p,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 15,
                    color: AppTheme.white.withValues(alpha: 0.92),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _PrincipiClauCard(principi: s.principiClau),
            if (s.biaixos.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Biaixos / Errors típics:',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontWeight: FontWeight.w600,
                        color: AppTheme.grisPistacho,
                      ),
                    ),
                    ...s.biaixos.map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Text(
                          '• $b',
                          style: TextStyle(
                            fontFamily: 'Geist',
                            color: AppTheme.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Text(
              'Exercicis per entrenar-ho:',
              style: TextStyle(
                fontFamily: 'Geist',
                fontWeight: FontWeight.w600,
                color: AppTheme.grisPistacho,
              ),
            ),
            ...s.exercicis.map(
              (e) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.white,
                    side: BorderSide(color: AppTheme.grisPistacho),
                  ),
                  onPressed: () {
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
                  child: Text(e.titol),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _PrincipiClauCard extends StatelessWidget {
  final String principi;
  const _PrincipiClauCard({required this.principi});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.grisPistacho,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(
          principi,
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.porpraFosc,
          ),
        ),
      ),
    );
  }
}
