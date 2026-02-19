import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import '../models/monthly_battle.dart';

/// Widget de rànquing de la batalla mensual
class BattleRankingWidget extends StatelessWidget {
  final List<BattleResult> ranking;
  final String currentUserId;

  const BattleRankingWidget({
    super.key,
    required this.ranking,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Títol
        Row(
          children: [
            const Icon(
              Icons.leaderboard_rounded,
              color: AppTheme.mostassa,
              size: 22,
            ),
            const SizedBox(width: 8),
            const Text(
              'Rànquing',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.white,
              ),
            ),
            const Spacer(),
            Text(
              '${ranking.length} participants',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 13,
                color: AppTheme.grisPistacho.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Llista de participants
        ...List.generate(ranking.length, (index) {
          final result = ranking[index];
          final position = index + 1;
          final isCurrentUser = result.userId == currentUserId;

          return _RankingRow(
            position: position,
            result: result,
            isCurrentUser: isCurrentUser,
          );
        }),
      ],
    );
  }
}

class _RankingRow extends StatelessWidget {
  final int position;
  final BattleResult result;
  final bool isCurrentUser;

  const _RankingRow({
    required this.position,
    required this.result,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final isTop3 = position <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppTheme.mostassa.withValues(alpha: 0.1)
            : AppTheme.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(
                color: AppTheme.mostassa.withValues(alpha: 0.3),
                width: 1.5,
              )
            : null,
      ),
      child: Row(
        children: [
          // Posició / medalla
          SizedBox(
            width: 36,
            child: isTop3
                ? Icon(
                    Icons.emoji_events_rounded,
                    color: _getMedalColor(position),
                    size: 22,
                  )
                : Text(
                    '#$position',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.grisPistacho.withValues(alpha: 0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
          const SizedBox(width: 10),

          // Nom
          Expanded(
            child: Text(
              result.displayName,
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 14,
                fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w500,
                color: isCurrentUser
                    ? AppTheme.mostassa
                    : AppTheme.white.withValues(alpha: 0.85),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Puntuació
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getScoreColor(result.score / 10).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${result.score}/10',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _getScoreColor(result.score / 10),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Temps
          SizedBox(
            width: 60,
            child: Text(
              result.formattedTime,
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 12,
                color: AppTheme.grisPistacho.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _getMedalColor(int position) {
    switch (position) {
      case 1:
        return const Color(0xFFFFD700); // Or
      case 2:
        return const Color(0xFFC0C0C0); // Plata
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppTheme.grisPistacho;
    }
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 0.7) return AppTheme.verdeEncert;
    if (percentage >= 0.5) return AppTheme.mostassa;
    return Colors.redAccent;
  }
}
