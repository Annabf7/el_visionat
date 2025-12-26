import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/personal_analysis.dart';
import '../providers/personal_analysis_provider.dart';

/// Modal per afegir o editar apunts personals dels àrbitres
///
/// Funcionalitats:
/// - Creació i edició d'apunts personals
/// - Selector multi-tag organitzat per categories
/// - Validació de text requerit
/// - Integració amb PersonalAnalysisProvider
/// - Design Material 3 consistent
class PersonalAnalysisModal extends StatefulWidget {
  /// L'apunt a editar (null per crear nou)
  final PersonalAnalysis? existingAnalysis;

  /// ID del partit actual
  final String matchId;

  const PersonalAnalysisModal({
    super.key,
    this.existingAnalysis,
    required this.matchId,
  });

  @override
  State<PersonalAnalysisModal> createState() => _PersonalAnalysisModalState();
}

class _PersonalAnalysisModalState extends State<PersonalAnalysisModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _textController;
  late final TextEditingController _ruleArticleController;
  late final Set<AnalysisTag> _selectedTags;
  late AnalysisSource _selectedSource;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Inicialitzar controladors amb dades existents (si n'hi ha)
    _textController = TextEditingController(
      text: widget.existingAnalysis?.text ?? '',
    );

    _ruleArticleController = TextEditingController(
      text: widget.existingAnalysis?.ruleArticle ?? '',
    );

    _selectedTags = Set<AnalysisTag>.from(widget.existingAnalysis?.tags ?? []);
    _selectedSource = widget.existingAnalysis?.source ?? AnalysisSource.match;
  }

  @override
  void dispose() {
    _textController.dispose();
    _ruleArticleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingAnalysis != null;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Capçalera
              Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit_note : Icons.note_add,
                    size: MediaQuery.of(context).size.width < 600 ? 24 : 32,
                    color: theme.colorScheme.onSurface,
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width < 600 ? 8 : 12,
                  ),
                  Expanded(
                    child: Text(
                      isEditing
                          ? 'Editar Apunt Personal'
                          : 'Nou Apunt Personal',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: MediaQuery.of(context).size.width < 600
                            ? 18
                            : 24,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Camp de text principal
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      // TextFormField per al text de l'apunt
                      TextFormField(
                        controller: _textController,
                        decoration: InputDecoration(
                          labelText: 'Descripció de la situació',
                          hintText: 'Escriu aquí les teves observacions...',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.edit),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                          suffixIcon: _textController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _textController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.clear),
                                )
                              : null,
                        ),
                        maxLines: 5,
                        minLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La descripció és obligatòria';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),

                      const SizedBox(height: 24),

                      // Selector de font (Partit o Test)
                      DropdownButtonFormField<AnalysisSource>(
                        initialValue: _selectedSource,
                        decoration: const InputDecoration(
                          labelText: 'Origen de l\'apunt',
                          border: OutlineInputBorder(),
                        ),
                        items: AnalysisSource.values.map((source) {
                          return DropdownMenuItem(
                            value: source,
                            child: Row(
                              children: [
                                Icon(source.icon, size: 20),
                                const SizedBox(width: 8),
                                Text(source.displayName),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedSource = value;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Camp d'article del reglament (OBLIGATORI)
                      TextFormField(
                        controller: _ruleArticleController,
                        decoration: InputDecoration(
                          labelText: 'Article del reglament *',
                          hintText: 'Ex: Art. 33.10',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.menu_book),
                          suffixIcon: _ruleArticleController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _ruleArticleController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.clear),
                                )
                              : null,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'L\'article del reglament és obligatori';
                          }
                          // Validar format bàsic (Art. XX.YY o Art. XX)
                          final regex = RegExp(r'^Art\.\s*\d+(\.\d+)?$', caseSensitive: false);
                          if (!regex.hasMatch(value.trim())) {
                            return 'Format invàlid. Exemple: Art. 33.10';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),

                      const SizedBox(height: 24),

                      // Selector de tags
                      _buildTagSelector(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Botons d'acció
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface,
                    ),
                    child: const Text('Cancel·lar'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _isLoading ? null : _saveAnalysis,
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEditing ? 'Actualitzar' : 'Crear'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagSelector() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Títol del selector
        Row(
          children: [
            Icon(Icons.label, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Etiquetes',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            // Indicador de tags seleccionats
            if (_selectedTags.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selectedTags.length} seleccionades',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Tags per categoria
        ...AnalysisCategory.values.map(_buildCategorySection),
      ],
    );
  }

  Widget _buildCategorySection(AnalysisCategory category) {
    final theme = Theme.of(context);
    final categoryTags = AnalysisTag.values
        .where((tag) => tag.category == category)
        .toList();

    return ExpansionTile(
      title: Row(
        children: [
          Icon(category.icon, size: 20, color: theme.colorScheme.onSurface),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              category.displayName,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      subtitle: Text(
        category.description,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categoryTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);

              return FilterChip(
                label: Text(tag.displayName, overflow: TextOverflow.ellipsis),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                },
                avatar: isSelected
                    ? Icon(
                        Icons.check_circle,
                        size: 18,
                        color: theme.colorScheme.onSecondaryContainer,
                      )
                    : null,
                selectedColor: theme.colorScheme.secondaryContainer,
                checkmarkColor: theme.colorScheme.onSecondaryContainer,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _saveAnalysis() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<PersonalAnalysisProvider>();
      final text = _textController.text.trim();

      if (widget.existingAnalysis != null) {
        // Editar apunt existent
        final updatedAnalysis = widget.existingAnalysis!.copyWith(
          text: text,
          tags: _selectedTags.toList(),
          ruleArticle: _ruleArticleController.text.trim(),
          source: _selectedSource,
        );

        await provider.updateAnalysis(updatedAnalysis);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Apunt actualitzat correctament'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Crear nou apunt
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('Usuari no autenticat');
        }

        final newAnalysis = PersonalAnalysis(
          id: '', // El servei generarà l'ID automàticament
          userId: user.uid,
          matchId: widget.matchId,
          jornadaId: 'jornada_actual', // TODO: obtenir de context real
          text: text,
          tags: _selectedTags.toList(),
          createdAt: DateTime.now(),
          userDisplayName: user.displayName ?? 'Usuari',
          isEdited: false,
          source: _selectedSource,
          ruleArticle: _ruleArticleController.text.trim(),
        );

        await provider.addAnalysis(newAnalysis);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Apunt creat correctament'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

/// Extensió per afegir icones a les categories d'anàlisi
extension AnalysisCategoryIcons on AnalysisCategory {
  IconData get icon {
    switch (this) {
      case AnalysisCategory.faltes:
        return Icons.sports_basketball;
      case AnalysisCategory.violacions:
        return Icons.warning;
      case AnalysisCategory.gestioControl:
        return Icons.control_camera;
      case AnalysisCategory.posicionament:
        return Icons.place;
      case AnalysisCategory.serveiRapid:
        return Icons.flash_on;
    }
  }

  String get description {
    switch (this) {
      case AnalysisCategory.faltes:
        return 'Anàlisi de situacions de faltes personals i tècniques, incloent RVBD i simulacions';
      case AnalysisCategory.violacions:
        return 'Observacions sobre violacions de les regles del joc';
      case AnalysisCategory.gestioControl:
        return 'Gestió del partit, control de situacions, comunicació i gestió d\'entrenadors';
      case AnalysisCategory.posicionament:
        return 'Posicionament arbitral i mecànica del treball en equip';
      case AnalysisCategory.serveiRapid:
        return 'Aplicació correcta del servei ràpid segons la normativa oficial';
    }
  }
}
