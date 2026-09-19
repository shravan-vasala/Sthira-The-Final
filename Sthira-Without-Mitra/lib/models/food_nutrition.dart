import 'package:isar/isar.dart';

part 'food_nutrition.g.dart';

@embedded
class FoodNutrition {
  double kcal;
  double proteinG;
  double carbsG;
  double fatG;

  FoodNutrition({
    this.kcal = 0.0,
    this.proteinG = 0.0,
    this.carbsG = 0.0,
    this.fatG = 0.0,
  });

  factory FoodNutrition.fromJson(Map<String, dynamic> json) {
    return FoodNutrition(
      kcal: (json['kcal'] as num?)?.toDouble() ?? 0.0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0.0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0.0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'kcal': kcal,
    'protein_g': proteinG,
    'carbs_g': carbsG,
    'fat_g': fatG,
  };

  /// Compute the total macros/calories based on the consumed grams/servings and the nutrition basis
  static FoodNutrition compute({
    double? consumedGrams,
    double? consumedServings,
    required FoodNutrition baseNutrition,
    required bool isPer100g,
    double? servingGrams,
  }) {
    final quantities = [
      consumedGrams,
      consumedServings,
      servingGrams,
    ].whereType<double>();
    if (quantities.any((v) => !v.isFinite || v < 0) ||
        [
          baseNutrition.kcal,
          baseNutrition.proteinG,
          baseNutrition.carbsG,
          baseNutrition.fatG,
        ].any((v) => !v.isFinite || v < 0)) {
      throw const FormatException(
        'Nutrition and quantities must be finite and nonnegative.',
      );
    }
    if ((consumedGrams == null || consumedGrams <= 0) &&
        (consumedServings == null || consumedServings <= 0)) {
      return FoodNutrition();
    }

    double multiplier = 1.0;

    if (isPer100g) {
      if (consumedGrams != null) {
        multiplier = consumedGrams / 100.0;
      } else if (consumedServings != null) {
        if (servingGrams != null && servingGrams > 0) {
          multiplier = (consumedServings * servingGrams) / 100.0;
        } else {
          // Cannot convert safely from servings to 100g basis without a defined serving mass.
          throw const FormatException(
            'Missing serving_grams for per-100g conversion.',
          );
        }
      }
    } else {
      // Basis is per-serving
      if (consumedServings != null && consumedGrams == null) {
        multiplier = consumedServings;
      } else if (consumedGrams != null) {
        if (servingGrams != null && servingGrams > 0) {
          multiplier = consumedGrams / servingGrams;
        } else {
          // Cannot convert safely from grams to per-serving basis without a defined serving mass.
          throw const FormatException(
            'Missing serving_grams for per-serving conversion.',
          );
        }
      }
    }

    final result = FoodNutrition(
      kcal: baseNutrition.kcal * multiplier,
      proteinG: baseNutrition.proteinG * multiplier,
      carbsG: baseNutrition.carbsG * multiplier,
      fatG: baseNutrition.fatG * multiplier,
    );
    if ([
      result.kcal,
      result.proteinG,
      result.carbsG,
      result.fatG,
    ].any((v) => !v.isFinite)) {
      throw const FormatException(
        'Nutrition calculation exceeds the supported range.',
      );
    }
    return result;
  }
}
