import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/habit.dart';
import 'package:trufit_bodamma/models/daily_log.dart';

void main() {
  test(
    'missing limit readings stay incomplete while explicit zero is recorded',
    () {
      final habit = Habit(
        id: 'screen',
        name: 'Screen time',
        icon: '',
        type: HabitType.autoFromScreenTime,
        target: 120,
        goalDirection: GoalDirection.atMost,
      );
      final entries = HabitCompletion(date: '2026-09-19');
      final missing = DailyLog(date: entries.date);
      expect(hasHabitRecord(habit, entries, missing), isFalse);
      expect(isHabitCompleted(habit, entries, missing), isFalse);
      final zero = DailyLog(date: entries.date, screenTimeMinutes: 0);
      expect(hasHabitRecord(habit, entries, zero), isTrue);
      expect(isHabitCompleted(habit, entries, zero), isTrue);
      expect(
        isHabitCompleted(habit, entries.setOverride(habit.id, 'notDone'), zero),
        isFalse,
      );
      expect(
        isHabitCompleted(habit, entries.setOverride(habit.id, 'done'), missing),
        isTrue,
      );
    },
  );

  test('numeric habits reject non-finite and negative input', () {
    final habit = Habit(
      id: 'counter',
      name: 'Counter',
      icon: '',
      type: HabitType.counter,
      target: 5,
      goalDirection: GoalDirection.atMost,
    );
    final daily = DailyLog(date: '2026-09-19');
    for (final value in [double.nan, double.infinity, -1.0]) {
      final entries = HabitCompletion(
        date: daily.date,
        completions: {habit.id: value},
      );
      expect(hasHabitRecord(habit, entries, daily), isFalse);
      expect(isHabitCompleted(habit, entries, daily), isFalse);
      expect(entries.isCompleted(habit), isFalse);
    }
  });
  test('explicit incomplete counter check-in is not a successful zero', () {
    final habit = Habit(
      id: 'limit',
      name: 'Limit',
      icon: '',
      type: HabitType.counter,
      target: 5,
      goalDirection: GoalDirection.atMost,
    );
    final daily = DailyLog(date: '2026-09-19');
    final entries = HabitCompletion(
      date: daily.date,
      completions: {habit.id: false},
    );
    expect(hasHabitRecord(habit, entries, daily), isTrue);
    expect(isHabitCompleted(habit, entries, daily), isFalse);
  });
}
