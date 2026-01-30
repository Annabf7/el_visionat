import '../models/designation_model.dart';

/// Servei per calcular tarifes arbitrals segons les taules oficials FCBQ 2025/26
class TariffCalculatorService {
  // Desplaçament mínim garantit
  static const double _minDisplacement = 7.54;

  /// Preu mitjà actual de la benzina Eurosuper 95 a Catalunya (€/litre)
  /// Actualitzar manualment cada 2 mesos segons clickgasoil.com
  /// Última revisió: gener 2026 → 1.453 €/L → rang 1.31-1.50 → 0.30 €/km
  static const double currentFuelPrice = 1.453;

  /// Retorna el preu per km segons el preu actual de la benzina.
  /// Taula oficial FCBQ (Assemblea General 14/06/2025, secció 3.5.4):
  ///   1.31-1.50 €/L → 0.30 €/km
  ///   1.51-1.70 €/L → 0.31 €/km
  ///   1.71-1.90 €/L → 0.32 €/km
  ///   1.91-2.10 €/L → 0.33 €/km
  ///   2.11-2.30 €/L → 0.34 €/km
  ///   2.31-2.50 €/L → 0.35 €/km
  /// Revisió: cada 2 mesos a partir del 01/07
  /// Font: https://www.clickgasoil.com/c/precio-gasolina-95-catalua
  static double get _pricePerKm {
    if (currentFuelPrice <= 1.50) return 0.30;
    if (currentFuelPrice <= 1.70) return 0.31;
    if (currentFuelPrice <= 1.90) return 0.32;
    if (currentFuelPrice <= 2.10) return 0.33;
    if (currentFuelPrice <= 2.30) return 0.34;
    return 0.35;
  }

  /// Calcula els ingressos totals d'una designació
  static EarningsModel calculateEarnings({
    required String category,
    required String role, // "principal" o "auxiliar"
    required double kilometers,
    required DateTime matchDate,
    required String matchTime, // Format "HH:MM"
  }) {
    final rights = _calculateRights(category, role);
    final kilometersAmount = _calculateKilometers(kilometers);
    final allowance = _calculateAllowance(matchDate, matchTime, kilometers);
    final total = rights + kilometersAmount + allowance;

    return EarningsModel(
      rights: rights,
      kilometersAmount: kilometersAmount,
      allowance: allowance,
      total: total,
      kilometerDistance: kilometers,
    );
  }

  /// Calcula els drets d'arbitratge segons categoria i rol.
  /// Tarifes oficials FCBQ temporada 2025/26 (Assemblea General 14/06/2025, secció 3.5.2).
  ///
  /// Estructura: s'usa matching per paraules clau individuals (no substrings composts)
  /// per gestionar correctament variants com "CADET FEMENÍ PREFERENT 1R ANY"
  /// on "FEMENÍ" pot aparèixer entre "CADET" i "PREFERENT".
  static double _calculateRights(String category, String role) {
    // Normalitzar categoria: majúscules i sense espais extra
    String normalizedCategory = category.toUpperCase().trim();

    // Eliminar prefixos comuns (C.T., C.C., C.I., etc.)
    final prefixes = ['C.T.', 'CT.', 'C.C.', 'CC.', 'C.I.', 'CI.', 'C. T.', 'C. C.', 'C. I.'];
    for (final prefix in prefixes) {
      if (normalizedCategory.startsWith(prefix)) {
        normalizedCategory = normalizedCategory.substring(prefix.length).trim();
        break;
      }
    }

    // Eliminar punts després de "1A.", "2A.", "3A.", "1R."
    normalizedCategory = normalizedCategory
        .replaceAll('1A.', '1A')
        .replaceAll('2A.', '2A')
        .replaceAll('3A.', '3A')
        .replaceAll('1R.', '1R');

    final cat = normalizedCategory;
    final isFemeni = cat.contains('FEMEN');

    print('TariffCalculator: "$category" → "$cat" | Rol: $role | Femení: $isFemeni');

    // ── SUPER COPA ──
    if (cat.contains('SUPER COPA')) {
      return isFemeni ? 90.00 : 110.00;
    }

    // ── COPA CATALUNYA ──
    if (cat.contains('COPA CATALUNYA')) {
      return isFemeni ? 74.00 : 95.00;
    }

    // ── 1A CATEGORIA ──
    if (cat.contains('1A CATEGORIA') || cat.contains('PRIMERA CATEGORIA')) {
      return 55.00; // Masc i fem: mateixa tarifa
    }

    // ── 2A CATEGORIA ──
    if (cat.contains('2A CATEGORIA') || cat.contains('SEGONA CATEGORIA')) {
      return 46.00; // Masc i fem: mateixa tarifa
    }

    // ── 1A TERRITORIAL ──
    if (cat.contains('1A TERRITORIAL')) {
      return 44.00; // Masc: principal + auxiliar / Fem: només principal (mateixa tarifa)
    }

    // ── 2A i 3A TERRITORIAL ──
    if (cat.contains('2A TERRITORIAL') || cat.contains('3A TERRITORIAL')) {
      return 40.00;
    }

    // ── SOTS 21 PREFERENT (agrupat amb 1A TERRITORIAL al PDF) ──
    if (cat.contains('SOTS 21') && cat.contains('PREF')) {
      return 44.00;
    }

    // ── SOTS 25 ──
    if (cat.contains('SOTS 25')) {
      return 40.00;
    }

    // ── SOTS 20 ──
    if (cat.contains('SOTS 20')) {
      if (cat.contains('NIVELL B')) return 32.00;
      // NIVELL A1, NIVELL A2, N. A1 o genèric → 40.00
      return 40.00;
    }

    // ── JÚNIOR ──
    // Comprova NIVELL i 1R ANY / INTERTERRITORIAL ABANS de PREFERENT genèric
    if (cat.contains('JÚNIOR') || cat.contains('JUNIOR')) {
      if (cat.contains('NIVELL C')) return 29.00;
      if (cat.contains('NIVELL B')) return isFemeni ? 29.00 : 35.00;
      if (cat.contains('NIVELL A')) return 35.00;
      if (cat.contains('INTERTERRITORIAL')) return 40.00;
      if (cat.contains('PREFERENT')) {
        if (cat.contains('1R ANY')) return 40.00;
        return 52.00;
      }
      return 35.00; // Júnior genèric
    }

    // ── CADET ──
    // Comprova PROMOCIÓ, INTERTERRITORIAL i 1R ANY ABANS de PREFERENT genèric
    if (cat.contains('CADET')) {
      if (cat.contains('PROMOCIÓ')) return 24.00;
      if (cat.contains('INTERTERRITORIAL')) return 27.00;
      if (cat.contains('PREFERENT')) {
        if (cat.contains('1R ANY')) return 27.00;
        return 35.00;
      }
      return 24.00; // Cadet genèric
    }

    // ── PREINFANTIL (abans d'INFANTIL per evitar match de substring) ──
    if (cat.contains('PREINFANTIL') || cat.contains('PRE-INFANTIL') ||
        cat.contains('PRE INFANTIL')) {
      return 22.00;
    }

    // ── INFANTIL ──
    if (cat.contains('INFANTIL')) {
      if (cat.contains('PROMOCIÓ')) return 22.00;
      if (cat.contains('INTERTERRITORIAL')) return 22.00;
      if (cat.contains('PREFERENT')) {
        if (cat.contains('1R ANY')) return 22.00;
        return 25.00;
      }
      return 22.00; // Infantil genèric
    }

    // ── PREMINI (abans de MINI per evitar match de substring) ──
    if (cat.contains('PREMINI') || cat.contains('PRE-MINI') ||
        cat.contains('PRE MINI')) {
      return 22.00;
    }

    // ── MINI ──
    if (cat.contains('MINI')) {
      return 22.00; // MINI A1 o genèric
    }

    // ── ESCOBOL ──
    if (cat.contains('ESCOBOL')) {
      return 15.00;
    }

    // Categoria no reconeguda
    print('TariffCalculator: ⚠️ Categoria no reconeguda: "$cat"');
    return 0.0;
  }

  /// Calcula el cost de quilometratge
  static double _calculateKilometers(double km) {
    if (km <= 0) return 0.0;
    final amount = km * _pricePerKm;
    return amount < _minDisplacement ? _minDisplacement : amount;
  }

  /// Calcula les dietes segons horari i quilometratge
  static double _calculateAllowance(
    DateTime matchDate,
    String matchTime,
    double kilometers,
  ) {
    final time = _parseTime(matchTime);
    if (time == null) return 0.0;

    final hour = time.hour;
    final minute = time.minute;
    final isWeekend = matchDate.weekday == DateTime.saturday ||
                      matchDate.weekday == DateTime.sunday;

    // Dietes de cap de setmana
    if (isWeekend) {
      // Abans de les 08:30
      if (hour < 8 || (hour == 8 && minute < 30)) {
        return 20.00;
      }
      // Entre 13:46 i 15:29
      if ((hour == 13 && minute >= 46) ||
          (hour == 14) ||
          (hour == 15 && minute <= 29)) {
        return 20.00;
      }
      // Entre 12:00 i 16:30 amb més de 90km
      if (hour >= 12 && hour <= 16 && kilometers >= 90) {
        return 25.00;
      }
      // A partir de 20:00 amb més de 90km
      if (hour >= 20 && kilometers >= 90) {
        return 25.00;
      }
      // A partir de 20:30 amb més de 40km
      if ((hour == 20 && minute >= 30) || hour > 20) {
        if (kilometers >= 40) return 25.00;
      }
      // A partir de 21:20 amb més de 130km
      if ((hour == 21 && minute >= 20) || hour > 21) {
        if (kilometers >= 130) return 25.00;
      }
    } else {
      // Dietes entre setmana
      // Excepció: més de 90km sempre 25€
      if (kilometers >= 90) {
        return 25.00;
      }
      // Altres casos: 20€
      return 20.00;
    }

    return 0.0;
  }

  /// Parse time string "HH:MM" to DateTime
  static DateTime? _parseTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length != 2) return null;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return DateTime(2000, 1, 1, hour, minute);
    } catch (e) {
      return null;
    }
  }
}