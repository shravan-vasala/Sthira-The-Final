import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/workout_plan.dart';

void main() {
  group('WorkoutPlan AI JSON Parsing', () {
    test('parses full workout plan correctly', () {
      final json = {
        "planName": "Push Pull Legs",
        "days": [
          {
            "dayId": "monday",
            "label": "Push Day",
            "sections": [
              {
                "title": "Warmup",
                "exercises": [
                  {
                    "name": "Pushups",
                    "reps": ["10", "10", "10"],
                    "note": "Slow and controlled",
                    "restSecondsAfterSet": 60,
                  },
                ],
              },
            ],
          },
        ],
      };

      final plan = WorkoutPlan.fromJson(json);

      expect(plan.planName, "Push Pull Legs");
      expect(plan.days.length, 1);

      final day = plan.days.first;
      expect(day.dayId, "monday");
      expect(day.label, "Push Day");
      expect(day.weekday, DateTime.monday);
      expect(day.sections.length, 1);

      final section = day.sections.first;
      expect(section.title, "Warmup");
      expect(section.exercises.length, 1);

      final exercise = section.exercises.first;
      expect(exercise.name, "Pushups");
      expect(exercise.reps, ["10", "10", "10"]);
      expect(exercise.note, "Slow and controlled");
      expect(exercise.restSecondsAfterSet, 60);
    });

    test('handles missing optional fields gracefully', () {
      final json = {
        "dayId": "tuesday",
        "sections": [
          {
            "title": "Main Lift",
            "exercises": [
              {
                "name": "Squat",
                "reps": ["5"],
              },
            ],
          },
        ],
      };

      final day = WorkoutDay.fromJson(json);

      expect(day.dayId, "tuesday");
      expect(day.label, isNull);

      final exercise = day.sections.first.exercises.first;
      expect(exercise.note, ""); // defaults to empty string
      expect(exercise.sideInfo, "None"); // defaults to 'None'
      expect(exercise.restSecondsAfterSet, 0); // defaults to 0
    });
  });
}
