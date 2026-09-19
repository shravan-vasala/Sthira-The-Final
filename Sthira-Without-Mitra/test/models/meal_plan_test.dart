import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/meal_plan.dart';

void main() {
  group('MealPlan AI JSON Parsing', () {
    test('parses full meal plan correctly', () {
      final json = {
        "planName": "High Protein Day",
        "totalCalories": 2000,
        "meals": [
          {
            "name": "Breakfast",
            "type": "breakfast",
            "calories": 500,
            "isCompleted": true,
            "suggestions": ["Oats", "Protein Shake"],
            "items": [
              {
                "name": "Oatmeal",
                "portion": "1 bowl",
                "calories": 300,
                "proteinG": 10.0,
                "carbsG": 50.0,
                "fatG": 5.0,
              },
            ],
          },
        ],
      };

      final plan = MealPlan.fromJson(json);

      expect(plan.planName, "High Protein Day");
      expect(plan.totalCalories, 2000);
      expect(plan.meals.length, 1);

      final meal = plan.meals.first;
      expect(meal.name, "Breakfast");
      expect(meal.type, "breakfast");
      expect(meal.calories, 500);
      expect(meal.isCompleted, true);
      expect(meal.suggestions, ["Oats", "Protein Shake"]);
      expect(meal.items.length, 1);

      final item = meal.items.first;
      expect(item.name, "Oatmeal");
    });

    test('handles missing optional fields gracefully', () {
      final json = {
        "planName": "Minimal Plan",
        "meals": [
          {"name": "Lunch", "type": "lunch", "calories": 600},
        ],
      };

      final plan = MealPlan.fromJson(json);

      expect(plan.planName, "Minimal Plan");
      expect(plan.totalCalories, 600); // auto-calculated from meals
      expect(plan.meals.length, 1);

      final meal = plan.meals.first;
      expect(meal.isCompleted, false); // defaults to false
      expect(meal.suggestions, isEmpty); // defaults to empty
      expect(meal.items, isEmpty); // defaults to empty
    });
  });
}
