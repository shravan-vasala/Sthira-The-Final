import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/coach_context.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/habit.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/models/workout_plan.dart';

void main() {
  CoachContext context({
    DailyLog? log,
    DailyMealLog? meals,
    List<Habit> habits = const [],
    HabitCompletion? previous,
    List<DailyLog> history = const [],
    Set<String> exerciseDates = const {},
    WorkoutPlan? plan,
  }) => CoachContext.fromRecords(
    date: DateTime(2026, 9, 21),
    today: DateTime(2026, 9, 21),
    profile: UserProfile(name: 'Alex', targetWeight: 60),
    log: log ?? DailyLog(date: '2026-09-21'),
    meals: meals ?? DailyMealLog(date: '2026-09-21'),
    habits: habits,
    completions: HabitCompletion(date: '2026-09-21'),
    previousCompletions: previous ?? HabitCompletion(date: '2026-09-20'),
    history: history,
    exerciseDates: exerciseDates,
    workoutPlan: plan,
    hasLog: (_, _) => false,
  );

  test(
    'missing records are unknown and target weight cannot invent a trend',
    () {
      final value = context(
        history: [DailyLog(date: '2026-09-14', weight: 70)],
      );
      expect(value.steps, isNull);
      expect(value.sleep, isNull);
      expect(value.calories, isNull);
      expect(value.weightComparison, 'Not enough recorded measurements');
      expect(value.isRestDay, isFalse);
      expect(value.sectionsDone, 0);
      expect(value.hasWorkoutPlan, isFalse);
      expect(value.daysSinceLastWorkout, isNull);
      final measured = context(log: DailyLog(date: '2026-09-21', weight: 70));
      expect(measured.weightComparison, 'Not enough recorded measurements');
    },
  );

  test('zero is retained and real dated weight observations are compared', () {
    final value = context(
      log: DailyLog(date: '2026-09-21', weight: 69, steps: 0, sleepHours: 0),
      history: [DailyLog(date: '2026-09-16', weight: 70)],
    );
    expect(value.steps, 0);
    expect(value.sleep, 0);
    expect(value.hasEntries, isTrue);
    expect(value.weightComparison, contains('70.0 kg on 2026-09-16'));
    expect(value.weightComparison, contains('-1.0 kg'));
  });

  test('previous habit rate uses the previous weekday schedule', () {
    final value = context(
      habits: [
        Habit(
          id: 'sun',
          name: 'Sunday',
          icon: '',
          target: 1,
          activeDays: [DateTime.sunday],
          initialCreatedAt: DateTime(2020),
        ),
        Habit(
          id: 'mon',
          name: 'Monday',
          icon: '',
          target: 1,
          activeDays: [DateTime.monday],
          initialCreatedAt: DateTime(2020),
        ),
      ],
      previous: HabitCompletion(date: '2026-09-20', completions: {'sun': true}),
    );
    expect(value.habitsTotal, 1);
    expect(value.habitsDone, 0);
    expect(value.yesterdayHabitRate, 1);
  });

  test(
    'scheduled rest has no completed workout and exercise-only yesterday is one day ago',
    () {
      final value = context(
        plan: WorkoutPlan(
          planName: 'Rest plan',
          days: [WorkoutDay(dayId: 'Monday')],
        ),
        exerciseDates: {'2026-09-20'},
      );
      expect(value.isRestDay, isTrue);
      expect(value.sectionsDone, 0);
      expect(value.sectionsTotal, 0);
      expect(value.daysSinceLastWorkout, 1);
      expect(value.hasEntries, isFalse);
    },
  );

  test('partial calories are explicitly partial in evidence', () {
    final value = context(
      meals: DailyMealLog(
        date: '2026-09-21',
        customSlots: {
          'lunch': MealSlotLog(totalCalories: 200, caloriesComplete: false),
        },
      ),
    );
    expect(value.calories, 200);
    expect(
      value.evidence,
      contains('partial; some logged foods have unknown calories'),
    );
  });

  test(
    'missing or partial previous habit coverage cannot be presented as a failure rate',
    () {
      final habits = [
        for (final id in ['a', 'b'])
          Habit(
            id: id,
            name: id,
            icon: '',
            target: 1,
            activeDays: [DateTime.sunday],
            initialCreatedAt: DateTime(2020),
          ),
      ];
      final empty = context(habits: habits);
      expect(empty.yesterdayHabitRate, isNull);
      expect(empty.previousHabitsRecorded, 0);
      final partial = context(
        habits: habits,
        previous: HabitCompletion(
          date: '2026-09-20',
          completions: {'a': false},
        ),
      );
      expect(partial.yesterdayHabitRate, isNull);
      expect(partial.evidence, contains('1 / 2 scheduled habits have records'));
      final complete = context(
        habits: habits,
        previous: HabitCompletion(
          date: '2026-09-20',
          completions: {'a': false, 'b': false},
        ),
      );
      expect(complete.yesterdayHabitRate, 0);
    },
  );
}
