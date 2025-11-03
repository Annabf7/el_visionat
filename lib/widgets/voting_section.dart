import 'package:el_visionat/models/team_platform.dart';
import 'package:el_visionat/services/team_data_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
import '../theme/app_theme.dart';

class VotingSection extends StatefulWidget {
  const VotingSection({super.key});

  @override
  State<VotingSection> createState() => _VotingSectionState();
}

class _VotingSectionState extends State<VotingSection> {
  List<Team> _teams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    try {
      final teams = await context.read<TeamDataService>().getTeams();
      if (mounted) {
        setState(() {
          _teams = teams;
          _isLoading = false;
        });
      }
    } catch (e, st) {
      debugPrint('Error loading teams: $e\n$st');
      if (mounted) {
        setState(() {
          _teams = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppTheme.porpraFosc, // Placeholder color
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            provider.openVotingTitle,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 18,
              color: AppTheme.grisPistacho,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            // Mostrem com a molt 3 enfrontaments (pares). Si hi ha menys equips,
            // calculem el nombre de files disponible i les mostrem de manera segura.
            ...(() {
              final pairs = (_teams.length / 2).floor();
              final count = pairs.clamp(0, 3);
              if (count == 0) {
                return [
                  const Text(
                    'No hi ha equips disponibles',
                    style: TextStyle(color: AppTheme.grisPistacho),
                  ),
                ];
              }
              return List.generate(count, (index) {
                final aIndex = index * 2;
                final bIndex = index * 2 + 1;
                final teamA = _teams.length > aIndex ? _teams[aIndex] : Team()
                  ..name = '—';
                final teamB = _teams.length > bIndex ? _teams[bIndex] : Team()
                  ..name = '—';
                return _buildVotingRow(
                  teamA.name,
                  teamB.name,
                  '15/10/2025',
                  true,
                );
              });
            }()),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.grisPistacho,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Veure tots',
                style: TextStyle(color: AppTheme.porpraFosc),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVotingRow(
    String teamA,
    String teamB,
    String date,
    bool canVote,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(teamA, style: const TextStyle(color: AppTheme.grisPistacho)),
          Text(teamB, style: const TextStyle(color: AppTheme.grisPistacho)),
          Text(date, style: const TextStyle(color: AppTheme.grisPistacho)),
          ElevatedButton(
            onPressed: canVote ? () {} : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lilaMitja,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Votar', style: TextStyle(color: AppTheme.white)),
          ),
        ],
      ),
    );
  }
}
