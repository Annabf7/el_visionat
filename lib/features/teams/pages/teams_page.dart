import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:el_visionat/features/teams/providers/team_provider.dart';
import 'package:el_visionat/features/teams/widgets/team_card.dart';
import 'package:el_visionat/core/theme/app_theme.dart';

/// Pàgina principal per visualitzar i gestionar els equips de bàsquet
///
/// Funcionalitats:
/// - Llista tots els equips carregats des de Firestore/Isar
/// - Filtre per gènere (masculí/femení)
/// - Cerca per nom o acrònim
/// - Pull-to-refresh per actualitzar dades
/// - Segueix les guidelines UI/UX del projecte
class TeamsPage extends StatefulWidget {
  const TeamsPage({super.key});

  @override
  State<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends State<TeamsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedGender = 'tots'; // 'tots', 'masculí', 'femení'

  @override
  void initState() {
    super.initState();
    // Carrega els equips quan s'inicialitza la pàgina
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeamProvider>().loadTeams();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equips de Bàsquet'),
        backgroundColor: AppTheme.porpraFosc,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Barra de cerca i filtres
          _buildSearchAndFilters(),
          // Llista d'equips
          Expanded(
            child: Consumer<TeamProvider>(
              builder: (context, teamProvider, child) {
                if (teamProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (teamProvider.error != null) {
                  return _buildErrorWidget(teamProvider.error!);
                }

                if (!teamProvider.hasTeams) {
                  return _buildEmptyState();
                }

                // Filtra els equips segons cerca i gènere
                final filteredTeams = _getFilteredTeams(teamProvider);

                if (filteredTeams.isEmpty) {
                  return _buildNoResultsState();
                }

                return RefreshIndicator(
                  onRefresh: () => teamProvider.refreshTeams(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTeams.length,
                    itemBuilder: (context, index) {
                      final team = filteredTeams[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TeamCard(team: team),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // Barra de cerca
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Cerca per nom o acrònim...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: 12),
          // Filtres de gènere
          Row(
            children: [
              const Text(
                'Filtrar per gènere: ',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'tots', label: Text('Tots')),
                    ButtonSegment(value: 'masculí', label: Text('Masculí')),
                    ButtonSegment(value: 'femení', label: Text('Femení')),
                  ],
                  selected: {_selectedGender},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _selectedGender = selection.first;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Error carregant equips',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<TeamProvider>().loadTeams(),
              child: const Text('Torna a intentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hi ha equips disponibles',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Els equips es carregaran automàticament quan estiguin disponibles.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No s\'han trobat equips',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Prova amb altres criteris de cerca o filtre.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<dynamic> _getFilteredTeams(TeamProvider teamProvider) {
    var teams = teamProvider.teams;

    // Filtra per cerca
    final searchQuery = _searchController.text.trim();
    if (searchQuery.isNotEmpty) {
      teams = teamProvider.searchTeams(searchQuery);
    }

    // Filtra per gènere
    if (_selectedGender != 'tots') {
      teams = teams.where((team) => team.gender == _selectedGender).toList();
    }

    return teams;
  }
}
