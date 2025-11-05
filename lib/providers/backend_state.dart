import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:el_visionat/services/auth_service.dart';

class BackendState extends ChangeNotifier {
  final AuthService authService;
  bool available;
  String? message;
  bool _isChecking = false;
  // Timer used to schedule periodic re-checks when backend is down.
  Timer? _retryTimer;
  // Timer used to auto sign-out the user in debug/dev mode to avoid ghost sessions.
  Timer? _autoSignOutTimer;
  // Current backoff interval in seconds. Starts small and grows up to [_maxBackoff].
  int _currentBackoff = 5;
  static const int _maxBackoff = 60;

  BackendState({
    required this.authService,
    required this.available,
    this.message,
  });

  bool get isChecking => _isChecking;

  /// Re-check backend availability and notify listeners on change.
  Future<void> recheck() async {
    if (_isChecking) return;
    _isChecking = true;
    notifyListeners();
    try {
      final ok = await authService.checkBackendAvailable();
      available = ok;
      message = ok ? null : 'Back-end no disponible';
      // If backend became available, stop any scheduled retries and reset backoff.
      if (ok) {
        _stopRetryTimer();
        _stopAutoSignOutTimer();
        _currentBackoff = 5;
      } else {
        // Ensure retries are scheduled when backend is unavailable.
        _ensureRetryScheduled();
      }
    } catch (e) {
      available = false;
      message = e.toString();
      _ensureRetryScheduled();
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  void _ensureRetryScheduled() {
    if (_retryTimer != null && _retryTimer!.isActive) return;
    // Schedule the next attempt using the current backoff value.
    _retryTimer = Timer(Duration(seconds: _currentBackoff), () async {
      // When the timer fires, attempt a recheck. If another recheck is already
      // in progress the call will return early.
      await recheck();
      // Exponential backoff: increase interval up to the max.
      _currentBackoff = (_currentBackoff * 2).clamp(5, _maxBackoff);
      // If still not available, schedule the next retry.
      if (!available) {
        _ensureRetryScheduled();
      }
    });
  }

  void _stopRetryTimer() {
    try {
      _retryTimer?.cancel();
    } catch (_) {}
    _retryTimer = null;
  }

  void _stopAutoSignOutTimer() {
    try {
      _autoSignOutTimer?.cancel();
    } catch (_) {}
    _autoSignOutTimer = null;
  }

  /// Start a dev-only auto sign-out timer. If the backend remains unavailable
  /// after [delay], the current user (if any) will be signed out. This helps
  /// avoid "ghost sessions" during development when the emulator is stopped.
  /// The method is a no-op in release builds.
  void startAutoSignOut({Duration delay = const Duration(seconds: 20)}) {
    if (!kDebugMode) return; // Only in dev
    if (available) return; // Backend already available
    // If a timer already exists, keep it.
    if (_autoSignOutTimer != null && _autoSignOutTimer!.isActive) return;

    _autoSignOutTimer = Timer(delay, () async {
      // If backend is still unavailable and there's a signed-in user, sign out.
      if (!available) {
        try {
          final currentUser = authService.auth.currentUser;
          if (currentUser != null) {
            await authService.signOut();
            // Update message for UI clarity
            message = 'Sessió tancada automàticament (backend no disponible)';
            notifyListeners();
          }
        } catch (e) {
          debugPrint('Auto sign-out failed: $e');
        }
      }
    });
  }

  /// Stop the auto sign-out timer if running.
  void stopAutoSignOut() {
    _stopAutoSignOutTimer();
  }

  /// Start periodic retrying if the backend is currently unavailable.
  void startAutoRetry() {
    if (available) return;
    _ensureRetryScheduled();
  }

  /// Stop any scheduled automatic retries.
  void stopAutoRetry() {
    _stopRetryTimer();
  }

  @override
  void dispose() {
    _stopRetryTimer();
    _stopAutoSignOutTimer();
    super.dispose();
  }
}
