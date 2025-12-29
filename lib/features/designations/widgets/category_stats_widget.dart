import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/theme/app_theme.dart';
import '../repositories/designations_repository.dart';

/// Widget que mostra estadístiques per categoria
class CategoryStatsWidget extends StatelessWidget {
  final bool inRow;

  const CategoryStatsWidget({super.key, this.inRow = false});

  @override
  Widget build(BuildContext context) {
    final repository = DesignationsRepository();

    return Container(
      margin: inRow
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16),
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
                  color: AppTheme.lilaClar.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.bar_chart_rounded,
                  color: AppTheme.lilaMitja,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Estadístiques per categoria',
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
          StreamBuilder<Map<String, int>>(
            stream: repository.getCategoryStatsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'Encara no hi ha dades estadístiques',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }

              final stats = snapshot.data!;

              // Debug: mostrar categories i prioritats
              for (final entry in stats.entries) {
                print('Category: "${entry.key}" -> Priority: ${_getCategoryPriority(entry.key)}');
              }

              final sortedEntries = stats.entries.toList()
                ..sort((a, b) {
                  // Ordenar per jerarquia de categoria (de més important a menys)
                  final priorityA = _getCategoryPriority(a.key);
                  final priorityB = _getCategoryPriority(b.key);
                  return priorityA.compareTo(priorityB);
                });

              return Column(
                children: [
                  // Gràfic de barres
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: sortedEntries.first.value.toDouble() * 1.2,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${sortedEntries[group.x.toInt()].key}\n${rod.toY.toInt()} partits',
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
                              reservedSize: 50,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= sortedEntries.length) {
                                  return const SizedBox.shrink();
                                }
                                final category = sortedEntries[value.toInt()].key;
                                // Escurçar el nom si és massa llarg
                                final shortName = category.length > 15
                                    ? '${category.substring(0, 12)}...'
                                    : category;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    shortName,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.porpraFosc,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.porpraFosc,
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 1,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: AppTheme.porpraFosc.withValues(alpha: 0.15),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(
                          sortedEntries.length,
                          (index) => BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: sortedEntries[index].value.toDouble(),
                                color: _getColorForIndex(index),
                                width: 24,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(6),
                                  topRight: Radius.circular(6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Llista de categories
                  ...sortedEntries.map((entry) {
                    final index = sortedEntries.indexOf(entry);
                    return _CategoryStatItem(
                      category: entry.key,
                      count: entry.value,
                      color: _getColorForIndex(index),
                    );
                  }),
                ],
              );
            },
          ),
        ],
        ),
      ),
    );
  }

  /// Retorna la prioritat d'una categoria segons la jerarquia oficial
  /// Números més baixos = més prioritat (apareixen primer a l'esquerra)
  int _getCategoryPriority(String category) {
    // Normalitzar la categoria per comparació (sense espais extra, majúscules/minúscules)
    final normalized = category.trim().toUpperCase();

    // Jerarquia oficial de categories (de més important a menys)
    final priorities = {
      // Lligues professionals
      'ACB': 1,
      'PRIMERA FEB': 2,
      'LLIGA FEMENINA': 3,
      'FEMENINA CHALLENGE': 4,
      'SEGONA FEB': 5,
      'FEMENINA 2': 6,
      'TERCERA FEB': 7,

      // Copes i tornejos
      'SUPER COPA': 8,
      'COPA CATALUNYA': 9,

      // Categories territorials
      'PRIMERA CATEGORIA': 10,
      '1A CATEGORIA': 10,
      'SEGONA CATEGORIA': 11,
      '2A CATEGORIA': 11,
      'TERRITORIAL SÈNIOR': 12,
      '1A TERRITORIAL': 12,
      '1A. TERRITORIAL': 12,
      '2A I 3A TERRITORIAL': 13,
      '2A TERRITORIAL': 13,
      '3A TERRITORIAL': 13,

      // Categories de base
      'SOTS 25': 14,
      'SOTS 20 PREFERENT': 15,
      'SOTS 20 NIVELL A': 16,
      'SOTS 20 NIVELL B': 17,
      'JÚNIOR PREFERENT': 18,
      'JUNIOR PREFERENT': 18,
      'JÚNIOR PREFERENT 1R ANY': 19,
      'JUNIOR PREFERENT 1R ANY': 19,
      'JÚNIOR INTERTERRITORIAL': 20,
      'JUNIOR INTERTERRITORIAL': 20,
      'JÚNIOR NIVELL A': 21,
      'JUNIOR NIVELL A': 21,
      'JÚNIOR NIVELL B': 22,
      'JUNIOR NIVELL B': 22,
      'JÚNIOR NIVELL C': 23,
      'JUNIOR NIVELL C': 23,
      'CADET PREFERENT': 24,
      'CADET PREFERENT 1R ANY': 25,
      'CADET INTERTERRITORIAL': 26,
      'CADET PROMOCIÓ': 27,
      'CADET MASCULÍ PROMOCIÓ': 27, // Variant amb masculí/femení
      'CADET FEMENÍ PROMOCIÓ': 27,
      'INFANTIL PREFERENT': 28,
      'INFANTIL PREFERENT 1R ANY': 29,
      'INFANTIL INTERTERRITORIAL': 30,
      'INFANTIL': 31,
      'PREINFANTIL': 31,
      'PRE-INFANTIL': 31, // Amb guió
      'MINI': 32,
      'PREMINI': 32,
      'PRE-MINI': 32, // Amb guió
      'ESCOBOL': 33,
      '3X3 NO PROMOCIÓ': 34,
      '3X3 PROMOCIÓ': 35,
    };

    // Buscar coincidència exacta o parcial (ordenat per claus més llargues primer)
    final sortedPriorities = priorities.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));

    for (final entry in sortedPriorities) {
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
    }

    // Si no es troba, assignar una prioritat baixa (al final)
    return 999;
  }

  Color _getColorForIndex(int index) {
    final colors = [
      AppTheme.lilaMitja,
      AppTheme.mostassa,
      AppTheme.lilaClar,
      AppTheme.grisPistacho,
      AppTheme.porpraFosc,
      AppTheme.grisBody,
    ];
    return colors[index % colors.length];
  }
}

class _CategoryStatItem extends StatelessWidget {
  final String category;
  final int count;
  final Color color;

  const _CategoryStatItem({
    required this.category,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.grisPistacho.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category,
              style: TextStyle(
                color: AppTheme.textBlackLow,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}