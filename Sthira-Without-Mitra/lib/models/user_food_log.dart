import 'package:isar/isar.dart';
import 'food_nutrition.dart';

part 'user_food_log.g.dart';

@collection
class UserFoodLog {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  final String normalizedName; // e.g., "idli", "sambar", "chicken curry"

  final String originalName;

  final FoodNutrition baseNutrition;

  final bool isPer100g;
  final double? servingGrams;
  final String? provenance; // 'verified', 'estimated', 'yours'

  final DateTime addedAt;

  UserFoodLog({
    required this.normalizedName,
    required this.originalName,
    required this.baseNutrition,
    this.isPer100g = false,
    this.servingGrams,
    this.provenance,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
    'name': originalName,
    'kcal': baseNutrition.kcal,
    'protein_g': baseNutrition.proteinG,
    'carbs_g': baseNutrition.carbsG,
    'fat_g': baseNutrition.fatG,
    'is_per_100g': isPer100g,
    if (servingGrams != null) 'serving_grams': servingGrams,
    if (provenance != null) 'provenance': provenance,
  };
}
