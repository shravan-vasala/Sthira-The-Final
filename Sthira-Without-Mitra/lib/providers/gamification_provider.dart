import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import '../models/daily_log.dart';
import '../models/daily_meal_log.dart';
import '../models/habit.dart';
import 'app_providers.dart';

String _key(DateTime day) => DateFormat('yyyy-MM-dd').format(day);
DateTime _previous(DateTime day) => DateTime(day.year, day.month, day.day - 1);

/// Today's unfinished day keeps yesterday's streak available.
int currentRecordedStreak(Iterable<String> recordedDates, DateTime now) {
  final dates = recordedDates.toSet();
  var day = DateTime(now.year, now.month, now.day);
  if (!dates.contains(_key(day))) day = _previous(day);
  var count = 0;
  while (dates.contains(_key(day))) {
    count++;
    day = _previous(day);
  }
  return count;
}

/// Badge milestones describe an earned run, not unrelated recorded activity.
int longestCompletedWorkoutStreak(Iterable<DailyLog> logs, DateTime now) {
  final today = _key(now);
  final dates =
      logs
          .where(
            (log) => log.workoutCompleted && log.date.compareTo(today) <= 0,
          )
          .map((log) => log.date)
          .toSet()
          .toList()
        ..sort();
  var longest = 0;
  var run = 0;
  DateTime? previous;
  for (final key in dates) {
    final date = DateTime.tryParse(key);
    if (date == null) continue;
    run = previous != null && _key(_previous(date)) == _key(previous)
        ? run + 1
        : 1;
    if (run > longest) longest = run;
    previous = date;
  }
  return longest;
}

/// Recognizes recording over time without rewarding meal quantity or requiring a streak.
int recordedMealDays(Iterable<DailyMealLog> logs, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  return logs
      .where((log) {
        final day = DateTime.tryParse(log.date);
        return day != null &&
            _key(day) == log.date &&
            !day.isAfter(today) &&
            log.loggedSlotsCount > 0;
      })
      .map((log) => log.date)
      .toSet()
      .length;
}

int scheduledStepsStreak({
  required List<DailyLog> logs,
  required List<Habit> habits,
  required DateTime now,
  HabitCompletion Function(String date)? completionsFor,
  List<HabitCompletion> habitRecords = const [],
}) {
  final stepHabits = habits
      .where(
        (habit) =>
            habit.type == HabitType.autoSteps &&
            habit.target.isFinite &&
            habit.target > 0,
      )
      .toList();
  if (stepHabits.isEmpty || (logs.isEmpty && habitRecords.isEmpty)) return 0;
  final records = {for (final log in logs) log.date: log};
  final habitByDate = {for (final record in habitRecords) record.date: record};
  final earliestKey = {...records.keys, ...habitByDate.keys}.toList()..sort();
  final earliest = DateTime.tryParse(earliestKey.first);
  if (earliest == null) return 0;
  final today = DateTime(now.year, now.month, now.day);
  var day = today;
  var streak = 0;
  while (!day.isBefore(earliest)) {
    final scheduled = stepHabits
        .where((habit) => isHabitScheduledOn(habit, day))
        .toList();
    if (scheduled.isNotEmpty) {
      final key = _key(day);
      final log = records[key] ?? DailyLog(date: key);
      final completions =
          completionsFor?.call(key) ??
          habitByDate[key] ??
          HabitCompletion(date: key);
      final complete = scheduled.every(
        (habit) =>
            hasHabitRecord(habit, completions, log) &&
            isHabitCompleted(habit, completions, log),
      );
      if (complete) {
        streak++;
      } else if (day != today) {
        break;
      }
    }
    day = _previous(day);
  }
  return streak;
}

final mealStreakProvider = Provider<int>((ref) {
  ref.watch(accountGenerationProvider);
  ref.watch(dailyMealLogsUpdateProvider);
  final now = ref.watch(clockProvider);
  final logs = ref.watch(mealRepoProvider).getAllLogs();
  return currentRecordedStreak(
    logs.where((log) => log.loggedSlotsCount > 0).map((log) => log.date),
    now,
  );
});

final stepsStreakProvider = Provider<int>((ref) {
  ref.watch(accountGenerationProvider);
  ref.watch(dailyLogsUpdateProvider);
  ref.watch(yearlyActivityChangesProvider);
  final habits = ref.watch(allHabitsProvider);
  final now = ref.watch(clockProvider);
  return scheduledStepsStreak(
    logs: ref.watch(dailyLogRepoProvider).getAllLogs(),
    habits: habits,
    now: now,
    completionsFor: ref.watch(habitRepoProvider).getCompletions,
    habitRecords:
        ref
            .watch(activeDatabaseProvider)
            ?.habitCompletions
            .where()
            .findAllSync() ??
        const [],
  );
});
