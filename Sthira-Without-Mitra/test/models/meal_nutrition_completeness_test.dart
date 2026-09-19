import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/food_nutrition.dart';
import 'package:trufit_bodamma/models/meal_plan.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/screens/progress/progress_screen.dart';
import 'package:trufit_bodamma/services/progress_aggregation_service.dart';
import 'package:trufit_bodamma/services/progress_insight_service.dart';
import 'package:trufit_bodamma/utils/meal_plan_complete.dart';
import 'package:trufit_bodamma/utils/meal_completion.dart';

MealSlotLog _log(Meal meal, UserProfile profile) =>
    MealPlanComplete.buildSlotLog(
      planned: meal,
      slotName: 'Lunch',
      slotEmoji: 'lunch',
      profile: profile,
    );

void main() {
  for (final usePhotoList in [false, true]) {
    test(
      'photo-only ${usePhotoList ? 'multi-photo' : 'legacy'} log stays recorded but nutrition is unknown',
      () {
        final day = DailyMealLog.fromJson({
          'date': '2026-09-14',
          'customSlots': {
            'lunch': {
              if (usePhotoList)
                'photoPaths': ['saved-meal.jpg']
              else
                'photoPath': 'saved-meal.jpg',
            },
          },
        });
        final slot = day.customSlots['lunch']!;
        expect(slot.isLogged, isTrue);
        expect(day.loggedSlotsCount, 1);
        expect(slot.hasCompleteCalories, isFalse);
        expect(slot.hasCompleteMacros, isFalse);
        expect(day.hasCompleteCalories, isFalse);
        expect(day.hasCompleteMacros, isFalse);
        expect(slot.totalCalories, 0);
        final restored = DailyMealLog.fromJson(day.toJson());
        expect(restored.hasCompleteCalories, isFalse);
        expect(restored.hasCompleteMacros, isFalse);
        expect(restored.customSlots['lunch']!.caloriesComplete, isNull);
        expect(
          MealCompletion.calculateTotalMeals(
            UserProfile(customMealSlots: const []),
            day,
          ),
          1,
        );
      },
    );
  }

  test(
    'explicitly measured photo zero remains complete and metric flags stay independent',
    () {
      final calorieOnlyZero = MealSlotLog(
        photoPath: 'water.jpg',
        caloriesComplete: true,
      );
      expect(calorieOnlyZero.hasCompleteCalories, isTrue);
      expect(calorieOnlyZero.hasCompleteMacros, isFalse);
      final knownZero = MealSlotLog.fromJson({
        'photoPath': 'water.jpg',
        'totalCalories': 0,
        'caloriesComplete': true,
        'macrosComplete': true,
      });
      expect(knownZero.hasCompleteCalories, isTrue);
      expect(knownZero.hasCompleteMacros, isTrue);
      expect(knownZero.totalCalories, 0);
    },
  );

  test(
    'empty slots and saved nonzero legacy aggregates retain their earlier meaning',
    () {
      final empty = MealSlotLog();
      expect(empty.isLogged, isFalse);
      expect(empty.hasCompleteCalories, isTrue);
      expect(empty.hasCompleteMacros, isTrue);
      final aggregate = MealSlotLog(
        photoPath: 'older-meal.jpg',
        totalCalories: 400,
        totalProtein: 20,
        totalCarbs: 50,
        totalFat: 10,
      );
      expect(aggregate.hasCompleteCalories, isTrue);
      expect(aggregate.hasCompleteMacros, isTrue);
      expect(aggregate.knownProtein, 20);
    },
  );

  for (final metric in [MetricType.calories, MetricType.protein]) {
    test(
      'photo-only unknown ${metric.name} is excluded while explicitly recorded zero is plotted',
      () {
        final start = DateTime(2026, 9, 14);
        final buckets = ProgressAggregationService.aggregate(
          logs: [],
          mealLogs: [
            DailyMealLog(
              date: '2026-09-14',
              customSlots: {
                'lunch': MealSlotLog(photoPaths: ['meal.jpg']),
              },
            ),
            DailyMealLog(
              date: '2026-09-15',
              customSlots: {
                'lunch': MealSlotLog(
                  photoPath: 'known-zero.jpg',
                  caloriesComplete: true,
                  macrosComplete: true,
                ),
              },
            ),
          ],
          metric: metric,
          range: TimeRange.weekly,
          rangeStart: start,
          rangeEnd: DateTime(2026, 9, 15),
          today: DateTime(2026, 9, 16),
          heightInMeters: 1.7,
          useKg: true,
        );
        expect(buckets.first.average, isNull);
        expect(buckets.first.incompleteDaysCount, 1);
        expect(buckets.last.average, 0);
        expect(buckets.last.incompleteDaysCount, 0);
      },
    );
  }

  test('actual item nutrition and portion survive import and round trip', () {
    final item = MealItem.fromJson({
      'name': 'Example food',
      'portion': '150 g',
      'calories': 210,
      'proteinG': 12,
      'carbsG': 25.5,
      'fatG': 6.0,
    });
    final restored = MealItem.fromJson(item.toJson());
    expect(restored.quantity, '150 g');
    expect(restored.proteinG, 12);
    expect(restored.carbsG, 25.5);
    expect(restored.fatG, 6);
    expect(restored.hasCompleteMacros, isTrue);
  });

  test('goals never change nutrition for the identical planned food', () {
    final meal = Meal(
      name: 'Example',
      type: 'lunch',
      calories: 210,
      items: [
        MealItem(
          name: 'Example food',
          quantity: '150 g',
          calories: 210,
          proteinG: 12,
          carbsG: 25.5,
          fatG: 6,
        ),
      ],
    );
    final first = _log(
      meal,
      UserProfile(targetCalories: 1250, targetProteinG: 85),
    );
    final second = _log(
      meal,
      UserProfile(targetCalories: 2500, targetProteinG: 150),
    );
    expect(first.totalProtein, 12);
    expect(second.totalProtein, first.totalProtein);
    expect(second.totalCarbs, first.totalCarbs);
    expect(second.totalFat, first.totalFat);
    expect(first.hasCompleteMacros, isTrue);
    expect(first.items.single.provenance, 'meal_plan');
  });

  test('calorie-only food remains explicitly macro-incomplete', () {
    final slot = _log(
      Meal(
        name: 'Example',
        type: 'lunch',
        calories: 200,
        items: [
          MealItem(name: 'Example food', quantity: '100 g', calories: 200),
        ],
      ),
      UserProfile(),
    );
    final restored = MealSlotLog.fromJson(slot.toJson());
    expect(restored.hasCompleteCalories, isTrue);
    expect(restored.hasCompleteMacros, isFalse);
    expect(restored.items.single.macrosKnown, isFalse);
    expect(restored.knownProtein, 0);
  });

  test('historical goal-derived macros remain stored but are not intake', () {
    final slot = MealSlotLog.fromJson({
      'confidence': 'planned',
      'totalCalories': 400,
      'totalProtein': 27.2,
      'totalCarbs': 43.2,
      'totalFat': 12.8,
      'items': [
        {
          'name': 'Old plan food',
          'portion': '1 bowl',
          'computedNutrition': {
            'kcal': 400,
            'protein_g': 27.2,
            'carbs_g': 43.2,
            'fat_g': 12.8,
          },
        },
      ],
    });
    final log = DailyMealLog(date: '2026-09-14', customSlots: {'lunch': slot});
    expect(slot.totalProtein, 27.2);
    expect(slot.toJson()['totalProtein'], 27.2);
    expect(log.totalProtein, 0);
    expect(log.hasCompleteMacros, isFalse);
  });

  test(
    'legacy aggregate totals are not lost when item detail is incomplete',
    () {
      final slot = MealSlotLog(
        totalCalories: 400,
        totalProtein: 20,
        totalCarbs: 50,
        totalFat: 10,
        items: [MealItemLog(name: 'Old food', resolved: false)],
      );
      expect(slot.knownProtein, 20);
      expect(slot.hasCompleteMacros, isFalse);
    },
  );

  test('complete zero macros are distinct from missing macros', () {
    final slot = _log(
      Meal(
        name: 'Water',
        type: 'snack',
        calories: 0,
        items: [
          MealItem(
            name: 'Water',
            quantity: '250 ml',
            calories: 0,
            proteinG: 0,
            carbsG: 0,
            fatG: 0,
          ),
        ],
      ),
      UserProfile(),
    );
    expect(slot.hasCompleteMacros, isTrue);
    expect(slot.knownProtein, 0);
  });

  test(
    'actual bundled seed requires food choices rather than fabricated logs',
    () {
      final plan = MealPlan.fromJson(
        jsonDecode(File('assets/data/seed_meal_plan.json').readAsStringSync())
            as Map<String, dynamic>,
      );
      expect(plan.meals, hasLength(4));
      for (final meal in plan.meals) {
        expect(meal.items.any((item) => item.needsFoodOrPortionChoice), isTrue);
        expect(() => _log(meal, UserProfile()), throwsFormatException);
      }
    },
  );

  test(
    'range quantities and combined alternatives require an actual choice',
    () {
      for (final item in [
        MealItem(name: 'Rice or roti', quantity: '1 bowl'),
        MealItem(name: 'Rice', quantity: '100-120 g'),
        MealItem(name: 'Roti', quantity: '1 to 2'),
        MealItem(name: 'Nuts', quantity: 'Handful'),
      ]) {
        expect(item.needsFoodOrPortionChoice, isTrue);
      }
      expect(
        MealItem(name: 'Rice', quantity: '120 g').needsFoodOrPortionChoice,
        isFalse,
      );
    },
  );

  test('non-finite and negative imported macros are rejected', () {
    for (final value in [-1, double.nan, double.infinity]) {
      expect(
        () => MealItem.fromJson({
          'name': 'Example',
          'quantity': '100 g',
          'calories': 100,
          'proteinG': value,
        }),
        throwsFormatException,
      );
    }
  });

  test('protein chart excludes incomplete days instead of plotting zero', () {
    final start = DateTime(2026, 9, 14);
    final logs = [
      DailyMealLog(
        date: '2026-09-14',
        customSlots: {
          'lunch': MealSlotLog(
            totalCalories: 400,
            totalProtein: 90,
            confidence: 'planned',
          ),
        },
      ),
      DailyMealLog(
        date: '2026-09-15',
        customSlots: {
          'lunch': MealSlotLog(
            totalCalories: 300,
            totalProtein: 0,
            macrosComplete: true,
          ),
        },
      ),
    ];
    final buckets = ProgressAggregationService.aggregate(
      logs: [],
      mealLogs: logs,
      metric: MetricType.protein,
      range: TimeRange.weekly,
      rangeStart: start,
      rangeEnd: DateTime(2026, 9, 15),
      today: DateTime(2026, 9, 16),
      heightInMeters: 1.7,
      useKg: true,
    );
    expect(buckets.first.average, isNull);
    expect(buckets.first.incompleteDaysCount, 1);
    expect(buckets.last.average, 0);
    final insight = ProgressInsightService.buildInsight(
      metric: MetricType.protein,
      range: TimeRange.weekly,
      currentBuckets: buckets,
      previousBuckets: [],
      useKg: true,
    );
    expect(insight.coverageText, contains('1 day excluded: macros incomplete'));
  });

  test('unresolved food keeps calorie comparisons incomplete too', () {
    final day = DateTime(2026, 9, 14);
    final buckets = ProgressAggregationService.aggregate(
      logs: [],
      mealLogs: [
        DailyMealLog(
          date: '2026-09-14',
          customSlots: {
            'lunch': MealSlotLog(
              totalCalories: 100,
              items: [
                MealItemLog(
                  name: 'Known',
                  computedNutrition: FoodNutrition(kcal: 100),
                ),
                MealItemLog(name: 'Unknown', resolved: false),
              ],
            ),
          },
        ),
      ],
      metric: MetricType.calories,
      range: TimeRange.weekly,
      rangeStart: day,
      rangeEnd: day,
      today: day,
      heightInMeters: 1.7,
      useKg: true,
    );
    expect(buckets.single.average, isNull);
    expect(buckets.single.incompleteDaysCount, 1);
  });
}
