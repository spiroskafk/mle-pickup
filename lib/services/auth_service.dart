import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user.dart';
import '../repositories/user_repository.dart';

/// Wraps Firebase Auth (email + Google) and ensures a `users/{uid}` profile
/// exists after sign-in.
class AuthService {
  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    UserRepository? userRepository,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _users = userRepository ?? UserRepository();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final UserRepository _users;

  /// Emits the current Firebase user (or null) on every auth state change.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Signs in with email/password. Throws [FirebaseAuthException] on failure —
  /// callers surface the message to the user (unlike the old project, we never
  /// dereference a null user after a failed sign-in).
  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Registers a new email/password account and creates its profile.
  Future<void> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user;
    if (user == null) return;
    await user.updateDisplayName(displayName);
    await _ensureProfile(user, fallbackName: displayName);
  }

  /// Google sign-in via Firebase credential exchange.
  Future<void> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return; // user cancelled
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    final user = cred.user;
    if (user != null) {
      await _ensureProfile(user, fallbackName: user.displayName ?? 'Player');
    }
  }

  Future<void> signOut() async {
    // Google sign-out is best-effort: it can throw when there's no Google
    // session (e.g. the user signed in with email, or on web/emulator).
    // It must never block the Firebase sign-out, which is the one that matters.
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // ignore — no active Google session to clear
    }
    await _auth.signOut();
  }

  Future<void> _ensureProfile(User user, {required String fallbackName}) {
    return _users.ensureExists(
      AppUser(
        uid: user.uid,
        displayName: user.displayName ?? fallbackName,
        photoUrl: user.photoURL,
      ),
    );
  }
}
