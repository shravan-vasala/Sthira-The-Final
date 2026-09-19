import 'dart:async';
import '../models/workout_plan.dart';
import '../services/cloud_record_store.dart';
import 'package:isar/isar.dart';
import '../models/exercise_log.dart';
import '../models/exercise_pr.dart';
import '../interfaces/i_cloud_sync_service.dart';
import 'dart:convert';
import '../models/sync_queue_item.dart';

class ExerciseLogRepository {
  late Isar _isar;
  ICloudSyncService? _sync;
  StreamSubscription<void>? _planSubscription;
  Map<String, (String, int)>? _legacyAliases;

  Stream<void> get watchUpdates =>
      _isar.exerciseLogs.watchLazy(fireImmediately: true);

  void attachSync(ICloudSyncService sync) => _sync = sync;
  Future<void> detachSync() async {
    _sync = null;
  }

  Future<void> init(Isar isar) async {
    await _planSubscription?.cancel();
    _isar = isar;
    _legacyAliases = null;
    _planSubscription = isar.workoutPlans.watchLazy().listen(
      (_) => _legacyAliases = null,
    );
  }

  ExercisePr? getPr(String exerciseName) {
    return _isar.exercisePrs
        .where()
        .exerciseNameEqualTo(exerciseName)
        .findFirstSync();
  }

  Future<void> savePr(ExercisePr pr) async {
    final database = _isar;
    final sync = _sync;
    final existing = getPr(pr.exerciseName);
    if (existing != null) pr.id = existing.id;
    await database.writeTxn(() async {
      if (!identical(_isar, database))
        throw StateError('The active account changed.');
      await database.exercisePrs.put(pr);
      if (!identical(_isar, database))
        throw StateError('The active account changed.');
      if (database.name != 'guest') {
        await database.syncQueueItems.put(
          SyncQueueItem(
            uid: database.name,
            collection: 'exercise_prs',
            docId: pr.exerciseName,
            payload: jsonEncode(pr.toJson()),
            timestamp: DateTime.now(),
          ),
        );
      }
    });
    if (identical(_isar, database) && identical(_sync, sync))
      sync?.triggerFlush();
  }

  Map<String, (String, int)> _unambiguousLegacyAliases() {
    if (_legacyAliases != null) return _legacyAliases!;
    final candidates = <(String, int), Set<String>>{};
    for (final plan in _isar.workoutPlans.where().findAllSync()) {
      plan.ensureExerciseIds();
      for (final day in [
        ...plan.days,
        ...?plan.weeks?.expand((week) => week.days),
      ]) {
        final weekday = day.weekday;
        if (weekday == null) continue;
        for (final exercise in day.sections.expand(
          (section) => section.exercises,
        )) {
          final name = exercise.name;
          final id = exercise.instanceId;
          if (name == null || name.isEmpty || id == null) continue;
          (candidates[(name, weekday)] ??= <String>{}).add(id);
        }
      }
    }
    return _legacyAliases = {
      for (final entry in candidates.entries)
        if (entry.value.length == 1) entry.value.single: entry.key,
    };
  }

  ExerciseLog? _exactLog(String date, String instanceId) => _isar.exerciseLogs
      .filter()
      .dateEqualTo(date)
      .and()
      .instanceIdEqualTo(instanceId)
      .findFirstSync();

  ExerciseLog? getLog(String date, String instanceId) {
    final exact = _exactLog(date, instanceId);
    if (exact != null) return exact;
    final legacy = _unambiguousLegacyAliases()[instanceId];
    if (legacy == null || DateTime.tryParse(date)?.weekday != legacy.$2)
      return null;
    // Ambiguous old name-based records remain in history; never duplicate them.
    return _exactLog(date, legacy.$1);
  }

  Future<void> saveLog(ExerciseLog log) async {
    final database = _isar;
    final sync = _sync;
    final existing = getLog(log.date, log.instanceId);
    if (existing != null) log.id = existing.id;
    await database.writeTxn(() async {
      if (!identical(_isar, database))
        throw StateError('The active account changed.');
      await database.exerciseLogs.put(log);
      if (!identical(_isar, database))
        throw StateError('The active account changed.');
      if (database.name != 'guest') {
        if (existing != null && existing.key != log.key) {
          await database.syncQueueItems.put(
            SyncQueueItem(
              uid: database.name,
              collection: '_delete_/exercise_logs',
              docId: existing.key,
              payload: '{}',
              timestamp: DateTime.now(),
            ),
          );
        }
        await database.syncQueueItems.put(
          SyncQueueItem(
            uid: database.name,
            collection: 'exercise_logs',
            docId: log.key,
            payload: jsonEncode(log.toJson()),
            timestamp: DateTime.now(),
          ),
        );
      }
    });
    if (identical(_isar, database) && identical(_sync, sync))
      sync?.triggerFlush();
  }

  Future<void> deleteLog(String date, String instanceId) async {
    final database = _isar;
    final sync = _sync;
    final existing = getLog(date, instanceId);
    if (existing != null) {
      await database.writeTxn(() async {
        if (!identical(_isar, database))
          throw StateError('The active account changed.');
        await database.exerciseLogs.delete(existing.id);
        if (!identical(_isar, database))
          throw StateError('The active account changed.');
        if (database.name != 'guest') {
          await database.syncQueueItems.put(
            SyncQueueItem(
              uid: database.name,
              collection: '_delete_/exercise_logs',
              docId: existing.key,
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

  bool hasLog(String date, String instanceId) {
    final log = getLog(date, instanceId);
    if (log == null) return false;

    // We cannot easily import WorkoutCompletion here due to potential circular dependencies,
    // so we duplicate the meaningful work check or we assume log.sets.isNotEmpty is meaningful
    // IF we trust the saver to delete bad logs.
    // However, the rule states to verify it here.
    if (log.sets.isEmpty) return false;
    for (final s in log.sets) {
      if ((s.reps ?? 0) > 0 ||
          (s.weight ?? 0.0) > 0 ||
          (s.durationSeconds ?? 0) > 0)
        return true;
    }
    return false;
  }

  List<ExerciseLog> getLogsForExercise(String exerciseName) {
    // Isar doesn't have a good endswith query out of the box, but we can query all and filter, or use filter().keyEndsWith()
    return _isar.exerciseLogs
        .filter()
        .exerciseNameEqualTo(exerciseName)
        .sortByDate()
        .findAllSync();
  }

  List<ExerciseLog> getLogsForDate(String date) {
    return _isar.exerciseLogs.filter().dateEqualTo(date).findAllSync();
  }

  ExerciseLog? getLastLog(String exerciseName, {String? beforeDate}) {
    var logs = getLogsForExercise(exerciseName);
    if (beforeDate != null) {
      logs = logs.where((l) => l.date.compareTo(beforeDate) <= 0).toList();
    }
    if (logs.isEmpty) return null;
    logs.sort((a, b) => b.date.compareTo(a.date));
    return logs.first;
  }

  // ── Cloud sync helpers ──

  Future<void> importLogsFromCloud(
    Map<String, Map<String, dynamic>> cloudData,
  ) async {
    final database = _isar;
    await CloudRecordStore(database).apply(
      'exercise_logs',
      cloudData,
      isCurrent: () => identical(_isar, database),
    );
  }

  Future<void> importPrsFromCloud(
    Map<String, Map<String, dynamic>> cloudData,
  ) async {
    final database = _isar;
    await CloudRecordStore(database).apply(
      'exercise_prs',
      cloudData,
      isCurrent: () => identical(_isar, database),
    );
  }

  Map<String, Map<String, dynamic>> exportLogsForCloud() {
    final result = <String, Map<String, dynamic>>{};
    final logs = _isar.exerciseLogs.where().findAllSync();
    for (final log in logs) {
      result[log.key] = log.toJson();
    }
    return result;
  }

  Map<String, Map<String, dynamic>> exportPrsForCloud() {
    final result = <String, Map<String, dynamic>>{};
    final prs = _isar.exercisePrs.where().findAllSync();
    for (final pr in prs) {
      result[pr.exerciseName] = pr.toJson();
    }
    return result;
  }
}
