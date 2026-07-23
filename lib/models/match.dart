import 'package:cloud_firestore/cloud_firestore.dart';

import 'sport.dart';

/// Lifecycle of a match.
enum MatchStatus {
  open('open'),
  full('full'),
  cancelled('cancelled'),
  finished('finished');

  const MatchStatus(this.id);
  final String id;

  static MatchStatus fromId(String? id) {
    return MatchStatus.values.firstWhere(
      (s) => s.id == id,
      orElse: () => MatchStatus.open,
    );
  }
}

/// A venue: a display name plus a location for proximity queries.
class Venue {
  const Venue({required this.name, required this.geo});

  final String name;
  final GeoPoint geo;

  factory Venue.fromMap(Map<String, dynamic> map) {
    return Venue(
      name: (map['name'] as String?) ?? 'Unknown venue',
      geo: (map['geo'] as GeoPoint?) ?? const GeoPoint(0, 0),
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'geo': geo};
}

/// A pickup game, stored at `matches/{matchId}`.
///
/// NOTE: [playerIds], [status], and the derived [spotsMissing] are
/// **server-authoritative** — clients must never write them directly. Joining
/// and leaving go through Cloud Functions (see repositories/match_repository).
class Match {
  const Match({
    required this.id,
    required this.sport,
    required this.organizerId,
    required this.venue,
    required this.startAt,
    required this.totalPlayers,
    required this.status,
    required this.playerIds,
    this.chatLink,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final Sport sport;
  final String organizerId;
  final Venue venue;
  final DateTime startAt;
  final int totalPlayers;
  final MatchStatus status;

  /// Denormalized list of participant uids, kept in sync server-side. Used for
  /// cheap "am I in?" checks and list rendering.
  final List<String> playerIds;

  /// Optional external chat (WhatsApp/Viber) invite link.
  final String? chatLink;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// How many spots are still open. Derived from the authoritative
  /// [playerIds]; never below zero.
  int get spotsMissing =>
      (totalPlayers - playerIds.length).clamp(0, totalPlayers);

  bool get isFull => spotsMissing == 0;

  bool containsPlayer(String uid) => playerIds.contains(uid);

  factory Match.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Match(
      id: doc.id,
      sport: Sport.fromId(data['sport'] as String?),
      organizerId: (data['organizerId'] as String?) ?? '',
      venue: Venue.fromMap(
          (data['venue'] as Map?)?.cast<String, dynamic>() ?? const {}),
      startAt: (data['startAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      totalPlayers: (data['totalPlayers'] as num?)?.toInt() ?? 0,
      status: MatchStatus.fromId(data['status'] as String?),
      playerIds:
          ((data['playerIds'] as List?) ?? const []).cast<String>().toList(),
      chatLink: data['chatLink'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Fields a **client** is allowed to set when creating a match. Deliberately
  /// omits [playerIds]/[status]/[spotsMissing] — those are initialized and
  /// maintained by Cloud Functions.
  Map<String, dynamic> toCreateMap() {
    return {
      'sport': sport.id,
      'organizerId': organizerId,
      'venue': venue.toMap(),
      'startAt': Timestamp.fromDate(startAt),
      'totalPlayers': totalPlayers,
      'chatLink': chatLink,
    };
  }
}
