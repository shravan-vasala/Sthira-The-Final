import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'app_providers.dart';
import '../models/daily_log.dart';
import '../models/workout_plan.dart';
import '../utils/workout_completion.dart';

class PhaseProgress {
  final int currentWeek;
  final int totalWeeks;
  final int completedDaysThisWeek;
  final int requiredDaysPerWeek;
  final bool isPhaseActive;
  final bool isPhaseComplete;

  PhaseProgress({
    required this.currentWeek,
    required this.totalWeeks,
    required this.completedDaysThisWeek,
    required this.requiredDaysPerWeek,
    required this.isPhaseActive,
    required this.isPhaseComplete,
  });

  bool get isWeekComplete =>
      requiredDaysPerWeek > 0 && completedDaysThisWeek >= requiredDaysPerWeek;

  static PhaseProgress calculate({
    required WorkoutPlan? plan,
    required DateTime? planStartDate,
    required DateTime date,
    required DateTime today,
    required DailyLog? Function(String date) getLog,
    required bool Function(String date, String instanceId) hasLog,
  }) {
    final total = plan == null ? 1 : WorkoutCompletion.totalWeeks(plan);
    final hasDuration =
        plan != null &&
        (plan.weeks?.isNotEmpty == true || (plan.durationWeeks ?? 0) > 0);
    final started =
        planStartDate != null &&
        WorkoutCompletion.calendarDaysSince(date, planStartDate) >= 0;
    final week = plan == null
        ? 1
        : WorkoutCompletion.currentWeekForDate(
            plan,
            date,
            planStartDate: planStartDate,
          );
    // Once the program ends, retain the final week's actual progress.
    final weekStart = started
        ? DateTime(
            planStartDate.year,
            planStartDate.month,
            planStartDate.day + (week - 1) * 7,
          )
        : DateTime(date.year, date.month, date.day - date.weekday + 1);
    final selectedDay = DateTime(date.year, date.month, date.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    final cutoff = selectedDay.isBefore(todayDay) ? selectedDay : todayDay;
    var required = 0;
    var completed = 0;
    if (plan != null && WorkoutCompletion.hasSchedule(plan)) {
      for (var i = 0; i < 7; i++) {
        final checkDate = DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day + i,
        );
        final day = WorkoutCompletion.resolveWorkoutDay(
          plan,
          checkDate,
          currentWeek: week,
        );
        // Rest days support recovery but are not completed training sessions.
        if (WorkoutCompletion.isRestDay(day, checkDate)) continue;
        required++;
        if (!started || checkDate.isAfter(cutoff)) continue;
        final key = DateFormat('yyyy-MM-dd').format(checkDate);
        if (WorkoutCompletion.isDayWorkoutDone(
          date: key,
          day: day,
          dateTime: checkDate,
          hasLog: hasLog,
          dailyLog: getLog(key) ?? DailyLog(date: key),
        ))
          completed++;
      }
    }
    return PhaseProgress(
      currentWeek: week,
      totalWeeks: total,
      completedDaysThisWeek: completed,
      requiredDaysPerWeek: required,
      isPhaseActive: hasDuration && started,
      isPhaseComplete:
          hasDuration &&
          started &&
          !selectedDay.isAfter(todayDay) &&
          WorkoutCompletion.calendarDaysSince(date, planStartDate!) >=
              total * 7,
    );
  }
}

final phaseProgressProvider = Provider<PhaseProgress>((ref) {
  final profile = ref.watch(profileProvider);
  final date = DateTime.parse(ref.watch(dateStringProvider));
  ref.watch(accountGenerationProvider);
  ref.watch(dailyLogsUpdateProvider);
  ref.watch(exerciseLogsUpdateProvider);
  ref.watch(exerciseRecordsUpdateProvider);
  final dailyLogRepo = ref.watch(dailyLogRepoProvider);
  final exerciseLogRepo = ref.watch(exerciseLogRepoProvider);
  return PhaseProgress.calculate(
    plan: ref.watch(workoutPlanProvider),
    planStartDate: profile.planStartDate,
    date: date,
    today: ref.watch(clockProvider),
    getLog: dailyLogRepo.getLog,
    hasLog: exerciseLogRepo.hasLog,
  );
});
