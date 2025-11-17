import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/personal_analysis.dart';
import '../providers/personal_analysis_provider.dart';
import '../widgets/personal_analysis_modal.dart';

/// Widget per mostrar els apunts personals al perfil de l'usuari
///
/// Funcionalitats:
/// - Llistat complet dels apunts personals de l'usuari
/// - Organització per dates i categories
/// - Estadístiques d'ús de tags
/// - Cerca i filtrat d'apunts
/// - Edició i eliminació d'apunts existents
class UserProfilePersonalNotesWidget extends StatefulWidget {
  const UserProfilePersonalNotesWidget({super.key});

  @override
  State<UserProfilePersonalNotesWidget> createState() =>
      _UserProfilePersonalNotesWidgetState();
}

class _UserProfilePersonalNotesWidgetState
    extends State<UserProfilePersonalNotesWidget> {
  String _searchQuery = '';
  AnalysisCategory? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<PersonalAnalysisProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Capçalera amb estadístiques
            _buildHeader(provider, theme),

            const SizedBox(height: 24),

            // Controls de cerca i filtratge
            _buildControls(theme),

            const SizedBox(height: 16),

            // Contingut principal
            Expanded(child: _buildContent(provider, theme)),
          ],
        );
      },
    );
  }

  Widget _buildHeader(PersonalAnalysisProvider provider, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  size: 28,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Els meus apunts personals',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (provider.hasError)
              _buildErrorState(provider, theme)
            else
              _buildStatsRow(provider, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(PersonalAnalysisProvider provider, ThemeData theme) {
    return Column(
      children: [
        Text(
          'Error carregant apunts: ${provider.errorMessage}',
          style: TextStyle(color: theme.colorScheme.error),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: provider.refresh,
          icon: const Icon(Icons.refresh),
          label: const Text('Tornar a intentar'),
        ),
      ],
    );
  }

  Widget _buildStatsRow(PersonalAnalysisProvider provider, ThemeData theme) {
    final totalAnalyses = provider.analysesCount;
    final categoriesUsed = _getCategoriesUsed(provider.analyses);
    final tagsUsed = _getUniqueTagsUsed(provider.analyses);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 400;

        if (isNarrow) {
          // Layout vertical per pantalles molt estretes
          return Column(
            children: [
              _buildStatCard(
                'Total apunts',
                totalAnalyses.toString(),
                Icons.notes,
                theme,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Categories',
                      categoriesUsed.toString(),
                      Icons.category,
                      theme,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Tags únics',
                      tagsUsed.toString(),
                      Icons.local_offer,
                      theme,
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        // Layout horitzontal normal
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total apunts',
                totalAnalyses.toString(),
                Icons.notes,
                theme,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Categories',
                categoriesUsed.toString(),
                Icons.category,
                theme,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Tags únics',
                tagsUsed.toString(),
                Icons.local_offer,
                theme,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: theme.colorScheme.onPrimaryContainer, size: 20),
          const SizedBox(height: 6),
          FittedBox(
            child: Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildControls(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        if (isNarrow) {
          // Layout vertical per pantalles estretes
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cerca
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Cercar apunts',
                  hintText: 'Text, tags, etc.',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),

              const SizedBox(height: 12),

              // Fila amb filtre i botó
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<AnalysisCategory?>(
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _selectedCategory,
                      items: [
                        const DropdownMenuItem<AnalysisCategory?>(
                          value: null,
                          child: Text('Totes'),
                        ),
                        ...AnalysisCategory.values.map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(
                              category.displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (category) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Botó per afegir nou apunt
                  FilledButton.icon(
                    onPressed: () => _openNewAnalysisModal(),
                    icon: const Icon(Icons.add),
                    label: const Text('Nou'),
                  ),
                ],
              ),
            ],
          );
        }

        // Layout horitzontal per pantalles amples
        return Row(
          children: [
            // Cerca
            Expanded(
              flex: 2,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Cercar apunts',
                  hintText: 'Text, tags, etc.',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            const SizedBox(width: 12),

            // Filtre per categoria
            Expanded(
              child: DropdownButtonFormField<AnalysisCategory?>(
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(),
                ),
                initialValue: _selectedCategory,
                items: [
                  const DropdownMenuItem<AnalysisCategory?>(
                    value: null,
                    child: Text('Totes'),
                  ),
                  ...AnalysisCategory.values.map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(
                        category.displayName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (category) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
              ),
            ),

            const SizedBox(width: 12),

            // Botó per afegir nou apunt
            FilledButton.icon(
              onPressed: () => _openNewAnalysisModal(),
              icon: const Icon(Icons.add),
              label: const Text('Nou'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(PersonalAnalysisProvider provider, ThemeData theme) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Error carregant els apunts',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage ?? 'Error desconegut',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: provider.refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Tornar a carregar'),
            ),
          ],
        ),
      );
    }

    if (!provider.hasAnalyses) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_add_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Encara no tens apunts personals',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Comença a afegir les teves observacions durant els partits',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _openNewAnalysisModal(),
              icon: const Icon(Icons.add),
              label: const Text('Crear primer apunt'),
            ),
          ],
        ),
      );
    }

    // Filtrar apunts
    final filteredAnalyses = _filterAnalyses(provider.analyses);

    if (filteredAnalyses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Cap apunt coincideix amb els filtres',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Prova a canviar la cerca o els filtres',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredAnalyses.length,
      itemBuilder: (context, index) {
        final analysis = filteredAnalyses[index];
        return _buildAnalysisCard(analysis, theme);
      },
    );
  }

  Widget _buildAnalysisCard(PersonalAnalysis analysis, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Capçalera amb timestamp i accions
            Row(
              children: [
                Text(
                  _formatDate(analysis.createdAt),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _editAnalysis(analysis),
                  icon: const Icon(Icons.edit, size: 20),
                  tooltip: 'Editar',
                ),
                IconButton(
                  onPressed: () => _deleteAnalysis(analysis),
                  icon: const Icon(Icons.delete, size: 20),
                  tooltip: 'Eliminar',
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Text principal
            Text(analysis.text, style: theme.textTheme.bodyLarge),

            const SizedBox(height: 12),

            // Tags
            if (analysis.tags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: analysis.tags
                    .map(
                      (tag) => Chip(
                        label: Text(
                          tag.displayName,
                          overflow: TextOverflow.ellipsis,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: theme.colorScheme.secondaryContainer,
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 8),
            ],

            // Informació adicional
            if (analysis.isEdited)
              Text(
                'Editat',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<PersonalAnalysis> _filterAnalyses(List<PersonalAnalysis> analyses) {
    var filtered = analyses;

    // Filtrar per cerca
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (analysis) =>
                analysis.text.toLowerCase().contains(query) ||
                analysis.tags.any(
                  (tag) => tag.displayName.toLowerCase().contains(query),
                ),
          )
          .toList();
    }

    // Filtrar per categoria
    if (_selectedCategory != null) {
      filtered = filtered
          .where(
            (analysis) =>
                analysis.tags.any((tag) => tag.category == _selectedCategory),
          )
          .toList();
    }

    return filtered;
  }

  int _getCategoriesUsed(List<PersonalAnalysis> analyses) {
    final categories = <AnalysisCategory>{};
    for (final analysis in analyses) {
      for (final tag in analysis.tags) {
        categories.add(tag.category);
      }
    }
    return categories.length;
  }

  int _getUniqueTagsUsed(List<PersonalAnalysis> analyses) {
    final tags = <AnalysisTag>{};
    for (final analysis in analyses) {
      tags.addAll(analysis.tags);
    }
    return tags.length;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Avui ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ahir ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final weekdays = ['Dl', 'Dt', 'Dc', 'Dj', 'Dv', 'Ds', 'Dg'];
      return '${weekdays[date.weekday - 1]} ${date.day}/${date.month}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _openNewAnalysisModal() {
    showDialog<void>(
      context: context,
      builder: (context) => const PersonalAnalysisModal(
        matchId: 'profile_general', // Apunt general del perfil
      ),
    );
  }

  void _editAnalysis(PersonalAnalysis analysis) {
    showDialog<void>(
      context: context,
      builder: (context) => PersonalAnalysisModal(
        existingAnalysis: analysis,
        matchId: analysis.matchId,
      ),
    );
  }

  Future<void> _deleteAnalysis(PersonalAnalysis analysis) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar apunt'),
        content: Text(
          'Estàs segur que vols eliminar aquest apunt?\n\n"${analysis.text}"',
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
      final provider = context.read<PersonalAnalysisProvider>();
      await provider.deleteAnalysis(analysis.id);
    }
  }
}
