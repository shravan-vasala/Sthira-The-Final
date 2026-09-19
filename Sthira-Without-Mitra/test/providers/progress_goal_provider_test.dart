import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/habit.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/providers/progress_goal_provider.dart';

Habit goal(
  String id,
  HabitType type,
  double target, {
  List<int>? days,
  GoalDirection direction = GoalDirection.atLeast,
  DateTime? created,
}) => Habit(
  id: id,
  name: id,
  icon: 'check',
  type: type,
  target: target,
  activeDays: days,
  goalDirection: direction,
  initialCreatedAt: created ?? DateTime(2020),
);
void main() {
  for (final type in [HabitType.autoSteps, HabitType.autoSleep]) {
    test('$type current target does not depend on Home weekday', () {
      final target = type == HabitType.autoSteps ? 8000.0 : 8.0;
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(DateTime(2026, 9, 18)),
          selectedDateProvider.overrideWith((ref) => DateTime(2026, 9, 18)),
          allHabitsProvider.overrideWithValue([
            goal('goal', type, target, days: [1, 2, 3, 4, 5]),
          ]),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(progressHabitGoalProvider(type)).value, target);
      container.read(selectedDateProvider.notifier).state = DateTime(
        2026,
        9,
        13,
      );
      expect(container.read(progressHabitGoalProvider(type)).value, target);
    });
  }
  test(
    'different scheduled targets do not arbitrarily pick the first habit',
    () {
      final result = ProgressHabitGoal.resolve(
        [
          goal('weekday', HabitType.autoSteps, 8000, days: [1, 2, 3, 4, 5]),
          goal('weekend', HabitType.autoSteps, 6000, days: [6, 7]),
        ],
        HabitType.autoSteps,
        DateTime(2026, 9, 19),
      );
      expect(result.value, isNull);
      expect(result.context, contains('vary by habit or day'));
    },
  );
  test('one consistent reference survives separate weekday schedules', () {
    final result = ProgressHabitGoal.resolve(
      [
        goal('weekday', HabitType.autoSteps, 8000, days: [1, 2, 3, 4, 5]),
        goal('weekend', HabitType.autoSteps, 8000, days: [6, 7]),
      ],
      HabitType.autoSteps,
      DateTime(2026, 9, 19),
    );
    expect(result.value, 8000);
  });
  test(
    'invalid, disabled, unrelated and future-created goals are not shown',
    () {
      final result = ProgressHabitGoal.resolve(
        [
          goal('invalid', HabitType.autoSteps, double.nan),
          goal('disabled', HabitType.autoSteps, 6000, days: []),
          goal('other', HabitType.autoSleep, 8),
          goal(
            'future',
            HabitType.autoSteps,
            10000,
            created: DateTime(2026, 9, 20),
          ),
        ],
        HabitType.autoSteps,
        DateTime(2026, 9, 19),
      );
      expect(result.value, isNull);
      expect(result.context, isNull);
    },
  );
  test('upper-bound rules are not described as reaching a minimum target', () {
    final result = ProgressHabitGoal.resolve(
      [
        goal(
          'maximum',
          HabitType.autoSteps,
          8000,
          direction: GoalDirection.atMost,
        ),
      ],
      HabitType.autoSteps,
      DateTime(2026, 9, 19),
    );
    expect(result.value, isNull);
    expect(result.context, contains('different goal rules'));
  });
}
