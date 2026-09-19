import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/utils/pr_calculator.dart';
import 'package:trufit_bodamma/models/exercise_log.dart';
import 'package:trufit_bodamma/models/exercise_pr.dart';

void main() {
  test('calculate1RM returns correct values', () {
    expect(PrCalculator.calculate1RM(100, 0), 0);
    expect(PrCalculator.calculate1RM(100, 1), 100);
    // Epley formula for 100x10 is 100 * (1 + 10/30) = 133.333
    expect(PrCalculator.calculate1RM(100, 10), closeTo(133.33, 0.01));
  });

  test('calculateNewPr detects new max weight', () {
    final log = ExerciseLog(
      date: '2023-10-01',
      instanceId: 'Squat',
      exerciseName: 'Squat',
      sets: [
        SetLog(setNumber: 1, weight: 100, reps: 5),
        SetLog(setNumber: 2, weight: 120, reps: 3), // new max weight
      ],
    );

    final result = PrCalculator.calculateNewPr(log, null);

    expect(result.isNewMaxWeight, isTrue);
    expect(result.newPr.maxWeight, 120.0);
    expect(result.newPr.maxWeightReps, 3);
  });

  test('calculateNewPr detects new max reps at same weight', () {
    final currentPr = ExercisePr(
      exerciseName: 'Squat',
      maxWeight: 100,
      maxWeightReps: 5,
    );

    final log = ExerciseLog(
      date: '2023-10-01',
      instanceId: 'Squat',
      exerciseName: 'Squat',
      sets: [
        SetLog(setNumber: 1, weight: 100, reps: 8), // new max weight reps
      ],
    );

    final result = PrCalculator.calculateNewPr(log, currentPr);

    expect(result.isNewMaxWeight, isTrue);
    expect(result.newPr.maxWeight, 100.0);
    expect(result.newPr.maxWeightReps, 8);
  });

  test('calculateNewPr detects max volume', () {
    final currentPr = ExercisePr(
      exerciseName: 'Squat',
      maxVolume: 500, // 100x5
    );

    final log = ExerciseLog(
      date: '2023-10-01',
      instanceId: 'Squat',
      exerciseName: 'Squat',
      sets: [
        SetLog(setNumber: 1, weight: 100, reps: 6), // vol = 600
      ],
    );

    final result = PrCalculator.calculateNewPr(log, currentPr);

    expect(result.isNewMaxVolume, isTrue);
    expect(result.newPr.maxVolume, 600.0);
  });
}
