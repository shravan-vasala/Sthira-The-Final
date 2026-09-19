import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/exercise_log.dart';
import 'package:trufit_bodamma/models/habit.dart';
import 'package:trufit_bodamma/models/social_profile.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/models/workout_plan.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/providers/progress_goal_provider.dart';
import 'package:trufit_bodamma/repositories/daily_log_repository.dart';
import 'package:trufit_bodamma/repositories/exercise_log_repository.dart';
import 'package:trufit_bodamma/repositories/habit_repository.dart';
import 'package:trufit_bodamma/repositories/meal_repository.dart';

const _today = '2026-09-16';
final _clock = StateProvider<DateTime>((ref) => DateTime(2026, 9, 16, 12));

class _Daily extends DailyLogRepository {
  final logs = <String, DailyLog>{};
  final updates = StreamController<void>.broadcast();
  @override
  DailyLog? getLog(String date) => logs[date];
  @override
  Stream<void> get watchUpdates => updates.stream;
}

class _Meals extends MealRepository {
  final logs = <String, DailyMealLog>{};
  final updates = StreamController<void>.broadcast();
  @override
  DailyMealLog getDailyLog(String date) =>
      logs[date] ?? DailyMealLog(date: date);
  @override
  Stream<void> get watchUpdates => updates.stream;
}

class _Habits extends HabitRepository {
  final habits = <Habit>[];
  final completions = <String, HabitCompletion>{};
  final updates = StreamController<void>.broadcast();
  @override
  List<Habit> getHabits() => habits;
  @override
  HabitCompletion getCompletions(String date) =>
      completions[date] ?? HabitCompletion(date: date);
}

class _Exercises extends ExerciseLogRepository {
  final logs = <String, List<ExerciseLog>>{};
  final updates = StreamController<void>.broadcast();
  @override
  List<ExerciseLog> getLogsForDate(String date) => logs[date] ?? [];
  @override
  bool hasLog(String date, String instanceId) =>
      getLogsForDate(date).any((log) => log.instanceId == instanceId);
}

class _Profile extends ProfileNotifier {
  _Profile(this.value);
  final UserProfile Function() value;
  @override
  UserProfile build() {
    ref.watch(accountGenerationProvider);
    return value();
  }

  void replace(UserProfile profile) => state = profile;
}

class _Harness {
  _Harness({UserProfile? initialProfile, WorkoutPlan? workout}) {
    profile = initialProfile ?? UserProfile(name: 'A', customMealSlots: []);
    container = ProviderContainer(
      overrides: [
        clockProvider.overrideWith((ref) => ref.watch(_clock)),
        socialSnapshotClockProvider.overrideWithValue(() => snapshotTime),
        selectedDateProvider.overrideWith((ref) => DateTime(2026, 9, 6)),
        activeAccountIdProvider.overrideWith((ref) {
          ref.watch(accountGenerationProvider);
          return uid;
        }),
        activeDatabaseProvider.overrideWithValue(null),
        profileProvider.overrideWith(() => _Profile(() => profile)),
        dailyLogRepoProvider.overrideWithValue(daily),
        mealRepoProvider.overrideWithValue(meals),
        habitRepoProvider.overrideWithValue(habits),
        exerciseLogRepoProvider.overrideWithValue(exercises),
        workoutPlanProvider.overrideWithValue(workout),
        mealPlanProvider.overrideWithValue(null),
        stepsStreakProvider.overrideWithValue(0),
        progressHabitHistoryUpdatesProvider.overrideWith(
          (ref) => habits.updates.stream,
        ),
        exerciseLogsUpdateProvider.overrideWith((ref) => 0),
        exerciseRecordsUpdateProvider.overrideWith(
          (ref) => exercises.updates.stream,
        ),
      ],
    );
  }

  final daily = _Daily();
  final meals = _Meals();
  final habits = _Habits();
  final exercises = _Exercises();
  late UserProfile profile;
  String uid = 'account-a';
  DateTime snapshotTime = DateTime(2026, 9, 16, 12);
  late final ProviderContainer container;

  SocialProfile get value => container.read(mySocialProfileProvider);

  Future<SocialProfile> change(
    void Function() mutate,
    bool Function(SocialProfile) matches,
  ) async {
    final completed = Completer<SocialProfile>();
    final subscription = container.listen(mySocialProfileProvider, (_, value) {
      if (!completed.isCompleted && matches(value)) completed.complete(value);
    });
    try {
      mutate();
      return await completed.future.timeout(const Duration(seconds: 3));
    } finally {
      subscription.close();
    }
  }

  Future<void> dispose() async {
    container.dispose();
    await Future.wait([
      daily.updates.close(),
      meals.updates.close(),
      habits.updates.close(),
      exercises.updates.close(),
    ]);
  }
}

Habit _readHabit() => Habit(
  id: 'read',
  name: 'Read',
  icon: 'check',
  target: 1,
  initialCreatedAt: DateTime(2020),
);

ExerciseLog _exercise(String date, String id) => ExerciseLog(
  date: date,
  instanceId: id,
  exerciseName: 'Squat',
  sets: [SetLog(setNumber: 1, reps: 8)],
);

void main() {
  test('publication uses the injected day independently of Home selection', () {
    final harness = _Harness();
    addTearDown(harness.dispose);
    harness.daily.logs[_today] = DailyLog(date: _today, steps: 600);
    harness.daily.logs['2026-09-06'] = DailyLog(
      date: '2026-09-06',
      steps: 99000,
    );
    final first = harness.value;
    expect(first.statsDate, _today);
    expect(first.lastUpdatedAt, DateTime(2026, 9, 16, 12));
    expect(first.weekStartDate, '2026-09-14');
    expect(first.todaySteps, 600);

    harness.container.read(selectedDateProvider.notifier).state = DateTime(
      2026,
      9,
      13,
    );
    expect(harness.value.toJson(), first.toJson());
  });

  test(
    'calendar-week average excludes missing, previous-week and future days',
    () {
      final harness = _Harness();
      addTearDown(harness.dispose);
      harness.habits.habits.add(_readHabit());
      for (final day in ['2026-09-13', _today]) {
        harness.habits.completions[day] = HabitCompletion(
          date: day,
          completions: {'read': true},
        );
      }
      for (final day in ['2026-09-14', '2026-09-17']) {
        harness.habits.completions[day] = HabitCompletion(
          date: day,
          completions: {'read': false},
        );
      }
      final result = harness.value;
      expect(
        result.weekScore,
        50,
        reason: 'Only Monday 0 and Wednesday 100 count.',
      );
      expect(result.weekScoreRecordedDays, 2);
      expect(result.todayScore, 100);
    },
  );

  test(
    'weekly step coverage includes recorded zero without inventing missing days',
    () {
      final harness = _Harness();
      addTearDown(harness.dispose);
      for (final entry in {
        '2026-09-13': 90000,
        '2026-09-14': 0,
        _today: 600,
        '2026-09-17': 80000,
      }.entries) {
        harness.daily.logs[entry.key] = DailyLog(
          date: entry.key,
          steps: entry.value,
        );
      }
      final result = harness.value;
      expect(result.weeklySteps, 600);
      expect(result.weeklyStepsRecordedDays, 2);
      expect(result.hasStepsRecord, isTrue);
    },
  );

  test(
    'daily updates distinguish zero from clearing the last steps record',
    () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      expect(harness.value.hasStepsRecord, isFalse);
      expect(harness.value.hasKnownTodaySteps, isFalse);
      final zero = await harness.change(() {
        harness.snapshotTime = DateTime(2026, 9, 16, 12, 35);
        harness.daily.logs[_today] = DailyLog(date: _today, steps: 0);
        harness.daily.updates.add(null);
      }, (profile) => profile.hasStepsRecord == true);
      expect(zero.todaySteps, 0);
      expect(zero.lastUpdatedAt, DateTime(2026, 9, 16, 12, 35));
      expect(harness.container.read(clockProvider), DateTime(2026, 9, 16, 12));
      expect(zero.weeklyStepsRecordedDays, 1);

      final cleared = await harness.change(() {
        harness.daily.logs.remove(_today);
        harness.daily.updates.add(null);
      }, (profile) => profile.hasStepsRecord == false);
      expect(cleared.hasKnownTodaySteps, isFalse);
      expect(cleared.weeklyStepsRecordedDays, 0);
      expect(cleared.todayScore, isNull);
      expect(cleared.weekScore, isNull);
    },
  );

  test('meal-only edits and deletion refresh score coverage', () async {
    final harness = _Harness();
    addTearDown(harness.dispose);
    expect(harness.value.weekScore, isNull);
    final logged = await harness.change(() {
      harness.meals.logs[_today] = DailyMealLog(
        date: _today,
        customSlots: {'lunch': MealSlotLog(totalCalories: 1250)},
      );
      harness.meals.updates.add(null);
    }, (profile) => profile.todayScore != null);
    expect(logged.todayScore, 100);
    expect(logged.weekScoreRecordedDays, 1);
    expect(logged.hasStepsRecord, isFalse);

    final cleared = await harness.change(() {
      harness.meals.logs.clear();
      harness.meals.updates.add(null);
    }, (profile) => profile.todayScore == null);
    expect(cleared.weekScore, isNull);
    expect(cleared.weekScoreRecordedDays, 0);
  });

  test(
    'habit-only history updates retain an explicit zero then completion',
    () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      harness.habits.habits.add(_readHabit());
      expect(harness.value.todayScore, isNull);
      final zero = await harness.change(() {
        harness.habits.completions[_today] = HabitCompletion(
          date: _today,
          completions: {'read': false},
        );
        harness.habits.updates.add(null);
      }, (profile) => profile.todayScore == 0);
      expect(zero.weekScore, 0);
      expect(zero.weekScoreRecordedDays, 1);
      final complete = await harness.change(() {
        harness.habits.completions[_today] = HabitCompletion(
          date: _today,
          completions: {'read': true},
        );
        harness.habits.updates.add(null);
      }, (profile) => profile.todayScore == 100);
      expect(complete.weekScore, 100);
    },
  );

  test(
    'exercise-only records refresh coverage without claiming a finished session',
    () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      harness.habits.habits.add(_readHabit());
      harness.daily.logs['2026-09-14'] = DailyLog(
        date: '2026-09-14',
        workoutStatus: 'completed',
      );
      expect(harness.value.todayScore, isNull);
      final updated = await harness.change(() {
        harness.exercises.logs[_today] = [
          _exercise(_today, 'one'),
          _exercise(_today, 'two'),
        ];
        harness.exercises.updates.add(null);
      }, (profile) => profile.todayScore == 0);
      expect(updated.todayWorkouts, 0);
      expect(updated.weeklyWorkouts, 1);
      expect(updated.weekScoreRecordedDays, 2);
    },
  );

  test(
    'unrecorded planned rest cannot publish an earned daily or weekly score',
    () {
      final harness = _Harness(
        workout: WorkoutPlan(
          planName: 'Rest',
          days: [
            for (final day in ['monday', 'tuesday', 'wednesday'])
              WorkoutDay(dayId: day, label: 'Rest', sections: []),
          ],
        ),
      );
      addTearDown(harness.dispose);
      final result = harness.value;
      expect(result.todayScore, isNull);
      expect(result.weekScore, isNull);
      expect(result.weekScoreRecordedDays, 0);
      expect(result.weeklyWorkouts, 0);
    },
  );

  test(
    'clock rollover clears daily data and begins the new calendar week',
    () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      harness.daily.logs[_today] = DailyLog(date: _today, steps: 400);
      expect(harness.value.todaySteps, 400);
      final result = await harness.change(() {
        harness.container.read(_clock.notifier).state = DateTime(
          2026,
          9,
          21,
          0,
          1,
        );
      }, (profile) => profile.statsDate == '2026-09-21');
      expect(result.weekStartDate, '2026-09-21');
      expect(result.todaySteps, 0);
      expect(result.hasStepsRecord, isFalse);
      expect(result.weeklySteps, 0);
      expect(result.weeklyStepsRecordedDays, 0);
      expect(result.weekScore, isNull);
    },
  );

  test(
    'account rebinding replaces the publication identity and old measurements',
    () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      harness.daily.logs[_today] = DailyLog(date: _today, steps: 400);
      expect(harness.value.uid, 'account-a');
      final result = await harness.change(() {
        harness.uid = 'account-b';
        harness.profile = UserProfile(name: 'B', customMealSlots: []);
        harness.daily.logs.clear();
        harness.container.read(accountGenerationProvider.notifier).state++;
      }, (profile) => profile.uid == 'account-b');
      expect(result.name, 'B');
      expect(result.hasStepsRecord, isFalse);
      expect(result.todayScore, isNull);
      expect(result.weeklyStepsRecordedDays, 0);
    },
  );

  test(
    'private profile fields and local photos never enter the shared payload',
    () async {
      final harness = _Harness(
        initialProfile: UserProfile(
          name: '  Ananya  ',
          photoPath: r'D:\private\profile.jpg',
          currentWeight: 70,
          targetWeight: 65,
          height: 170,
          age: 31,
          gender: 'F',
          geminiApiKey: 'private-key',
          customMealSlots: [],
        ),
      );
      addTearDown(harness.dispose);
      final json = harness.value.toJson();
      expect(json['name'], 'Ananya');
      expect(json['avatarUrl'], isNull);
      for (final key in [
        'photoPath',
        'currentWeight',
        'targetWeight',
        'height',
        'age',
        'gender',
        'geminiApiKey',
        'customMealSlots',
        'allowedReaders',
      ]) {
        expect(json.containsKey(key), isFalse, reason: '$key is private.');
      }

      final withAvatar = await harness.change(() {
        (harness.container.read(profileProvider.notifier) as _Profile).replace(
          UserProfile(
            name: ' ',
            photoPath: 'assets/avatars/avatar_1.png',
            customMealSlots: [],
          ),
        );
      }, (profile) => profile.avatarUrl != null);
      expect(withAvatar.name, 'Friend');
      expect(withAvatar.avatarUrl, 'assets/avatars/avatar_1.png');
    },
  );
}
