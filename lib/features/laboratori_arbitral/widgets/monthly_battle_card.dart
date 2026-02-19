import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import '../models/monthly_battle.dart';
import '../pages/monthly_battle_page.dart';
import '../services/monthly_battle_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Card dinàmic de la batalla mensual que mostra l'estat actual
class MonthlyBattleCard extends StatefulWidget {
  const MonthlyBattleCard({super.key});

  @override
  State<MonthlyBattleCard> createState() => _MonthlyBattleCardState();
}

class _MonthlyBattleCardState extends State<MonthlyBattleCard> {
  final MonthlyBattleService _service = MonthlyBattleService();
  MonthlyBattle? _battle;
  BattleResult? _userResult;
  int? _userPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final battle = await _service.getCurrentBattle();
      BattleResult? userResult;
      int? position;

      if (battle != null) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          userResult = await _service.getUserResult(battle.yearMonth, uid);
          if (userResult != null) {
            final ranking = await _service.getRanking(battle.yearMonth);
            final idx = ranking.indexWhere((r) => r.userId == uid);
            if (idx >= 0) position = idx + 1;
          }
        }
      }

      if (mounted) {
        setState(() {
          _battle = battle;
          _userResult = userResult;
          _userPosition = position;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _getSubtitle();

    return Card(
      color: AppTheme.lilaMitja,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MonthlyBattlePage()),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.porpraFosc.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: AppTheme.porpraFosc,
                  size: 32,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Batalla mensual',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.porpraFosc,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    if (_isLoading)
                      SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.porpraFosc.withValues(alpha: 0.5),
                        ),
                      )
                    else
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.porpraFosc.withValues(alpha: 0.8),
                            ),
                      ),
                    // Badge si ja ha jugat
                    if (_userResult != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.porpraFosc.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_userResult!.score}/10 · ${_userResult!.formattedTime}${_userPosition != null ? ' · #$_userPosition' : ''}',
                          style: const TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.porpraFosc,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                _userResult != null
                    ? Icons.leaderboard_rounded
                    : Icons.arrow_forward_ios,
                color: AppTheme.porpraFosc,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSubtitle() {
    if (_battle == null) return 'Pròximament...';

    if (_userResult != null) {
      return 'Ja has jugat · Veure rànquing';
    }

    if (_battle!.isActive) {
      final dies = _battle!.daysRemaining;
      return '10 casos sorpresa · $dies dies restants';
    }

    return 'Batalla finalitzada';
  }
}
