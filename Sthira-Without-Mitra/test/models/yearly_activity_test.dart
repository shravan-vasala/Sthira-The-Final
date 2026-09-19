import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/exercise_log.dart';
import 'package:trufit_bodamma/models/habit.dart';
import 'package:trufit_bodamma/models/yearly_activity.dart';

void main() {
  test(
    'recording includes partial and zero check-ins without claiming completion',
    () {
      final activity = YearlyActivity.fromRecords(
        year: 2026,
        today: DateTime(2026, 9, 19),
        dailyLogs: [
          DailyLog(date: '2026-09-01', steps: 0),
          DailyLog(date: '2026-09-02', waterMl: 0),
          DailyLog(date: '2026-09-03', bodyFat: 24),
          DailyLog(date: '2026-09-04', dayNote: 'A calmer day'),
          DailyLog(date: '2026-09-05', dayFeeling: 'good'),
          DailyLog(date: '2026-09-06', workoutStatus: 'skipped'),
          DailyLog(date: '2026-09-07', workoutStatus: 'partial'),
          DailyLog(date: '2026-09-08', updatedAt: DateTime(2026, 9, 8)),
        ],
        habitLogs: [
          HabitCompletion(
            date: '2026-09-01',
            completions: {'archived-habit': false},
          ),
          HabitCompletion(date: '2026-09-02', completions: {'counter': 0}),
          HabitCompletion(date: '2026-09-03', completions: {'counter': 0.5}),
          HabitCompletion(date: '2026-09-04', overrides: {'habit': 'notDone'}),
          HabitCompletion(date: '2026-09-08', streaks: {'habit': 3}),
        ],
      );
      expect(activity.recordedDays, 7);
      expect(activity.day(DateTime(2026, 9, 1)).areas, {
        ActivityArea.habits,
        ActivityArea.wellbeing,
      });
      expect(
        activity.day(DateTime(2026, 9, 4)).areas.contains(ActivityArea.habits),
        isTrue,
      );
      expect(activity.day(DateTime(2026, 9, 6)).workoutStatus, 'skipped');
      expect(activity.day(DateTime(2026, 9, 7)).workoutStatus, 'partial');
      expect(activity.day(DateTime(2026, 9, 8)).hasEntries, isFalse);
      expect(activity.longestStreak, 7);
    },
  );

  test(
    'exercise-only and meal photos count, and intensity caps at four areas',
    () {
      final activity = YearlyActivity.fromRecords(
        year: 2026,
        today: DateTime(2026, 9, 19),
        dailyLogs: [DailyLog(date: '2026-09-02', weight: 60)],
        habitLogs: [
          HabitCompletion(date: '2026-09-02', overrides: {'habit': 'done'}),
        ],
        exerciseLogs: [
          for (final date in ['2026-09-01', '2026-09-02'])
            ExerciseLog(
              date: date,
              instanceId: 'exercise',
              exerciseName: 'Squat',
              sets: [SetLog(reps: 8, weight: 0)],
            ),
          ExerciseLog(
            date: '2026-09-03',
            instanceId: 'empty',
            exerciseName: 'Empty',
            sets: [],
          ),
        ],
        mealLogs: [
          DailyMealLog(
            date: '2026-09-02',
            customSlots: {
              'photo': MealSlotLog(photoPaths: ['photo.jpg']),
              'second': MealSlotLog(totalCalories: 150),
            },
          ),
          DailyMealLog(
            date: '2026-09-03',
            customSlots: {'empty': MealSlotLog(photoPath: '')},
          ),
        ],
      );
      expect(activity.day(DateTime(2026, 9, 1)).areas, {ActivityArea.workouts});
      expect(activity.day(DateTime(2026, 9, 2)).intensity, 4);
      expect(activity.day(DateTime(2026, 9, 3)).hasEntries, isFalse);
      expect(activity.recordedDays, 2);
    },
  );

  test(
    'calendar includes leap day, rejects invalid/future records and spans months',
    () {
      final activity = YearlyActivity.fromRecords(
        year: 2024,
        today: DateTime(2024, 3, 2, 16),
        dailyLogs: [
          for (final date in [
            '2024-02-28',
            '2024-02-29',
            '2024-03-01',
            '2024-03-02',
            '2024-03-03',
            '2024-02-30',
            '2023-12-31',
            '2024-01-01T12:00:00',
          ])
            DailyLog(date: date, steps: 1),
        ],
      );
      expect(activity.days.length, 366);
      expect(activity.recordedDays, 4);
      expect(activity.longestStreak, 4);
      expect(activity.recordedMonths, 2);
      expect(activity.recordedInMonth(2), 2);
      expect(activity.recordedInMonth(3), 2);
      expect(activity.day(DateTime(2024, 3, 2, 12)).hasEntries, isTrue);
      expect(activity.day(DateTime(2024, 3, 3)).hasEntries, isFalse);
    },
  );

  test('snapshot collections are immutable and future fixtures stay empty', () {
    final date = DateTime(2026, 9, 19);
    final areas = {ActivityArea.meals};
    final input = {date: ActivityDay(date: date, areas: areas)};
    final activity = YearlyActivity(
      year: 2026,
      today: DateTime(2026, 9, 18),
      days: input,
    );
    areas.add(ActivityArea.habits);
    input.clear();
    expect(activity.days.length, 365);
    expect(activity.recordedDays, 0);
    expect(() => activity.days.clear(), throwsUnsupportedError);
    expect(
      () => activity.day(date).areas.add(ActivityArea.habits),
      throwsUnsupportedError,
    );
  });
}
