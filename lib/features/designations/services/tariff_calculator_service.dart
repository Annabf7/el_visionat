import '../models/designation_model.dart';

/// Servei per calcular tarifes arbitrals segons les taules oficials FCBQ 2025/26
class TariffCalculatorService {
  // Preu per quilòmetre (actualitzable segons preu gasolina)
  static const double _pricePerKm = 0.32; // Actualitzar segons taula oficial
  static const double _minDisplacement = 7.54;

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
    );
  }

  /// Calcula els drets d'arbitratge segons categoria i rol
  static double _calculateRights(String category, String role) {
    // Normalitzar categoria: eliminar prefixos com "C.T.", "C.C.", "C.I.", etc.
    String normalizedCategory = category.toUpperCase().trim();

    // Eliminar prefixos comuns
    final prefixes = ['C.T.', 'CT.', 'C.C.', 'CC.', 'C.I.', 'CI.', 'C. T.', 'C. C.', 'C. I.'];
    for (final prefix in prefixes) {
      if (normalizedCategory.startsWith(prefix)) {
        normalizedCategory = normalizedCategory.substring(prefix.length).trim();
        print('TariffCalculator: Removed prefix "$prefix" from category');
        break;
      }
    }

    // Eliminar punts després de "1A.", "2A.", "3A."
    normalizedCategory = normalizedCategory
        .replaceAll('1A.', '1A')
        .replaceAll('2A.', '2A')
        .replaceAll('3A.', '3A');

    final cat = normalizedCategory;
    final isPrincipal = role.toLowerCase() == 'principal';

    print('TariffCalculator: Original category: "$category"');
    print('TariffCalculator: Normalized category: "$cat"');
    print('TariffCalculator: Role: "$role" (isPrincipal: $isPrincipal)');

    // Masculins
    if (cat.contains('SUPER COPA') && cat.contains('MASCULÍ')) {
      return isPrincipal ? 110.00 : 110.00;
    }
    if (cat.contains('COPA CATALUNYA') && cat.contains('MASCULÍ')) {
      return isPrincipal ? 95.00 : 95.00;
    }
    if (cat.contains('1A CATEGORIA') || cat.contains('PRIMERA CATEGORIA')) {
      return isPrincipal ? 55.00 : 55.00;
    }
    if (cat.contains('2A CATEGORIA') || cat.contains('SEGONA CATEGORIA')) {
      return isPrincipal ? 46.00 : 46.00;
    }
    if (cat.contains('1A TERRITORIAL') && cat.contains('MASCULÍ')) {
      return isPrincipal ? 44.00 : 44.00;
    }
    if ((cat.contains('2A TERRITORIAL') || cat.contains('3A TERRITORIAL')) &&
        cat.contains('MASCULÍ')) {
      return 40.00; // Només àrbitre principal
    }
    if (cat.contains('SOTS 25') || cat.contains('SOTS 20 N. A1')) {
      return 40.00; // Només àrbitre principal
    }
    if (cat.contains('SOTS 20 NIVELL A2')) {
      return isPrincipal ? 40.00 : 40.00;
    }
    if (cat.contains('SOTS 20 NIVELL B')) {
      return 32.00; // Només àrbitre principal
    }
    if (cat.contains('JÚNIOR PREFERENT') || cat.contains('JUNIOR PREFERENT')) {
      return isPrincipal ? 52.00 : 52.00;
    }
    if ((cat.contains('JÚNIOR PREFERENT 1R ANY') ||
         cat.contains('JÚNIOR INTERTERRITORIAL') ||
         cat.contains('JUNIOR INTERTERRITORIAL')) &&
        cat.contains('MASCULÍ')) {
      return isPrincipal ? 40.00 : 40.00;
    }
    if (cat.contains('JÚNIOR NIVELL A') || cat.contains('JUNIOR NIVELL A')) {
      return 35.00; // Només àrbitre principal
    }
    if (cat.contains('JÚNIOR NIVELL B') || cat.contains('JUNIOR NIVELL B')) {
      return 35.00; // Només àrbitre principal
    }
    if (cat.contains('JÚNIOR NIVELL C') || cat.contains('JUNIOR NIVELL C')) {
      return 29.00; // Només àrbitre principal
    }
    if (cat.contains('CADET PREFERENT') && !cat.contains('1R ANY')) {
      return isPrincipal ? 35.00 : 35.00;
    }
    if (cat.contains('CADET INTERTERRITORIAL')) {
      return isPrincipal ? 27.00 : 27.00;
    }
    if (cat.contains('CADET') && cat.contains('PROMOCIÓ')) {
      return 24.00; // Només àrbitre principal (masculí o sense especificar)
    }
    if (cat.contains('CADET PREFERENT 1R ANY')) {
      return isPrincipal ? 27.00 : 27.00;
    }
    if (cat.contains('INFANTIL PREFERENT') && !cat.contains('1R ANY')) {
      return isPrincipal ? 25.00 : 25.00;
    }
    if (cat.contains('INFANTIL PREFERENT 1R ANY') ||
        cat.contains('INFANTIL INTERTERRITORIAL')) {
      return 22.00; // Només àrbitre principal
    }
    if (cat.contains('MINI A1')) {
      return isPrincipal ? 22.00 : 22.00;
    }
    if (cat.contains('PREMINI') || cat.contains('PRE-MINI') || cat.contains('MINI') ||
        cat.contains('PREINFANTIL') || cat.contains('PRE-INFANTIL') ||
        cat.contains('INFANTIL PROMOCIÓ')) {
      return 22.00; // Només àrbitre principal
    }
    if (cat.contains('ESCOBOL')) {
      return 15.00; // Només àrbitre principal
    }

    // Femenins
    if (cat.contains('SUPER COPA') && cat.contains('FEMEN')) {
      return isPrincipal ? 90.00 : 90.00;
    }
    if (cat.contains('COPA CATALUNYA') && cat.contains('FEMEN')) {
      return isPrincipal ? 74.00 : 74.00;
    }
    if (cat.contains('1A CATEGORIA') && cat.contains('FEMEN')) {
      return isPrincipal ? 55.00 : 55.00;
    }
    if (cat.contains('2A CATEGORIA') && cat.contains('FEMEN')) {
      return isPrincipal ? 46.00 : 46.00;
    }
    if (cat.contains('1A TERRITORIAL') && cat.contains('FEMEN')) {
      return 44.00; // Només àrbitre principal
    }
    if ((cat.contains('2A TERRITORIAL') || cat.contains('SOTS 25') ||
         cat.contains('SOTS 20')) && cat.contains('FEMEN')) {
      return 40.00; // Només àrbitre principal
    }
    if (cat.contains('JÚNIOR PREFERENT') && cat.contains('FEMEN')) {
      return isPrincipal ? 52.00 : 52.00;
    }
    if ((cat.contains('JÚNIOR PREFERENT 1R ANY') ||
         cat.contains('JÚNIOR INTERTERRITORIAL')) && cat.contains('FEMEN')) {
      return isPrincipal ? 40.00 : 40.00;
    }
    if (cat.contains('JÚNIOR NIVELL A') && cat.contains('FEMEN')) {
      return 35.00; // Només àrbitre principal
    }
    if (cat.contains('JÚNIOR NIVELL B') && cat.contains('FEMEN')) {
      return 29.00; // Només àrbitre principal
    }
    if (cat.contains('CADET') && cat.contains('FEMEN')) {
      if (cat.contains('PREFERENT') && !cat.contains('1R ANY')) {
        return isPrincipal ? 35.00 : 35.00;
      }
      if (cat.contains('INTERTERRITORIAL') || cat.contains('1R ANY')) {
        return isPrincipal ? 27.00 : 27.00;
      }
      if (cat.contains('PROMOCIÓ')) {
        return 24.00;
      }
    }
    if (cat.contains('INFANTIL') && cat.contains('FEMEN')) {
      if (cat.contains('PREFERENT') && !cat.contains('1R ANY')) {
        return isPrincipal ? 25.00 : 25.00;
      }
      if (cat.contains('1R ANY') || cat.contains('INTERTERRITORIAL')) {
        return 22.00;
      }
    }
    if ((cat.contains('PREMINI') || cat.contains('MINI') ||
         cat.contains('PREINFANTIL') || cat.contains('PROMOCIÓ')) &&
        cat.contains('FEMEN')) {
      return 22.00;
    }
    if (cat.contains('ESCOBOL') && cat.contains('FEMEN')) {
      return 15.00;
    }

    // Default si no es troba la categoria
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