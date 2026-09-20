import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/utils/target_calculator.dart';

TargetEstimateInputs inputs({
  double height = 153,
  double weight = 66,
  int age = 29,
  String gender = 'F',
  String activity = 'Sedentary',
  String goal = 'Maintain',
}) => TargetEstimateInputs(
  heightCm: height,
  weightKg: weight,
  age: age,
  gender: gender,
  activityLevel: activity,
  goal: goal,
);

void expectCoherent(TargetMacros result) {
  expect(result.proteinG, greaterThanOrEqualTo(0));
  expect(result.carbsG, greaterThanOrEqualTo(0));
  expect(result.fatG, greaterThanOrEqualTo(0));
  final energy = result.proteinG * 4 + result.carbsG * 4 + result.fatG * 9;
  expect((energy - result.calories).abs(), lessThanOrEqualTo(2));
}

void main() {
  test('sister defaults reproduce the equation and coherent daily macros', () {
    final result = TargetCalculator.estimate(inputs());
    expect(result.restingCalories, 1310.25);
    expect(result.maintenanceCalories, 1572);
    expect(result.targets.calories, 1572);
    expect(result.targets.proteinG, 119);
    expect(result.targets.carbsG, 175);
    expect(result.targets.fatG, 44);
    expect(result.calorieFloorApplied, isFalse);
    expect(result.proteinTargetAdjusted, isFalse);
    expectCoherent(result.targets);
  });

  test('male moderate loss fixture adjusts maintenance only once', () {
    final result = TargetCalculator.estimate(
      inputs(
        height: 180,
        weight: 80,
        age: 40,
        gender: 'M',
        activity: 'Moderately active',
        goal: 'Lose weight',
      ),
    );
    expect(result.restingCalories, 1730);
    expect(result.maintenanceCalories, 2682);
    expect(result.targets.calories, 2145);
    expect(result.targets.proteinG, 144);
    expectCoherent(result.targets);
  });

  final sensitivity = <String, TargetEstimateInputs>{
    'height': inputs(height: 163),
    'weight': inputs(weight: 76),
    'age': inputs(age: 39),
    'sex': inputs(gender: 'M'),
    'activity': inputs(activity: 'Lightly active'),
    'goal': inputs(goal: 'Gain weight'),
  };
  for (final entry in sensitivity.entries) {
    test('changing ${entry.key} changes the estimate', () {
      expect(
        TargetCalculator.estimate(entry.value).targets.calories,
        isNot(TargetCalculator.estimate(inputs()).targets.calories),
      );
    });
  }

  final invalid = <String, TargetEstimateInputs>{
    'short height': inputs(height: 99),
    'tall height': inputs(height: 231),
    'nonfinite height': inputs(height: double.nan),
    'light weight': inputs(weight: 29),
    'heavy weight': inputs(weight: 201),
    'infinite weight': inputs(weight: double.infinity),
    'minor age': inputs(age: 17),
    'unsupported age': inputs(age: 101),
    'unknown sex': inputs(gender: 'other'),
    'unknown activity': inputs(activity: 'Almost active'),
    'unknown goal': inputs(goal: 'Anything'),
  };
  for (final entry in invalid.entries) {
    test('rejects ${entry.key} instead of generating a target', () {
      expect(
        () => TargetCalculator.estimate(entry.value),
        throwsFormatException,
      );
    });
  }

  test('floor and protein adjustments are visible to the caller', () {
    final floor = TargetCalculator.estimate(
      inputs(height: 100, weight: 30, age: 100, goal: 'Lose weight'),
    );
    expect(floor.maintenanceCalories, 317);
    expect(floor.targets.calories, 1200);
    expect(floor.calorieFloorApplied, isTrue);
    final high = TargetCalculator.estimate(
      inputs(height: 100, weight: 200, age: 100, goal: 'Lose weight'),
    );
    expect(high.proteinTargetAdjusted, isTrue);
    expect(
      high.targets.proteinG * 4 / high.targets.calories,
      lessThanOrEqualTo(0.35),
    );
    expect(high.targets.carbsG, greaterThan(0));
  });

  test('boundary matrix is finite, nonnegative and energy coherent', () {
    for (final height in [100.0, 230.0]) {
      for (final weight in [30.0, 200.0]) {
        for (final age in [18, 100]) {
          for (final sex in ['F', 'M']) {
            for (final activity in TargetCalculator.activityLevels) {
              for (final goal in TargetCalculator.goals) {
                final result = TargetCalculator.estimate(
                  inputs(
                    height: height,
                    weight: weight,
                    age: age,
                    gender: sex,
                    activity: activity,
                    goal: goal,
                  ),
                );
                expect(result.restingCalories.isFinite, isTrue);
                expect(result.targets.calories, greaterThanOrEqualTo(1200));
                expect(
                  result.targets.proteinG * 4 / result.targets.calories,
                  lessThanOrEqualTo(0.35),
                );
                expectCoherent(result.targets);
              }
            }
          }
        }
      }
    }
  });

  test('legacy aliases normalize without losing known choices', () {
    expect(TargetCalculator.normalizeGoal('Lose fat'), 'Lose weight');
    expect(TargetCalculator.normalizeGoal('Build muscle'), 'Gain weight');
    expect(TargetCalculator.normalizeGoal('Maintain'), 'Maintain');
    expect(TargetCalculator.normalizeGoal(null), 'Maintain');
    expect(
      TargetCalculator.normalizeActivityLevel(' light '),
      'Lightly active',
    );
    expect(
      TargetCalculator.normalizeActivityLevel('MODERATE'),
      'Moderately active',
    );
    expect(TargetCalculator.normalizeActivityLevel('Active'), 'Very active');
    expect(TargetCalculator.normalizeActivityLevel(null), 'Sedentary');
    final legacy = TargetCalculator.calculate(
      heightCm: 180,
      weightKg: 80,
      age: 40,
      gender: 'Male',
      goal: 'Lose fat',
      activityLevel: 'Moderate',
    );
    expect(legacy.calories, 2145);
    expectCoherent(legacy);
  });

  test(
    'nullable and invalid legacy profile values fall back without crashing',
    () {
      for (final height in <double?>[null, double.nan, 0]) {
        final targets = TargetCalculator.calculate(
          heightCm: height,
          weightKg: double.infinity,
          age: -1,
          gender: null,
          goal: null,
          activityLevel: null,
        );
        expect(targets.calories, 1572);
        expect(targets.proteinG, 119);
        expectCoherent(targets);
      }
    },
  );

  test('manual calorie changes retain feasible existing protein', () {
    const base = TargetMacros(
      calories: 2400,
      proteinG: 220,
      carbsG: 230,
      fatG: 67,
    );
    for (final calories in [800, 1200, 1573, 2000, 3499, 4000]) {
      final result = TargetCalculator.rebalanceForCalories(calories, base);
      expect(result.calories, calories < 1200 ? 1200 : calories);
      expect(result.proteinG, 220);
      expectCoherent(result);
    }
  });

  test('manual impossible protein is fitted to the actual calorie budget', () {
    const base = TargetMacros(
      calories: 3000,
      proteinG: 500,
      carbsG: 100,
      fatG: 67,
    );
    final result = TargetCalculator.rebalanceForCalories(1200, base);
    expect(result.proteinG, 300);
    expect(result.carbsG, 0);
    expect(result.fatG, 0);
    expectCoherent(result);
  });

  test('negative existing protein is rejected', () {
    const base = TargetMacros(
      calories: 2000,
      proteinG: -1,
      carbsG: 100,
      fatG: 67,
    );
    expect(
      () => TargetCalculator.rebalanceForCalories(1500, base),
      throwsFormatException,
    );
  });
}
