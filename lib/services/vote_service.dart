import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Lightweight VoteService that stores a per-user vote document and
/// maintains an aggregated counter inside `matches/{matchId}.voteCounts`.
///
/// This implementation uses a transaction to ensure a user cannot vote
/// twice for the same match and to increment the aggregate safely.
class VoteService {
  final FirebaseFirestore _db;

  VoteService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  /// Record or change a user's vote for a given jornada.
  ///
  /// If the user has not voted yet for `jornada`, a new vote is created and
  /// the match aggregate counter is incremented. If the user already voted
  /// for a different match/team in the same jornada, this will decrement the
  /// previous team's counter and increment the new team's counter atomically.
  ///
  /// Returns `true` when a change (or new vote) was applied. Returns `false`
  /// when the vote was a no-op (user already voted for the same match/team)
  /// or when an error occurred.
  Future<bool> voteForMatch({
    required String matchId,
    required int jornada,
  }) async {
    // Capture the current Firebase user synchronously to avoid timing issues.
    final user = FirebaseAuth.instance.currentUser;
    // Debug print to help trace authentication timing issues in runtime.
    // This will appear in the console logs when a vote attempt happens.
    // Example: "User before voteForMatch: uid-abc123"
    // Avoid printing sensitive data in production logs.
    // ignore: avoid_print
    print('User before voteForMatch: ${user?.uid}');
    if (user == null) throw Exception('User not signed in');

    final userId = user.uid;
    final voteDoc = _db.collection('votes').doc('${jornada}_$userId');
    final newMatchRef = _db.collection('matches').doc(matchId);

    try {
      return await _db.runTransaction<bool>((tx) async {
        final voteSnap = await tx.get(voteDoc);

        Future<void> incMatchCount(DocumentReference ref, int delta) async {
          final snap = await tx.get(ref);
          if (!snap.exists) {
            tx.set(ref, {
              'createdAt': FieldValue.serverTimestamp(),
              'voteCount': delta,
            });
          } else {
            tx.update(ref, {'voteCount': FieldValue.increment(delta)});
          }
        }

        if (!voteSnap.exists) {
          // New vote: increment new match counter
          await incMatchCount(newMatchRef, 1);
          tx.set(voteDoc, {
            'matchId': matchId,
            'userId': userId,
            'jornada': jornada,
            'createdAt': FieldValue.serverTimestamp(),
          });
          return true;
        }

        final data = voteSnap.data();
        if (data == null) return false;
        final prevMatchId = data['matchId'] as String?;

        // If same match as existing vote, no-op
        if (prevMatchId == matchId) {
          return false;
        }

        // Decrement previous match counter if exists
        if (prevMatchId != null) {
          final prevRef = _db.collection('matches').doc(prevMatchId);
          await incMatchCount(prevRef, -1);
        }

        // Increment new match counter
        await incMatchCount(newMatchRef, 1);

        // Update vote doc with new match selection
        tx.update(voteDoc, {
          'matchId': matchId,
          'jornada': jornada,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e) {
      // ignore: avoid_print
      print('voteForMatch error: $e');
      return Future.value(false);
    }
  }

  /// Check if a user already voted for the given jornada. Returns the vote
  /// document data (matchId, teamId, jornada) if present, otherwise null.
  Future<Map<String, dynamic>?> getUserVoteForJornada({
    required int jornada,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    // ignore: avoid_print
    print('User before getUserVoteForJornada: ${user?.uid}');
    if (user == null) throw Exception('User not signed in');
    final doc = await _db
        .collection('votes')
        .doc('${jornada}_${user.uid}')
        .get();
    if (!doc.exists) return null;
    return doc.data();
  }

  /// Returns a map of teamId -> count for the match. If none, returns {}.
  Future<int> getVoteCount({required String matchId}) async {
    final snap = await _db.collection('matches').doc(matchId).get();
    if (!snap.exists) return 0;
    final data = snap.data();
    if (data == null) return 0;
    final vc = data['voteCount'] as num?;
    if (vc == null) return 0;
    return vc.toInt();
  }
}
