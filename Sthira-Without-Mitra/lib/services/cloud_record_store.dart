import 'dart:convert';
import 'package:isar/isar.dart';
import 'cloud_sync_transport.dart';
import '../models/app_config.dart';
import '../models/user_profile.dart';
import '../models/badge.dart';
import '../models/body_stats.dart';
import '../models/coach_note.dart';
import '../models/daily_log.dart';
import '../models/daily_meal_log.dart';
import '../models/exercise_log.dart';
import '../models/exercise_pr.dart';
import '../models/habit.dart';
import '../models/meal_plan.dart';
import '../models/sync_queue_item.dart';
import '../models/workout_plan.dart';
import '../models/workout_session.dart';

/// Shared private-data reconciliation. Pending local intent always wins until
/// acknowledged. Only server-authoritative removals delete previously seen rows.
class CloudRecordStore {
  CloudRecordStore(this.database);
  final Isar database;

  static String versionKey(String collection, String docId) =>
      'cloud_version_${base64Url.encode(utf8.encode('$collection/$docId'))}';

  static DateTime? recordVersion(Map<String, dynamic> json) {
    final sync = DateTime.tryParse('${json['_syncUpdatedAt']}');
    final model = DateTime.tryParse('${json['updatedAt']}');
    if (sync == null) return model;
    if (model == null || sync.isAfter(model)) return sync;
    return model;
  }

  static Future<void> rememberVersion(
    Isar database,
    String collection,
    String docId,
    DateTime version, {
    bool deleted = false,
  }) async {
    await database.appConfigs.put(
      AppConfig(
        key: versionKey(collection, docId),
        value: jsonEncode({
          'updatedAt': version.toUtc().toIso8601String(),
          'deleted': deleted,
        }),
      ),
    );
  }

  late final Map<String, _CloudBinding> _bindings = {
    'daily_logs': _Binding<DailyLog>(
      database.dailyLogs,
      (key, json) => DailyLog.fromJson(json),
      (v) => v.date,
      (v) => v.toJson(),
      (v) => v.id,
      (v, id) => v.id = id,
      (key) => database.dailyLogs.where().dateEqualTo(key).findFirst(),
    ),
    'meal_logs': _Binding<DailyMealLog>(
      database.dailyMealLogs,
      (key, json) => DailyMealLog.fromJson(json),
      (v) => v.date,
      (v) => v.toJson(),
      (v) => v.id,
      (v, id) => v.id = id,
      (key) => database.dailyMealLogs.where().dateEqualTo(key).findFirst(),
    ),
    'body_stats': _Binding<BodyStats>(
      database.bodyStats,
      (key, json) => BodyStats.fromJson(json),
      (v) => v.date,
      (v) => v.toJson(),
      (v) => v.id,
      (v, id) => v.id = id,
      (key) => database.bodyStats.where().dateEqualTo(key).findFirst(),
    ),
    'workout_plans': _Binding<WorkoutPlan>(
      database.workoutPlans,
      (key, json) => WorkoutPlan.fromJson(json),
      (v) => v.planName,
      (v) => v.toJson(),
      (v) => v.id,
      (v, id) => v.id = id,
      (key) => database.workoutPlans.where().planNameEqualTo(key).findFirst(),
    ),
    'meal_plans': _Binding<MealPlan>(
      database.mealPlans,
      (key, json) => MealPlan.fromJson(json),
      (v) => v.planName,
      (v) => v.toJson(),
      (v) => v.id,
      (v, id) => v.id = id,
      (key) => database.mealPlans.where().planNameEqualTo(key).findFirst(),
    ),
    'habit_config': _Binding<Habit>(
      database.habits,
      (key, json) => Habit.fromJson(json),
      (v) => v.id,
      (v) => v.toJson(),
      (v) => v.idInternal,
      (v, id) => v.idInternal = id,
      (key) => database.habits.where().idEqualTo(key).findFirst(),
    ),
    'habit_completions': _Binding<HabitCompletion>(
      database.habitCompletions,
      (key, json) => HabitCompletion.fromJson(json),
      (v) => v.date,
      (v) => v.toJson(),
      (v) => v.id,
      (v, id) => v.id = id,
      (key) => database.habitCompletions.where().dateEqualTo(key).findFirst(),
    ),
    'exercise_prs': _Binding<ExercisePr>(
      database.exercisePrs,
      (key, json) => ExercisePr.fromJson(json),
      (v) => v.exerciseName,
      (v) => v.toJson(),
      (v) => v.id,
      (v, id) => v.id = id,
      (key) =>
          database.exercisePrs.where().exerciseNameEqualTo(key).findFirst(),
    ),
    'coach_notes': _Binding<CoachNote>(
      database.coachNotes,
      (key, json) => CoachNote.fromJson(json),
      (v) => v.date,
      (v) => v.toJson(),
      (v) => v.id,
      (v, id) => v.id = id,
      (key) => database.coachNotes.where().dateEqualTo(key).findFirst(),
    ),
    'badges': _Binding<Badge>(
      database.badges,
      (key, json) => Badge.fromJson(json),
      (v) => v.id,
      (v) => v.toJson(),
      (v) => v.idInternal,
      (v, id) => v.idInternal = id,
      (key) => database.badges.where().idEqualTo(key).findFirst(),
    ),
    'exercise_logs': _Binding<ExerciseLog>(
      database.exerciseLogs,
      (key, json) => ExerciseLog.fromJson(json),
      (v) => v.key,
      (v) => v.toJson(),
      (v) => v.id,
      (v, id) => v.id = id,
      (key) {
        final split = key.indexOf('_');
        if (split < 0) return Future.value(null);
        return database.exerciseLogs
            .where()
            .dateInstanceIdEqualTo(
              key.substring(0, split),
              key.substring(split + 1),
            )
            .findFirst();
      },
    ),
    'workout_sessions': _Binding<WorkoutSession>(
      database.workoutSessions,
      (key, json) => WorkoutSession(key: key, jsonStr: jsonEncode(json)),
      (v) => v.key,
      (v) => Map<String, dynamic>.from(jsonDecode(v.jsonStr) as Map),
      (v) => v.id,
      (v, id) => v.id = id,
      (key) => database.workoutSessions.where().keyEqualTo(key).findFirst(),
    ),
  };
  Iterable<String> get collections => _bindings.keys;

  Future<void> apply(
    String collection,
    Map<String, Map<String, dynamic>> snapshot, {
    bool Function()? isCurrent,
  }) async {
    final binding = _bindings[collection];
    if (binding == null) throw ArgumentError.value(collection);
    final parsed = <String, Object>{};
    // Parse before opening a transaction; a malformed snapshot cannot partially apply.
    for (final entry in snapshot.entries) {
      final record = binding.parse(entry.key, entry.value);
      if (binding.key(record) != entry.key)
        throw FormatException('Cloud record identity does not match its key');
      parsed[entry.key] = record;
    }
    if (!database.isOpen || isCurrent?.call() == false) return;
    await database.writeTxn(() async {
      if (isCurrent?.call() == false) return;
      if (await database.appConfigs
          .where()
          .keyEqualTo('restore_reconciliation_pending')
          .isNotEmpty())
        return;
      final pending = await database.syncQueueItems
          .where()
          .uidEqualToAnyTimestamp(database.name)
          .findAll();
      if (pending.any(
        (v) => v.collection == '_reconcile_' && v.docId == collection,
      ))
        return;
      final protected = pending
          .where(
            (v) =>
                v.collection == collection ||
                v.collection == '_delete_/$collection',
          )
          .map((v) => v.docId)
          .toSet();
      for (final entry in parsed.entries) {
        if (protected.contains(entry.key)) continue;
        final previous = await binding.find(entry.key);
        final versionConfig = await database.appConfigs
            .where()
            .keyEqualTo(versionKey(collection, entry.key))
            .findFirst();
        final remembered = versionConfig == null
            ? <String, dynamic>{}
            : Map<String, dynamic>.from(jsonDecode(versionConfig.value) as Map);
        final rememberedVersion = DateTime.tryParse(
          '${remembered['updatedAt']}',
        );
        final incomingVersion = recordVersion(snapshot[entry.key]!);
        if (rememberedVersion != null &&
            (incomingVersion == null ||
                incomingVersion.isBefore(rememberedVersion) ||
                (remembered['deleted'] == true &&
                    !incomingVersion.isAfter(rememberedVersion))))
          continue;
        if (previous != null) {
          final oldJson = binding.json(previous);
          final newJson = binding.json(entry.value);
          final oldVersion = recordVersion(oldJson);
          final newVersion = incomingVersion;
          if (oldVersion != null &&
              (newVersion == null || newVersion.isBefore(oldVersion)))
            continue;
          if (jsonEncode(oldJson) == jsonEncode(newJson)) {
            if (incomingVersion != null)
              await rememberVersion(
                database,
                collection,
                entry.key,
                incomingVersion,
              );
            continue;
          }
          binding.setId(entry.value, binding.id(previous));
        }
        if (isCurrent?.call() == false)
          throw StateError('Account changed during cloud import.');
        await binding.put(entry.value);
        if (incomingVersion != null) {
          await rememberVersion(
            database,
            collection,
            entry.key,
            incomingVersion,
          );
        }
      }
      if (snapshot is CloudSnapshot && snapshot.authoritative) {
        final configKey = 'cloud_seen_$collection';
        final config = await database.appConfigs
            .where()
            .keyEqualTo(configKey)
            .findFirst();
        final seen = config == null
            ? <String>{}
            : (jsonDecode(config.value) as List).cast<String>().toSet();
        final removed = {
          if (snapshot.isComplete) ...seen.difference(snapshot.keys.toSet()),
          ...snapshot.removedIds,
        };
        for (final key in removed) {
          if (protected.contains(key)) continue;
          final record = await binding.find(key);
          if (record != null) {
            await binding.delete(binding.id(record));
            await rememberVersion(
              database,
              collection,
              key,
              DateTime.now(),
              deleted: true,
            );
          }
        }
        final nextSeen = snapshot.isComplete
            ? snapshot.keys.toSet()
            : (seen
                ..removeAll(removed)
                ..addAll(snapshot.keys));
        await database.appConfigs.put(
          AppConfig(key: configKey, value: jsonEncode(nextSeen.toList())),
        );
      }
      if (isCurrent?.call() == false)
        throw StateError('Account changed during cloud import.');
    });
  }

  Future<Map<String, Map<String, dynamic>>> export(String collection) =>
      _bindings[collection]!.export();

  /// Queue a complete snapshot before reconciliation deletes any obsolete cloud rows.
  Future<void> enqueueSnapshot({bool replaceCloud = false}) async {
    if (database.name == 'guest') return;
    await database.writeTxn(() async {
      // Read and enqueue in one native transaction: an edit made during hydration
      // must not be superseded by an older snapshot with a newer queue timestamp.
      final snapshots = <String, Map<String, Map<String, dynamic>>>{};
      for (final collection in collections) {
        snapshots[collection] = await export(collection);
      }
      final profile = (await database.userProfiles.where().findFirst())
          ?.toJson();
      if (profile != null) {
        await database.syncQueueItems.put(
          SyncQueueItem(
            uid: database.name,
            collection: '_profile_',
            docId: 'profile',
            payload: jsonEncode(profile),
            timestamp: DateTime.now(),
          ),
        );
      }
      for (final entry in snapshots.entries) {
        for (final record in entry.value.entries) {
          await database.syncQueueItems.put(
            SyncQueueItem(
              uid: database.name,
              collection: entry.key,
              docId: record.key,
              payload: jsonEncode(record.value),
              timestamp: DateTime.now(),
            ),
          );
        }
      }
      if (replaceCloud) {
        for (final entry in snapshots.entries) {
          await database.syncQueueItems.put(
            SyncQueueItem(
              uid: database.name,
              collection: '_reconcile_',
              docId: entry.key,
              payload: jsonEncode({'ids': entry.value.keys.toList()}),
              timestamp: DateTime.now(),
            ),
          );
        }
      }
      await database.appConfigs
          .where()
          .keyEqualTo('restore_reconciliation_pending')
          .deleteAll();
    });
  }
}

abstract class _CloudBinding {
  Object parse(String key, Map<String, dynamic> json);
  String key(Object value);
  Map<String, dynamic> json(Object value);
  int id(Object value);
  void setId(Object value, int id);
  Future<Object?> find(String key);
  Future<void> put(Object value);
  Future<void> delete(int id);
  Future<Map<String, Map<String, dynamic>>> export();
}

class _Binding<T> implements _CloudBinding {
  _Binding(
    this.collection,
    this.fromJson,
    this.readKey,
    this.toJson,
    this.readId,
    this.writeId,
    this.lookup,
  );
  final IsarCollection<T> collection;
  final T Function(String, Map<String, dynamic>) fromJson;
  final String Function(T) readKey;
  final Map<String, dynamic> Function(T) toJson;
  final int Function(T) readId;
  final void Function(T, int) writeId;
  final Future<T?> Function(String) lookup;
  @override
  Object parse(String key, Map<String, dynamic> json) =>
      fromJson(key, json) as Object;
  @override
  String key(Object value) => readKey(value as T);
  @override
  Map<String, dynamic> json(Object value) => toJson(value as T);
  @override
  int id(Object value) => readId(value as T);
  @override
  void setId(Object value, int id) => writeId(value as T, id);
  @override
  Future<Object?> find(String key) async => await lookup(key);
  @override
  Future<void> put(Object value) async {
    await collection.put(value as T);
  }

  @override
  Future<void> delete(int id) async {
    await collection.delete(id);
  }

  @override
  Future<Map<String, Map<String, dynamic>>> export() async {
    final records = await collection.where().findAll();
    return {for (final record in records) readKey(record): toJson(record)};
  }
}
