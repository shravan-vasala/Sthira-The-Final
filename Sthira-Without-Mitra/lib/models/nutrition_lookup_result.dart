import '../models/food_nutrition.dart';

class NutritionLookupResult {
  final String id;
  final String name;
  final FoodNutrition baseNutrition;
  final bool isPer100g;
  final double? servingGrams;
  final String? baseQuantityUnit;
  final String? provenance;
  final bool estimated;
  final String? preparation;

  NutritionLookupResult({
    required this.id,
    required this.name,
    required this.baseNutrition,
    required this.isPer100g,
    this.servingGrams,
    this.baseQuantityUnit,
    this.provenance,
    this.estimated = true,
    this.preparation,
  });
}
