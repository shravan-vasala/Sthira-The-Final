import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/food_nutrition.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/screens/home/widgets/add_serving_sheet.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';
import 'package:trufit_bodamma/widgets/app_bottom_sheet.dart';
import 'package:trufit_bodamma/widgets/primary_button.dart';

class _Capture extends DailyMealLogNotifier {
  int calls = 0;
  MealItemLog? item;
  String? date;
  String? slot;
  bool fail = false;
  Completer<void>? pending;
  @override
  DailyMealLog build() => DailyMealLog(date: '2026-09-20');
  @override
  Future<void> appendMealItem(
    String slotId,
    MealItemLog addition, {
    String? targetDate,
    String? slotName,
    String? slotEmoji,
  }) async {
    calls++;
    item = addition;
    date = targetDate;
    slot = slotId;
    if (fail) throw StateError('Storage unavailable');
    if (pending != null) await pending!.future;
  }
}

MealItemLog food(String name, double kcal, String portion) => MealItemLog(
  name: name,
  portion: portion,
  provenance: 'verified',
  computedNutrition: FoodNutrition(
    kcal: kcal,
    proteinG: 6,
    carbsG: 20,
    fatG: 3,
  ),
);

void main() {
  late _Capture capture;
  late ProviderContainer container;
  AddServingResult? result;

  setUp(() {
    capture = _Capture();
    result = null;
    container = ProviderContainer(
      overrides: [dailyMealLogProvider.overrideWith(() => capture)],
    );
  });
  tearDown(() => container.dispose());

  Future<void> showSheet(
    WidgetTester tester, {
    bool multiple = false,
    bool repeated = false,
    bool dark = false,
    double scale = 1,
    Size size = const Size(500, 1100),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                child: const Text('Open'),
                onPressed: () async {
                  result = await showAppBottomSheet<AddServingResult>(
                    context: context,
                    isDismissible: false,
                    enableDrag: false,
                    builder: (_) => AddServingSheet(
                      slotId: 'breakfast',
                      slotDisplayName: 'Breakfast',
                      targetDate: '2026-09-19',
                      slotLog: MealSlotLog(
                        items: [
                          food('Idli', 160, '2 idlis'),
                          if (repeated)
                            food('Idli', 160, '2 idlis')..macrosKnown = true,
                          if (multiple) food('Milk', 120, '200 ml'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String text) async {
    final target = text == 'Close'
        ? find.byTooltip('Close')
        : find.text(text).first;
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'repeats selected portion in pinned meal and date without scanning',
    (tester) async {
      await showSheet(tester);
      expect(find.text('1\u00d7 = another 2 idlis'), findsOneWidget);
      await tap(tester, '0.5\u00d7');
      expect(find.text('+80 kcal'), findsOneWidget);
      await tap(tester, 'Add to Breakfast');
      expect(capture.calls, 1);
      expect(capture.item!.computedNutrition!.kcal, 80);
      expect(capture.slot, 'breakfast');
      expect(capture.date, '2026-09-19');
      expect(result, AddServingResult.added);
    },
  );

  testWidgets('selects one food and accepts a custom amount', (tester) async {
    await showSheet(tester, multiple: true);
    await tap(tester, 'Milk');
    await tap(tester, 'Custom');
    final field = find.byKey(const Key('extra-serving-amount'));
    await tester.ensureVisible(field);
    await tester.enterText(field, '1.25');
    await tester.pumpAndSettle();
    expect(find.text('+150 kcal'), findsOneWidget);
    await tap(tester, 'Add to Breakfast');
    expect(capture.item!.name, 'Milk');
    expect(capture.item!.computedNutrition!.kcal, 150);
  });

  testWidgets('invalid custom amounts cannot save', (tester) async {
    await showSheet(tester);
    await tap(tester, 'Custom');
    final field = find.byKey(const Key('extra-serving-amount'));
    for (final value in ['0', '-2', 'NaN', 'Infinity', '1e17', '1e308']) {
      await tester.ensureVisible(field);
      await tester.enterText(field, value);
      await tester.pump();
      expect(
        tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
        isNull,
      );
    }
    expect(capture.calls, 0);
  });

  testWidgets('keeps selection after failed save and permits retry', (
    tester,
  ) async {
    capture.fail = true;
    await showSheet(tester);
    await tap(tester, '2\u00d7');
    await tap(tester, 'Add to Breakfast');
    expect(find.textContaining('Your selection is still here'), findsOneWidget);
    capture.fail = false;
    await tap(tester, 'Add to Breakfast');
    expect(capture.calls, 2);
    expect(capture.item!.computedNutrition!.kcal, 320);
    expect(result, AddServingResult.added);
  });

  testWidgets('pending save prevents duplicate additions and dismissal', (
    tester,
  ) async {
    capture.pending = Completer<void>();
    await showSheet(tester);
    await tester.ensureVisible(find.text('Add to Breakfast'));
    await tester.tap(find.text('Add to Breakfast'));
    await tester.pump();
    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();
    expect(capture.calls, 1);
    expect(tester.widget<PopScope>(find.byType(PopScope).last).canPop, isFalse);
    capture.pending!.complete();
    await tester.pumpAndSettle();
    expect(result, AddServingResult.added);
  });

  testWidgets('account switch hides old food and prevents saving', (
    tester,
  ) async {
    await showSheet(tester);
    container.read(accountGenerationProvider.notifier).state++;
    await tester.pumpAndSettle();
    expect(find.text('Idli'), findsNothing);
    expect(find.text('Add to Breakfast'), findsNothing);
    expect(find.textContaining('Your account is changing'), findsOneWidget);
    expect(capture.calls, 0);
  });

  testWidgets('different food keeps existing photo and description routes', (
    tester,
  ) async {
    await showSheet(tester);
    await tap(tester, 'Describe');
    expect(result, AddServingResult.describe);
    expect(capture.calls, 0);
  });

  for (final dark in [false, true]) {
    testWidgets(
      'fits narrow screen and large text in ${dark ? 'dark' : 'light'} theme',
      (tester) async {
        await showSheet(
          tester,
          multiple: true,
          dark: dark,
          scale: 2,
          size: const Size(320, 800),
        );
        expect(tester.takeException(), isNull);
        await tap(tester, 'Custom');
        await tester.ensureVisible(
          find.byKey(const Key('extra-serving-amount')),
        );
        expect(tester.takeException(), isNull);
        await tap(tester, 'Close');
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('identical logged servings remain one quick-repeat choice', (
    tester,
  ) async {
    await showSheet(tester, repeated: true);
    expect(find.text('Idli'), findsOneWidget);
    expect(find.byType(RadioListTile<int>), findsNothing);
    await tap(tester, 'Add to Breakfast');
    expect(capture.calls, 1);
    expect(capture.item!.computedNutrition!.kcal, 160);
  });
}
