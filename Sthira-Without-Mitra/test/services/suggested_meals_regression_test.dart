import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Platform faults are exercised through the installed preferences implementation.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:trufit_bodamma/services/ai_client.dart';
import 'package:trufit_bodamma/services/gemini_food_service.dart';
import 'package:trufit_bodamma/services/nutrition_lookup_service.dart';

class _FailingWrites extends InMemorySharedPreferencesStore {
  _FailingWrites() : super.empty();
  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      throw StateError('Test cache persistence failure');
}

Future<String> _idea(
  GeminiFoodService service, {
  bool fresh = false,
  String? previous,
  double? protein = 20,
  int? mealsLeft = 2,
  List<String> history = const [],
}) => service
    .suggestMealStream(
      remainingCalories: 600,
      remainingProtein: protein,
      remainingCarbs: 50,
      remainingFat: 10,
      mealsLeft: mealsLeft,
      previousMeals: history,
      targetDate: '2026-09-19',
      forceRefresh: fresh,
      previousSuggestion: previous,
    )
    .join();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'alternative bypasses cached idea and ordinary reopen reuses the new idea',
    () async {
      final prompts = <String>[];
      final client = AiClient(
        mockCallModelStream:
            ({
              required modelName,
              required prompt,
              required systemInstruction,
              apiKey,
            }) {
              prompts.add(prompt);
              return Stream.value(
                prompts.length == 1 ? 'Dal and rice' : 'Paneer wrap',
              );
            },
      );
      addTearDown(client.dispose);
      final service = GeminiFoodService(
        apiKey: 'key',
        accountId: 'A',
        aiClient: client,
        nutritionLookup: NutritionLookupService(),
      );
      expect(await _idea(service), 'Dal and rice');
      expect(await _idea(service), 'Dal and rice');
      expect(prompts, hasLength(1));
      expect(
        await _idea(service, fresh: true, previous: 'Dal and rice'),
        'Paneer wrap',
      );
      expect(prompts, hasLength(2));
      expect(prompts.last, contains('Dal and rice'));
      expect(prompts.last, contains('Change the main meal'));
      expect(await _idea(service), 'Paneer wrap');
      expect(prompts, hasLength(2));
    },
  );

  test(
    'unset and exceeded macro targets are distinct and later food names reach prompt',
    () async {
      final prompts = <String>[];
      final client = AiClient(
        mockCallModelStream:
            ({
              required modelName,
              required prompt,
              required systemInstruction,
              apiKey,
            }) {
              prompts.add(prompt);
              return Stream.value('Estimated meal');
            },
      );
      addTearDown(client.dispose);
      final service = GeminiFoodService(
        apiKey: 'key',
        accountId: 'A',
        aiClient: client,
        nutritionLookup: NutritionLookupService(),
      );
      await _idea(
        service,
        protein: null,
        history: ['Idli', 'Sambar', 'Paneer', 'Curd'],
      );
      expect(prompts.last, contains('Protein: no target set'));
      expect(prompts.last, contains('Idli, Sambar, Paneer, Curd'));
      expect(prompts.last, contains('2 unlogged meal slots'));
      expect(prompts.last, isNot(contains('AIR FRYER')));
      expect(prompts.last, isNot(contains('PLATE & BOWL SIZE')));
      await _idea(service, protein: -20);
      expect(prompts.last, contains('Protein: target already met'));
      expect(prompts.last, isNot(contains('-20.0 g')));
      expect(
        prompts.last,
        contains('Do not assume that no meals have been eaten'),
      );
    },
  );

  test(
    'fully logged schedule offers optional idea without inventing another required meal',
    () async {
      String? captured;
      final client = AiClient(
        mockCallModelStream:
            ({
              required modelName,
              required prompt,
              required systemInstruction,
              apiKey,
            }) {
              captured = prompt;
              return Stream.value('Estimated snack');
            },
      );
      addTearDown(client.dispose);
      final service = GeminiFoodService(
        apiKey: 'key',
        accountId: 'A',
        aiClient: client,
        nutritionLookup: NutritionLookupService(),
      );
      await _idea(service, mealsLeft: 0);
      expect(captured, contains('All scheduled meal slots already have logs'));
      expect(captured, contains('do not imply that another meal is required'));
    },
  );

  test('cache read failure cannot prevent usable suggestion', () async {
    final client = AiClient(
      mockCallModelStream:
          ({
            required modelName,
            required prompt,
            required systemInstruction,
            apiKey,
          }) => Stream.value('Complete idea'),
    );
    addTearDown(client.dispose);
    final service = GeminiFoodService(
      apiKey: 'key',
      accountId: 'A',
      aiClient: client,
      nutritionLookup: NutritionLookupService(),
      loadSuggestionPreferences: () async =>
          throw StateError('Test read failure'),
    );
    expect(await _idea(service), 'Complete idea');
  });

  test('stalled cache read is bounded and does not hold generation', () async {
    final pending = Completer<SharedPreferences>();
    final client = AiClient(
      mockCallModelStream:
          ({
            required modelName,
            required prompt,
            required systemInstruction,
            apiKey,
          }) => Stream.value('Complete idea'),
    );
    addTearDown(client.dispose);
    final service = GeminiFoodService(
      apiKey: 'key',
      accountId: 'A',
      aiClient: client,
      nutritionLookup: NutritionLookupService(),
      loadSuggestionPreferences: () => pending.future,
    );
    expect(
      await _idea(service).timeout(const Duration(seconds: 2)),
      'Complete idea',
    );
    pending.complete(await SharedPreferences.getInstance());
  });

  test(
    'cache write failure cannot turn complete answer into a stream error',
    () async {
      final oldStore = SharedPreferencesStorePlatform.instance;
      SharedPreferencesStorePlatform.instance = _FailingWrites();
      addTearDown(() => SharedPreferencesStorePlatform.instance = oldStore);
      final client = AiClient(
        mockCallModelStream:
            ({
              required modelName,
              required prompt,
              required systemInstruction,
              apiKey,
            }) => Stream.value('Complete idea'),
      );
      addTearDown(client.dispose);
      final service = GeminiFoodService(
        apiKey: 'key',
        accountId: 'A',
        aiClient: client,
        nutritionLookup: NutritionLookupService(),
      );
      expect(await _idea(service), 'Complete idea');
    },
  );

  test(
    'interrupted idea remains an error and is never cached as complete',
    () async {
      var calls = 0;
      final client = AiClient(
        mockCallModelStream:
            ({
              required modelName,
              required prompt,
              required systemInstruction,
              apiKey,
            }) async* {
              calls++;
              if (calls == 1) {
                yield 'Partial meal';
                throw AiException('Interrupted', cause: AiErrorCause.parse);
              }
              yield 'Complete replacement';
            },
      );
      addTearDown(client.dispose);
      final service = GeminiFoodService(
        apiKey: 'key',
        accountId: 'A',
        aiClient: client,
        nutritionLookup: NutritionLookupService(),
      );
      await expectLater(_idea(service), throwsA(isA<AiException>()));
      expect(await _idea(service), 'Complete replacement');
      expect(calls, 2);
    },
  );
}
