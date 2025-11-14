import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import 'tag_definitions.dart';

class TagSelector extends StatefulWidget {
  final Function(String) onTagSelected;
  final String? initialTag;

  const TagSelector({super.key, required this.onTagSelected, this.initialTag});

  @override
  State<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> {
  final _searchController = TextEditingController();
  List<String> _filteredTags = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filteredTags = TagDefinitions.getAllTags();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filteredTags = TagDefinitions.searchTags(query);
    });
  }

  void _selectTag(String tag) {
    widget.onTagSelected(tag);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWideScreen = MediaQuery.of(context).size.width >= 900;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.8,
          maxWidth: isWideScreen ? 600 : double.infinity,
        ),
        margin: EdgeInsets.symmetric(
          horizontal: isWideScreen ? 0 : 16,
          vertical: 20,
        ),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.porpraFosc.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.lilaMitja,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.label, color: AppTheme.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Selecciona tipus de jugada',
                      style: textTheme.titleLarge?.copyWith(
                        color: AppTheme.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: AppTheme.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Barra de cerca
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Cerca per nom de la infracció...',
                  hintStyle: TextStyle(
                    color: AppTheme.grisBody.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(Icons.search, color: AppTheme.lilaMitja),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                          icon: Icon(Icons.clear, color: AppTheme.grisBody),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.lilaMitja),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.lilaMitja, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: TextStyle(color: AppTheme.porpraFosc, fontSize: 14),
              ),
            ),

            // Contingut principal
            Expanded(
              child: _searchQuery.isNotEmpty
                  ? _buildSearchResults()
                  : _buildCategorizedView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_filteredTags.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: AppTheme.grisBody.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No s\'han trobat resultats',
                style: TextStyle(
                  color: AppTheme.grisBody,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Prova amb altres termes de cerca',
                style: TextStyle(
                  color: AppTheme.grisBody.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredTags.length,
      itemBuilder: (context, index) {
        final tag = _filteredTags[index];
        return _buildTagItem(tag);
      },
    );
  }

  Widget _buildCategorizedView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: TagDefinitions.categories.length,
      itemBuilder: (context, index) {
        final category = TagDefinitions.categories[index];
        return _buildCategorySection(category);
      },
    );
  }

  Widget _buildCategorySection(TagCategory category) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encapçalament de categoria
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.mostassa,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(category.icon),
                  size: 18,
                  color: AppTheme.porpraFosc,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.name,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.porpraFosc,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Tags de la categoria
        ...category.tags.map((tag) => _buildTagItem(tag)),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTagItem(String tag) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectTag(tag),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.initialTag == tag
                  ? AppTheme.lilaMitja.withValues(alpha: 0.1)
                  : Colors.transparent,
              border: Border.all(
                color: widget.initialTag == tag
                    ? AppTheme.lilaMitja
                    : AppTheme.grisBody.withValues(alpha: 0.2),
                width: widget.initialTag == tag ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: widget.initialTag == tag
                          ? AppTheme.lilaMitja
                          : AppTheme.porpraFosc,
                      fontSize: 14,
                      fontWeight: widget.initialTag == tag
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
                if (widget.initialTag == tag)
                  Icon(Icons.check_circle, color: AppTheme.lilaMitja, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'hand_back':
        return Icons.back_hand;
      case 'rule':
        return Icons.rule;
      case 'warning':
        return Icons.warning;
      case 'dangerous':
        return Icons.dangerous;
      case 'settings':
        return Icons.settings;
      case 'special_char':
        return Icons.star;
      default:
        return Icons.label;
    }
  }
}

/// Funció helper per mostrar el TagSelector
Future<String?> showTagSelector(
  BuildContext context, {
  String? initialTag,
}) async {
  String? selectedTag;

  await showDialog<String>(
    context: context,
    builder: (context) => TagSelector(
      initialTag: initialTag,
      onTagSelected: (tag) {
        selectedTag = tag;
      },
    ),
  );

  return selectedTag;
}
