class TargetMacros {
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;
  const TargetMacros({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });
}

class TargetEstimateInputs {
  final double heightCm;
  final double weightKg;
  final int age;
  final String gender;
  final String activityLevel;
  final String goal;
  const TargetEstimateInputs({
    required this.heightCm,
    required this.weightKg,
    required this.age,
    required this.gender,
    required this.activityLevel,
    required this.goal,
  });
}

class TargetEstimate {
  final TargetEstimateInputs inputs;
  final double restingCalories;
  final int maintenanceCalories;
  final TargetMacros targets;
  final bool calorieFloorApplied;
  final bool proteinTargetAdjusted;
  const TargetEstimate({
    required this.inputs,
    required this.restingCalories,
    required this.maintenanceCalories,
    required this.targets,
    required this.calorieFloorApplied,
    required this.proteinTargetAdjusted,
  });
}

class TargetCalculator {
  static const double defaultHeightCm = 153.0;
  static const double defaultWeightKg = 66.0;
  static const int defaultAge = 29;
  static const String defaultGender = 'F';
  static const String defaultActivity = 'Sedentary';
  static const String defaultGoal = 'Maintain';
  static const int minimumCalories = 1200;
  static const activityLevels = [
    'Sedentary',
    'Lightly active',
    'Moderately active',
    'Very active',
    'Extra active',
  ];
  static const goals = ['Maintain', 'Lose weight', 'Gain weight'];
  static const _activityFactors = [1.2, 1.375, 1.55, 1.725, 1.9];

  /// Mifflin-St Jeor energy estimate. The floor is an app constraint,
  /// not a medical safety threshold.
  static TargetEstimate estimate(TargetEstimateInputs inputs) {
    if (!_inRange(inputs.heightCm, 100, 230)) {
      throw const FormatException('Enter a height from 100 to 230 cm.');
    }
    if (!_inRange(inputs.weightKg, 30, 200)) {
      throw const FormatException('Enter a weight from 30 to 200 kg.');
    }
    if (inputs.age < 18 || inputs.age > 100) {
      throw const FormatException('Enter an adult age from 18 to 100.');
    }
    if (inputs.gender != 'F' && inputs.gender != 'M') {
      throw const FormatException('Select female or male for the equation.');
    }
    final activityIndex = activityLevels.indexOf(inputs.activityLevel);
    if (activityIndex < 0 || !goals.contains(inputs.goal)) {
      throw const FormatException('Select an activity level and goal.');
    }
    final resting =
        10 * inputs.weightKg +
        6.25 * inputs.heightCm -
        5 * inputs.age +
        (inputs.gender == 'M' ? 5 : -161);
    final maintenance = resting * _activityFactors[activityIndex];
    final factor = switch (inputs.goal) {
      'Lose weight' => 0.8,
      'Gain weight' => 1.1,
      _ => 1.0,
    };
    final adjusted = (maintenance * factor).round();
    final calories = adjusted < minimumCalories ? minimumCalories : adjusted;
    final requestedProtein = (inputs.weightKg * 1.8).round();
    // Keep the automatic suggestion within the adult protein energy range.
    final proteinLimit = (calories * 0.35 / 4).floor();
    final protein = requestedProtein > proteinLimit
        ? proteinLimit
        : requestedProtein;
    return TargetEstimate(
      inputs: inputs,
      restingCalories: resting,
      maintenanceCalories: maintenance.round(),
      targets: _allocate(calories, protein),
      calorieFloorApplied: adjusted < minimumCalories,
      proteinTargetAdjusted: protein != requestedProtein,
    );
  }

  static bool _inRange(double value, double min, double max) =>
      value.isFinite && value >= min && value <= max;

  static String normalizeActivityLevel(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'lightly active' || 'light' => 'Lightly active',
      'moderately active' || 'moderate' => 'Moderately active',
      'very active' || 'active' => 'Very active',
      'extra active' => 'Extra active',
      _ => defaultActivity,
    };
  }

  static String normalizeGoal(String? value) {
    final goal = value?.trim().toLowerCase() ?? '';
    if (goal.contains('lose')) return 'Lose weight';
    if (goal.contains('gain') || goal.contains('build')) return 'Gain weight';
    return defaultGoal;
  }

  /// Compatibility entry point for optional saved profile values.
  /// Interactive inputs should use [estimate] to surface invalid entries.
  static TargetMacros calculate({
    required double? heightCm,
    required double? weightKg,
    required int? age,
    required String? gender,
    required String? goal,
    required String? activityLevel,
  }) {
    final sex = gender?.trim().toLowerCase();
    return estimate(
      TargetEstimateInputs(
        heightCm: heightCm != null && _inRange(heightCm, 100, 230)
            ? heightCm
            : defaultHeightCm,
        weightKg: weightKg != null && _inRange(weightKg, 30, 200)
            ? weightKg
            : defaultWeightKg,
        age: age != null && age >= 18 && age <= 100 ? age : defaultAge,
        gender: sex == 'm' || sex == 'male' ? 'M' : 'F',
        goal: normalizeGoal(goal),
        activityLevel: normalizeActivityLevel(activityLevel),
      ),
    ).targets;
  }

  /// Retains an existing protein target where the calorie budget permits.
  /// Unlike automatic estimates, this does not impose a new protein ratio.
  static TargetMacros rebalanceForCalories(
    int newCalories,
    TargetMacros originalBase,
  ) {
    final calories = newCalories < minimumCalories
        ? minimumCalories
        : newCalories;
    if (originalBase.proteinG < 0) {
      throw const FormatException('Protein cannot be negative.');
    }
    return _allocate(calories, originalBase.proteinG);
  }

  static TargetMacros _allocate(int calories, int requestedProtein) {
    final proteinLimit = calories ~/ 4;
    final protein = requestedProtein > proteinLimit
        ? proteinLimit
        : requestedProtein;
    final remaining = calories - protein * 4;
    final preferredFat = (calories * 0.25 / 9).round();
    final fatLimit = remaining ~/ 9;
    final fat = preferredFat > fatLimit ? fatLimit : preferredFat;
    final carbs = ((remaining - fat * 9) / 4).round();
    // Round the remainder last: whole-gram energy differs by at most 2 kcal.
    return TargetMacros(
      calories: calories,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
    );
  }
}
