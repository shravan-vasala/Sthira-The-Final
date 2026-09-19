import 'package:trufit_bodamma/models/coach_context.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleai_dart/googleai_dart.dart'
    show ApiException, RequestMetadata, ResponseMetadata;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trufit_bodamma/models/food_nutrition.dart';
import 'package:trufit_bodamma/models/nutrition_lookup_result.dart';
import 'package:trufit_bodamma/services/ai_client.dart';
import 'package:trufit_bodamma/services/gemini_food_service.dart';
import 'package:trufit_bodamma/services/nutrition_lookup_service.dart';
import 'package:trufit_bodamma/services/coach_service.dart';
import 'package:trufit_bodamma/utils/food_name.dart';

class _Lookup extends NutritionLookupService {
  final NutritionLookupResult? result;
  _Lookup([this.result]);
  @override
  Future<void> load() async {}
  @override
  NutritionLookupResult? match(String name) => result;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('HTTP status wins over conflicting request metadata', () {
    for (final status in [401, 403, 404, 429, 503]) {
      final error = ApiException(
        statusCode: status,
        message: 'Request failed',
        requestMetadata: RequestMetadata(
          method: 'POST',
          url: Uri.parse('https://example.com/403/429'),
          headers: const {},
          correlationId: 'req_403429503',
          timestamp: DateTime(2026),
        ),
        responseMetadata: ResponseMetadata(
          statusCode: status,
          headers: const {},
          bodyExcerpt: '',
          latency: const Duration(milliseconds: 403),
        ),
      );
      expect(
        classifyAiError(error),
        {
          401: AiErrorCause.invalidKey,
          403: AiErrorCause.invalidKey,
          404: AiErrorCause.notFound,
          429: AiErrorCause.rateLimited,
          503: AiErrorCause.overloaded,
        }[status],
      );
    }
    expect(
      classifyAiError('request id 403429 took 503ms'),
      AiErrorCause.unknown,
    );
    expect(
      classifyAiError('API_KEY_INVALID', statusCode: 400),
      AiErrorCause.invalidKey,
    );
  });

  test(
    'already cancelled stream terminates without starting transport',
    () async {
      var calls = 0;
      final client = AiClient(
        mockCallModelStream:
            ({
              required modelName,
              required prompt,
              required systemInstruction,
              apiKey,
            }) {
              calls++;
              return const Stream.empty();
            },
      );
      final token = CancellationToken()..cancel();
      await expectLater(
        client
            .generateTextStream(
              prompt: 'p',
              systemInstruction: 's',
              apiKey: 'k',
              cancellationToken: token,
            )
            .toList(),
        throwsA(
          isA<AiException>().having(
            (e) => e.cause,
            'cause',
            AiErrorCause.cancelled,
          ),
        ),
      );
      expect(calls, 0);
    },
  );

  test(
    'token cancellation closes silent stream despite stalled upstream cancellation',
    () async {
      var cancelled = false;
      final never = Completer<void>();
      final source = StreamController<String>(
        onCancel: () {
          cancelled = true;
          return never.future;
        },
      );
      final client = AiClient(
        mockCallModelStream:
            ({
              required modelName,
              required prompt,
              required systemInstruction,
              apiKey,
            }) => source.stream,
      );
      final token = CancellationToken();
      final done = client
          .generateTextStream(
            prompt: 'p',
            systemInstruction: 's',
            apiKey: 'k',
            cancellationToken: token,
          )
          .toList();
      final assertion = expectLater(
        done.timeout(const Duration(seconds: 1)),
        throwsA(
          isA<AiException>().having(
            (e) => e.cause,
            'cause',
            AiErrorCause.cancelled,
          ),
        ),
      );
      token.cancel();
      await assertion;
      expect(cancelled, isTrue);
      never.complete();
    },
  );

  test(
    'per-serving memory retains source basis through both portion directions',
    () async {
      final lookup = _Lookup(
        NutritionLookupResult(
          id: 'oats',
          name: 'My oats',
          baseNutrition: FoodNutrition(
            kcal: 100,
            proteinG: 5,
            carbsG: 15,
            fatG: 2,
          ),
          isPer100g: false,
          servingGrams: 50,
          provenance: 'yours',
          estimated: false,
        ),
      );
      final service = GeminiFoodService(
        aiClient: AiClient(),
        nutritionLookup: lookup,
      );
      final result = (await service.analyzeFoodText('100 g my oats'))!;
      final item = result['items'][0] as Map;
      expect(item['calories'], 200);
      expect(item['estimated_grams'], 100);
      expect(item['serving_grams'], 50);
      // Round-trip the persisted nutrition basis before applying portion changes.
      final stored = jsonDecode(jsonEncode(item)) as Map;
      for (final scale in [0.5, 1.0, 2.0]) {
        final nutrition = FoodNutrition.compute(
          consumedGrams: 100 * scale,
          baseNutrition: FoodNutrition.fromJson(
            Map<String, dynamic>.from(stored['baseNutrition']),
          ),
          isPer100g: stored['is_per_100g'],
          servingGrams: stored['serving_grams'],
        );
        expect(nutrition.kcal, 200 * scale);
      }
    },
  );

  test(
    'powder never aliases a prepared drink; recipes retain estimated provenance',
    () async {
      final lookup = NutritionLookupService(databaseResolver: () => null);
      await lookup.load();
      expect(lookup.match('whey protein'), isNull);
      final drink = lookup.match('Protein Shake')!;
      expect(drink.estimated, isTrue);
      expect(drink.provenance, 'database_estimate');
      expect(drink.preparation, contains('prepared'));
      expect(
        canonicalFoodName(" Mom's   Dal! "),
        canonicalFoodName('mom s dal'),
      );
      expect(
        canonicalFoodName('\u0c2a\u0c2a\u0c4d\u0c2a\u0c41'),
        '\u0c2a\u0c2a\u0c4d\u0c2a\u0c41',
      );
    },
  );

  test(
    'common-food fallback requested; implausible composition and oversized portions require review',
    () async {
      Future<Map<String, dynamic>> scan(
        double grams,
        Map<String, num> nutrition,
      ) async {
        final client = AiClient(
          mockCallModel:
              ({
                required modelName,
                required prompt,
                systemInstruction,
                apiKey,
                List<Uint8List>? imageBytesList,
                mimeType,
                Duration timeout = const Duration(seconds: 30),
                responseSchema,
              }) async {
                final schema =
                    responseSchema!['properties']['items']['items']['properties'];
                expect(
                  schema['estimated_nutrition_if_unknown']['description'],
                  contains('every identified food'),
                );
                return jsonEncode({
                  'items': [
                    {
                      'name': 'Apple',
                      'portion': '$grams g',
                      'estimated_grams': grams,
                      'estimated_nutrition_if_unknown': nutrition,
                    },
                  ],
                  'confidence': 'high',
                });
              },
        );
        return (await GeminiFoodService(
          apiKey: 'k',
          aiClient: client,
          nutritionLookup: _Lookup(),
        ).analyzeFoodText('an apple'))!;
      }

      final valid = await scan(100, {
        'kcal': 52,
        'protein_g': 0.3,
        'carbs_g': 14,
        'fat_g': 0.2,
      });
      expect(valid['items'][0]['resolved'], isTrue);
      expect(valid['items'][0]['calories'], 52);
      final impossible = await scan(100, {
        'kcal': 9000,
        'protein_g': 300,
        'carbs_g': 4,
        'fat_g': 0,
      });
      expect(impossible['items'][0]['resolved'], isFalse);
      final batch = await scan(2000, {
        'kcal': 52,
        'protein_g': 0.3,
        'carbs_g': 14,
        'fat_g': 0.2,
      });
      expect(batch['items'][0]['estimated_grams'], 2000);
      expect(batch['items'][0]['resolved'], isFalse);
      expect(batch['items'][0]['review_reason'], isNotEmpty);
    },
  );

  test(
    'nutrition arithmetic rejects nonfinite values rather than silently clamping',
    () {
      expect(
        () => FoodNutrition.compute(
          consumedGrams: double.nan,
          baseNutrition: FoodNutrition(kcal: 100),
          isPer100g: true,
        ),
        throwsFormatException,
      );
      expect(
        FoodNutrition.compute(
          consumedGrams: 100000,
          baseNutrition: FoodNutrition(kcal: 200),
          isPer100g: true,
        ).kcal,
        200000,
      );
    },
  );

  test(
    'suggestion cache requires exact account, date, budget, meals left and history',
    () async {
      var calls = 0;
      final client = AiClient(
        mockCallModelStream:
            ({
              required modelName,
              required prompt,
              required systemInstruction,
              apiKey,
            }) => Stream.value('Meal ${++calls}'),
      );
      GeminiFoodService service(String? account, {String? key = 'k'}) =>
          GeminiFoodService(
            apiKey: key,
            accountId: account,
            aiClient: client,
            nutritionLookup: _Lookup(),
          );
      Future<String> suggestion(
        GeminiFoodService food, {
        int calories = 199,
        String date = '2026-09-19',
        int mealsLeft = 1,
        List<String> history = const [],
      }) => food
          .suggestMealStream(
            remainingCalories: calories,
            remainingProtein: 20,
            remainingCarbs: 20,
            remainingFat: 5,
            targetDate: date,
            mealsLeft: mealsLeft,
            previousMeals: history,
          )
          .join();
      expect(await suggestion(service('A')), 'Meal 1');
      expect(await suggestion(service('A', key: null)), 'Meal 1');
      expect(await suggestion(service('B')), 'Meal 2');
      expect(await suggestion(service('A'), calories: 100), 'Meal 3');
      expect(await suggestion(service('A'), date: '2026-09-18'), 'Meal 4');
      expect(await suggestion(service('A'), mealsLeft: 2), 'Meal 5');
      expect(await suggestion(service('A'), history: ['ab', 'c']), 'Meal 6');
      expect(await suggestion(service('A'), history: ['a', 'bc']), 'Meal 7');
      await suggestion(service(null));
      await suggestion(service(null));
      expect(calls, 9);
    },
  );

  test('cancelled coach work cannot emit a local fallback', () async {
    final token = CancellationToken();
    final client = AiClient(
      mockCallModelStream:
          ({
            required modelName,
            required prompt,
            required systemInstruction,
            apiKey,
          }) async* {
            token.cancel();
            throw AiException('cancelled', cause: AiErrorCause.cancelled);
          },
    );
    final result = await CoachService(apiKey: 'k', aiClient: client)
        .generateNoteStream(
          context: CoachContext(
            date: DateTime(2026, 9, 19),
            today: DateTime(2026, 9, 19),
            userName: 'A',
            steps: 100,
            hasEntries: true,
          ),
          cancellationToken: token,
        )
        .toList();
    expect(result, isNot(contains('__LOCAL__')));
  });
}
