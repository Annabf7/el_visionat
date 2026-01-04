import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/theme/app_theme.dart';

/// Gràfica amb els ingressos anuals (comparativa per anys)
class YearlyEarningsChart extends StatelessWidget {
  final String? selectedCategory;  // Filtre per categoria (opcional)

  const YearlyEarningsChart({
    super.key,
    this.selectedCategory,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<int, double>>(
      stream: _getYearlyEarningsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.mostassa),
          );
        }

        final yearlyData = snapshot.data ?? {};
        final hasData = yearlyData.values.any((amount) => amount > 0);

        if (!hasData) {
          return _buildEmptyState();
        }

        // Ordenar anys
        final sortedYears = yearlyData.keys.toList()..sort();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Títol
            const Text(
              'Evolució anual',
              style: TextStyle(
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
                  maxY: _calculateMaxY(yearlyData),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final year = sortedYears[group.x.toInt()];
                        final amount = rod.toY;
                        return BarTooltipItem(
                          '$year\n${NumberFormat.currency(locale: 'ca_ES', symbol: '€').format(amount)}',
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
                          if (value.toInt() < 0 || value.toInt() >= sortedYears.length) {
                            return const SizedBox();
                          }
                          final year = sortedYears[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              year.toString(),
                              style: TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 12,
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
                    horizontalInterval: _calculateMaxY(yearlyData) / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppTheme.grisPistacho.withValues(alpha: 0.3),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(sortedYears.length, (index) {
                    final year = sortedYears[index];
                    final amount = yearlyData[year] ?? 0.0;
                    final isCurrentYear = year == DateTime.now().year;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: amount,
                          color: isCurrentYear ? AppTheme.mostassa : AppTheme.lilaMitja,
                          width: sortedYears.length <= 3 ? 40 : 30,
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
                _buildLegendItem('Any actual', AppTheme.mostassa),
                const SizedBox(width: 16),
                _buildLegendItem('Altres anys', AppTheme.lilaMitja),
              ],
            ),

            const SizedBox(height: 20),

            // Estadístiques addicionals
            _buildStats(yearlyData, sortedYears),
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

  Widget _buildStats(Map<int, double> yearlyData, List<int> sortedYears) {
    if (sortedYears.length < 2) return const SizedBox();

    final currentYear = sortedYears.last;
    final previousYear = sortedYears[sortedYears.length - 2];
    final currentAmount = yearlyData[currentYear] ?? 0.0;
    final previousAmount = yearlyData[previousYear] ?? 0.0;

    double growthPercentage = 0;
    if (previousAmount > 0) {
      growthPercentage = ((currentAmount - previousAmount) / previousAmount) * 100;
    }

    final isPositive = growthPercentage >= 0;
    final formatter = NumberFormat.currency(locale: 'ca_ES', symbol: '€');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.grisPistacho.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.grisPistacho.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comparativa amb l\'any anterior',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textBlackLow.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    previousYear.toString(),
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textBlackLow.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatter.format(previousAmount),
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.lilaMitja,
                    ),
                  ),
                ],
              ),
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: isPositive ? Colors.green : Colors.red,
                size: 32,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currentYear.toString(),
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textBlackLow.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatter.format(currentAmount),
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.mostassa,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '${isPositive ? '+' : ''}${growthPercentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
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
              'Sense dades històriques',
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

  /// Obté els ingressos anuals de tots els anys
  Stream<Map<int, double>> _getYearlyEarningsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value({});

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('designations');

    // Aplicar filtre per categoria si està especificat
    if (selectedCategory != null) {
      query = query.where('category', isEqualTo: selectedCategory);
    }

    return query.snapshots().map((snapshot) {
      final Map<int, double> yearlyEarnings = {};

      // Sumar els ingressos per any
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = data['date'] as Timestamp?;
        final earnings = data['earnings'] as Map<String, dynamic>?;
        final total = (earnings?['total'] as num?)?.toDouble() ?? 0.0;

        if (timestamp != null) {
          final date = timestamp.toDate();
          final year = date.year;
          yearlyEarnings[year] = (yearlyEarnings[year] ?? 0.0) + total;
        }
      }

      return yearlyEarnings;
    });
  }

  double _calculateMaxY(Map<int, double> data) {
    if (data.isEmpty) return 1000;
    final maxValue = data.values.reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) return 1000;
    // Arrodonir cap amunt
    final magnitude = ((maxValue / 100).ceil() * 100).toDouble();
    return magnitude * 1.2; // +20% d'espai superior
  }
}