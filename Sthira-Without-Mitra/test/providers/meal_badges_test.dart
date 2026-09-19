import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/providers/badge_engine_provider.dart';
import 'package:trufit_bodamma/repositories/badge_repository.dart';
import 'package:trufit_bodamma/repositories/daily_log_repository.dart';
import 'package:trufit_bodamma/repositories/meal_repository.dart';
import '../helpers/test_isar_setup.dart';

DailyMealLog _meal(String date) => DailyMealLog(
  date: date,
  customSlots: {
    'lunch': MealSlotLog(items: [MealItemLog(name: 'Dal')]),
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 9, 19);

  test(
    'meal milestones count distinct recorded days, not meals or calories',
    () {
      expect(
        recordedMealDays([
          _meal('2026-09-01'),
          _meal('2026-09-01'),
          DailyMealLog(
            date: '2026-09-04',
            customSlots: {
              'breakfast': MealSlotLog(photoPath: 'saved-photo.jpg'),
              'lunch': MealSlotLog(totalCalories: 900),
              'dinner': MealSlotLog(
                items: [MealItemLog(name: 'Unresolved food')],
              ),
            },
          ),
        ], now),
        2,
      );
    },
  );

  test('empty, future and malformed days cannot earn a meal trophy', () {
    expect(
      recordedMealDays([
        DailyMealLog(date: '2026-09-01', customSlots: {'lunch': MealSlotLog()}),
        _meal('2026-09-20'),
        _meal('invalid'),
        _meal('2026-02-31'),
        _meal('2026-09-19'),
      ], now),
      1,
    );
  });

  test('breaks do not reset recorded meal-day progress', () {
    expect(
      recordedMealDays(
        List.generate(
          7,
          (index) => _meal(
            DateFormat('yyyy-MM-dd').format(DateTime(2026, 8, 1 + index * 3)),
          ),
        ),
        now,
      ),
      7,
    );
  });

  group('persisted meal trophies', () {
    late Isar database;
    late BadgeRepository badges;
    late MealRepository meals;
    late DailyLogRepository daily;
    ProviderContainer? container;

    setUp(() async {
      database = await setUpTestIsar();
      badges = BadgeRepository();
      meals = MealRepository();
      daily = DailyLogRepository();
      await badges.init(database);
      await meals.init(database);
      await daily.init(database);
    });
    tearDown(() async {
      container?.dispose();
      container = null;
      await badges.detachSync();
      await meals.detachSync();
      await daily.detachSync();
      meals.dispose();
      daily.dispose();
      await tearDownTestIsar(database);
    });

    void startEngine() {
      container = ProviderContainer(
        overrides: [
          badgeRepoProvider.overrideWithValue(badges),
          mealRepoProvider.overrideWithValue(meals),
          dailyLogRepoProvider.overrideWithValue(daily),
          clockProvider.overrideWithValue(now),
        ],
      );
      container!.read(badgeEngineProvider);
    }

    Future<void> waitFor(
      String id,
      bool Function() ready, {
      bool announced = false,
    }) async {
      if (!ready()) {
        await badges.watchUpdates
            .firstWhere((_) => ready())
            .timeout(const Duration(seconds: 5));
      }
      await Future<void>.delayed(Duration.zero);
      expect(badges.getBadge(id)!.isUnlocked, isTrue);
      expect(
        container!
            .read(badgeUnlockEventProvider)
            .any((badge) => badge.id == id),
        announced,
      );
    }

    test(
      'history earns silently; a new locally recorded day celebrates once',
      () async {
        for (var index = 0; index < 7; index++) {
          await meals.saveDailyLog(
            _meal(
              DateFormat('yyyy-MM-dd').format(DateTime(2026, 8, 1 + index * 2)),
            ),
          );
        }
        startEngine();
        await waitFor(
          'meal_days_7',
          () => badges.getBadge('meal_days_7')!.isUnlocked,
        );
        expect(badges.getBadge('meal_days_30')!.isUnlocked, isFalse);
        expect(badges.getBadge('first_workout')!.isUnlocked, isFalse);

        for (var index = 0; index < 29; index++) {
          await meals.saveDailyLog(
            _meal(
              DateFormat('yyyy-MM-dd').format(DateTime(2026, 8, 1 + index)),
            ),
          );
        }
        await meals.saveMealSlot(
          '2026-09-19',
          'lunch',
          MealSlotLog(items: [MealItemLog(name: 'Dal')]),
        );
        await waitFor(
          'meal_days_30',
          () => badges.getBadge('meal_days_30')!.isUnlocked,
          announced: true,
        );
        final events = container!.read(badgeUnlockEventProvider);
        expect(events.where((badge) => badge.id == 'meal_days_7'), isEmpty);
        expect(
          events.where((badge) => badge.id == 'meal_days_30'),
          hasLength(1),
        );
        expect(badges.getBadge('first_workout')!.isUnlocked, isFalse);
      },
    );

    test(
      'cloud-only current-day records earn silently and corrections do not replay',
      () async {
        for (var index = 0; index < 6; index++) {
          await meals.saveDailyLog(
            _meal(
              DateFormat('yyyy-MM-dd').format(DateTime(2026, 9, index + 1)),
            ),
          );
        }
        startEngine();
        if (badges.getBadge('meal_days_7')!.currentProgress != 6) {
          await badges.watchUpdates
              .firstWhere(
                (_) => badges.getBadge('meal_days_7')!.currentProgress == 6,
              )
              .timeout(const Duration(seconds: 5));
        }
        // CloudRecordStore/restore write to Isar without emitting local commits.
        await database.writeTxn(() async {
          await database.dailyMealLogs.put(_meal('2026-09-19'));
        });
        await waitFor(
          'meal_days_7',
          () => badges.getBadge('meal_days_7')!.isUnlocked,
        );
        await meals.clearMealSlot('2026-09-19', 'lunch');
        await meals.saveMealSlot(
          '2026-09-19',
          'lunch',
          MealSlotLog(items: [MealItemLog(name: 'Dal')]),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(container!.read(badgeUnlockEventProvider), isEmpty);
      },
    );

    test(
      'catalog reseeding and backup roundtrip preserve earned trophies',
      () async {
        final earnedAt = DateTime(2026, 8, 30);
        await badges.saveBadge(
          badges
              .getBadge('meal_days_7')!
              .copyWith(currentProgress: 7, unlockedAt: earnedAt),
        );
        final exported = badges.exportForCloud();
        await badges.init(database);
        await badges.importFromCloud(exported);
        expect(
          badges.getAllBadges().where((badge) => badge.category == 'meal'),
          hasLength(2),
        );
        expect(badges.getBadge('meal_days_7')!.unlockedAt, earnedAt);
        expect(badges.getBadge('meal_days_30')!.requiredProgress, 30);
        expect(badges.getBadge('first_workout'), isNotNull);
      },
    );

    test(
      'hydration does not unlock trophies before records are ready',
      () async {
        for (var index = 0; index < 7; index++) {
          await meals.saveDailyLog(
            _meal('2026-09-${(index + 1).toString().padLeft(2, '0')}'),
          );
        }
        container = ProviderContainer(
          overrides: [
            badgeRepoProvider.overrideWithValue(badges),
            mealRepoProvider.overrideWithValue(meals),
            dailyLogRepoProvider.overrideWithValue(daily),
            clockProvider.overrideWithValue(now),
          ],
        );
        container!.read(accountHydratingProvider.notifier).state = true;
        container!.read(badgeEngineProvider);
        await Future<void>.delayed(Duration.zero);
        expect(badges.getBadge('meal_days_7')!.isUnlocked, isFalse);
        container!.read(accountHydratingProvider.notifier).state = false;
        await waitFor(
          'meal_days_7',
          () => badges.getBadge('meal_days_7')!.isUnlocked,
        );
      },
    );
  });
}
