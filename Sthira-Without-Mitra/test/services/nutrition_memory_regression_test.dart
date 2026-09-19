import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:trufit_bodamma/models/food_nutrition.dart';
import 'package:trufit_bodamma/models/user_food_log.dart';
import 'package:trufit_bodamma/services/nutrition_lookup_service.dart';
import 'package:trufit_bodamma/utils/food_name.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Isar database;
  setUp(() async {
    await Isar.initializeIsarCore(download: true);
    final directory = await Directory.systemTemp.createTemp(
      'food-memory-regression-',
    );
    database = await Isar.open(
      [UserFoodLogSchema],
      directory: directory.path,
      name: 'food-memory-${DateTime.now().microsecondsSinceEpoch}',
    );
  });
  tearDown(() async {
    await database.close();
  });

  test(
    'canonical personal corrections round-trip punctuation whitespace and Telugu',
    () async {
      final names = [
        "Mom's Dal",
        'Iced   Coffee',
        '\u0c2a\u0c2a\u0c4d\u0c2a\u0c41',
      ];
      await database.writeTxn(() async {
        for (final name in names) {
          await database.userFoodLogs.put(
            UserFoodLog(
              normalizedName: canonicalFoodName(name),
              originalName: name,
              baseNutrition: FoodNutrition(kcal: 321),
              servingGrams: 150,
              provenance: 'yours',
              addedAt: DateTime.now(),
            ),
          );
        }
      });
      final lookup = NutritionLookupService(database: database);
      await lookup.load();
      for (final name in ["  MOM'S DAL! ", 'iced coffee', names.last]) {
        final match = lookup.match(name)!;
        expect(match.baseNutrition.kcal, 321);
        expect(match.servingGrams, 150);
        expect(match.provenance, 'yours');
        expect(match.estimated, isFalse);
      }
    },
  );

  test(
    'legacy lowercase-only corrections remain readable and never leak via a null resolver',
    () async {
      await database.writeTxn(() async {
        await database.userFoodLogs.put(
          UserFoodLog(
            normalizedName: "mom's  dal",
            originalName: "Mom's  Dal",
            baseNutrition: FoodNutrition(kcal: 222),
            provenance: 'ai_estimate',
            servingGrams: 100,
            addedAt: DateTime.now(),
          ),
        );
      });
      final lookup = NutritionLookupService(database: database);
      await lookup.load();
      expect(lookup.match("Mom's Dal")!.baseNutrition.kcal, 222);
      expect(lookup.match("Mom's Dal")!.estimated, isTrue);
      final disconnected = NutritionLookupService(databaseResolver: () => null);
      await disconnected.load();
      expect(disconnected.match("Mom's Dal"), isNull);
    },
  );
}
