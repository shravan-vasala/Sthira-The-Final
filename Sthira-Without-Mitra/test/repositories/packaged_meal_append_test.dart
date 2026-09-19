import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:trufit_bodamma/interfaces/i_cloud_sync_service.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/food_nutrition.dart';
import 'package:trufit_bodamma/models/sync_queue_item.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/repositories/meal_repository.dart';
import 'package:trufit_bodamma/services/cloud_record_store.dart';

import '../helpers/test_isar_setup.dart';

class _RecordingCloudSync extends Fake implements ICloudSyncService {
  int flushCount = 0;
  bool failFlush = false;

  @override
  bool get canSync => false;

  @override
  String get currentUid => 'test-user';

  @override
  void triggerFlush() {
    flushCount++;
    if (failFlush) throw StateError('Sync scheduler unavailable');
  }
}

MealItemLog _packagedItem(String name, double calories) => MealItemLog(
  name: name,
  barcode: '8901234567890',
  brand: 'Example brand',
  portion: '200 ml',
  nutritionBasis: 'per100ml',
  consumedMl: 200,
  baseNutrition: FoodNutrition(
    kcal: calories / 2,
    proteinG: 3,
    carbsG: 5,
    fatG: 2,
  ),
  computedNutrition: FoodNutrition(
    kcal: calories,
    proteinG: 6,
    carbsG: 10,
    fatG: 4,
  ),
  provenance: 'label',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Isar isar;
  late MealRepository repo;

  setUp(() async {
    isar = await setUpTestIsar();
    repo = MealRepository();
    await repo.init(isar);
  });

  tearDown(() async {
    await repo.detachSync();
    await tearDownTestIsar(isar);
  });

  for (final knownCalories in [false, true]) {
    test(
      'cloud photo-only import and packaged append preserve ${knownCalories ? 'known zero calories' : 'unknown calories'}',
      () async {
        const date = '2026-09-19';
        await CloudRecordStore(isar).apply('meal_logs', {
          date: {
            'date': date,
            'customSlots': {
              'lunch': {
                'photoPaths': ['legacy-meal.jpg'],
                if (knownCalories) 'caloriesComplete': true,
              },
            },
          },
        });
        final imported = repo.getDailyLog(date);
        expect(repo.isMealLogged(date, 'lunch'), isTrue);
        expect(imported.loggedSlotsCount, 1);
        expect(imported.hasCompleteCalories, knownCalories);
        expect(imported.hasCompleteMacros, isFalse);
        await repo.appendMealItem(date, 'lunch', _packagedItem('Milk', 120));
        final saved = repo.getDailyLog(date);
        expect(saved.totalCalories, 120);
        expect(saved.hasCompleteCalories, knownCalories);
        expect(saved.hasCompleteMacros, isFalse);
        expect(saved.customSlots['lunch']!.photoPaths, ['legacy-meal.jpg']);
        expect(saved.customSlots['lunch']!.items.single.name, 'Milk');
        final restored = DailyMealLog.fromJson(saved.toJson());
        expect(restored.hasCompleteCalories, knownCalories);
        expect(restored.hasCompleteMacros, isFalse);
      },
    );
  }

  test(
    'parallel additions preserve legacy totals, items and meal metadata',
    () async {
      const date = '2026-09-19';
      await repo.saveMealSlot(
        date,
        'lunch',
        MealSlotLog(
          name: 'My lunch',
          emoji: 'meal',
          photoPath: '/original.jpg',
          photoPaths: ['/original.jpg', '/second.jpg'],
          confidence: 'medium',
          items: [MealItemLog(name: 'Legacy meal', resolved: false)],
          totalCalories: 400,
          totalProtein: 20,
          totalCarbs: 60,
          totalFat: 10,
        ),
      );
      await repo.saveMealSlot(date, 'dinner', MealSlotLog(totalCalories: 300));

      await Future.wait([
        repo.appendMealItem(
          date,
          'lunch',
          _packagedItem('Milk', 120),
          slotName: 'Replacement name',
        ),
        repo.appendMealItem(date, 'lunch', _packagedItem('Drink', 180)),
      ]);

      final log = repo.getDailyLog(date);
      final slot = log.customSlots['lunch']!;
      expect(
        slot.items.map((item) => item.name),
        containsAll(['Legacy meal', 'Milk', 'Drink']),
      );
      expect(slot.items, hasLength(3));
      expect(slot.totalCalories, 700);
      expect(slot.totalProtein, 32);
      expect(slot.totalCarbs, 80);
      expect(slot.totalFat, 18);
      expect(slot.name, 'My lunch');
      expect(slot.emoji, 'meal');
      expect(slot.photoPath, '/original.jpg');
      expect(slot.photoPaths, ['/original.jpg', '/second.jpg']);
      expect(slot.confidence, 'medium');
      expect(log.customSlots['dinner']!.totalCalories, 300);
      expect(isar.dailyMealLogs.where().dateEqualTo(date).countSync(), 1);
    },
  );

  test(
    'persists packaged units and immutable nutrition in Isar and sync payload',
    () async {
      final sync = _RecordingCloudSync();
      await repo.attachSync(sync);
      final item = _packagedItem('Milk', 120);
      final pending = repo.appendMealItem(
        '2026-09-18',
        'snack',
        item,
        slotName: 'Afternoon snack',
        slotEmoji: 'snack',
      );
      item.computedNutrition!.kcal = 999;
      item.baseNutrition!.kcal = 999;
      item.brand = 'Changed later';
      await pending;

      final slot = repo.getDailyLog('2026-09-18').customSlots['snack']!;
      final stored = slot.items.single;
      expect(slot.name, 'Afternoon snack');
      expect(slot.emoji, 'snack');
      expect(stored.barcode, '8901234567890');
      expect(stored.brand, 'Example brand');
      expect(stored.nutritionBasis, 'per100ml');
      expect(stored.consumedMl, 200);
      expect(stored.consumedGrams, isNull);
      expect(stored.isPer100g, isFalse);
      expect(stored.baseNutrition!.kcal, 60);
      expect(stored.computedNutrition!.kcal, 120);
      expect(slot.totalCalories, 120);

      final queued = isar.syncQueueItems.where().findAllSync().single;
      expect(queued.collection, 'meal_logs');
      expect(queued.docId, '2026-09-18');
      expect(queued.uid, isar.name);
      final payload = jsonDecode(queued.payload) as Map<String, dynamic>;
      final restored = DailyMealLog.fromJson(payload);
      expect(
        restored.customSlots['snack']!.items.single.toJson(),
        stored.toJson(),
      );
      expect(payload['updatedAt'], isNotNull);
      expect(sync.flushCount, 1);
    },
  );

  test(
    'sync scheduling failure does not reject a durable meal append',
    () async {
      final sync = _RecordingCloudSync()..failFlush = true;
      await repo.attachSync(sync);

      await repo.appendMealItem(
        '2026-09-19',
        'snack',
        _packagedItem('Milk', 120),
      );

      expect(repo.getDailyLog('2026-09-19').totalCalories, 120);
      expect(isar.syncQueueItems.where().countSync(), 1);
      expect(sync.flushCount, 1);
    },
  );

  test(
    'disposing notifier during append still reports durable save success',
    () async {
      final container = ProviderContainer(
        overrides: [
          mealRepoProvider.overrideWithValue(repo),
          selectedDateProvider.overrideWith((ref) => DateTime(2026, 9, 19)),
        ],
      );
      final pending = container
          .read(dailyMealLogProvider.notifier)
          .appendMealItem('snack', _packagedItem('Milk', 120));
      container.dispose();

      await pending;

      expect(repo.getDailyLog('2026-09-19').totalCalories, 120);
      expect(
        repo.getDailyLog('2026-09-19').customSlots['snack']!.items,
        hasLength(1),
      );
    },
  );

  test('an in-flight append stays in its original account database', () async {
    final replacement = await setUpTestIsar();
    addTearDown(() => tearDownTestIsar(replacement));
    final entered = Completer<void>();
    final release = Completer<void>();
    final lock = isar.writeTxn(() async {
      entered.complete();
      await release.future;
    });
    await entered.future;
    final pending = repo.appendMealItem(
      '2026-09-19',
      'snack',
      _packagedItem('Milk', 120),
    );
    try {
      await repo.init(replacement);
    } finally {
      release.complete();
    }
    await lock;
    await pending;

    final original = isar.dailyMealLogs
        .where()
        .dateEqualTo('2026-09-19')
        .findFirstSync();
    expect(original!.totalCalories, 120);
    expect(replacement.dailyMealLogs.where().countSync(), 0);
    expect(isar.syncQueueItems.where().findAllSync().single.uid, isar.name);
    expect(replacement.syncQueueItems.where().countSync(), 0);
  });

  test('serving and gram quantities survive Isar persistence', () async {
    final servings = MealItemLog(
      name: 'Small snack pack',
      barcode: '8900000000001',
      nutritionBasis: 'perServing',
      consumedServings: 0.5,
      baseNutrition: FoodNutrition(kcal: 200),
      computedNutrition: FoodNutrition(kcal: 100),
    );
    final grams = MealItemLog(
      name: 'Biscuits',
      barcode: '8900000000002',
      nutritionBasis: 'per100g',
      consumedGrams: 25,
      baseNutrition: FoodNutrition(kcal: 400),
      computedNutrition: FoodNutrition(kcal: 100),
    );

    await repo.appendMealItem('2026-09-19', 'snack', servings);
    await repo.appendMealItem('2026-09-19', 'snack', grams);

    final stored = repo.getDailyLog('2026-09-19').customSlots['snack']!.items;
    expect(stored[0].toJson(), servings.toJson());
    expect(stored[1].toJson(), grams.toJson());
    expect(stored[0].consumedGrams, isNull);
    expect(stored[0].consumedServings, 0.5);
    expect(stored[1].isPer100g, isTrue);
    expect(stored[1].consumedMl, isNull);
  });

  test(
    'explicit target date stays fixed when the visible date changes',
    () async {
      final container = ProviderContainer(
        overrides: [
          mealRepoProvider.overrideWithValue(repo),
          selectedDateProvider.overrideWith((ref) => DateTime(2026, 9, 19)),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(dailyMealLogProvider.notifier);

      final pending = notifier.appendMealItem(
        'breakfast',
        _packagedItem('Milk', 120),
        targetDate: '2026-09-18',
        slotName: 'Breakfast',
      );
      container.read(selectedDateProvider.notifier).state = DateTime(
        2026,
        9,
        20,
      );
      expect(container.read(dailyMealLogProvider).date, '2026-09-20');
      await pending;

      expect(repo.getDailyLog('2026-09-18').totalCalories, 120);
      expect(repo.getDailyLog('2026-09-19').customSlots, isEmpty);
      expect(container.read(dailyMealLogProvider).date, '2026-09-20');
      expect(container.read(dailyMealLogProvider).customSlots, isEmpty);
    },
  );

  test('notifier defaults to selected date and refreshes its meal', () async {
    final container = ProviderContainer(
      overrides: [
        mealRepoProvider.overrideWithValue(repo),
        selectedDateProvider.overrideWith((ref) => DateTime(2026, 9, 17)),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(dailyMealLogProvider.notifier)
        .appendMealItem('breakfast', _packagedItem('Milk', 120));

    expect(container.read(dailyMealLogProvider).date, '2026-09-17');
    expect(container.read(dailyMealLogProvider).totalCalories, 120);
  });

  test(
    'missing and invalid nutrition cannot create a partial log or sync entry',
    () async {
      for (final nutrition in <FoodNutrition?>[
        null,
        FoodNutrition(kcal: double.nan),
        FoodNutrition(kcal: double.infinity),
        FoodNutrition(proteinG: -1),
      ]) {
        await expectLater(
          repo.appendMealItem(
            '2026-09-19',
            'snack',
            MealItemLog(name: 'Incomplete label', computedNutrition: nutrition),
          ),
          throwsArgumentError,
        );
      }

      expect(repo.getDailyLog('2026-09-19').customSlots, isEmpty);
      expect(isar.syncQueueItems.where().countSync(), 0);
    },
  );
}
