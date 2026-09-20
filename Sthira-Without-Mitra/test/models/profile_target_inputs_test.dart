import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:trufit_bodamma/models/app_config.dart';
import 'package:trufit_bodamma/models/sync_queue_item.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/repositories/profile_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  UserProfile personalInputs() => UserProfile(
    name: 'Asha',
    age: 36,
    gender: 'F',
    activityLevel: 'Moderately active',
    primaryGoal: 'Build muscle',
    height: 164,
    currentWeight: 63,
    targetCalories: 2100,
    targetProteinG: 120,
    targetCarbsG: 255,
    targetFatG: 67,
    activeMealPlan: 'expert-meal-plan',
    activeWorkoutPlan: 'expert-workout-plan',
  );

  test('unconfigured profiles leave suggestion inputs unset', () {
    final profile = UserProfile();
    expect(profile.age, isNull);
    expect(profile.gender, isNull);
    expect(profile.activityLevel, isNull);
    expect(profile.primaryGoal, isNull);
    expect(profile.height, isNull);
    expect(profile.currentWeight, isNull);
    expect(profile.toJson().containsKey('activityLevel'), isFalse);
  });

  test(
    'JSON and unrelated edits preserve personal inputs and expert plans',
    () {
      final original = personalInputs()..id = 41;
      final restored = UserProfile.fromJson(
        jsonDecode(jsonEncode(original.toJson())),
      );
      expect(restored.toJson(), original.toJson());
      final renamed = original.copyWith(name: 'New name');
      expect(renamed.id, 41);
      expect(renamed.toJson(), {...original.toJson(), 'name': 'New name'});
      final changed = renamed.copyWith(activityLevel: 'Sedentary');
      expect(changed.activityLevel, 'Sedentary');
      expect(changed.activeMealPlan, 'expert-meal-plan');
      expect(changed.targetCalories, 2100);
    },
  );

  test(
    'legacy cloud JSON retains saved targets without inventing activity',
    () {
      final legacy = personalInputs().toJson()..remove('activityLevel');
      final restored = UserProfile.fromJson(legacy);
      expect(restored.activityLevel, isNull);
      expect(restored.age, 36);
      expect(restored.height, 164);
      expect(restored.currentWeight, 63);
      expect(restored.targetCalories, 2100);
      expect(restored.toJson(), legacy);
    },
  );

  group('persisted target inputs', () {
    late Directory directory;
    late Isar database;
    late String databaseName;

    Future<Isar> openDatabase() => Isar.open(
      [UserProfileSchema, SyncQueueItemSchema, AppConfigSchema],
      directory: directory.path,
      name: databaseName,
    );

    setUpAll(() async {
      await Isar.initializeIsarCore(download: false);
    });
    setUp(() async {
      directory = await Directory.systemTemp.createTemp(
        'sthira_target_inputs_',
      );
      databaseName = 'target_inputs_${DateTime.now().microsecondsSinceEpoch}';
      database = await openDatabase();
    });
    tearDown(() async {
      if (database.isOpen) await database.close();
      await directory.delete(recursive: true);
    });

    test(
      'Isar retains inputs and plan targets after closing and reopening',
      () async {
        final saved = personalInputs();
        await database.writeTxn(() => database.userProfiles.put(saved));
        await database.close();
        database = await openDatabase();
        final restored = await database.userProfiles.get(saved.id);
        expect(restored, isNotNull);
        expect(restored!.toJson(), saved.toJson());
      },
    );

    test(
      'native backup JSON roundtrip retains activity and accepts its absence',
      () async {
        final saved = personalInputs();
        await database.writeTxn(() => database.userProfiles.put(saved));
        final exported = await database.userProfiles.where().exportJson();
        expect(exported.single['activityLevel'], 'Moderately active');
        await database.writeTxn(() async {
          await database.userProfiles.clear();
          await database.userProfiles.importJson(exported);
        });
        expect(
          database.userProfiles.where().findFirstSync()!.toJson(),
          saved.toJson(),
        );

        exported.single.remove('activityLevel');
        await database.writeTxn(() async {
          await database.userProfiles.clear();
          await database.userProfiles.importJson(exported);
        });
        final legacy = database.userProfiles.where().findFirstSync()!;
        expect(legacy.activityLevel, isNull);
        expect(legacy.age, 36);
        expect(legacy.primaryGoal, 'Build muscle');
        expect(legacy.targetCalories, 2100);
      },
    );

    test(
      'repository sync queue and cloud export preserve inputs on other edits',
      () async {
        final repository = ProfileRepository();
        await repository.init(database);
        await repository.saveProfile(personalInputs());
        await repository.updateName('Renamed');
        final expected = personalInputs().copyWith(name: 'Renamed').toJson();
        expect(repository.exportProfileForCloud(), expected);
        final payloads = await database.syncQueueItems.where().findAll();
        expect(payloads, isNotEmpty);
        for (final payload in payloads) {
          final json = jsonDecode(payload.payload) as Map<String, dynamic>;
          expect(json['activityLevel'], 'Moderately active');
          expect(json['age'], 36);
          expect(json['height'], 164);
        }
      },
    );

    test(
      'cloud import restores editable inputs to local persistence',
      () async {
        final repository = ProfileRepository();
        await repository.init(database);
        await repository.importProfileFromCloud(personalInputs().toJson());
        expect(repository.getProfile().toJson(), personalInputs().toJson());
      },
    );
  });
}
