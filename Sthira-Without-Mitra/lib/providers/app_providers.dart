import 'social_providers.dart';
export 'social_providers.dart';
import '../services/social_relationship_coordinator.dart';
import 'dart:async';
import '../models/workout_plan.dart';
import '../models/meal_plan.dart';
import '../models/body_stats.dart';
import '../models/exercise_log.dart';
import '../models/exercise_pr.dart';
import 'account_session_provider.dart';
export 'account_session_provider.dart';
import 'account_scope_provider.dart';
export 'account_scope_provider.dart';
export '../services/widget_coordinator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/social_profile.dart';
import '../models/friend.dart';
import '../models/progress_photo.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/coach_note_repository.dart';
import '../repositories/workout_repository.dart';
import '../repositories/meal_repository.dart';
import '../repositories/daily_log_repository.dart';
import '../repositories/habit_repository.dart';
import '../repositories/body_stats_repository.dart';
import '../repositories/media_repository.dart';
import '../repositories/photo_meal_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/exercise_log_repository.dart';
import '../repositories/badge_repository.dart';
import '../repositories/friend_repository.dart';
import '../services/health_connect_service.dart';
import '../services/backup_service.dart';
import '../services/coach_service.dart';
import '../services/gemini_food_service.dart';
import '../services/csv_export_service.dart';
import '../services/ai_cache.dart';
import '../services/ai_client.dart';
import '../services/social_sync_service.dart';
import '../services/nutrition_lookup_service.dart';
import '../interfaces/i_ai_food_service.dart';
import '../utils/time_utils.dart';
import 'auth_provider.dart';
import 'credential_provider.dart';

export 'rest_timer_provider.dart';
export 'phase_progress_provider.dart';
export 'theme_provider.dart';
export 'daily_score_provider.dart';
export 'yearly_heatmap_provider.dart';
export 'auth_provider.dart';
export 'habit_providers.dart';
export 'workout_providers.dart';
export 'meal_providers.dart';
export 'profile_providers.dart';
export 'daily_log_notifier.dart';
export 'coach_note_notifier.dart';
export 'sync_controller.dart';
export 'gamification_provider.dart';

final clockProvider = Provider<DateTime>((ref) => DateTime.now());

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('prefs must be overridden in ProviderScope');
});

final onboardingCompletedProvider =
    NotifierProvider<OnboardingCompletedNotifier, bool>(() {
      return OnboardingCompletedNotifier();
    });

class OnboardingCompletedNotifier extends Notifier<bool> {
  static const String _onboardingKey = 'onboarding_completed';
  late SharedPreferences _prefs;

  @override
  bool build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    return _prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> commitLocalSetup() async {
    await _prefs.setBool(_onboardingKey, true);
  }

  void completeRoute() {
    state = true;
  }
}

// ── Date ──
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final dateStringProvider = Provider<String>((ref) {
  final date = ref.watch(selectedDateProvider);
  return todayKey(date);
});

final weekOffsetProvider = StateProvider<int>((ref) => 0);

// ── Repositories (singletons) ──
final workoutRepoProvider = Provider<WorkoutRepository>((ref) {
  throw UnimplementedError('Must be overridden in main');
});
final mealRepoProvider = Provider<MealRepository>((ref) {
  throw UnimplementedError('Must be overridden in main');
});
final dailyLogRepoProvider = Provider<DailyLogRepository>((ref) {
  throw UnimplementedError('Must be overridden in main');
});
final dailyLogsUpdateProvider = StreamProvider<void>((ref) {
  ref.watch(accountGenerationProvider);
  final repo = ref.watch(dailyLogRepoProvider);
  return repo.watchUpdates;
});

final dailyMealLogsUpdateProvider = StreamProvider<void>((ref) {
  ref.watch(accountGenerationProvider);
  final repo = ref.watch(mealRepoProvider);
  return repo.watchUpdates;
});
final habitRepoProvider = Provider<HabitRepository>((ref) {
  throw UnimplementedError('Must be overridden in main');
});
final bodyStatsRepoProvider = Provider<BodyStatsRepository>((ref) {
  throw UnimplementedError('Must be overridden in main');
});
final mediaRepoProvider = Provider<MediaRepository>((ref) {
  throw UnimplementedError('Must be overridden in main');
});
final progressPhotosStreamProvider = StreamProvider<void>((ref) {
  ref.watch(accountGenerationProvider);
  final repo = ref.watch(mediaRepoProvider);
  // We only care about changes to progress photos to trigger reminder updates
  return repo.isar.progressPhotos.watchLazy(fireImmediately: true);
});
final photoMealRepoProvider = Provider<PhotoMealRepository>((ref) {
  throw UnimplementedError('Must be overridden in main');
});
final profileRepoProvider = Provider<ProfileRepository>((ref) {
  throw UnimplementedError('Must be overridden in main');
});
final exerciseLogRepoProvider = Provider<ExerciseLogRepository>((ref) {
  throw UnimplementedError('Must be overridden in main');
});
final coachNoteRepoProvider = Provider<CoachNoteRepository>((ref) {
  throw UnimplementedError('Must be overridden in main');
});
final badgeRepoProvider = Provider<BadgeRepository>((ref) {
  throw UnimplementedError('Must be overridden in main');
});
final friendRepoProvider = Provider<FriendRepository>((ref) {
  throw UnimplementedError('Must be overridden in main');
});
final friendsListStreamProvider = StreamProvider<List<Friend>>((ref) {
  ref.watch(accountGenerationProvider);
  final repo = ref.watch(friendRepoProvider);
  return repo.isar.friends.where().sortByAddedAtDesc().watch(
    fireImmediately: true,
  );
});
final healthConnectServiceProvider = Provider<HealthConnectService>((ref) {
  throw UnimplementedError('Must be overridden in main');
});
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    ref.watch(authServiceProvider),
    databaseResolver: () => ref.read(profileRepoProvider).isar,
    beforeRestore: (database) =>
        ref.read(accountSessionProvider).beforeRestore(database),
    afterRestore: (database, committed) =>
        ref.read(accountSessionProvider).afterRestore(database, committed),
  );
});
final socialSyncServiceProvider = Provider<SocialSyncService>((ref) {
  ref.watch(accountGenerationProvider);
  final service = SocialSyncService(
    ref.watch(authServiceProvider),
    accountId: ref.watch(activeAccountIdProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
final socialErrorProvider = StateProvider<String?>((ref) {
  ref.watch(accountGenerationProvider);
  return null;
});
final socialRelationshipProvider = Provider<SocialRelationshipCoordinator?>((
  ref,
) {
  final generation = ref.watch(accountGenerationProvider);
  final transitioning = ref.watch(accountTransitionProvider);
  final hydrating = ref.watch(accountHydratingProvider);
  final service = ref.watch(socialSyncServiceProvider);
  if (transitioning || hydrating || !service.canSync) return null;
  final coordinator = SocialRelationshipCoordinator(
    service: service,
    friends: ref.watch(friendRepoProvider),
    isCurrent: () =>
        generation == ref.read(accountGenerationProvider) &&
        !ref.read(accountTransitionProvider),
    onError: (error) =>
        ref.read(socialErrorProvider.notifier).state = error.toString(),
  );
  ref.onDispose(coordinator.dispose);
  coordinator.start();
  return coordinator;
});
final socialPushControllerProvider = Provider<void>((ref) {
  ref.watch(socialRelationshipProvider);
  final transitioning = ref.watch(accountTransitionProvider);
  final hydrating = ref.watch(accountHydratingProvider);
  ref.watch(accountGenerationProvider);
  final service = ref.watch(socialSyncServiceProvider);
  if (transitioning || hydrating || !service.canSync) return;
  void push(SocialProfile profile) {
    if (!service.canSync || ref.read(accountTransitionProvider)) return;
    unawaited(
      service.pushProfile(profile).catchError((Object error) {
        if (service.canSync)
          ref.read(socialErrorProvider.notifier).state = error.toString();
      }),
    );
  }

  ref.listen(mySocialProfileProvider, (_, profile) => push(profile));
  Future.microtask(() {
    if (service.canSync && !ref.read(accountTransitionProvider)) {
      push(ref.read(mySocialProfileProvider));
    }
  });
});

final friendProfileStreamProvider = StreamProvider.autoDispose
    .family<SocialProfile?, String>((ref, uid) {
      ref.watch(accountGenerationProvider);
      if (ref.watch(accountTransitionProvider) ||
          ref.watch(accountHydratingProvider))
        return Stream.value(null);
      final syncService = ref.watch(socialSyncServiceProvider);
      return syncService.streamFriendProfile(uid);
    });

final csvExportServiceProvider = Provider<CsvExportService>((ref) {
  return CsvExportService(
    databaseResolver: () => ref.read(profileRepoProvider).isar,
    accountIdResolver: () => ref.read(authServiceProvider).uid,
  );
});

final aiCacheProvider = Provider<AiCache>((ref) {
  ref.watch(accountGenerationProvider);
  final database = ref.watch(activeDatabaseProvider);
  return AiCache(databaseResolver: () => database);
});

final aiClientProvider = Provider<AiClient>((ref) {
  final client = AiClient(cache: ref.watch(aiCacheProvider));
  ref.onDispose(() => client.dispose());
  return client;
});

final nutritionLookupServiceProvider = Provider<NutritionLookupService>((ref) {
  final database = ref.watch(activeDatabaseProvider);
  return NutritionLookupService(database: database);
});

enum CloudSyncState { idle, syncing, success, error }

final cloudSyncControllerProvider =
    NotifierProvider<CloudSyncController, CloudSyncState>(
      CloudSyncController.new,
    );

class CloudSyncController extends Notifier<CloudSyncState> {
  String? errorMessage;

  @override
  CloudSyncState build() {
    return CloudSyncState.idle;
  }

  Future<void> signInAndSync() async {
    state = CloudSyncState.syncing;
    errorMessage = null;
    try {
      await ref.read(accountSessionProvider).signIn();
      state = CloudSyncState.success;
    } catch (error) {
      errorMessage = error.toString().replaceAll('Exception: ', '');
      state = CloudSyncState.error;
    }
  }
}

final geminiFoodServiceProvider = Provider<IAiFoodService>((ref) {
  final credentialState = ref.watch(credentialProvider);
  return GeminiFoodService(
    accountId: ref.watch(activeAccountIdProvider),
    apiKey: credentialState.key,
    aiClient: ref.watch(aiClientProvider),
    nutritionLookup: ref.watch(nutritionLookupServiceProvider),
  );
});

final coachServiceProvider = Provider<CoachService>((ref) {
  final key = ref.watch(credentialProvider.select((s) => s.key));
  return CoachService(apiKey: key, aiClient: ref.watch(aiClientProvider));
});

final stepsSourceProvider = StateProvider<StepsSource>(
  (ref) => StepsSource.none,
);

// ── End of file ──

final friendRequestsProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) {
  ref.watch(accountGenerationProvider);
  if (ref.watch(accountTransitionProvider) ||
      ref.watch(accountHydratingProvider)) {
    return Stream.value(const []);
  }
  final service = ref.watch(socialSyncServiceProvider);
  return service.canSync
      ? service.streamFriendRequests()
      : Stream.value(const []);
});

final friendRequestsCountProvider = Provider<AsyncValue<int>>((ref) {
  return ref
      .watch(friendRequestsProvider)
      .whenData((requests) => requests.length);
});

final syncPendingCountProvider = StreamProvider<int>((ref) {
  ref.watch(accountGenerationProvider);
  final sync = ref.watch(firestoreSyncServiceProvider);
  return sync.pendingCountStream;
});

final planRecordsUpdateProvider = StreamProvider<void>((ref) {
  final database = ref.watch(activeDatabaseProvider);
  if (database == null) return const Stream.empty();
  final controller = StreamController<void>();
  final subs = [
    database.mealPlans.watchLazy().listen(controller.add),
    database.workoutPlans.watchLazy().listen(controller.add),
  ];
  ref.onDispose(() {
    for (final sub in subs) {
      sub.cancel();
    }
    controller.close();
  });
  return controller.stream;
});
final bodyStatsUpdateProvider = StreamProvider<void>((ref) {
  return ref.watch(activeDatabaseProvider)?.bodyStats.watchLazy() ??
      const Stream.empty();
});
final exerciseRecordsUpdateProvider = StreamProvider<void>((ref) {
  final database = ref.watch(activeDatabaseProvider);
  if (database == null) return const Stream.empty();
  final controller = StreamController<void>();
  final subs = [
    database.exerciseLogs.watchLazy().listen(controller.add),
    database.exercisePrs.watchLazy().listen(controller.add),
  ];
  ref.onDispose(() {
    for (final sub in subs) {
      sub.cancel();
    }
    controller.close();
  });
  return controller.stream;
});
