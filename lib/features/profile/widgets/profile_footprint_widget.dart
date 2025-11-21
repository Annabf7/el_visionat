import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/features/visionat/providers/personal_analysis_provider.dart';

/// Widget que mostra l'empremta de l'usuari al Visionat
/// Inclou partits analitzats, apunts creats i tags més utilitzats
class ProfileFootprintWidget extends StatelessWidget {
  const ProfileFootprintWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PersonalAnalysisProvider>(
      builder: (context, analysisProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Títol principal
            Text(
              'La teva Empremta',
              style: const TextStyle(
                fontFamily: 'Geist',
                color: AppTheme.textBlackLow,
                fontWeight: FontWeight.w700,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 32),

            // Taula d'estadístiques amb aparença exacta del prototip
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildFootprintItem(
                    'Partits analitzats',
                    analysisProvider.isLoading
                        ? '...'
                        : analysisProvider.totalMatchesAnalyzed > 0
                        ? analysisProvider.totalMatchesAnalyzed.toString()
                        : '12', // Valor del prototip Figma
                    isFirst: true,
                    itemIndex: 0,
                  ),
                  _buildFootprintItem(
                    'Apunts personals creats',
                    analysisProvider.isLoading
                        ? '...'
                        : analysisProvider.totalPersonalNotes > 0
                        ? analysisProvider.totalPersonalNotes.toString()
                        : '48', // Valor del prototip Figma
                    itemIndex: 1,
                  ),
                  _buildFootprintItem(
                    'Tags més utilitzats',
                    analysisProvider.isLoading
                        ? '...'
                        : _getTopTags(analysisProvider.topTags),
                    isLast: true,
                    itemIndex: 2,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Construeix cada fila de la taula d'estadístiques
  Widget _buildFootprintItem(
    String title,
    String value, {
    bool isFirst = false,
    bool isLast = false,
    required int itemIndex,
  }) {
    // Alternar entre dos tons de gris
    final backgroundColor = itemIndex % 2 == 0
        ? AppTheme.grisPistacho.withValues(alpha: 0.4) // Més fosc
        : AppTheme.grisPistacho.withValues(alpha: 0.2); // Més clar

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        // Només la primera fila té stroke mostassa superior
        border: isFirst
            ? const Border(top: BorderSide(color: AppTheme.mostassa, width: 2))
            : null,
        borderRadius: isFirst
            ? const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              )
            : isLast
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Títol
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppTheme.textBlackLow,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          // Valor
          Expanded(
            flex: 1,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppTheme.textBlackLow,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Formata els tags més utilitzats per mostrar-los
  String _getTopTags(List<String> topTags) {
    if (topTags.isEmpty) {
      return 'FP, 3 seg.,'; // Valor del prototip Figma
    }

    if (topTags.length == 1) {
      return topTags.first;
    }

    if (topTags.length == 2) {
      return '${topTags[0]}, ${topTags[1]}';
    }

    // Mostrem els 3 primers tags
    return '${topTags[0]}, ${topTags[1]}, ${topTags[2]}';
  }
}
