import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/food_nutrition.dart';
import 'package:trufit_bodamma/models/meal_plan.dart';
import 'package:trufit_bodamma/repositories/meal_repository.dart';
import '../helpers/test_isar_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Isar isar;
  late MealRepository repo;
  setUp(() async {
    isar = await setUpTestIsar();
    repo = MealRepository();
    await repo.init(isar);
  });
  tearDown(() async {
    await repo.detachSync();
    await tearDownTestIsar(isar);
  });

  test(
    'actual meal nutrition and expert origin survive native persistence',
    () async {
      await repo.savePlanJson(
        'Custom',
        jsonEncode({
          'planName': 'Custom',
          'source': 'user',
          'basedOnPlanName': 'Meal Plan',
          'totalCalories': 250,
          'meals': [
            {
              'name': 'Lunch',
              'type': 'lunch',
              'calories': 250,
              'items': [
                {
                  'name': 'Example',
                  'portion': '100 g',
                  'calories': 250,
                  'proteinG': 20,
                  'carbsG': 30,
                  'fatG': 5,
                },
              ],
            },
          ],
        }),
      );
      final stored = isar.mealPlans
          .where()
          .planNameEqualTo('Custom')
          .findFirstSync()!;
      expect(stored.basedOnPlanName, 'Meal Plan');
      expect(stored.meals.single.items.single.quantity, '100 g');
      expect(stored.meals.single.items.single.proteinG, 20);
      expect(stored.meals.single.items.single.carbsG, 30);
      expect(stored.meals.single.items.single.fatG, 5);
    },
  );

  test(
    'overriding expert default becomes user-owned and survives seed refresh',
    () async {
      final seed = repo.getMealPlan('Meal Plan')!;
      final customized = seed.toJson();
      customized['totalCalories'] = 1800;
      await repo.savePlanJson('Meal Plan', jsonEncode(customized));
      await repo.init(isar);
      final stored = repo.getMealPlan('Meal Plan')!;
      expect(stored.totalCalories, 1800);
      expect(stored.source, 'user');
      expect(stored.basedOnPlanName, 'Meal Plan');
      expect(repo.getMealPlan('Meal Plan (Expert)')?.source, 'seed');
    },
  );

  test(
    'appending actual food does not legitimize old invented planned macros',
    () async {
      await repo.saveMealSlot(
        '2026-09-14',
        'lunch',
        MealSlotLog(
          confidence: 'planned',
          totalCalories: 400,
          totalProtein: 90,
          items: [
            MealItemLog(
              name: 'Old plan',
              computedNutrition: FoodNutrition(kcal: 400, proteinG: 90),
            ),
          ],
        ),
      );
      await repo.appendMealItem(
        '2026-09-14',
        'lunch',
        MealItemLog(
          name: 'Label food',
          portion: '100 g',
          provenance: 'label',
          computedNutrition: FoodNutrition(
            kcal: 120,
            proteinG: 6,
            carbsG: 10,
            fatG: 4,
          ),
        ),
      );
      final log = repo.getDailyLog('2026-09-14');
      expect(log.totalCalories, 520);
      expect(log.totalProtein, 6);
      expect(log.hasCompleteMacros, isFalse);
      expect(log.customSlots['lunch']!.macrosComplete, isFalse);
      final restored = DailyMealLog.fromJson(log.toJson());
      expect(restored.totalProtein, 6);
      expect(restored.hasCompleteMacros, isFalse);
    },
  );
}
