import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/food_nutrition.dart';
import 'package:trufit_bodamma/models/nutrition_lookup_result.dart';
import 'package:trufit_bodamma/services/ai_client.dart';
import 'package:trufit_bodamma/services/ai_cache.dart';
import 'package:trufit_bodamma/services/ai_profiler.dart';
import 'package:trufit_bodamma/services/gemini_food_service.dart';
import 'package:trufit_bodamma/services/nutrition_lookup_service.dart';

class _MemoryCache implements AiCache {
  @override
  AiCache forRequest() => this;
  String? stored;
  final written = Completer<void>();
  @override
  Map<String, dynamic>? get(
    String prompt,
    String? instruction, [
    String? images,
    String? schema,
  ]) => stored == null ? null : jsonDecode(stored!) as Map<String, dynamic>;
  @override
  Future<void> set(
    String prompt,
    String? instruction,
    Map<String, dynamic> result, [
    String? images,
    String? schema,
  ]) async {
    await Future<void>.delayed(Duration.zero);
    stored = jsonEncode(result);
    if (!written.isCompleted) written.complete();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FailingCache extends _MemoryCache {
  @override
  Map<String, dynamic>? get(
    String prompt,
    String? instruction, [
    String? images,
    String? schema,
  ]) => throw StateError('Storage is busy');
}

class _PendingWriteCache extends _MemoryCache {
  final started = Completer<void>();
  final release = Completer<void>();
  @override
  Future<void> set(
    String prompt,
    String? instruction,
    Map<String, dynamic> result, [
    String? images,
    String? schema,
  ]) async {
    started.complete();
    await release.future;
  }
}

class _Lookup extends NutritionLookupService {
  final Completer<void>? ready;
  bool started = false;
  final NutritionLookupResult? result;
  _Lookup({this.ready, this.result});
  @override
  Future<void> load() async {
    started = true;
    await ready?.future;
  }

  @override
  NutritionLookupResult? match(String name) => result;
}

AiClient _client(Map<String, dynamic> response, {void Function()? onRequest}) =>
    AiClient(
      mockCallModel:
          ({
            required String modelName,
            required String prompt,
            String? systemInstruction,
            String? apiKey,
            List<Uint8List>? imageBytesList,
            String? mimeType,
            Duration? timeout,
            Map<String, dynamic>? responseSchema,
          }) async {
            onRequest?.call();
            return jsonEncode(response);
          },
    );

Map<String, dynamic> _meal({
  Object grams = 150,
  Map<String, dynamic>? fallback,
}) => {
  'items': [
    {
      'name': 'White Rice',
      'portion': '1 bowl',
      'estimated_grams': grams,
      if (fallback != null) 'estimated_nutrition_if_unknown': fallback,
    },
  ],
  'confidence': 'high',
};

Future<Map<String, dynamic>?> _scan(
  GeminiFoodService service, {
  CancellationToken? token,
  void Function(AiScanStage)? onProgress,
}) => service.analyzeFoodImage(
  [
    Uint8List.fromList([1, 2, 3]),
  ],
  'image/jpeg',
  null,
  true,
  true,
  token,
  null,
  onProgress,
);

void main() {
  test(
    'repeat scan keeps raw cached confidence and reuses the AI result',
    () async {
      final cache = _MemoryCache();
      var requests = 0;
      final mock = _client(
        _meal(
          fallback: {'kcal': 130, 'protein_g': 3, 'carbs_g': 28, 'fat_g': 1},
        ),
        onRequest: () => requests++,
      );
      final client = AiClient(cache: cache, mockCallModel: mock.mockCallModel);
      addTearDown(client.dispose);
      final service = GeminiFoodService(
        apiKey: 'test',
        aiClient: client,
        nutritionLookup: _Lookup(),
      );
      final first = await service.analyzeFoodImage(
        [
          Uint8List.fromList([1, 2, 3]),
        ],
        'image/jpeg',
        null,
        false,
        true,
      );
      await cache.written.future;
      expect((jsonDecode(cache.stored!) as Map)['confidence'], 'high');
      final profile = AiProfileSession();
      final second = await service.analyzeFoodImage(
        [
          Uint8List.fromList([1, 2, 3]),
        ],
        'image/jpeg',
        null,
        false,
        true,
        null,
        profile,
      );
      expect(requests, 1);
      expect(profile.cacheHit, isTrue);
      expect(first!['confidence'], 'medium');
      expect(second!['confidence'], 'medium');
      expect(second['total'], first['total']);
    },
  );

  test(
    'nutrition load overlaps inference and preserves the calculation basis',
    () async {
      final ready = Completer<void>();
      final requested = Completer<void>();
      final lookup = _Lookup(
        ready: ready,
        result: NutritionLookupResult(
          id: 'rice',
          name: 'White Rice',
          baseNutrition: FoodNutrition(
            kcal: 130,
            proteinG: 2.7,
            carbsG: 28,
            fatG: 0.3,
          ),
          isPer100g: true,
          provenance: 'verified',
        ),
      );
      final client = _client(_meal(), onRequest: requested.complete);
      addTearDown(client.dispose);
      final service = GeminiFoodService(
        apiKey: 'test',
        aiClient: client,
        nutritionLookup: lookup,
      );
      final stages = <AiScanStage>[];
      final resultFuture = _scan(service, onProgress: stages.add);
      await requested.future;
      expect(
        lookup.started,
        isTrue,
        reason: 'Loading must start before inference finishes.',
      );
      ready.complete();
      final result = (await resultFuture)!;
      expect(result['total']['calories'], 195);
      expect(result['items'][0]['baseNutrition']['kcal'], 130);
      expect(result['items'][0]['provenance'], 'verified');
      expect(stages, [
        AiScanStage.preparing,
        AiScanStage.analyzing,
        AiScanStage.resolving,
      ]);
    },
  );

  test(
    'empty detections cannot become a zero-calorie successful meal',
    () async {
      final client = _client({'items': [], 'confidence': 'high'});
      addTearDown(client.dispose);
      final service = GeminiFoodService(
        apiKey: 'test',
        aiClient: client,
        nutritionLookup: _Lookup(),
      );
      await expectLater(
        _scan(service),
        throwsA(
          isA<AiException>().having(
            (e) => e.cause,
            'cause',
            AiErrorCause.parse,
          ),
        ),
      );
    },
  );

  test('negative or missing portions require a fresh estimate', () async {
    for (final grams in [-30, 0, '150g']) {
      final client = _client(_meal(grams: grams));
      addTearDown(client.dispose);
      final service = GeminiFoodService(
        apiKey: 'test',
        aiClient: client,
        nutritionLookup: _Lookup(),
      );
      await expectLater(_scan(service), throwsA(isA<AiException>()));
    }
  });

  test(
    'unrecognized nutrition stays unresolved instead of inventing values',
    () async {
      final client = _client(
        _meal(
          fallback: {'kcal': -100, 'protein_g': 5, 'carbs_g': 20, 'fat_g': 3},
        ),
      );
      addTearDown(client.dispose);
      final service = GeminiFoodService(
        apiKey: 'test',
        aiClient: client,
        nutritionLookup: _Lookup(),
      );
      final result = (await _scan(service))!;
      expect(result['items'][0]['resolved'], isFalse);
      expect(result['total']['unresolved_count'], 1);
      expect(result['confidence'], 'medium');
    },
  );

  test('per-serving memory without gram weight stays reviewable', () async {
    final client = _client(_meal());
    addTearDown(client.dispose);
    final lookup = _Lookup(
      result: NutritionLookupResult(
        id: 'personal',
        name: 'White Rice',
        baseNutrition: FoodNutrition(kcal: 200),
        isPer100g: false,
        provenance: 'yours',
      ),
    );
    final result = (await _scan(
      GeminiFoodService(
        apiKey: 'test',
        aiClient: client,
        nutritionLookup: lookup,
      ),
    ))!;
    expect(result['items'][0]['resolved'], isFalse);
    expect(result['total']['unresolved_count'], 1);
  });

  test('cancellation interrupts a pending nutrition load', () async {
    final ready = Completer<void>();
    final requested = Completer<void>();
    final client = _client(_meal(), onRequest: requested.complete);
    addTearDown(client.dispose);
    final token = CancellationToken();
    final service = GeminiFoodService(
      apiKey: 'test',
      aiClient: client,
      nutritionLookup: _Lookup(ready: ready),
    );
    final result = _scan(service, token: token);
    final expectation = expectLater(
      result,
      throwsA(
        isA<AiException>().having(
          (e) => e.cause,
          'cause',
          AiErrorCause.cancelled,
        ),
      ),
    );
    await requested.future;
    token.cancel();
    await expectation;
    ready.complete();
  });
  test('optional cache read failure falls through to a fresh scan', () async {
    var requests = 0;
    final mock = _client(_meal(), onRequest: () => requests++);
    final client = AiClient(
      cache: _FailingCache(),
      mockCallModel: mock.mockCallModel,
    );
    addTearDown(client.dispose);
    final service = GeminiFoodService(
      apiKey: 'test',
      aiClient: client,
      nutritionLookup: _Lookup(),
    );
    final result = await service
        .analyzeFoodText('2 idlis')
        .timeout(const Duration(seconds: 2));
    expect(requests, 1);
    expect(result!['items'], isNotEmpty);
  });

  test(
    'a blocked optional cache write never delays usable text results',
    () async {
      final cache = _PendingWriteCache();
      addTearDown(() {
        if (!cache.release.isCompleted) cache.release.complete();
      });
      final mock = _client(_meal());
      final client = AiClient(cache: cache, mockCallModel: mock.mockCallModel);
      addTearDown(client.dispose);
      final service = GeminiFoodService(
        apiKey: 'test',
        aiClient: client,
        nutritionLookup: _Lookup(),
      );
      final result = await service
          .analyzeFoodText('2 idlis')
          .timeout(const Duration(seconds: 2));
      await cache.started.future;
      expect(result!['items'], isNotEmpty);
      expect(cache.release.isCompleted, isFalse);
    },
  );

  test(
    'semantically invalid raw meals are not cached on failed scans',
    () async {
      final cache = _MemoryCache();
      var requests = 0;
      final mock = _client({
        'items': [],
        'confidence': 'high',
      }, onRequest: () => requests++);
      final client = AiClient(cache: cache, mockCallModel: mock.mockCallModel);
      addTearDown(client.dispose);
      final service = GeminiFoodService(
        apiKey: 'test',
        aiClient: client,
        nutritionLookup: _Lookup(),
      );
      for (var i = 0; i < 2; i++) {
        await expectLater(
          service.analyzeFoodText('2 idlis'),
          throwsA(isA<AiException>()),
        );
      }
      await Future<void>.delayed(Duration.zero);
      expect(requests, 2);
      expect(cache.stored, isNull);
      expect(cache.written.isCompleted, isFalse);
    },
  );

  test(
    'invalid historical cache entries are bypassed for a fresh estimate',
    () async {
      final cache = _MemoryCache()
        ..stored = jsonEncode({'items': [], 'confidence': 'high'});
      var requests = 0;
      final mock = _client(_meal(), onRequest: () => requests++);
      final client = AiClient(cache: cache, mockCallModel: mock.mockCallModel);
      addTearDown(client.dispose);
      final service = GeminiFoodService(
        apiKey: 'test',
        aiClient: client,
        nutritionLookup: _Lookup(),
      );
      final profile = AiProfileSession();
      final result = await service.analyzeFoodText('2 idlis', null, profile);
      expect(result!['items'], isNotEmpty);
      expect(requests, 1);
      expect(profile.cacheHit, isFalse);
      await cache.written.future;
      expect((jsonDecode(cache.stored!) as Map)['items'], isNotEmpty);
    },
  );

  test(
    'repeated text inference re-resolves current nutrition from raw cache',
    () async {
      final cache = _MemoryCache();
      var requests = 0;
      final mock = _client(_meal(grams: 80), onRequest: () => requests++);
      final client = AiClient(cache: cache, mockCallModel: mock.mockCallModel);
      addTearDown(client.dispose);
      GeminiFoodService service(double kcal) => GeminiFoodService(
        apiKey: 'test',
        aiClient: client,
        nutritionLookup: _Lookup(
          result: NutritionLookupResult(
            id: 'idli',
            name: 'Idli',
            isPer100g: true,
            servingGrams: 100,
            baseNutrition: FoodNutrition(kcal: kcal),
            provenance: 'yours',
          ),
        ),
      );
      final first = await service(150).analyzeFoodText('2 idlis');
      await cache.written.future;
      final profile = AiProfileSession();
      final second = await service(
        200,
      ).analyzeFoodText('2 idlis', null, profile);
      expect(requests, 1);
      expect(profile.cacheHit, isTrue);
      expect(first!['total']['calories'], 120);
      expect(second!['total']['calories'], 160);
    },
  );

  test(
    'explicit gram variants resolve locally without API key or cache access',
    () async {
      var requests = 0;
      final mock = _client(_meal(), onRequest: () => requests++);
      final client = AiClient(
        cache: _FailingCache(),
        mockCallModel: mock.mockCallModel,
      );
      addTearDown(client.dispose);
      final lookup = _Lookup(
        result: NutritionLookupResult(
          id: 'rice',
          name: 'White Rice',
          isPer100g: true,
          baseNutrition: FoodNutrition(kcal: 130),
          servingGrams: 100,
        ),
      );
      final service = GeminiFoodService(
        aiClient: client,
        nutritionLookup: lookup,
      );
      for (final description in [
        '150 grams rice',
        '150 gram rice',
        '150g rice',
        '150 g rice',
      ]) {
        final result = await service
            .analyzeFoodText(description)
            .timeout(const Duration(seconds: 2));
        expect(result!['total']['calories'], 195, reason: description);
        expect(result['items'][0]['estimated_grams'], 150, reason: description);
      }
      expect(requests, 0);
    },
  );

  test(
    'counted idlis do not treat default portion mass as one piece',
    () async {
      var requests = 0;
      final client = _client(_meal(grams: 80), onRequest: () => requests++);
      addTearDown(client.dispose);
      final service = GeminiFoodService(
        apiKey: 'test',
        aiClient: client,
        nutritionLookup: _Lookup(
          result: NutritionLookupResult(
            id: 'idli',
            name: 'Idli',
            isPer100g: true,
            servingGrams: 100,
            baseNutrition: FoodNutrition(kcal: 150),
          ),
        ),
      );
      final result = await service.analyzeFoodText('2 idlis');
      expect(requests, 1);
      expect(result!['items'][0]['estimated_grams'], 80);
      expect(result['total']['calories'], 120);
    },
  );

  test(
    'volume quantities do not silently become grams in the local shortcut',
    () async {
      var requests = 0;
      final client = _client(_meal(grams: 120), onRequest: () => requests++);
      addTearDown(client.dispose);
      final service = GeminiFoodService(
        apiKey: 'test',
        aiClient: client,
        nutritionLookup: _Lookup(
          result: NutritionLookupResult(
            id: 'rice',
            name: 'White Rice',
            isPer100g: true,
            servingGrams: 150,
            baseNutrition: FoodNutrition(kcal: 130),
          ),
        ),
      );
      for (final description in ['200 ml rice', '1 cup rice', '1 bowl rice']) {
        final result = await service.analyzeFoodText(description);
        expect(result!['items'][0]['estimated_grams'], 120);
      }
      expect(requests, 3);
    },
  );

  test(
    'cancelling text preparation returns without waiting for nutrition assets',
    () async {
      final ready = Completer<void>();
      final token = CancellationToken();
      var requests = 0;
      final client = _client(_meal(), onRequest: () => requests++);
      addTearDown(client.dispose);
      final lookup = _Lookup(ready: ready);
      final service = GeminiFoodService(
        apiKey: 'test',
        aiClient: client,
        nutritionLookup: lookup,
      );
      final result = service.analyzeFoodText('2 idlis', token);
      final expectation = expectLater(
        result,
        throwsA(
          isA<AiException>().having(
            (e) => e.cause,
            'cause',
            AiErrorCause.cancelled,
          ),
        ),
      );
      token.cancel();
      await expectation.timeout(const Duration(seconds: 2));
      ready.complete();
      expect(requests, 0);
    },
  );
}
