import 'dart:async';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/exercise_log.dart';
import 'package:trufit_bodamma/models/habit.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/providers/badge_engine_provider.dart';
import 'package:trufit_bodamma/repositories/badge_repository.dart';
import 'package:trufit_bodamma/repositories/meal_repository.dart';
import 'package:trufit_bodamma/repositories/daily_log_repository.dart';
import 'package:trufit_bodamma/screens/profile/widgets/journey_stats_strip.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';
import '../helpers/test_isar_setup.dart';

class _Logs extends Fake implements DailyLogRepository {
  List<DailyLog> values = [];
  @override
  List<DailyLog> getAllLogs() => values;
  @override
  Stream<String> get watchLocalWorkoutCompletions => const Stream.empty();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'recorded streak is not capped at 30 days and ignores future entries',
    () {
      final today = DateTime(2026, 9, 19);
      final dates = List.generate(
        90,
        (i) => DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime(today.year, today.month, today.day - i)),
      );
      expect(currentRecordedStreak([...dates, '2026-09-20'], today), 90);
      expect(currentRecordedStreak(dates.skip(1), today), 89);
      expect(currentRecordedStreak(['2026-09-17'], today), 0);
    },
  );

  test(
    'workout badges count actual consecutive completions with missing dates breaking a run',
    () {
      final logs = [
        DailyLog(date: '2026-09-19', workoutStatus: 'completed'),
        DailyLog(date: '2026-09-17', workoutStatus: 'completed'),
        DailyLog(date: '2026-09-16', workoutStatus: 'completed'),
        DailyLog(date: '2026-09-18', steps: 12000),
        DailyLog(date: '2026-09-20', workoutStatus: 'completed'),
      ];
      expect(longestCompletedWorkoutStreak(logs, DateTime(2026, 9, 19)), 2);
    },
  );

  test(
    'steps streak uses configured type and scheduled days, with no invented goal',
    () {
      final logs = [
        DailyLog(date: '2026-09-17', steps: 7000),
        DailyLog(date: '2026-09-18', steps: 7000),
      ];
      final habit = Habit(
        id: 'walk',
        name: 'Move',
        icon: 'walk',
        type: HabitType.autoSteps,
        target: 6500,
        activeDays: [1, 2, 3, 4, 5],
        initialCreatedAt: DateTime(2026, 1, 1),
      );
      expect(
        scheduledStepsStreak(
          logs: logs,
          habits: [habit],
          now: DateTime(2026, 9, 20),
        ),
        2,
      );
      expect(
        scheduledStepsStreak(
          logs: [],
          habits: [habit],
          now: DateTime(2026, 9, 20),
          habitRecords: [
            HabitCompletion(date: '2026-09-17', overrides: {'walk': 'done'}),
            HabitCompletion(date: '2026-09-18', overrides: {'walk': 'done'}),
          ],
        ),
        2,
      );
      expect(
        scheduledStepsStreak(
          logs: logs,
          habits: [],
          now: DateTime(2026, 9, 20),
        ),
        0,
      );
      expect(
        scheduledStepsStreak(
          logs: logs,
          habits: [habit],
          now: DateTime(2026, 9, 22),
        ),
        0,
      );
    },
  );

  test(
    'journey includes habit and exercise only records, without invented workouts or future dates',
    () {
      final stats = JourneyStats.fromRecords(
        daily: [DailyLog(date: '2026-09-16', workoutStatus: 'completed')],
        meals: [
          DailyMealLog(
            date: '2026-09-19',
            customSlots: {'lunch': MealSlotLog(totalCalories: 300)},
          ),
        ],
        habits: [
          HabitCompletion(date: '2026-09-17', overrides: {'water': 'notDone'}),
        ],
        exercises: [
          ExerciseLog(
            date: '2026-09-18',
            instanceId: 'one',
            exerciseName: 'Squat',
            sets: [SetLog(reps: 10)],
          ),
          ExerciseLog(
            date: '2026-09-20',
            instanceId: 'two',
            exerciseName: 'Squat',
            sets: [SetLog(reps: 10)],
          ),
        ],
        now: DateTime(2026, 9, 19),
        earnedBadges: 2,
      );
      expect(stats.trackedDays, 4);
      expect(stats.completedWorkouts, 1);
      expect(stats.streak, 4);
      expect(stats.earnedBadges, 2);
      expect(stats.firstTrackedDate, DateTime(2026, 9, 16));
    },
  );

  testWidgets('journey cards remain readable at 320px and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journeyStatsProvider.overrideWithValue(const JourneyStats()),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: JourneyStatsStrip(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Workouts'), findsOneWidget);
    expect(
      find.text('Your journey starts with your first log.'),
      findsOneWidget,
    );
  });

  group('native badge persistence and updates', () {
    late Isar isar;
    late BadgeRepository repo;
    late MealRepository meals;
    setUp(() async {
      isar = await setUpTestIsar();
      repo = BadgeRepository();
      await repo.init(isar);
      meals = MealRepository();
      await meals.init(isar);
    });
    tearDown(() async {
      await repo.detachSync();
      await tearDownTestIsar(isar);
    });

    test(
      'earned badges remain earned and stale account evaluation cannot write',
      () async {
        final original = repo.getBadge('first_workout')!;
        await repo.saveBadge(
          original.copyWith(
            currentProgress: 1,
            unlockedAt: DateTime(2026, 9, 1),
          ),
        );
        await repo.saveBadge(original);
        expect(repo.getBadge('first_workout')!.isUnlocked, isTrue);
        await repo.saveBadge(
          repo.getBadge('workout_10')!.copyWith(currentProgress: 10),
          isCurrent: () => false,
        );
        expect(repo.getBadge('workout_10')!.currentProgress, 0);
      },
    );

    test(
      'local workout completion celebrates once and later corrections stay quiet',
      () async {
        final daily = DailyLogRepository();
        await daily.init(isar);
        final container = ProviderContainer(
          overrides: [
            dailyLogRepoProvider.overrideWithValue(daily),
            mealRepoProvider.overrideWithValue(meals),
            badgeRepoProvider.overrideWithValue(repo),
            clockProvider.overrideWithValue(DateTime(2026, 9, 19)),
          ],
        );
        addTearDown(() {
          container.dispose();
          daily.dispose();
        });
        container.read(badgeEngineProvider);
        await Future<void>.delayed(Duration.zero);
        final earned = Completer<void>();
        final subscription = container.listen(badgeUnlockEventProvider, (
          _,
          badges,
        ) {
          if (badges.any((badge) => badge.id == 'first_workout') &&
              !earned.isCompleted) {
            earned.complete();
          }
        });
        addTearDown(subscription.close);
        await daily.updateWorkoutStatus('2026-09-19', 'day_1', 'completed');
        await earned.future.timeout(const Duration(seconds: 5));
        expect(container.read(badgeUnlockEventProvider), hasLength(1));
        container.read(badgeUnlockEventProvider.notifier).clear();
        await daily.updateWorkoutStatus('2026-09-19', 'day_1', 'partial');
        await daily.updateWorkoutStatus('2026-09-19', 'day_1', 'completed');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(container.read(badgeUnlockEventProvider), isEmpty);
      },
    );

    test(
      'background dated completion update unlocks, unrelated activity does not',
      () async {
        final logs = _Logs()
          ..values = [
            DailyLog(date: '2026-09-17', steps: 10000),
            DailyLog(date: '2026-09-18', steps: 10000),
            DailyLog(date: '2026-09-19', steps: 10000),
          ];
        final changes = StreamController<void>.broadcast();
        final container = ProviderContainer(
          overrides: [
            dailyLogRepoProvider.overrideWithValue(logs),
            badgeRepoProvider.overrideWithValue(repo),
            mealRepoProvider.overrideWithValue(meals),
            dailyLogsUpdateProvider.overrideWith((ref) => changes.stream),
            clockProvider.overrideWithValue(DateTime(2026, 9, 19)),
          ],
        );
        addTearDown(() async {
          container.dispose();
          await changes.close();
        });
        container.read(badgeEngineProvider);
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(repo.getBadge('streak_3')!.isUnlocked, isFalse);
        final unlocked = repo.watchUpdates.firstWhere(
          (_) => repo.getBadge('streak_3')!.isUnlocked,
        );
        logs.values = [
          DailyLog(date: '2026-09-17', workoutStatus: 'completed'),
          DailyLog(date: '2026-09-18', workoutStatus: 'completed'),
          DailyLog(date: '2026-09-19', workoutStatus: 'completed'),
        ];
        changes.add(null);
        await unlocked.timeout(const Duration(seconds: 5));
        expect(repo.getBadge('streak_3')!.isUnlocked, isTrue);
        expect(repo.getBadge('first_workout')!.isUnlocked, isTrue);
        expect(container.read(badgeUnlockEventProvider), isEmpty);
      },
    );
  });
}
