import '../models/daily_meal_log.dart';
import '../models/food_nutrition.dart';
import '../models/meal_plan.dart';
import '../models/user_profile.dart';

/// Shared helpers for logging a meal slot from the seed / active meal plan.
class MealPlanComplete {
  MealPlanComplete._();

  static bool isSlotLogged(MealSlotLog? log) {
    if (log == null) return false;
    return log.items.isNotEmpty ||
        log.photoPath != null ||
        log.totalCalories > 0;
  }

  static bool isPlannedComplete(MealSlotLog? log) {
    return isSlotLogged(log) && log!.confidence == 'planned';
  }

  static Meal? plannedForSlot(MealPlan? plan, String slotId) {
    if (plan == null) return null;
    for (final m in plan.meals) {
      if (m.type == slotId) return m;
    }
    return null;
  }

  static MealSlotLog buildSlotLog({
    required Meal planned,
    required String slotName,
    required String slotEmoji,
    required UserProfile profile,
  }) {
    if (planned.items.any((item) => item.needsFoodOrPortionChoice)) {
      throw const FormatException(
        'Choose the foods and portions you actually ate before logging this template.',
      );
    }
    final items = planned.items.map((item) {
      final known = item.hasCompleteMacros;
      return MealItemLog(
        name: item.name,
        portion: item.quantity,
        resolved: item.calories != null,
        macrosKnown: known,
        provenance: 'meal_plan',
        computedNutrition: item.calories == null
            ? null
            : FoodNutrition(
                kcal: item.calories!.toDouble(),
                proteinG: item.proteinG ?? 0,
                carbsG: item.carbsG ?? 0,
                fatG: item.fatG ?? 0,
              ),
      );
    }).toList();
    final completeMacros =
        items.isNotEmpty && items.every((item) => item.hasKnownMacros);
    final protein = items
        .where((item) => item.hasKnownMacros)
        .fold(0.0, (sum, item) => sum + item.computedNutrition!.proteinG);
    final carbs = items
        .where((item) => item.hasKnownMacros)
        .fold(0.0, (sum, item) => sum + item.computedNutrition!.carbsG);
    final fat = items
        .where((item) => item.hasKnownMacros)
        .fold(0.0, (sum, item) => sum + item.computedNutrition!.fatG);

    return MealSlotLog(
      name: slotName,
      emoji: slotEmoji,
      items: items,
      totalCalories: planned.calories,
      totalProtein: protein,
      totalCarbs: carbs,
      totalFat: fat,
      confidence: 'planned',
      caloriesComplete: items.every((item) => item.resolved),
      macrosComplete: completeMacros,
    );
  }
}
