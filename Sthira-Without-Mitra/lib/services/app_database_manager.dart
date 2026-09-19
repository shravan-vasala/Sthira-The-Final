import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';
import '../models/daily_log.dart';
import '../models/workout_plan.dart';
import '../models/workout_session.dart';
import '../models/daily_meal_log.dart';
import '../models/meal_plan.dart';
import '../models/habit.dart';
import '../models/scanned_meal_log.dart';
import '../models/progress_photo.dart';
import '../models/exercise_log.dart';
import '../models/exercise_pr.dart';
import '../models/coach_note.dart';
import '../models/body_stats.dart';
import '../models/badge.dart';
import '../models/app_config.dart';
import '../models/ai_cache_entry.dart';
import '../models/food_search_cache.dart';
import '../models/user_food_log.dart';
import '../models/friend.dart';
import '../models/sync_queue_item.dart';

class AppDatabaseManager {
  static const List<CollectionSchema> schemas = [
    UserProfileSchema,
    DailyLogSchema,
    WorkoutPlanSchema,
    WorkoutSessionSchema,
    DailyMealLogSchema,
    MealPlanSchema,
    HabitSchema,
    HabitCompletionSchema,
    ScannedMealLogSchema,
    ProgressPhotoSchema,
    ExerciseLogSchema,
    ExercisePrSchema,
    CoachNoteSchema,
    BodyStatsSchema,
    BadgeSchema,
    AppConfigSchema,
    AiCacheEntrySchema,
    FoodSearchCacheSchema,
    UserFoodLogSchema,
    FriendSchema,
    SyncQueueItemSchema,
  ];

  static Future<void> _opening = Future<void>.value();

  /// Serialize opening and the one-time claim of the pre-account database.
  static Future<Isar> openDatabaseForUser(String? uid) async {
    final previous = _opening;
    final completed = Completer<void>();
    _opening = completed.future;
    await previous;
    try {
      return await _openDatabaseForUser(uid);
    } finally {
      completed.complete();
    }
  }

  static Future<Isar> _openDatabaseForUser(String? uid) async {
    final rootDir = await getApplicationDocumentsDirectory();
    final isarName = uid ?? 'guest';
    if (isarName.isEmpty ||
        isarName == '.' ||
        isarName == '..' ||
        isarName.contains('/') ||
        isarName.contains('\\') ||
        isarName.contains(':')) {
      throw ArgumentError.value(uid, 'uid', 'Invalid account identifier.');
    }
    final existing = Isar.getInstance(isarName);
    if (existing != null && existing.isOpen) return existing;
    final targetDir = Directory(p.join(rootDir.path, isarName));
    await targetDir.create(recursive: true);
    final oldFile = File(p.join(rootDir.path, 'default.isar'));
    final targetFile = File(p.join(targetDir.path, '$isarName.isar'));
    final marker = File(p.join(rootDir.path, 'legacy_database_owner.json'));
    Map<String, dynamic>? claim;
    if (await marker.exists()) {
      try {
        final value = jsonDecode(await marker.readAsString());
        if (value is! Map<String, dynamic> ||
            value['owner'] is! String ||
            !const ['pending', 'complete'].contains(value['state'])) {
          throw const FormatException('Invalid ownership marker.');
        }
        claim = value;
      } catch (_) {
        // Preserve the legacy file for recovery, but never guess a new owner.
        claim = {'owner': '', 'state': 'complete'};
        debugPrint(
          'AppDatabaseManager: Legacy ownership marker is unreadable; legacy data was not reassigned.',
        );
      }
    }
    var finishClaim = false;
    if (await oldFile.exists()) {
      if (claim == null) {
        claim = {'owner': isarName, 'state': 'pending', 'version': 1};
        // Persist ownership before the copy. A later account may never claim it.
        await marker.writeAsString(jsonEncode(claim), flush: true);
      }
      if (claim['owner'] == isarName && claim['state'] == 'pending') {
        if (!await targetFile.exists()) {
          final liveLegacy = Isar.getInstance(Isar.defaultName);
          if (liveLegacy?.isOpen == true) {
            throw StateError('Close the legacy database before migrating it.');
          }
          final staging = File(p.join(targetDir.path, 'legacy_migration.tmp'));
          await oldFile.copy(staging.path);
          await staging.rename(targetFile.path);
        }
        finishClaim = true;
      }
    }
    final database = await Isar.open(
      schemas,
      name: isarName,
      directory: targetDir.path,
    );
    if (finishClaim) {
      await marker.writeAsString(
        jsonEncode({'owner': isarName, 'state': 'complete', 'version': 1}),
        flush: true,
      );
    }
    return database;
  }
}
