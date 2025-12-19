// ============================================================================
// WeeklyFocusService - Servei per obtenir el focus setmanal
// ============================================================================
// Llegeix weekly_focus/current de Firestore i proporciona les dades
// del partit guanyador i l'equip arbitral.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/weekly_focus.dart';

/// Excepció quan no hi ha focus setmanal actiu
class NoWeeklyFocusException implements Exception {
  final String message;
  NoWeeklyFocusException([this.message = 'No hi ha focus setmanal actiu']);

  @override
  String toString() => 'NoWeeklyFocusException: $message';
}

/// Servei singleton per obtenir el focus setmanal
class WeeklyFocusService {
  static final WeeklyFocusService _instance = WeeklyFocusService._internal();
  factory WeeklyFocusService() => _instance;
  WeeklyFocusService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache local
  WeeklyFocus? _cachedFocus;
  DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Obté el focus setmanal actual (weekly_focus/current)
  ///
  /// Retorna null si no hi ha focus actiu.
  /// Utilitza cache de 5 minuts per reduir lectures a Firestore.
  Future<WeeklyFocus?> getCurrentFocus({bool forceRefresh = false}) async {
    // Comprova cache
    if (!forceRefresh && _cachedFocus != null && _cacheTime != null) {
      final elapsed = DateTime.now().difference(_cacheTime!);
      if (elapsed < _cacheDuration) {
        debugPrint(
          '[WeeklyFocusService] Retornant dades del cache (${elapsed.inSeconds}s)',
        );
        return _cachedFocus;
      }
    }

    try {
      debugPrint('[WeeklyFocusService] Carregant weekly_focus/current...');

      final doc = await _firestore
          .collection('weekly_focus')
          .doc('current')
          .get();

      if (!doc.exists) {
        debugPrint('[WeeklyFocusService] No hi ha weekly_focus/current');
        _cachedFocus = null;
        return null;
      }

      final data = doc.data();
      if (data == null) {
        debugPrint('[WeeklyFocusService] Document buit');
        _cachedFocus = null;
        return null;
      }

      final focus = WeeklyFocus.fromJson(data);

      // Actualitzem cache
      _cachedFocus = focus;
      _cacheTime = DateTime.now();

      debugPrint(
        '[WeeklyFocusService] ✅ Focus carregat: Jornada ${focus.jornada}, '
        '${focus.winningMatch.matchDisplayName}, ${focus.totalVotes} vots',
      );
      debugPrint(
        '[WeeklyFocusService] Àrbitre principal: ${focus.refereeInfo.principal ?? "no disponible"}',
      );

      return focus;
    } catch (e) {
      debugPrint('[WeeklyFocusService] ❌ Error: $e');
      return null;
    }
  }

  /// Stream per escoltar canvis en temps real al focus
  Stream<WeeklyFocus?> watchCurrentFocus() {
    return _firestore.collection('weekly_focus').doc('current').snapshots().map(
      (snapshot) {
        if (!snapshot.exists) return null;
        final data = snapshot.data();
        if (data == null) return null;

        final focus = WeeklyFocus.fromJson(data);
        // Actualitzem cache
        _cachedFocus = focus;
        _cacheTime = DateTime.now();

        return focus;
      },
    );
  }

  /// Obté el focus d'una jornada específica (weekly_focus/jornada_{n})
  Future<WeeklyFocus?> getFocusByJornada(int jornada) async {
    try {
      debugPrint(
        '[WeeklyFocusService] Carregant weekly_focus/jornada_$jornada...',
      );

      final doc = await _firestore
          .collection('weekly_focus')
          .doc('jornada_$jornada')
          .get();

      if (!doc.exists) {
        debugPrint(
          '[WeeklyFocusService] No hi ha weekly_focus/jornada_$jornada',
        );
        return null;
      }

      final data = doc.data();
      if (data == null) return null;

      return WeeklyFocus.fromJson(data);
    } catch (e) {
      debugPrint('[WeeklyFocusService] ❌ Error: $e');
      return null;
    }
  }

  /// Neteja el cache forçant una nova lectura
  void clearCache() {
    _cachedFocus = null;
    _cacheTime = null;
    debugPrint('[WeeklyFocusService] Cache netejat');
  }
}
