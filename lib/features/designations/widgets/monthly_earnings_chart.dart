import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/theme/app_theme.dart';

/// Gràfica amb els ingressos mensuals de la temporada (setembre-juny)
class MonthlyEarningsChart extends StatelessWidget {
  final int seasonStartYear;  // Any d'inici de la temporada (ex: 2024 per temporada 2024-2025)
  final String? selectedCategory;  // Filtre per categoria (opcional)

  const MonthlyEarningsChart({
    super.key,
    required this.seasonStartYear,
    this.selectedCategory,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<int, double>>(
      stream: _getMonthlyEarningsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.mostassa),
          );
        }

        final monthlyData = snapshot.data ?? {};
        final hasData = monthlyData.values.any((amount) => amount > 0);

        if (!hasData) {
          return _buildEmptyState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Títol
            Text(
              'Temporada $seasonStartYear-${seasonStartYear + 1}',
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.porpraFosc,
              ),
            ),
            if (selectedCategory != null) ...[
              const SizedBox(height: 4),
              Text(
                'Categoria: $selectedCategory',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textBlackLow.withValues(alpha: 0.7),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Gràfica
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _calculateMaxY(monthlyData),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final months = [9, 10, 11, 12, 1, 2, 3, 4, 5, 6];
                        final month = months[group.x.toInt()];
                        final monthName = _getMonthName(month);
                        final amount = rod.toY;
                        return BarTooltipItem(
                          '$monthName\n${NumberFormat.currency(locale: 'ca_ES', symbol: '€').format(amount)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final months = [9, 10, 11, 12, 1, 2, 3, 4, 5, 6];
                          if (value.toInt() < 0 || value.toInt() >= months.length) {
                            return const SizedBox();
                          }
                          final month = months[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _getMonthAbbr(month),
                              style: TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textBlackLow.withValues(alpha: 0.7),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}€',
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textBlackLow.withValues(alpha: 0.6),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _calculateMaxY(monthlyData) / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppTheme.grisPistacho.withValues(alpha: 0.3),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(10, (index) {
                    // Mesos de la temporada: Set, Oct, Nov, Des, Gen, Feb, Mar, Abr, Mai, Jun
                    final months = [9, 10, 11, 12, 1, 2, 3, 4, 5, 6];
                    final month = months[index];
                    final amount = monthlyData[month] ?? 0.0;

                    // Determinar si és el mes actual
                    final now = DateTime.now();
                    final monthYear = month >= 9 ? seasonStartYear : seasonStartYear + 1;
                    final isCurrentMonth = month == now.month && monthYear == now.year;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: amount,
                          color: isCurrentMonth ? AppTheme.mostassa : AppTheme.lilaMitja,
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Llegenda
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Mes actual', AppTheme.mostassa),
                const SizedBox(width: 16),
                _buildLegendItem('Altres mesos', AppTheme.lilaMitja),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.textBlackLow.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 48,
              color: AppTheme.textBlackLow.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'Sense dades per aquesta temporada',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textBlackLow.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Obté els ingressos mensuals de la temporada (setembre a juny)
  Stream<Map<int, double>> _getMonthlyEarningsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value({});

    // Temporada: setembre a juny (ex: set 2024 - juny 2025)
    final seasonStart = DateTime(seasonStartYear, 9, 1, 0, 0, 0);
    final seasonEnd = DateTime(seasonStartYear + 1, 6, 30, 23, 59, 59);

    var query = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('designations')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(seasonStart))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(seasonEnd));

    // Aplicar filtre per categoria si està especificat
    if (selectedCategory != null) {
      query = query.where('category', isEqualTo: selectedCategory);
    }

    return query.snapshots().map((snapshot) {
      final Map<int, double> monthlyEarnings = {};

      // Inicialitzar mesos de la temporada (set=9 a juny=6 de l'any següent)
      // Usarem claus: 9, 10, 11, 12 (any inicial), 1, 2, 3, 4, 5, 6 (any següent)
      for (int i = 9; i <= 12; i++) {
        monthlyEarnings[i] = 0.0;
      }
      for (int i = 1; i <= 6; i++) {
        monthlyEarnings[i] = 0.0;
      }

      // Sumar els ingressos per mes
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = data['date'] as Timestamp?;
        final earnings = data['earnings'] as Map<String, dynamic>?;
        final total = (earnings?['total'] as num?)?.toDouble() ?? 0.0;

        if (timestamp != null) {
          final date = timestamp.toDate();
          final month = date.month;
          monthlyEarnings[month] = (monthlyEarnings[month] ?? 0.0) + total;
        }
      }

      return monthlyEarnings;
    });
  }

  double _calculateMaxY(Map<int, double> data) {
    if (data.isEmpty) return 100;
    final maxValue = data.values.reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) return 100;
    // Arrodonir cap amunt a la desena/centena més propera
    final magnitude = (maxValue / 10).ceil() * 10;
    return magnitude.toDouble() * 1.2; // +20% d'espai superior
  }

  String _getMonthName(int month) {
    const months = [
      'Gener', 'Febrer', 'Març', 'Abril', 'Maig', 'Juny',
      'Juliol', 'Agost', 'Setembre', 'Octubre', 'Novembre', 'Desembre'
    ];
    return months[month - 1];
  }

  String _getMonthAbbr(int month) {
    const abbr = [
      'Gen', 'Feb', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Oct', 'Nov', 'Des'
    ];
    return abbr[month - 1];
  }
}