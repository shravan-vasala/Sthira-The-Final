import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/providers/weekly_summary_provider.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/exercise_log.dart';
import 'package:trufit_bodamma/models/habit.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/models/workout_plan.dart';
import 'package:trufit_bodamma/repositories/daily_log_repository.dart';
import 'package:trufit_bodamma/repositories/exercise_log_repository.dart';
import 'package:trufit_bodamma/repositories/habit_repository.dart';

class _Logs extends DailyLogRepository {
  @override
  DailyLog? getLog(String date) => null;
}

class _Exercises extends ExerciseLogRepository {
  @override
  bool hasLog(String date, String name) => false;
  @override
  List<ExerciseLog> getLogsForDate(String date) => [];
}

class _Habits extends HabitRepository {
  _Habits(this.habits, this.completions);
  final List<Habit> habits;
  final Map<String, HabitCompletion> completions;
  @override
  List<Habit> getHabits() => habits;
  @override
  HabitCompletion getCompletions(String date) =>
      completions[date] ?? HabitCompletion(date: date);
}

class _Profile extends ProfileNotifier {
  _Profile(this.profile);
  final UserProfile profile;
  @override
  UserProfile build() => profile;
}

class _Completions extends HabitCompletionsNotifier {
  @override
  HabitCompletion build() => HabitCompletion(date: '2026-09-14');
}

final _monday = DateTime(2026, 9, 14);
DailyScore _score({
  List<Habit> habits = const [],
  WorkoutPlan? plan,
  UserProfile? profile,
  HabitCompletion? completions,
  DailyMealLog? meals,
  DailyLog? log,
  DateTime? now,
}) => DailyScore.calculate(
  date: _monday,
  dateStr: '2026-09-14',
  habits: habits,
  habitCompletions: completions ?? HabitCompletion(date: '2026-09-14'),
  dailyLog: log ?? DailyLog(date: '2026-09-14'),
  workoutPlan: plan,
  logRepo: _Exercises(),
  mealPlan: null,
  mealLog: meals ?? DailyMealLog(date: '2026-09-14'),
  targetWeight: 0,
  targetCalories: 1250,
  dailyLogRepo: _Logs(),
  profile: profile ?? UserProfile(),
  now: now ?? DateTime(2026, 9, 19, 12),
);

WeeklySummary _week({
  required List<DailyLog> logs,
  List<Habit> habits = const [],
  List<DailyMealLog> meals = const [],
  Map<String, HabitCompletion> completions = const {},
  WorkoutPlan? plan,
  DateTime? selected,
  DateTime? now,
  bool useKg = true,
}) {
  final container = ProviderContainer(
    overrides: [
      selectedDateProvider.overrideWith((ref) => selected ?? _monday),
      clockProvider.overrideWithValue(now ?? DateTime(2026, 9, 19, 12)),
      profileProvider.overrideWith(() => _Profile(UserProfile(useKg: useKg))),
      habitsProvider.overrideWithValue(habits),
      allHabitsProvider.overrideWithValue(habits),
      habitRepoProvider.overrideWithValue(_Habits(habits, completions)),
      habitCompletionsProvider.overrideWith(_Completions.new),
      workoutPlanProvider.overrideWithValue(plan),
      mealPlanProvider.overrideWithValue(null),
      exerciseLogRepoProvider.overrideWithValue(_Exercises()),
      dailyLogRepoProvider.overrideWithValue(_Logs()),
      dailyMealLogsUpdateProvider.overrideWith(
        (ref) => const Stream<void>.empty(),
      ),
      dailyLogsRangeProvider.overrideWith(
        (ref, range) => logs
            .where(
              (log) =>
                  log.date.compareTo(range.$1) >= 0 &&
                  log.date.compareTo(range.$2) <= 0,
            )
            .toList(),
      ),
      dailyMealLogsRangeProvider.overrideWith(
        (ref, range) => meals
            .where(
              (log) =>
                  log.date.compareTo(range.$1) >= 0 &&
                  log.date.compareTo(range.$2) <= 0,
            )
            .toList(),
      ),
    ],
  );
  try {
    return container.read(weeklySummaryProvider);
  } finally {
    container.dispose();
  }
}

void main() {
  test('Incomplete calorie subtotals never earn daily accuracy points', () {
    final score = _score(
      profile: UserProfile(customMealSlots: []),
      meals: DailyMealLog(
        date: '2026-09-14',
        customSlots: {
          'lunch': MealSlotLog(totalCalories: 1250, caloriesComplete: false),
        },
      ),
    );
    expect(score.mealsScore, 14);
    expect(score.mealsMax, 20);
    expect(score.totalScore, 70);
    expect(score.isPrimaryComplete, isFalse);
  });

  test(
    'Known calories retain accuracy credit when only macros are unknown',
    () {
      final score = _score(
        profile: UserProfile(customMealSlots: []),
        meals: DailyMealLog(
          date: '2026-09-14',
          customSlots: {
            'lunch': MealSlotLog(
              totalCalories: 1250,
              caloriesComplete: true,
              macrosComplete: false,
            ),
          },
        ),
      );
      expect(score.mealsScore, 20);
      expect(score.totalScore, 100);
      expect(score.isPrimaryComplete, isTrue);
    },
  );

  test('Mood and reflection text never award or remove daily score points', () {
    final scores = [
      _score(),
      _score(
        log: DailyLog(date: '2026-09-14', dayFeeling: 'veryLow'),
      ),
      _score(
        log: DailyLog(
          date: '2026-09-14',
          dayFeeling: 'great',
          dayNote: 'A reflection',
        ),
      ),
    ];
    expect(scores.map((score) => score.totalScore).toSet(), {0});
    expect(scores.map((score) => score.totalMax).toSet(), {20.0});
  });

  test('No plan does not earn planned-rest workout points', () {
    final score = _score();
    expect(score.workoutsScore, 0);
    expect(score.workoutsMax, 0);
    expect(score.workoutConfigured, isFalse);
    expect(score.isRestDay, isFalse);
    expect(score.totalScore, 0);
  });
  test('An actual planned rest day keeps its existing workout credit', () {
    final score = _score(
      plan: WorkoutPlan(
        planName: 'Rest',
        days: [WorkoutDay(dayId: 'monday', label: 'Rest', sections: [])],
      ),
    );
    expect(score.workoutsScore, 30);
    expect(score.workoutConfigured, isTrue);
    expect(score.isRestDay, isTrue);
  });
  test('A plan stored in weeks is configured, not a missing plan', () {
    final score = _score(
      plan: WorkoutPlan(
        planName: 'Weekly',
        days: [],
        weeks: [
          WorkoutWeek(
            weekNumber: 1,
            days: [
              WorkoutDay(
                dayId: 'monday',
                label: 'Train',
                sections: [
                  WorkoutSection(
                    title: 'One',
                    exercises: [
                      Exercise(name: 'Walk', reps: ['10']),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
    expect(score.workoutConfigured, isTrue);
    expect(score.isRestDay, isFalse);
    expect(score.workoutsMax, 30);
  });

  test('Normalized score and empty-category completion are distinct', () {
    final empty = _score(profile: UserProfile(customMealSlots: []));
    expect(empty.totalMax, 0);
    expect(empty.isPrimaryComplete, isFalse);
    final habit = Habit(
      initialCreatedAt: DateTime(2020),
      id: 'h',
      name: 'Read',
      icon: 'check',
      target: 1,
    );
    final complete = _score(
      profile: UserProfile(customMealSlots: []),
      habits: [habit],
      completions: HabitCompletion(
        date: '2026-09-14',
        completions: {'h': true},
      ),
    );
    expect(complete.totalMax, 50);
    expect(complete.totalScore, 100);
    expect(complete.isPrimaryComplete, isTrue);
  });
  test('Scheduled habit only contributes on its own weekday', () {
    final score = _score(
      habits: [
        Habit(
          initialCreatedAt: DateTime(2020),
          id: 'h',
          name: 'Read',
          icon: 'check',
          target: 1,
          activeDays: [2],
        ),
      ],
    );
    expect(score.habitsMax, 0);
  });
  test('Today uses a normalized date and an injected clock', () {
    final today = _score(now: DateTime(2026, 9, 14, 12));
    expect(today.isToday, isTrue);
    expect(today.isFutureDate, isFalse);
    expect(_score(now: DateTime(2026, 9, 13, 12)).isFutureDate, isTrue);
  });
  test('Week averages retain recorded zero and disclose coverage', () {
    final result = _week(
      logs: [
        DailyLog(date: '2026-09-14', steps: 0, sleepHours: 0),
        DailyLog(date: '2026-09-15', steps: 10000, sleepHours: 8),
      ],
    );
    expect(result.avgSteps, 5000);
    expect(result.avgSleep, 4);
    expect(result.stepsDays, 2);
    expect(result.sleepNights, 2);
    expect(result.dailyScores[2], isNull);
    expect(result.isPartialWeek, isTrue);
    expect(result.previousWeekScore, isNull);
  });
  test('Future weeks are empty, not a failed zero-score week', () {
    final result = _week(logs: [], selected: DateTime(2026, 9, 21));
    expect(result.isFutureWeek, isTrue);
    expect(result.hasScoreData, isFalse);
    expect(result.elapsedDays, 0);
    expect(result.workoutsTotal, 0);
    expect(result.dailyScores.every((v) => v == null), isTrue);
    expect(result.previousWeekScore, isNull);
    expect(result.generateShareText(), contains('No scored days yet.'));
    expect(result.generateShareText(), contains('upcoming week'));
    expect(result.generateShareText(), isNot(contains('0/100')));
  });
  test('Week uses each day schedule and excludes future habits', () {
    final result = _week(
      logs: [],
      habits: [
        Habit(
          initialCreatedAt: DateTime(2020),
          id: 'h',
          name: 'Read',
          icon: 'check',
          target: 1,
          activeDays: [1, 7],
        ),
      ],
      completions: {
        '2026-09-14': HabitCompletion(
          date: '2026-09-14',
          completions: {'h': true},
        ),
      },
    );
    expect(result.dailyHabitsTotal, [1, 0, 0, 0, 0, 0, 0]);
    expect(result.habitCompletionRate, 1);
    expect(result.scoreDays, 1);
  });
  test('Workout sessions exclude planned rest and future training days', () {
    final plan = WorkoutPlan(
      planName: 'Mixed',
      days: [
        WorkoutDay(
          dayId: 'monday',
          label: 'Train',
          sections: [
            WorkoutSection(
              title: 'One',
              exercises: [
                Exercise(name: 'Walk', reps: ['10']),
              ],
            ),
            WorkoutSection(
              title: 'Two',
              exercises: [
                Exercise(name: 'Stretch', reps: ['10']),
              ],
            ),
          ],
        ),
        WorkoutDay(
          dayId: 'sunday',
          label: 'Train',
          sections: [
            WorkoutSection(
              title: 'One',
              exercises: [
                Exercise(name: 'Walk', reps: ['10']),
              ],
            ),
          ],
        ),
      ],
    );
    final result = _week(
      logs: [DailyLog(date: '2026-09-14', workoutStatus: 'completed')],
      plan: plan,
    );
    expect(result.workoutsTotal, 1);
    expect(result.workoutsCompleted, 1);
  });
  test('Weight difference follows the configured unit and needs coverage', () {
    final result = _week(
      logs: [
        DailyLog(date: '2026-09-14', weight: 80),
        DailyLog(date: '2026-09-15', weight: 79),
      ],
      useKg: false,
    );
    expect(result.weightDelta, closeTo(-2.20462, .0001));
    expect(result.weightMeasurements, 2);
    expect(result.useKg, isFalse);
  });
  test('Previous score stays absent when there is no previous evidence', () {
    final result = _week(
      now: DateTime(2026, 9, 28),
      logs: [
        DailyLog(date: '2026-09-14', steps: 1000),
        DailyLog(date: '2026-09-15', steps: 2000),
        DailyLog(date: '2026-09-16', steps: 3000),
      ],
    );
    expect(result.isPartialWeek, isFalse);
    expect(result.previousWeekScore, isNull);
  });

  test(
    'Habit creation date excludes earlier days but includes its whole local day',
    () {
      final habit = Habit(
        id: 'new',
        name: 'Read',
        icon: 'check',
        target: 1,
        initialCreatedAt: DateTime(2026, 9, 14, 23, 59),
      );
      expect(DailyScore.habitsForDate([habit], DateTime(2026, 9, 13)), isEmpty);
      expect(DailyScore.habitsForDate([habit], DateTime(2026, 9, 14)), [habit]);
      final week = _week(logs: [], habits: [habit], now: DateTime(2026, 9, 15));
      expect(week.dailyHabitsTotal, [1, 1, 0, 0, 0, 0, 0]);
      expect(week.recordedHabitInstances, 0);
    },
  );
  test(
    'Weekly habits distinguish no records from explicit not-done and completion',
    () {
      final habit = Habit(
        id: 'read',
        name: 'Read',
        icon: 'check',
        target: 1,
        initialCreatedAt: DateTime(2020),
      );
      final empty = _week(logs: [], habits: [habit]);
      expect(empty.scheduledHabitInstances, 6);
      expect(empty.hasHabitRecords, isFalse);
      expect(
        empty.generateShareText(),
        contains('Habits: no entries recorded'),
      );
      final recorded = _week(
        logs: [],
        habits: [habit],
        completions: {
          '2026-09-14': HabitCompletion(
            date: '2026-09-14',
            completions: {'read': false},
          ),
          '2026-09-15': HabitCompletion(
            date: '2026-09-15',
            completions: {'read': true},
          ),
        },
      );
      expect(recorded.dailyHabitsRecorded, [1, 1, 0, 0, 0, 0, 0]);
      expect(recorded.dailyHabitsCompleted, [0, 1, 0, 0, 0, 0, 0]);
      expect(recorded.recordedHabitInstances, 2);
      expect(
        recorded.generateShareText(),
        contains('1/6 completed; 2 recorded'),
      );
      expect(recorded.prevHabitCompletionRate, isNull);
    },
  );
  test(
    'Incomplete calories are excluded from weekly average and target counts',
    () {
      final result = _week(
        logs: [],
        meals: [
          DailyMealLog(
            date: '2026-09-14',
            customSlots: {'lunch': MealSlotLog(totalCalories: 1800)},
          ),
          DailyMealLog(
            date: '2026-09-15',
            customSlots: {
              'lunch': MealSlotLog(
                totalCalories: 3000,
                caloriesComplete: false,
              ),
            },
          ),
        ],
      );
      expect(result.avgCalories, 1800);
      expect(result.foodDays, 1);
      expect(result.incompleteFoodDays, 1);
      expect(result.daysOverCalories + result.daysUnderCalories, 1);
      expect(
        result.generateShareText(),
        contains('1 days with incomplete calories excluded'),
      );
    },
  );
  test(
    'Weeks-only schedules score previous and current weeks consistently',
    () {
      final plan = WorkoutPlan(
        planName: 'Rest weeks',
        days: [],
        weeks: [
          WorkoutWeek(
            weekNumber: 1,
            days: [WorkoutDay(dayId: 'monday', label: 'Rest', sections: [])],
          ),
        ],
      );
      final result = _week(
        now: DateTime(2026, 9, 28),
        plan: plan,
        logs: [
          for (final day in [7, 8, 9, 14, 15, 16])
            DailyLog(
              date: '2026-09-${day.toString().padLeft(2, '0')}',
              steps: 0,
            ),
        ],
      );
      expect(result.scoreDays, 7);
      expect(result.previousWeekScore, result.weekScore);
      expect(result.dailyScores.every((value) => value != null), isTrue);
      expect(result.workoutsTotal, 0);
    },
  );
}
