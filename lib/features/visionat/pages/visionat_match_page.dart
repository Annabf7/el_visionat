import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/highlight_entry.dart';
import '../models/collective_comment.dart';

import '../providers/highlight_provider.dart';
import '../providers/collective_comment_provider.dart';
import '../providers/personal_analysis_provider.dart';
import '../providers/weekly_match_provider.dart';

import 'package:el_visionat/core/navigation/side_navigation_menu.dart';
import 'package:el_visionat/core/widgets/global_header.dart';
import '../widgets/match_header.dart';
import '../widgets/match_video_section.dart';
import '../widgets/tag_filter_bar.dart';
import '../widgets/highlights_timeline.dart';
import '../widgets/match_details_card.dart';
import '../widgets/referee_comment_card.dart';
import '../widgets/add_highlight_card.dart';
import '../widgets/collective_analysis_modal.dart';
import '../widgets/analysis_section_card.dart';
import '../widgets/clips_section.dart';

class VisionatMatchPage extends StatefulWidget {
  const VisionatMatchPage({super.key});

  @override
  State<VisionatMatchPage> createState() => _VisionatMatchPageState();
}

class _VisionatMatchPageState extends State<VisionatMatchPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final String _mockMatchId =
      'match_123'; // TODO: Obtenir de paràmetres de ruta

  @override
  /// Inicialitza l'estat amb lazy loading per evitar ANR
  /// Utilitza Future.microtask per evitar crides dins de build()
  void initState() {
    super.initState();

    // Lazy initialization per evitar rebuild loops
    Future.microtask(() {
      if (!mounted) return;

      // Accedir als providers globals i inicialitzar només una vegada
      final highlightProvider = context.read<VisionatHighlightProvider>();
      final commentProvider = context.read<VisionatCollectiveCommentProvider>();
      final personalAnalysisProvider = context.read<PersonalAnalysisProvider>();
      final weeklyMatchProvider = context.read<WeeklyMatchProvider>();

      highlightProvider.setMatch(_mockMatchId);
      commentProvider.setMatch(_mockMatchId);

      // Inicialitzar weekly match provider per carregar àrbitre
      weeklyMatchProvider.initialize();

      // Inicialitzar personal analysis amb userId actual
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        personalAnalysisProvider.setUser(user.uid);
      }
    });
  }

  // Les dades del partit es gestionen pel WeeklyMatchProvider

  @override
  void dispose() {
    // No need to dispose global providers
    super.dispose();
  }

  void _addNewHighlight(
    String minutage,
    String tagText,
    String title,
    String comment,
  ) async {
    try {
      // Convertir minutatge de text a Duration
      Duration timestamp = _parseMinutage(minutage);

      // Convertir tag de text a HighlightTagType i categoria
      HighlightTagType? highlightTag = _mapTextToTagType(tagText);
      String category = _mapTextToCategory(tagText);

      // Obtenir usuari actual
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('Cal estar autenticat per afegir highlights');
        return;
      }

      // Validació de dades
      if (highlightTag != null && title.isNotEmpty && category.isNotEmpty) {
        final newHighlight = HighlightEntry(
          id: '', // Es generarà automàticament
          matchId: _mockMatchId,
          timestamp: timestamp,
          title: title,
          tag: highlightTag,
          category: category,
          tagId: highlightTag.value,
          tagLabel: highlightTag.displayName,
          description: comment.isNotEmpty ? comment : title,
          createdBy: user.uid,
          createdAt: DateTime.now(),
        );

        final highlightProvider = context.read<VisionatHighlightProvider>();
        await highlightProvider.addHighlight(newHighlight);
      }
    } catch (e) {
      _showError('Error afegint highlight: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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
    final highlightProvider = context.read<VisionatHighlightProvider>();
    highlightProvider.setCategory(category);
  }

  void _addCollectiveComment(String text, bool isAnonymous) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final comment = CollectiveComment(
        id: '', // S'assignarà automàticament a Firestore
        matchId: _mockMatchId,
        content: text,
        tagId: 'general', // Tag general per defecte
        tagLabel: 'General',
        createdBy: user.uid,
        createdByName: isAnonymous ? 'Anònim' : (user.displayName ?? 'Usuari'),
        createdAt: DateTime.now(),
        likes: 0,
        likedBy: [],
        isEdited: false,
      );

      final commentProvider = context.read<VisionatCollectiveCommentProvider>();
      await commentProvider.addComment(comment);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error afegint comentari: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openCollectiveAnalysisModal() {
    showCollectiveAnalysisModal(context, onCommentAdded: _addCollectiveComment);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= 900;

        if (isWideScreen) {
          // Layout desktop: Menú lateral ocupa tota l'alçada
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: Row(
              children: [
                // Menú lateral amb alçada completa (inclou l'espai del header)
                SizedBox(
                  width: 288,
                  height: double.infinity,
                  child: const SideNavigationMenu(),
                ),

                // Columna dreta amb GlobalHeader + contingut
                Expanded(
                  child: Column(
                    children: [
                      // GlobalHeader només per l'amplada restant
                      GlobalHeader(
                        scaffoldKey: _scaffoldKey,
                        showMenuButton: false,
                      ),

                      // Contingut principal
                      Expanded(child: _buildWebLayout()),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          // Layout mòbil: comportament tradicional
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: Theme.of(context).colorScheme.surface,
            drawer: const SideNavigationMenu(),
            body: Column(
              children: [
                // GlobalHeader sempre visible
                GlobalHeader(scaffoldKey: _scaffoldKey),
                // Contingut principal expandit
                Expanded(child: _buildMobileLayout()),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildWebLayout() {
    return Row(
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
                Consumer<VisionatHighlightProvider>(
                  builder: (context, provider, child) => TagFilterBar(
                    selectedCategory: provider.selectedCategory,
                    onCategoryChanged: _onCategoryChanged,
                  ),
                ),
                const SizedBox(height: 24),
                Consumer<VisionatHighlightProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (provider.hasError) {
                      return Center(
                        child: Column(
                          children: [
                            Text(
                              'Error: ${provider.errorMessage}',
                              style: TextStyle(color: Colors.red),
                            ),
                            ElevatedButton(
                              onPressed: () => provider.refresh(),
                              child: Text('Tornar a carregar'),
                            ),
                          ],
                        ),
                      );
                    }
                    return HighlightsTimeline(
                      entries: provider.filteredHighlights,
                      selectedCategory: provider.selectedCategory,
                    );
                  },
                ),
                const SizedBox(height: 24),
                const ClipsSection(),
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
                  const MatchDetailsCard(),
                  const SizedBox(height: 16),
                  AddHighlightCard(onHighlightAdded: _addNewHighlight),
                  const SizedBox(height: 16),
                  const RefereeCommentCard(),
                  const SizedBox(height: 16),
                  Consumer<VisionatCollectiveCommentProvider>(
                    builder: (context, provider, child) {
                      return AnalysisSectionCard(
                        matchId: _mockMatchId,
                        collectiveComments: provider.comments,
                        onViewAllComments: _openCollectiveAnalysisModal,
                      );
                    },
                  ),
                ],
              ),
            ),
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
          Consumer<VisionatHighlightProvider>(
            builder: (context, provider, child) => TagFilterBar(
              selectedCategory: provider.selectedCategory,
              onCategoryChanged: _onCategoryChanged,
            ),
          ),
          const SizedBox(height: 24),
          Consumer<VisionatHighlightProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (provider.hasError) {
                return Center(
                  child: Column(
                    children: [
                      Text(
                        'Error: ${provider.errorMessage}',
                        style: TextStyle(color: Colors.red),
                      ),
                      ElevatedButton(
                        onPressed: () => provider.refresh(),
                        child: Text('Tornar a carregar'),
                      ),
                    ],
                  ),
                );
              }
              return HighlightsTimeline(
                entries: provider.filteredHighlights,
                selectedCategory: provider.selectedCategory,
              );
            },
          ),
          const SizedBox(height: 16),
          const MatchDetailsCard(),
          const SizedBox(height: 16),
          AddHighlightCard(onHighlightAdded: _addNewHighlight),
          const SizedBox(height: 16),
          const RefereeCommentCard(),
          const SizedBox(height: 16),
          Consumer<VisionatCollectiveCommentProvider>(
            builder: (context, provider, child) {
              return AnalysisSectionCard(
                matchId: _mockMatchId,
                collectiveComments: provider.comments,
                onViewAllComments: _openCollectiveAnalysisModal,
              );
            },
          ),
          const SizedBox(height: 16),
          const ClipsSection(),
        ],
      ),
    );
  }
}
