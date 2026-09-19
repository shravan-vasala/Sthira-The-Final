import 'dart:io';
import 'dart:ffi';
import 'package:isar/isar.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/workout_plan.dart';
import 'package:trufit_bodamma/models/workout_session.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/meal_plan.dart';
import 'package:trufit_bodamma/models/habit.dart';
import 'package:trufit_bodamma/models/scanned_meal_log.dart';
import 'package:trufit_bodamma/models/progress_photo.dart';
import 'package:trufit_bodamma/models/exercise_log.dart';
import 'package:trufit_bodamma/models/exercise_pr.dart';
import 'package:trufit_bodamma/models/coach_note.dart';
import 'package:trufit_bodamma/models/body_stats.dart';
import 'package:trufit_bodamma/models/badge.dart';
import 'package:trufit_bodamma/models/app_config.dart';
import 'package:trufit_bodamma/models/ai_cache_entry.dart';
import 'package:trufit_bodamma/models/food_search_cache.dart';
import 'package:trufit_bodamma/models/friend.dart';
import 'package:trufit_bodamma/models/sync_queue_item.dart';

Future<Isar> setUpTestIsar() async {
  try {
    await Isar.initializeIsarCore(download: true);
  } catch (e) {
    // ignore: avoid_print
    print('Isar initializeIsarCore failed: $e. Attempting manual download...');
    if (Platform.isLinux) {
      try {
        final request = await HttpClient().getUrl(
          Uri.parse(
            'https://github.com/isar/isar/releases/download/3.1.0+1/libisar_linux_x64.so',
          ),
        );
        final response = await request.close();
        if (response.statusCode == 200) {
          final tempName = 'libisar_${DateTime.now().microsecondsSinceEpoch}.so';
          final file = File('${Directory.systemTemp.path}/$tempName');
          await response.pipe(file.openWrite());
          await Isar.initializeIsarCore(
            libraries: {Abi.linuxX64: file.absolute.path},
            download: false,
          );
        } else {
          // ignore: avoid_print
          print('Manual download failed with status: ${response.statusCode}');
        }
      } catch (e2) {
        // ignore: avoid_print
        print('Manual download also failed: $e2');
      }
    }
  }

  final tempDir = Directory.systemTemp.createTempSync('isar_test_');
  return await Isar.open([
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
    FriendSchema,
    SyncQueueItemSchema,
  ], 
    directory: tempDir.path, 
    name: 'test_${DateTime.now().microsecondsSinceEpoch}_${tempDir.hashCode}',
  );
}

Future<void> tearDownTestIsar(Isar isar) async {
  // Do not use deleteFromDisk: true on Windows as it causes file-lock deadlocks
  try {
    // Watchers in riverpod sometimes take a microtask to cancel.
    // Wrap close in a timeout so test runner NEVER hangs!
    await isar.close().timeout(const Duration(milliseconds: 250));
  } catch (e) {
    // Ignore timeout and lock exceptions during teardowns
  }
}
