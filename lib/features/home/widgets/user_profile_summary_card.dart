import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
import 'package:el_visionat/theme/app_theme.dart';

class UserProfileSummaryCard extends StatelessWidget {
  const UserProfileSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppTheme.mostassa,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PERFIL DE L\'ÀRBITRE',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 16,
              color: AppTheme.textBlackLow,
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: CircleAvatar(
              radius: 41,
              // Placeholder for the referee's image
              backgroundColor: AppTheme.grisPistacho,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              provider.refereeName,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                color: AppTheme.textBlackLow,
              ),
            ),
          ),
          Center(
            child: Text(
              provider.refereeCategory,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppTheme.textBlackLow,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildProfileStat(
            'Partits Analitzats',
            provider.analyzedMatches.toString(),
          ),
          _buildProfileStat('Precisió Mitjana', provider.averagePrecision),
          _buildProfileStat('Nivell Actual', provider.currentLevel),
          const SizedBox(height: 24),
          // This is where you could check for subscription status
          if (provider.isSubscribed)
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.grisBody,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow, color: AppTheme.grisPistacho),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Veure entrevista',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.grisPistacho),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppTheme.textBlackLow,
              ),
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textBlackLow,
            ),
          ),
        ],
      ),
    );
  }
}
