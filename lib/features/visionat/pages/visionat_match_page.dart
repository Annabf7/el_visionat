import 'package:flutter/material.dart';
import '../models/highlight_entry.dart';
import '../models/match_models.dart';
import '../models/collective_comment.dart';
import '../../../widgets/side_navigation_menu.dart';
import '../widgets/match_header.dart';
import '../widgets/match_video_section.dart';
import '../widgets/tag_filter_bar.dart';
import '../widgets/highlights_timeline.dart';
import '../widgets/match_details_card.dart';
import '../widgets/referee_comment_card.dart';
import '../widgets/add_highlight_card.dart';
import '../widgets/collective_analysis_modal.dart';
import '../widgets/analysis_section_card.dart';

class VisionatMatchPage extends StatefulWidget {
  const VisionatMatchPage({super.key});

  @override
  State<VisionatMatchPage> createState() => _VisionatMatchPageState();
}

class _VisionatMatchPageState extends State<VisionatMatchPage> {
  String? selectedCategory;
  String userAnalysisText = '';

  // Comentaris col·lectius (mock data)
  final List<CollectiveComment> _collectiveComments = [
    CollectiveComment(
      id: '1',
      username: 'Joan Martí',
      text:
          'Crec que l\'àrbitre ha estat bastant consistent durant tot el partit. Les decisions clau han estat correctes.',
      anonymous: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    CollectiveComment(
      id: '2',
      username: 'Usuari anònim',
      text:
          'Hi ha hagut algunes situacions dubtoses al tercer quart que haurien pogut ser xiulades de manera diferent.',
      anonymous: true,
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
    CollectiveComment(
      id: '3',
      username: 'Maria Sánchez',
      text:
          'Molt bon control del partit en general. El posicionament ha estat excel·lent.',
      anonymous: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
    ),
  ];

  // Llista mutable d'highlights (inicialment amb mock data)
  final List<HighlightEntry> _highlights = [
    HighlightEntry(
      id: '1',
      timestamp: const Duration(minutes: 23, seconds: 45),
      title: 'Possible interferència no xiulada – Pista ofensiva Salt',
      tag: HighlightTagType.decisioClau,
      category: 'Situacions especials',
    ),
    HighlightEntry(
      id: '2',
      timestamp: const Duration(minutes: 45, seconds: 12),
      title: 'Manca control banquetes',
      tag: HighlightTagType.gestio,
      category: 'Gestió i posicionament',
    ),
    HighlightEntry(
      id: '3',
      timestamp: const Duration(minutes: 67, seconds: 32),
      title: 'Error R.LL',
      tag: HighlightTagType.faltaTecnica,
      category: 'Faltes tècniques',
    ),
    HighlightEntry(
      id: '4',
      timestamp: const Duration(minutes: 67, seconds: 32),
      title: 'Violació camp enrere',
      tag: HighlightTagType.faltaTecnica,
      category: 'Violacions',
    ),
    HighlightEntry(
      id: '5',
      timestamp: const Duration(minutes: 67, seconds: 32),
      title: 'Bloqueig Il·legal',
      tag: HighlightTagType.posicio,
      category: 'Faltes personals',
    ),
    HighlightEntry(
      id: '6',
      timestamp: const Duration(minutes: 67, seconds: 32),
      title: 'Tècnica per Flopping',
      tag: HighlightTagType.comunicacio,
      category: 'Faltes tècniques',
    ),
    HighlightEntry(
      id: '7',
      timestamp: const Duration(minutes: 67, seconds: 32),
      title: 'Servei ràpid',
      tag: HighlightTagType.gestio,
      category: 'Gestió i posicionament',
    ),
  ];

  // Mock data per a detalls del partit
  final MatchDetails mockMatchDetails = const MatchDetails(
    refereeName: 'Marc Ribas',
    league: 'Super copa Catalunya',
    matchday: 10,
  );

  List<HighlightEntry> get filteredHighlights {
    if (selectedCategory == null) return _highlights;
    return _highlights.where((h) => h.category == selectedCategory).toList();
  }

  void _addNewHighlight(
    String minutage,
    String tagText,
    String title,
    String comment,
  ) {
    try {
      // Convertir minutatge de text a Duration
      Duration timestamp = _parseMinutage(minutage);

      // Convertir tag de text a HighlightTagType i categoria
      HighlightTagType? highlightTag = _mapTextToTagType(tagText);
      String category = _mapTextToCategory(tagText);

      // Validació de dades
      if (highlightTag != null && title.isNotEmpty && category.isNotEmpty) {
        final newHighlight = HighlightEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          timestamp: timestamp,
          title: title,
          tag: highlightTag,
          category: category,
        );

        setState(() {
          _highlights.add(newHighlight);
          // Ordenar per timestamp
          _highlights.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        });
      }
    } catch (e) {
      debugPrint('Error afegint highlight: $e');
      // Mostrar error a l'usuari
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error afegint la jugada: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Duration _parseMinutage(String minutage) {
    if (minutage.isEmpty) return Duration.zero;

    final parts = minutage.split(':');
    if (parts.length == 2) {
      final minutes = int.tryParse(parts[0]) ?? 0;
      final seconds = int.tryParse(parts[1]) ?? 0;
      return Duration(minutes: minutes, seconds: seconds);
    }

    // Si només hi ha un número, assumim que són minuts
    final minutes = int.tryParse(minutage) ?? 0;
    return Duration(minutes: minutes);
  }

  HighlightTagType? _mapTextToTagType(String tagText) {
    switch (tagText) {
      case 'Falta tècnica':
      case 'Falta antiesportiva':
      case 'Falta personal':
      case 'Infracció':
      case 'Violació 24s':
      case 'Violació 8s':
      case 'Violació 3s':
      case 'Peu':
      case 'Dobles':
      case 'Passos':
        return HighlightTagType.faltaTecnica;

      case 'Fora de banda':
      case 'Canasta vàlida':
      case 'Canasta no vàlida':
      case 'Interferència':
      case 'Revisió vídeo':
        return HighlightTagType.decisioClau;

      case 'Temps mort':
        return HighlightTagType.gestio;

      default:
        return HighlightTagType.posicio; // Tag per defecte
    }
  }

  String _mapTextToCategory(String tagText) {
    // Assegurem que sempre retornem un String vàlid
    if (tagText.isEmpty) return 'Situacions especials';

    // Mapear tags del TagSelector a categories FIBA
    if (tagText.contains('Bloqueig') ||
        tagText.contains('Càrrega') ||
        tagText.contains('Mans') ||
        tagText.contains('Contacte') ||
        tagText.contains('Falta en rebot') ||
        tagText.contains('Pantalla') ||
        tagText.contains('Retenir') ||
        tagText.contains('Empenta') ||
        tagText.contains('Falta per darrere') ||
        tagText.contains('Obstrucció') ||
        tagText.contains('Falta d\'atac') ||
        tagText.contains('Falta defensiva') ||
        tagText.contains('Falta personal')) {
      return 'Faltes personals';
    }

    if (tagText.contains('Passos') ||
        tagText.contains('Dobles') ||
        tagText.contains('Violació') ||
        tagText.contains('Camp enrere') ||
        tagText.contains('Peu') ||
        tagText.contains('Fora de banda') ||
        tagText.contains('Interferència') ||
        tagText.contains('Interposició') ||
        tagText.contains('Portada') ||
        tagText.contains('Tir que no toca')) {
      return 'Violacions';
    }

    if (tagText.contains('Protesta') ||
        tagText.contains('Gesticulacions') ||
        tagText.contains('Simulació') ||
        tagText.contains('Retardar') ||
        tagText.contains('Tècnica') ||
        tagText.contains('Comunicació irrespectuosa') ||
        tagText.contains('Expressions ofensives') ||
        tagText.contains('Intimidació')) {
      return 'Faltes tècniques';
    }

    if (tagText.contains('Antiesportiva') ||
        tagText.contains('Desqualificant') ||
        tagText.contains('Expulsió') ||
        tagText.contains('Agressió') ||
        tagText.contains('Conducta violent') ||
        tagText.contains('Amenaça')) {
      return 'Antiesportives i desqualificants';
    }

    if (tagText.contains('Posicionament') ||
        tagText.contains('Rotació') ||
        tagText.contains('Gestió') ||
        tagText.contains('Control') ||
        tagText.contains('Comunicació entre àrbitres') ||
        tagText.contains('Mecànica') ||
        tagText.contains('Cronometratge')) {
      return 'Gestió i posicionament';
    }

    // Situacions especials per defecte - sempre retornem un valor vàlid
    return 'Situacions especials';
  }

  void _onCategoryChanged(String? category) {
    setState(() {
      selectedCategory = category;
    });
  }

  void _onAnalysisTextChanged(String text) {
    setState(() {
      userAnalysisText = text;
    });
  }

  void _savePersonalAnalysis() {
    // Aquí es guardaria a userProfile en el futur
    debugPrint('Guardant anàlisi personal: $userAnalysisText');
  }

  void _addCollectiveComment(String text, bool isAnonymous) {
    final newComment = CollectiveComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: isAnonymous
          ? 'Usuari anònim'
          : 'Tu', // En el futur vindria del perfil
      text: text,
      anonymous: isAnonymous,
      createdAt: DateTime.now(),
    );

    setState(() {
      _collectiveComments.insert(0, newComment); // Afegir al principi
    });
  }

  void _openCollectiveAnalysisModal() {
    showCollectiveAnalysisModal(
      context,
      comments: _collectiveComments,
      onCommentAdded: _addCollectiveComment,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= 900;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          // AppBar només en mòbil per accés al drawer
          appBar: isWideScreen
              ? null
              : AppBar(
                  title: const Text('El Visionat'),
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  elevation: 0,
                ),
          // Drawer en mòbil per navegació
          drawer: isWideScreen ? null : const SideNavigationMenu(),

          body: isWideScreen ? _buildWebLayout() : _buildMobileLayout(),
        );
      },
    );
  }

  Widget _buildWebLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Menú lateral fix en mode desktop
        const SizedBox(width: 288, child: SideNavigationMenu()),

        // Contingut principal
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Columna esquerra
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const MatchHeader(),
                      const SizedBox(height: 24),
                      const MatchVideoSection(),
                      const SizedBox(height: 24),
                      TagFilterBar(
                        selectedCategory: selectedCategory,
                        onCategoryChanged: _onCategoryChanged,
                      ),
                      const SizedBox(height: 24),
                      HighlightsTimeline(
                        entries: filteredHighlights,
                        selectedCategory: selectedCategory,
                      ),
                    ],
                  ),
                ),
              ),
              // Columna dreta
              Expanded(
                flex: 1,
                child: Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        MatchDetailsCard(details: mockMatchDetails),
                        const SizedBox(height: 16),
                        AddHighlightCard(onHighlightAdded: _addNewHighlight),
                        const SizedBox(height: 16),
                        const RefereeCommentCard(),
                        const SizedBox(height: 16),
                        AnalysisSectionCard(
                          personalAnalysisText: userAnalysisText,
                          onPersonalAnalysisChanged: _onAnalysisTextChanged,
                          onPersonalAnalysisSave: _savePersonalAnalysis,
                          collectiveComments: _collectiveComments,
                          onViewAllComments: _openCollectiveAnalysisModal,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const MatchHeader(),
          const SizedBox(height: 16),
          const MatchVideoSection(),
          const SizedBox(height: 16),
          TagFilterBar(
            selectedCategory: selectedCategory,
            onCategoryChanged: _onCategoryChanged,
          ),
          const SizedBox(height: 16),
          HighlightsTimeline(
            entries: filteredHighlights,
            selectedCategory: selectedCategory,
          ),
          const SizedBox(height: 16),
          MatchDetailsCard(details: mockMatchDetails),
          const SizedBox(height: 16),
          AddHighlightCard(onHighlightAdded: _addNewHighlight),
          const SizedBox(height: 16),
          const RefereeCommentCard(),
          const SizedBox(height: 16),
          AnalysisSectionCard(
            personalAnalysisText: userAnalysisText,
            onPersonalAnalysisChanged: _onAnalysisTextChanged,
            onPersonalAnalysisSave: _savePersonalAnalysis,
            collectiveComments: _collectiveComments,
            onViewAllComments: _openCollectiveAnalysisModal,
          ),
        ],
      ),
    );
  }
}
