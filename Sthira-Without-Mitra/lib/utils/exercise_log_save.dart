import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_plan.dart';
import '../models/exercise_log.dart';
import '../models/exercise_pr.dart';
import '../providers/app_providers.dart';

import 'target_parser.dart';

/// Rep targets come from the original sets, never the condensed display label.
/// Duration is stored separately; distance and ambiguous units are not rep targets.
bool supportsRepLogging(Exercise exercise) =>
    (exercise.durationSeconds ?? 0) <= 0 &&
    !exercise.reps.any(
      (target) => RegExp(
        r'\d\s*(?:s(?:ec(?:onds?)?)?|m(?:in(?:utes?)?)?|km|mi(?:les?)?|h(?:ours?)?)\b',
        caseSensitive: false,
      ).hasMatch(target),
    );

/// Explicit time targets retain their unit and original set count.
List<int> plannedDurationTargets(Exercise exercise) {
  if ((exercise.durationSeconds ?? 0) > 0) {
    return List.filled(
      exercise.reps.isEmpty ? 1 : exercise.reps.length,
      exercise.durationSeconds!,
    );
  }
  final targets = <int>[];
  for (final raw in exercise.reps) {
    final match = RegExp(
      r'^(\d+(?:\.\d+)?)\s*(s|sec|secs|second|seconds|min|mins|minute|minutes|h|hr|hrs|hour|hours)$',
      caseSensitive: false,
    ).firstMatch(raw.trim());
    if (match == null) return const [];
    final amount = double.parse(match.group(1)!);
    final unit = match.group(2)!.toLowerCase();
    final seconds =
        amount *
        (unit.startsWith('h')
            ? 3600
            : unit.startsWith('m')
            ? 60
            : 1);
    if (!seconds.isFinite || seconds <= 0 || seconds != seconds.roundToDouble())
      return const [];
    targets.add(seconds.toInt());
  }
  return targets;
}

bool supportsExerciseLogging(Exercise exercise) =>
    plannedDurationTargets(exercise).isNotEmpty || supportsRepLogging(exercise);

List<int> plannedRepTargets(Exercise exercise) {
  if ((exercise.durationSeconds ?? 0) > 0) return const [];
  final targets = <int>[];
  for (final raw in exercise.reps) {
    final value = raw.trim().toLowerCase();
    if (!RegExp(r'^\d+(?:\s*[-–]\s*\d+)?(?:\s*reps?)?$').hasMatch(value)) {
      return const [];
    }
    final reps = TargetParser.parseRepTarget(value.replaceAll('–', '-'));
    if (reps <= 0) return const [];
    targets.add(reps);
  }
  return targets;
}

SetLog? loggedSetNumber(ExerciseLog? log, int number) {
  if (log == null) return null;
  for (final set in log.sets) {
    if (set.setNumber == number) return set;
  }
  // Older records may not have explicit numbering.
  if (log.sets.every((set) => set.setNumber == null) &&
      number <= log.sets.length) {
    return log.sets[number - 1];
  }
  return null;
}

void ensureExerciseSaveScope(WidgetRef ref, int generation, String date) {
  if (!ref.context.mounted ||
      ref.read(accountGenerationProvider) != generation ||
      ref.read(accountTransitionProvider)) {
    throw StateError('Your account changed. Reopen this exercise to log it.');
  }
  final day = DateTime.tryParse(date);
  final now = ref.read(clockProvider);
  if (day == null || day.isAfter(DateTime(now.year, now.month, now.day))) {
    throw StateError('Future workouts cannot be logged yet.');
  }
}

Future<PrUpdateResult> saveExerciseAsPlanned({
  required WidgetRef ref,
  required Exercise exercise,
}) async {
  final date = ref.read(dateStringProvider);
  final generation = ref.read(accountGenerationProvider);
  ensureExerciseSaveScope(ref, generation, date);
  final durations = plannedDurationTargets(exercise);
  final timed = durations.isNotEmpty;
  final targets = timed ? durations : plannedRepTargets(exercise);
  if (targets.isEmpty) {
    throw StateError(
      supportsRepLogging(exercise)
          ? 'Enter the actual reps for this open target before saving.'
          : 'This target has no supported unit. Confirm the expert guidance before logging it.',
    );
  }
  final repo = ref.read(exerciseLogRepoProvider);
  final lastLog = repo.getLastLog(exercise.name ?? '', beforeDate: date);
  final sets = <SetLog>[];
  for (var i = 0; i < targets.length; i++) {
    final weight = timed
        ? 0.0
        : exercise.weightKg ?? loggedSetNumber(lastLog, i + 1)?.weight ?? 0;
    if (!weight.isFinite || weight < 0) {
      throw StateError('Enter a valid weight before saving.');
    }
    sets.add(
      SetLog(
        setNumber: i + 1,
        reps: timed ? null : targets[i],
        durationSeconds: timed ? targets[i] : null,
        weight: weight,
      ),
    );
  }
  await repo.saveLog(
    ExerciseLog(
      date: date,
      instanceId: exercise.instanceId ?? exercise.name ?? '',
      exerciseName: exercise.name ?? '',
      sets: sets,
    ),
  );
  ensureExerciseSaveScope(ref, generation, date);
  ref.read(exerciseLogsUpdateProvider.notifier).state++;
  return checkAndSavePr(
    ref: ref,
    exerciseName: exercise.name ?? '',
    sets: sets,
    expectedGeneration: generation,
  );
}

Future<PrUpdateResult> checkAndSavePr({
  required WidgetRef ref,
  required String exerciseName,
  required List<SetLog> sets,
  int? expectedGeneration,
}) async {
  final generation = expectedGeneration ?? ref.read(accountGenerationProvider);
  if (!ref.context.mounted ||
      ref.read(accountGenerationProvider) != generation) {
    throw StateError('Your account changed. Reopen this exercise to log it.');
  }
  final repo = ref.read(exerciseLogRepoProvider);
  final allLogs = repo.getLogsForExercise(exerciseName);
  if (!allLogs.any((log) => log.sets.any((set) => (set.reps ?? 0) > 0)) &&
      repo.getPr(exerciseName) == null) {
    return PrUpdateResult(newPr: ExercisePr(exerciseName: exerciseName));
  }

  var calcMaxWeight = 0.0;
  var calcMaxWeightReps = 0;
  var calcMaxReps = 0;
  var calcMaxRepsWeight = 0.0;
  var calcMaxVolume = 0.0;
  var calcEstimated1RM = 0.0;

  for (final log in allLogs) {
    var logVolume = 0.0;
    for (final s in log.sets) {
      final w = s.weight ?? 0.0;
      final r = s.reps ?? 0;
      if (!w.isFinite || w < 0 || r <= 0) continue;

      if (w > calcMaxWeight || (w == calcMaxWeight && r > calcMaxWeightReps)) {
        calcMaxWeight = w;
        calcMaxWeightReps = r;
      }

      if (r > calcMaxReps || (r == calcMaxReps && w > calcMaxRepsWeight)) {
        calcMaxReps = r;
        calcMaxRepsWeight = w;
      }

      logVolume += (w * r);
      final oneRM = w * (1 + (r / 30));
      if (oneRM > calcEstimated1RM) calcEstimated1RM = oneRM;
    }
    if (logVolume > calcMaxVolume) calcMaxVolume = logVolume;
  }

  final currentPr = repo.getPr(exerciseName);
  final oldW = currentPr?.maxWeight ?? 0.0;
  final oldR = currentPr?.maxReps ?? 0;
  final oldV = currentPr?.maxVolume ?? 0.0;
  final old1RM = currentPr?.estimated1RM ?? 0.0;

  final updatedPr = ExercisePr(
    exerciseName: exerciseName,
    maxWeight: calcMaxWeight,
    maxWeightReps: calcMaxWeightReps,
    maxReps: calcMaxReps,
    maxRepsWeight: calcMaxRepsWeight,
    maxVolume: calcMaxVolume,
    estimated1RM: calcEstimated1RM,
  );

  await repo.savePr(updatedPr);
  if (!ref.context.mounted ||
      ref.read(accountGenerationProvider) != generation) {
    throw StateError('Your account changed. Reopen this exercise to log it.');
  }

  final newW = calcMaxWeight > oldW && calcMaxWeight > 0;
  final newR = calcMaxReps > oldR && calcMaxReps > 0;
  final newV = calcMaxVolume > oldV && calcMaxVolume > 0;
  final new1RM = calcEstimated1RM > old1RM && calcEstimated1RM > 0;
  final hasAnyNewPr = newW || newR || newV || new1RM;

  return PrUpdateResult(
    hasAnyNewPr: hasAnyNewPr,
    isNewMaxWeight: newW,
    isNewMaxReps: newR,
    isNewMaxVolume: newV,
    isNew1RM: new1RM,
    newPr: updatedPr,
  );
}

class PrUpdateResult {
  final bool hasAnyNewPr;
  final bool isNewMaxWeight;
  final bool isNewMaxReps;
  final bool isNewMaxVolume;
  final bool isNew1RM;
  final ExercisePr newPr;

  PrUpdateResult({
    this.hasAnyNewPr = false,
    this.isNewMaxWeight = false,
    this.isNewMaxReps = false,
    this.isNewMaxVolume = false,
    this.isNew1RM = false,
    required this.newPr,
  });
}

Map<String, dynamic> getExerciseChartData(WidgetRef ref, Exercise exercise) {
  final repo = ref.read(exerciseLogRepoProvider);
  return {
    'allLogs': repo.getLogsForExercise(exercise.name ?? ''),
    'pr': repo.getPr(exercise.name ?? ''),
  };
}
