import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

/// Data access for `users/{uid}`.
class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('users');

  /// Live stream of a single user's profile.
  Stream<AppUser?> watch(String uid) {
    return _col.doc(uid).snapshots().map(
          (doc) => doc.exists ? AppUser.fromDoc(doc) : null,
        );
  }

  /// One-shot read.
  Future<AppUser?> get(String uid) async {
    final doc = await _col.doc(uid).get();
    return doc.exists ? AppUser.fromDoc(doc) : null;
  }

  /// Creates the profile document if it doesn't exist yet (e.g. right after
  /// first sign-in). [createdAt] is set with a server timestamp exactly once.
  Future<void> ensureExists(AppUser user) async {
    final ref = _col.doc(user.uid);
    final snap = await ref.get();
    if (snap.exists) return;
    await ref.set({
      ...user.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Updates editable profile fields.
  Future<void> update(AppUser user) {
    return _col.doc(user.uid).update(user.toMap());
  }

  /// Adds an FCM token without clobbering tokens from the user's other devices.
  Future<void> addFcmToken(String uid, String token) {
    return _col.doc(uid).update({
      'fcmTokens': FieldValue.arrayUnion([token]),
    });
  }

  /// Removes an FCM token (e.g. on sign-out).
  Future<void> removeFcmToken(String uid, String token) {
    return _col.doc(uid).update({
      'fcmTokens': FieldValue.arrayRemove([token]),
    });
  }
}
