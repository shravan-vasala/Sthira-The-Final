import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trufit_bodamma/models/packaged_food.dart';
import 'package:trufit_bodamma/services/barcode_food_service.dart';

const _code = '0012345678905';

Map<String, dynamic> _product({
  Map<String, dynamic>? nutrients,
  Map<String, dynamic> overrides = const {},
}) => {
  'code': _code,
  'product_name': 'Protein biscuit',
  'brands': 'Sample brand',
  'product_quantity': 200,
  'product_quantity_unit': 'g',
  'nutrition_data_per': '100g',
  'nutriments':
      nutrients ??
      {
        'energy-kcal_100g': 420,
        'proteins_100g': 10,
        'carbohydrates_100g': 60,
        'fat_100g': 15,
      },
  ...overrides,
};

BarcodeFoodService _service(Map<String, dynamic> product) => BarcodeFoodService(
  client: MockClient(
    (_) async => http.Response(
      jsonEncode({'status': 'success', 'product': product}),
      200,
    ),
  ),
);

Matcher _error(BarcodeLookupError kind) =>
    isA<BarcodeLookupException>().having((error) => error.kind, 'kind', kind);

void main() {
  test(
    'requests food only, narrow fields and India locale with user agent',
    () async {
      final service = BarcodeFoodService(
        client: MockClient((request) async {
          expect(request.url.host, 'world.openfoodfacts.org');
          expect(request.url.path, '/api/v3/product/$_code');
          expect(request.url.queryParameters['cc'], 'in');
          expect(request.url.queryParameters['lc'], 'en');
          expect(request.url.queryParameters['product_type'], 'food');
          expect(request.url.queryParameters['fields'], contains('nutriments'));
          expect(
            request.url.queryParameters['fields'],
            isNot(contains('images')),
          );
          expect(request.headers['User-Agent'], startsWith('Sthira/'));
          return http.Response(
            jsonEncode({'status': 'success', 'product': _product()}),
            200,
          );
        }),
      );
      final food = await service.lookup(_code);
      expect(food.barcode, _code);
      expect(food.name, 'Protein biscuit');
      expect(food.brand, 'Sample brand');
      expect(food.basis, NutritionBasis.per100g);
      expect(food.computeNutrition(50).kcal, 210);
      expect(food.source, PackagedFoodSource.openFoodFacts);
    },
  );

  test(
    'real Amul milk shape requires confirming volume despite 100g flag',
    () async {
      // Read-only live API check, 2026-09-19: quantity/unit fields absent.
      final food = await _service({
        'code': _code,
        'product_name': 'Amul Taaza milk 500ml',
        'nutrition_data_per': '100g',
        'nutriments': {
          'energy-kcal_100g': 58.2,
          'energy_100g': 243.6,
          'proteins_100g': 3,
          'carbohydrates_100g': 4.8,
          'fat_100g': 3,
        },
      }).lookup(_code);
      expect(food.kcal, 58.2);
      expect(food.basis, isNull);
      expect(food.hasCompleteNutrition, isFalse);
    },
  );

  test(
    'unrecognized lookup status cannot be treated as a successful product',
    () async {
      final service = BarcodeFoodService(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'status': 'unknown', 'product': _product()}),
            200,
          ),
        ),
      );
      await expectLater(
        service.lookup(_code),
        throwsA(_error(BarcodeLookupError.invalidResponse)),
      );
    },
  );

  test('OFF liquid _100g suffix is interpreted as per100ml', () async {
    final food = await _service(
      _product(
        overrides: {'product_quantity': 500, 'product_quantity_unit': 'ml'},
      ),
    ).lookup(_code);
    expect(food.basis, NutritionBasis.per100ml);
    expect(food.packageUnit, FoodQuantityUnit.millilitres);
    expect(food.computeNutrition(250).kcal, 1050);
  });

  test(
    'normalized energy is kJ even when original energy_unit was kcal',
    () async {
      final food = await _service(
        _product(
          nutrients: {
            'energy_100g': 418.4,
            'energy_unit': 'kcal',
            'proteins_100g': 0,
            'carbohydrates_100g': 25,
            'fat_100g': 0,
          },
        ),
      ).lookup(_code);
      expect(food.kcal, closeTo(100, 0.0001));
      expect(food.hasCompleteNutrition, isTrue);
    },
  );

  test('explicit kcal takes precedence over kJ', () async {
    final food = await _service(
      _product(
        nutrients: {
          'energy-kcal_100g': 100,
          'energy-kj_100g': 420,
          'proteins_100g': 0,
          'carbohydrates_100g': 25,
          'fat_100g': 0,
        },
      ),
    ).lookup(_code);
    expect(food.kcal, 100);
  });

  test(
    'missing macros remain unknown while explicit zeros are valid',
    () async {
      final food = await _service(
        _product(
          nutrients: {
            'energy-kcal_100g': 0,
            'proteins_100g': 0,
            'carbohydrates_100g': 0,
          },
        ),
      ).lookup(_code);
      expect(food.kcal, 0);
      expect(food.fatG, isNull);
      expect(food.hasCompleteNutrition, isFalse);
    },
  );

  test('unknown quantity units require basis confirmation', () async {
    final food = await _service(
      _product(
        overrides: {'product_quantity_unit': null, 'quantity': '6 pieces'},
      ),
    ).lookup(_code);
    expect(food.basis, isNull);
    expect(food.hasCompleteNutrition, isFalse);
    expect(food.kcal, 420);
    expect(food.packageQuantity, isNull);
  });

  test(
    'conflicting mass and volume measurements require confirmation',
    () async {
      final food = await _service(
        _product(
          overrides: {'serving_quantity': 100, 'serving_quantity_unit': 'ml'},
        ),
      ).lookup(_code);
      expect(food.basis, isNull);
      expect(food.hasCompleteNutrition, isFalse);
    },
  );

  test(
    'simple explicit litres and kilograms normalize without assumptions',
    () async {
      final liquid = await _service(
        _product(
          overrides: {
            'product_quantity': null,
            'product_quantity_unit': null,
            'quantity': '1.5 L',
            'serving_size': '250 ml',
          },
        ),
      ).lookup(_code);
      final solid = await _service(
        _product(
          overrides: {
            'product_quantity': null,
            'product_quantity_unit': null,
            'quantity': '0,5 kg',
          },
        ),
      ).lookup(_code);
      expect(liquid.packageQuantity, 1500);
      expect(liquid.servingQuantity, 250);
      expect(liquid.basis, NutritionBasis.per100ml);
      expect(solid.packageQuantity, 500);
      expect(solid.basis, NutritionBasis.per100g);
    },
  );

  test(
    'normalized multipacks use total quantity, not one individual pack',
    () async {
      final food = await _service(
        _product(
          overrides: {
            'product_quantity': 600,
            'product_quantity_unit': 'ml',
            'quantity': '3 x 200 ml',
          },
        ),
      ).lookup(_code);
      expect(food.packageQuantity, 600);
      expect(food.packageUnit, FoodQuantityUnit.millilitres);
    },
  );

  test('unparsed multipacks and ounces are not guessed', () async {
    for (final label in ['3 x 200 ml', '12 fl oz', '6 oz', '1,000 g']) {
      final food = await _service(
        _product(
          overrides: {
            'product_quantity': null,
            'product_quantity_unit': null,
            'quantity': label,
          },
        ),
      ).lookup(_code);
      expect(food.packageQuantity, isNull);
      expect(food.basis, isNull);
    }
  });

  test(
    'per-serving labels retain their values and known serving volume',
    () async {
      final food = await _service(
        _product(
          overrides: {
            'nutrition_data_per': 'serving',
            'product_quantity_unit': 'ml',
            'serving_quantity': 250,
            'serving_quantity_unit': 'ml',
          },
          nutrients: {
            'energy-kcal_serving': 120,
            'proteins_serving': 6,
            'carbohydrates_serving': 12,
            'fat_serving': 5,
          },
        ),
      ).lookup(_code);
      expect(food.basis, NutritionBasis.perServing);
      expect(food.servingQuantity, 250);
      expect(food.computeNutrition(0.5).kcal, 60);
    },
  );

  test(
    'no label nutrition does not use residual or prepared nutrients',
    () async {
      final food = await _service(
        _product(overrides: {'no_nutrition_data': 'on'}),
      ).lookup(_code);
      expect(food.kcal, isNull);
      expect(food.hasCompleteNutrition, isFalse);
      final prepared = await _service(
        _product(
          nutrients: {
            'energy-kcal_prepared_100g': 300,
            'proteins_prepared_100g': 20,
            'carbohydrates_prepared_100g': 30,
            'fat_prepared_100g': 10,
          },
        ),
      ).lookup(_code);
      expect(prepared.hasCompleteNutrition, isFalse);
    },
  );

  test(
    'negative, nonfinite and qualified values cannot become complete',
    () async {
      final food = await _service(
        _product(
          nutrients: {
            'energy-kcal_100g': '-1',
            'proteins_100g': 'NaN',
            'carbohydrates_100g': 'Infinity',
            'fat_100g': 1,
            'fat_modifier': '<',
          },
        ),
      ).lookup(_code);
      expect([
        food.kcal,
        food.proteinG,
        food.carbsG,
        food.fatG,
      ], everyElement(isNull));
    },
  );

  test('numeric strings and absent product name remain reviewable', () async {
    final food = await _service(
      _product(
        overrides: {'product_name': null},
        nutrients: {
          'energy-kcal_100g': '100',
          'proteins_100g': '0',
          'carbohydrates_100g': '25.0',
          'fat_100g': '0',
        },
      ),
    ).lookup(_code);
    expect(food.name, '');
    expect(food.kcal, 100);
  });

  test(
    'a server normalized barcode may add leading zero without changing identity',
    () async {
      final food = await _service(
        _product(overrides: {'code': '00012345678905'}),
      ).lookup(_code);
      expect(food.barcode, _code);
    },
  );

  test('a mismatched barcode is an invalid response', () async {
    await expectLater(
      _service(_product(overrides: {'code': '3017620422003'})).lookup(_code),
      throwsA(_error(BarcodeLookupError.invalidResponse)),
    );
  });

  test('invalid barcode input never starts a network request', () async {
    final service = BarcodeFoodService(
      client: MockClient((_) async {
        fail('Invalid barcode must not be requested');
      }),
    );
    for (final code in ['123', 'http://example.com', '1234abcd', '123456789']) {
      await expectLater(
        service.lookup(code),
        throwsA(_error(BarcodeLookupError.invalidBarcode)),
      );
    }
  });

  test(
    'not found, rate limit and unavailable are distinct with nonJSON bodies',
    () async {
      for (final entry in {
        404: BarcodeLookupError.notFound,
        429: BarcodeLookupError.rateLimited,
        503: BarcodeLookupError.unavailable,
      }.entries) {
        final service = BarcodeFoodService(
          client: MockClient(
            (_) async => http.Response('<html>error</html>', entry.key),
          ),
        );
        await expectLater(service.lookup(_code), throwsA(_error(entry.value)));
      }
    },
  );

  test('malformed response is distinct from missing product', () async {
    for (final body in ['not json', '[]', '{}', '{"product":{}}']) {
      final service = BarcodeFoodService(
        client: MockClient((_) async => http.Response(body, 200)),
      );
      await expectLater(
        service.lookup(_code),
        throwsA(_error(BarcodeLookupError.invalidResponse)),
      );
    }
  });

  test('v3 product_not_found result is recognized', () async {
    final service = BarcodeFoodService(
      client: MockClient(
        (_) async => http.Response(
          '{"status":"failure","result":{"id":"product_not_found"}}',
          200,
        ),
      ),
    );
    await expectLater(
      service.lookup(_code),
      throwsA(_error(BarcodeLookupError.notFound)),
    );
  });

  test('transport failure has a recoverable network error', () async {
    final service = BarcodeFoodService(
      client: MockClient((_) async {
        throw http.ClientException('offline');
      }),
    );
    await expectLater(
      service.lookup(_code),
      throwsA(_error(BarcodeLookupError.network)),
    );
  });

  test(
    'deadline includes response body and aborts the outstanding request',
    () async {
      final client = _HangingClient();
      final service = BarcodeFoodService(
        client: client,
        timeout: const Duration(milliseconds: 10),
      );
      await expectLater(
        service.lookup(_code),
        throwsA(_error(BarcodeLookupError.timeout)),
      );
      await client.aborted.future.timeout(const Duration(seconds: 1));
      expect(client.aborted.isCompleted, isTrue);
      await client.body.close();
    },
  );
}

class _HangingClient extends http.BaseClient {
  final body = StreamController<List<int>>();
  final aborted = Completer<void>();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    unawaited(
      (request as http.AbortableRequest).abortTrigger!.then(
        (_) => aborted.complete(),
      ),
    );
    return http.StreamedResponse(body.stream, 200);
  }
}
