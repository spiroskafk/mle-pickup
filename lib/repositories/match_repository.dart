import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/match.dart';
import '../models/sport.dart';

/// Data access for `matches/{matchId}`.
///
/// Reads go straight to Firestore. **Mutations that touch shared state
/// (join/leave) go through Cloud Functions**, so the server stays the single
/// source of truth for `playerIds`, `status`, and capacity — a client can
/// never grant itself a spot or corrupt the count.
class MatchRepository {
  MatchRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('matches');

  /// Live stream of open matches, newest start time first, optionally filtered
  /// by [sport].
  ///
  /// v1 uses a simple status/sport query; geo-proximity filtering is a
  /// documented follow-up (see SPEC §13). Until then the client can sort by
  /// distance in-memory after fetching.
  Stream<List<Match>> watchOpen({Sport? sport}) {
    Query<Map<String, dynamic>> query =
        _col.where('status', isEqualTo: MatchStatus.open.id);
    if (sport != null) {
      query = query.where('sport', isEqualTo: sport.id);
    }
    query = query.orderBy('startAt');
    return query.snapshots().map(
          (snap) => snap.docs.map(Match.fromDoc).toList(),
        );
  }

  /// Live stream of a single match.
  Stream<Match?> watch(String matchId) {
    return _col.doc(matchId).snapshots().map(
          (doc) => doc.exists ? Match.fromDoc(doc) : null,
        );
  }

  /// Matches the given user organizes or has joined.
  Stream<List<Match>> watchForPlayer(String uid) {
    return _col
        .where('playerIds', arrayContains: uid)
        .orderBy('startAt')
        .snapshots()
        .map((snap) => snap.docs.map(Match.fromDoc).toList());
  }

  /// Creates a new match. The client only writes the fields in [toCreateMap];
  /// a Cloud Function initializes the organizer as the first participant and
  /// sets the server-authoritative fields (playerIds/status/timestamps).
  Future<String> create(Match match) async {
    final callable = _functions.httpsCallable('createMatch');
    final result = await callable.call<Map<String, dynamic>>(
      match.toCreateMap(),
    );
    return result.data['matchId'] as String;
  }

  /// Claims a spot. Server rejects if the match is full, cancelled, or the
  /// user already joined.
  Future<void> join(String matchId) async {
    final callable = _functions.httpsCallable('joinMatch');
    await callable.call<void>({'matchId': matchId});
  }

  /// Releases the current user's spot, reopening it.
  Future<void> leave(String matchId) async {
    final callable = _functions.httpsCallable('leaveMatch');
    await callable.call<void>({'matchId': matchId});
  }

  /// Organizer-only cancel.
  Future<void> cancel(String matchId) async {
    final callable = _functions.httpsCallable('cancelMatch');
    await callable.call<void>({'matchId': matchId});
  }
}
