// Requisits mínims per aprovar tests de regles segons categoria FCBQ
//
// Basats en la normativa oficial d'activitats tècniques FCBQ:
// - Tests de 25 preguntes
// - Mínim d'encerts varia segons categoria i rol (àrbitre/auxiliar de taula)
//
// ÀRBITRES:
// - FCBQ A i FCBQ A1: 20/25 (cat) - 17/25 (actuar)
// - FCBQ A2: 19/25 (cat) - 17/25 (actuar)
// - Resta CABQ (B1,B2,C1,C2,C3): 17/25 (cat) - 17/25 (actuar)
// - ESCOLA (EABQ): 15/25 (cat) - 15/25 (actuar)
//
// AUXILIARS DE TAULA:
// - ACB: 20/25 (cat) - 17/25 (actuar)
// - FEB (GRUP1 i GRUP2): 19/25 (cat) - 17/25 (actuar)
// - FCBQ A1: 18/25 (cat) - 17/25 (actuar)
// - FCBQ A2: 17/25 (cat) - 17/25 (actuar)
// - FCBQ B1 i B2: 15/25 (cat) - 15/25 (actuar)

class TestRequirements {
  /// Tipus de rol per als tests
  static const String rolArbitre = 'arbitre';
  static const String rolAuxiliar = 'auxiliar';

  /// Mínims per ÀRBITRES - ACTUAR A LA CATEGORIA (sobre 25 preguntes)
  static const Map<String, int> _minimArbitresCategoria = {
    // FCBQ A i FCBQ A1
    'FCBQ A': 20,
    'FCBQ A1': 20,
    // FCBQ A2
    'FCBQ A2': 19,
    // Resta de categories CABQ (B1, B2, C1, C2, C3)
    'FCBQ B1': 17,
    'FCBQ B2': 17,
    'FCBQ C1': 17,
    'FCBQ C2': 17,
    'FCBQ C3': 17,
    // Escola (EABQ)
    'ESCOLA': 15,
    'EABQ': 15,
  };

  /// Mínims per ÀRBITRES - ACTUAR (més permissiu)
  static const Map<String, int> _minimArbitresActuar = {
    'FCBQ A': 17,
    'FCBQ A1': 17,
    'FCBQ A2': 17,
    'FCBQ B1': 17,
    'FCBQ B2': 17,
    'FCBQ C1': 17,
    'FCBQ C2': 17,
    'FCBQ C3': 17,
    'ESCOLA': 15,
    'EABQ': 15,
  };

  /// Mínims per AUXILIARS DE TAULA - ACTUAR A LA CATEGORIA (sobre 25 preguntes)
  static const Map<String, int> _minimAuxiliarsCategoria = {
    // ACB
    'ACB': 20,
    // FEB
    'FEB': 19,
    'FEB GRUP1': 19,
    'FEB GRUP2': 19,
    // FCBQ A1
    'FCBQ A1': 18,
    // FCBQ A2
    'FCBQ A2': 17,
    // FCBQ B1 i B2
    'FCBQ B1': 15,
    'FCBQ B2': 15,
  };

  /// Mínims per AUXILIARS DE TAULA - ACTUAR (més permissiu)
  static const Map<String, int> _minimAuxiliarsActuar = {
    'ACB': 17,
    'FEB': 17,
    'FEB GRUP1': 17,
    'FEB GRUP2': 17,
    'FCBQ A1': 17,
    'FCBQ A2': 17,
    'FCBQ B1': 15,
    'FCBQ B2': 15,
  };

  /// Comprova si la categoria és auxiliar de taula
  /// Basat en el prefix de la categoria a Firestore (ex: "AUX. DE TAULA FEB GRUP1")
  static bool isAuxiliarDeTaula(String category) {
    final upper = category.toUpperCase();
    return upper.contains('AUX. DE TAULA') ||
        upper.contains('AUX DE TAULA') ||
        upper.contains('AUXILIAR');
  }

  /// Comprova si la categoria pertany a la Federació Espanyola (ACB/FEB)
  /// Retorna true NOMÉS per ÀRBITRES ACB/FEB (no per auxiliars)
  /// Els auxiliars de taula ACB/FEB SÍ tenen mínims definits i els processem
  static bool isFederacioEspanyolaArbitre(String category) {
    final normalized = _normalizeCategory(category);
    final isFebAcb = normalized == 'ACB' ||
        normalized == 'FEB' ||
        normalized == 'FEB GRUP1' ||
        normalized == 'FEB GRUP2' ||
        normalized == 'FEB GRUP3';

    // Si és auxiliar de taula, NO mostrem el banner (sí que els processem)
    if (isAuxiliarDeTaula(category)) {
      return false;
    }

    // Si és àrbitre FEB/ACB, SÍ mostrem el banner (fora de l'abast)
    return isFebAcb;
  }

  /// Comprova si la categoria pertany a la Federació Espanyola (ACB/FEB)
  /// DEPRECATED: Utilitza isFederacioEspanyolaArbitre per la lògica correcta
  static bool isFederacioEspanyola(String category) {
    return isFederacioEspanyolaArbitre(category);
  }

  /// Normalitza la categoria per fer matching
  static String _normalizeCategory(String category) {
    String normalized = category.toUpperCase().trim();

    // Eliminar prefixos comuns
    normalized = normalized.replaceAll('CATEGORIA ', '');
    normalized = normalized.replaceAll('CAT. ', '');
    normalized = normalized.replaceAll('CAT ', '');

    // Categories especials (no FCBQ) - Federació Espanyola
    // Detectem si conté "ACB" (pot ser "ÀRBITRE ACB Barcelona", "ACB", etc.)
    if (normalized.contains('ACB')) {
      return 'ACB';
    }
    // Detectem si conté "FEB" (pot ser "FEB GRUP1", "ÀRBITRE FEB", etc.)
    if (normalized.contains('FEB')) {
      if (normalized.contains('GRUP1') || normalized.contains('GRUP 1')) {
        return 'FEB GRUP1';
      }
      if (normalized.contains('GRUP2') || normalized.contains('GRUP 2')) {
        return 'FEB GRUP2';
      }
      return 'FEB';
    }

    // Normalitzar variants FCBQ
    if (normalized.contains('ESCOLA') || normalized.contains('EABQ')) {
      return 'ESCOLA';
    }
    if (normalized == 'A' || normalized == 'FCBQ A' || normalized == 'A FCBQ') {
      return 'FCBQ A';
    }
    if (normalized == 'A1' || normalized.contains('A1')) {
      return 'FCBQ A1';
    }
    if (normalized == 'A2' || normalized.contains('A2')) {
      return 'FCBQ A2';
    }
    if (normalized == 'B1' || normalized.contains('B1')) {
      return 'FCBQ B1';
    }
    if (normalized == 'B2' || normalized.contains('B2')) {
      return 'FCBQ B2';
    }
    if (normalized == 'C1' || normalized.contains('C1')) {
      return 'FCBQ C1';
    }
    if (normalized == 'C2' || normalized.contains('C2')) {
      return 'FCBQ C2';
    }
    if (normalized == 'C3' || normalized.contains('C3')) {
      return 'FCBQ C3';
    }

    return normalized;
  }

  /// Obté el mínim d'encerts requerits per aprovar a la categoria
  /// [category] - Categoria de l'àrbitre (ex: "FCBQ A1", "B2", "ACB", etc.)
  /// [totalQuestions] - Total de preguntes del test (normalment 25)
  /// [isAuxiliar] - true si és auxiliar de taula, false si és àrbitre
  static int getMinimumRequired(
    String category, {
    int totalQuestions = 25,
    bool isAuxiliar = false,
  }) {
    final normalized = _normalizeCategory(category);

    // Seleccionar la taula segons el rol
    final Map<String, int> table =
        isAuxiliar ? _minimAuxiliarsCategoria : _minimArbitresCategoria;

    // Buscar el mínim
    int minim = table[normalized] ?? 17; // Default: 17/25

    // Si el test no és de 25 preguntes, escalar proporcionalment
    if (totalQuestions != 25) {
      minim = ((minim / 25) * totalQuestions).ceil();
    }

    return minim;
  }

  /// Obté el mínim d'encerts per actuar (més permissiu)
  static int getMinimumToAct(
    String category, {
    int totalQuestions = 25,
    bool isAuxiliar = false,
  }) {
    final normalized = _normalizeCategory(category);

    // Seleccionar la taula segons el rol
    final Map<String, int> table =
        isAuxiliar ? _minimAuxiliarsActuar : _minimArbitresActuar;

    // Buscar el mínim
    int minim = table[normalized] ?? 17; // Default: 17/25

    // Si el test no és de 25 preguntes, escalar proporcionalment
    if (totalQuestions != 25) {
      minim = ((minim / 25) * totalQuestions).ceil();
    }

    return minim;
  }

  /// Comprova si el test està aprovat per actuar a la categoria
  static bool isApprovedForCategory(
    String category,
    int correctAnswers,
    int totalQuestions, {
    bool isAuxiliar = false,
  }) {
    final minim = getMinimumRequired(
      category,
      totalQuestions: totalQuestions,
      isAuxiliar: isAuxiliar,
    );
    return correctAnswers >= minim;
  }

  /// Comprova si el test està aprovat per actuar (mínim més permissiu)
  static bool isApprovedToAct(
    String category,
    int correctAnswers,
    int totalQuestions, {
    bool isAuxiliar = false,
  }) {
    final minim = getMinimumToAct(
      category,
      totalQuestions: totalQuestions,
      isAuxiliar: isAuxiliar,
    );
    return correctAnswers >= minim;
  }

  /// Obté el resultat detallat del test
  static TestResult getTestResult(
    String category,
    int correctAnswers,
    int totalQuestions, {
    bool isAuxiliar = false,
  }) {
    final minimCategory = getMinimumRequired(
      category,
      totalQuestions: totalQuestions,
      isAuxiliar: isAuxiliar,
    );

    final minimAct = getMinimumToAct(
      category,
      totalQuestions: totalQuestions,
      isAuxiliar: isAuxiliar,
    );

    final approvedCategory = correctAnswers >= minimCategory;
    final approvedAct = correctAnswers >= minimAct;

    return TestResult(
      category: _normalizeCategory(category),
      correctAnswers: correctAnswers,
      totalQuestions: totalQuestions,
      minimumForCategory: minimCategory,
      minimumToAct: minimAct,
      isApprovedForCategory: approvedCategory,
      isApprovedToAct: approvedAct,
      margin: correctAnswers - minimCategory,
    );
  }
}

/// Resultat d'un test amb tota la informació
class TestResult {
  final String category;
  final int correctAnswers;
  final int totalQuestions;
  final int minimumForCategory;
  final int minimumToAct;
  final bool isApprovedForCategory;
  final bool isApprovedToAct;
  final int margin; // Positiu = marge, negatiu = falten

  const TestResult({
    required this.category,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.minimumForCategory,
    required this.minimumToAct,
    required this.isApprovedForCategory,
    required this.isApprovedToAct,
    required this.margin,
  });

  /// Missatge de resultat
  String get resultMessage {
    if (isApprovedForCategory) {
      return 'APTE per actuar a $category';
    } else if (isApprovedToAct) {
      return 'APTE per actuar (no a categoria)';
    } else {
      return 'NO APTE';
    }
  }

  /// Missatge de marge
  String get marginMessage {
    if (margin > 0) {
      return '+$margin de marge';
    } else if (margin == 0) {
      return 'Just al límit';
    } else {
      return '${margin.abs()} preguntes per aprovar';
    }
  }
}
