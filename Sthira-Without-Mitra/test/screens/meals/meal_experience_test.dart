import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/repositories/meal_repository.dart';
import 'package:trufit_bodamma/screens/home/meal_detail_screen.dart';
import 'package:trufit_bodamma/screens/home/widgets/meals_card.dart';
import 'package:trufit_bodamma/screens/home/widgets/ai_meal_suggestion_card.dart';
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
}

class _Repo extends MealRepository {
  final logs = <String, DailyMealLog>{};
  final writes = <({String date, String slot, MealSlotLog log})>[];
  Completer<void>? pending;
  bool fail = false;
  @override
  DailyMealLog getDailyLog(String date) =>
      logs[date] ?? DailyMealLog(date: date);
  @override
  Future<void> saveMealSlot(
    String date,
    String slotId,
    MealSlotLog slotLog,
  ) async {
    writes.add((date: date, slot: slotId, log: slotLog));
    if (pending != null) await pending!.future;
    if (fail) throw StateError('Test storage failure');
    final log = getDailyLog(date);
    logs[date] = log.copyWith(
      customSlots: {...log.customSlots, slotId: slotLog},
    );
  }
}

DailyMealLog _populated(String date) => DailyMealLog(
  date: date,
  customSlots: {
    'breakfast': MealSlotLog(
      totalCalories: 720,
      totalProtein: 32,
      totalCarbs: 94,
      totalFat: 21,
      confidence: 'medium',
      items: [
        MealItemLog(
          name: 'Masala dosa',
          portion: '2 medium',
          provenance: 'estimated',
        ),
        MealItemLog(name: 'Sambar', portion: '1 bowl', provenance: 'estimated'),
        MealItemLog(
          name: 'Greek yogurt',
          portion: '150 g',
          provenance: 'barcode',
          barcode: '8901262150217',
          nutritionBasis: 'per100g',
          consumedGrams: 150,
        ),
      ],
    ),
  },
);
UserProfile _profile({int target = 2100}) => UserProfile(
  name: 'Shravan',
  targetCalories: target,
  targetProteinG: 120,
  targetCarbsG: 235,
  targetFatG: 75,
);
Future<ProviderContainer> _mount(
  WidgetTester tester, {
  required Widget child,
  String date = '2026-09-19',
  DailyMealLog? log,
  UserProfile? profile,
  _Repo? repo,
  double scale = 1,
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      profileProvider.overrideWith(() => _Profile(profile ?? _profile())),
      dailyMealLogProvider.overrideWith(
        () => _Meals(log ?? DailyMealLog(date: date)),
      ),
      mealPlanProvider.overrideWithValue(null),
      clockProvider.overrideWithValue(DateTime(2026, 9, 19, 14)),
      selectedDateProvider.overrideWith((ref) => DateTime.parse(date)),
      if (repo != null) mealRepoProvider.overrideWithValue(repo),
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
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets(
    'meal ideas are absent when reviewing history or an unset target',
    (tester) async {
      for (final settings in [
        (date: '2026-09-18', target: 2100),
        (date: '2026-09-19', target: 0),
      ]) {
        await _mount(
          tester,
          child: const MealDetailScreen(),
          date: settings.date,
          profile: _profile(target: settings.target),
        );
        for (var i = 0; i < 5; i++) {
          await tester.drag(find.byType(ListView).first, const Offset(0, -500));
          await tester.pumpAndSettle();
        }
        expect(find.byType(AIMealSuggestionCard), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    },
  );
  testWidgets(
    'meal page stays readable through populated and empty slots at 200 percent text',
    (tester) async {
      await _mount(
        tester,
        child: const MealDetailScreen(),
        log: _populated('2026-09-19'),
        scale: 2,
        width: 320,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Calories logged'), findsOneWidget);
      for (var i = 0; i < 8; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -500));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(find.text('Meal ideas'), findsOneWidget);
      expect(find.text('Add another meal'), findsOneWidget);
    },
  );
  testWidgets('no historical logs are not described as below target', (
    tester,
  ) async {
    await _mount(
      tester,
      child: const Scaffold(body: SingleChildScrollView(child: MealsCard())),
      date: '2026-09-18',
    );
    expect(find.text('No meals logged for this day.'), findsOneWidget);
    expect(find.textContaining('Below target'), findsNothing);
    expect(find.textContaining('kcal logged'), findsOneWidget);
  });
  testWidgets(
    'meal summary handles an unset calorie target without invalid progress',
    (tester) async {
      await _mount(
        tester,
        child: const Scaffold(body: SingleChildScrollView(child: MealsCard())),
        profile: _profile(target: 0),
      );
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        0,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'repeat today preserves history, uses the next empty slot and blocks duplicate taps',
    (tester) async {
      final source = _populated('2026-09-18');
      final repo = _Repo()..pending = Completer<void>();
      repo.logs['2026-09-18'] = source;
      // A calorie-only legacy record still counts as an occupied slot.
      repo.logs['2026-09-19'] = DailyMealLog(
        date: '2026-09-19',
        customSlots: {'breakfast': MealSlotLog(totalCalories: 350)},
      );
      final container = await _mount(
        tester,
        child: const MealDetailScreen(),
        date: '2026-09-18',
        log: source,
        repo: repo,
      );
      await tester.ensureVisible(find.text('Repeat today'));
      await tester.tap(find.text('Repeat today'));
      await tester.pump();
      await tester.tap(find.text('Repeat today'));
      await tester.pump();
      expect(repo.writes, hasLength(1));
      expect(repo.writes.single.date, '2026-09-19');
      expect(repo.writes.single.slot, 'lunch');
      expect(repo.writes.single.log.name, 'Lunch');
      expect(repo.writes.single.log.confidence, 'medium');
      expect(repo.writes.single.log.items.last.barcode, '8901262150217');
      expect(
        identical(
          repo.writes.single.log.items.last,
          source.customSlots['breakfast']!.items.last,
        ),
        isFalse,
      );
      repo.pending!.complete();
      await tester.pumpAndSettle();
      expect(container.read(dateStringProvider), '2026-09-18');
      expect(container.read(dailyMealLogProvider).date, '2026-09-18');
      expect(repo.logs['2026-09-18']!.customSlots, hasLength(1));
      expect(
        repo.logs['2026-09-19']!.customSlots['breakfast']!.totalCalories,
        350,
      );
      expect(find.text('Added to today \u00b7 Lunch'), findsOneWidget);
    },
  );
  testWidgets('repeat failures remain retryable and never claim success', (
    tester,
  ) async {
    final source = _populated('2026-09-18');
    final repo = _Repo()..fail = true;
    repo.logs['2026-09-18'] = source;
    await _mount(
      tester,
      child: const MealDetailScreen(),
      date: '2026-09-18',
      log: source,
      repo: repo,
    );
    await tester.ensureVisible(find.text('Repeat today'));
    await tester.tap(find.text('Repeat today'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not repeat this meal. Please try again.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextButton>(
            find.ancestor(
              of: find.text('Repeat today'),
              matching: find.byType(TextButton),
            ),
          )
          .onPressed,
      isNotNull,
    );
    expect(repo.logs.containsKey('2026-09-19'), isFalse);
  });
  testWidgets(
    'over-target meal ideas show neutral logged context at large text',
    (tester) async {
      await _mount(
        tester,
        child: const Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: AIMealSuggestionCard(
                remainingCalories: -500,
                remainingProtein: 0,
                remainingCarbs: 0,
                remainingFat: 0,
              ),
            ),
          ),
        ),
        scale: 2,
        width: 320,
      );
      expect(find.text('Above your calorie target'), findsOneWidget);
      expect(
        find.text('500 kcal above your daily target, based on logged meals.'),
        findsOneWidget,
      );
      expect(find.textContaining('Great job'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
