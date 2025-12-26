import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'package:el_visionat/features/visionat/providers/personal_analysis_provider.dart';
import 'package:el_visionat/features/visionat/models/personal_analysis.dart';
import 'package:el_visionat/features/visionat/widgets/personal_analysis_modal.dart';

/// Pantalla completa per visualitzar tots els apunts personals amb filtres i cerca
class AllPersonalNotesScreen extends StatefulWidget {
  const AllPersonalNotesScreen({super.key});

  @override
  State<AllPersonalNotesScreen> createState() => _AllPersonalNotesScreenState();
}

class _AllPersonalNotesScreenState extends State<AllPersonalNotesScreen> {
  // Controladors i estat de filtres
  final TextEditingController _searchController = TextEditingController();
  AnalysisSource? _selectedSource;
  AnalysisCategory? _selectedCategory;
  String _sortBy = 'date_desc'; // 'date_desc', 'date_asc', 'article'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Els meus apunts personals',
          style: TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w700,
            color: AppTheme.textBlackLow,
          ),
        ),
        backgroundColor: Colors.grey[50],
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textBlackLow),
        actions: [
          // Botó per crear nou apunt
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Crear nou apunt',
            onPressed: () => _handleCreateNote(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/backgrounds/notes_background.png'),
            repeat: ImageRepeat.repeat,
            opacity: 0.4, // Ajustable segons la intensitat de la imatge generada
          ),
        ),
        child: Column(
          children: [
            // Barra de cerca i filtres
            _buildSearchAndFilters(),

            const SizedBox(height: 16),

            // Llista d'apunts
            Expanded(
              child: _buildNotesList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Barra de cerca i filtres
  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;

          if (isDesktop) {
            // Layout desktop: Cerca i filtres en la mateixa fila
            return Row(
              children: [
                // Camp de cerca (ocupa espai disponible)
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cerca per text, article o partit...',
                      hintStyle: TextStyle(
                        color: AppTheme.textBlackLow.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 20,
                        color: AppTheme.textBlackLow.withValues(alpha: 0.6),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.grisPistacho.withValues(alpha: 0.1),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: AppTheme.grisPistacho.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppTheme.porpraFosc,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      isDense: true,
                    ),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: AppTheme.textBlackLow,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),

                const SizedBox(width: 12),

                // Filtres (alineats a la dreta)
                _buildFilterChip(
                  label: _selectedSource?.displayName ?? 'Tots els orígens',
                  icon: _selectedSource?.icon ?? Icons.filter_list,
                  onTap: () => _showSourceFilterDialog(),
                  isActive: _selectedSource != null,
                ),
                const SizedBox(width: 8),

                _buildFilterChip(
                  label: _selectedCategory?.displayName ?? 'Totes les categories',
                  icon: _selectedCategory?.icon ?? Icons.category,
                  onTap: () => _showCategoryFilterDialog(),
                  isActive: _selectedCategory != null,
                ),
                const SizedBox(width: 8),

                _buildFilterChip(
                  label: _getSortLabel(),
                  icon: Icons.sort,
                  onTap: () => _showSortDialog(),
                  isActive: _sortBy != 'date_desc',
                ),
              ],
            );
          } else {
            // Layout mòbil: Cerca a dalt, filtres a baix
            return Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cerca per text, article o partit...',
                    hintStyle: TextStyle(
                      color: AppTheme.textBlackLow.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      size: 20,
                      color: AppTheme.textBlackLow.withValues(alpha: 0.6),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.grisPistacho.withValues(alpha: 0.1),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppTheme.grisPistacho.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppTheme.porpraFosc,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    isDense: true,
                  ),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppTheme.textBlackLow,
                  ),
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 10),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: _selectedSource?.displayName ?? 'Tots els orígens',
                        icon: _selectedSource?.icon ?? Icons.filter_list,
                        onTap: () => _showSourceFilterDialog(),
                        isActive: _selectedSource != null,
                      ),
                      const SizedBox(width: 8),

                      _buildFilterChip(
                        label: _selectedCategory?.displayName ?? 'Totes les categories',
                        icon: _selectedCategory?.icon ?? Icons.category,
                        onTap: () => _showCategoryFilterDialog(),
                        isActive: _selectedCategory != null,
                      ),
                      const SizedBox(width: 8),

                      _buildFilterChip(
                        label: _getSortLabel(),
                        icon: Icons.sort,
                        onTap: () => _showSortDialog(),
                        isActive: _sortBy != 'date_desc',
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  /// Chip de filtre
  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.porpraFosc.withValues(alpha: 0.15)
              : AppTheme.grisPistacho.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppTheme.porpraFosc : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppTheme.porpraFosc : AppTheme.textBlackLow,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isActive ? AppTheme.porpraFosc : AppTheme.textBlackLow,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Llista d'apunts filtrats
  Widget _buildNotesList() {
    return Consumer<PersonalAnalysisProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Aplicar filtres i ordenació
        List<PersonalAnalysis> filteredNotes = _applyFilters(provider.analyses);

        if (filteredNotes.isEmpty) {
          return _buildEmptyState();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 800;

            Widget listView = ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filteredNotes.length,
              itemBuilder: (context, index) {
                return _buildNoteCard(filteredNotes[index], index);
              },
            );

            // Desktop: Limitar amplada i centrar
            if (isDesktop) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: listView,
                ),
              );
            }

            // Mòbil: Amplada completa
            return listView;
          },
        );
      },
    );
  }

  /// Targeta d'apunt individual
  Widget _buildNoteCard(PersonalAnalysis analysis, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.grisPistacho.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleEdit(analysis),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Capçalera: Origen + Data
                Row(
                  children: [
                    // Origen
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: _getSourceColor(analysis.source).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: _getSourceColor(analysis.source).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            analysis.source.icon,
                            size: 13,
                            color: _getSourceColor(analysis.source).withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            analysis.matchName ?? analysis.source.displayName,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getSourceColor(analysis.source).withValues(alpha: 0.95),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Data
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 13,
                          color: AppTheme.textBlackLow.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          analysis.formattedDate,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textBlackLow.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Text de l'apunt
                Text(
                  analysis.text,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textBlackLow,
                    height: 1.45,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 10),

                // Article del reglament + Tags
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    // Article
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.purple.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.menu_book,
                            size: 11,
                            color: Colors.purple.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            analysis.ruleArticle.isNotEmpty
                                ? analysis.ruleArticle
                                : 'Sense article',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.purple.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tags (màxim 2 visibles per ser més compacte)
                    ...analysis.tags.take(2).map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: AppTheme.grisPistacho.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag.displayName,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textBlackLow.withValues(alpha: 0.85),
                            ),
                          ),
                        )),
                    if (analysis.tags.length > 2)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: AppTheme.porpraFosc.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '+${analysis.tags.length - 2}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.porpraFosc.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // Accions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _handleEdit(analysis),
                      icon: const Icon(Icons.edit_outlined, size: 15),
                      label: const Text('Editar'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange.shade700,
                        textStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: () => _handleDelete(analysis),
                      icon: const Icon(Icons.delete_outline, size: 15),
                      label: const Text('Eliminar'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red.shade600,
                        textStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Estat buit
  Widget _buildEmptyState() {
    final hasFilters = _selectedSource != null ||
        _selectedCategory != null ||
        _searchController.text.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters ? Icons.search_off : Icons.note_add_outlined,
              size: 64,
              color: AppTheme.textBlackLow.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters
                  ? 'No s\'han trobat apunts amb aquests filtres'
                  : 'Encara no tens cap apunt personal',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textBlackLow.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Prova a canviar els criteris de cerca'
                  : 'Comença creant el teu primer apunt',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppTheme.textBlackLow.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            if (hasFilters) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _selectedSource = null;
                    _selectedCategory = null;
                  });
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Esborrar filtres'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.porpraFosc,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Aplicar filtres i ordenació
  List<PersonalAnalysis> _applyFilters(List<PersonalAnalysis> notes) {
    List<PersonalAnalysis> filtered = List.from(notes);

    // Filtre de cerca
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((note) {
        return note.text.toLowerCase().contains(query) ||
            note.ruleArticle.toLowerCase().contains(query) ||
            (note.matchName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Filtre per origen
    if (_selectedSource != null) {
      filtered = filtered.where((note) => note.source == _selectedSource).toList();
    }

    // Filtre per categoria
    if (_selectedCategory != null) {
      filtered = filtered.where((note) {
        return note.tags.any((tag) => tag.category == _selectedCategory);
      }).toList();
    }

    // Ordenació
    switch (_sortBy) {
      case 'date_asc':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'date_desc':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'article':
        filtered.sort((a, b) => a.ruleArticle.compareTo(b.ruleArticle));
        break;
    }

    return filtered;
  }

  /// Diàleg de filtre per origen
  Future<void> _showSourceFilterDialog() async {
    final selected = await showDialog<AnalysisSource?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar per origen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('Tots els orígens'),
              onTap: () => Navigator.pop(context, null),
            ),
            ...AnalysisSource.values.map((source) => ListTile(
                  leading: Icon(source.icon),
                  title: Text(source.displayName),
                  onTap: () => Navigator.pop(context, source),
                )),
          ],
        ),
      ),
    );

    if (selected != null || selected == null && _selectedSource != null) {
      setState(() {
        _selectedSource = selected;
      });
    }
  }

  /// Diàleg de filtre per categoria
  Future<void> _showCategoryFilterDialog() async {
    final selected = await showDialog<AnalysisCategory?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar per categoria'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.clear_all),
                title: const Text('Totes les categories'),
                onTap: () => Navigator.pop(context, null),
              ),
              ...AnalysisCategory.values.map((category) => ListTile(
                    leading: Icon(category.icon),
                    title: Text(category.displayName),
                    onTap: () => Navigator.pop(context, category),
                  )),
            ],
          ),
        ),
      ),
    );

    if (selected != null || selected == null && _selectedCategory != null) {
      setState(() {
        _selectedCategory = selected;
      });
    }
  }

  /// Diàleg d'ordenació
  Future<void> _showSortDialog() async {
    final sortOptions = [
      ('date_desc', 'Més recents primer', Icons.arrow_downward),
      ('date_asc', 'Més antics primer', Icons.arrow_upward),
      ('article', 'Article del reglament', Icons.menu_book),
    ];

    final selected = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ordenar per'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: sortOptions.map((option) {
            final isSelected = _sortBy == option.$1;
            return ListTile(
              leading: Icon(
                option.$3,
                color: isSelected ? Theme.of(context).colorScheme.primary : null,
              ),
              title: Text(
                option.$2,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Theme.of(context).colorScheme.primary : null,
                ),
              ),
              trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () => Navigator.pop(context, option.$1),
            );
          }).toList(),
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _sortBy = selected;
      });
    }
  }

  /// Obtenir label d'ordenació
  String _getSortLabel() {
    switch (_sortBy) {
      case 'date_asc':
        return 'Antics primer';
      case 'date_desc':
        return 'Recents primer';
      case 'article':
        return 'Per article';
      default:
        return 'Ordenar';
    }
  }

  /// Crear nou apunt
  void _handleCreateNote(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PersonalAnalysisModal(
        matchId: 'general',
      ),
    );
  }

  /// Editar apunt
  void _handleEdit(PersonalAnalysis analysis) {
    showDialog(
      context: context,
      builder: (context) => PersonalAnalysisModal(
        existingAnalysis: analysis,
        matchId: analysis.matchId,
      ),
    );
  }

  /// Eliminar apunt
  Future<void> _handleDelete(PersonalAnalysis analysis) async {
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
              content: Text('Error eliminant apunt: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Obtenir color segons origen
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
