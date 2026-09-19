import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/workout_plan.dart';
import 'package:trufit_bodamma/models/meal_plan.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/habit.dart';

void main() {
  group('WorkoutPlan', () {
    test('fromJson parses correctly', () {
      final json = {
        'planName': 'Test Plan',
        'days': [
          {
            'dayId': 'day1',
            'sections': [
              {
                'title': 'Warm Up',
                'exercises': [
                  {
                    'name': 'Jumping Jacks',
                    'youtubeUrl': 'https://youtu.be/test123',
                    'reps': [30],
                    'note': '',
                    'sideInfo': 'None',
                    'restSecondsAfterSet': 0,
                  },
                ],
              },
            ],
          },
        ],
      };

      final plan = WorkoutPlan.fromJson(json);
      expect(plan.planName, 'Test Plan');
      expect(plan.days.length, 1);
      expect(plan.days[0].dayId, 'day1');
      expect(plan.days[0].sections[0].exercises[0].name, 'Jumping Jacks');
    });

    test('Exercise YouTube ID extraction', () {
      final exercise = Exercise(
        name: 'Test',
        youtubeUrl: 'https://youtu.be/test123',
        reps: ['10'],
      );
      expect(exercise.youtubeVideoId, 'test123');

      final exercise2 = Exercise(
        name: 'Test',
        youtubeUrl: 'https://www.youtube.com/watch?v=abc456',
        reps: ['10'],
      );
      expect(exercise2.youtubeVideoId, 'abc456');
    });
  });

  group('MealPlan', () {
    test('calorie computation', () {
      final plan = MealPlan(
        planName: 'Test',
        meals: [
          Meal(
            name: 'B',
            type: 'breakfast',
            items: [],
            calories: 300,
            isCompleted: true,
          ),
          Meal(
            name: 'L',
            type: 'lunch',
            items: [],
            calories: 500,
            isCompleted: false,
          ),
        ],
        totalCalories: 800,
      );

      expect(plan.completedMeals, 1);
      expect(plan.completedCalories, 300);
    });
  });

  group('DailyLog', () {
    test('hasAnyActivity', () {
      final empty = DailyLog(date: '2026-07-21');
      expect(empty.hasAnyActivity, false);

      final withWeight = DailyLog(date: '2026-07-21', weight: 65.0);
      expect(withWeight.hasAnyActivity, true);
    });
  });

  group('Habit', () {
    test('defaults', () {
      expect(Habit.defaults.length, 3);
      expect(Habit.defaults[0].id, 'sleep');
      expect(Habit.defaults[1].id, 'walk');
      expect(Habit.defaults[2].id, 'water');
    });
  });
}
