import '../services/cloud_record_store.dart';
import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:isar/isar.dart';
import '../models/daily_meal_log.dart';
import '../models/meal_plan.dart';
import '../interfaces/i_cloud_sync_service.dart';
import '../models/sync_queue_item.dart';
import 'package:flutter/foundation.dart';
import '../utils/seed_migration_manager.dart';

class MealRepository {
  late Isar _isar;
  ICloudSyncService? _sync;

  int _syncGeneration = 0;
  String? _attachedUid;
  final List<StreamSubscription> _syncSubscriptions = [];
  final Map<String, DateTime> _localEdits = {};
  final _localMealDays = StreamController<String>.broadcast(sync: true);

  /// A first recorded meal saved locally; cloud/restore writes stay silent.
  Stream<String> get watchLocalMealDays => _localMealDays.stream;

  void _notifyLocalMealDay(Isar database, String date, bool newlyRecorded) {
    if (newlyRecorded &&
        identical(database, _isar) &&
        !_localMealDays.isClosed) {
      _localMealDays.add(date);
    }
  }

  String defaultPlanName = "Meal Plan";

  Stream<void> get watchUpdates =>
      _isar.dailyMealLogs.watchLazy(fireImmediately: true);

  Future<void> detachSync() async {
    _syncGeneration++;
    _attachedUid = null;
    final toCancel = List<StreamSubscription>.from(_syncSubscriptions);
    _syncSubscriptions.clear();
    for (final sub in toCancel) {
      try {
        await sub.cancel();
      } catch (e) {
        debugPrint('MealRepository: Error cancelling sync subscription: $e');
      }
    }
    _sync = null;
  }

  Future<void> attachSync(ICloudSyncService sync, {bool listen = true}) async {
    await detachSync();
    final generation = ++_syncGeneration;
    final database = _isar;
    _sync = sync;
    _attachedUid = sync.currentUid;
    if (!listen || !sync.canSync) return;
    _syncSubscriptions.add(
      sync
          .streamCollection('meal_logs')
          .asyncMap((snapshot) async {
            if (generation != _syncGeneration || !identical(_isar, database))
              return;
            await CloudRecordStore(database).apply(
              'meal_logs',
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
    _syncSubscriptions.add(
      sync
          .streamCollection('meal_plans')
          .asyncMap((snapshot) async {
            if (generation != _syncGeneration || !identical(_isar, database))
              return;
            await CloudRecordStore(database).apply(
              'meal_plans',
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
    _localMealDays.close();
  }

  Future<void> init(Isar isar) async {
    _isar = isar;
    _localEdits.clear();

    // Quick migration to rename the default plan if the user disliked it.
    final existingPlan = _isar.mealPlans
        .where()
        .planNameEqualTo('standard_plan')
        .findFirstSync();
    if (existingPlan != null &&
        existingPlan.planName == '1200 kcal Cutting Plan') {
      final updatedPlan = existingPlan.copyWith(
        planName: 'Daily Nutrition Plan',
      );
      updatedPlan.id = existingPlan.id;
      await _isar.writeTxn(() async {
        await _isar.mealPlans.put(updatedPlan);
      });
    }

    await _seedIfEmpty();
  }

  Future<void> _seedIfEmpty() async {
    await SeedMigrationManager.seedOrMigrateMeals(
      _isar,
      'assets/data/seed_meal_plan.json',
    );

    // Setup defaultPlanName referencing either the migrated seed plan or the known fallback expert plan
    final plan = _isar.mealPlans
        .filter()
        .planNameStartsWith('Meal Plan')
        .findFirstSync();
    if (plan != null) {
      defaultPlanName = plan.planName;
    }
  }

  DailyMealLog getDailyLog(String date) {
    return _isar.dailyMealLogs.where().dateEqualTo(date).findFirstSync() ??
        DailyMealLog(date: date);
  }

  bool isMealLogged(String date, String slotId) {
    final log = getDailyLog(date);
    final slot = log.customSlots[slotId];
    return slot?.isLogged ?? false;
  }

  Stream<DailyMealLog?> watchDailyLog(String date) {
    return _isar.dailyMealLogs
        .where()
        .dateEqualTo(date)
        .watch(fireImmediately: true)
        .map((logs) {
          return logs.isNotEmpty ? logs.first : null;
        });
  }

  List<DailyMealLog> getAllLogs() {
    return _isar.dailyMealLogs.where().findAllSync();
  }

  List<DailyMealLog> getLogsInRange(String start, String end) {
    return _isar.dailyMealLogs
        .filter()
        .dateGreaterThan(start, include: true)
        .and()
        .dateLessThan(end, include: true)
        .sortByDate()
        .findAllSync();
  }

  Future<void> saveDailyLog(DailyMealLog log) async {
    final database = _isar;
    final sync = _sync;
    _localEdits[log.date] = DateTime.now();
    final existing = database.dailyMealLogs
        .where()
        .dateEqualTo(log.date)
        .findFirstSync();
    if (existing != null) {
      log.id = existing.id;
    }
    await database.writeTxn(() async {
      log.updatedAt = DateTime.now();
      await database.dailyMealLogs.put(log);
      final payload = log.toJson();

      if (database.name != 'guest') {
        await database.syncQueueItems.put(
          SyncQueueItem(
            uid: database.name,
            collection: 'meal_logs',
            docId: log.date,
            payload: jsonEncode(payload),
            timestamp: DateTime.now(),
          ),
        );
      }
    });
    _notifyLocalMealDay(
      database,
      log.date,
      (existing?.loggedSlotsCount ?? 0) == 0 && log.loggedSlotsCount > 0,
    );
    sync?.triggerFlush();
  }

  Future<void> saveMealSlot(
    String date,
    String slotId,
    MealSlotLog slotLog,
  ) async {
    final database = _isar;
    final sync = _sync;
    _localEdits[date] = DateTime.now();
    var newlyRecorded = false;
    await database.writeTxn(() async {
      final currentLog =
          await database.dailyMealLogs.where().dateEqualTo(date).findFirst() ??
          DailyMealLog(date: date);
      final updatedSlots = Map<String, MealSlotLog>.from(
        currentLog.customSlots,
      );
      updatedSlots[slotId] = slotLog;

      final updated = currentLog.copyWith(customSlots: updatedSlots);
      updated.id = currentLog.id;
      newlyRecorded =
          currentLog.loggedSlotsCount == 0 && updated.loggedSlotsCount > 0;

      updated.updatedAt = DateTime.now();
      await database.dailyMealLogs.put(updated);
      final payload = updated.toJson();

      if (database.name != 'guest') {
        await database.syncQueueItems.put(
          SyncQueueItem(
            uid: database.name,
            collection: 'meal_logs',
            docId: updated.date,
            payload: jsonEncode(payload),
            timestamp: DateTime.now(),
          ),
        );
      }
    });
    _notifyLocalMealDay(database, date, newlyRecorded);
    sync?.triggerFlush();
  }

  /// Adds one calculated item without replacing an existing meal or assuming
  /// old items still contain the nutrition needed to rebuild its totals.
  Future<void> appendMealItem(
    String date,
    String slotId,
    MealItemLog item, {
    String? slotName,
    String? slotEmoji,
  }) async {
    // Account transitions reinitialize this repository instance. Pin the
    // database for every read/write belonging to this one transaction.
    final isar = _isar;
    final sync = _sync;
    final suppliedNutrition = item.computedNutrition;
    if (suppliedNutrition == null ||
        [
          suppliedNutrition.kcal,
          suppliedNutrition.proteinG,
          suppliedNutrition.carbsG,
          suppliedNutrition.fatG,
        ].any((value) => !value.isFinite || value < 0)) {
      throw ArgumentError.value(
        item,
        'item',
        'A complete, nonnegative nutrition snapshot is required.',
      );
    }
    final snapshot = item.copy();
    final nutrition = snapshot.computedNutrition!;

    _localEdits[date] = DateTime.now();
    var newlyRecorded = false;
    await isar.writeTxn(() async {
      // Read inside the transaction so concurrent barcode/manual additions
      // append to the latest slot instead of overwriting one another.
      final currentLog =
          await isar.dailyMealLogs.where().dateEqualTo(date).findFirst() ??
          DailyMealLog(date: date);
      final existing = currentLog.customSlots[slotId];
      final updatedSlots = Map<String, MealSlotLog>.from(
        currentLog.customSlots,
      );
      updatedSlots[slotId] = MealSlotLog(
        name: existing?.name ?? slotName,
        emoji: existing?.emoji ?? slotEmoji,
        photoPath: existing?.photoPath,
        photoPaths: List<String>.of(existing?.photoPaths ?? const []),
        items: [...?existing?.items, snapshot],
        totalCalories: (existing?.totalCalories ?? 0) + nutrition.kcal.round(),
        totalProtein: (existing?.knownProtein ?? 0) + nutrition.proteinG,
        totalCarbs: (existing?.knownCarbs ?? 0) + nutrition.carbsG,
        totalFat: (existing?.knownFat ?? 0) + nutrition.fatG,
        confidence: existing?.confidence,
        caloriesComplete: existing?.hasCompleteCalories ?? true,
        macrosComplete: existing?.hasCompleteMacros ?? true,
      );
      final updated = currentLog.copyWith(customSlots: updatedSlots);
      updated.id = currentLog.id;
      newlyRecorded =
          currentLog.loggedSlotsCount == 0 && updated.loggedSlotsCount > 0;
      updated.updatedAt = DateTime.now();
      await isar.dailyMealLogs.put(updated);

      final timestamp = DateTime.now();
      final payload = updated.toJson();
      if (isar.name != 'guest') {
        await isar.syncQueueItems.put(
          SyncQueueItem(
            uid: isar.name,
            collection: 'meal_logs',
            docId: date,
            payload: jsonEncode(payload),
            timestamp: timestamp,
          ),
        );
      }
    });
    _notifyLocalMealDay(isar, date, newlyRecorded);
    try {
      if (identical(_isar, isar) && identical(_sync, sync)) {
        sync?.triggerFlush();
      }
    } catch (error) {
      // The meal and queue entry are already durable. A scheduler failure must
      // not report the addition as failed and cause a duplicate on retry.
      debugPrint('MealRepository: Saved meal; sync scheduling failed: $error');
    }
  }

  Future<void> clearMealSlot(String date, String slotId) async {
    final database = _isar;
    final sync = _sync;
    _localEdits[date] = DateTime.now();
    await database.writeTxn(() async {
      final currentLog =
          await database.dailyMealLogs.where().dateEqualTo(date).findFirst() ??
          DailyMealLog(date: date);
      final updatedSlots = Map<String, MealSlotLog>.from(
        currentLog.customSlots,
      );
      updatedSlots.remove(slotId);

      final updated = currentLog.copyWith(customSlots: updatedSlots);
      updated.id = currentLog.id;

      updated.updatedAt = DateTime.now();
      await database.dailyMealLogs.put(updated);
      final payload = updated.toJson();

      if (database.name != 'guest') {
        await database.syncQueueItems.put(
          SyncQueueItem(
            uid: database.name,
            collection: 'meal_logs',
            docId: updated.date,
            payload: jsonEncode(payload),
            timestamp: DateTime.now(),
          ),
        );
      }
    });
    sync?.triggerFlush();
  }

  MealPlan? getMealPlan(String key) {
    return _isar.mealPlans.where().planNameEqualTo(key).findFirstSync();
  }

  Future<void> savePlanJson(String key, String jsonStr) async {
    final database = _isar;
    final sync = _sync;
    final dynamic decoded = jsonDecode(jsonStr);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Root JSON must be an object');
    }
    final map = decoded;
    if (map['planName'] == null || map['planName'].toString().trim().isEmpty) {
      throw const FormatException('Missing or empty "planName"');
    }
    final meals = map['meals'];
    if (meals is! List) {
      throw const FormatException('"meals" must be an array');
    }
    for (int i = 0; i < meals.length; i++) {
      final meal = meals[i];
      if (meal is! Map<String, dynamic>) {
        throw FormatException('Meal at index $i is not an object');
      }

      if (meal['id'] == null || meal['id'].toString().trim().isEmpty) {
        meal['id'] = const Uuid().v4();
      }

      if (meal['nutritionTarget'] != null) {
        throw const FormatException(
          'nutritionTarget describes goals. Supply actual item calories and proteinG/carbsG/fatG instead.',
        );
      }
      final calories = meal['calories'];
      if (calories is! int || calories < 0) {
        throw const FormatException(
          'Meal calories must be a nonnegative whole number.',
        );
      }

      if (meal['suggestions'] != null) {
        if (meal['suggestions'] is! List) {
          throw FormatException(
            '"suggestions" in meal "${meal['name'] ?? 'unknown'}" must be an array',
          );
        }
        for (final item in meal['suggestions']) {
          if (item is! String) {
            throw FormatException(
              'Suggestion in meal "${meal['name'] ?? 'unknown'}" is not a valid string. Found: ${item.runtimeType}',
            );
          }
        }
      }
    }

    final existing = getMealPlan(key);
    // Saving an imported or customized plan always creates user-owned content.
    // Expert attribution is retained separately from migration ownership.
    map['basedOnPlanName'] ??=
        existing?.basedOnPlanName ??
        (existing?.source == 'seed' ? existing!.planName : null);
    map['source'] = 'user';
    map.remove('seedVersion');
    final plan = MealPlan.fromJson(map);
    if (plan.totalCalories < 0) {
      throw const FormatException('Plan calories must be nonnegative.');
    }

    if (existing != null) {
      plan.id = existing.id;
    }
    await database.writeTxn(() async {
      await database.mealPlans.put(plan);
      if (database.name != 'guest') {
        await database.syncQueueItems.put(
          SyncQueueItem(
            uid: database.name,
            collection: 'meal_plans',
            docId: key,
            payload: jsonEncode(plan.toJson()),
            timestamp: DateTime.now(),
          ),
        );
      }
    });
    sync?.triggerFlush();
  }

  Future<void> renamePlan(String oldKey, String newKey, String jsonStr) async {
    final database = _isar;
    final sync = _sync;
    final existing = getMealPlan(oldKey);
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    map['source'] = 'user';
    map['basedOnPlanName'] ??=
        existing?.basedOnPlanName ??
        (existing?.source == 'seed' ? existing!.planName : null);
    map.remove('seedVersion');
    final newPlan = MealPlan.fromJson(map);

    await database.writeTxn(() async {
      if (existing != null) {
        await database.mealPlans.delete(existing.id);
      }
      await database.mealPlans.put(newPlan);
      if (database.name != 'guest') {
        await database.syncQueueItems.put(
          SyncQueueItem(
            uid: database.name,
            collection: '_delete_/meal_plans',
            docId: oldKey,
            payload: '{}',
            timestamp: DateTime.now(),
          ),
        );
        await database.syncQueueItems.put(
          SyncQueueItem(
            uid: database.name,
            collection: 'meal_plans',
            docId: newKey,
            payload: jsonEncode(newPlan.toJson()),
            timestamp: DateTime.now(),
          ),
        );
      }
    });
    sync?.triggerFlush();
  }

  String? getRawPlanJson(String key) {
    final plan = getMealPlan(key);
    if (plan == null) return null;
    return jsonEncode(plan.toJson());
  }

  List<String> getPlanKeys() {
    final plans = _isar.mealPlans.where().findAllSync();
    return plans.map((p) => p.planName).toList();
  }

  // ── Cloud sync helpers ──

  Future<void> importLogsFromCloud(
    Map<String, Map<String, dynamic>> cloudData,
  ) async {
    final database = _isar;
    await CloudRecordStore(database).apply(
      'meal_logs',
      cloudData,
      isCurrent: () => identical(_isar, database),
    );
  }

  Map<String, Map<String, dynamic>> exportLogsForCloud() {
    final result = <String, Map<String, dynamic>>{};
    final logs = _isar.dailyMealLogs.where().findAllSync();
    for (final log in logs) {
      result[log.date] = log.toJson();
    }
    return result;
  }

  Future<void> importPlansFromCloud(
    Map<String, Map<String, dynamic>> cloudData,
  ) async {
    final database = _isar;
    await CloudRecordStore(database).apply(
      'meal_plans',
      cloudData,
      isCurrent: () => identical(_isar, database),
    );
  }

  Future<void> fetchGlobalPlans() async {
    final database = _isar;
    final sync = _sync;
    if (sync == null) return;
    final data = await sync.pullGlobalCollection('public_meal_plans');
    if (!identical(_isar, database) || !identical(_sync, sync)) return;
    await database.writeTxn(() async {
      for (final entry in data.entries) {
        final plan = MealPlan.fromJson(entry.value).copyWith(source: 'public');
        if (plan.planName != entry.key) continue;
        final existing = await database.mealPlans
            .where()
            .planNameEqualTo(entry.key)
            .findFirst();
        if (existing != null &&
            (existing.source != 'public' ||
                (existing.seedVersion ?? 0) >= (plan.seedVersion ?? 0)))
          continue;
        if (existing != null) plan.id = existing.id;
        await database.mealPlans.put(plan);
      }
    });
  }

  Future<void> fetchUserPlans() async {
    final database = _isar;
    final sync = _sync;
    if (sync == null) return;
    final data = await sync.pullCollection('meal_plans');
    if (!identical(_isar, database) || !identical(_sync, sync)) return;
    await CloudRecordStore(
      database,
    ).apply('meal_plans', data, isCurrent: () => identical(_isar, database));
  }

  Map<String, Map<String, dynamic>> exportPlansForCloud() {
    final result = <String, Map<String, dynamic>>{};
    final plans = _isar.mealPlans.where().findAllSync();
    for (final plan in plans) {
      result[plan.planName] = plan.toJson();
    }
    return result;
  }
}
