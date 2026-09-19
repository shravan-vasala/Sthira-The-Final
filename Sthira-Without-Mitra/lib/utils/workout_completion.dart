import '../models/daily_log.dart';
import '../models/workout_plan.dart';
import '../models/exercise_log.dart';
import '../repositories/exercise_log_repository.dart';

/// Shared workout completion rules (Approach A):
/// - [ExerciseLog] is the source of truth for exercise/section completion.
/// - [DailyLog.workoutCompleted] is the day-level Finish flag (full or early).
/// - Planned rest days count as done for scoring / day-done checks.
class WorkoutCompletion {
  /// A day with no workout sections.
  static bool isRestDay(WorkoutDay day, DateTime date) {
    return day.sections.every((section) => section.exercises.isEmpty);
  }

  /// Whether the logged work has non-zero positive effort.
  static bool hasMeaningfulWork(ExerciseLog log) {
    if (log.sets.isEmpty) return false;
    for (final s in log.sets) {
      if ((s.reps ?? 0) > 0 ||
          (s.weight ?? 0.0) > 0 ||
          (s.durationSeconds ?? 0) > 0)
        return true;
    }
    return false;
  }

  /// A schedule may be stored directly or as a series of program weeks.
  static bool hasSchedule(WorkoutPlan? plan) {
    if (plan == null) return false;
    if (plan.weeks?.isNotEmpty == true) {
      return plan.weeks!.any((week) => week.days.isNotEmpty);
    }
    return plan.days.isNotEmpty;
  }

  static int totalWeeks(WorkoutPlan plan) {
    final count = plan.weeks?.isNotEmpty == true
        ? plan.weeks!.length
        : plan.durationWeeks ?? 1;
    return count < 1 ? 1 : count;
  }

  /// Use calendar dates so daylight-saving changes cannot shift a program week.
  static int calendarDaysSince(DateTime date, DateTime start) => DateTime.utc(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;

  static int currentWeekForDate(
    WorkoutPlan plan,
    DateTime date, {
    DateTime? planStartDate,
  }) {
    if (planStartDate == null) return 1;
    final elapsed = calendarDaysSince(date, planStartDate);
    final week = elapsed < 0 ? 1 : elapsed ~/ 7 + 1;
    return week.clamp(1, totalWeeks(plan));
  }

  static List<WorkoutDay> scheduledDays(
    WorkoutPlan plan,
    DateTime date, {
    int? currentWeek,
    DateTime? planStartDate,
  }) {
    if (plan.weeks?.isNotEmpty != true) return plan.days;
    final week =
        currentWeek ??
        currentWeekForDate(plan, date, planStartDate: planStartDate);
    return plan.weeks![week.clamp(1, plan.weeks!.length) - 1].days;
  }

  /// Resolves the selected calendar date against its program week.
  static WorkoutDay resolveWorkoutDay(
    WorkoutPlan plan,
    DateTime date, {
    int? currentWeek,
    DateTime? planStartDate,
  }) {
    final days = scheduledDays(
      plan,
      date,
      currentWeek: currentWeek,
      planStartDate: planStartDate,
    );

    // 1. Find a day matching the explicit weekday
    for (final day in days) {
      if (day.weekday == date.weekday) {
        return day;
      }
    }

    // 2. If no weekday match, maybe fallback to 'Rest'
    for (final day in days) {
      if (day.dayId?.toLowerCase() == 'rest') {
        return day;
      }
    }

    // 3. Last resort fallback
    return WorkoutDay(dayId: 'Rest', label: 'Rest Day', sections: []);
  }

  static bool isSectionComplete(
    String date,
    WorkoutSection section,
    bool Function(String date, String instanceId) hasLog,
  ) {
    return section.exercises.isNotEmpty &&
        section.exercises.every((ex) => hasLog(date, ex.instanceId ?? ''));
  }

  static bool isSectionCompleteWithRepo(
    String date,
    WorkoutSection section,
    ExerciseLogRepository repo,
  ) {
    return isSectionComplete(date, section, repo.hasLog);
  }

  /// True when every section on a training day has all exercises logged.
  static bool isTrainingDayComplete(
    String date,
    WorkoutDay day,
    bool Function(String date, String instanceId) hasLog,
  ) {
    final sections = day.sections.where(
      (section) => section.exercises.isNotEmpty,
    );
    return sections.isNotEmpty &&
        sections.every((sec) => isSectionComplete(date, sec, hasLog));
  }

  static bool isTrainingDayCompleteWithRepo(
    String date,
    WorkoutDay day,
    ExerciseLogRepository repo,
  ) {
    return isTrainingDayComplete(date, day, repo.hasLog);
  }

  /// Day-level "workout done" for score / summaries.
  /// Rest → always true (planned rest). Training → all logs or Finish flag.
  static bool isDayWorkoutDone({
    required String date,
    required WorkoutDay day,
    required DateTime dateTime,
    required bool Function(String date, String instanceId) hasLog,
    required DailyLog dailyLog,
  }) {
    if (isRestDay(day, dateTime)) return true;
    return isTrainingDayComplete(date, day, hasLog) ||
        dailyLog.workoutCompleted;
  }

  static bool isDayWorkoutDoneWithRepo({
    required String date,
    required WorkoutDay day,
    required DateTime dateTime,
    required ExerciseLogRepository repo,
    required DailyLog dailyLog,
  }) {
    return isDayWorkoutDone(
      date: date,
      day: day,
      dateTime: dateTime,
      hasLog: repo.hasLog,
      dailyLog: dailyLog,
    );
  }

  /// Count of fully logged sections on a training day.
  static int completedSectionCount(
    String date,
    WorkoutDay day,
    bool Function(String date, String instanceId) hasLog,
  ) {
    var count = 0;
    for (final sec in day.sections) {
      if (isSectionComplete(date, sec, hasLog)) count++;
    }
    return count;
  }
}
