import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/exercise_log.dart';
import 'package:trufit_bodamma/models/habit.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/repositories/daily_log_repository.dart';
import 'package:trufit_bodamma/repositories/exercise_log_repository.dart';
import 'package:trufit_bodamma/repositories/habit_repository.dart';
import 'package:trufit_bodamma/repositories/meal_repository.dart';
import 'package:trufit_bodamma/screens/home/widgets/week_calendar_strip.dart';
import '../helpers/test_isar_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Isar database;
  late ProviderContainer container;
  final provider = calendarWeekActivityProvider('2026-09-14');
  setUp(() async {
    database = await setUpTestIsar();
    final logs = DailyLogRepository();
    final exercises = ExerciseLogRepository();
    final meals = MealRepository();
    final habits = HabitRepository();
    await logs.init(database);
    await exercises.init(database);
    await meals.init(database);
    await habits.init(database);
    await database.writeTxn(() async => database.habits.clear());
    container = ProviderContainer(
      overrides: [
        activeDatabaseProvider.overrideWithValue(database),
        dailyLogRepoProvider.overrideWithValue(logs),
        exerciseLogRepoProvider.overrideWithValue(exercises),
        mealRepoProvider.overrideWithValue(meals),
        habitRepoProvider.overrideWithValue(habits),
        selectedDateProvider.overrideWith((ref) => DateTime(2026, 9, 19)),
      ],
    );
    container.listen(provider, (_, __) {}, fireImmediately: true);
    await container.pump();
  });
  tearDown(() async {
    container.dispose();
    await Future<void>.delayed(Duration.zero);
    await tearDownTestIsar(database);
  });

  Future<void> waitForFlag(String date, bool expected) async {
    for (var i = 0; i < 50; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await container.pump();
      if (container.read(provider)[date] == expected) return;
    }
    expect(container.read(provider)[date], expected);
  }

  test(
    'non-selected exercise-only date updates on database writes and deletions',
    () async {
      expect(container.read(provider)['2026-09-15'], false);
      final log = ExerciseLog(
        date: '2026-09-15',
        instanceId: 'squat-1',
        exerciseName: 'Squat',
        sets: [SetLog(setNumber: 1, reps: 10, weight: 0)],
      );
      await database.writeTxn(() async => database.exerciseLogs.put(log));
      await waitForFlag('2026-09-15', true);
      await database.writeTxn(() async => database.exerciseLogs.delete(log.id));
      await waitForFlag('2026-09-15', false);
      expect(container.read(selectedDateProvider), DateTime(2026, 9, 19));
    },
  );

  test(
    'rest-day meal entry counts and remote deletion clears its dot',
    () async {
      final meal = DailyMealLog(
        date: '2026-09-20',
        customSlots: {'lunch': MealSlotLog(photoPath: 'meal.jpg')},
      );
      await database.writeTxn(() async => database.dailyMealLogs.put(meal));
      await waitForFlag('2026-09-20', true);
      await database.writeTxn(
        () async => database.dailyMealLogs.delete(meal.id),
      );
      await waitForFlag('2026-09-20', false);
    },
  );

  test(
    'habit completions follow scheduled weekdays and live definition changes',
    () async {
      var habit = Habit(
        id: 'read',
        name: 'Read',
        icon: 'book',
        target: 1,
        activeDays: [DateTime.monday],
        initialCreatedAt: DateTime(2026, 1, 1),
      );
      await database.writeTxn(() async {
        await database.habits.put(habit);
        await database.habitCompletions.put(
          HabitCompletion(date: '2026-09-15', completions: {'read': true}),
        );
      });
      await waitForFlag('2026-09-15', false);
      habit = habit.copyWith(activeDays: [DateTime.tuesday]);
      await database.writeTxn(() async => database.habits.put(habit));
      await waitForFlag('2026-09-15', true);
      await database.writeTxn(() async => database.habitCompletions.clear());
      await waitForFlag('2026-09-15', false);
    },
  );
  test(
    'unrecorded at-most goals do not create activity and partial entries count',
    () async {
      await database.writeTxn(() async {
        await database.habits.put(
          Habit(
            id: 'screen',
            name: 'Screen limit',
            icon: 'phone',
            target: 60,
            type: HabitType.counter,
            goalDirection: GoalDirection.atMost,
            initialCreatedAt: DateTime(2026, 1, 1),
          ),
        );
        await database.habits.put(
          Habit(
            id: 'read',
            name: 'Read',
            icon: 'book',
            target: 30,
            type: HabitType.counter,
            initialCreatedAt: DateTime(2026, 1, 1),
          ),
        );
      });
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await container.pump();
      expect(container.read(provider)['2026-09-15'], false);
      await database.writeTxn(
        () async => database.habitCompletions.put(
          HabitCompletion(date: '2026-09-15', completions: {'read': 5}),
        ),
      );
      await waitForFlag('2026-09-15', true);
      await database.writeTxn(
        () async => database.habitCompletions.put(
          HabitCompletion(date: '2026-09-16', completions: {'screen': 0}),
        ),
      );
      await waitForFlag('2026-09-16', true);
    },
  );
}
