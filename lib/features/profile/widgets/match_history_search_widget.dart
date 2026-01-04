import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../designations/widgets/designation_details_sheet.dart';
import '../models/match_history_result.dart';
import '../services/match_history_service.dart';
import 'match_history_card.dart';

/// Widget de cerca d'historial de partits (àrbitres i equips)
class MatchHistorySearchWidget extends StatefulWidget {
  const MatchHistorySearchWidget({super.key});

  @override
  State<MatchHistorySearchWidget> createState() =>
      _MatchHistorySearchWidgetState();
}

class _MatchHistorySearchWidgetState extends State<MatchHistorySearchWidget>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _service = MatchHistoryService();

  late TabController _tabController;
  MatchHistoryResult? _searchResult;
  bool _isSearching = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();

    // Evitar cerques repetides
    if (query == _lastQuery) return;
    _lastQuery = query;

    // Esperar 500ms abans de cercar (debounce)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text.trim() == query) {
        _performSearch(query);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResult = null;
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final result = _tabController.index == 0
          ? await _service.searchByReferee(refereeName: query)
          : await _service.searchByTeam(teamName: query);

      setState(() {
        _searchResult = result;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cercant: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.grisPistacho.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.porpraFosc.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Títol
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.search,
                color: AppTheme.grisPistacho,
                size: 20,
              ),
              SizedBox(width: 10),
              Text(
                'Cerca el teu historial',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textBlackLow,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tabs
          Container(
            decoration: BoxDecoration(
              color: AppTheme.grisPistacho.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.grisPistacho,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textBlackLow.withValues(alpha: 0.6),
              labelStyle: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Àrbitres'),
                Tab(text: 'Equips'),
              ],
              onTap: (index) {
                // Refrescar la cerca quan canviem de tab
                if (_searchController.text.trim().isNotEmpty) {
                  _performSearch(_searchController.text.trim());
                }
              },
            ),
          ),
          const SizedBox(height: 16),

          // Camp de cerca
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: _tabController.index == 0
                  ? 'Cerca per nom d\'àrbitre...'
                  : 'Cerca per nom d\'equip...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.lilaMitja),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppTheme.lilaMitja),
                        ),
                      ),
                    )
                  : _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchResult = null);
                          },
                        )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.grisBody.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.grisBody.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.lilaMitja,
                  width: 2,
                ),
              ),
            ),
          ),

          // Resultats
          if (_searchResult != null) ...[
            const SizedBox(height: 24),
            _buildResults(),
          ],
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_searchResult == null) return const SizedBox.shrink();

    if (_searchResult!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: AppTheme.grisPistacho.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No s\'han trobat partits',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.grisPistacho.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _tabController.index == 0
                    ? 'No has arbitrat cap partit amb "${_searchResult!.searchTerm}"'
                    : 'No has arbitrat cap partit de "${_searchResult!.searchTerm}"',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.grisPistacho.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resum
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.lilaMitja.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                _tabController.index == 0 ? Icons.person : Icons.sports_basketball,
                color: AppTheme.lilaMitja,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _searchResult!.searchTerm,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.grisPistacho,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_searchResult!.totalMatches} ${_searchResult!.totalMatches == 1 ? 'partit' : 'partits'}${_searchResult!.lastMatchDate != null ? ' • Última vegada: ${DateFormat('dd/MM/yyyy').format(_searchResult!.lastMatchDate!)}' : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.grisPistacho.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Llista de partits
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _searchResult!.matches.length,
          itemBuilder: (context, index) {
            final match = _searchResult!.matches[index];
            return MatchHistoryCard(
              designation: match,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => DraggableScrollableSheet(
                    initialChildSize: 0.9,
                    minChildSize: 0.5,
                    maxChildSize: 0.95,
                    builder: (context, scrollController) => Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: DesignationDetailsSheet(designation: match),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}