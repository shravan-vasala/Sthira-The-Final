import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/packaged_food.dart';

void main() {
  const food = PackagedFood(
    barcode: '0012345678905',
    name: 'Milk',
    brand: 'Test dairy',
    basis: NutritionBasis.per100ml,
    kcal: 60,
    proteinG: 3,
    carbsG: 5,
    fatG: 3,
    packageQuantity: 1000,
    packageUnit: FoodQuantityUnit.millilitres,
    servingQuantity: 200,
    servingUnit: FoodQuantityUnit.millilitres,
    source: PackagedFoodSource.openFoodFacts,
  );

  test('liquid nutrition scales in ml with no mass conversion', () {
    final result = food.computeNutrition(250);
    expect(result.kcal, 150);
    expect(result.proteinG, 7.5);
    expect(result.carbsG, 12.5);
    expect(result.fatG, 7.5);
    expect(food.amountUnit, 'ml');
  });

  test(
    'round trip preserves barcode zeros, units, source and nullable values',
    () {
      final restored = PackagedFood.fromJson(
        jsonDecode(jsonEncode(food.toJson())),
      );
      expect(restored.toJson(), food.toJson());
      expect(restored.barcode, '0012345678905');
      expect(restored.computeNutrition(250).kcal, 150);
    },
  );

  test('missing data remains unknown, not a zero calorie product', () {
    final incomplete = PackagedFood.fromJson({...food.toJson(), 'kcal': null});
    expect(incomplete.kcal, isNull);
    expect(incomplete.hasCompleteNutrition, isFalse);
    expect(incomplete.baseNutrition, isNull);
    expect(() => incomplete.computeNutrition(100), throwsFormatException);
  });

  test('explicit zeros remain valid for zero sugar drinks', () {
    final zero = PackagedFood.fromJson({
      ...food.toJson(),
      'kcal': 0,
      'protein_g': 0,
      'carbs_g': 0,
      'fat_g': 0,
    });
    expect(zero.hasCompleteNutrition, isTrue);
    expect(zero.computeNutrition(330).kcal, 0);
  });

  test('unknown nutrition basis cannot be logged', () {
    final unknown = PackagedFood.fromJson({...food.toJson(), 'basis': null});
    expect(unknown.hasCompleteNutrition, isFalse);
    expect(() => unknown.computeNutrition(100), throwsFormatException);
  });

  test('grams and fractional servings each use their declared basis', () {
    final grams = PackagedFood.fromJson({...food.toJson(), 'basis': 'per100g'});
    final servings = PackagedFood.fromJson({
      ...food.toJson(),
      'basis': 'perServing',
    });
    expect(grams.computeNutrition(50).kcal, 30);
    expect(servings.computeNutrition(0.5).kcal, 30);
    expect(servings.amountUnit, 'servings');
  });

  test('invalid amounts cannot produce food log nutrition', () {
    for (final amount in [0.0, -1.0, double.nan, double.infinity]) {
      expect(() => food.computeNutrition(amount), throwsFormatException);
    }
  });

  test('invalid label values are incomplete even in direct constructor', () {
    for (final invalid in [-1.0, double.nan, double.infinity]) {
      final value = PackagedFood(
        barcode: food.barcode,
        name: food.name,
        basis: food.basis,
        kcal: invalid,
        proteinG: 0,
        carbsG: 0,
        fatG: 0,
        source: PackagedFoodSource.manual,
      );
      expect(value.hasCompleteNutrition, isFalse);
      expect(() => value.computeNutrition(100), throwsFormatException);
    }
  });

  test('base nutrition callers cannot mutate the label snapshot', () {
    food.baseNutrition!.kcal = 999;
    expect(food.kcal, 60);
    expect(food.computeNutrition(100).kcal, 60);
  });

  test('quantity without a unit is discarded on restore', () {
    final restored = PackagedFood.fromJson({
      ...food.toJson(),
      'package_unit': null,
      'serving_quantity': -1,
    });
    expect(restored.packageQuantity, isNull);
    expect(restored.packageUnit, isNull);
    expect(restored.servingQuantity, isNull);
    expect(restored.servingUnit, isNull);
  });

  test('corrupt snapshot identity and source are rejected', () {
    expect(
      () => PackagedFood.fromJson({...food.toJson(), 'barcode': 123}),
      throwsFormatException,
    );
    expect(
      () => PackagedFood.fromJson({...food.toJson(), 'source': 'guess'}),
      throwsFormatException,
    );
  });

  test('scaling cannot overflow into nonfinite logged nutrition', () {
    final large = PackagedFood.fromJson({...food.toJson(), 'kcal': 1e308});
    expect(() => large.computeNutrition(1e308), throwsFormatException);
  });
}
