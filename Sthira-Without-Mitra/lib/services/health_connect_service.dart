import 'dart:convert';
import 'package:health/health.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:isar/isar.dart';
import '../models/app_config.dart';

import '../models/feature_availability.dart';

enum StepsSource { healthConnect, manual, none }

enum HealthStatus { success, empty, error }

class HealthReadResult<T> {
  final HealthStatus status;
  final T? data;

  HealthReadResult.success(this.data) : status = HealthStatus.success;
  HealthReadResult.empty() : status = HealthStatus.empty, data = null;
  HealthReadResult.error() : status = HealthStatus.error, data = null;
}

class HealthConnectService {
  static const String _backfillDoneKey = 'health_connect_backfill_done';

  final Health _health = Health();
  late Isar _isar;
  Future<void>? _configuration;
  bool _configured = false;

  Future<void> init(Isar isar) async {
    _isar = isar;
  }

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    final pending = _configuration ??= _health.configure();
    try {
      await pending;
      _configured = true;
    } finally {
      if (identical(_configuration, pending)) _configuration = null;
    }
  }

  Future<FeatureAvailability> getAvailability() async {
    if (!await isAvailable()) return FeatureAvailability.unavailable;
    if (!await isAuthorized()) return FeatureAvailability.disabled;
    return FeatureAvailability.available;
  }

  /// Check if Health Connect app is installed on the device.
  Future<bool> isAvailable() async {
    try {
      await _ensureConfigured();
      final status = await _health.getHealthConnectSdkStatus();
      return status == HealthConnectSdkStatus.sdkAvailable;
    } catch (_) {
      return false;
    }
  }

  /// Check if we already have STEPS + SLEEP_SESSION read permission.
  Future<bool> isAuthorized() async {
    try {
      await _ensureConfigured();
      final types = [HealthDataType.STEPS, HealthDataType.SLEEP_SESSION];
      final perms = [HealthDataAccess.READ, HealthDataAccess.READ];
      return await _health.hasPermissions(types, permissions: perms) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Request STEPS + SLEEP_SESSION read permission from Health Connect.
  Future<bool> requestPermission() async {
    try {
      await _ensureConfigured();
      // Request activity recognition first (required for step data)
      await Permission.activityRecognition.request();

      final types = [HealthDataType.STEPS, HealthDataType.SLEEP_SESSION];
      final perms = [HealthDataAccess.READ, HealthDataAccess.READ];
      return await _health.requestAuthorization(types, permissions: perms);
    } catch (_) {
      return false;
    }
  }

  /// Request historical data access (needed for >30 day backfill).
  Future<bool> requestHistoryAccess() async {
    try {
      await _ensureConfigured();
      return await _health.requestHealthDataHistoryAuthorization();
    } catch (_) {
      return false;
    }
  }

  Future<HealthReadResult<int>> getTodaySteps() async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      final steps = await _health.getTotalStepsInInterval(midnight, now);
      return steps != null
          ? HealthReadResult.success(steps)
          : HealthReadResult.empty();
    } catch (_) {
      return HealthReadResult.error();
    }
  }

  Future<HealthReadResult<int>> getStepsForDate(DateTime date) async {
    try {
      await _ensureConfigured();
      final start = DateTime(date.year, date.month, date.day);
      var end = DateTime(date.year, date.month, date.day + 1);
      final now = DateTime.now();
      if (start.isAfter(now)) return HealthReadResult.empty();
      if (end.isAfter(now)) {
        end = now;
      }
      final steps = await _health.getTotalStepsInInterval(start, end);
      return steps != null
          ? HealthReadResult.success(steps)
          : HealthReadResult.empty();
    } catch (_) {
      return HealthReadResult.error();
    }
  }

  Future<HealthReadResult<double>> getSleepForDate(DateTime date) async {
    try {
      await _ensureConfigured();
      // Attribute complete session-duration records to their local end date.
      // This is a session-duration fallback, not a claim of stage-based time asleep.
      final midnight = DateTime(date.year, date.month, date.day);
      final now = DateTime.now();
      if (midnight.isAfter(now)) return HealthReadResult.empty();
      final start = DateTime(date.year, date.month, date.day - 1);
      final nextDay = DateTime(date.year, date.month, date.day + 1);
      final end = nextDay.isAfter(now) ? now : nextDay;

      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_SESSION],
        startTime: start,
        endTime: end,
      );

      healthData.removeWhere(
        (point) =>
            point.dateTo.isBefore(midnight) || !point.dateTo.isBefore(nextDay),
      );
      if (healthData.isEmpty) return HealthReadResult.empty();

      // Deduplicate overlapping sleep sessions
      healthData.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));
      double totalMinutes = 0;
      DateTime? currentStart;
      DateTime? currentEnd;

      for (final data in healthData) {
        final actualStart = data.dateFrom;
        final actualEnd = data.dateTo.isAfter(now) ? now : data.dateTo;
        if (actualStart.isAfter(actualEnd) ||
            actualStart.isAtSameMomentAs(actualEnd)) {
          continue;
        }

        if (currentStart == null) {
          currentStart = actualStart;
          currentEnd = actualEnd;
        } else {
          if (actualStart.isBefore(currentEnd!)) {
            // Overlapping, extend currentEnd if this session ends later
            if (actualEnd.isAfter(currentEnd)) {
              currentEnd = actualEnd;
            }
          } else {
            // No overlap, add previous interval and start new
            totalMinutes += currentEnd.difference(currentStart).inMinutes;
            currentStart = actualStart;
            currentEnd = actualEnd;
          }
        }
      }
      if (currentStart != null && currentEnd != null) {
        totalMinutes += currentEnd.difference(currentStart).inMinutes;
      }

      return HealthReadResult.success(
        double.parse((totalMinutes / 60).toStringAsFixed(1)),
      );
    } catch (_) {
      return HealthReadResult.error();
    }
  }

  /// Whether the 90-day backfill has already been done.
  bool get isBackfillDone {
    final config = _isar.appConfigs
        .where()
        .keyEqualTo(_backfillDoneKey)
        .findFirstSync();
    return config?.value == 'true';
  }

  /// Persist each completed batch before checkpointing it. A failed metric keeps
  /// its day pending so a partial read never marks the entire history complete.
  Future<void> backfillInBatches({
    required Future<void> Function(List<HealthDailyData>) persist,
    required bool Function() isCurrent,
    bool requestAccess = false,
  }) async {
    final database = _isar;
    if (isBackfillDone || !isCurrent()) return;
    if (!await isAuthorized() || !isCurrent()) return;
    if (requestAccess && !await requestHistoryAccess()) return;
    final now = DateTime.now();
    final anchorKey = 'health_connect_backfill_anchor';
    final completedKey = 'health_connect_backfill_days';
    String? readConfig(String key) =>
        database.appConfigs.where().keyEqualTo(key).findFirstSync()?.value;
    final anchor =
        DateTime.tryParse(readConfig(anchorKey) ?? '') ??
        DateTime(now.year, now.month, now.day);
    Set<String> completed = {};
    try {
      completed = (jsonDecode(readConfig(completedKey) ?? '[]') as List)
          .whereType<String>()
          .toSet();
    } catch (_) {}
    for (int offset = 1; offset <= 90 && isCurrent(); offset += 7) {
      final batch = <HealthDailyData>[];
      final finished = <String>[];
      for (int i = offset; i < offset + 7 && i <= 90; i++) {
        if (!isCurrent()) return;
        final date = DateTime(anchor.year, anchor.month, anchor.day - i);
        final key = DateFormat('yyyy-MM-dd').format(date);
        if (completed.contains(key)) continue;
        final data = await readDate(date);
        if (!isCurrent()) return;
        batch.add(data);
        if (data.stepsResult.status != HealthStatus.error &&
            data.sleepResult.status != HealthStatus.error)
          finished.add(key);
      }
      if (batch.isEmpty) continue;
      await persist(batch);
      if (!isCurrent() || !identical(database, _isar)) return;
      completed.addAll(finished);
      await database.writeTxn(() async {
        if (!isCurrent() || !identical(database, _isar)) return;
        await database.appConfigs.putAll([
          AppConfig(
            key: anchorKey,
            value: DateFormat('yyyy-MM-dd').format(anchor),
          ),
          AppConfig(key: completedKey, value: jsonEncode(completed.toList())),
          if (completed.length == 90)
            AppConfig(key: _backfillDoneKey, value: 'true'),
        ]);
      });
    }
  }

  Future<HealthDailyData> readDate(DateTime date) async {
    final results = await Future.wait([
      getStepsForDate(date),
      getSleepForDate(date),
    ]);
    return HealthDailyData(
      dateStr: DateFormat('yyyy-MM-dd').format(date),
      stepsResult: results[0] as HealthReadResult<int>,
      sleepResult: results[1] as HealthReadResult<double>,
    );
  }

  /// Collect history without marking it persisted. Only backfillInBatches may
  /// advance checkpoints after its persistence callback has succeeded.
  Future<List<HealthDailyData>> backfillLast90Days() async {
    if (isBackfillDone || !await isAuthorized()) return [];
    final database = _isar;
    final now = DateTime.now();
    final results = <HealthDailyData>[];
    for (var i = 1; i <= 90; i++) {
      if (!identical(database, _isar)) break;
      results.add(await readDate(DateTime(now.year, now.month, now.day - i)));
    }
    return results;
  }

  Future<void> markBackfillDone() async {
    final database = _isar;
    final config = database.appConfigs
        .where()
        .keyEqualTo('health_connect_backfill_days')
        .findFirstSync();
    final List<dynamic> completed;
    try {
      completed = jsonDecode(config?.value ?? '[]') as List<dynamic>;
    } catch (_) {
      return;
    }
    if (completed.toSet().length != 90) return;
    await database.writeTxn(() async {
      if (!identical(database, _isar)) return;
      await database.appConfigs.put(
        AppConfig(key: _backfillDoneKey, value: 'true'),
      );
    });
  }

  Future<List<HealthDailyData>> syncLast7Days() async {
    final List<HealthDailyData> results = [];
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd');

    for (int i = 0; i <= 6; i++) {
      final date = DateTime(now.year, now.month, now.day - i);
      final dateStr = dateFormat.format(date);

      final steps = await getStepsForDate(date);
      final sleep = await getSleepForDate(date);

      if (steps.status != HealthStatus.error ||
          sleep.status != HealthStatus.error) {
        results.add(
          HealthDailyData(
            dateStr: dateStr,
            stepsResult: steps,
            sleepResult: sleep,
          ),
        );
      }
    }

    return results;
  }

  Future<HealthDailyData?> syncToday() async {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final steps = await getTodaySteps();
    final sleep = await getSleepForDate(now);

    if (steps.status != HealthStatus.error ||
        sleep.status != HealthStatus.error) {
      return HealthDailyData(
        dateStr: dateStr,
        stepsResult: steps,
        sleepResult: sleep,
      );
    }
    return null;
  }

  /// Try reading today's steps to verify permission.
  /// [hasPermissions] is unreliable on Android Health Connect after process death.
  Future<bool> canReadSteps() async {
    try {
      final steps = await getTodaySteps();
      return steps.status != HealthStatus.error;
    } catch (_) {
      return false;
    }
  }
}

class HealthDailyData {
  final String dateStr;
  final HealthReadResult<int> stepsResult;
  final HealthReadResult<double> sleepResult;

  HealthDailyData({
    required this.dateStr,
    required this.stepsResult,
    required this.sleepResult,
  });
}
