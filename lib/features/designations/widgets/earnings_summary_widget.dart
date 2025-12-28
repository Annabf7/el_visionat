import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../repositories/designations_repository.dart';

/// Widget que mostra el resum econòmic de les designacions
class EarningsSummaryWidget extends StatelessWidget {
  final bool inRow;

  const EarningsSummaryWidget({super.key, this.inRow = false});

  @override
  Widget build(BuildContext context) {
    final repository = DesignationsRepository();
    final now = DateTime.now();

    // Calcular dates per període actual
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final yearStart = DateTime(now.year, 1, 1);
    final yearEnd = DateTime(now.year, 12, 31, 23, 59, 59);

    return Container(
      margin: inRow
          ? EdgeInsets.zero
          : const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      constraints: inRow ? const BoxConstraints(minHeight: 400, maxHeight: 400) : null,
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.grisBody.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.euro_rounded,
                  color: Colors.black,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Resum econòmic',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.porpraFosc,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: StreamBuilder<double>(
                  stream: repository.getTotalEarningsStream(
                    startDate: weekStart,
                    endDate: weekEnd,
                  ),
                  builder: (context, snapshot) {
                    return _EarningCard(
                      title: 'Setmana',
                      amount: snapshot.data ?? 0.0,
                      icon: Icons.calendar_today_rounded,
                      color: AppTheme.lilaMitja,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StreamBuilder<double>(
                  stream: repository.getTotalEarningsStream(
                    startDate: monthStart,
                    endDate: monthEnd,
                  ),
                  builder: (context, snapshot) {
                    return _EarningCard(
                      title: 'Mes',
                      amount: snapshot.data ?? 0.0,
                      icon: Icons.event_rounded,
                      color: AppTheme.lilaClar,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StreamBuilder<double>(
                  stream: repository.getTotalEarningsStream(
                    startDate: yearStart,
                    endDate: yearEnd,
                  ),
                  builder: (context, snapshot) {
                    return _EarningCard(
                      title: 'Any',
                      amount: snapshot.data ?? 0.0,
                      icon: Icons.calendar_view_month_rounded,
                      color: AppTheme.grisPistacho,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StreamBuilder<double>(
                  stream: repository.getTotalEarningsStream(),
                  builder: (context, snapshot) {
                    return _EarningCard(
                      title: 'Total',
                      amount: snapshot.data ?? 0.0,
                      icon: Icons.account_balance_wallet_rounded,
                      color: AppTheme.mostassa,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }
}

class _EarningCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const _EarningCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'ca_ES', symbol: '€');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.lilaMitja.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.lilaMitja.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.lilaMitja, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textBlackLow,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            formatter.format(amount),
            style: TextStyle(
              color: AppTheme.lilaMitja,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}