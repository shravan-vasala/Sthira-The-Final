import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/exercise_log.dart';
import 'package:trufit_bodamma/models/habit.dart';
import 'package:trufit_bodamma/models/yearly_activity.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import '../helpers/test_isar_setup.dart';

Future<YearlyActivity> waitForRefresh(
  ProviderContainer container,
  bool Function(YearlyActivity value) matches,
  Future<void> Function() action,
) async {
  final complete = Completer<YearlyActivity>();
  final subscription = container.listen(yearlyActivityHeatmapProvider(2026), (
    _,
    next,
  ) {
    final value = next.asData?.value;
    if (value != null && matches(value) && !complete.isCompleted) {
      complete.complete(value);
    }
  });
  try {
    await action();
    return await complete.future.timeout(const Duration(seconds: 5));
  } finally {
    subscription.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Isar database;
  setUp(() async => database = await setUpTestIsar());
  tearDown(() async => tearDownTestIsar(database));

  test(
    'all-date native updates refresh each recording area and deletion',
    () async {
      final container = ProviderContainer(
        overrides: [
          activeDatabaseProvider.overrideWithValue(database),
          clockProvider.overrideWithValue(DateTime(2026, 9, 19)),
        ],
      );
      final keepAlive = container.listen(
        yearlyActivityHeatmapProvider(2026),
        (_, next) {},
      );
      addTearDown(() {
        keepAlive.close();
        container.dispose();
      });
      expect(
        (await container.read(
          yearlyActivityHeatmapProvider(2026).future,
        )).recordedDays,
        0,
      );

      var snapshot = await waitForRefresh(
        container,
        (value) => value.recordedDays == 1,
        () async {
          await database.writeTxn(() async {
            await database.exerciseLogs.put(
              ExerciseLog(
                date: '2026-09-02',
                instanceId: 'squat',
                exerciseName: 'Squat',
                sets: [SetLog(reps: 8)],
              ),
            );
          });
        },
      );
      expect(snapshot.day(DateTime(2026, 9, 2)).areas, {ActivityArea.workouts});

      snapshot = await waitForRefresh(
        container,
        (value) => value.recordedDays == 2,
        () async {
          await database.writeTxn(() async {
            await database.habitCompletions.put(
              HabitCompletion(
                date: '2026-08-01',
                overrides: {'old-habit': 'notDone'},
              ),
            );
          });
        },
      );
      expect(snapshot.day(DateTime(2026, 8, 1)).areas, {ActivityArea.habits});

      snapshot = await waitForRefresh(
        container,
        (value) => value.recordedDays == 3,
        () async {
          await database.writeTxn(() async {
            await database.dailyMealLogs.put(
              DailyMealLog(
                date: '2026-07-01',
                customSlots: {
                  'snack': MealSlotLog(photoPaths: ['snack.jpg']),
                },
              ),
            );
          });
        },
      );
      expect(snapshot.day(DateTime(2026, 7, 1)).areas, {ActivityArea.meals});

      snapshot = await waitForRefresh(
        container,
        (value) => value.recordedDays == 4,
        () async {
          await database.writeTxn(() async {
            await database.dailyLogs.putAll([
              DailyLog(date: '2026-06-01', waterMl: 0),
              DailyLog(date: '2025-06-01', steps: 100),
              DailyLog(date: '2026-09-20', steps: 100),
              DailyLog(date: '2026-01-01', updatedAt: DateTime(2026)),
            ]);
          });
        },
      );
      expect(snapshot.day(DateTime(2026, 6, 1)).areas, {
        ActivityArea.wellbeing,
      });
      expect(snapshot.day(DateTime(2026, 9, 20)).hasEntries, isFalse);
      expect(snapshot.day(DateTime(2026, 1, 1)).hasEntries, isFalse);

      snapshot = await waitForRefresh(
        container,
        (value) => value.recordedDays == 3,
        () async {
          await database.writeTxn(() async => database.exerciseLogs.clear());
        },
      );
      expect(snapshot.day(DateTime(2026, 9, 2)).hasEntries, isFalse);
    },
  );

  test(
    'account rebinding and clock rollover cannot leak the previous snapshot',
    () async {
      final second = await setUpTestIsar();
      addTearDown(() => tearDownTestIsar(second));
      await database.writeTxn(() async {
        await database.dailyLogs.put(DailyLog(date: '2026-01-01', steps: 10));
      });
      await second.writeTxn(() async {
        await second.dailyLogs.put(DailyLog(date: '2026-09-20', steps: 0));
      });
      var active = database;
      var now = DateTime(2026, 9, 19);
      final container = ProviderContainer(
        overrides: [
          activeDatabaseProvider.overrideWith((ref) {
            ref.watch(accountGenerationProvider);
            return active;
          }),
          clockProvider.overrideWith((ref) => now),
        ],
      );
      final keepAlive = container.listen(
        yearlyActivityHeatmapProvider(2026),
        (_, next) {},
      );
      addTearDown(() {
        keepAlive.close();
        container.dispose();
      });
      expect(
        (await container.read(
          yearlyActivityHeatmapProvider(2026).future,
        )).recordedDays,
        1,
      );

      final changed = await waitForRefresh(
        container,
        (value) => value.recordedDays == 0,
        () async {
          active = second;
          container.read(accountGenerationProvider.notifier).state++;
        },
      );
      expect(changed.day(DateTime(2026, 1, 1)).hasEntries, isFalse);

      final tomorrow = await waitForRefresh(
        container,
        (value) => value.recordedDays == 1,
        () async {
          now = DateTime(2026, 9, 20);
          container.invalidate(clockProvider);
        },
      );
      expect(tomorrow.day(DateTime(2026, 9, 20)).hasEntries, isTrue);
      expect(tomorrow.day(DateTime(2026, 1, 1)).hasEntries, isFalse);

      final empty = await waitForRefresh(
        container,
        (value) => value.recordedDays == 0,
        () async {
          container.read(accountTransitionProvider.notifier).state = true;
        },
      );
      expect(empty.recordedDays, 0);
    },
  );

  test(
    'selected year uses injected clock and preserves explicit navigation',
    () {
      var now = DateTime(2026, 12, 31);
      final container = ProviderContainer(
        overrides: [clockProvider.overrideWith((ref) => now)],
      );
      addTearDown(container.dispose);
      expect(container.read(selectedYearProvider), 2026);
      container.read(selectedYearProvider.notifier).state = 2024;
      now = DateTime(2027, 1, 1);
      container.invalidate(clockProvider);
      expect(container.read(selectedYearProvider), 2024);
    },
  );
}
