import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/features/visionat/providers/personal_analysis_provider.dart';
import 'package:el_visionat/features/visionat/models/personal_analysis.dart';
import 'package:el_visionat/features/visionat/widgets/personal_analysis_modal.dart';
import 'package:el_visionat/features/profile/screens/all_personal_notes_screen.dart';

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

            // Botons "Crear apunt" i "Mostrar tot"
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Botó "Crear apunt" - Estil discret
                Builder(
                  builder: (context) => TextButton.icon(
                    onPressed: () => _handleCreateNote(context),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Crear apunt'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textBlackLow,
                      textStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Botó "Mostrar tot" - Estil discret
                Builder(
                  builder: (context) => TextButton.icon(
                    onPressed: () => _handleShowAll(context),
                    icon: const Icon(Icons.list_alt, size: 18),
                    label: const Text('Mostrar tot'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textBlackLow,
                      textStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Construeix cada fila de la taula d'apunts personals
  Widget _buildPersonalNoteItem(
    PersonalAnalysis? analysis, {
    required int itemIndex,
    bool isFirst = false,
    bool isLast = false,
  }) {
    // Alternar entre dos tons de gris (mateix estil que l'empremta)
    final backgroundColor = itemIndex % 2 == 0
        ? AppTheme.grisPistacho.withValues(alpha: 0.4) // Més fosc
        : AppTheme.grisPistacho.withValues(alpha: 0.2); // Més clar

    // Si no hi ha apunt, mostrar fila buida
    if (analysis == null) {
      return Container(
        decoration: BoxDecoration(
          color: backgroundColor,
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
        child: const Center(
          child: Text(
            'Encara no tens apunts personals',
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppTheme.textBlackLow,
              fontWeight: FontWeight.w400,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
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
          // Secció Origen (Partit/Test)
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _getSourceColor(analysis.source).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    analysis.source.icon,
                    color: _getSourceColor(analysis.source),
                    size: 14,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    analysis.matchName ?? analysis.source.displayName,
                    style: const TextStyle(
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

          // Secció Situació (text de l'apunt)
          Expanded(
            flex: 3,
            child: Text(
              analysis.text,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppTheme.textBlackLow,
                fontWeight: FontWeight.w400,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 12),

          // Secció Reglament
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.menu_book,
                    color: Colors.purple,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    analysis.ruleArticle.isNotEmpty
                        ? analysis.ruleArticle
                        : '-',
                    style: const TextStyle(
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
                Expanded(
                  child: Text(
                    analysis.formattedDate,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppTheme.textBlackLow,
                      fontWeight: FontWeight.w400,
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
            child: Builder(
              builder: (context) => InkWell(
                onTap: () => _handleEdit(analysis, context),
                borderRadius: BorderRadius.circular(6),
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
            ),
          ),
          const SizedBox(width: 12),

          // Secció Eliminar
          Expanded(
            flex: 1,
            child: Builder(
              builder: (context) => InkWell(
                onTap: () => _handleDelete(analysis, context),
                borderRadius: BorderRadius.circular(6),
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
            ),
          ),
        ],
      ),
    );
  }

  void _handleEdit(PersonalAnalysis analysis, BuildContext context) {
    debugPrint('✏️ Editant apunt: ${analysis.id}');

    showDialog(
      context: context,
      builder: (context) => PersonalAnalysisModal(
        existingAnalysis: analysis,
        matchId: analysis.matchId,
      ),
    );
  }

  Future<void> _handleDelete(PersonalAnalysis analysis, BuildContext context) async {
    debugPrint('🗑️ Eliminant apunt: ${analysis.id}');

    // Mostrar diàleg de confirmació
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Eliminar apunt'),
          ],
        ),
        content: const Text(
          'Estàs segur que vols eliminar aquest apunt personal? '
          'Aquesta acció no es pot desfer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel·lar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final provider = context.read<PersonalAnalysisProvider>();
        await provider.deleteAnalysis(analysis.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Apunt eliminat correctament'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error eliminant apunt: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _handleCreateNote(BuildContext context) {
    debugPrint('➕ Creant nou apunt personal');

    // Obre el modal de creació sense matchId predefinit
    // L'usuari podrà crear apunts generals (formació, tests, etc.)
    showDialog(
      context: context,
      builder: (context) => PersonalAnalysisModal(
        matchId: 'general', // ID genèric per apunts no vinculats a partit específic
      ),
    );
  }

  void _handleShowAll(BuildContext context) {
    debugPrint('📋 Navegant a la vista completa d\'apunts personals');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AllPersonalNotesScreen(),
      ),
    );
  }

  /// Retorna el color segons l'origen de l'apunt
  Color _getSourceColor(AnalysisSource source) {
    switch (source) {
      case AnalysisSource.match:
        return Colors.orange;
      case AnalysisSource.test:
        return Colors.blue;
      case AnalysisSource.training:
        return Colors.green;
    }
  }
}
