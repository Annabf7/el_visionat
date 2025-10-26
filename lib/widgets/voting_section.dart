import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
import '../theme/app_theme.dart';

class VotingSection extends StatelessWidget {
  const VotingSection({super.key});

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
          _buildVotingRow('Equip A', 'Equip B', '15/10/2025', true),
          _buildVotingRow('Equip C', 'Equip D', '15/10/2025', true),
          _buildVotingRow('Equip E', 'Equip F', '16/10/2025', false),
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
