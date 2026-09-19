class TargetMacros {
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;

  TargetMacros({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });
}

class TargetCalculator {
  static const double defaultHeightCm = 153.0;
  static const double defaultWeightKg = 66.0;
  static const int defaultAge = 29;
  static const String defaultGender = 'F';
  static const String defaultActivity = 'Sedentary';

  /// Calculate suggested targets using Mifflin-St Jeor equation.
  static TargetMacros calculate({
    required double? heightCm,
    required double? weightKg,
    required int? age,
    required String? gender,
    required String? goal,
    required String? activityLevel,
  }) {
    final weight = weightKg ?? defaultWeightKg;
    final h = heightCm ?? defaultHeightCm;
    final a = age ?? defaultAge;
    final isMale = (gender ?? defaultGender).toUpperCase() == 'M';

    // Mifflin-St Jeor BMR
    double bmr = (10 * weight) + (6.25 * h) - (5 * a);
    bmr += isMale ? 5 : -161;

    // Activity multiplier
    double multiplier = 1.2; // defaultActivity (Sedentary)
    switch ((activityLevel ?? defaultActivity).toLowerCase()) {
      case 'lightly active':
      case 'light':
        multiplier = 1.375;
        break;
      case 'moderately active':
      case 'moderate':
        multiplier = 1.55;
        break;
      case 'very active':
      case 'active':
        multiplier = 1.725;
        break;
      case 'extra active':
        multiplier = 1.9;
        break;
    }

    double tdee = bmr * multiplier;

    // Goal adjustment
    if (goal != null) {
      if (goal.toLowerCase().contains('lose')) {
        tdee *= 0.8; // -20%
      } else if (goal.toLowerCase().contains('gain') ||
          goal.toLowerCase().contains('build')) {
        tdee *= 1.1; // +10%
      }
    }

    int targetCalories = tdee.round();
    if (targetCalories < 1200) targetCalories = 1200;

    // Macros:
    // Protein: 1.8g / kg
    final double protein = weight * 1.8;

    // Fat: 25% of total calories
    final double fat = (targetCalories * 0.25) / 9;

    // Carbs: remainder
    final double caloriesFromProtein = protein * 4;
    final double caloriesFromFat = fat * 9;
    double carbs = (targetCalories - caloriesFromProtein - caloriesFromFat) / 4;
    if (carbs < 0) carbs = 0;

    return TargetMacros(
      calories: targetCalories,
      proteinG: _roundToNearest5(protein),
      fatG: _roundToNearest5(fat),
      carbsG: _roundToNearest5(carbs),
    );
  }

  /// Adjust calories up/down while maintaining the absolute protein target
  /// and assigning the remainder between carbs and fat.
  static TargetMacros rebalanceForCalories(
    int newCalories,
    TargetMacros originalBase,
  ) {
    if (newCalories < 1200) newCalories = 1200;

    // Keep protein fixed
    double protein = originalBase.proteinG.toDouble();
    final double caloriesFromProtein = protein * 4;

    // What's left over?
    double remainingCalories = newCalories - caloriesFromProtein;
    if (remainingCalories < 0) {
      // Infeasible: protein alone exceeds the targeted calories!
      // Scale protein down heavily so it fits.
      protein = (newCalories * 0.4) / 4;
      remainingCalories = newCalories - (protein * 4);
    }

    // Assign up to 25% of total calories to fat, but not exceeding remaining
    double targetFatCals = newCalories * 0.25;
    if (targetFatCals > remainingCalories) {
      targetFatCals = remainingCalories;
    }
    final double fat = targetFatCals / 9;

    // Remainder goes to carbs
    double carbs = (remainingCalories - targetFatCals) / 4;
    if (carbs < 0) carbs = 0;

    return TargetMacros(
      calories: newCalories,
      proteinG: _roundToNearest5(protein),
      fatG: _roundToNearest5(fat),
      carbsG: _roundToNearest5(carbs),
    );
  }

  static int _roundToNearest5(double value) {
    return (value / 5).round() * 5;
  }
}
