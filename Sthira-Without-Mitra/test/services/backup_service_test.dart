import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trufit_bodamma/interfaces/i_auth_service.dart';
import 'package:trufit_bodamma/models/app_config.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/exercise_log.dart';
import 'package:trufit_bodamma/models/meal_plan.dart';
import 'package:trufit_bodamma/models/workout_plan.dart';
import 'package:trufit_bodamma/models/friend.dart';
import 'package:trufit_bodamma/models/progress_photo.dart';
import 'package:trufit_bodamma/models/scanned_meal_log.dart';
import 'package:trufit_bodamma/models/sync_queue_item.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/services/app_database_manager.dart';
import 'package:trufit_bodamma/services/backup_service.dart';
import 'package:trufit_bodamma/services/csv_export_service.dart';
import 'package:trufit_bodamma/services/schema_migration_service.dart';

class _Paths extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _Paths(this.path);
  final String path;
  @override
  Future<String?> getApplicationDocumentsPath() async => path;
  @override
  Future<String?> getTemporaryPath() async => path;
}

class _Auth extends Fake implements IAuthService {
  String? account;
  @override
  String? get uid => account;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late Isar database;
  late _Auth auth;
  late BackupService service;
  var serial = 0;
  setUpAll(() async {
    await Isar.initializeIsarCore(download: false);
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('sthira_backup_test_');
    PathProviderPlatform.instance = _Paths(directory.path);
    SharedPreferences.setMockInitialValues({});
    database = await Isar.open(
      AppDatabaseManager.schemas,
      directory: directory.path,
      name: 'backup_test_${serial++}_${DateTime.now().microsecondsSinceEpoch}',
    );
    auth = _Auth();
    service = BackupService(auth, databaseResolver: () => database);
  });
  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });
  Map<String, dynamic> dataFrom(String path) => jsonDecode(
    utf8.decode(
      ZipDecoder()
          .decodeBytes(File(path).readAsBytesSync())
          .findFile('data.json')!
          .content,
    ),
  );
  Future<String> fixture(
    Map<String, dynamic> data, {
    int schema = 5,
    int? total,
    String? uid,
    String? extraName,
  }) async {
    final archive = Archive()
      ..addFile(
        ArchiveFile.bytes(
          'manifest.json',
          utf8.encode(
            jsonEncode({
              'schemaVersion': schema,
              'createdAt': '2026-09-19T12:00:00Z',
              'totalEntries':
                  total ??
                  data.values.fold<int>(
                    0,
                    (n, rows) => n + (rows as List).length,
                  ),
              'uid': uid,
            }),
          ),
        ),
      )
      ..addFile(ArchiveFile.bytes('data.json', utf8.encode(jsonEncode(data))));
    if (extraName != null)
      archive.addFile(ArchiveFile.bytes(extraName, [1, 2, 3]));
    final file = File('${directory.path}/fixture_${serial++}.zip');
    await file.writeAsBytes(ZipEncoder().encode(archive));
    return file.path;
  }

  Map<String, dynamic> emptySnapshot() => {
    for (final name in SchemaMigrationService.collectionNames)
      name: <dynamic>[],
  };

  test(
    'create verify restore round trip retains records, friends, photos and config',
    () async {
      final photo = await File(
        '${directory.path}/meal.jpg',
      ).writeAsBytes([1, 2, 3, 4]);
      await File('${directory.path}/another-account.jpg').writeAsBytes([8, 9]);
      await database.writeTxn(() async {
        await database.userProfiles.put(
          UserProfile(name: 'Asha', photoPath: photo.path),
        );
        await database.dailyLogs.put(DailyLog(date: '2026-09-19', steps: 2222));
        await database.progressPhotos.put(
          ProgressPhoto(path: photo.path, date: '2026-09-19', pose: 'front'),
        );
        await database.dailyMealLogs.put(
          DailyMealLog(
            date: '2026-09-19',
            customSlots: {
              'lunch': MealSlotLog(
                photoPath: photo.path,
                photoPaths: [photo.path],
                totalCalories: 200,
              ),
            },
          ),
        );
        await database.exerciseLogs.put(
          ExerciseLog(
            date: '2026-09-19',
            instanceId: 'pushups_1',
            exerciseName: 'Push-ups',
            sets: [SetLog(setNumber: 1, reps: 12, weight: 0)],
          ),
        );
        await database.friends.put(
          Friend()
            ..uid = 'friend_a'
            ..name = 'Anu'
            ..addedAt = DateTime(2026, 9, 19),
        );
        await database.appConfigs.put(
          AppConfig(key: 'device-only', value: 'preserve'),
        );
      });
      final path = await service.createBackup();
      expect(path, isNotNull);
      final verify = await service.verifyBackup(path!);
      expect(verify.isValid, isTrue, reason: verify.errorMessage);
      expect(verify.totalEntries, 6);
      expect(verify.photoCount, 1);
      final names = ZipDecoder()
          .decodeBytes(File(path).readAsBytesSync())
          .map((file) => file.name)
          .toList();
      expect(names, containsAll(['manifest.json', 'data.json']));
      expect(names.any((name) => name.contains('another-account')), isFalse);
      await database.writeTxn(() async {
        await database.dailyLogs.clear();
        await database.dailyLogs.put(DailyLog(date: '2026-09-20', steps: 9999));
        await database.friends.clear();
        await database.syncQueueItems.put(
          SyncQueueItem(
            collection: 'daily_logs',
            docId: 'old',
            payload: '{}',
            timestamp: DateTime.now(),
            uid: 'old_account',
          ),
        );
      });
      final restored = await service.restoreBackup(path);
      expect(restored.success, isTrue, reason: restored.errorMessage);
      expect(restored.localCommitted, isTrue);
      expect(restored.safetyBackupPath, isNotNull);
      expect(
        (await service.verifyBackup(restored.safetyBackupPath!)).isValid,
        isTrue,
      );
      expect(database.dailyLogs.where().findAllSync().single.steps, 2222);
      expect(database.friends.where().findAllSync().single.uid, 'friend_a');
      expect(database.syncQueueItems.countSync(), 0);
      expect(
        database.appConfigs.where().findAllSync().single.value,
        'preserve',
      );
      expect(
        database.exerciseLogs.where().findAllSync().single.sets.single.reps,
        12,
      );
      final restoredPhoto = database.progressPhotos
          .where()
          .findAllSync()
          .single
          .path;
      expect(restoredPhoto, contains('restored_media'));
      expect(await File(restoredPhoto).readAsBytes(), [1, 2, 3, 4]);
      expect(
        database.dailyMealLogs
            .where()
            .findAllSync()
            .single
            .customSlots['lunch']!
            .photoPath,
        restoredPhoto,
      );
    },
  );

  test(
    'relative media round trip keeps category identity and shared-file references',
    () async {
      final media = Directory('${directory.path}/trufit_media');
      final scanned = Directory('${directory.path}/trufit_meal_photos');
      await media.create();
      await scanned.create();
      await File('${media.path}/same.jpg').writeAsBytes([11, 12]);
      await File('${scanned.path}/same.jpg').writeAsBytes([21, 22]);
      final scoped = File(
        '${media.path}/accounts/Z3Vlc3Q/progress_photos/new.jpg',
      );
      await scoped.parent.create(recursive: true);
      await scoped.writeAsBytes([31, 32]);
      await database.writeTxn(() async {
        await database.userProfiles.put(UserProfile(photoPath: 'same.jpg'));
        await database.progressPhotos.put(
          ProgressPhoto(
            path: 'accounts/Z3Vlc3Q/progress_photos/new.jpg',
            date: '2026-09-19',
            pose: 'front',
          ),
        );
        await database.dailyMealLogs.put(
          DailyMealLog(
            date: '2026-09-19',
            customSlots: {
              'lunch': MealSlotLog(
                photoPath: 'same.jpg',
                photoPaths: ['same.jpg'],
                totalCalories: 200,
              ),
            },
          ),
        );
        await database.scannedMealLogs.put(
          ScannedMealLog(
            id: 'scan_1',
            date: '2026-09-19',
            photoPath: 'same.jpg',
            mealType: 'lunch',
            foodName: 'Dal',
            estimatedCalories: 200,
            proteinGrams: 10,
            carbsGrams: 20,
            fatGrams: 4,
            portionMultiplier: 1,
            timestamp: '2026-09-19T12:00:00Z',
          ),
        );
      });
      final path = await service.createBackup();
      expect(path, isNotNull);
      final verified = await service.verifyBackup(path!);
      expect(verified.isValid, isTrue, reason: verified.errorMessage);
      expect(verified.photoCount, 3);
      final restored = await service.restoreBackup(path);
      expect(restored.success, isTrue, reason: restored.errorMessage);
      expect(restored.failedPhotosCount, 0);
      final profilePath = database.userProfiles
          .where()
          .findAllSync()
          .single
          .photoPath!;
      final meal = database.dailyMealLogs
          .where()
          .findAllSync()
          .single
          .customSlots['lunch']!;
      final scanPath = database.scannedMealLogs
          .where()
          .findAllSync()
          .single
          .photoPath;
      expect(meal.photoPath, profilePath);
      expect(meal.photoPaths.single, profilePath);
      expect(scanPath, isNot(profilePath));
      expect(await File(profilePath).readAsBytes(), [11, 12]);
      expect(await File(scanPath).readAsBytes(), [21, 22]);
      expect(
        await File(
          database.progressPhotos.where().findAllSync().single.path,
        ).readAsBytes(),
        [31, 32],
      );
    },
  );

  test(
    'schema 6 native round trip retains nutrition certainty, timed sets and custom origins',
    () async {
      await database.writeTxn(() async {
        await database.dailyMealLogs.put(
          DailyMealLog(
            date: '2026-09-19',
            customSlots: {
              'lunch': MealSlotLog(
                totalCalories: 400,
                totalProtein: 30,
                confidence: 'planned',
                caloriesComplete: true,
                macrosComplete: false,
              ),
              'snack': MealSlotLog(
                totalCalories: 100,
                totalProtein: 0,
                caloriesComplete: true,
                macrosComplete: true,
              ),
            },
          ),
        );
        await database.exerciseLogs.put(
          ExerciseLog(
            date: '2026-09-19',
            instanceId: 'plank-1',
            exerciseName: 'Plank',
            sets: [SetLog(setNumber: 1, durationSeconds: 45)],
          ),
        );
        await database.mealPlans.put(
          MealPlan(
            planName: 'My meals',
            totalCalories: 400,
            source: 'user',
            basedOnPlanName: 'Starter meals',
            meals: [
              Meal(
                name: 'Lunch',
                type: 'lunch',
                calories: 400,
                suggestions: ['Choose a familiar serving'],
                items: [
                  MealItem(
                    name: 'Dal',
                    quantity: '200 g',
                    calories: 400,
                    proteinG: 20,
                    carbsG: 45,
                    fatG: 12,
                  ),
                ],
              ),
            ],
          ),
        );
        await database.workoutPlans.put(
          WorkoutPlan(
            planName: 'My workout',
            source: 'user',
            basedOnPlanName: 'Starter workout',
            days: [
              WorkoutDay(
                dayId: 'monday',
                label: 'Core',
                sections: [
                  WorkoutSection(
                    title: 'Core',
                    exercises: [
                      Exercise(
                        name: 'Plank',
                        reps: ['45s'],
                        durationSeconds: 45,
                      )..instanceId = 'plank-1',
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      });
      final path = await service.createBackup(includeMedia: false);
      expect(path, isNotNull);
      final verification = await service.verifyBackup(path!);
      expect(verification.isValid, isTrue, reason: verification.errorMessage);
      expect(verification.schemaVersion, 6);
      await database.writeTxn(() async {
        await database.dailyMealLogs.clear();
        await database.exerciseLogs.clear();
        await database.mealPlans.clear();
        await database.workoutPlans.clear();
      });
      final restored = await service.restoreBackup(path);
      expect(restored.success, isTrue, reason: restored.errorMessage);
      final meals = database.dailyMealLogs.where().findAllSync().single;
      expect(meals.customSlots['lunch']!.caloriesComplete, isTrue);
      expect(meals.customSlots['lunch']!.macrosComplete, isFalse);
      expect(meals.customSlots['lunch']!.totalProtein, 30);
      expect(meals.customSlots['snack']!.macrosComplete, isTrue);
      expect(meals.customSlots['snack']!.hasCompleteMacros, isTrue);
      expect(meals.hasCompleteCalories, isTrue);
      expect(meals.hasCompleteMacros, isFalse);
      expect(
        database.exerciseLogs
            .where()
            .findAllSync()
            .single
            .sets
            .single
            .durationSeconds,
        45,
      );
      final mealPlan = database.mealPlans.where().findAllSync().single;
      expect(mealPlan.source, 'user');
      expect(mealPlan.basedOnPlanName, 'Starter meals');
      expect(mealPlan.meals.single.suggestions, ['Choose a familiar serving']);
      expect(mealPlan.meals.single.items.single.proteinG, 20);
      expect(mealPlan.meals.single.items.single.calories, 400);
      final workout = database.workoutPlans.where().findAllSync().single;
      expect(workout.source, 'user');
      expect(workout.basedOnPlanName, 'Starter workout');
      expect(
        workout.days.single.sections.single.exercises.single.durationSeconds,
        45,
      );
      expect(
        workout.days.single.sections.single.exercises.single.instanceId,
        'plank-1',
      );
    },
  );

  for (final version in [4, 5]) {
    test(
      'native schema $version restores without inventing new nutrition or duration fields',
      () async {
        await database.writeTxn(() async {
          await database.dailyMealLogs.put(
            DailyMealLog(
              date: '2026-09-19',
              customSlots: {
                'lunch': MealSlotLog(
                  totalCalories: 400,
                  totalProtein: 30,
                  confidence: 'planned',
                ),
              },
            ),
          );
          await database.exerciseLogs.put(
            ExerciseLog(
              date: '2026-09-19',
              instanceId: 'squat-1',
              exerciseName: 'Squat',
              sets: [SetLog(setNumber: 1, reps: 10, weight: 20)],
            ),
          );
          await database.mealPlans.put(
            MealPlan(
              planName: 'Legacy meals',
              meals: [
                Meal(
                  name: 'Lunch',
                  type: 'lunch',
                  calories: 400,
                  items: [MealItem(name: 'Dal', quantity: '200 g')],
                ),
              ],
              totalCalories: 400,
            ),
          );
          await database.workoutPlans.put(
            WorkoutPlan(
              planName: 'Legacy workout',
              days: [
                WorkoutDay(
                  dayId: 'monday',
                  sections: [
                    WorkoutSection(
                      title: 'Train',
                      exercises: [
                        Exercise(name: 'Squat', reps: ['10'])
                          ..instanceId = 'squat-1',
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        });
        final current = await service.createBackup(includeMedia: false);
        final data = dataFrom(current!);
        final mealRow =
            (data['dailyMealLogs'] as List).single as Map<String, dynamic>;
        for (final entry in mealRow['isarCustomSlots'] as List) {
          final slot = entry['value'] as Map<String, dynamic>;
          slot.remove('caloriesComplete');
          slot.remove('macrosComplete');
        }
        for (final row in data['exerciseLogs'] as List) {
          for (final set in row['sets'] as List) {
            (set as Map).remove('durationSeconds');
          }
        }
        for (final row in data['mealPlans'] as List) {
          (row as Map).remove('basedOnPlanName');
          for (final meal in row['meals'] as List) {
            (meal as Map).remove('suggestions');
            for (final item in meal['items'] as List) {
              for (final field in ['calories', 'proteinG', 'carbsG', 'fatG']) {
                (item as Map).remove(field);
              }
            }
          }
        }
        for (final row in data['workoutPlans'] as List) {
          (row as Map).remove('basedOnPlanName');
          for (final day in row['days'] as List) {
            for (final section in day['sections'] as List) {
              for (final exercise in section['exercises'] as List) {
                (exercise as Map).remove('durationSeconds');
              }
            }
          }
        }
        if (version == 4) data.remove('friends');
        final legacy = await fixture(data, schema: version);
        final verification = await service.verifyBackup(legacy);
        expect(verification.isValid, isTrue, reason: verification.errorMessage);
        final restored = await service.restoreBackup(legacy);
        expect(restored.success, isTrue, reason: restored.errorMessage);
        await database.writeTxn(() async {
          await database.appConfigs.put(
            AppConfig(key: 'schema_version', value: '$version'),
          );
        });
        await SchemaMigrationService.runStartupMigrations(database);
        expect(
          database.appConfigs
              .where()
              .keyEqualTo('schema_version')
              .findFirstSync()!
              .value,
          '6',
        );
        final lunch = database.dailyMealLogs
            .where()
            .findAllSync()
            .single
            .customSlots['lunch']!;
        expect(
          lunch.totalProtein,
          30,
          reason: 'Legacy stored data is retained, not silently rewritten.',
        );
        expect(
          lunch.hasCompleteMacros,
          isFalse,
          reason:
              'Old plan-derived macros are not promoted to observed nutrients.',
        );
        expect(lunch.macrosComplete, isNull);
        expect(
          database.exerciseLogs
              .where()
              .findAllSync()
              .single
              .sets
              .single
              .durationSeconds,
          isNull,
        );
        expect(
          database.exerciseLogs.where().findAllSync().single.sets.single.reps,
          10,
        );
        final mealPlan = database.mealPlans.where().findAllSync().single;
        expect(mealPlan.basedOnPlanName, isNull);
        expect(mealPlan.meals.single.items.single.proteinG, isNull);
        final workout = database.workoutPlans.where().findAllSync().single;
        expect(workout.basedOnPlanName, isNull);
        expect(
          workout.days.single.sections.single.exercises.single.durationSeconds,
          isNull,
        );
      },
    );
  }

  test('no-media backup is a complete readable snapshot', () async {
    await database.writeTxn(() async {
      await database.dailyLogs.put(DailyLog(date: '2026-09-19', steps: 4));
    });
    final path = await service.createBackup(includeMedia: false);
    expect(path, isNotNull);
    expect(
      dataFrom(path!).keys,
      containsAll(SchemaMigrationService.collectionNames),
    );
    expect((await service.verifyBackup(path)).isValid, isTrue);
  });

  test(
    'future schemas, unknown/incomplete collections and counts are rejected before mutation',
    () async {
      await database.writeTxn(() async {
        await database.dailyLogs.put(DailyLog(date: '2026-09-19', steps: 123));
      });
      for (final path in [
        await fixture(emptySnapshot(), schema: 999),
        await fixture({'unknown': []}),
        await fixture({'dailyLogs': []}),
        await fixture(emptySnapshot(), total: 100),
        await fixture(emptySnapshot(), extraName: '../outside.jpg'),
      ]) {
        expect((await service.verifyBackup(path)).isValid, isFalse);
        expect((await service.restoreBackup(path)).success, isFalse);
        expect(database.dailyLogs.where().findAllSync().single.steps, 123);
      }
    },
  );

  test('invalid numeric values are rejected by verification', () async {
    await database.writeTxn(() async {
      await database.dailyLogs.put(DailyLog(date: '2026-09-19', steps: 123));
    });
    final backup = await service.createBackup(includeMedia: false);
    final data = dataFrom(backup!);
    (data['dailyLogs'] as List).single['steps'] = 'not a number';
    final path = await fixture(data);
    expect((await service.verifyBackup(path)).isValid, isFalse);
    expect((await service.restoreBackup(path)).localCommitted, isFalse);
  });

  test(
    'complete version 4 native snapshots migrate with empty friends',
    () async {
      final data = emptySnapshot()..remove('friends');
      final path = await fixture(data, schema: 4);
      expect((await service.verifyBackup(path)).isValid, isTrue);
      expect((await service.restoreBackup(path)).success, isTrue);
    },
  );

  test(
    'duplicate unique records roll back the transaction including stale queue',
    () async {
      await database.writeTxn(() async {
        await database.dailyLogs.put(DailyLog(date: '2026-09-19', steps: 123));
        await database.syncQueueItems.put(
          SyncQueueItem(
            collection: 'daily_logs',
            docId: 'old',
            payload: '{}',
            timestamp: DateTime.now(),
            uid: 'guest',
          ),
        );
      });
      final backup = await service.createBackup(includeMedia: false);
      final data = dataFrom(backup!);
      final rows = data['dailyLogs'] as List;
      rows.add({...rows.single as Map<String, dynamic>, 'id': 999});
      final result = await service.restoreBackup(await fixture(data));
      expect(result.success, isFalse);
      expect(result.localCommitted, isFalse);
      expect(database.dailyLogs.where().findAllSync().single.steps, 123);
      expect(database.syncQueueItems.countSync(), 1);
    },
  );

  test(
    'signed-in restore refuses absent coordination and foreign owner',
    () async {
      auth.account = 'account_a';
      final path = await service.createBackup(includeMedia: false);
      expect(path, isNotNull);
      expect((await service.restoreBackup(path!)).success, isFalse);
      auth.account = 'account_b';
      expect((await service.verifyBackup(path)).isValid, isFalse);
    },
  );

  test('account changes in coordinator abort before replacement', () async {
    final path = await service.createBackup(includeMedia: false);
    final coordinated = BackupService(
      auth,
      databaseResolver: () => database,
      beforeRestore: (_) async {
        auth.account = 'other';
      },
      afterRestore: (_, committed) async {
        expect(committed, isFalse);
      },
    );
    final result = await coordinated.restoreBackup(path!);
    expect(result.success, isFalse);
    expect(result.localCommitted, isFalse);
  });

  test(
    'post-commit reconciliation failure explicitly reports committed local data once',
    () async {
      var callbacks = 0;
      final path = await service.createBackup(includeMedia: false);
      final coordinated = BackupService(
        auth,
        databaseResolver: () => database,
        beforeRestore: (_) async {},
        afterRestore: (_, committed) async {
          callbacks++;
          expect(committed, isTrue);
          throw StateError('offline reconciliation failure');
        },
      );
      final result = await coordinated.restoreBackup(path!);
      expect(result.success, isFalse);
      expect(result.localCommitted, isTrue);
      expect(callbacks, 1);
    },
  );

  test('safety backup failure prevents any replacement', () async {
    final path = await service.createBackup(includeMedia: false);
    final coordinated = BackupService(
      auth,
      databaseResolver: () => database,
      beforeRestore: (_) async {
        // The account becomes structurally invalid to export, not the incoming fixture.
        database.writeTxnSync(() {
          database.dailyLogs.importJsonSync([
            {'id': 1, 'date': null},
          ]);
        });
      },
      afterRestore: (_, committed) async {
        expect(committed, isFalse);
      },
    );
    final result = await coordinated.restoreBackup(path!);
    expect(result.success, isFalse);
    expect(result.localCommitted, isFalse);
    expect(database.dailyLogs.countSync(), 1);
  });

  test(
    'explicit DB resolves CSV and backup correctly while ambiguous fallback refuses',
    () async {
      await database.writeTxn(() async {
        await database.dailyLogs.put(DailyLog(date: '2026-09-19', steps: 1111));
      });
      final otherDir = await Directory('${directory.path}/other').create();
      final other = await Isar.open(
        AppDatabaseManager.schemas,
        directory: otherDir.path,
        name: 'csv_other_${serial++}',
      );
      try {
        await other.writeTxn(() async {
          await other.dailyLogs.put(
            DailyLog(date: '2026-09-19', steps: 2222, dayNote: '=SUM(A1)'),
          );
        });
        expect((await CsvExportService().exportData(null)).isSuccess, isFalse);
        expect(
          await BackupService(auth).createBackup(includeMedia: false),
          isNull,
        );
        final result = await CsvExportService(
          databaseResolver: () => other,
        ).exportData(null);
        expect(result.isSuccess, isTrue, reason: result.errorMessage);
        final zip = ZipDecoder().decodeBytes(
          await File(result.filePath!).readAsBytes(),
        );
        final csv = utf8.decode(zip.findFile('daily_logs.csv')!.content);
        expect(csv, contains('2222'));
        expect(csv, isNot(contains('1111')));
        expect(csv, contains("'=SUM(A1)"));
      } finally {
        await other.close();
      }
    },
  );

  test(
    'CSV actual file excludes dates outside inclusive selected range',
    () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      String date(DateTime value) => value.toIso8601String().split('T').first;
      await database.writeTxn(() async {
        await database.dailyLogs.putAll([
          DailyLog(date: date(today), steps: 1),
          DailyLog(
            date: date(today.subtract(const Duration(days: 29))),
            steps: 2,
          ),
          DailyLog(
            date: date(today.subtract(const Duration(days: 30))),
            steps: 3,
          ),
          DailyLog(date: date(today.add(const Duration(days: 1))), steps: 4),
        ]);
      });
      final result = await CsvExportService(
        databaseResolver: () => database,
      ).exportData(today.subtract(const Duration(days: 29)));
      final zip = ZipDecoder().decodeBytes(
        await File(result.filePath!).readAsBytes(),
      );
      final manifest = jsonDecode(
        utf8.decode(zip.findFile('manifest.json')!.content),
      );
      expect(manifest['categories']['dailyLogs']['count'], 2);
      expect(manifest['range'], contains('(30 days)'));
    },
  );

  test('automatic backup dates and retention are account scoped', () async {
    auth.account = 'a';
    await service.autoBackup();
    final prefs = await SharedPreferences.getInstance();
    final keyA = service.metadataKey('last_auto_backup_date');
    expect(prefs.getString(keyA), isNotNull);
    auth.account = 'b';
    await service.autoBackup();
    expect(
      prefs.getString(service.metadataKey('last_auto_backup_date')),
      isNotNull,
    );
    expect(service.metadataKey('last_auto_backup_date'), isNot(keyA));
  });
}
