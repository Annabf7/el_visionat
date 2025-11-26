import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/features/visionat/providers/personal_analysis_provider.dart';

/// Widget que mostra la taula d'apunts personals amb estil coherent
/// Segueix l'aparença de les captures del prototip Figma
class PersonalNotesTableWidget extends StatelessWidget {
  const PersonalNotesTableWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PersonalAnalysisProvider>(
      builder: (context, analysisProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Títol de la secció
            const Text(
              'Apunts personals',
              style: TextStyle(
                fontFamily: 'Geist',
                color: AppTheme.textBlackLow,
                fontWeight: FontWeight.w700,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 24),

            // Taula d'apunts: responsiva, scroll només en mòbil
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 700;
                final tableContent = Column(
                  children: [
                    // Mostrar màxim 3 apunts o apunts de mostra
                    ...List.generate(
                      3, // Sempre mostrar 3 files
                      (index) => _buildPersonalNoteItem(
                        analysisProvider.analyses.isNotEmpty &&
                                index < analysisProvider.analyses.length
                            ? analysisProvider.analyses[index]
                            : null,
                        itemIndex: index,
                        isFirst: index == 0,
                        isLast: index == 2,
                      ),
                    ),
                  ],
                );
                if (isMobile) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: IntrinsicWidth(child: tableContent),
                  );
                } else {
                  return SizedBox(width: double.infinity, child: tableContent);
                }
              },
            ),
            const SizedBox(height: 20),

            // Botó "Mostrar tot" amb estil del prototip
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.porpraFosc,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      debugPrint('📋 Mostrar tots els apunts personals');
                      // TODO: Navegar a la vista completa d'apunts
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Text(
                        'Mostrar tot',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: AppTheme.mostassa,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Construeix cada fila de la taula d'apunts personals
  Widget _buildPersonalNoteItem(
    dynamic analysis, {
    required int itemIndex,
    bool isFirst = false,
    bool isLast = false,
  }) {
    // Alternar entre dos tons de gris (mateix estil que l'empremta)
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Secció Partit
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.sports_basketball,
                    color: Colors.orange,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Partit',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppTheme.textBlackLow,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Secció Data
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.access_time,
                    color: Colors.grey,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Data',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppTheme.textBlackLow,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Secció Tags
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.mostassa.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.local_offer,
                    color: AppTheme.mostassa,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Tags',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppTheme.textBlackLow,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Secció Editar
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.yellow.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.edit, color: Colors.orange, size: 14),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Editar',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppTheme.textBlackLow,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Secció Eliminar
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.delete, color: Colors.red, size: 14),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Eliminar',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppTheme.textBlackLow,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
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
