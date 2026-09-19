import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_log.dart';
import '../models/social_profile.dart';
import '../utils/time_utils.dart';
import 'app_providers.dart';
import 'progress_goal_provider.dart';

final socialSnapshotClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// The same current snapshot drives publication and the local leaderboard.
/// Selected historical dates never change what friends see as "today".
final mySocialProfileProvider = Provider<SocialProfile>((ref) {
  ref.watch(accountGenerationProvider);
  final now = ref.watch(clockProvider);
  final today = DateTime(now.year, now.month, now.day);
  final monday = DateTime(
    today.year,
    today.month,
    today.day - today.weekday + 1,
  );
  final profile = ref.watch(profileProvider);
  final uid = ref.watch(activeAccountIdProvider);
  final dailyRepo = ref.watch(dailyLogRepoProvider);
  final mealRepo = ref.watch(mealRepoProvider);
  final habitRepo = ref.watch(habitRepoProvider);
  final exerciseRepo = ref.watch(exerciseLogRepoProvider);
  final habits = ref.watch(allHabitsProvider);
  final workoutPlan = ref.watch(workoutPlanProvider);
  final mealPlan = ref.watch(mealPlanProvider);
  ref.watch(dailyLogsUpdateProvider);
  ref.watch(dailyMealLogsUpdateProvider);
  ref.watch(progressHabitHistoryUpdatesProvider);
  ref.watch(exerciseLogsUpdateProvider);
  ref.watch(exerciseRecordsUpdateProvider);

  var weeklySteps = 0;
  var weeklyStepsDays = 0;
  var weeklyWorkouts = 0;
  var scoreTotal = 0;
  var scoreDays = 0;
  int? todayScore;
  final todayLog =
      dailyRepo.getLog(todayKey(today)) ?? DailyLog(date: todayKey(today));
  for (var offset = 0; offset < today.weekday; offset++) {
    final date = DateTime(monday.year, monday.month, monday.day + offset);
    final key = todayKey(date);
    final log = dailyRepo.getLog(key) ?? DailyLog(date: key);
    final meal = mealRepo.getDailyLog(key);
    final completion = habitRepo.getCompletions(key);
    if (log.steps != null && log.steps! >= 0) {
      weeklySteps += log.steps!;
      weeklyStepsDays++;
    }
    // Count finished sessions/days, never exercise sets or planned rest.
    if (log.workoutCompleted) weeklyWorkouts++;
    final recorded =
        DailyScore.hasDailyRecords(log) ||
        meal.loggedSlotsCount > 0 ||
        completion.completions.isNotEmpty ||
        completion.overrides.isNotEmpty ||
        exerciseRepo.getLogsForDate(key).isNotEmpty;
    if (!recorded) continue;
    final score = DailyScore.calculate(
      date: date,
      dateStr: key,
      habits: habits,
      habitCompletions: completion,
      dailyLog: log,
      workoutPlan: workoutPlan,
      logRepo: exerciseRepo,
      mealPlan: mealPlan,
      mealLog: meal,
      targetWeight: profile.targetWeight ?? 0,
      targetCalories: profile.targetCalories,
      dailyLogRepo: dailyRepo,
      profile: profile,
      now: now,
    );
    if (score.totalMax <= 0) continue;
    scoreTotal += score.totalScore;
    scoreDays++;
    if (date == today) todayScore = score.totalScore;
  }
  final avatar = profile.photoPath;
  return SocialProfile(
    uid: uid,
    name: profile.name.trim().isEmpty ? 'Friend' : profile.name.trim(),
    avatarUrl: avatar != null && avatar.startsWith('assets/avatars/')
        ? avatar
        : null,
    todaySteps: todayLog.steps != null && todayLog.steps! >= 0
        ? todayLog.steps!
        : 0,
    todayWorkouts: todayLog.workoutCompleted ? 1 : 0,
    currentStreak: ref.watch(stepsStreakProvider),
    weeklySteps: weeklySteps,
    weeklyWorkouts: weeklyWorkouts,
    lastUpdatedAt: ref.read(socialSnapshotClockProvider)(),
    todayScore: todayScore,
    weekScore: scoreDays > 0 ? (scoreTotal / scoreDays).round() : null,
    statsDate: todayKey(today),
    weekStartDate: todayKey(monday),
    hasStepsRecord: todayLog.steps != null && todayLog.steps! >= 0,
    weeklyStepsRecordedDays: weeklyStepsDays,
    weekScoreRecordedDays: scoreDays,
  );
});
