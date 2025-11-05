import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/vote_model.dart';

class VoteService {
  final FirebaseFirestore _firestore;

  VoteService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Document id per user and jornada to ensure one vote per jornada per user.
  String _docId(int jornada, String userId) => '${jornada}_$userId';

  Future<Vote?> getUserVote(int jornada, String userId) async {
    final doc = await _firestore
        .collection('votes')
        .doc(_docId(jornada, userId))
        .get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    return Vote.fromJson(Map<String, dynamic>.from(data));
  }

  /// Cast or replace a vote for the given jornada by the given user.
  /// The implementation writes to a single document per (jornada,user) so
  /// replacing a previous vote is just an overwrite.
  Future<void> castVote(Vote vote) async {
    final docRef = _firestore
        .collection('votes')
        .doc(_docId(vote.jornada, vote.userId));
    // Use a transaction to avoid races and to be explicit.
    await _firestore.runTransaction((tx) async {
      tx.set(docRef, vote.toJson());
    });
  }

  /// Optionally delete a user's vote for a jornada.
  Future<void> revokeVote(int jornada, String userId) async {
    final docRef = _firestore.collection('votes').doc(_docId(jornada, userId));
    await docRef.delete();
  }

  /// Helper: returns current user id or null.
  String? currentUserId() => FirebaseAuth.instance.currentUser?.uid;

  /// Returns true if voting is open for the given jornada.
  /// Reads document `voting_meta/jornada_<num>` and returns `votingOpen` bool.
  /// If the document does not exist or the field is missing, defaults to true.
  Future<bool> isVotingOpen(int jornada) async {
    try {
      final doc = await _firestore
          .collection('voting_meta')
          .doc('jornada_$jornada')
          .get();
      if (!doc.exists) return true;
      final data = doc.data();
      if (data == null) return true;
      return (data['votingOpen'] as bool?) ?? true;
    } catch (e) {
      // In case of error, be permissive and return true so UI doesn't block votes
      // due to transient issues. Logging can be added here.
      debugPrint('VoteService.isVotingOpen error: $e');
      return true;
    }
  }

  /// Real-time stream of votingOpen for a jornada. Emits `true` when open.
  Stream<bool> votingOpenStream(int jornada) {
    final ref = _firestore.collection('voting_meta').doc('jornada_$jornada');
    return ref.snapshots().map((snap) {
      if (!snap.exists) return true;
      final data = snap.data();
      return (data?['votingOpen'] as bool?) ?? true;
    });
  }

  /// Stream of vote counts for a given match/jornada. Returns 0 when absent.
  Stream<int> getVoteCount(String matchId, int jornada) {
    final docRef = _firestore
        .collection('vote_counts')
        .doc('${jornada}_$matchId');
    return docRef.snapshots().map((snap) {
      if (!snap.exists) return 0;
      final data = snap.data();
      return (data?['count'] as int?) ?? 0;
    });
  }
}
