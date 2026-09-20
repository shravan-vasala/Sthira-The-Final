import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/food_nutrition.dart';
import 'package:trufit_bodamma/utils/meal_serving.dart';

MealItemLog milk() => MealItemLog(
  name: 'Milk',
  portion: '200 ml',
  barcode: '8901234567890',
  nutritionBasis: 'per100ml',
  consumedMl: 200,
  provenance: 'label',
  baseNutrition: FoodNutrition(kcal: 60, proteinG: 3, carbsG: 5, fatG: 2),
  computedNutrition: FoodNutrition(kcal: 120, proteinG: 6, carbsG: 10, fatG: 4),
);

void main() {
  test(
    'extra portions scale recorded nutrition and units without changing source',
    () {
      final item = milk();
      final slot = MealSlotLog(items: [item], totalCalories: 120);
      final extra = MealServing.repeat(slot, item, 1.25);
      expect(extra.computedNutrition!.kcal, 150);
      expect(extra.computedNutrition!.proteinG, 7.5);
      expect(extra.consumedMl, 250);
      expect(extra.portion, '1.25 \u00d7 (200 ml)');
      expect(extra.barcode, item.barcode);
      expect(extra.provenance, 'label');
      expect(extra.baseNutrition!.kcal, 60);
      extra.baseNutrition!.kcal = 999;
      expect(item.baseNutrition!.kcal, 60);
      expect(item.computedNutrition!.kcal, 120);
      expect(item.consumedMl, 200);
      expect(slot.totalCalories, 120);
    },
  );

  test('legacy planned macros stay unknown instead of becoming intake', () {
    final item = milk()
      ..provenance = 'expert_plan'
      ..macrosKnown = null;
    final slot = MealSlotLog(items: [item], confidence: 'planned');
    final extra = MealServing.repeat(slot, item, 0.5);
    expect(extra.computedNutrition!.kcal, 60);
    expect(extra.macrosKnown, isFalse);
    expect(extra.computedNutrition!.proteinG, 0);
    expect(extra.computedNutrition!.carbsG, 0);
    expect(extra.computedNutrition!.fatG, 0);
    expect(extra.provenance, 'expert_plan');
  });

  test('explicitly known plan food macros remain usable', () {
    final item = milk()
      ..provenance = 'expert_plan'
      ..macrosKnown = true;
    final extra = MealServing.repeat(
      MealSlotLog(confidence: 'planned'),
      item,
      2,
    );
    expect(extra.hasKnownMacros, isTrue);
    expect(extra.computedNutrition!.proteinG, 12);
  });

  test(
    'unresolved foods and invalid or overflowing quantities cannot repeat',
    () {
      final item = milk();
      final slot = MealSlotLog(items: [item]);
      expect(
        MealServing.canRepeat(slot, MealItemLog(name: 'Photo only')),
        isFalse,
      );
      expect(
        MealServing.canRepeat(slot, item.copy()..resolved = false),
        isFalse,
      );
      for (final amount in [
        0.0,
        -1.0,
        double.nan,
        double.infinity,
        1e17,
        1e308,
      ]) {
        expect(
          () => MealServing.repeat(slot, item, amount),
          throwsFormatException,
        );
      }
      item.computedNutrition!.kcal = double.nan;
      expect(MealServing.canRepeat(slot, item), isFalse);
    },
  );

  test(
    'gram and serving metadata scale while base reference stays unchanged',
    () {
      final item = milk()
        ..consumedMl = null
        ..consumedGrams = 80
        ..consumedServings = 2
        ..servingGrams = 40
        ..portion = '2 idlis';
      final extra = MealServing.repeat(MealSlotLog(), item, 0.5);
      expect(extra.consumedGrams, 40);
      expect(extra.consumedServings, 1);
      expect(extra.servingGrams, 40);
      expect(extra.portion, '0.5 \u00d7 (2 idlis)');
    },
  );
  test('finite portions exceeding the manual calorie ceiling are rejected', () {
    final item = milk();
    expect(
      () => MealServing.repeat(MealSlotLog(), item, 100),
      throwsFormatException,
    );
  });
  test('unassigned legacy subtotals are not offered as repeatable foods', () {
    final subtotal = milk()
      ..name = 'Previously saved totals'
      ..provenance = 'saved_total';
    expect(MealServing.canRepeat(MealSlotLog(), subtotal), isFalse);
  });
}
