import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'app_providers.dart';
import '../models/habit.dart';
import '../models/daily_log.dart';
import '../models/user_profile.dart';
import '../models/workout_plan.dart';
import '../models/meal_plan.dart';
import '../models/daily_meal_log.dart';
import '../repositories/exercise_log_repository.dart';
import '../repositories/daily_log_repository.dart';
import '../models/daily_stats_snapshot.dart';
import '../utils/workout_completion.dart';

class DailyScore {
  final int totalScore;
  final bool isFutureDate;
  final double habitsScore;
  final double habitsMax;
  final double workoutsScore;
  final double workoutsMax;
  final double mealsScore;
  final double mealsMax;
  final double totalMax;
  final bool isRestDay;
  final bool workoutConfigured;
  final bool isToday;
  final DateTime? date;
  final int sevenDayRecordedDays;

  DailyScore({
    required this.totalScore,
    required this.isFutureDate,
    required this.habitsScore,
    required this.habitsMax,
    required this.workoutsScore,
    required this.workoutsMax,
    required this.mealsScore,
    required this.mealsMax,
    required this.totalMax,
    this.yesterdayScore,
    this.sevenDayAverage,
    this.isRestDay = false,
    this.workoutConfigured = false,
    this.isToday = false,
    this.date,
    this.sevenDayRecordedDays = 0,
  });

  final int? yesterdayScore;
  final int? sevenDayAverage;

  static bool _bucketFull(double score, double max) =>
      max <= 0 || score >= max - 0.01;

  /// Habits + meals + workouts fully earned.
  bool get isPrimaryComplete {
    if (isFutureDate || totalMax <= 0) return false;
    return _bucketFull(habitsScore, habitsMax) &&
        _bucketFull(mealsScore, mealsMax) &&
        _bucketFull(workoutsScore, workoutsMax);
  }

  /// Compact labels for Home "still to do" cue.
  List<String> get remainingLabels {
    if (isFutureDate) return const [];
    final labels = <String>[];
    if (habitsMax > 0 && !_bucketFull(habitsScore, habitsMax)) {
      labels.add('habits');
    }
    if (mealsMax > 0 && !_bucketFull(mealsScore, mealsMax)) {
      labels.add('meals');
    }
    if (workoutsMax > 0 && !_bucketFull(workoutsScore, workoutsMax)) {
      labels.add('workout');
    }
    return labels;
  }

  static DailyScore calculate({
    required DateTime date,
    required String dateStr,
    required List<Habit> habits,
    required HabitCompletion habitCompletions,
    required DailyLog dailyLog,
    required WorkoutPlan? workoutPlan,
    required ExerciseLogRepository logRepo,
    required MealPlan? mealPlan,
    required DailyMealLog mealLog,
    required double targetWeight,
    required int targetCalories,
    required DailyLogRepository dailyLogRepo,
    required UserProfile profile,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final today = DateTime(clock.year, clock.month, clock.day);
    final day = DateTime(date.year, date.month, date.day);
    workoutPlan = planForScoring(workoutPlan);
    final workoutConfigured = WorkoutCompletion.hasSchedule(workoutPlan);
    final isFuture = day.isAfter(today);

    if (isFuture) {
      return DailyScore(
        totalScore: 0,
        isFutureDate: true,
        habitsScore: 0,
        habitsMax: 0,
        workoutsScore: 0,
        workoutsMax: 0,
        mealsScore: 0,
        mealsMax: 0,
        totalMax: 0,
      );
    }

    final stats = DailyStatsSnapshot.compute(
      date: date,
      dateStr: dateStr,
      habits: habitsForDate(habits, date),
      habitCompletions: habitCompletions,
      dailyLog: dailyLog,
      workoutPlan: workoutPlan,
      hasLog: logRepo.hasLog,
      mealPlan: mealPlan,
      mealLog: mealLog,
      targetWeight: targetWeight,
      dailyLogRepo: dailyLogRepo,
      profile: profile,
    );

    // 1. Habits (Max 50)
    double habitsScore = 0;
    final double habitsMax = stats.habitsTotal > 0 ? 50.0 : 0.0;
    if (stats.habitsTotal > 0) {
      habitsScore = stats.habitRate * habitsMax;
    }

    // 2. Workouts (Max 30)
    double workoutsScore = 0;
    final double workoutsMax =
        workoutConfigured && (stats.workoutsTotal > 0 || stats.isRestDay)
        ? 30.0
        : 0.0;
    if (workoutConfigured && stats.isRestDay) {
      workoutsScore = workoutsMax;
    } else if (workoutConfigured && stats.workoutsTotal > 0) {
      workoutsScore = (stats.workoutsDone / stats.workoutsTotal) * workoutsMax;
    }

    // 3. Meals (Max 20 = 14 completion + 6 accuracy)
    double mealsScore = 0;
    final double mealsMax = stats.mealsTotal > 0 ? 20.0 : 0.0;
    if (stats.mealsTotal > 0) {
      final double completionScore =
          (stats.mealsLogged / stats.mealsTotal) * 14.0;
      double accuracyScore = 0;

      // A known subtotal cannot establish accuracy while food calories are missing.
      if (stats.mealsLogged > 0 &&
          targetCalories > 0 &&
          mealLog.hasCompleteCalories) {
        final double consumed = mealLog.totalCalories.toDouble();
        final double variance =
            (consumed - targetCalories).abs() / targetCalories;

        if (variance <= 0.10) {
          accuracyScore = 6.0; // Perfect within 10%
        } else if (variance < 0.35) {
          // Linearly scale down from 6 to 0 between 10% and 35%
          final double ratio = (0.35 - variance) / (0.35 - 0.10);
          accuracyScore = 6.0 * ratio;
        }
      }

      mealsScore = completionScore + accuracyScore;
    }

    final totalEarned = habitsScore + workoutsScore + mealsScore;
    final totalPossible = habitsMax + workoutsMax + mealsMax;

    int finalScore = 0;
    if (totalPossible > 0) {
      finalScore = ((totalEarned / totalPossible) * 100).round();
    }

    return DailyScore(
      totalScore: finalScore,
      isFutureDate: false,
      habitsScore: habitsScore,
      habitsMax: habitsMax,
      workoutsScore: workoutsScore,
      workoutsMax: workoutsMax,
      mealsScore: mealsScore,
      mealsMax: mealsMax,
      totalMax: totalPossible,
      isRestDay: workoutConfigured && stats.isRestDay,
      workoutConfigured: workoutConfigured,
      isToday: day == today,
      date: day,
    );
  }

  /// Match the existing workout resolver for plans stored only in weeks.
  static WorkoutPlan? planForScoring(WorkoutPlan? plan) {
    if (plan == null || plan.days.isNotEmpty || plan.weeks?.isNotEmpty != true)
      return plan;
    return plan.copyWith(days: plan.weeks!.first.days);
  }

  static List<Habit> habitsForDate(List<Habit> habits, DateTime date) =>
      habits.where((habit) => isHabitScheduledOn(habit, date)).toList();

  static bool hasDailyRecords(DailyLog log) =>
      log.weight != null ||
      log.steps != null ||
      log.sleepHours != null ||
      log.bodyFat != null ||
      log.workoutStatus != null ||
      log.waterMl != null ||
      log.screenTimeMinutes != null ||
      log.dayFeeling != null ||
      log.dayNote != null;

  DailyScore copyWithContext({
    int? yesterdayScore,
    int? sevenDayAverage,
    int? sevenDayRecordedDays,
  }) {
    return DailyScore(
      totalScore: totalScore,
      isFutureDate: isFutureDate,
      habitsScore: habitsScore,
      habitsMax: habitsMax,
      workoutsScore: workoutsScore,
      workoutsMax: workoutsMax,
      mealsScore: mealsScore,
      mealsMax: mealsMax,
      totalMax: totalMax,
      isRestDay: isRestDay,
      workoutConfigured: workoutConfigured,
      isToday: isToday,
      date: date,
      sevenDayRecordedDays: sevenDayRecordedDays ?? this.sevenDayRecordedDays,
      yesterdayScore: yesterdayScore ?? this.yesterdayScore,
      sevenDayAverage: sevenDayAverage ?? this.sevenDayAverage,
    );
  }
}

final dailyScoreProvider = Provider<DailyScore>((ref) {
  final now = ref.watch(clockProvider);
  final dateStr = ref.watch(dateStringProvider);
  final date = DateTime.parse(dateStr);

  ref.watch(habitsProvider);
  final habits = ref.watch(habitRepoProvider).getHabits();
  final habitCompletions = ref.watch(habitCompletionsProvider);
  final dailyLog = ref.watch(dailyLogProvider);

  final workoutPlan = ref.watch(workoutPlanProvider);
  final logRepo = ref.watch(exerciseLogRepoProvider);
  ref.watch(exerciseLogsUpdateProvider);
  ref.watch(exerciseRecordsUpdateProvider);

  final mealPlan = ref.watch(mealPlanProvider);
  final mealLog = ref.watch(dailyMealLogProvider);

  final dailyLogRepo = ref.watch(dailyLogRepoProvider);
  final profile = ref.watch(profileProvider);
  final targetWeight = profile.targetWeight ?? 0.0;
  final targetCalories = profile.targetCalories;

  // To compute yesterday/7-day avg, we need past logs.
  final sevenDaysAgoStr = DateFormat(
    'yyyy-MM-dd',
  ).format(date.subtract(const Duration(days: 7)));
  final allDailyLogs = ref.watch(
    dailyLogsRangeProvider((sevenDaysAgoStr, dateStr)),
  );
  final allMealLogs = ref.watch(
    dailyMealLogsRangeProvider((sevenDaysAgoStr, dateStr)),
  );

  int? yesterdayScore;
  int? sevenDayAverage;

  int sevenDayRecordedDays = 0;
  if (!date.isAfter(now)) {
    // Helper to calculate score for a specific date in the past
    int? calcScoreForDate(DateTime d) {
      final dStr = DateFormat('yyyy-MM-dd').format(d);
      // Skip if completely inactive (no daily log, no meal log, no habit completions)
      final hasDailyLog = allDailyLogs.any(
        (l) => l.date == dStr && DailyScore.hasDailyRecords(l),
      );
      final hasMealLog = allMealLogs.any(
        (l) => l.date == dStr && l.loggedSlotsCount > 0,
      );
      final completions = ref.read(habitRepoProvider).getCompletions(dStr);
      if (!hasDailyLog &&
          !hasMealLog &&
          completions.completions.isEmpty &&
          completions.overrides.isEmpty &&
          logRepo.getLogsForDate(dStr).isEmpty) {
        return null;
      }

      final log = allDailyLogs.firstWhere(
        (l) => l.date == dStr,
        orElse: () => DailyLog(date: dStr),
      );
      final mLog = allMealLogs.firstWhere(
        (l) => l.date == dStr,
        orElse: () => DailyMealLog(date: dStr),
      );

      return DailyScore.calculate(
        date: d,
        dateStr: dStr,
        habits: habits,
        habitCompletions: completions,
        dailyLog: log,
        workoutPlan: workoutPlan,
        logRepo: logRepo,
        mealPlan: mealPlan,
        mealLog: mLog,
        targetWeight: targetWeight,
        targetCalories: targetCalories,
        dailyLogRepo: dailyLogRepo,
        profile: profile,
        now: now,
      ).totalScore;
    }

    yesterdayScore = calcScoreForDate(date.subtract(const Duration(days: 1)));

    int sum = 0;
    int count = 0;
    for (int i = 1; i <= 7; i++) {
      final pastDate = date.subtract(Duration(days: i));
      final s = calcScoreForDate(pastDate);
      if (s != null) {
        sum += s;
        count++;
      }
    }
    if (count > 0) {
      sevenDayAverage = (sum / count).round();
      sevenDayRecordedDays = count;
    }
  }

  final todayScore = DailyScore.calculate(
    date: date,
    dateStr: dateStr,
    habits: habits,
    habitCompletions: habitCompletions,
    dailyLog: dailyLog,
    workoutPlan: workoutPlan,
    logRepo: logRepo,
    mealPlan: mealPlan,
    mealLog: mealLog,
    targetWeight: targetWeight,
    targetCalories: targetCalories,
    dailyLogRepo: dailyLogRepo,
    profile: profile,
    now: now,
  );

  return todayScore.copyWithContext(
    yesterdayScore: yesterdayScore,
    sevenDayAverage: sevenDayAverage,
    sevenDayRecordedDays: sevenDayRecordedDays,
  );
});

final todayScoreProvider = Provider<DailyScore>((ref) {
  final now = ref.watch(clockProvider);
  final date = DateTime(now.year, now.month, now.day);
  final dateStr = DateFormat('yyyy-MM-dd').format(date);

  ref.watch(habitsProvider);
  final habits = ref.watch(habitRepoProvider).getHabits();
  ref.watch(habitCompletionsProvider);
  final habitCompletions = ref.watch(habitRepoProvider).getCompletions(dateStr);
  // Need to get today's daily log explicitly, instead of dailyLogProvider which tracks selectedDate
  final dailyLogRepo = ref.watch(dailyLogRepoProvider);
  final dailyLog = dailyLogRepo.getOrCreate(dateStr);

  final workoutPlan = ref.watch(workoutPlanProvider);
  final logRepo = ref.watch(exerciseLogRepoProvider);
  ref.watch(exerciseLogsUpdateProvider);
  ref.watch(exerciseRecordsUpdateProvider);

  final mealPlan = ref.watch(mealPlanProvider);
  // Need today's meal log explicitly
  final mealLogs = ref.watch(dailyMealLogsRangeProvider((dateStr, dateStr)));
  final mealLog = mealLogs.isNotEmpty
      ? mealLogs.first
      : DailyMealLog(date: dateStr);

  final profile = ref.watch(profileProvider);
  final targetWeight = profile.targetWeight ?? 0.0;
  final targetCalories = profile.targetCalories;

  final sevenDaysAgoStr = DateFormat(
    'yyyy-MM-dd',
  ).format(date.subtract(const Duration(days: 7)));
  final allDailyLogs = ref.watch(
    dailyLogsRangeProvider((sevenDaysAgoStr, dateStr)),
  );
  final allMealLogs = ref.watch(
    dailyMealLogsRangeProvider((sevenDaysAgoStr, dateStr)),
  );

  int? sevenDayAverage;
  int sum = 0;
  int count = 0;
  for (int i = 1; i <= 7; i++) {
    final pastDate = date.subtract(Duration(days: i));
    final dStr = DateFormat('yyyy-MM-dd').format(pastDate);
    final hasDailyLog = allDailyLogs.any(
      (l) => l.date == dStr && DailyScore.hasDailyRecords(l),
    );
    final hasMealLog = allMealLogs.any(
      (l) => l.date == dStr && l.loggedSlotsCount > 0,
    );
    final completions = ref.read(habitRepoProvider).getCompletions(dStr);
    if (!hasDailyLog &&
        !hasMealLog &&
        completions.completions.isEmpty &&
        completions.overrides.isEmpty &&
        logRepo.getLogsForDate(dStr).isEmpty) {
      continue;
    }

    final log = allDailyLogs.firstWhere(
      (l) => l.date == dStr,
      orElse: () => DailyLog(date: dStr),
    );
    final mLog = allMealLogs.firstWhere(
      (l) => l.date == dStr,
      orElse: () => DailyMealLog(date: dStr),
    );

    final s = DailyScore.calculate(
      date: pastDate,
      dateStr: dStr,
      habits: habits,
      habitCompletions: completions,
      dailyLog: log,
      workoutPlan: workoutPlan,
      logRepo: logRepo,
      mealPlan: mealPlan,
      mealLog: mLog,
      targetWeight: targetWeight,
      targetCalories: targetCalories,
      dailyLogRepo: dailyLogRepo,
      profile: profile,
      now: now,
    ).totalScore;
    sum += s;
    count++;
  }
  if (count > 0) sevenDayAverage = (sum / count).round();

  final todayScore = DailyScore.calculate(
    date: date,
    dateStr: dateStr,
    habits: habits,
    habitCompletions: habitCompletions,
    dailyLog: dailyLog,
    workoutPlan: workoutPlan,
    logRepo: logRepo,
    mealPlan: mealPlan,
    mealLog: mealLog,
    targetWeight: targetWeight,
    targetCalories: targetCalories,
    dailyLogRepo: dailyLogRepo,
    profile: profile,
    now: now,
  );

  return todayScore.copyWithContext(
    sevenDayAverage: sevenDayAverage,
    sevenDayRecordedDays: count,
  );
});
