import 'dart:async';

import 'package:flutter/material.dart';
import '../models/vote_model.dart';
import '../services/vote_service.dart';
import '../../auth/index.dart';

class VoteProvider with ChangeNotifier {
  final VoteService _service;

  // Simple instance counter to help detect leaked providers during runtime.
  static int _liveInstances = 0;

  // map jornada -> matchId
  final Map<int, String?> _userVotes = {};

  // in-flight states by jornada (true when casting)
  final Map<int, bool> _inFlight = {};

  // closed jornadas set — can be updated from remote in the future
  final Set<int> _closed = {};
  final Map<int, StreamSubscription<bool>> _votingSubs = {};
  // track jornadas we've loaded/listened for so we can refresh after auth changes
  final Set<int> _observedJornadas = {};

  // Optional injected AuthProvider (presentation-level auth access)
  final AuthProvider? _authProvider;
  VoidCallback? _authListener;

  VoteProvider({VoteService? service, AuthProvider? authProvider})
    : _service = service ?? VoteService(),
      _authProvider = authProvider {
    _liveInstances += 1;
    debugPrint('VoteProvider.created (hash=$hashCode) — live=$_liveInstances');
    // If an AuthProvider is supplied, listen to its changes so we can refresh
    // observed jornadas when the auth state changes.
    if (_authProvider != null) {
      _authListener = () {
        debugPrint(
          'VoteProvider(AuthProvider listener) triggered for provider hash=$hashCode',
        );
        for (final j in _observedJornadas) {
          // ignore: unawaited_futures
          loadVoteForJornada(j);
        }
      };
      _authProvider.addListener(_authListener!);
      debugPrint('VoteProvider._authListener registered (hash=$hashCode)');
    }
  }

  // Auth listening is handled via an injected AuthProvider listener (if supplied).

  bool isClosed(int jornada) => _closed.contains(jornada);

  bool isCasting(int jornada) => _inFlight[jornada] == true;

  String? votedMatchId(int jornada) => _userVotes[jornada];

  /// Load the current user's vote for a jornada (if logged in).
  Future<void> loadVoteForJornada(int jornada) async {
    // register this jornada as observed so auth changes trigger reloads
    _observedJornadas.add(jornada);
    debugPrint(
      'VoteProvider.loadVoteForJornada: provider=$hashCode jornada=$jornada observed=${_observedJornadas.length}',
    );
    final userId = _authProvider?.currentUserUid;
    if (userId == null) {
      _userVotes[jornada] = null;
      notifyListeners();
      return;
    }
    try {
      final v = await _service.getUserVote(jornada, userId);
      _userVotes[jornada] = v?.matchId;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading vote: $e');
    }
  }

  /// Start listening to votingOpen for a jornada and update closed state.
  void listenVotingOpen(int jornada) {
    // cancel existing
    _votingSubs[jornada]?.cancel();
    _votingSubs[jornada] = _service
        .votingOpenStream(jornada)
        .listen(
          (isOpen) {
            setClosed(jornada, !isOpen);
          },
          onError: (e) {
            debugPrint('Error listening votingOpen for $jornada: $e');
          },
        );
    debugPrint(
      'VoteProvider.listenVotingOpen: provider=$hashCode jornada=$jornada — subscribed',
    );
  }

  /// Expose a stream of vote counts for UI wiring
  Stream<int> getVoteCountStream(String matchId, int jornada) =>
      _service.getVoteCount(matchId, jornada);

  /// Cast a vote (replaces previous vote for the jornada). If the jornada
  /// is closed, this will throw a StateError.
  Future<void> castVote({required int jornada, required String matchId}) async {
    final userId = _authProvider?.currentUserUid;
    if (userId == null) {
      throw StateError('Not authenticated');
    }
    if (isClosed(jornada)) {
      throw StateError('Voting closed for jornada $jornada');
    }
    _inFlight[jornada] = true;
    notifyListeners();
    try {
      final vote = Vote(
        userId: userId,
        jornada: jornada,
        matchId: matchId,
        timestamp: DateTime.now().toUtc(),
      );
      await _service.castVote(vote);
      _userVotes[jornada] = matchId;
    } finally {
      _inFlight.remove(jornada);
      notifyListeners();
    }
  }

  /// Revoke user's vote for jornada (optional)
  Future<void> revokeVote(int jornada) async {
    final userId = _authProvider?.currentUserUid;
    if (userId == null) throw StateError('Not authenticated');
    _inFlight[jornada] = true;
    notifyListeners();
    try {
      await _service.revokeVote(jornada, userId);
      _userVotes[jornada] = null;
    } finally {
      _inFlight.remove(jornada);
      notifyListeners();
    }
  }

  /// For admin or remote control: mark jornada as closed/open.
  void setClosed(int jornada, bool closed) {
    if (closed) {
      _closed.add(jornada);
    } else {
      _closed.remove(jornada);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    debugPrint(
      'VoteProvider.dispose called (hash=$hashCode) — cancelling ${_votingSubs.length} voting subs',
    );
    for (final s in _votingSubs.values) {
      try {
        s.cancel();
      } catch (e) {
        debugPrint('Error cancelling voting sub: $e');
      }
    }
    _votingSubs.clear();
    if (_authListener != null && _authProvider != null) {
      try {
        _authProvider.removeListener(_authListener!);
        debugPrint('VoteProvider._authListener removed (hash=$hashCode)');
      } catch (e) {
        debugPrint('Error removing auth listener: $e');
      }
      _authListener = null;
    }
    _liveInstances -= 1;
    debugPrint('VoteProvider.disposed (hash=$hashCode) — live=$_liveInstances');
    super.dispose();
  }
}
