import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/workout_plan.dart';
import 'package:trufit_bodamma/utils/workout_completion.dart';

void main() {
  final trainingDay = WorkoutDay(
    dayId: 'monday',
    label: 'Monday',
    sections: [
      WorkoutSection(
        title: 'Main',
        exercises: [
          Exercise(name: 'Bench Press', reps: ['10'])..instanceId = 'bench_1',
          Exercise(name: 'Squat', reps: ['10'])..instanceId = 'squat_1',
        ],
      ),
    ],
  );

  final restDay = WorkoutDay(dayId: 'Rest', label: 'Sunday', sections: []);

  final monday = DateTime(2023, 10, 2); // Monday
  final sunday = DateTime(2023, 10, 1); // Sunday

  test('isRestDay is true for empty sections only', () {
    expect(WorkoutCompletion.isRestDay(trainingDay, sunday), isFalse);
    expect(WorkoutCompletion.isRestDay(restDay, monday), isTrue);
    expect(WorkoutCompletion.isRestDay(trainingDay, monday), isFalse);
  });

  test('training day incomplete / complete via logs', () {
    final logged = <String>{};

    bool hasLog(String date, String name) => logged.contains('$date|$name');

    expect(
      WorkoutCompletion.isTrainingDayComplete(
        '2023-10-02',
        trainingDay,
        hasLog,
      ),
      isFalse,
    );
    expect(
      WorkoutCompletion.isDayWorkoutDone(
        date: '2023-10-02',
        day: trainingDay,
        dateTime: monday,
        hasLog: hasLog,
        dailyLog: DailyLog(date: '2023-10-02'),
      ),
      isFalse,
    );

    logged.add('2023-10-02|bench_1');
    expect(
      WorkoutCompletion.isTrainingDayComplete(
        '2023-10-02',
        trainingDay,
        hasLog,
      ),
      isFalse,
    );

    logged.add('2023-10-02|squat_1');
    expect(
      WorkoutCompletion.isTrainingDayComplete(
        '2023-10-02',
        trainingDay,
        hasLog,
      ),
      isTrue,
    );
    expect(
      WorkoutCompletion.isDayWorkoutDone(
        date: '2023-10-02',
        day: trainingDay,
        dateTime: monday,
        hasLog: hasLog,
        dailyLog: DailyLog(date: '2023-10-02'),
      ),
      isTrue,
    );
  });

  test(
    'Finish-early / skip via DailyLog.workoutCompleted counts as day done',
    () {
      bool hasLog(String date, String name) => false;

      expect(
        WorkoutCompletion.isDayWorkoutDone(
          date: '2023-10-02',
          day: trainingDay,
          dateTime: monday,
          hasLog: hasLog,
          dailyLog: DailyLog(date: '2023-10-02', workoutStatus: 'completed'),
        ),
        isTrue,
      );
    },
  );

  test('rest day scores as done', () {
    bool hasLog(String date, String name) => false;

    expect(
      WorkoutCompletion.isDayWorkoutDone(
        date: '2023-10-01',
        day: restDay,
        dateTime: sunday,
        hasLog: hasLog,
        dailyLog: DailyLog(date: '2023-10-01'),
      ),
      isTrue,
    );
  });

  test('resolveWorkoutDay maps weekday to plan day', () {
    final plan = WorkoutPlan(
      planName: 'Test',
      days: [
        WorkoutDay(dayId: 'monday', sections: trainingDay.sections),
        WorkoutDay(dayId: 'tuesday', sections: trainingDay.sections),
        WorkoutDay(dayId: 'wednesday', sections: trainingDay.sections),
        WorkoutDay(dayId: 'thursday', sections: trainingDay.sections),
        WorkoutDay(dayId: 'friday', sections: trainingDay.sections),
        WorkoutDay(dayId: 'saturday', sections: trainingDay.sections),
        restDay,
      ],
    );

    expect(WorkoutCompletion.resolveWorkoutDay(plan, monday).dayId, 'monday');
    expect(
      WorkoutCompletion.isRestDay(
        WorkoutCompletion.resolveWorkoutDay(plan, sunday),
        sunday,
      ),
      isTrue,
    );
  });

  test('resolveWorkoutDay respects currentWeek and weeks array', () {
    final w1d1 = WorkoutDay(dayId: 'monday', label: 'w1_d1', sections: trainingDay.sections);
    final w2d1 = WorkoutDay(dayId: 'monday', label: 'w2_d1', sections: trainingDay.sections);
    
    final planWithWeeks = WorkoutPlan(
      planName: 'Periodized Plan',
      durationWeeks: 2,
      weeks: [
        WorkoutWeek(weekNumber: 1, days: [w1d1, restDay, restDay, restDay, restDay, restDay, restDay]),
        WorkoutWeek(weekNumber: 2, days: [w2d1, restDay, restDay, restDay, restDay, restDay, restDay]),
      ],
      days: [], // unused when weeks is present
    );

    // Monday (day index 0)
    expect(WorkoutCompletion.resolveWorkoutDay(planWithWeeks, monday, currentWeek: 1).label, 'w1_d1');
    expect(WorkoutCompletion.resolveWorkoutDay(planWithWeeks, monday, currentWeek: 2).label, 'w2_d1');
    
    // Out of bounds defaults to last week
    expect(WorkoutCompletion.resolveWorkoutDay(planWithWeeks, monday, currentWeek: 3).label, 'w2_d1');
    expect(WorkoutCompletion.resolveWorkoutDay(planWithWeeks, monday, currentWeek: 5).label, 'w2_d1');
  });
}
