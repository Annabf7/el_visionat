import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../repositories/designations_repository.dart';
import 'monthly_earnings_chart.dart';
import 'yearly_earnings_chart.dart';

/// Widget que mostra el resum econòmic de les designacions
class EarningsSummaryWidget extends StatefulWidget {
  final bool inRow;

  const EarningsSummaryWidget({super.key, this.inRow = false});

  @override
  State<EarningsSummaryWidget> createState() => _EarningsSummaryWidgetState();
}

class _EarningsSummaryWidgetState extends State<EarningsSummaryWidget> {
  String? expandedCard;  // 'year' o 'total'

  void _toggleExpansion(String cardType) {
    setState(() {
      if (expandedCard == cardType) {
        expandedCard = null;  // Collapse if already expanded
      } else {
        expandedCard = cardType;  // Expand and collapse others
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final repository = DesignationsRepository();
    final now = DateTime.now();

    // Calcular dates per període actual
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final monthStart = DateTime(now.year, now.month, 1, 0, 0, 0);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    // Calcular temporada actual (setembre a juny)
    // Si estem entre gener-juny, la temporada va de setembre de l'any anterior
    // Si estem entre juliol-desembre, la temporada va de setembre d'aquest any
    final int seasonStartYear = now.month >= 9 ? now.year : now.year - 1;
    final seasonStart = DateTime(seasonStartYear, 9, 1, 0, 0, 0);  // 1 setembre
    final seasonEnd = DateTime(seasonStartYear + 1, 6, 30, 23, 59, 59);  // 30 juny

    return Container(
      margin: widget.inRow
          ? EdgeInsets.zero
          : const EdgeInsets.all(16),
      padding: widget.inRow
          ? const EdgeInsets.all(24)
          : const EdgeInsets.all(16),
      constraints: widget.inRow ? const BoxConstraints(minHeight: 400, maxHeight: 400) : null,
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
              SizedBox(width: widget.inRow ? 12 : 8),
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
                    startDate: seasonStart,
                    endDate: seasonEnd,
                  ),
                  builder: (context, snapshot) {
                    return _EarningCard(
                      title: 'Temporada',
                      amount: snapshot.data ?? 0.0,
                      icon: Icons.calendar_view_month_rounded,
                      color: AppTheme.grisPistacho,
                      onTap: () => _toggleExpansion('season'),
                      isExpanded: expandedCard == 'season',
                    );
                  },
                ),
              ),
              SizedBox(width: widget.inRow ? 12 : 8),
              Expanded(
                child: StreamBuilder<double>(
                  stream: repository.getTotalEarningsStream(),
                  builder: (context, snapshot) {
                    return _EarningCard(
                      title: 'Total',
                      amount: snapshot.data ?? 0.0,
                      icon: Icons.account_balance_wallet_rounded,
                      color: AppTheme.mostassa,
                      onTap: () => _toggleExpansion('total'),
                      isExpanded: expandedCard == 'total',
                    );
                  },
                ),
              ),
            ],
          ),
          // Expanded charts
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: expandedCard == 'season'
                ? Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: MonthlyEarningsChart(
                      seasonStartYear: seasonStartYear,
                    ),
                  )
                : expandedCard == 'total'
                    ? const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: YearlyEarningsChart(),
                      )
                    : const SizedBox.shrink(),
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
  final VoidCallback? onTap;
  final bool isExpanded;

  const _EarningCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    this.onTap,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'ca_ES', symbol: '€');
    final isClickable = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isExpanded
                ? color.withValues(alpha: 0.6)
                : AppTheme.lilaMitja.withValues(alpha: 0.25),
            width: isExpanded ? 2.5 : 1.5,
          ),
          boxShadow: isExpanded
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
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
                if (isClickable)
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.textBlackLow.withValues(alpha: 0.5),
                    size: 18,
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
      ),
    );
  }
}