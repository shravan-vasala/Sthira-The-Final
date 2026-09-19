import 'daily_log.dart';
import 'daily_meal_log.dart';
import 'exercise_log.dart';
import 'habit.dart';

/// Recorded areas describe logging, never goal achievement or a health score.
enum ActivityArea { habits, workouts, meals, wellbeing }

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

class ActivityDay {
  final DateTime date;
  final Set<ActivityArea> areas;
  final String? workoutStatus;

  ActivityDay({
    required DateTime date,
    Set<ActivityArea> areas = const {},
    this.workoutStatus,
  }) : date = _dateOnly(date),
       areas = Set.unmodifiable(areas);

  bool get hasEntries => areas.isNotEmpty;
  int get intensity => areas.length;
}

class YearlyActivity {
  final int year;
  final DateTime today;
  final Map<DateTime, ActivityDay> days;

  factory YearlyActivity({
    required int year,
    required DateTime today,
    required Map<DateTime, ActivityDay> days,
  }) {
    final cutoff = _dateOnly(today);
    final normalized = {
      for (final entry in days.entries) _dateOnly(entry.key): entry.value,
    };
    final calendar = <DateTime, ActivityDay>{};
    // Use calendar construction; elapsed 24-hour periods drift across DST.
    for (
      var day = 1;
      day <= DateTime.utc(year + 1).difference(DateTime.utc(year)).inDays;
      day++
    ) {
      final date = DateTime(year, 1, day);
      final saved = normalized[date];
      calendar[date] = date.isAfter(cutoff) || saved == null
          ? ActivityDay(date: date)
          : ActivityDay(
              date: date,
              areas: saved.areas,
              workoutStatus: saved.workoutStatus,
            );
    }
    return YearlyActivity._(year, cutoff, Map.unmodifiable(calendar));
  }

  YearlyActivity._(this.year, this.today, this.days);

  factory YearlyActivity.fromRecords({
    required int year,
    required DateTime today,
    Iterable<DailyLog> dailyLogs = const [],
    Iterable<DailyMealLog> mealLogs = const [],
    Iterable<HabitCompletion> habitLogs = const [],
    Iterable<ExerciseLog> exerciseLogs = const [],
  }) {
    final cutoff = _dateOnly(today);
    final areas = <DateTime, Set<ActivityArea>>{};
    final statuses = <DateTime, String>{};
    DateTime? recordDate(String key) {
      final date = DateTime.tryParse(key);
      if (date == null || date.year != year || date.isAfter(cutoff)) {
        return null;
      }
      // Reject normalized malformed dates such as February 30 and timestamps.
      final canonical =
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      return canonical == key ? _dateOnly(date) : null;
    }

    void add(String key, ActivityArea area) {
      final date = recordDate(key);
      if (date != null) (areas[date] ??= <ActivityArea>{}).add(area);
    }

    for (final log in dailyLogs) {
      if (log.weight != null ||
          log.steps != null ||
          log.sleepHours != null ||
          log.bodyFat != null ||
          log.waterMl != null ||
          log.screenTimeMinutes != null ||
          (log.dayFeeling?.trim().isNotEmpty ?? false) ||
          (log.dayNote?.trim().isNotEmpty ?? false)) {
        add(log.date, ActivityArea.wellbeing);
      }
      if (log.workoutStatus?.trim().isNotEmpty ?? false) {
        add(log.date, ActivityArea.workouts);
        final date = recordDate(log.date);
        if (date != null) statuses[date] = log.workoutStatus!;
      }
    }
    for (final log in mealLogs) {
      if (log.customSlots.values.any(
        (slot) =>
            slot.items.isNotEmpty ||
            (slot.photoPath?.trim().isNotEmpty ?? false) ||
            slot.photoPaths.any((path) => path.trim().isNotEmpty) ||
            slot.totalCalories > 0 ||
            slot.totalProtein > 0 ||
            slot.totalCarbs > 0 ||
            slot.totalFat > 0,
      )) {
        add(log.date, ActivityArea.meals);
      }
    }
    for (final log in habitLogs) {
      // A saved false/zero or partial entry is still a check-in. Current habit
      // schedules cannot erase recordings from archived or changed habits.
      if (log.completions.values.any(
            (value) => value is bool || (value is num && value.isFinite),
          ) ||
          log.overrides.values.any(
            (value) => value == 'done' || value == 'notDone',
          )) {
        add(log.date, ActivityArea.habits);
      }
    }
    for (final log in exerciseLogs) {
      if (log.sets.any(
        (set) =>
            set.reps != null ||
            set.weight != null ||
            (set.durationSeconds ?? 0) > 0,
      )) {
        add(log.date, ActivityArea.workouts);
      }
    }
    return YearlyActivity(
      year: year,
      today: today,
      days: {
        for (final entry in areas.entries)
          entry.key: ActivityDay(
            date: entry.key,
            areas: entry.value,
            workoutStatus: statuses[entry.key],
          ),
      },
    );
  }

  int get recordedDays => days.values.where((day) => day.hasEntries).length;
  int get recordedMonths => days.values
      .where((day) => day.hasEntries)
      .map((day) => day.date.month)
      .toSet()
      .length;
  int recordedInMonth(int month) => days.values
      .where((day) => day.hasEntries && day.date.month == month)
      .length;
  ActivityDay day(DateTime date) =>
      days[_dateOnly(date)] ?? ActivityDay(date: date);

  int get longestStreak {
    var longest = 0;
    var current = 0;
    for (final day in days.values) {
      current = day.hasEntries ? current + 1 : 0;
      if (current > longest) longest = current;
    }
    return longest;
  }
}
