// ============================================================================
// RefereeCategoryColors - Sistema de colors per categories arbitrals
// ============================================================================
// Defineix colors únics per cada categoria segons la jerarquia oficial FCBQ
// Utilitzat per mostrar badges de categoria en comentaris anònims

import 'package:flutter/material.dart';

/// Tipus de categoria arbitral segons jerarquia FCBQ
/// Ordre de màxima a mínima autoritat
enum RefereeCategory {
  /// Lliga ACB - Màxima categoria professional
  acb,

  /// FEB Grup 1 i Vinculats
  febGrup1,

  /// FEB Grup 2 i Vinculats
  febGrup2,

  /// FEB Grup 3 i Vinculats
  febGrup3,

  /// FCBQ A1 - Màxima categoria autonòmica
  fcbqA1,

  /// Altres categories FCBQ
  fcbqOther,
}

extension RefereeCategoryExtension on RefereeCategory {
  /// Converteix el valor de l'enum a string per serialització
  String get value {
    switch (this) {
      case RefereeCategory.acb:
        return 'ACB';
      case RefereeCategory.febGrup1:
        return 'FEB_GRUP_1';
      case RefereeCategory.febGrup2:
        return 'FEB_GRUP_2';
      case RefereeCategory.febGrup3:
        return 'FEB_GRUP_3';
      case RefereeCategory.fcbqA1:
        return 'FCBQ_A1';
      case RefereeCategory.fcbqOther:
        return 'FCBQ_OTHER';
    }
  }

  /// Nom complet per mostrar a la UI
  String get displayName {
    switch (this) {
      case RefereeCategory.acb:
        return 'Lliga ACB';
      case RefereeCategory.febGrup1:
        return 'FEB Grup 1';
      case RefereeCategory.febGrup2:
        return 'FEB Grup 2';
      case RefereeCategory.febGrup3:
        return 'FEB Grup 3';
      case RefereeCategory.fcbqA1:
        return 'FCBQ A1';
      case RefereeCategory.fcbqOther:
        return 'Àrbitre FCBQ';
    }
  }

  /// Converteix string a RefereeCategory
  static RefereeCategory fromValue(String value) {
    switch (value.toUpperCase()) {
      case 'ACB':
      case 'LLIGA ACB':
        return RefereeCategory.acb;
      case 'FEB_GRUP_1':
      case 'FEB (GRUP 1 I VINCULATS)':
        return RefereeCategory.febGrup1;
      case 'FEB_GRUP_2':
      case 'FEB (GRUP 2 I VINCULATS)':
        return RefereeCategory.febGrup2;
      case 'FEB_GRUP_3':
      case 'FEB (GRUP 3 I VINCULATS)':
        return RefereeCategory.febGrup3;
      case 'FCBQ_A1':
      case 'FCBQ A1':
        return RefereeCategory.fcbqA1;
      default:
        return RefereeCategory.fcbqOther;
    }
  }

  /// Extreu categoria des del string categoriaRrtt del referees_registry
  /// Format: "ÀRBITRE FEB (GRUP 3) Barcelona" → febGrup3
  static RefereeCategory fromCategoriaRrtt(String? categoriaRrtt) {
    if (categoriaRrtt == null || categoriaRrtt.isEmpty) {
      return RefereeCategory.fcbqOther;
    }

    final normalized = categoriaRrtt.toUpperCase();

    if (normalized.contains('ACB')) {
      return RefereeCategory.acb;
    }
    if (normalized.contains('FEB') && normalized.contains('GRUP 1')) {
      return RefereeCategory.febGrup1;
    }
    if (normalized.contains('FEB') && normalized.contains('GRUP 2')) {
      return RefereeCategory.febGrup2;
    }
    if (normalized.contains('FEB') && normalized.contains('GRUP 3')) {
      return RefereeCategory.febGrup3;
    }
    if (normalized.contains('FCBQ A1') || normalized.contains('A1')) {
      return RefereeCategory.fcbqA1;
    }

    return RefereeCategory.fcbqOther;
  }
}

/// Sistema de colors per categories arbitrals
class RefereeCategoryColors {
  // Nivell Professional - Tons càlids (or, plata, bronze)
  static const Color acb = Color(0xFFFFD700); // Or
  static const Color febGrup1 = Color(0xFFC0C0C0); // Plata
  static const Color febGrup2 = Color(0xFFCD7F32); // Bronze
  static const Color febGrup3 = Color(0xFF4A90E2); // Blau fosc

  // Nivell Autonòmic - Tons verds/liles
  static const Color fcbqA1 = Color(0xFF50C878); // Verd maragda
  static const Color fcbqOther = Color(0xFF9B59B6); // Lila

  /// Obté el color per una categoria específica
  static Color getColorForCategory(RefereeCategory category) {
    switch (category) {
      case RefereeCategory.acb:
        return acb;
      case RefereeCategory.febGrup1:
        return febGrup1;
      case RefereeCategory.febGrup2:
        return febGrup2;
      case RefereeCategory.febGrup3:
        return febGrup3;
      case RefereeCategory.fcbqA1:
        return fcbqA1;
      case RefereeCategory.fcbqOther:
        return fcbqOther;
    }
  }

  /// Retorna el nivell jeràrquic (0 = màxima autoritat)
  /// Utilitzat per ordenar comentaris i determinar qui pot tancar el debat
  static int getHierarchyLevel(RefereeCategory category) {
    switch (category) {
      case RefereeCategory.acb:
        return 0; // Màxima autoritat
      case RefereeCategory.febGrup1:
        return 1;
      case RefereeCategory.febGrup2:
        return 2;
      case RefereeCategory.febGrup3:
        return 3;
      case RefereeCategory.fcbqA1:
        return 4;
      case RefereeCategory.fcbqOther:
        return 5; // Mínima autoritat
    }
  }

  /// Comprova si una categoria pot tancar el debat (ACB o FEB Grup 1)
  static bool canCloseDebate(RefereeCategory category) {
    return category == RefereeCategory.acb ||
        category == RefereeCategory.febGrup1;
  }
}
