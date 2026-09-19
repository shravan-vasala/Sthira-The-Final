import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'app_providers.dart';
import 'progress_goal_provider.dart';
import '../models/daily_stats_snapshot.dart';
import '../models/daily_log.dart';
import '../models/daily_meal_log.dart';
import '../models/habit.dart';
import '../utils/workout_completion.dart';

class WeeklySummary {
  final int workoutsCompleted;
  final int workoutsTotal;
  final double habitCompletionRate; // 0.0 to 1.0
  final String? bestHabit;
  final int avgSteps;
  final int bestSteps;
  final double avgSleep;
  final int nightsUnder7h;
  final int avgCalories;
  final int targetCalories;
  final int daysOverCalories;
  final int daysUnderCalories;
  final double weightDelta; // end - start
  final int weekScore; // 0 to 100
  final List<double> dailyHabitRates;
  final List<int> dailyHabitsTotal;
  final List<int> dailyHabitsCompleted;
  final List<int> dailyHabitsRecorded;
  final int incompleteFoodDays;
  int get scheduledHabitInstances =>
      dailyHabitsTotal.fold(0, (sum, value) => sum + value);
  int get completedHabitInstances =>
      dailyHabitsCompleted.fold(0, (sum, value) => sum + value);
  int get recordedHabitInstances =>
      dailyHabitsRecorded.fold(0, (sum, value) => sum + value);
  bool get hasHabitRecords => recordedHabitInstances > 0;
  final List<int?> dailyScores;

  final int elapsedDays,
      scoreDays,
      stepsDays,
      sleepNights,
      foodDays,
      weightMeasurements;
  final bool isPartialWeek, isFutureWeek, useKg;
  final String? comparisonLabel;
  bool get hasScoreData => scoreDays > 0;

  // Previous week stats for trend deltas
  final int? previousWeekScore;
  final int? prevAvgSteps;
  final double? prevAvgSleep;
  final int? prevAvgCalories;
  final int? prevWorkoutsCompleted;
  final double? prevHabitCompletionRate;
  final double? prevWeightDelta;

  WeeklySummary({
    required this.workoutsCompleted,
    required this.workoutsTotal,
    required this.habitCompletionRate,
    this.bestHabit,
    required this.avgSteps,
    required this.bestSteps,
    required this.avgSleep,
    required this.nightsUnder7h,
    required this.avgCalories,
    required this.targetCalories,
    required this.daysOverCalories,
    required this.daysUnderCalories,
    required this.weightDelta,
    required this.dailyHabitRates,
    required this.dailyHabitsTotal,
    this.dailyHabitsCompleted = const [],
    this.dailyHabitsRecorded = const [],
    this.incompleteFoodDays = 0,
    required this.dailyScores,
    required this.weekScore,
    this.previousWeekScore,
    this.prevAvgSteps,
    this.prevAvgSleep,
    this.prevAvgCalories,
    this.prevWorkoutsCompleted,
    this.prevHabitCompletionRate,
    this.prevWeightDelta,
    this.elapsedDays = 0,
    this.scoreDays = 0,
    this.stepsDays = 0,
    this.sleepNights = 0,
    this.foodDays = 0,
    this.weightMeasurements = 0,
    this.isPartialWeek = false,
    this.isFutureWeek = false,
    this.useKg = true,
    this.comparisonLabel,
  });

  String generateShareText() {
    final sb = StringBuffer();
    sb.writeln('💪 My Weekly Fitness Summary');
    sb.writeln(
      hasScoreData
          ? 'Plan and logging score: $weekScore/100'
          : 'No scored days yet.',
    );
    sb.writeln('---');
    sb.writeln(
      workoutsTotal == 0
          ? '🏋️ Workouts: none scheduled'
          : '🏋️ Workouts: $workoutsCompleted/$workoutsTotal${isPartialWeek ? ' so far' : ''}',
    );
    sb.writeln(
      scheduledHabitInstances == 0
          ? '✅ Habits: none scheduled'
          : !hasHabitRecords
          ? '✅ Habits: no entries recorded'
          : '✅ Habits: $completedHabitInstances/$scheduledHabitInstances completed; $recordedHabitInstances recorded',
    );
    if (bestHabit != null) sb.writeln('⭐ Best Habit: $bestHabit');
    if (stepsDays > 0)
      sb.writeln(
        '👟 Avg Steps: $avgSteps across $stepsDays recorded days (Best: $bestSteps)',
      );
    if (sleepNights > 0) {
      sb.writeln('💤 Avg Sleep: ${avgSleep.toStringAsFixed(1)}h');
    }
    if (foodDays > 0)
      sb.writeln(
        '🔥 Avg Calories logged: $avgCalories kcal across $foodDays days with known calories',
      );
    if (incompleteFoodDays > 0)
      sb.writeln('$incompleteFoodDays days with incomplete calories excluded.');
    if (weightDelta != 0) {
      final deltaStr = weightDelta > 0
          ? '+${weightDelta.toStringAsFixed(1)}'
          : weightDelta.toStringAsFixed(1);
      sb.writeln('⚖️ Weight Change: $deltaStr ${useKg ? 'kg' : 'lb'}');
    }
    sb.writeln('---');
    sb.writeln(
      '$scoreDays scored days; ${isFutureWeek
          ? 'upcoming week'
          : isPartialWeek
          ? 'week in progress'
          : 'week complete'}.',
    );
    sb.writeln('Logged food intake may be incomplete.');
    sb.writeln('Tracked with Sthira');
    return sb.toString();
  }
}

String _weekKey(DateTime d) {
  final weekday = d.weekday;
  final start = d.subtract(Duration(days: weekday - 1));
  return DateFormat('yyyy-MM-dd').format(start);
}

final weeklySummaryProvider = Provider<WeeklySummary>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final now = ref.watch(clockProvider);
  final today = DateTime(now.year, now.month, now.day);
  // Phase 4 Optimization: Only recompute if the week changes
  final startOfWeekStr = _weekKey(selectedDate);
  final startOfWeek = DateTime.parse(startOfWeekStr);
  final endOfWeek = startOfWeek.add(const Duration(days: 6));
  final isFutureWeek = startOfWeek.isAfter(today);
  final isPartialWeek = !isFutureWeek && !endOfWeek.isBefore(today);
  var elapsedDayCount = 0;

  final startStr = DateFormat('yyyy-MM-dd').format(startOfWeek);
  final endStr = DateFormat('yyyy-MM-dd').format(endOfWeek);

  final prevStartOfWeek = startOfWeek.subtract(const Duration(days: 7));
  final prevEndOfWeek = prevStartOfWeek.add(const Duration(days: 6));
  final prevStartStr = DateFormat('yyyy-MM-dd').format(prevStartOfWeek);
  final prevEndStr = DateFormat('yyyy-MM-dd').format(prevEndOfWeek);

  final dailyLogs = ref.watch(dailyLogsRangeProvider((startStr, endStr)));
  final mealLogs = ref.watch(dailyMealLogsRangeProvider((startStr, endStr)));

  final prevDailyLogs = ref.watch(
    dailyLogsRangeProvider((prevStartStr, prevEndStr)),
  );
  final prevMealLogs = ref.watch(
    dailyMealLogsRangeProvider((prevStartStr, prevEndStr)),
  );

  final profile = ref.watch(profileProvider);

  final habitRepo = ref.watch(habitRepoProvider);
  final workoutPlan = DailyScore.planForScoring(ref.watch(workoutPlanProvider));
  final exerciseLogRepo = ref.watch(exerciseLogRepoProvider);
  final mealPlan = ref.watch(mealPlanProvider);
  final dailyLogRepo = ref.watch(dailyLogRepoProvider);

  ref.watch(exerciseLogsUpdateProvider);
  ref.watch(exerciseRecordsUpdateProvider);
  ref.watch(habitCompletionsProvider);
  final allHabits = ref.watch(allHabitsProvider);
  ref.watch(progressHabitHistoryUpdatesProvider);
  ref.watch(dailyMealLogsUpdateProvider);

  int wCompleted = 0;
  int wTotal = 0;
  int observedScoreDays = 0;

  int totalHabitInstances = 0;
  int completedHabitInstances = 0;
  final List<double> dailyRates = List.filled(7, 0.0);
  final List<int> dailyHabitsTotalList = List.filled(7, 0);
  final List<int> dailyHabitsCompletedList = List.filled(7, 0);
  final List<int> dailyHabitsRecordedList = List.filled(7, 0);
  final List<int?> dailyScores = List.filled(7, null);
  final Map<String, int> habitStreaksThisWeek = {};
  final Map<String, int> currentHabitStreak = {};

  // Calculate Steps & Sleep
  int sumSteps = 0;
  int daysWithSteps = 0;
  int bestSteps = 0;

  double sumSleep = 0;
  int daysWithSleep = 0;
  int nightsUnder7h = 0;

  // Combine all stats using DailyStatsSnapshot
  for (int i = 0; i < 7; i++) {
    final d = startOfWeek.add(Duration(days: i));
    if (d.isAfter(today)) continue;
    elapsedDayCount++;
    final dateStr = DateFormat('yyyy-MM-dd').format(d);
    final habits = DailyScore.habitsForDate(allHabits, d);

    final log = dailyLogs.firstWhere(
      (dl) => dl.date == dateStr,
      orElse: () => DailyLog(date: dateStr),
    );
    final mealLog = mealLogs.firstWhere(
      (ml) => ml.date == dateStr,
      orElse: () => DailyMealLog(date: dateStr),
    );
    final completions = habitRepo.getCompletions(dateStr);

    final stats = DailyStatsSnapshot.compute(
      date: d,
      dateStr: dateStr,
      habits: habits,
      habitCompletions: completions,
      dailyLog: log,
      workoutPlan: workoutPlan,
      hasLog: exerciseLogRepo.hasLog,
      mealPlan: mealPlan,
      mealLog: mealLog,
      targetWeight: profile.targetWeight ?? 0.0,
      dailyLogRepo: dailyLogRepo,
      profile: profile,
    );

    if (workoutPlan != null && WorkoutCompletion.hasSchedule(workoutPlan)) {
      final plannedDay = WorkoutCompletion.resolveWorkoutDay(
        workoutPlan,
        d,
        planStartDate: profile.planStartDate,
      );
      if (!WorkoutCompletion.isRestDay(plannedDay, d)) {
        wTotal++;
        if (WorkoutCompletion.isDayWorkoutDone(
          date: dateStr,
          day: plannedDay,
          dateTime: d,
          hasLog: exerciseLogRepo.hasLog,
          dailyLog: log,
        ))
          wCompleted++;
      }
    }

    totalHabitInstances += stats.habitsTotal;
    completedHabitInstances += stats.habitsDone;
    dailyRates[i] = stats.habitRate;
    dailyHabitsTotalList[i] = stats.habitsTotal;
    dailyHabitsCompletedList[i] = stats.habitsDone;
    dailyHabitsRecordedList[i] = habits
        .where((habit) => hasHabitRecord(habit, completions, log))
        .length;

    final hasRecords =
        DailyScore.hasDailyRecords(log) ||
        mealLog.loggedSlotsCount > 0 ||
        completions.completions.isNotEmpty ||
        completions.overrides.isNotEmpty ||
        exerciseLogRepo.getLogsForDate(dateStr).isNotEmpty ||
        (workoutPlan != null &&
            WorkoutCompletion.hasSchedule(workoutPlan) &&
            stats.isRestDay);
    if (hasRecords) {
      final recordedActivity =
          DailyScore.hasDailyRecords(log) ||
          mealLog.loggedSlotsCount > 0 ||
          completions.completions.isNotEmpty ||
          completions.overrides.isNotEmpty ||
          exerciseLogRepo.getLogsForDate(dateStr).isNotEmpty;
      if (recordedActivity) observedScoreDays++;
      final score = DailyScore.calculate(
        date: d,
        dateStr: dateStr,
        habits: habits,
        habitCompletions: completions,
        dailyLog: log,
        workoutPlan: workoutPlan,
        logRepo: exerciseLogRepo,
        mealPlan: mealPlan,
        mealLog: mealLog,
        targetWeight: profile.targetWeight ?? 0.0,
        targetCalories: profile.targetCalories,
        dailyLogRepo: dailyLogRepo,
        profile: profile,
        now: now,
      );
      if (score.totalMax > 0) dailyScores[i] = score.totalScore;
    }

    for (final h in habits) {
      if (isHabitCompleted(h, completions, log)) {
        currentHabitStreak[h.name] = (currentHabitStreak[h.name] ?? 0) + 1;
        if (currentHabitStreak[h.name]! > (habitStreaksThisWeek[h.name] ?? 0)) {
          habitStreaksThisWeek[h.name] = currentHabitStreak[h.name]!;
        }
      } else {
        currentHabitStreak[h.name] = 0;
      }
    }

    if (log.steps != null && log.steps! >= 0) {
      sumSteps += log.steps!;
      daysWithSteps++;
      if (stats.steps > bestSteps) bestSteps = stats.steps;
    }

    if (log.sleepHours != null &&
        log.sleepHours!.isFinite &&
        log.sleepHours! >= 0) {
      sumSleep += log.sleepHours!;
      daysWithSleep++;
      if (stats.sleepHours < 7.0) nightsUnder7h++;
    }
  }

  final habitCompletionRate = totalHabitInstances > 0
      ? (completedHabitInstances / totalHabitInstances)
      : 0.0;

  String? bestHabit;
  int maxHabitStreak = 0;
  habitStreaksThisWeek.forEach((key, value) {
    if (value > maxHabitStreak) {
      maxHabitStreak = value;
      bestHabit = key;
    }
  });

  final avgSteps = daysWithSteps > 0 ? sumSteps ~/ daysWithSteps : 0;
  final avgSleep = daysWithSleep > 0 ? sumSleep / daysWithSleep : 0.0;

  // Calculate Calories
  int sumCalories = 0;
  int daysWithCalories = 0;
  int incompleteFoodDays = 0;
  int daysOver = 0;
  int daysUnder = 0;

  for (final mealLog in mealLogs) {
    final cals = mealLog.totalCalories;
    if (DateTime.parse(mealLog.date).isAfter(today)) continue;
    if (mealLog.loggedSlotsCount > 0 && !mealLog.hasCompleteCalories) {
      incompleteFoodDays++;
      continue;
    }
    if (mealLog.loggedSlotsCount > 0 && cals >= 0) {
      sumCalories += cals;
      daysWithCalories++;
      if (cals > profile.targetCalories) {
        daysOver++;
      } else {
        daysUnder++;
      }
    }
  }

  final avgCalories = daysWithCalories > 0
      ? sumCalories ~/ daysWithCalories
      : 0;

  // Calculate Weight Delta
  double firstWeight = 0;
  double lastWeight = 0;
  int weightMeasurements = 0;
  final sortedLogs = List<DailyLog>.from(dailyLogs)
    ..sort((a, b) => a.date.compareTo(b.date));
  for (final log in sortedLogs) {
    if (!DateTime.parse(log.date).isAfter(today) &&
        log.weight != null &&
        log.weight!.isFinite &&
        log.weight! > 0) {
      weightMeasurements++;
      if (firstWeight == 0) firstWeight = log.weight!;
      lastWeight = log.weight!;
    }
  }
  final weightDelta =
      (firstWeight > 0 && lastWeight > 0 && firstWeight != lastWeight)
      ? (lastWeight - firstWeight) * (profile.useKg ? 1 : 2.20462)
      : 0.0;

  // Calculate Week Score (0-100) by averaging elapsed days
  int sumScores = 0;
  int elapsedDays = 0;
  for (final s in dailyScores) {
    if (s != null) {
      sumScores += s;
      elapsedDays++;
    }
  }
  final int weekScore = elapsedDays > 0 ? (sumScores / elapsedDays).round() : 0;

  // Calculate Previous Week Stats
  int? prevWeekScore;
  int prevSumScores = 0;
  int prevElapsedDays = 0;
  int prevObservedScoreDays = 0;

  int prevWCompleted = 0;
  int prevHabitsTotal = 0;
  int prevHabitsDone = 0;
  int prevHabitsRecorded = 0;
  int prevSumSteps = 0;
  int prevDaysWithSteps = 0;
  double prevSumSleep = 0;
  int prevDaysWithSleep = 0;
  int prevSumCalories = 0;
  int prevDaysWithCalories = 0;
  double prevFirstWeight = 0;
  double prevLastWeight = 0;
  int prevWeightCount = 0;

  for (int i = 0; i < 7; i++) {
    final pd = prevStartOfWeek.add(Duration(days: i));
    final pDateStr = DateFormat('yyyy-MM-dd').format(pd);
    final isFuture = pd.isAfter(today);
    final habits = DailyScore.habitsForDate(allHabits, pd);
    if (!isFuture) {
      final pLog = prevDailyLogs.firstWhere(
        (dl) => dl.date == pDateStr,
        orElse: () => DailyLog(date: pDateStr),
      );
      final pMealLog = prevMealLogs.firstWhere(
        (ml) => ml.date == pDateStr,
        orElse: () => DailyMealLog(date: pDateStr),
      );
      final pCompletions = habitRepo.getCompletions(pDateStr);

      final pStats = DailyStatsSnapshot.compute(
        date: pd,
        dateStr: pDateStr,
        habits: habits,
        habitCompletions: pCompletions,
        dailyLog: pLog,
        workoutPlan: workoutPlan,
        hasLog: exerciseLogRepo.hasLog,
        mealPlan: mealPlan,
        mealLog: pMealLog,
        targetWeight: profile.targetWeight ?? 0.0,
        dailyLogRepo: dailyLogRepo,
        profile: profile,
      );

      if (workoutPlan != null && WorkoutCompletion.hasSchedule(workoutPlan)) {
        final plannedDay = WorkoutCompletion.resolveWorkoutDay(
          workoutPlan,
          pd,
          planStartDate: profile.planStartDate,
        );
        if (!WorkoutCompletion.isRestDay(plannedDay, pd) &&
            WorkoutCompletion.isDayWorkoutDone(
              date: pDateStr,
              day: plannedDay,
              dateTime: pd,
              hasLog: exerciseLogRepo.hasLog,
              dailyLog: pLog,
            ))
          prevWCompleted++;
      }
      prevHabitsTotal += pStats.habitsTotal;
      prevHabitsDone += pStats.habitsDone;
      prevHabitsRecorded += habits
          .where((habit) => hasHabitRecord(habit, pCompletions, pLog))
          .length;
      if (pLog.steps != null && pLog.steps! >= 0) {
        prevSumSteps += pStats.steps;
        prevDaysWithSteps++;
      }
      if (pLog.sleepHours != null &&
          pLog.sleepHours!.isFinite &&
          pLog.sleepHours! >= 0) {
        prevSumSleep += pStats.sleepHours;
        prevDaysWithSleep++;
      }
      if (pMealLog.loggedSlotsCount > 0 &&
          pMealLog.hasCompleteCalories &&
          pMealLog.totalCalories >= 0) {
        prevSumCalories += pMealLog.totalCalories;
        prevDaysWithCalories++;
      }
      if (pLog.weight != null && pLog.weight!.isFinite && pLog.weight! > 0) {
        prevWeightCount++;
        if (prevFirstWeight == 0) prevFirstWeight = pLog.weight!;
        prevLastWeight = pLog.weight!;
      }

      final score = DailyScore.calculate(
        date: pd,
        dateStr: pDateStr,
        habits: habits,
        habitCompletions: pCompletions,
        dailyLog: pLog,
        workoutPlan: workoutPlan,
        logRepo: exerciseLogRepo,
        mealPlan: mealPlan,
        mealLog: pMealLog,
        targetWeight: profile.targetWeight ?? 0.0,
        targetCalories: profile.targetCalories,
        dailyLogRepo: dailyLogRepo,
        profile: profile,
        now: now,
      );
      final hasRecords =
          DailyScore.hasDailyRecords(pLog) ||
          pMealLog.loggedSlotsCount > 0 ||
          pCompletions.completions.isNotEmpty ||
          pCompletions.overrides.isNotEmpty ||
          exerciseLogRepo.getLogsForDate(pDateStr).isNotEmpty ||
          (workoutPlan != null &&
              WorkoutCompletion.hasSchedule(workoutPlan) &&
              pStats.isRestDay);
      if (hasRecords && score.totalMax > 0) {
        if (DailyScore.hasDailyRecords(pLog) ||
            pMealLog.loggedSlotsCount > 0 ||
            pCompletions.completions.isNotEmpty ||
            pCompletions.overrides.isNotEmpty ||
            exerciseLogRepo.getLogsForDate(pDateStr).isNotEmpty)
          prevObservedScoreDays++;
        prevSumScores += score.totalScore;
        prevElapsedDays++;
      }
    }
  }
  final comparable =
      !isPartialWeek &&
      !isFutureWeek &&
      elapsedDays >= 3 &&
      prevElapsedDays >= 3 &&
      observedScoreDays >= 3 &&
      prevObservedScoreDays >= 3;
  if (comparable) {
    prevWeekScore = (prevSumScores / prevElapsedDays).round();
  }

  return WeeklySummary(
    workoutsCompleted: wCompleted,
    workoutsTotal: wTotal,
    habitCompletionRate: habitCompletionRate,
    bestHabit: bestHabit,
    avgSteps: avgSteps,
    bestSteps: bestSteps,
    avgSleep: avgSleep,
    nightsUnder7h: nightsUnder7h,
    avgCalories: avgCalories,
    targetCalories: profile.targetCalories,
    daysOverCalories: daysOver,
    daysUnderCalories: daysUnder,
    weightDelta: weightDelta,
    dailyHabitRates: dailyRates,
    dailyHabitsTotal: dailyHabitsTotalList,
    dailyHabitsCompleted: dailyHabitsCompletedList,
    dailyHabitsRecorded: dailyHabitsRecordedList,
    incompleteFoodDays: incompleteFoodDays,
    dailyScores: dailyScores,
    weekScore: weekScore,
    previousWeekScore: prevWeekScore,
    elapsedDays: elapsedDayCount,
    scoreDays: elapsedDays,
    stepsDays: daysWithSteps,
    sleepNights: daysWithSleep,
    foodDays: daysWithCalories,
    weightMeasurements: weightMeasurements,
    isPartialWeek: isPartialWeek,
    isFutureWeek: isFutureWeek,
    useKg: profile.useKg,
    comparisonLabel: comparable ? 'vs previous completed week' : null,
    prevAvgSteps: comparable && daysWithSteps >= 3 && prevDaysWithSteps >= 3
        ? (prevSumSteps / prevDaysWithSteps).round()
        : null,
    prevAvgSleep: comparable && daysWithSleep >= 3 && prevDaysWithSleep >= 3
        ? prevSumSleep / prevDaysWithSleep
        : null,
    prevAvgCalories:
        comparable && daysWithCalories >= 3 && prevDaysWithCalories >= 3
        ? (prevSumCalories / prevDaysWithCalories).round()
        : null,
    prevWorkoutsCompleted: comparable ? prevWCompleted : null,
    prevHabitCompletionRate:
        comparable &&
            prevHabitsTotal > 0 &&
            totalHabitInstances > 0 &&
            prevHabitsRecorded / prevHabitsTotal >= .5 &&
            dailyHabitsRecordedList.fold<int>(0, (sum, value) => sum + value) /
                    totalHabitInstances >=
                .5
        ? prevHabitsDone / prevHabitsTotal
        : null,
    prevWeightDelta:
        comparable && weightMeasurements >= 2 && prevWeightCount >= 2
        ? (prevLastWeight - prevFirstWeight) * (profile.useKg ? 1 : 2.20462)
        : null,
  );
});
