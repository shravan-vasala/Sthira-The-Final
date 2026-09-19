import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'app_providers.dart';
import '../models/daily_log.dart';
import '../models/daily_meal_log.dart';
import '../models/exercise_log.dart';
import '../models/habit.dart';
import '../models/yearly_activity.dart';

// Preserve an explicitly chosen year when the clock rolls over.
final selectedYearProvider = StateProvider<int>(
  (ref) => ref.read(clockProvider).year,
);

final yearlyActivityChangesProvider = StreamProvider.autoDispose<void>((ref) {
  final database = ref.watch(activeDatabaseProvider);
  if (database == null) return const Stream.empty();
  final changes = StreamController<void>();
  final subscriptions = [
    database.dailyLogs.watchLazy().listen(changes.add),
    database.dailyMealLogs.watchLazy().listen(changes.add),
    database.habitCompletions.watchLazy().listen(changes.add),
    database.exerciseLogs.watchLazy().listen(changes.add),
  ];
  ref.onDispose(() {
    for (final subscription in subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(changes.close());
  });
  return changes.stream;
});

/// One bounded snapshot for the year. No per-day score or plan queries.
final yearlyActivityHeatmapProvider = FutureProvider.autoDispose
    .family<YearlyActivity, int>((ref, year) async {
      ref.watch(accountGenerationProvider);
      ref.watch(yearlyActivityChangesProvider);
      final database = ref.watch(activeDatabaseProvider);
      final now = ref.watch(clockProvider);
      final today = DateTime(now.year, now.month, now.day);
      if (ref.watch(accountTransitionProvider) || database == null) {
        return YearlyActivity(year: year, today: today, days: const {});
      }
      final prefix = year.toString().padLeft(4, '0');
      final first = '$prefix-01-01';
      final last = '$prefix-12-31';
      // Capture this account's database. A switch invalidates this future and
      // cannot redirect any of the queries to the next user's repositories.
      return database.txn(() async {
        final daily = await database.dailyLogs
            .filter()
            .dateBetween(first, last)
            .findAll();
        final meals = await database.dailyMealLogs
            .filter()
            .dateBetween(first, last)
            .findAll();
        final habits = await database.habitCompletions
            .filter()
            .dateBetween(first, last)
            .findAll();
        final exercises = await database.exerciseLogs
            .filter()
            .dateBetween(first, last)
            .findAll();
        return YearlyActivity.fromRecords(
          year: year,
          today: today,
          dailyLogs: daily,
          mealLogs: meals,
          habitLogs: habits,
          exerciseLogs: exercises,
        );
      });
    });
