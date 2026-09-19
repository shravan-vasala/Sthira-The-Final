import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_providers.dart';
import '../models/user_profile.dart';
import '../models/body_stats.dart';

final latestBodyStatsProvider = Provider<BodyStats?>((ref) {
  ref.watch(bodyStatsUpdateProvider);
  ref.watch(accountGenerationProvider);
  return ref.watch(bodyStatsRepoProvider).getLatestStats();
});

class ProfileNotifier extends Notifier<UserProfile> {
  int _generation = 0;
  @override
  UserProfile build() {
    final generation = ++_generation;
    ref.watch(accountGenerationProvider);
    final repo = ref.watch(profileRepoProvider);

    final sub = repo.watchProfile().listen((profile) {
      if (generation == _generation && profile != null) {
        state = profile;
      }
    });

    ref.onDispose(() {
      _generation++;
      sub.cancel();
    });

    return repo.getProfile();
  }

  Future<void> updateProfile(UserProfile profile) async {
    final generation = _generation;
    state = profile;
    final repo = ref.read(profileRepoProvider);
    try {
      await repo.saveProfile(profile);
    } catch (_) {
      if (generation == _generation) state = repo.getProfile();
      rethrow;
    }
  }

  Future<void> toggleUnit() async {
    state = state.copyWith(useKg: !state.useKg);
    final repo = ref.read(profileRepoProvider);
    final generation = _generation;
    await repo.toggleUnit();
    if (generation != _generation) return;
    state = repo.getProfile();
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, UserProfile>(
  ProfileNotifier.new,
);
