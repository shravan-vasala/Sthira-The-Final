import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trufit_bodamma/models/packaged_food.dart';
import 'package:trufit_bodamma/repositories/barcode_food_store.dart';

PackagedFood _food({
  String barcode = '123456789012',
  String name = 'Milk',
  String brand = 'Dairy A',
  double? kcal = 60,
  NutritionBasis? basis = NutritionBasis.per100ml,
}) => PackagedFood(
  barcode: barcode,
  name: name,
  brand: brand,
  basis: basis,
  kcal: kcal,
  proteinG: 3,
  carbsG: 5,
  fatG: 3,
  packageQuantity: 500,
  packageUnit: FoodQuantityUnit.millilitres,
  source: PackagedFoodSource.manual,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences preferences;
  late BarcodeFoodStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    store = BarcodeFoodStore(preferences, accountId: 'first-user');
  });

  test(
    'saved product and amount are available offline after reopening',
    () async {
      await store.remember(_food(), 250);
      final reopened = BarcodeFoodStore(preferences, accountId: 'first-user');
      final saved = reopened.find('123456789012')!;
      expect(saved.food.toJson(), _food().toJson());
      expect(saved.lastAmount, 250);
      expect(saved.food.computeNutrition(saved.lastAmount!).kcal, 150);
    },
  );

  test('UPC-A and zero-padded EAN13/GTIN14 update the same shortcut', () async {
    await store.remember(_food(), 100);
    expect(store.find('0123456789012')!.lastAmount, 100);
    expect(store.find('00123456789012')!.lastAmount, 100);
    await store.remember(_food(barcode: '00123456789012', kcal: 65), 250);
    expect(store.recent, hasLength(1));
    expect(store.find('123456789012')!.food.kcal, 65);
    expect(store.find('0123456789012')!.lastAmount, 250);
  });

  test('EAN8 and padded GTIN14 refer to one shortcut', () async {
    await store.remember(_food(barcode: '12345670'), 100);
    expect(store.find('00000012345670'), isNotNull);
  });

  test('GTIN14 package indicator keeps different packaging separate', () async {
    await store.remember(_food(), 100);
    await store.remember(_food(barcode: '10123456789019'), 100);
    expect(store.recent, hasLength(2));
  });

  test(
    'same food name with different barcode or brand does not collide',
    () async {
      await store.remember(_food(), 100);
      await store.remember(
        _food(barcode: '123456789013', brand: 'Dairy B'),
        200,
      );
      expect(store.recent, hasLength(2));
      expect(store.find('123456789012')!.food.brand, 'Dairy A');
      expect(store.find('123456789013')!.food.brand, 'Dairy B');
    },
  );

  test('accounts, guest and markets have separate saved products', () async {
    await store.remember(_food(), 100);
    for (final other in [
      BarcodeFoodStore(preferences, accountId: 'second-user'),
      BarcodeFoodStore(preferences, accountId: 'guest'),
      BarcodeFoodStore(preferences, accountId: 'first-user', market: 'us'),
    ]) {
      expect(other.recent, isEmpty);
      expect(other.find('123456789012'), isNull);
    }
    expect(store.recent, hasLength(1));
  });

  test(
    'incomplete and unnamed products cannot replace a valid shortcut',
    () async {
      await store.remember(_food(), 100);
      for (final invalid in [
        _food(kcal: null),
        _food(basis: null),
        _food(name: '  '),
        _food(barcode: 'invalid'),
      ]) {
        await expectLater(store.remember(invalid, 100), throwsFormatException);
      }
      expect(store.recent, hasLength(1));
      expect(store.recent.single.food.kcal, 60);
      expect(store.find('invalid'), isNull);
    },
  );

  test('invalid amount cannot be remembered', () async {
    for (final amount in [0.0, -1.0, double.nan, double.infinity]) {
      await expectLater(store.remember(_food(), amount), throwsFormatException);
    }
    expect(store.recent, isEmpty);
  });

  test(
    'corrupt entries do not hide valid products or enable invalid data',
    () async {
      await store.remember(_food(), 100);
      final key = preferences.getKeys().single;
      final entries = jsonDecode(preferences.getString(key)!) as List;
      final valid = entries.single as Map<String, dynamic>;
      await preferences.setString(
        key,
        jsonEncode([
          null,
          42,
          {},
          {
            ...valid,
            'food': {..._food().toJson(), 'barcode': 'invalid'},
          },
          {
            ...valid,
            'food': {..._food().toJson(), 'kcal': null},
          },
          {
            ...valid,
            'food': {..._food().toJson(), 'name': ''},
          },
          {...valid, 'saved_at': 'not a date'},
          valid,
        ]),
      );
      expect(store.recent, hasLength(1));
      expect(store.find('123456789012')!.food.kcal, 60);
    },
  );

  test(
    'corrupt top-level JSON and wrong preference type are recoverable',
    () async {
      await store.remember(_food(), 100);
      final key = preferences.getKeys().single;
      for (final raw in ['{', '{}', 'null']) {
        await preferences.setString(key, raw);
        expect(store.recent, isEmpty);
      }
      await preferences.setInt(key, 17);
      expect(store.recent, isEmpty);
      await store.remember(_food(), 150);
      expect(store.recent.single.lastAmount, 150);
    },
  );

  test(
    'unusable last amount is discarded without losing valid product',
    () async {
      await store.remember(_food(), 100);
      final key = preferences.getKeys().single;
      final entries = jsonDecode(preferences.getString(key)!) as List;
      (entries.single as Map<String, dynamic>)['last_amount'] = -5;
      await preferences.setString(key, jsonEncode(entries));
      expect(store.recent.single.lastAmount, isNull);
      expect(store.recent.single.food.hasCompleteNutrition, isTrue);
    },
  );

  test('duplicate persisted aliases retain the most recent snapshot', () async {
    await store.remember(_food(), 100);
    final key = preferences.getKeys().single;
    final valid =
        (jsonDecode(preferences.getString(key)!) as List).single as Map;
    await preferences.setString(
      key,
      jsonEncode([
        {...valid, 'saved_at': '2026-01-01T00:00:00Z'},
        {
          ...valid,
          'food': _food(barcode: '00123456789012', kcal: 65).toJson(),
          'saved_at': '2026-02-01T00:00:00Z',
        },
      ]),
    );
    expect(store.recent, hasLength(1));
    expect(store.recent.single.food.kcal, 65);
  });

  test('recent shortcut storage is bounded', () async {
    for (var i = 0; i < BarcodeFoodStore.maximumProducts + 3; i++) {
      await store.remember(_food(barcode: (123456780000 + i).toString()), 100);
    }
    expect(store.recent, hasLength(BarcodeFoodStore.maximumProducts));
    expect(store.find('123456780000'), isNull);
    expect(store.find('123456780062'), isNotNull);
  });
}
