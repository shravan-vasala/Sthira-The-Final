import 'dart:convert';
import 'dart:io';
import 'package:trufit_bodamma/models/daily_stats_snapshot.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/habit.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/repositories/daily_log_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:trufit_bodamma/models/exercise_log.dart';
import 'package:trufit_bodamma/models/workout_plan.dart';
import 'package:trufit_bodamma/models/sync_queue_item.dart';
import 'package:trufit_bodamma/providers/phase_progress_provider.dart';
import 'package:trufit_bodamma/repositories/workout_repository.dart';
import 'package:trufit_bodamma/repositories/exercise_log_repository.dart';
import 'package:trufit_bodamma/utils/workout_completion.dart';
import 'package:trufit_bodamma/utils/exercise_log_save.dart';
import '../helpers/test_isar_setup.dart';

class _NoDailyLogs extends DailyLogRepository {
  @override
  DailyLog? getLog(String date) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Isar database;
  late WorkoutRepository workouts;
  late ExerciseLogRepository logs;
  late WorkoutPlan plan;
  List<Exercise> exercises(WorkoutPlan plan) => plan.days
      .expand((day) => day.sections.expand((section) => section.exercises))
      .toList();
  setUp(() async {
    database = await setUpTestIsar();
    workouts = WorkoutRepository();
    await workouts.init(database);
    logs = ExerciseLogRepository();
    await logs.init(database);
    plan = workouts.getActivePlan()!;
  });
  tearDown(() => tearDownTestIsar(database));

  test(
    'real seed occurrences have stable unique IDs through reload and migration',
    () async {
      final first = exercises(
        plan,
      ).map((exercise) => exercise.instanceId).toList();
      expect(first.length, 65);
      expect(first.toSet().length, 65);
      expect(first.any((id) => id == null || id.isEmpty), isFalse);
      final parsed = WorkoutPlan.fromJson(
        jsonDecode(
              File('assets/data/seed_workout_plan.json').readAsStringSync(),
            )
            as Map<String, dynamic>,
      );
      expect(exercises(parsed).map((exercise) => exercise.instanceId), first);
      for (final exercise in exercises(plan)) {
        exercise.instanceId = null;
      }
      await database.writeTxn(() async => database.workoutPlans.put(plan));
      await workouts.init(database);
      expect(
        exercises(
          workouts.getActivePlan()!,
        ).map((exercise) => exercise.instanceId),
        first,
      );
    },
  );

  test(
    'repeated Saturday names never share or overwrite occurrence logs',
    () async {
      final day = plan.days.firstWhere((day) => day.dayId == 'saturday');
      final burpees = day.sections
          .expand((section) => section.exercises)
          .where((exercise) => exercise.name == 'Modified Burpees')
          .toList();
      expect(burpees.length, 2);
      await logs.saveLog(
        ExerciseLog(
          date: '2026-09-19',
          instanceId: 'Modified Burpees',
          exerciseName: 'Modified Burpees',
          sets: [SetLog(reps: 6)],
        ),
      );
      expect(logs.hasLog('2026-09-19', burpees[0].instanceId!), isFalse);
      expect(logs.hasLog('2026-09-19', burpees[1].instanceId!), isFalse);
      await logs.saveLog(
        ExerciseLog(
          date: '2026-09-19',
          instanceId: burpees[0].instanceId!,
          exerciseName: 'Modified Burpees',
          sets: [SetLog(reps: 6)],
        ),
      );
      expect(logs.hasLog('2026-09-19', burpees[0].instanceId!), isTrue);
      expect(logs.hasLog('2026-09-19', burpees[1].instanceId!), isFalse);
      expect(logs.getLogsForExercise('Modified Burpees').length, 2);
    },
  );

  test(
    'unique legacy log stays available and edits migrate one row plus sync key',
    () async {
      final exercise = plan.days.first.sections.first.exercises.first;
      await logs.saveLog(
        ExerciseLog(
          date: '2026-09-14',
          instanceId: exercise.name!,
          exerciseName: exercise.name!,
          sets: [SetLog(reps: 20)],
        ),
      );
      expect(logs.hasLog('2026-09-14', exercise.instanceId!), isTrue);
      await logs.saveLog(
        ExerciseLog(
          date: '2026-09-14',
          instanceId: exercise.instanceId!,
          exerciseName: exercise.name!,
          sets: [SetLog(reps: 22)],
        ),
      );
      expect(logs.getLogsForDate('2026-09-14').length, 1);
      expect(logs.getLog('2026-09-14', exercise.name!), isNull);
      expect(
        logs.getLog('2026-09-14', exercise.instanceId!)!.sets.single.reps,
        22,
      );
      final queue = database.syncQueueItems.where().findAllSync();
      expect(
        queue.any(
          (item) =>
              item.collection == '_delete_/exercise_logs' &&
              item.docId == '2026-09-14_${exercise.name}',
        ),
        isTrue,
      );
    },
  );

  test('empty sections do not dilute recorded workout progress', () {
    final date = DateTime(2026, 9, 14);
    final custom = WorkoutPlan(
      planName: 'One section',
      days: [
        WorkoutDay(
          dayId: 'monday',
          sections: [
            WorkoutSection(
              title: 'Workout',
              exercises: [
                Exercise(name: 'Squat', reps: ['8']),
              ],
            ),
            WorkoutSection(title: 'Optional', exercises: []),
          ],
        ),
      ],
    )..ensureExerciseIds();
    final stats = DailyStatsSnapshot.compute(
      date: date,
      dateStr: '2026-09-14',
      habits: [],
      habitCompletions: HabitCompletion(date: '2026-09-14'),
      dailyLog: DailyLog(date: '2026-09-14'),
      workoutPlan: custom,
      hasLog: (_, __) => true,
      mealPlan: null,
      mealLog: DailyMealLog(date: '2026-09-14'),
      targetWeight: 60,
      dailyLogRepo: _NoDailyLogs(),
      profile: UserProfile(),
    );
    expect(stats.workoutsDone, 1);
    expect(stats.workoutsTotal, 1);
  });

  test('real Sunday is rest and weekly target excludes it', () {
    final sunday = WorkoutCompletion.resolveWorkoutDay(
      plan,
      DateTime(2026, 9, 20),
    );
    expect(WorkoutCompletion.isRestDay(sunday, DateTime(2026, 9, 20)), isTrue);
    final progress = PhaseProgress.calculate(
      plan: plan,
      planStartDate: DateTime(2026, 9, 14),
      date: DateTime(2026, 9, 19),
      today: DateTime(2026, 9, 19),
      getLog: (_) => null,
      hasLog: logs.hasLog,
    );
    expect(progress.requiredDaysPerWeek, 6);
    expect(progress.completedDaysThisWeek, 0);
  });

  test(
    'all real Monday prescriptions can complete with cooldown saved as time',
    () async {
      final day = plan.days.first;
      for (final exercise in day.sections.expand(
        (section) => section.exercises,
      )) {
        final times = plannedDurationTargets(exercise);
        final reps = plannedRepTargets(exercise);
        final sets = times.isNotEmpty
            ? [
                for (var i = 0; i < times.length; i++)
                  SetLog(
                    setNumber: i + 1,
                    durationSeconds: times[i],
                    weight: 0,
                  ),
              ]
            : [
                for (var i = 0; i < reps.length; i++)
                  SetLog(setNumber: i + 1, reps: reps[i], weight: 0),
              ];
        await logs.saveLog(
          ExerciseLog(
            date: '2026-09-14',
            instanceId: exercise.instanceId!,
            exerciseName: exercise.name!,
            sets: sets,
          ),
        );
      }
      expect(
        WorkoutCompletion.isTrainingDayCompleteWithRepo(
          '2026-09-14',
          day,
          logs,
        ),
        isTrue,
      );
      final cooldown = day.sections.last.exercises.single;
      final saved = logs.getLog('2026-09-14', cooldown.instanceId!)!;
      expect(saved.sets.single.durationSeconds, 20);
      expect(saved.sets.single.reps, isNull);
      expect(ExerciseLog.fromJson(saved.toJson()).totalDurationSeconds, 20);
      final exported = await database.exerciseLogs.where().exportJson();
      await database.writeTxn(() async {
        await database.exerciseLogs.clear();
        await database.exerciseLogs.importJson(exported);
      });
      expect(
        logs.getLog('2026-09-14', cooldown.instanceId!)!.totalDurationSeconds,
        20,
      );
    },
  );

  test(
    '8 and 10 week user overrides survive seed refresh and explicit weeks import',
    () async {
      for (final count in [8, 10]) {
        final json = plan.toJson()..['durationWeeks'] = count;
        await workouts.savePlanJson(plan.planName, jsonEncode(json));
        expect(workouts.getPlan(plan.planName)!.durationWeeks, count);
      }
      await workouts.init(database);
      final custom = workouts.getPlan(plan.planName)!;
      expect(custom.source, 'user');
      expect(custom.durationWeeks, 10);
      expect(custom.basedOnPlanName, plan.planName);
      expect(workouts.getPlan('${plan.planName} (Expert)')!.source, 'seed');
      final detailed = <String, dynamic>{
        'planName': 'Detailed 10 weeks',
        'weeks': [
          for (var i = 1; i <= 10; i++)
            {
              'weekNumber': i,
              'days': plan.days.map((day) => day.toJson()).toList(),
            },
        ],
      };
      await workouts.savePlanJson('Detailed 10 weeks', jsonEncode(detailed));
      expect(workouts.getPlan('Detailed 10 weeks')!.weeks!.length, 10);
      expect(
        WorkoutCompletion.totalWeeks(workouts.getPlan('Detailed 10 weeks')!),
        10,
      );
      expect(
        () => workouts.savePlanJson(
          'bad',
          jsonEncode({'planName': 'bad', 'durationWeeks': 0, 'days': []}),
        ),
        throwsFormatException,
      );
    },
  );
}
