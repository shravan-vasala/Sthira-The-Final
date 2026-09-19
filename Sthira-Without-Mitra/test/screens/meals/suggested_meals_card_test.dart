import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/interfaces/i_ai_food_service.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/repositories/meal_repository.dart';
import 'package:trufit_bodamma/screens/home/meal_detail_screen.dart';
import 'package:trufit_bodamma/screens/home/widgets/ai_meal_suggestion_card.dart';
import 'package:trufit_bodamma/services/ai_client.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';

class _Profile extends ProfileNotifier {
  _Profile(this.profile);
  final UserProfile profile;
  @override
  UserProfile build() => profile;
}

class _Meals extends DailyMealLogNotifier {
  _Meals(this.log);
  final DailyMealLog log;
  @override
  DailyMealLog build() => log;
  void update(DailyMealLog log) => state = log;
}

class _Repo extends MealRepository {
  @override
  List<DailyMealLog> getLogsInRange(String start, String end) => [];
}

class _Service implements IAiFoodService {
  final requests =
      <({bool fresh, String? previous, CancellationToken? token})>[];
  Stream<String> Function() next = () =>
      Stream.value('Dal and rice, estimated nutrition.');
  @override
  Stream<String> suggestMealStream({
    required int remainingCalories,
    required double? remainingProtein,
    required double? remainingCarbs,
    required double? remainingFat,
    String? mealName,
    int? mealsLeft,
    List<String>? previousMeals,
    String? targetDate,
    bool forceRefresh = false,
    String? previousSuggestion,
    CancellationToken? cancellationToken,
  }) {
    requests.add((
      fresh: forceRefresh,
      previous: previousSuggestion,
      token: cancellationToken,
    ));
    return next();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<ProviderContainer> _mount(
  WidgetTester tester, {
  required _Service service,
  bool page = false,
  DailyMealLog? log,
  UserProfile? profile,
  double scale = 1,
}) async {
  tester.view.physicalSize = const Size(320, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      activeAccountIdProvider.overrideWithValue('A'),
      geminiFoodServiceProvider.overrideWithValue(service),
      mealRepoProvider.overrideWithValue(_Repo()),
      mealPlanProvider.overrideWithValue(null),
      dailyMealLogProvider.overrideWith(
        () => _Meals(log ?? DailyMealLog(date: '2026-09-19')),
      ),
      profileProvider.overrideWith(
        () => _Profile(profile ?? UserProfile(name: 'A')),
      ),
      selectedDateProvider.overrideWith((ref) => DateTime(2026, 9, 19)),
      clockProvider.overrideWithValue(DateTime(2026, 9, 19, 12)),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: page
            ? const MealDetailScreen()
            : const Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: AIMealSuggestionCard(
                      remainingCalories: 600,
                      remainingProtein: 20,
                      remainingCarbs: 50,
                      remainingFat: 10,
                      mealName: 'Lunch',
                      mealsLeft: 2,
                    ),
                  ),
                ),
              ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets(
    'alternative button requests a fresh idea with the previous response',
    (tester) async {
      final service = _Service();
      await _mount(tester, service: service, scale: 2);
      await tester.tap(find.text('Suggest a Meal'));
      await tester.pumpAndSettle();
      expect(find.text('Dal and rice, estimated nutrition.'), findsOneWidget);
      service.next = () => Stream.value('Paneer wrap, estimated nutrition.');
      await tester.ensureVisible(find.text('Suggest something else'));
      await tester.tap(find.text('Suggest something else'));
      await tester.pumpAndSettle();
      expect(service.requests, hasLength(2));
      expect(service.requests.first.fresh, isFalse);
      expect(service.requests.last.fresh, isTrue);
      expect(
        service.requests.last.previous,
        'Dal and rice, estimated nutrition.',
      );
      expect(find.text('Paneer wrap, estimated nutrition.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'account transition cancels a pending idea and ignores its late text',
    (tester) async {
      final controller = StreamController<String>();
      addTearDown(controller.close);
      final service = _Service()..next = () => controller.stream;
      final container = await _mount(tester, service: service);
      await tester.tap(find.text('Suggest a Meal'));
      await tester.pump();
      container.read(accountGenerationProvider.notifier).state++;
      await tester.pump();
      expect(service.requests.single.token!.isCancelled, isTrue);
      controller.add('Old account food');
      await tester.pumpAndSettle();
      expect(find.text('Old account food'), findsNothing);
      expect(find.text('Suggest a Meal'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('meal log update invalidates an in-flight idea', (tester) async {
    final controller = StreamController<String>();
    addTearDown(controller.close);
    final service = _Service()..next = () => controller.stream;
    final container = await _mount(tester, service: service);
    await tester.tap(find.text('Suggest a Meal'));
    await tester.pump();
    (container.read(dailyMealLogProvider.notifier) as _Meals).update(
      DailyMealLog(date: '2026-09-19'),
    );
    await tester.pump();
    controller.add('Outdated idea');
    await tester.pumpAndSettle();
    expect(find.text('Outdated idea'), findsNothing);
    expect(service.requests.single.token!.isCancelled, isTrue);
    expect(find.text('Suggest a Meal'), findsOneWidget);
  });

  testWidgets(
    'interrupted response has an explicit retry and reduced motion settles while streaming',
    (tester) async {
      final controller = StreamController<String>();
      addTearDown(controller.close);
      final service = _Service()..next = () => controller.stream;
      await _mount(tester, service: service, scale: 2);
      await tester.tap(find.text('Suggest a Meal'));
      await tester.pump();
      controller.add('Partial idea');
      await tester.pumpAndSettle();
      expect(find.text('Partial idea'), findsOneWidget);
      expect(find.text('Suggest something else'), findsNothing);
      controller.addError(
        AiException('Interrupted', cause: AiErrorCause.parse),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('This response was interrupted'),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'aggregate-only logged meals do not inflate meals-left or fabricate zero macro targets',
    (tester) async {
      final service = _Service();
      await _mount(
        tester,
        service: service,
        page: true,
        profile: UserProfile(
          name: 'A',
          targetCalories: 1800,
          targetProteinG: 0,
          targetCarbsG: 200,
          targetFatG: 50,
          customMealSlots: const [
            {'id': 'breakfast', 'name': 'Breakfast', 'emoji': 'B'},
            {'id': 'lunch', 'name': 'Lunch', 'emoji': 'L'},
          ],
        ),
        log: DailyMealLog(
          date: '2026-09-19',
          customSlots: {
            'breakfast': MealSlotLog(
              totalCalories: 400,
              totalProtein: 20,
              totalCarbs: 240,
              totalFat: 10,
              caloriesComplete: true,
              macrosComplete: true,
            ),
          },
        ),
      );
      await tester.scrollUntilVisible(find.byType(AIMealSuggestionCard), 400);
      final card = tester.widget<AIMealSuggestionCard>(
        find.byType(AIMealSuggestionCard),
      );
      expect(card.mealsLeft, 1);
      expect(card.mealName, 'Lunch');
      expect(card.remainingProtein, isNull);
      expect(card.remainingCarbs, 0);
      expect(card.remainingCalories, 1400);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'incomplete logged nutrition does not offer a precise remaining-target idea',
    (tester) async {
      final service = _Service();
      await _mount(
        tester,
        service: service,
        page: true,
        profile: UserProfile(name: 'A', targetCalories: 1800),
        log: DailyMealLog(
          date: '2026-09-19',
          customSlots: {
            'lunch': MealSlotLog(
              totalCalories: 400,
              caloriesComplete: true,
              macrosComplete: false,
            ),
          },
        ),
      );
      for (var i = 0; i < 5; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -500));
        await tester.pumpAndSettle();
      }
      expect(find.byType(AIMealSuggestionCard), findsNothing);
      expect(service.requests, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
