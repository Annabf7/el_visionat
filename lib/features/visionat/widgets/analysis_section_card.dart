import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/collective_comment.dart';
import '../models/personal_analysis.dart';
import '../providers/personal_analysis_provider.dart';
import '../widgets/personal_analysis_modal.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

class AnalysisSectionCard extends StatefulWidget {
  final String matchId;
  final List<CollectiveComment> collectiveComments;
  final VoidCallback onViewAllComments;

  const AnalysisSectionCard({
    super.key,
    required this.matchId,
    required this.collectiveComments,
    required this.onViewAllComments,
  });

  @override
  State<AnalysisSectionCard> createState() => _AnalysisSectionCardState();
}

class _AnalysisSectionCardState extends State<AnalysisSectionCard> {
  /// Obre el modal de Personal Analysis
  void _openPersonalAnalysisModal({PersonalAnalysis? existingAnalysis}) {
    showDialog<void>(
      context: context,
      builder: (context) => PersonalAnalysisModal(
        existingAnalysis: existingAnalysis,
        matchId: widget.matchId,
      ),
    );
  }

  /// Obre modal per veure tots els apunts personals
  void _openAllAnalysesModal() {
    final provider = context.read<PersonalAnalysisProvider>();

    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Capçalera
              Row(
                children: [
                  Icon(
                    Icons.list_alt,
                    size: MediaQuery.of(context).size.width < 600 ? 20 : 24,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Els meus apunts personals',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: MediaQuery.of(context).size.width < 600
                            ? 18
                            : 20,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Tancar',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Llista d'apunts
              Expanded(
                child: ListView.separated(
                  itemCount: provider.analysesCount,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final analysis = provider.analyses[index];
                    final isSmallScreen =
                        MediaQuery.of(context).size.width < 600;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: isSmallScreen
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Contingut principal
                                  Text(
                                    analysis.text,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 8),

                                  // Timestamp
                                  Text(
                                    _formatTimestamp(analysis.createdAt),
                                    style: TextStyle(
                                      color: AppTheme.mostassa,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),

                                  // Tags
                                  if (analysis.tags.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: analysis.tags
                                          .take(3)
                                          .map(
                                            (tag) => Chip(
                                              label: Text(
                                                tag.displayName,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                ),
                                              ),
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],

                                  const SizedBox(height: 12),

                                  // Botons d'acció sota el contingut
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Flexible(
                                        child: TextButton.icon(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _openPersonalAnalysisModal(
                                              existingAnalysis: analysis,
                                            );
                                          },
                                          icon: Icon(
                                            Icons.edit,
                                            size: 14,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                          label: const Text(
                                            'Editar',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            minimumSize: Size.zero,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: TextButton.icon(
                                          onPressed: () =>
                                              _confirmDeleteAnalysis(analysis),
                                          icon: Icon(
                                            Icons.delete_outline,
                                            size: 14,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                          label: const Text(
                                            'Eliminar',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            minimumSize: Size.zero,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          : ListTile(
                              title: Text(
                                analysis.text,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatTimestamp(analysis.createdAt),
                                    style: TextStyle(
                                      color: AppTheme.mostassa,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (analysis.tags.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 4,
                                      children: analysis.tags
                                          .take(3)
                                          .map(
                                            (tag) => Chip(
                                              label: Text(
                                                tag.displayName,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                ),
                                              ),
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _openPersonalAnalysisModal(
                                        existingAnalysis: analysis,
                                      );
                                    },
                                    icon: Icon(
                                      Icons.edit,
                                      size: 20,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                    tooltip: 'Editar',
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        _confirmDeleteAnalysis(analysis),
                                    icon: Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                    tooltip: 'Eliminar',
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Botó per afegir nou apunt
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _openPersonalAnalysisModal();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Nou Apunt'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Confirma l'eliminació d'un apunt personal
  Future<void> _confirmDeleteAnalysis(PersonalAnalysis analysis) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar apunt'),
        content: const Text(
          'Segur que vols eliminar aquest apunt personal? Aquesta acció no es pot desfer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel·lar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final provider = context.read<PersonalAnalysisProvider>();
        await provider.deleteAnalysis(analysis.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Apunt eliminat correctament'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error eliminant apunt: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  /// Formata un timestamp per mostrar-lo de forma amigable
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Ara mateix';
    } else if (difference.inHours < 1) {
      return 'Fa ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Fa ${difference.inHours}h';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return 'fa ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'fa ${difference.inHours}h';
    } else {
      return 'fa ${difference.inDays} dies';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        top: 24,
      ), // Separació més marcada del widget superior
      decoration: BoxDecoration(
        // Gradient suau vertical amb tons corporatius
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.porpraFosc.withValues(alpha: 0.05),
            AppTheme.lilaMitja.withValues(alpha: 0.08),
          ],
        ),
        // Borde subtil amb color mostassa corporatiu
        border: Border.all(
          color: AppTheme.mostassa.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(20), // Radi de cantonades més gran
        // Ombra més profunda i difosa
        boxShadow: [
          BoxShadow(
            color: AppTheme.porpraFosc.withValues(alpha: 0.15),
            offset: const Offset(0, 6),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          // Capçalera visual amb barra superior
          border: Border(
            top: BorderSide(
              color: AppTheme.mostassa.withValues(alpha: 0.6),
              width: 6,
            ),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24), // Padding augmentat
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SECCIÓ A: Apunts Personals (nou sistema Sprint 3)
              Consumer<PersonalAnalysisProvider>(
                builder: (context, provider, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Capçalera amb títol i comptador
                      Row(
                        children: [
                          Icon(
                            Icons.note_add,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: MediaQuery.of(context).size.width < 600
                                ? 16
                                : 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Apunts Personals',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontSize:
                                      MediaQuery.of(context).size.width < 600
                                      ? 16
                                      : 18,
                                ),
                          ),
                          const Spacer(),
                          if (provider.hasAnalyses)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.lilaMitja.withValues(
                                  alpha: 0.8,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.lilaMitja),
                              ),
                              child: Text(
                                '${provider.analysesCount}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Estat i contingut
                      if (provider.isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (provider.hasError)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Error: ${provider.errorMessage}',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: provider.refresh,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Tornar a carregar'),
                              ),
                            ],
                          ),
                        )
                      else if (provider.hasAnalyses)
                        Column(
                          children: [
                            // Apunts recents (màxim 3)
                            ...provider
                                .getRecentAnalyses(limit: 3)
                                .map(
                                  (analysis) => Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline
                                            .withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.sticky_note_2,
                                              size: 16,
                                              color: AppTheme.mostassa,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _formatTimestamp(
                                                  analysis.createdAt,
                                                ),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: AppTheme.mostassa,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () =>
                                                  _openPersonalAnalysisModal(
                                                    existingAnalysis: analysis,
                                                  ),
                                              icon: Icon(
                                                Icons.edit,
                                                size: 16,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                              tooltip: 'Editar',
                                              visualDensity:
                                                  VisualDensity.compact,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(
                                                minWidth: 28,
                                                minHeight: 28,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () =>
                                                  _confirmDeleteAnalysis(
                                                    analysis,
                                                  ),
                                              icon: Icon(
                                                Icons.delete_outline,
                                                size: 16,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                              tooltip: 'Eliminar',
                                              visualDensity:
                                                  VisualDensity.compact,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(
                                                minWidth: 28,
                                                minHeight: 28,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          analysis.text,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (analysis.tags.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            children: analysis.tags
                                                .take(3)
                                                .map(
                                                  (tag) => Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primaryContainer,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      tag.displayName,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelSmall
                                                          ?.copyWith(
                                                            color: Theme.of(context)
                                                                .colorScheme
                                                                .onPrimaryContainer,
                                                          ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                          ],
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.note_add_outlined,
                                size: 48,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Encara no tens apunts personals',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Fes clic a "Nou Apunt" per començar a guardar les teves observacions',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Botons d'acció
                      Row(
                        children: [
                          if (provider.analysesCount > 1)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _openAllAnalysesModal(),
                                icon: const Icon(Icons.list, size: 16),
                                label: Text(
                                  provider.analysesCount > 3
                                      ? 'Veure tots (${provider.analysesCount})'
                                      : 'Veure tots',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          if (provider.analysesCount > 1)
                            const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _openPersonalAnalysisModal(),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Nou Apunt'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.white,
                              foregroundColor: AppTheme.porpraFosc,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Divider suau
              Divider(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
                thickness: 1,
              ),

              const SizedBox(height: 24),

              // SECCIÓ B: Anàlisi col·lectiva
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Anàlisi col·lectiva',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Aportacions del grup',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppTheme.white),
                      ),
                    ],
                  ),
                  // Comptador de comentaris
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.lilaMitja.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.lilaMitja),
                    ),
                    child: Text(
                      '${widget.collectiveComments.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Comentaris recents (màxim 3)
              if (widget.collectiveComments.isNotEmpty) ...[
                ...widget.collectiveComments
                    .take(3)
                    .map(
                      (comment) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: comment.anonymous
                                      ? AppTheme.mostassa.withValues(alpha: 1)
                                      : AppTheme.mostassa.withValues(alpha: 1),
                                  child: Icon(
                                    comment.anonymous
                                        ? Icons.person_outline
                                        : Icons.person,
                                    size: 14,
                                    color: comment.anonymous
                                        ? AppTheme.porpraFosc
                                        : AppTheme.porpraFosc,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    comment.displayName,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                        ),
                                  ),
                                ),
                                Text(
                                  _formatTimeAgo(comment.createdAt),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              comment.text,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Encara no hi ha comentaris col·lectius',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Botó "Veure comentaris"
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: widget.onViewAllComments,
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Veure comentaris'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
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
}
