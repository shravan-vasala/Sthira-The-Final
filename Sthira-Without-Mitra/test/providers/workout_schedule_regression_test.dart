import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/daily_stats_snapshot.dart';
import 'package:trufit_bodamma/models/habit.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/models/workout_plan.dart';
import 'package:trufit_bodamma/providers/phase_progress_provider.dart';
import 'package:trufit_bodamma/repositories/daily_log_repository.dart';
import 'package:trufit_bodamma/utils/workout_completion.dart';

class _EmptyLogs extends DailyLogRepository {
  @override
  DailyLog? getLog(String date) => null;
}

WorkoutDay _training(String weekday, String instance) => WorkoutDay(
  dayId: weekday,
  label: instance,
  sections: [
    WorkoutSection(
      title: 'Strength',
      exercises: [
        Exercise(name: 'Squat', reps: ['8'])..instanceId = instance,
      ],
    ),
  ],
);

WorkoutPlan _program() => WorkoutPlan(
  planName: 'Two weeks',
  days: [],
  weeks: [
    WorkoutWeek(weekNumber: 1, days: [_training('monday', 'week1')]),
    WorkoutWeek(weekNumber: 2, days: [_training('monday', 'week2')]),
  ],
);

void main() {
  final start = DateTime(2026, 9, 7);

  test(
    'weeks-only programs resolve the selected date and retain historical week',
    () {
      final plan = _program();
      expect(WorkoutCompletion.hasSchedule(plan), isTrue);
      expect(
        WorkoutCompletion.resolveWorkoutDay(
          plan,
          DateTime(2026, 9, 14),
          planStartDate: start,
        ).label,
        'week2',
      );
      expect(
        WorkoutCompletion.resolveWorkoutDay(
          plan,
          start,
          planStartDate: start,
        ).label,
        'week1',
      );
      expect(
        WorkoutCompletion.resolveWorkoutDay(
          plan,
          DateTime(2026, 9, 28),
          planStartDate: start,
        ).label,
        'week2',
      );
    },
  );

  test(
    'week changes on the seventh calendar day regardless of stored time',
    () {
      final plan = _program();
      final lateStart = DateTime(2026, 9, 7, 23, 59);
      expect(
        WorkoutCompletion.currentWeekForDate(
          plan,
          DateTime(2026, 9, 13, 23),
          planStartDate: lateStart,
        ),
        1,
      );
      expect(
        WorkoutCompletion.currentWeekForDate(
          plan,
          DateTime(2026, 9, 14),
          planStartDate: lateStart,
        ),
        2,
      );
      expect(
        WorkoutCompletion.currentWeekForDate(
          plan,
          DateTime(2026, 9, 6),
          planStartDate: lateStart,
        ),
        1,
      );
    },
  );

  test('explicit week still supports previewing a different program week', () {
    expect(
      WorkoutCompletion.resolveWorkoutDay(
        _program(),
        start,
        planStartDate: start,
        currentWeek: 2,
      ).label,
      'week2',
    );
  });

  test(
    'score snapshot uses week two logs rather than same-name week one exercise',
    () {
      const date = '2026-09-14';
      final stats = DailyStatsSnapshot.compute(
        date: DateTime(2026, 9, 14),
        dateStr: date,
        habits: [],
        habitCompletions: HabitCompletion(date: date),
        dailyLog: DailyLog(date: date),
        workoutPlan: _program(),
        hasLog: (day, instance) => day == date && instance == 'week2',
        mealPlan: null,
        mealLog: DailyMealLog(date: date),
        targetWeight: 0,
        dailyLogRepo: _EmptyLogs(),
        profile: UserProfile(planStartDate: start),
      );
      expect(stats.isRestDay, isFalse);
      expect(stats.workoutsTotal, 1);
      expect(stats.workoutsDone, 1);
    },
  );

  test('duplicate exercise names need separate instance logs', () {
    final section = WorkoutSection(
      title: 'Strength',
      exercises: [
        Exercise(name: 'Squat')..instanceId = 'warmup',
        Exercise(name: 'Squat')..instanceId = 'working',
      ],
    );
    expect(
      WorkoutCompletion.isSectionComplete(
        '2026-09-14',
        section,
        (_, instance) => instance == 'warmup',
      ),
      isFalse,
    );
    expect(
      WorkoutCompletion.isSectionComplete(
        '2026-09-14',
        section,
        (_, instance) => {'warmup', 'working'}.contains(instance),
      ),
      isTrue,
    );
  });

  test('rest days do not satisfy the weekly training target', () {
    final progress = PhaseProgress.calculate(
      plan: _program(),
      planStartDate: start,
      date: DateTime(2026, 9, 13),
      today: DateTime(2026, 9, 13),
      getLog: (_) => null,
      hasLog: (_, __) => false,
    );
    expect(progress.requiredDaysPerWeek, 1);
    expect(progress.completedDaysThisWeek, 0);
    expect(progress.isWeekComplete, isFalse);
  });

  test(
    'phase progress uses week-specific instances and clamps future completions',
    () {
      final plan = _program();
      plan.weeks![1].days.add(_training('friday', 'week2_friday'));
      final progress = PhaseProgress.calculate(
        plan: plan,
        planStartDate: start,
        date: DateTime(2026, 9, 20),
        today: DateTime(2026, 9, 15),
        getLog: (_) => null,
        hasLog: (_, instance) => instance.startsWith('week2'),
      );
      expect(progress.currentWeek, 2);
      expect(progress.requiredDaysPerWeek, 2);
      expect(progress.completedDaysThisWeek, 1);
      expect(progress.isWeekComplete, isFalse);
    },
  );

  test('ended program retains its last actual training week', () {
    final progress = PhaseProgress.calculate(
      plan: _program(),
      planStartDate: start,
      date: DateTime(2026, 10, 1),
      today: DateTime(2026, 10, 1),
      getLog: (_) => null,
      hasLog: (date, instance) => date == '2026-09-14' && instance == 'week2',
    );
    expect(progress.currentWeek, 2);
    expect(progress.isPhaseComplete, isTrue);
    expect(progress.completedDaysThisWeek, 1);
  });

  test(
    'ordinary repeating plan does not become a one-week program after logging',
    () {
      final progress = PhaseProgress.calculate(
        plan: WorkoutPlan(
          planName: 'Ongoing',
          days: [_training('monday', 'main')],
        ),
        planStartDate: start,
        date: DateTime(2026, 10, 1),
        today: DateTime(2026, 10, 1),
        getLog: (_) => null,
        hasLog: (_, __) => false,
      );
      expect(progress.isPhaseActive, isFalse);
      expect(progress.isPhaseComplete, isFalse);
    },
  );
  test('browsing a future date does not announce that the plan has ended', () {
    final progress = PhaseProgress.calculate(
      plan: _program(),
      planStartDate: start,
      date: DateTime(2026, 10, 1),
      today: DateTime(2026, 9, 15),
      getLog: (_) => null,
      hasLog: (_, __) => false,
    );
    expect(progress.isPhaseComplete, isFalse);
  });
}
