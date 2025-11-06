import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/vote_model.dart';
import '../services/vote_service.dart';

class VoteProvider with ChangeNotifier {
  final VoteService _service;

  // map jornada -> matchId
  final Map<int, String?> _userVotes = {};

  // in-flight states by jornada (true when casting)
  final Map<int, bool> _inFlight = {};

  // closed jornadas set — can be updated from remote in the future
  final Set<int> _closed = {};
  final Map<int, StreamSubscription<bool>> _votingSubs = {};
  // track jornadas we've loaded/listened for so we can refresh after auth changes
  final Set<int> _observedJornadas = {};
  StreamSubscription<User?>? _authSub;

  VoteProvider({VoteService? service}) : _service = service ?? VoteService();

  // Subscribe to auth changes so that when the user signs in/out we reload
  // any observed jornadas (calls to loadVoteForJornada will register jornadas).
  void _ensureAuthListener() {
    _authSub ??= FirebaseAuth.instance.authStateChanges().listen((user) {
      // When auth state changes, reload votes for observed jornadas.
      for (final j in _observedJornadas) {
        // ignore: unawaited_futures
        loadVoteForJornada(j);
      }
    });
  }

  bool isClosed(int jornada) => _closed.contains(jornada);

  bool isCasting(int jornada) => _inFlight[jornada] == true;

  String? votedMatchId(int jornada) => _userVotes[jornada];

  /// Load the current user's vote for a jornada (if logged in).
  Future<void> loadVoteForJornada(int jornada) async {
    // register this jornada as observed so auth changes trigger reloads
    _observedJornadas.add(jornada);
    _ensureAuthListener();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _userVotes[jornada] = null;
      notifyListeners();
      return;
    }
    try {
      final v = await _service.getUserVote(jornada, user.uid);
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
  }

  /// Expose a stream of vote counts for UI wiring
  Stream<int> getVoteCountStream(String matchId, int jornada) =>
      _service.getVoteCount(matchId, jornada);

  /// Cast a vote (replaces previous vote for the jornada). If the jornada
  /// is closed, this will throw a StateError.
  Future<void> castVote({required int jornada, required String matchId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Not authenticated');
    }
    if (isClosed(jornada)) {
      throw StateError('Voting closed for jornada $jornada');
    }
    _inFlight[jornada] = true;
    notifyListeners();
    try {
      final vote = Vote(
        userId: user.uid,
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Not authenticated');
    _inFlight[jornada] = true;
    notifyListeners();
    try {
      await _service.revokeVote(jornada, user.uid);
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
    for (final s in _votingSubs.values) {
      s.cancel();
    }
    _votingSubs.clear();
    super.dispose();
  }
}
