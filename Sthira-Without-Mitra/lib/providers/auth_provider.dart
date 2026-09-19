import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/firestore_sync_service.dart';
import '../interfaces/i_cloud_sync_service.dart';

import '../interfaces/i_auth_service.dart';

/// Singleton AuthService
final authServiceProvider = Provider<IAuthService>((ref) {
  return AuthService();
});

/// Stream of Firebase Auth state changes
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Whether the user is currently signed in
final isSignedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, _) => false,
  );
});

/// The current user's display name
final userDisplayNameProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user?.displayName,
    loading: () => null,
    error: (_, _) => null,
  );
});

/// The current user's email
final userEmailProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user?.email,
    loading: () => null,
    error: (_, _) => null,
  );
});

/// The current user's photo URL
final userPhotoUrlProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user?.photoURL,
    loading: () => null,
    error: (_, _) => null,
  );
});

/// Firestore sync service — depends on auth being available
final firestoreSyncServiceProvider = Provider<ICloudSyncService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return FirestoreSyncService(authService);
});
