import '../services/cloud_record_store.dart';
import 'package:isar/isar.dart';
import '../models/habit.dart';
import '../interfaces/i_cloud_sync_service.dart';
import '../models/app_config.dart';
import 'dart:convert';
import '../models/sync_queue_item.dart';

class HabitRepository {
  late Isar _isar;
  ICloudSyncService? _sync;

  Stream<void> get watchUpdates =>
      _isar.habits.watchLazy(fireImmediately: true);

  void attachSync(ICloudSyncService sync) => _sync = sync;
  Future<void> detachSync() async {
    _sync = null;
  }

  Future<void> init(Isar isar) async {
    _isar = isar;
    await _seedIfEmpty();
  }

  Future<void> _seedIfEmpty() async {
    final database = _isar;
    final config = database.appConfigs
        .where()
        .keyEqualTo('habits_seeded')
        .findFirstSync();
    if (config == null) {
      final defaultHabits = Habit.defaults;
      await database.writeTxn(() async {
        if (!identical(_isar, database))
          throw StateError('The active account changed.');
        for (final habit in defaultHabits) {
          await database.habits.put(habit);
        }
        await database.appConfigs.put(
          AppConfig(key: 'habits_seeded', value: 'true'),
        );
      });
    }
  }

  List<Habit> getHabits() {
    return _isar.habits.where().sortByOrder().findAllSync();
  }

  Habit? getHabit(String id) {
    return _isar.habits.where().idEqualTo(id).findFirstSync();
  }

  Future<void> saveHabit(Habit habit) async {
    final database = _isar;
    final sync = _sync;
    final updatedHabit = habit.copyWith(updatedAt: DateTime.now());
    final existing = getHabit(habit.id);
    if (existing != null) {
      updatedHabit.idInternal = existing.idInternal;
    }
    await database.writeTxn(() async {
      if (!identical(_isar, database))
        throw StateError('The active account changed.');
      await database.habits.put(updatedHabit);
      if (!identical(_isar, database))
        throw StateError('The active account changed.');
      if (database.name != 'guest') {
        await database.syncQueueItems.put(
          SyncQueueItem(
            uid: database.name,
            collection: 'habit_config',
            docId: updatedHabit.id,
            payload: jsonEncode(updatedHabit.toJson()),
            timestamp: DateTime.now(),
          ),
        );
      }
    });
    if (identical(_isar, database) && identical(_sync, sync))
      sync?.triggerFlush();
  }

  Future<void> deleteHabit(String id) async {
    final database = _isar;
    final sync = _sync;
    final existing = getHabit(id);
    if (existing != null) {
      await database.writeTxn(() async {
        if (!identical(_isar, database))
          throw StateError('The active account changed.');
        await database.habits.delete(existing.idInternal);
        if (!identical(_isar, database))
          throw StateError('The active account changed.');
        if (database.name != 'guest') {
          await database.syncQueueItems.put(
            SyncQueueItem(
              uid: database.name,
              collection: '_delete_/habit_config',
              docId: id,
              payload: '{}',
              timestamp: DateTime.now(),
            ),
          );
        }
      });
      if (identical(_isar, database) && identical(_sync, sync))
        sync?.triggerFlush();
    }
  }

  Future<void> reorderHabits(List<Habit> reordered) async {
    final database = _isar;
    final sync = _sync;
    await database.writeTxn(() async {
      if (!identical(_isar, database))
        throw StateError('The active account changed.');
      for (int i = 0; i < reordered.length; i++) {
        final existing = await database.habits.get(reordered[i].idInternal);
        final h = reordered[i].copyWith(order: i, updatedAt: DateTime.now());
        if (existing != null) {
          h.idInternal = existing.idInternal;
        }
        await database.habits.put(h);
        if (!identical(_isar, database))
          throw StateError('The active account changed.');
        if (database.name != 'guest') {
          await database.syncQueueItems.put(
            SyncQueueItem(
              uid: database.name,
              collection: 'habit_config',
              docId: h.id,
              payload: jsonEncode(h.toJson()),
              timestamp: DateTime.now(),
            ),
          );
        }
      }
    });
    if (identical(_isar, database) && identical(_sync, sync))
      sync?.triggerFlush();
  }

  HabitCompletion getCompletions(String date) {
    return _isar.habitCompletions.where().dateEqualTo(date).findFirstSync() ??
        HabitCompletion(date: date);
  }

  Stream<HabitCompletion?> watchCompletions(String date) {
    return _isar.habitCompletions
        .where()
        .dateEqualTo(date)
        .watch(fireImmediately: true)
        .map((comps) {
          return comps.isNotEmpty ? comps.first : null;
        });
  }

  Future<void> saveCompletion(HabitCompletion completion) async {
    final database = _isar;
    final sync = _sync;
    final updatedCompletion = HabitCompletion(
      date: completion.date,
      completions: completion.completions,
      overrides: completion.overrides,
      streaks: completion.streaks,
      updatedAt: DateTime.now(),
    );
    final existing = database.habitCompletions
        .where()
        .dateEqualTo(completion.date)
        .findFirstSync();
    if (existing != null) {
      updatedCompletion.id = existing.id;
    }
    await database.writeTxn(() async {
      if (!identical(_isar, database))
        throw StateError('The active account changed.');
      await database.habitCompletions.put(updatedCompletion);
      if (!identical(_isar, database))
        throw StateError('The active account changed.');
      if (database.name != 'guest') {
        await database.syncQueueItems.put(
          SyncQueueItem(
            uid: database.name,
            collection: 'habit_completions',
            docId: updatedCompletion.date,
            payload: jsonEncode(updatedCompletion.toJson()),
            timestamp: DateTime.now(),
          ),
        );
      }
    });
    if (identical(_isar, database) && identical(_sync, sync))
      sync?.triggerFlush();
  }

  Future<void> _updateCompletionSafe(
    String date,
    HabitCompletion Function(HabitCompletion) modifier,
  ) async {
    final database = _isar;
    final sync = _sync;
    await database.writeTxn(() async {
      if (!identical(_isar, database))
        throw StateError('The active account changed.');
      final current =
          await database.habitCompletions
              .where()
              .dateEqualTo(date)
              .findFirst() ??
          HabitCompletion(date: date);
      final updated = modifier(current);

      // Inherit the private DB id manually because immutable models discard them during mapping
      // Although our modifier functions actually pass the whole object, so we're good mostly.
      updated.id = current.id;

      await database.habitCompletions.put(updated);
      if (!identical(_isar, database))
        throw StateError('The active account changed.');
      if (database.name != 'guest') {
        await database.syncQueueItems.put(
          SyncQueueItem(
            uid: database.name,
            collection: 'habit_completions',
            docId: updated.date,
            payload: jsonEncode(updated.toJson()),
            timestamp: DateTime.now(),
          ),
        );
      }
    });
    if (identical(_isar, database) && identical(_sync, sync))
      sync?.triggerFlush();
  }

  // Checkbox toggle
  Future<void> toggleCheckboxCompletion(String date, String habitId) async {
    await _updateCompletionSafe(
      date,
      (completion) => completion.toggleCheckbox(habitId),
    );
  }

  // Counter / numeric update
  Future<void> updateProgress(
    String date,
    String habitId,
    double progress,
  ) async {
    await _updateCompletionSafe(
      date,
      (completion) => completion.updateProgress(habitId, progress),
    );
  }

  // Backwards compatibility for old HealthConnectService code
  Future<void> setCompletion(
    String date,
    String habitId,
    dynamic completed,
  ) async {
    await _updateCompletionSafe(date, (completion) {
      final current = completion.completions[habitId];
      if (current == completed) return completion;

      final newCompletions = Map<String, dynamic>.from(completion.completions);
      newCompletions[habitId] = completed;
      return HabitCompletion(
        date: date,
        completions: newCompletions,
        overrides: completion.overrides,
        streaks: completion.streaks,
        updatedAt: DateTime.now(),
      );
    });
  }

  /// Removes a derived reading without changing explicit user overrides.
  Future<void> clearCompletion(String date, String habitId) async {
    await _updateCompletionSafe(date, (completion) {
      if (!completion.completions.containsKey(habitId)) return completion;
      final values = Map<String, dynamic>.from(completion.completions)
        ..remove(habitId);
      return HabitCompletion(
        date: date,
        completions: values,
        overrides: completion.overrides,
        streaks: completion.streaks,
        updatedAt: DateTime.now(),
      );
    });
  }

  Future<void> setOverride(
    String date,
    String habitId,
    String? overrideValue,
  ) async {
    await _updateCompletionSafe(
      date,
      (completion) => completion.setOverride(habitId, overrideValue),
    );
  }

  // ── Cloud sync helpers ──

  Future<void> importConfigFromCloud(
    Map<String, Map<String, dynamic>> cloudData,
  ) async {
    final database = _isar;
    await CloudRecordStore(database).apply(
      'habit_config',
      cloudData,
      isCurrent: () => identical(_isar, database),
    );
  }

  Future<void> importCompletionsFromCloud(
    Map<String, Map<String, dynamic>> cloudData,
  ) async {
    final database = _isar;
    await CloudRecordStore(database).apply(
      'habit_completions',
      cloudData,
      isCurrent: () => identical(_isar, database),
    );
  }

  Map<String, Map<String, dynamic>> exportConfigForCloud() {
    final result = <String, Map<String, dynamic>>{};
    final habits = getHabits();
    for (final habit in habits) {
      result[habit.id] = habit.toJson();
    }
    return result;
  }

  Map<String, Map<String, dynamic>> exportCompletionsForCloud() {
    final result = <String, Map<String, dynamic>>{};
    final completions = _isar.habitCompletions.where().findAllSync();
    for (final completion in completions) {
      result[completion.date] = completion.toJson();
    }
    return result;
  }
}
