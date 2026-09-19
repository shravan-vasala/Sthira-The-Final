import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/habit.dart';
import 'package:trufit_bodamma/models/meal_plan.dart';
import 'package:trufit_bodamma/models/workout_plan.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/repositories/daily_log_repository.dart';
import 'package:trufit_bodamma/repositories/meal_repository.dart';
import 'package:trufit_bodamma/repositories/habit_repository.dart';
import 'package:trufit_bodamma/repositories/workout_repository.dart';
import 'package:trufit_bodamma/repositories/exercise_log_repository.dart';
import 'package:trufit_bodamma/utils/meal_completion.dart';

const _channel = MethodChannel('home_widget');
const _date = '2026-09-19';

class _Daily extends DailyLogRepository {
  final logs = <String, DailyLog>{};
  final updates = StreamController<void>.broadcast();
  @override
  Stream<void> get watchUpdates => updates.stream;
  @override
  DailyLog? getLog(String date) => logs[date];
}

class _Meals extends MealRepository {
  @override
  Stream<void> get watchUpdates => const Stream.empty();
  @override
  MealPlan? getMealPlan(String key) => null;
  @override
  DailyMealLog getDailyLog(String date) => DailyMealLog(
    date: date,
    customSlots: {'lunch': MealSlotLog(totalCalories: 250)},
  );
}

class _Habits extends HabitRepository {
  _Habits(this.habits);
  final List<Habit> habits;
  @override
  Stream<void> get watchUpdates => const Stream.empty();
  @override
  List<Habit> getHabits() => habits;
  @override
  HabitCompletion getCompletions(String date) => HabitCompletion(date: date);
}

class _Exercises extends ExerciseLogRepository {
  @override
  Stream<void> get watchUpdates => const Stream.empty();
}

class _Workouts extends WorkoutRepository {
  @override
  WorkoutPlan? getActivePlan({String? preferredKey}) => null;
}

class _Profile extends ProfileNotifier {
  _Profile(this.profile);
  final UserProfile profile;
  @override
  UserProfile build() => profile;
}

class _Harness {
  _Harness({required List<Habit> habits}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          if (call.method == 'saveWidgetData') {
            final args = call.arguments as Map;
            if (args['id'] == 'widget_data') {
              _pending =
                  jsonDecode(args['data'] as String) as Map<String, dynamic>;
            }
          } else if (call.method == 'updateWidget' && _pending != null) {
            snapshots.add(_pending!);
            _pending = null;
          }
          return true;
        });
    container = ProviderContainer(
      overrides: [
        clockProvider.overrideWith((ref) => now),
        dailyLogRepoProvider.overrideWithValue(daily),
        mealRepoProvider.overrideWithValue(meals),
        habitRepoProvider.overrideWithValue(_Habits(habits)),
        workoutRepoProvider.overrideWithValue(_Workouts()),
        exerciseLogRepoProvider.overrideWithValue(_Exercises()),
        activeDatabaseProvider.overrideWithValue(null),
        profileProvider.overrideWith(() => _Profile(profile)),
        workoutPlanProvider.overrideWithValue(null),
      ],
    );
  }
  DateTime now = DateTime(2026, 9, 19, 23, 59);
  final daily = _Daily();
  final meals = _Meals();
  final profile = UserProfile(
    customMealSlots: [
      {'id': 'lunch', 'name': 'Lunch', 'isDefault': true},
      {'id': 'dinner', 'name': 'Dinner', 'isDefault': true},
    ],
  );
  final snapshots = StreamController<Map<String, dynamic>>.broadcast();
  Map<String, dynamic>? _pending;
  late final ProviderContainer container;

  Future<Map<String, dynamic>> start() {
    final result = nextSnapshot();
    container.read(widgetCoordinatorProvider);
    return result;
  }

  // Wait for the real coordinator's debounce and native save/update sequence.
  Future<Map<String, dynamic>> nextSnapshot() =>
      snapshots.stream.first.timeout(const Duration(seconds: 5));
  Future<void> dispose() async {
    container.dispose();
    await daily.updates.close();
    await snapshots.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  }
}

Habit _stepHabit({
  String id = 'walk',
  double target = 8000,
  List<int>? activeDays,
  DateTime? createdAt,
  GoalDirection direction = GoalDirection.atLeast,
}) => Habit(
  id: id,
  name: 'Steps',
  icon: 'walk',
  type: HabitType.autoSteps,
  target: target,
  activeDays: activeDays,
  initialCreatedAt: createdAt ?? DateTime(2020),
  goalDirection: direction,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final unavailableGoals = <String, List<Habit>>{
    'no configured goal': [],
    'paused goal': [_stepHabit(activeDays: [])],
    'off-day goal': [
      _stepHabit(activeDays: [DateTime.monday]),
    ],
    'future-created goal': [_stepHabit(createdAt: DateTime(2026, 9, 20))],
    'conflicting active goals': [
      _stepHabit(),
      _stepHabit(id: 'other', target: 10000),
    ],
    'at-most goal': [_stepHabit(direction: GoalDirection.atMost)],
    'mixed active directions': [
      _stepHabit(),
      _stepHabit(id: 'other', direction: GoalDirection.atMost),
    ],
    'zero target': [_stepHabit(target: 0)],
    'non-finite target': [_stepHabit(target: double.infinity)],
  };
  for (final entry in unavailableGoals.entries) {
    test('widget suppresses ${entry.key}', () async {
      final harness = _Harness(habits: entry.value);
      addTearDown(harness.dispose);
      final snapshot = await harness.start();
      expect(snapshot['date'], _date);
      expect(snapshot['stepGoal'], isNull);
    });
  }

  test(
    'equal active step targets are accepted while inactive targets are ignored',
    () async {
      final harness = _Harness(
        habits: [
          _stepHabit(createdAt: DateTime(2026, 9, 19, 23, 59)),
          _stepHabit(id: 'same', activeDays: [DateTime.saturday]),
          _stepHabit(id: 'paused', target: 12000, activeDays: []),
          _stepHabit(
            id: 'off-day',
            target: 10000,
            activeDays: [DateTime.sunday],
          ),
        ],
      );
      addTearDown(harness.dispose);
      final snapshot = await harness.start();
      expect(snapshot['stepGoal'], 8000);
      expect(snapshot['totalHabits'], 2);
    },
  );

  test('widget distinguishes missing steps from a recorded zero', () async {
    final harness = _Harness(habits: [_stepHabit()]);
    addTearDown(harness.dispose);
    expect((await harness.start())['steps'], isNull);
    final next = harness.nextSnapshot();
    harness.daily.logs[_date] = DailyLog(date: _date, steps: 0);
    harness.daily.updates.add(null);
    final recorded = await next;
    expect(recorded['steps'], 0);
    expect(recorded['stepGoal'], 8000);
  });

  test('widget uses the same two-slot meal denominator as Home', () async {
    final harness = _Harness(habits: []);
    addTearDown(harness.dispose);
    final snapshot = await harness.start();
    final expected = MealCompletion.calculateTotalMeals(
      harness.profile,
      harness.meals.getDailyLog(_date),
    );
    expect(expected, 2);
    expect(snapshot['totalMeals'], expected);
    expect(snapshot['mealsLogged'], 1);
  });

  test(
    'active coordinator refreshes a cached date after suspension spans midnight',
    () async {
      final harness = _Harness(
        habits: [
          _stepHabit(activeDays: [DateTime.saturday]),
          _stepHabit(
            id: 'sunday',
            target: 10000,
            activeDays: [DateTime.sunday],
          ),
        ],
      );
      addTearDown(harness.dispose);
      expect((await harness.start())['date'], _date);
      final clearing = harness.nextSnapshot();
      harness.container.read(accountTransitionProvider.notifier).state = true;
      harness.container.read(widgetCoordinatorProvider);
      expect(await clearing, isEmpty);

      harness.now = DateTime(2026, 9, 20);
      // The previous coordinator's real midnight timer was disposed; the cached
      // provider still belongs to yesterday until the new active instance starts.
      expect(harness.container.read(clockProvider).day, 19);
      final reopened = harness.nextSnapshot();
      harness.container.read(accountTransitionProvider.notifier).state = false;
      harness.container.read(widgetCoordinatorProvider);
      final snapshot = await reopened;
      expect(snapshot['date'], '2026-09-20');
      expect(snapshot['stepGoal'], 10000);
      expect(snapshot['steps'], isNull);
    },
  );

  test(
    'clock rollover refreshes the date, readings and scheduled goal without repository activity',
    () async {
      final harness = _Harness(
        habits: [
          _stepHabit(activeDays: [DateTime.saturday]),
          _stepHabit(
            id: 'sunday',
            target: 10000,
            activeDays: [DateTime.sunday],
          ),
        ],
      );
      addTearDown(harness.dispose);
      harness.daily.logs[_date] = DailyLog(date: _date, steps: 7500);
      harness.daily.logs['2026-09-20'] = DailyLog(date: '2026-09-20', steps: 0);
      final before = await harness.start();
      expect(before['date'], _date);
      expect(before['steps'], 7500);
      expect(before['stepGoal'], 8000);
      final next = harness.nextSnapshot();
      harness.now = DateTime(2026, 9, 20);
      harness.container.invalidate(clockProvider);
      final after = await next;
      expect(after['date'], '2026-09-20');
      expect(after['updatedAt'], matches(r'^([01][0-9]|2[0-3]):[0-5][0-9]$'));
      expect(after['steps'], 0);
      expect(after['stepGoal'], 10000);
    },
  );
}
