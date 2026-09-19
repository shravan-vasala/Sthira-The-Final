import '../models/exercise_log.dart';
import '../models/exercise_pr.dart';

class PrCalculationResult {
  final ExercisePr newPr;
  final bool isNewMaxWeight;
  final bool isNewMaxReps;
  final bool isNewMaxVolume;
  final bool isNew1RM;

  PrCalculationResult({
    required this.newPr,
    this.isNewMaxWeight = false,
    this.isNewMaxReps = false,
    this.isNewMaxVolume = false,
    this.isNew1RM = false,
  });

  bool get hasAnyNewPr =>
      isNewMaxWeight || isNewMaxReps || isNewMaxVolume || isNew1RM;
}

class PrCalculator {
  static double calculate1RM(double weight, int reps) {
    if (reps == 0) return 0;
    if (reps == 1) return weight;
    // Epley formula: w * (1 + r/30)
    return weight * (1 + reps / 30);
  }

  static PrCalculationResult calculateNewPr(
    ExerciseLog log,
    ExercisePr? currentPr,
  ) {
    final pr = currentPr ?? ExercisePr(exerciseName: log.exerciseName);

    bool newMaxWeight = false;
    bool newMaxReps = false;
    bool newMaxVolume = false;
    bool new1RM = false;

    double maxWeight = pr.maxWeight;
    int maxWeightReps = pr.maxWeightReps;

    int maxReps = pr.maxReps;
    double maxRepsWeight = pr.maxRepsWeight;

    double estimated1RM = pr.estimated1RM;

    for (final set in log.sets) {
      final setWeight = set.weight ?? 0.0;
      final setReps = set.reps ?? 0;

      // Check max weight (only meaningful if weight > 0)
      if (setWeight > 0) {
        if (setWeight > maxWeight) {
          maxWeight = setWeight;
          maxWeightReps = setReps;
          newMaxWeight = true;
        } else if (setWeight == maxWeight && setReps > maxWeightReps) {
          maxWeightReps = setReps;
          newMaxWeight = true;
        }
      }

      // Check max reps
      if (setReps > maxReps) {
        maxReps = setReps;
        maxRepsWeight = setWeight;
        newMaxReps = true;
      } else if (setReps == maxReps && setWeight > maxRepsWeight) {
        maxRepsWeight = setWeight;
        newMaxReps = true;
      }

      // Check 1RM
      final current1RM = calculate1RM(setWeight, setReps);
      if (current1RM > estimated1RM) {
        estimated1RM = current1RM;
        new1RM = true;
      }
    }

    // Check volume
    double maxVolume = pr.maxVolume;
    if (log.totalVolume > maxVolume) {
      maxVolume = log.totalVolume;
      newMaxVolume = true;
    }

    final newPr = pr.copyWith(
      maxWeight: maxWeight,
      maxWeightReps: maxWeightReps,
      maxReps: maxReps,
      maxRepsWeight: maxRepsWeight,
      estimated1RM: estimated1RM,
      maxVolume: maxVolume,
    );

    return PrCalculationResult(
      newPr: newPr,
      isNewMaxWeight: newMaxWeight,
      isNewMaxReps: newMaxReps,
      isNewMaxVolume: newMaxVolume,
      isNew1RM: new1RM,
    );
  }
}
