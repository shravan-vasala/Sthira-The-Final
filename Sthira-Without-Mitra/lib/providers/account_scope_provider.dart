import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'app_providers.dart' show profileRepoProvider;

/// Invalidates account-bound work before and after repository rebinding.
final accountGenerationProvider = StateProvider<int>((ref) => 0);
final accountTransitionProvider = StateProvider<bool>((ref) => false);
final activeDatabaseProvider = Provider<Isar?>((ref) {
  ref.watch(accountGenerationProvider);
  try {
    final database = ref.watch(profileRepoProvider).isar;
    return database.isOpen ? database : null;
  } catch (_) {
    return null;
  }
});
final activeAccountIdProvider = Provider<String>((ref) {
  return ref.watch(activeDatabaseProvider)?.name ?? 'guest';
});

final recoveredAccountProvider = StateProvider<String?>((ref) => null);

final accountHydratingProvider = StateProvider<bool>((ref) => false);
