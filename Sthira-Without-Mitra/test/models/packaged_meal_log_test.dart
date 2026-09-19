import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/food_nutrition.dart';

void main() {
  test(
    'legacy calorie fields still reconstruct a meal without packaged units',
    () {
      final item = MealItemLog.fromJson({
        'name': 'Homemade dal',
        'portion': '1 bowl',
        'calories': 210,
        'protein_g': 12,
        'carbs_g': 30,
        'fat_g': 6,
        'is_per_100g': true,
        'consumed_grams': 150,
      });

      expect(item.computedNutrition!.kcal, 210);
      expect(item.isPer100g, isTrue);
      expect(item.consumedGrams, 150);
      expect(item.nutritionBasis, isNull);
      expect(item.consumedMl, isNull);
      expect(item.barcode, isNull);
      final restored = MealItemLog.fromJson(item.toJson());
      expect(restored.toJson(), item.toJson());
      expect(restored.toJson(), isNot(contains('consumed_ml')));
    },
  );

  test(
    'millilitres round trip without becoming grams or per-100g nutrition',
    () {
      final item = MealItemLog(
        name: 'Plain milk',
        portion: '250 ml',
        barcode: '8901234567890',
        brand: 'Test dairy',
        nutritionBasis: 'per100ml',
        isPer100g: true,
        consumedMl: 250,
        baseNutrition: FoodNutrition(kcal: 60, proteinG: 3),
        computedNutrition: FoodNutrition(kcal: 150, proteinG: 7.5),
        provenance: 'label',
      );

      final restored = MealItemLog.fromJson(item.toJson());
      expect(restored.barcode, item.barcode);
      expect(restored.brand, item.brand);
      expect(restored.nutritionBasis, 'per100ml');
      expect(restored.isPer100g, isFalse);
      expect(restored.consumedMl, 250);
      expect(restored.consumedGrams, isNull);
      expect(restored.baseNutrition!.kcal, 60);
      expect(restored.computedNutrition!.kcal, 150);
      expect(restored.toJson()['nutrition_basis'], 'per100ml');
      expect(restored.toJson()['consumed_ml'], 250);
    },
  );

  test('gram and serving bases retain their explicit consumed units', () {
    final grams = MealItemLog(
      name: 'Biscuits',
      nutritionBasis: 'per100g',
      consumedGrams: 25,
    ).copy();
    final servings = MealItemLog(
      name: 'Small pack',
      nutritionBasis: 'perServing',
      consumedServings: 0.5,
    ).copy();

    expect(grams.isPer100g, isTrue);
    expect(grams.consumedGrams, 25);
    expect(grams.consumedMl, isNull);
    expect(servings.isPer100g, isFalse);
    expect(servings.consumedServings, 0.5);
    expect(servings.consumedGrams, isNull);
    expect(servings.toJson()['consumed_servings'], 0.5);
  });

  test('copy freezes base and computed nutrition independently', () {
    final item = MealItemLog(
      name: 'Yoghurt',
      baseNutrition: FoodNutrition(kcal: 65),
      computedNutrition: FoodNutrition(kcal: 130),
    );
    final snapshot = item.copy();
    item.baseNutrition!.kcal = 90;
    item.computedNutrition!.kcal = 180;

    expect(snapshot.portion, isNull);
    expect(snapshot.baseNutrition!.kcal, 65);
    expect(snapshot.computedNutrition!.kcal, 130);
  });
}
