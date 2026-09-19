import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../interfaces/i_auth_service.dart';

class AuthService implements IAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Web Client ID from google-services.json to explicitly avoid Error 10
    serverClientId:
        '611231023306-pdpsdsikt8vua5b8jo35h4fltourlmp4.apps.googleusercontent.com',
  );

  /// Stream of auth state changes
  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current user (null if not signed in)
  @override
  User? get currentUser => _auth.currentUser;

  /// Whether user is currently signed in
  @override
  bool get isSignedIn => _auth.currentUser != null;

  /// User's UID (null if not signed in)
  @override
  String? get uid => _auth.currentUser?.uid;

  /// User's display name
  @override
  String? get displayName => _auth.currentUser?.displayName;

  /// User's email
  @override
  String? get email => _auth.currentUser?.email;

  /// User's photo URL
  @override
  String? get photoUrl => _auth.currentUser?.photoURL;

  /// Sign in with Google
  @override
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint('AuthService: Signed in as ${userCredential.user?.email}');
      return userCredential.user;
    } catch (e) {
      debugPrint('AuthService: Google sign-in error: $e');
      rethrow;
    }
  }

  /// Sign out
  @override
  Future<void> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
      debugPrint('AuthService: Signed out');
    } catch (e) {
      debugPrint('AuthService: Sign out error: $e');
      rethrow;
    }
  }

  /// Delete account
  @override
  Future<void> deleteAccount() async {
    // This unexposed API must not delete login credentials while orphaning
    // private Firestore/media records. Enable only with server-side cleanup.
    throw UnsupportedError(
      'Account deletion requires complete cloud and local data cleanup.',
    );
  }
}
