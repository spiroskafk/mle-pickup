import 'package:cloud_firestore/cloud_firestore.dart';

import 'sport.dart';

/// A user profile, stored at `users/{uid}`.
///
/// Named [AppUser] to avoid clashing with `firebase_auth`'s `User`.
class AppUser {
  const AppUser({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    this.preferredSports = const [],
    this.fcmTokens = const [],
    this.createdAt,
  });

  final String uid;
  final String displayName;
  final String? photoUrl;
  final List<Sport> preferredSports;

  /// FCM registration tokens for push targeting (a user may have several
  /// devices). Managed by the messaging service, not edited in the UI.
  final List<String> fcmTokens;

  final DateTime? createdAt;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return AppUser(
      uid: doc.id,
      displayName: (data['displayName'] as String?) ?? 'Player',
      photoUrl: data['photoUrl'] as String?,
      preferredSports: ((data['preferredSports'] as List?) ?? const [])
          .map((e) => Sport.fromId(e as String?))
          .toList(),
      fcmTokens:
          ((data['fcmTokens'] as List?) ?? const []).cast<String>().toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Serializes to a Firestore map. [createdAt] is written as a server
  /// timestamp on first creation and left untouched afterwards, so it is
  /// intentionally omitted here — see the repository.
  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'photoUrl': photoUrl,
      'preferredSports': preferredSports.map((s) => s.id).toList(),
      'fcmTokens': fcmTokens,
    };
  }

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    List<Sport>? preferredSports,
    List<String>? fcmTokens,
  }) {
    return AppUser(
      uid: uid,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      preferredSports: preferredSports ?? this.preferredSports,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      createdAt: createdAt,
    );
  }
}
