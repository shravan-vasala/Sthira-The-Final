import '../services/cloud_record_store.dart';
import 'dart:convert';
import 'package:isar/isar.dart';
import '../models/workout_plan.dart';
import '../models/workout_session.dart';
import '../models/daily_log.dart';
import '../models/user_profile.dart';
import '../interfaces/i_cloud_sync_service.dart';
import '../models/sync_queue_item.dart';
import '../utils/seed_migration_manager.dart';

class WorkoutRepository {
  late Isar _isar;
  ICloudSyncService? _sync;

  void attachSync(ICloudSyncService sync) => _sync = sync;
  Future<void> detachSync() async {
    _sync = null;
  }

  Future<void> init(Isar isar) async {
    _isar = isar;
    await _seedIfEmpty();
    final changed = _isar.workoutPlans
        .where()
        .findAllSync()
        .where((plan) => plan.ensureExerciseIds())
        .toList();
    if (changed.isNotEmpty) {
      await _isar.writeTxn(() async => _isar.workoutPlans.putAll(changed));
    }
  }

  Future<void> _seedIfEmpty() async {
    await SeedMigrationManager.seedOrMigrateWorkouts(
      _isar,
      'assets/data/seed_workout_plan.json',
    );
  }

  List<WorkoutPlan> getAllPlans() {
    final plans = _isar.workoutPlans.where().findAllSync();
    for (final plan in plans) {
      plan.ensureExerciseIds();
    }
    return plans;
  }

  WorkoutPlan? getPlan(String key) {
    final plan = _isar.workoutPlans
        .where()
        .planNameEqualTo(key)
        .findFirstSync();
    plan?.ensureExerciseIds();
    return plan;
  }

  /// Resolves the plan for [preferredKey], falling back to `beginner_plan`
  /// then the first stored plan (same pattern as meal plans).
  WorkoutPlan? getActivePlan({String? preferredKey}) {
    if (_isar.workoutPlans.where().countSync() == 0) return null;
    if (preferredKey != null) {
      final preferred = getPlan(preferredKey);
      if (preferred != null) return preferred;
    }
    return getPlan('beginner_plan') ?? getAllPlans().first;
  }

  WorkoutDay? getWorkoutDay(String dayId) {
    final plans = getAllPlans();
    for (final plan in plans) {
      for (final day in plan.days) {
        if (day.dayId == dayId) return day;
      }
    }
    return null;
  }

  Future<void> savePlan(String key, WorkoutPlan plan) async {
    plan.ensureExerciseIds();
    final database = _isar;
    final sync = _sync;
    final existing = getPlan(key);
    if (existing != null) {
      plan.id = existing.id;
    }
    await database.writeTxn(() async {
      if (!identical(_isar, database))
        throw StateError('The active account changed.');
      await database.workoutPlans.put(plan);
      if (!identical(_isar, database))
        throw StateError('The active account changed.');
      if (database.name != 'guest') {
        await database.syncQueueItems.put(
          SyncQueueItem(
            uid: database.name,
            collection: 'workout_plans',
            docId: key,
            payload: jsonEncode(plan.toJson()),
            timestamp: DateTime.now(),
          ),
        );
      }
    });
    if (identical(_isar, database) && identical(_sync, sync))
      sync?.triggerFlush();
  }

  Future<void> renamePlan(String oldKey, String newKey, String jsonStr) async {
    final database = _isar;
    final sync = _sync;
    final existing = getPlan(oldKey);
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    final newPlan = WorkoutPlan.fromJson(map);

    await database.writeTxn(() async {
      if (!identical(_isar, database))
        throw StateError('The active account changed.');
      if (existing != null) {
        await database.workoutPlans.delete(existing.id);
      }
      await database.workoutPlans.put(newPlan);
      if (!identical(_isar, database))
        throw StateError('The active account changed.');
      if (database.name != 'guest') {
        await database.syncQueueItems.put(
          SyncQueueItem(
            uid: database.name,
            collection: '_delete_/workout_plans',
            docId: oldKey,
            payload: '{}',
            timestamp: DateTime.now(),
          ),
        );
        await database.syncQueueItems.put(
          SyncQueueItem(
            uid: database.name,
            collection: 'workout_plans',
            docId: newKey,
            payload: jsonEncode(newPlan.toJson()),
            timestamp: DateTime.now(),
          ),
        );
      }
    });
    if (identical(_isar, database) && identical(_sync, sync))
      sync?.triggerFlush();
  }

  Future<void> savePlanJson(String key, String jsonStr) async {
    // Validate JSON first
    final dynamic decoded = jsonDecode(jsonStr);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Root JSON must be an object');
    }
    final map = decoded;

    if (map['planName'] == null || map['planName'].toString().trim().isEmpty) {
      throw const FormatException('Missing or empty "planName"');
    }

    final duration = map['durationWeeks'];
    if (duration != null &&
        (duration is! int || duration < 1 || duration > 104)) {
      throw const FormatException(
        'Program length must be 1 to 104 whole weeks.',
      );
    }
    final days = map['days'];
    final weeks = map['weeks'];

    if (days == null && weeks == null) {
      throw const FormatException('Must contain either "days" or "weeks"');
    }

    if (days != null && days is! List) {
      throw const FormatException('"days" must be an array');
    }

    if (weeks != null) {
      if (weeks is! List) {
        throw const FormatException('"weeks" must be an array');
      }
      if (weeks.length > 104) {
        throw const FormatException('A program can contain up to 104 weeks.');
      }
      if (weeks.isEmpty) {
        throw const FormatException('"weeks" cannot be empty');
      }

      int expectedWeekNumber = 1;
      for (int i = 0; i < weeks.length; i++) {
        final w = weeks[i];
        if (w is! Map<String, dynamic>) {
          throw FormatException('Week at index $i is not an object');
        }

        final wn = w['weekNumber'];
        if (wn != null) {
          if (wn != expectedWeekNumber) {
            throw FormatException(
              'Expected weekNumber $expectedWeekNumber but got $wn',
            );
          }
        } else {
          w['weekNumber'] = expectedWeekNumber;
        }
        expectedWeekNumber++;

        final weekDays = w['days'];
        if (weekDays == null || weekDays is! List) {
          throw FormatException(
            'Week ${w['weekNumber']} must have a "days" array',
          );
        }
      }
    }

    // Validation for days structure - we'll collect all days from weeks or root days
    final List<dynamic> allDaysToValidate = [];
    if (days != null) allDaysToValidate.addAll(days);
    if (weeks != null) {
      for (final w in weeks) {
        allDaysToValidate.addAll(w['days']);
      }
    }

    for (int i = 0; i < allDaysToValidate.length; i++) {
      final day = allDaysToValidate[i];
      if (day is! Map<String, dynamic>) {
        throw FormatException('Day at index $i is not an object');
      }

      if (day['dayId'] == null || day['dayId'].toString().trim().isEmpty) {
        throw const FormatException('Every workout day needs a weekday dayId.');
      }

      final sections = day['sections'];
      if (sections != null && sections is! List) {
        throw FormatException(
          '"sections" in day "${day['dayName'] ?? day['dayId']}" must be an array',
        );
      }

      if (sections != null) {
        for (final section in sections) {
          if (section is! Map<String, dynamic>) {
            throw const FormatException('Each section must be an object');
          }
          final exercises = section['exercises'];
          if (exercises != null && exercises is! List) {
            throw FormatException(
              '"exercises" in section "${section['title'] ?? 'unknown'}" must be an array',
            );
          }

          if (exercises != null) {
            for (final ex in exercises) {
              if (ex is! Map<String, dynamic>) {
                throw const FormatException('Each exercise must be an object');
              }
              final name = ex['name']?.toString() ?? '';
              if (name.trim().isEmpty) {
                throw const FormatException('An exercise is missing a "name"');
              }
              final reps = ex['reps'];
              final duration = ex['durationSeconds'];
              if ((reps == null || (reps is List && reps.isEmpty)) &&
                  (duration == null || duration <= 0)) {
                throw FormatException(
                  'Exercise "$name" is missing "reps" or valid "durationSeconds"',
                );
              }

              final yt = ex['youtubeUrl']?.toString() ?? '';
              if (yt.isNotEmpty) {
                if (!yt.contains('youtube.com/watch') &&
                    !yt.contains('youtu.be') &&
                    !yt.contains('youtube.com/shorts')) {
                  throw FormatException(
                    'Invalid YouTube URL format for exercise "$name". Use youtube.com/watch, youtu.be, or shorts',
                  );
                }
              }

              if (ex['instanceId'] == null ||
                  ex['instanceId'].toString().trim().isEmpty) {
                // Assigned deterministically by WorkoutPlan.fromJson below.
              }
            }
          }
        }
      }
    }
    if (map['planName'] != key) {
      throw const FormatException('Plan name must match the save key.');
    }
    final previous = getPlan(key);
    map['source'] = 'user';
    map.remove('seedVersion');
    if (map['basedOnPlanName'] == null) {
      if (previous?.basedOnPlanName != null) {
        map['basedOnPlanName'] = previous!.basedOnPlanName;
      } else if (previous?.source == 'seed' || previous?.source == 'public') {
        map['basedOnPlanName'] = previous!.planName;
      }
    }
    final plan = WorkoutPlan.fromJson(map);
    await savePlan(key, plan);
  }

  /// Session state, daily summaries and their outbox records commit together.
  Future<void> finishWorkout(
    String date,
    String dayId, {
    String status = 'completed',
  }) async {
    if (!const {'completed', 'partial', 'skipped'}.contains(status)) {
      throw ArgumentError.value(status, 'status', 'Unknown workout status');
    }
    if (dayId.trim().isEmpty || DateTime.tryParse(date) == null) {
      throw ArgumentError('A workout needs a valid date and day.');
    }
    final database = _isar;
    final sync = _sync;
    final key = '${date}_$dayId';
    final now = DateTime.now();
    await database.writeTxn(() async {
      if (!identical(_isar, database)) {
        throw StateError('The active account changed.');
      }
      final existingSession = await database.workoutSessions
          .where()
          .keyEqualTo(key)
          .findFirst();
      final data = existingSession == null
          ? <String, dynamic>{}
          : jsonDecode(existingSession.jsonStr) as Map<String, dynamic>;
      data.addAll({
        'finished': true,
        'status': status,
        'finishedAt': now.toIso8601String(),
        'dayId': dayId,
        'date': date,
      });
      final session = WorkoutSession(key: key, jsonStr: jsonEncode(data));
      if (existingSession != null) session.id = existingSession.id;
      final existingLog = await database.dailyLogs
          .where()
          .dateEqualTo(date)
          .findFirst();
      final dailyLog = (existingLog ?? DailyLog(date: date)).copyWith(
        workoutStatus: status,
        workoutDayId: dayId,
        updatedAt: now,
      );
      if (existingLog != null) dailyLog.id = existingLog.id;
      await database.workoutSessions.put(session);
      await database.dailyLogs.put(dailyLog);
      // The first saved session starts the program on its logged date.
      // Keep this with the session so a partial save cannot lose the start date.
      final existingProfile = await database.userProfiles.where().findFirst();
      UserProfile? startedProfile;
      if (existingProfile != null && existingProfile.planStartDate == null) {
        final sessionDate = DateTime.parse(date);
        startedProfile = existingProfile.copyWith(
          planStartDate: DateTime(
            sessionDate.year,
            sessionDate.month,
            sessionDate.day,
          ),
        )..id = existingProfile.id;
        await database.userProfiles.put(startedProfile);
      }
      if (database.name != 'guest') {
        await database.syncQueueItems.putAll([
          SyncQueueItem(
            uid: database.name,
            collection: 'workout_sessions',
            docId: key,
            payload: jsonEncode(data),
            timestamp: now,
          ),
          SyncQueueItem(
            uid: database.name,
            collection: 'daily_logs',
            docId: date,
            payload: jsonEncode(dailyLog.toJson()),
            timestamp: now,
          ),
          if (startedProfile != null)
            SyncQueueItem(
              uid: database.name,
              collection: '_profile_',
              docId: 'profile',
              payload: jsonEncode(startedProfile.toJson()),
              timestamp: now,
            ),
        ]);
      }
      if (!identical(_isar, database)) {
        throw StateError('The active account changed.');
      }
    });
    if (identical(_isar, database) && identical(_sync, sync)) {
      sync?.triggerFlush();
    }
  }

  bool isWorkoutFinished(String date, String dayId) {
    final key = '${date}_$dayId';
    final existingSession = _isar.workoutSessions
        .where()
        .keyEqualTo(key)
        .findFirstSync();
    if (existingSession == null) return false;
    final data = jsonDecode(existingSession.jsonStr) as Map<String, dynamic>;
    return data['finished'] as bool? ?? false;
  }

  String? getRawPlanJson(String key) {
    final plan = getPlan(key);
    if (plan == null) return null;
    return jsonEncode(plan.toJson());
  }

  List<String> getPlanKeys() {
    final plans = _isar.workoutPlans.where().findAllSync();
    return plans.map((p) => p.planName).toList();
  }

  // ── Cloud sync helpers ──

  Future<void> importPlansFromCloud(
    Map<String, Map<String, dynamic>> cloudData,
  ) async {
    final database = _isar;
    await CloudRecordStore(database).apply(
      'workout_plans',
      cloudData,
      isCurrent: () => identical(_isar, database),
    );
  }

  /// Fetches global/public workout plans from Firebase and merges them locally.
  Future<void> fetchGlobalPlans() async {
    final database = _isar;
    final sync = _sync;
    if (sync == null) return;
    final data = await sync.pullGlobalCollection('public_workout_plans');
    if (!identical(_isar, database) || !identical(_sync, sync)) return;
    await database.writeTxn(() async {
      for (final entry in data.entries) {
        final plan = WorkoutPlan.fromJson(
          entry.value,
        ).copyWith(source: 'public');
        if (plan.planName != entry.key) continue;
        final existing = await database.workoutPlans
            .where()
            .planNameEqualTo(entry.key)
            .findFirst();
        if (existing != null &&
            (existing.source != 'public' ||
                (existing.seedVersion ?? 0) >= (plan.seedVersion ?? 0)))
          continue;
        if (existing != null) plan.id = existing.id;
        await database.workoutPlans.put(plan);
      }
    });
  }

  /// Fetches the user's personal workout plans from Firebase and merges them locally.
  Future<void> fetchUserPlans() async {
    final database = _isar;
    final sync = _sync;
    if (sync == null) return;
    final data = await sync.pullCollection('workout_plans');
    if (!identical(_isar, database) || !identical(_sync, sync)) return;
    await CloudRecordStore(
      database,
    ).apply('workout_plans', data, isCurrent: () => identical(_isar, database));
  }

  Future<void> importSessionsFromCloud(
    Map<String, Map<String, dynamic>> cloudData,
  ) async {
    final database = _isar;
    await CloudRecordStore(database).apply(
      'workout_sessions',
      cloudData,
      isCurrent: () => identical(_isar, database),
    );
  }

  Map<String, Map<String, dynamic>> exportPlansForCloud() {
    final result = <String, Map<String, dynamic>>{};
    final plans = getAllPlans();
    for (final plan in plans) {
      result[plan.planName] = plan.toJson();
    }
    return result;
  }

  Map<String, Map<String, dynamic>> exportSessionsForCloud() {
    final result = <String, Map<String, dynamic>>{};
    final sessions = _isar.workoutSessions.where().findAllSync();
    for (final session in sessions) {
      result[session.key] = jsonDecode(session.jsonStr) as Map<String, dynamic>;
    }
    return result;
  }
}
