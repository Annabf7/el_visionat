import 'package:flutter/material.dart';
import 'package:el_visionat/core/theme/app_theme.dart';
import '../models/monthly_battle.dart';
import '../pages/monthly_battle_page.dart';
import '../services/monthly_battle_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:el_visionat/features/laboratori_arbitral/widgets/laboratori_section_card.dart';

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
    final badge = _getBadge();

    return LaboratoriSectionCard(
      title: 'Batalla mensual',
      subtitle: subtitle,
      badge: badge,
      icon: Icons.emoji_events,
      color: AppTheme.lilaMitja,
      textColor: AppTheme.porpraFosc,
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MonthlyBattlePage()));
      },
    );
  }

  String _getBadge() {
    if (_isLoading || _battle == null) return '...';
    if (_userResult != null) {
      if (_userPosition != null) return '#$_userPosition';
      return '${_userResult!.score}/10';
    }
    if (_battle!.isActive) return 'OBERT';
    return 'TANCAT';
  }

  String _getSubtitle() {
    if (_isLoading) return 'Carregant dades...';
    if (_battle == null) return 'Pròximament...';

    if (_userResult != null) {
      return 'Rànquing complet disponible';
    }

    if (_battle!.isActive) {
      final dies = _battle!.daysRemaining;
      return '10 preguntes · $dies dies';
    }

    return 'Batalla finalitzada';
  }
}
