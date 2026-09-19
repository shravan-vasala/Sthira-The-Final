import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_providers.dart';
import '../models/workout_plan.dart';
import '../models/exercise_log.dart';
import '../models/exercise_pr.dart';
import '../utils/workout_completion.dart';

final workoutPlanProvider = Provider<WorkoutPlan?>((ref) {
  ref.watch(planRecordsUpdateProvider);
  ref.watch(accountGenerationProvider);
  final repo = ref.watch(workoutRepoProvider);
  final activePlanId = ref.watch(
    profileProvider.select((p) => p.activeWorkoutPlan),
  );
  return repo.getActivePlan(preferredKey: activePlanId ?? 'beginner_plan');
});

final workoutDayProvider = Provider.family<WorkoutDay?, String>((ref, dayId) {
  ref.watch(accountGenerationProvider);
  final plan = ref.watch(workoutPlanProvider);
  if (plan == null) return null;
  final date = ref.watch(selectedDateProvider);
  final start = ref.watch(
    profileProvider.select((profile) => profile.planStartDate),
  );
  for (final day in WorkoutCompletion.scheduledDays(
    plan,
    date,
    planStartDate: start,
  )) {
    if (day.dayId == dayId) return day;
  }
  return null;
});

final resolvedWorkoutDayProvider = Provider.family<WorkoutDay?, DateTime>((
  ref,
  date,
) {
  final plan = ref.watch(workoutPlanProvider);
  if (plan == null) return null;
  final start = ref.watch(
    profileProvider.select((profile) => profile.planStartDate),
  );
  return WorkoutCompletion.resolveWorkoutDay(plan, date, planStartDate: start);
});

// Keep as StateProvider to avoid breaking UI code that uses .state++
final exerciseLogsUpdateProvider = StateProvider<int>((ref) => 0);

final exerciseHistoryProvider = Provider.family<List<ExerciseLog>, String>((
  ref,
  exerciseName,
) {
  ref.watch(exerciseLogsUpdateProvider);
  ref.watch(exerciseRecordsUpdateProvider);
  ref.watch(accountGenerationProvider);
  return ref.watch(exerciseLogRepoProvider).getLogsForExercise(exerciseName);
});

final exercisePrProvider = Provider.family<ExercisePr?, String>((
  ref,
  exerciseName,
) {
  ref.watch(exerciseLogsUpdateProvider);
  ref.watch(exerciseRecordsUpdateProvider);
  // Watch logRepo to rebuild when PR updates
  ref.watch(accountGenerationProvider);
  final repo = ref.watch(exerciseLogRepoProvider);
  return repo.getPr(exerciseName);
});
