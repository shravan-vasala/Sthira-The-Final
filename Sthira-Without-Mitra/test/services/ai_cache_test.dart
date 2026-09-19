import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:trufit_bodamma/models/ai_cache_entry.dart';
import 'package:trufit_bodamma/models/food_nutrition.dart';
import 'package:trufit_bodamma/models/food_search_cache.dart';
import 'package:trufit_bodamma/models/user_food_log.dart';
import 'package:trufit_bodamma/services/ai_cache.dart';
import 'package:trufit_bodamma/services/ai_client.dart';
import 'package:trufit_bodamma/services/gemini_food_service.dart';
import 'package:trufit_bodamma/services/nutrition_lookup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'unavailable or throwing cache resolver makes storage optional',
    () async {
      for (final cache in [
        AiCache(databaseResolver: () => null),
        AiCache(
          databaseResolver: () => throw StateError('Account unavailable'),
        ),
      ]) {
        expect(cache.get('meal', 'instructions'), isNull);
        await cache.set('meal', 'instructions', {'items': []});
        await cache.prune();
      }
    },
  );

  group('account-bound cache and nutrition', () {
    late Isar first;
    late Isar second;
    late Isar? active;
    late AiCache cache;

    setUpAll(() async {
      await Isar.initializeIsarCore(download: true);
      Future<Isar> open(String suffix) async {
        final dir = await Directory.systemTemp.createTemp('meal_cache_test_');
        return Isar.open(
          [AiCacheEntrySchema, UserFoodLogSchema, FoodSearchCacheSchema],
          directory: dir.path,
          name: 'meal_cache_${DateTime.now().microsecondsSinceEpoch}_$suffix',
          inspector: false,
        );
      }

      first = await open('first');
      second = await open('second');
    });
    setUp(() async {
      await first.writeTxn(() => first.clear());
      await second.writeTxn(() => second.clear());
      active = first;
      cache = AiCache(databaseResolver: () => active);
    });
    tearDownAll(() async {
      await first.close();
      await second.close();
    });

    Future<void> replaceEntry({
      required DateTime timestamp,
      String response = '{"value":1}',
    }) async {
      final prior = first.aiCacheEntrys.where().findFirstSync()!;
      final entry = AiCacheEntry(
        cacheKey: prior.cacheKey,
        cachedResponse: response,
        timestamp: timestamp,
      )..id = prior.id;
      await first.writeTxn(() => first.aiCacheEntrys.put(entry));
    }

    test('fresh raw responses use the configured 24-hour lifetime', () async {
      await cache.set('meal', 'instruction', {'value': 1}, null, 'schema-v3');
      expect(cache.get('meal', 'instruction', null, 'schema-v3'), {'value': 1});
      expect(
        cache.get('meal', 'instruction', null, 'different-schema'),
        isNull,
      );
      await replaceEntry(
        timestamp: DateTime.now().subtract(const Duration(hours: 25)),
      );
      expect(cache.get('meal', 'instruction', null, 'schema-v3'), isNull);
    });

    test(
      'expired and corrupt lookup never writes during another async transaction',
      () async {
        await cache.set('meal', 'instruction', {'value': 1});
        for (final corrupt in [false, true]) {
          await replaceEntry(
            timestamp: corrupt
                ? DateTime.now()
                : DateTime.now().subtract(const Duration(hours: 25)),
            response: corrupt ? 'invalid JSON' : '{"value":1}',
          );
          final entered = Completer<void>();
          final release = Completer<void>();
          final transaction = first.writeTxn(() async {
            entered.complete();
            await release.future;
          });
          await entered.future;
          try {
            expect(cache.get('meal', 'instruction'), isNull);
            expect(
              first.aiCacheEntrys.countSync(),
              1,
              reason: 'Lookup must not start cleanup writes.',
            );
          } finally {
            release.complete();
            await transaction;
          }
        }
      },
    );

    test(
      'switching accounts uses each account cache without reusing a stale instance',
      () async {
        await cache.set('meal', 'instruction', {'account': 'first'});
        active = second;
        expect(cache.get('meal', 'instruction'), isNull);
        await cache.set('meal', 'instruction', {'account': 'second'});
        expect(cache.get('meal', 'instruction'), {'account': 'second'});
        active = first;
        expect(cache.get('meal', 'instruction'), {'account': 'first'});
        active = null;
        expect(cache.get('meal', 'instruction'), isNull);
        await cache.set('meal', 'instruction', {'account': 'none'});
        active = first;
        expect(cache.get('meal', 'instruction'), {'account': 'first'});
      },
    );

    test(
      'request scope retains its account when a later event stores a response',
      () async {
        final requestCache = cache.forRequest();
        active = second;
        await requestCache.set('meal', 'instruction', {'account': 'first'});
        expect(cache.get('meal', 'instruction'), isNull);
        active = first;
        expect(cache.get('meal', 'instruction'), {'account': 'first'});
        active = null;
        final unavailableRequest = cache.forRequest();
        active = second;
        await unavailableRequest.set('meal', 'instruction', {
          'account': 'none',
        });
        expect(cache.get('meal', 'instruction'), isNull);
      },
    );

    test(
      'a queued write keeps the account captured when that operation started',
      () async {
        final entered = Completer<void>();
        final release = Completer<void>();
        final blocking = first.writeTxn(() async {
          entered.complete();
          await release.future;
        });
        await entered.future;
        final write = cache.set('meal', 'instruction', {'account': 'first'});
        active = second;
        release.complete();
        await blocking;
        await write;
        expect(cache.get('meal', 'instruction'), isNull);
        active = first;
        expect(cache.get('meal', 'instruction'), {'account': 'first'});
      },
    );

    test(
      'personal nutrition follows the resolver and null falls back only to the bundled table',
      () async {
        Future<void> remember(Isar database, double kcal) =>
            database.writeTxn(() async {
              await database.userFoodLogs.put(
                UserFoodLog(
                  normalizedName: 'white rice',
                  originalName: 'White Rice',
                  baseNutrition: FoodNutrition(kcal: kcal),
                  isPer100g: true,
                  provenance: 'yours',
                  addedAt: DateTime.now(),
                ),
              );
            });
        await remember(first, 111);
        await remember(second, 222);
        final lookup = NutritionLookupService(databaseResolver: () => active);
        await lookup.load();
        expect(lookup.match('White Rice')!.baseNutrition.kcal, 111);
        active = second;
        expect(lookup.match('White Rice')!.baseNutrition.kcal, 222);
        active = null;
        expect(lookup.match('White Rice')!.baseNutrition.kcal, 130);
      },
    );

    test(
      'legacy resolved text cache cannot override a freshly computed local amount',
      () async {
        await first.writeTxn(() async {
          await first.foodSearchCaches.put(
            FoodSearchCache(
              normalizedQuery: '150 grams rice',
              cachedResponseJson: '{"total":{"calories":9999}}',
              timestamp: DateTime.now(),
              schemaVersion: '1',
            ),
          );
        });
        final client = AiClient(cache: cache);
        addTearDown(client.dispose);
        final service = GeminiFoodService(
          aiClient: client,
          nutritionLookup: NutritionLookupService(
            databaseResolver: () => active,
          ),
        );
        final result = await service.analyzeFoodText('150 grams rice');
        expect(result!['total']['calories'], 195);
      },
    );
  }, skip: Platform.isLinux ? 'Native Isar is unavailable in Linux CI.' : false);
}
