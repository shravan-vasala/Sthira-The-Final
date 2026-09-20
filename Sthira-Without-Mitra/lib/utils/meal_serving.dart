import '../models/daily_meal_log.dart';
import '../models/food_nutrition.dart';

/// Reuses the recorded nutrition for an extra portion, never the meal plan.
class MealServing {
  static bool canRepeat(MealSlotLog slot, MealItemLog item) {
    final nutrition = item.computedNutrition;
    if (!item.resolved ||
        nutrition == null ||
        item.provenance == 'saved_total') {
      return false;
    }
    final values = [
      nutrition.kcal,
      if (slot.hasKnownMacrosFor(item)) ...[
        nutrition.proteinG,
        nutrition.carbsG,
        nutrition.fatG,
      ],
    ];
    return values.every((value) => value.isFinite && value >= 0);
  }

  static String number(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();

  static MealItemLog repeat(
    MealSlotLog slot,
    MealItemLog item,
    double multiplier,
  ) {
    if (!multiplier.isFinite ||
        multiplier <= 0 ||
        multiplier > 100 ||
        !canRepeat(slot, item)) {
      throw const FormatException('Choose a valid food and extra amount.');
    }
    final original = item.computedNutrition!;
    final knownMacros = slot.hasKnownMacrosFor(item);
    final nutrition = FoodNutrition(
      kcal: original.kcal * multiplier,
      proteinG: knownMacros ? original.proteinG * multiplier : 0,
      carbsG: knownMacros ? original.carbsG * multiplier : 0,
      fatG: knownMacros ? original.fatG * multiplier : 0,
    );
    if ([
      nutrition.kcal,
      nutrition.proteinG,
      nutrition.carbsG,
      nutrition.fatG,
    ].any((value) => !value.isFinite)) {
      throw const FormatException('Choose a smaller amount.');
    }
    // Match the existing manual meal-entry limit before converting kcal to int.
    if (nutrition.kcal > 9999) {
      throw const FormatException('Choose a smaller amount.');
    }
    double? scaleQuantity(double? value) {
      if (value == null || !value.isFinite || value < 0) return null;
      final scaled = value * multiplier;
      if (!scaled.isFinite) {
        throw const FormatException('Choose a smaller amount.');
      }
      return scaled;
    }

    final portion = item.portion?.trim();
    final originalPortion = portion == null || portion.isEmpty
        ? 'logged portion'
        : portion;
    return item.copy()
      ..computedNutrition = nutrition
      ..macrosKnown = knownMacros
      ..portion = multiplier == 1
          ? originalPortion
          : '${number(multiplier)} \u00d7 ($originalPortion)'
      ..consumedGrams = scaleQuantity(item.consumedGrams)
      ..consumedMl = scaleQuantity(item.consumedMl)
      ..consumedServings = scaleQuantity(item.consumedServings);
  }
}
