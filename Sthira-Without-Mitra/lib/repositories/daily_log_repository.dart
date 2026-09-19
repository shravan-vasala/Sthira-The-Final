import '../services/cloud_record_store.dart';
import 'dart:async';
import 'dart:convert';
import 'package:isar/isar.dart';
import '../models/daily_log.dart';
import '../interfaces/i_cloud_sync_service.dart';
import '../models/sync_queue_item.dart';
import '../services/health_connect_service.dart';

class DailyLogRepository {
  late Isar _isar;
  ICloudSyncService? _sync;

  int _syncGeneration = 0;
  final List<StreamSubscription> _syncSubscriptions = [];
  final Map<String, DateTime> _localEdits = {};

  final _updates = StreamController<void>.broadcast();
  final _localWorkoutCompletions = StreamController<String>.broadcast(
    sync: true,
  );

  /// Successful local completion transitions only; imports never celebrate.
  Stream<String> get watchLocalWorkoutCompletions =>
      _localWorkoutCompletions.stream;
  Stream<void> get watchUpdates => _isar.dailyLogs.watchLazy();

  Future<void> detachSync() async {
    _syncGeneration++;
    final toCancel = List<StreamSubscription>.from(_syncSubscriptions);
    _syncSubscriptions.clear();
    for (final sub in toCancel) {
      try {
        await sub.cancel();
      } catch (e) {
        // ignore errors during teardown
      }
    }
    _sync = null;
  }

  /// Attach a Firestore sync service (called after sign-in).
  Future<void> attachSync(ICloudSyncService sync, {bool listen = true}) async {
    await detachSync();
    final generation = ++_syncGeneration;
    final database = _isar;
    _sync = sync;
    if (!listen || !sync.canSync) return;
    _syncSubscriptions.add(
      sync
          .streamCollection('daily_logs')
          .asyncMap((snapshot) async {
            if (generation != _syncGeneration || !identical(_isar, database)) {
              return;
            }
            await CloudRecordStore(database).apply(
              'daily_logs',
              snapshot,
              isCurrent: () =>
                  generation == _syncGeneration && identical(_isar, database),
            );
          })
          .listen(
            (_) {},
            onError: (Object error) {
              /* Outbox and last local snapshot remain intact; next server snapshot retries. */
            },
          ),
    );
  }

  void dispose() {
    detachSync();
    _updates.close();
    _localWorkoutCompletions.close();
  }

  Future<void> init(Isar isar) async {
    _isar = isar;
    _localEdits.clear();
  }

  DailyLog? getLog(String date) {
    return _isar.dailyLogs.where().dateEqualTo(date).findFirstSync();
  }

  Stream<DailyLog?> watchLog(String date) {
    return _isar.dailyLogs
        .where()
        .dateEqualTo(date)
        .watch(fireImmediately: true)
        .map((logs) {
          return logs.isNotEmpty ? logs.first : null;
        });
  }

  DailyLog getOrCreate(String date) {
    return getLog(date) ?? DailyLog(date: date);
  }

  Future<void> saveLog(DailyLog log) async {
    final database = _isar;
    final sync = _sync;
    _localEdits[log.date] = DateTime.now();
    final updatedLog = log.copyWith(updatedAt: DateTime.now());
    final existing = getLog(log.date);
    if (existing != null) {
      updatedLog.id = existing.id;
    }
    await database.writeTxn(() async {
      await database.dailyLogs.put(updatedLog);
      if (database.name != 'guest') {
        await database.syncQueueItems.put(
          SyncQueueItem(
            uid: database.name,
            collection: 'daily_logs',
            docId: updatedLog.date,
            payload: jsonEncode(updatedLog.toJson()),
            timestamp: DateTime.now(),
          ),
        );
      }
    });
    _afterCommit(database, sync);
    if (existing?.workoutCompleted != true && updatedLog.workoutCompleted) {
      _notifyLocalWorkoutCompletion(database, log.date);
    }
  }

  Future<void> _updateLogSafe(
    String date,
    DailyLog Function(DailyLog) modifier,
  ) async {
    final database = _isar;
    final sync = _sync;
    _localEdits[date] = DateTime.now();
    var newlyCompleted = false;
    await database.writeTxn(() async {
      final current =
          await database.dailyLogs.where().dateEqualTo(date).findFirst() ??
          DailyLog(date: date);
      final updated = modifier(current).copyWith(updatedAt: DateTime.now());
      updated.id = current.id;
      newlyCompleted = !current.workoutCompleted && updated.workoutCompleted;

      await database.dailyLogs.put(updated);
      if (database.name != 'guest') {
        await database.syncQueueItems.put(
          SyncQueueItem(
            uid: database.name,
            collection: 'daily_logs',
            docId: updated.date,
            payload: jsonEncode(updated.toJson()),
            timestamp: DateTime.now(),
          ),
        );
      }
    });
    _afterCommit(database, sync);
    if (newlyCompleted) _notifyLocalWorkoutCompletion(database, date);
  }

  void _notifyLocalWorkoutCompletion(Isar database, String date) {
    if (identical(database, _isar) && !_localWorkoutCompletions.isClosed) {
      _localWorkoutCompletions.add(date);
    }
  }

  // A durable save must not be reported as failed merely because a background
  // flush cannot start. Its outbox entry will retry on the next sync attempt.
  void _afterCommit(Isar database, ICloudSyncService? sync) {
    if (!identical(database, _isar)) return;
    if (!_updates.isClosed) _updates.add(null);
    try {
      if (sync != null && sync.currentUid == database.name) {
        sync.triggerFlush();
      }
    } catch (_) {
      // The data and pending upload already committed together.
    }
  }

  Future<void> updateWater(String date, int waterMl) async {
    await _updateLogSafe(date, (log) => log.copyWith(waterMl: waterMl));
  }

  Future<void> clearWater(String date) async {
    await _updateLogSafe(date, (log) => log.clearWater());
  }

  Future<void> clearBodyFat(String date) async {
    await _updateLogSafe(date, (log) => log.clearBodyFat());
  }

  Future<void> updateWeight(String date, double weight) async {
    await _updateLogSafe(date, (log) => log.copyWith(weight: weight));
  }

  Future<void> updateCheckIn(String date, String? feeling, String? note) async {
    const feelings = {'veryLow', 'low', 'okay', 'good', 'great'};
    final trimmedFeeling = feeling?.trim();
    final value = trimmedFeeling == null || trimmedFeeling.isEmpty
        ? null
        : trimmedFeeling;
    if (value != null && !feelings.contains(value)) {
      throw ArgumentError.value(feeling, 'feeling', 'Choose a valid feeling');
    }
    final trimmedNote = note?.trim();
    final noteValue = trimmedNote == null || trimmedNote.isEmpty
        ? null
        : trimmedNote;
    if (value == null && noteValue == null) {
      await removeCheckIn(date);
      return;
    }
    await _updateLogSafe(
      date,
      // Clear only reflection fields first: null/blank means remove the old note.
      (log) => log.clearCheckIn().copyWith(
        dayFeeling: value,
        dayNote: noteValue,
        checkInUpdatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> removeCheckIn(String date) async {
    await _updateLogSafe(date, (log) => log.clearCheckIn());
  }

  Future<void> updateSteps(String date, int steps, {String? source}) async {
    await _updateLogSafe(
      date,
      (log) => log.copyWith(steps: steps, stepsSource: source),
    );
  }

  Future<void> updateScreenTime(String date, int minutes) async {
    await _updateLogSafe(
      date,
      (log) => log.copyWith(screenTimeMinutes: minutes),
    );
  }

  Future<void> updateSleep(String date, double? hours, {String? source}) async {
    await _updateLogSafe(
      date,
      (log) => log.copyWith(sleepHours: hours, sleepSource: source),
    );
  }

  Future<void> updateFromHealthConnect(
    List<HealthDailyData> healthDataList, {
    bool Function()? isCurrent,
  }) async {
    final database = _isar;
    final sync = _sync;
    bool ownsWrite() =>
        identical(database, _isar) && (isCurrent?.call() ?? true);
    if (!ownsWrite() || healthDataList.isEmpty) return;
    var changed = false;
    await database.writeTxn(() async {
      if (!ownsWrite()) return;
      for (final data in healthDataList) {
        if (!ownsWrite()) return;
        final log =
            await database.dailyLogs
                .where()
                .dateEqualTo(data.dateStr)
                .findFirst() ??
            DailyLog(date: data.dateStr);
        var updated = log;
        final steps = data.stepsResult.data;
        final sleep = data.sleepResult.data;
        // Empty/error means unknown. Retain existing readings and real zeros.
        if (log.stepsSource != 'manual' &&
            data.stepsResult.status == HealthStatus.success &&
            steps != null &&
            steps >= 0) {
          updated = updated.copyWith(
            steps: steps,
            stepsSource: 'healthConnect',
          );
        }
        if (log.sleepSource != 'manual' &&
            data.sleepResult.status == HealthStatus.success &&
            sleep != null &&
            sleep.isFinite &&
            sleep >= 0) {
          updated = updated.copyWith(
            sleepHours: sleep,
            sleepSource: 'healthConnect',
          );
        }
        if (jsonEncode(updated.toJson()) == jsonEncode(log.toJson())) continue;
        final stamp = DateTime.now();
        updated = updated.copyWith(updatedAt: stamp)..id = log.id;
        if (!ownsWrite()) return;
        await database.dailyLogs.put(updated);
        _localEdits[data.dateStr] = stamp;
        if (database.name != 'guest') {
          await database.syncQueueItems.put(
            SyncQueueItem(
              uid: database.name,
              collection: 'daily_logs',
              docId: updated.date,
              payload: jsonEncode(updated.toJson()),
              timestamp: stamp,
            ),
          );
        }
        changed = true;
      }
    });
    if (changed && ownsWrite()) {
      _afterCommit(database, sync);
    }
  }

  Future<void> clearSteps(String date) async {
    await _updateLogSafe(date, (log) => log.clearSteps());
  }

  Future<void> clearSleep(String date) async {
    await _updateLogSafe(date, (log) => log.clearSleep());
  }

  Future<void> updateBodyFat(String date, double bodyFat) async {
    await _updateLogSafe(date, (log) => log.copyWith(bodyFat: bodyFat));
  }

  Future<void> updateWorkoutStatus(
    String date,
    String dayId,
    String status,
  ) async {
    await _updateLogSafe(
      date,
      (log) => log.copyWith(workoutStatus: status, workoutDayId: dayId),
    );
  }

  List<DailyLog> getLogsInRange(String startDate, String endDate) {
    return _isar.dailyLogs
        .filter()
        .dateGreaterThan(startDate, include: true)
        .and()
        .dateLessThan(endDate, include: true)
        .sortByDate()
        .findAllSync();
  }

  List<DailyLog> getAllLogs() {
    return _isar.dailyLogs.where().sortByDate().findAllSync();
  }

  bool hasActivityOnDate(String date) {
    final log = getLog(date);
    return log?.hasAnyActivity ?? false;
  }

  /// Bulk import from Firestore (used on new-device sign-in).
  Future<void> importFromCloud(
    Map<String, Map<String, dynamic>> cloudData,
  ) async {
    final database = _isar;
    await CloudRecordStore(database).apply(
      'daily_logs',
      cloudData,
      isCurrent: () => identical(_isar, database),
    );
    if (identical(database, _isar) && !_updates.isClosed) _updates.add(null);
  }

  /// Export all local data as a map for bulk cloud upload.
  Map<String, Map<String, dynamic>> exportForCloud() {
    final result = <String, Map<String, dynamic>>{};
    final logs = _isar.dailyLogs.where().findAllSync();
    for (final log in logs) {
      result[log.date] = log.toJson();
    }
    return result;
  }
}
