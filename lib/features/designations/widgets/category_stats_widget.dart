import 'dart:ui' show PointerDeviceKind;

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
      padding: inRow
          ? const EdgeInsets.all(24)
          : const EdgeInsets.all(16),
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

              final sortedEntries = stats.entries.toList()
                ..sort((a, b) {
                  // Ordenar per jerarquia de categoria (de més important a menys)
                  final priorityA = _getCategoryPriority(a.key);
                  final priorityB = _getCategoryPriority(b.key);
                  return priorityA.compareTo(priorityB);
                });

              return Column(
                children: [
                  // Gràfic de barres (scrollable horitzontalment amb suport desktop)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final minWidth = sortedEntries.length * 65.0;
                      final chartWidth = minWidth > constraints.maxWidth
                          ? minWidth
                          : constraints.maxWidth;

                      Widget chart = SizedBox(
                        height: 280,
                        width: chartWidth,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: sortedEntries.first.value.toDouble() * 1.2,
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                fitInsideVertically: true,
                                fitInsideHorizontally: true,
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  // Tooltip mostra nom complet
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
                                  reservedSize: 90,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() >= sortedEntries.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final category = sortedEntries[value.toInt()].key;
                                    return SideTitleWidget(
                                      axisSide: AxisSide.bottom,
                                      angle: -0.7,
                                      space: 20,
                                      child: Text(
                                        _abbreviateCategory(category),
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.porpraFosc,
                                        ),
                                        maxLines: 1,
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
                      );

                      // Scroll horitzontal si hi ha massa categories
                      final needsScroll = minWidth > constraints.maxWidth;
                      if (needsScroll) {
                        chart = SizedBox(
                          height: 280,
                          child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(
                              dragDevices: {
                                PointerDeviceKind.touch,
                                PointerDeviceKind.mouse,
                              },
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: chart,
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          chart,
                          if (needsScroll)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.swipe,
                                    size: 14,
                                    color: AppTheme.grisBody.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Llisca per veure més categories',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.grisBody.withValues(alpha: 0.6),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
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

  /// Retorna la prioritat d'una categoria segons la jerarquia oficial FCBQ.
  /// Usa matching per paraules clau individuals (no substrings compostos)
  /// per gestionar variants amb gènere intercalat (ex: "JÚNIOR MASCULÍ INTERTERRITORIAL").
  int _getCategoryPriority(String category) {
    String upper = category.trim().toUpperCase().replaceAll('-', ' ');

    // Treure prefixos (C.T., C.C., C.I. i variants)
    upper = upper.replaceFirst(RegExp(r'^C\.?\s*[TCI]\.?\s*'), '').trim();

    // Normalitzar punts d'ordinals (1A. → 1A, 2A. → 2A, etc.)
    upper = upper
        .replaceAll('1A.', '1A')
        .replaceAll('2A.', '2A')
        .replaceAll('3A.', '3A')
        .replaceAll('1R.', '1R');

    // 1. SUPER COPA
    if (upper.contains('SUPER COPA')) return 1;
    // 2. COPA CATALUNYA
    if (upper.contains('COPA CATALUNYA')) return 2;
    // 3. PRIMERA CATEGORIA
    if (upper.contains('PRIMERA CATEGORIA') || upper.contains('1A CATEGORIA')) return 3;
    // 4. SEGONA CATEGORIA
    if (upper.contains('SEGONA CATEGORIA') || upper.contains('2A CATEGORIA')) return 4;
    // 5. 1A TERRITORIAL
    if (upper.contains('1A TERRITORIAL')) return 5;
    // 6. 2A TERRITORIAL
    if (upper.contains('2A TERRITORIAL')) return 6;
    // 7. 3A TERRITORIAL
    if (upper.contains('3A TERRITORIAL')) return 7;

    // 8-11. SOTS
    if (upper.contains('SOTS 21') && upper.contains('PREF')) return 8;
    if (upper.contains('SOTS 20')) {
      if (upper.contains('PREF')) return 8;
      if (upper.contains('NIVELL A') || upper.contains('N. A')) return 10;
      if (upper.contains('NIVELL B') || upper.contains('N. B')) return 11;
      return 10;
    }
    if (upper.contains('SOTS 25')) return 9;

    // 12-17. JÚNIOR
    if (upper.contains('JÚNIOR') || upper.contains('JUNIOR')) {
      if (upper.contains('PREFERENT')) {
        if (upper.contains('1R ANY')) return 13;
        return 12;
      }
      if (upper.contains('INTERTERRITORIAL')) return 14;
      if (upper.contains('NIVELL A')) return 15;
      if (upper.contains('NIVELL B')) return 16;
      if (upper.contains('NIVELL C')) return 17;
      return 15;
    }

    // 18/31. 3X3
    if (upper.contains('3X3') || upper.contains('3 X 3')) {
      if (upper.contains('NO PROMO')) return 18;
      if (upper.contains('PROMO')) return 31;
      return 18;
    }

    // 19-22. CADET
    if (upper.contains('CADET')) {
      if (upper.contains('PREFERENT')) {
        if (upper.contains('1R ANY')) return 20;
        return 19;
      }
      if (upper.contains('INTERTERRITORIAL')) return 21;
      if (upper.contains('PROMOCIÓ') || upper.contains('PROMOCI')) return 22;
      return 22;
    }

    // 27. PREINFANTIL (comprovar ABANS d'INFANTIL)
    if (upper.contains('PREINFANTIL') || upper.contains('PRE INFANTIL')) return 27;

    // 23-26. INFANTIL
    if (upper.contains('INFANTIL')) {
      if (upper.contains('PREFERENT')) {
        if (upper.contains('1R ANY')) return 25;
        return 23;
      }
      if (upper.contains('INTERTERRITORIAL')) return 24;
      return 26;
    }

    // 29. PREMINI (comprovar ABANS de MINI)
    if (upper.contains('PREMINI') || upper.contains('PRE MINI')) return 29;
    // 28. MINI
    if (upper.contains('MINI')) return 28;

    // 30. ESCOBOL
    if (upper.contains('ESCOBOL')) return 30;

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

  /// Abrevia el nom de la categoria per mostrar a l'eix X del gràfic.
  /// Ex: "C.C. PRIMERA CATEGORIA MASCULINA" → "1Cat. Masc."
  /// Ex: "C.T. 1A TERRITORIAL SÈNIOR MASCULÍ" → "1a Terr. Masc."
  /// Ex: "C.C. JÚNIOR MASCULÍ INTERTERRITORIAL" → "Júnior Masc. Inter."
  String _abbreviateCategory(String category) {
    String upper = category.trim().toUpperCase();

    // Treure prefixos (C.T., C.C., C.I. i variants)
    upper = upper.replaceFirst(RegExp(r'^C\.?\s*[TCI]\.?\s*'), '').trim();

    // Normalitzar guions (SOTS-25 → SOTS 25) i punts d'ordinals (1A. → 1A)
    final norm = upper
        .replaceAll('-', ' ')
        .replaceAll('1A.', '1A')
        .replaceAll('2A.', '2A')
        .replaceAll('3A.', '3A')
        .replaceAll('1R.', '1R');

    // Detectar gènere
    String gender = '';
    if (norm.contains('MASCULIN') || norm.contains('MASCULÍ')) {
      gender = 'Masc.';
    } else if (norm.contains('FEMEN')) {
      gender = 'Fem.';
    }

    // Detectar base de categoria
    String base;
    if (norm.contains('SUPER COPA')) {
      base = 'S. Copa';
    } else if (norm.contains('COPA CATALUNYA')) {
      base = 'Copa Cat.';
    } else if (norm.contains('PRIMERA CATEGORIA') || norm.contains('1A CATEGORIA')) {
      base = '1Cat.';
    } else if (norm.contains('SEGONA CATEGORIA') || norm.contains('2A CATEGORIA')) {
      base = '2Cat.';
    } else if (norm.contains('3A TERRITORIAL')) {
      base = '3a Terr.';
    } else if (norm.contains('2A TERRITORIAL')) {
      base = '2a Terr.';
    } else if (norm.contains('1A TERRITORIAL')) {
      base = '1a Terr.';
    } else if (norm.contains('SOTS 25')) {
      base = 'Sots 25';
    } else if (norm.contains('SOTS 21')) {
      base = 'Sots 21';
    } else if (norm.contains('SOTS 20')) {
      base = 'Sots 20';
    } else if (norm.contains('3X3') || norm.contains('3 X 3')) {
      base = '3x3';
    } else if (norm.contains('PREINFANTIL') || norm.contains('PRE INFANTIL')) {
      base = 'Pre-Inf.';
    } else if (norm.contains('PREMINI') || norm.contains('PRE MINI')) {
      base = 'Pre-Mini';
    } else if (norm.contains('JÚNIOR') || norm.contains('JUNIOR')) {
      base = 'Júnior';
    } else if (norm.contains('CADET')) {
      base = 'Cadet';
    } else if (norm.contains('INFANTIL')) {
      base = 'Infantil';
    } else if (norm.contains('MINI')) {
      base = 'Mini';
    } else if (norm.contains('ESCOBOL')) {
      base = 'Escobol';
    } else {
      return category;
    }

    // Construir resultat: Base + Gènere + Qualificador
    final parts = <String>[base];
    if (gender.isNotEmpty) parts.add(gender);

    // Qualificadors (mútuament excloents excepte nivell)
    if (norm.contains('PREFERENT')) {
      parts.add('Pref.');
      if (norm.contains('1R ANY') || norm.contains('1R. ANY')) {
        parts.add('1r');
      }
    } else if (norm.contains('INTERTERRITORIAL')) {
      parts.add('Inter.');
    } else if (norm.contains('NO PROMO')) {
      // 3X3 NO PROMOCIÓ: sense qualificador extra
    } else if (norm.contains('PROMOCIÓ') || norm.contains('PROMOCI')) {
      parts.add('Promo.');
    }

    // Nivell (independent del qualificador anterior)
    if (norm.contains('NIVELL A') || norm.contains('N. A')) {
      parts.add('A');
    } else if (norm.contains('NIVELL B') || norm.contains('N. B')) {
      parts.add('B');
    } else if (norm.contains('NIVELL C')) {
      parts.add('C');
    }

    return parts.join(' ');
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
          color: AppTheme.grisPistacho.withValues(alpha: 0.35),
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