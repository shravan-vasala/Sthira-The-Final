import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:trufit_bodamma/interfaces/i_auth_service.dart';
import 'package:trufit_bodamma/interfaces/i_cloud_sync_service.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/providers/account_session_provider.dart';
import 'package:trufit_bodamma/repositories/profile_repository.dart';
import 'package:trufit_bodamma/repositories/workout_repository.dart';
import 'package:trufit_bodamma/repositories/meal_repository.dart';
import 'package:trufit_bodamma/repositories/daily_log_repository.dart';
import 'package:trufit_bodamma/repositories/habit_repository.dart';
import 'package:trufit_bodamma/repositories/body_stats_repository.dart';
import 'package:trufit_bodamma/repositories/exercise_log_repository.dart';
import 'package:trufit_bodamma/repositories/coach_note_repository.dart';
import 'package:trufit_bodamma/repositories/badge_repository.dart';
import '../helpers/test_isar_setup.dart';

class _Auth implements IAuthService {
  @override
  String? get uid => null;
  @override
  bool get isSignedIn => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FailingDrain implements ICloudSyncService {
  int attempts = 0;
  int resumes = 0;
  @override
  bool get canSync => false;
  @override
  String? get currentUid => null;
  @override
  Future<void> pauseAndDrainSync() async {
    attempts++;
    throw StateError('drain failed');
  }

  @override
  void resumeSync() {
    resumes++;
  }

  @override
  void pauseSync() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Isar database;
  late _FailingDrain sync;
  late ProviderContainer container;
  setUp(() async {
    database = await setUpTestIsar();
    final profile = ProfileRepository();
    await profile.init(database);
    sync = _FailingDrain();
    container = ProviderContainer(
      overrides: [
        profileRepoProvider.overrideWithValue(profile),
        firestoreSyncServiceProvider.overrideWithValue(sync),
        authServiceProvider.overrideWithValue(_Auth()),
        workoutRepoProvider.overrideWithValue(WorkoutRepository()),
        mealRepoProvider.overrideWithValue(MealRepository()),
        dailyLogRepoProvider.overrideWithValue(DailyLogRepository()),
        habitRepoProvider.overrideWithValue(HabitRepository()),
        bodyStatsRepoProvider.overrideWithValue(BodyStatsRepository()),
        exerciseLogRepoProvider.overrideWithValue(ExerciseLogRepository()),
        coachNoteRepoProvider.overrideWithValue(CoachNoteRepository()),
        badgeRepoProvider.overrideWithValue(BadgeRepository()),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await tearDownTestIsar(database);
  });
  test(
    'failed restore preparation clears its barrier and allows a retry',
    () async {
      final session = container.read(accountSessionProvider);
      await expectLater(session.beforeRestore(database), throwsStateError);
      expect(container.read(accountTransitionProvider), isFalse);
      final firstGeneration = container.read(accountGenerationProvider);
      await expectLater(session.beforeRestore(database), throwsStateError);
      expect(
        sync.attempts,
        2,
        reason: 'A failed prepare must not leave the restoring flag set',
      );
      expect(sync.resumes, 2);
      expect(
        container.read(accountGenerationProvider),
        greaterThan(firstGeneration),
      );
    },
  );
  test('failed sign-in drain resumes the local session', () async {
    await expectLater(
      container.read(accountSessionProvider).signIn(),
      throwsStateError,
    );
    expect(sync.resumes, greaterThan(0));
    expect(container.read(accountTransitionProvider), isFalse);
  });
}
