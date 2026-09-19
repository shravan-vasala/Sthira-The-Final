import 'package:firebase_auth/firebase_auth.dart';

abstract class IAuthService {
  Stream<User?> get authStateChanges;

  User? get currentUser;

  bool get isSignedIn;

  String? get uid;

  String? get displayName;

  String? get email;

  String? get photoUrl;

  Future<User?> signInWithGoogle();

  Future<void> signOut();

  Future<void> deleteAccount();
}
