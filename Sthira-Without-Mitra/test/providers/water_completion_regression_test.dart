import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/habit.dart';
import 'package:trufit_bodamma/models/sync_queue_item.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/repositories/daily_log_repository.dart';
import 'package:trufit_bodamma/repositories/habit_repository.dart';
import '../helpers/test_isar_setup.dart';

const _date = '2026-09-19';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Isar database;
  late DailyLogRepository logs;
  late HabitRepository habits;
  late ProviderContainer container;

  setUp(() async {
    database = await setUpTestIsar();
    logs = DailyLogRepository();
    habits = HabitRepository();
    await logs.init(database);
    await habits.init(database);
    container = ProviderContainer(
      overrides: [
        dateStringProvider.overrideWithValue(_date),
        dailyLogRepoProvider.overrideWithValue(logs),
        habitRepoProvider.overrideWithValue(habits),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await logs.detachSync();
    logs.dispose();
    await habits.detachSync();
    await Future<void>.delayed(Duration.zero);
    await tearDownTestIsar(database);
  });

  test(
    'correcting water reconciles completion and Clear restores no-reading state',
    () async {
      final water = habits.getHabit('water')!.copyWith(name: 'Hydration');
      await habits.saveHabit(water);
      final checkInTime = DateTime(2026, 9, 19, 9);
      await logs.saveLog(
        DailyLog(
          date: _date,
          dayFeeling: 'good',
          dayNote: 'A calm morning.',
          checkInUpdatedAt: checkInTime,
          steps: 5000,
        ),
      );
      final notifier = container.read(dailyLogProvider.notifier);
      await notifier.updateWaterForDate(_date, 3000);
      expect(
        isHabitCompleted(
          water,
          habits.getCompletions(_date),
          logs.getOrCreate(_date),
        ),
        isTrue,
      );
      await notifier.updateWaterForDate(_date, 500);
      expect(logs.getOrCreate(_date).waterMl, 500);
      expect(
        isHabitCompleted(
          water,
          habits.getCompletions(_date),
          logs.getOrCreate(_date),
        ),
        isFalse,
      );
      expect(
        hasHabitRecord(
          water,
          habits.getCompletions(_date),
          logs.getOrCreate(_date),
        ),
        isTrue,
      );
      await notifier.clearWaterForDate(_date);
      final cleared = logs.getOrCreate(_date);
      expect(cleared.waterMl, isNull);
      expect(cleared.dayFeeling, 'good');
      expect(cleared.dayNote, 'A calm morning.');
      expect(cleared.checkInUpdatedAt, checkInTime);
      expect(cleared.steps, 5000);
      expect(
        habits.getCompletions(_date).completions.containsKey('water'),
        isFalse,
      );
      expect(
        isHabitCompleted(water, habits.getCompletions(_date), cleared),
        isFalse,
      );
      expect(
        hasHabitRecord(water, habits.getCompletions(_date), cleared),
        isFalse,
      );
    },
  );

  for (final override in ['done', 'notDone']) {
    test(
      'water corrections and Clear preserve explicit $override override',
      () async {
        final water = habits.getHabit('water')!;
        await habits.setOverride(_date, 'water', override);
        final notifier = container.read(dailyLogProvider.notifier);
        for (final amount in [3000, 500]) {
          await notifier.updateWaterForDate(_date, amount);
          expect(habits.getCompletions(_date).overrides['water'], override);
          expect(
            isHabitCompleted(
              water,
              habits.getCompletions(_date),
              logs.getOrCreate(_date),
            ),
            override == 'done',
          );
        }
        await notifier.clearWaterForDate(_date);
        final completion = habits.getCompletions(_date);
        expect(completion.overrides['water'], override);
        expect(completion.completions.containsKey('water'), isFalse);
        expect(
          isHabitCompleted(water, completion, logs.getOrCreate(_date)),
          override == 'done',
        );
      },
    );
  }

  test(
    'recorded zero honors an at-most water target and Clear is still missing data',
    () async {
      final water = habits
          .getHabit('water')!
          .copyWith(goalDirection: GoalDirection.atMost, target: 2);
      await habits.saveHabit(water);
      final notifier = container.read(dailyLogProvider.notifier);
      await notifier.updateWaterForDate(_date, 3000);
      expect(
        isHabitCompleted(
          water,
          habits.getCompletions(_date),
          logs.getOrCreate(_date),
        ),
        isFalse,
      );
      await notifier.updateWaterForDate(_date, 0);
      expect(
        isHabitCompleted(
          water,
          habits.getCompletions(_date),
          logs.getOrCreate(_date),
        ),
        isTrue,
      );
      await notifier.clearWaterForDate(_date);
      expect(
        isHabitCompleted(
          water,
          habits.getCompletions(_date),
          logs.getOrCreate(_date),
        ),
        isFalse,
      );
    },
  );

  test(
    'atomic derived clear preserves concurrent habit edits and queues authoritative state',
    () async {
      await habits.saveCompletion(
        HabitCompletion(
          date: _date,
          completions: {'water': true, 'reading': false},
          overrides: {'water': 'done'},
          streaks: {'reading': 2},
        ),
      );
      await Future.wait([
        habits.clearCompletion(_date, 'water'),
        habits.setCompletion(_date, 'reading', true),
      ]);
      final saved = habits.getCompletions(_date);
      expect(saved.completions, {'reading': true});
      expect(saved.overrides, {'water': 'done'});
      expect(saved.streaks, {'reading': 2});
      final pending =
          database.syncQueueItems
              .where()
              .findAllSync()
              .where((item) => item.collection == 'habit_completions')
              .toList()
            ..sort((a, b) => a.id.compareTo(b.id));
      expect(jsonDecode(pending.last.payload), saved.toJson());
    },
  );
}
