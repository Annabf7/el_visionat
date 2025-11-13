import 'package:flutter/material.dart';
import '../../../models/highlight_entry.dart';
import '../../../models/match_models.dart';
import 'widgets/match_header.dart';
import 'widgets/match_video_section.dart';
import 'widgets/tag_filter_bar.dart';
import 'widgets/highlights_timeline.dart';
import 'widgets/match_details_card.dart';
import 'widgets/user_analysis_card.dart';
import 'widgets/referee_comment_card.dart';
import 'widgets/add_highlight_card.dart';

class VisionatMatchPage extends StatefulWidget {
  const VisionatMatchPage({super.key});

  @override
  State<VisionatMatchPage> createState() => _VisionatMatchPageState();
}

class _VisionatMatchPageState extends State<VisionatMatchPage> {
  HighlightTagType? selectedTag;
  String userAnalysisText = '';

  // Mock data per a highlights
  final List<HighlightEntry> mockHighlights = [
    HighlightEntry(
      id: '1',
      timestamp: const Duration(minutes: 23, seconds: 45),
      title: 'Possible interferència no xiulada – Pista ofensiva Salt',
      tag: HighlightTagType.decisioClau,
    ),
    HighlightEntry(
      id: '2',
      timestamp: const Duration(minutes: 45, seconds: 12),
      title: 'Manca control banquetes',
      tag: HighlightTagType.gestio,
    ),
    HighlightEntry(
      id: '3',
      timestamp: const Duration(minutes: 67, seconds: 32),
      title: 'Error R.LL',
      tag: HighlightTagType.faltaTecnica,
    ),
    HighlightEntry(
      id: '4',
      timestamp: const Duration(minutes: 67, seconds: 32),
      title: 'Violació camp enrere',
      tag: HighlightTagType.faltaTecnica,
    ),
    HighlightEntry(
      id: '5',
      timestamp: const Duration(minutes: 67, seconds: 32),
      title: 'Bloqueig Il·legal',
      tag: HighlightTagType.posicio,
    ),
    HighlightEntry(
      id: '6',
      timestamp: const Duration(minutes: 67, seconds: 32),
      title: 'Tècnica per Flopping',
      tag: HighlightTagType.comunicacio,
    ),
    HighlightEntry(
      id: '7',
      timestamp: const Duration(minutes: 67, seconds: 32),
      title: 'Servei ràpid',
      tag: HighlightTagType.gestio,
    ),
  ];

  // Mock data per a detalls del partit
  final MatchDetails mockMatchDetails = const MatchDetails(
    refereeName: 'Marc Ribas',
    league: 'Super copa Catalunya',
    matchday: 10,
  );

  List<HighlightEntry> get filteredHighlights {
    if (selectedTag == null) return mockHighlights;
    return mockHighlights.where((h) => h.tag == selectedTag).toList();
  }

  void _onTagChanged(HighlightTagType? newTag) {
    setState(() {
      selectedTag = newTag;
    });
  }

  void _onAnalysisTextChanged(String text) {
    setState(() {
      userAnalysisText = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth >= 900;

          if (isWideScreen) {
            return _buildWebLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
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
                TagFilterBar(
                  selectedTag: selectedTag,
                  onTagChanged: _onTagChanged,
                  showIcons: true,
                ),
                const SizedBox(height: 24),
                HighlightsTimeline(
                  entries: filteredHighlights,
                  selectedTag: selectedTag,
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
                  UserAnalysisCard(
                    text: userAnalysisText,
                    onTextChanged: _onAnalysisTextChanged,
                  ),
                  const SizedBox(height: 16),
                  const RefereeCommentCard(),
                  const SizedBox(height: 16),
                  const AddHighlightCard(),
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
          TagFilterBar(
            selectedTag: selectedTag,
            onTagChanged: _onTagChanged,
            showIcons: false,
          ),
          const SizedBox(height: 16),
          HighlightsTimeline(
            entries: filteredHighlights,
            selectedTag: selectedTag,
          ),
          const SizedBox(height: 16),
          MatchDetailsCard(details: mockMatchDetails),
          const SizedBox(height: 16),
          UserAnalysisCard(
            text: userAnalysisText,
            onTextChanged: _onAnalysisTextChanged,
          ),
          const SizedBox(height: 16),
          const RefereeCommentCard(),
          const SizedBox(height: 16),
          const AddHighlightCard(),
        ],
      ),
    );
  }
}
