import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trufit_bodamma/services/auth_service.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/packaged_food.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/providers/barcode_food_providers.dart';
import 'package:trufit_bodamma/repositories/barcode_food_store.dart';
import 'package:trufit_bodamma/screens/meals/widgets/barcode_food_sheet.dart';
import 'package:trufit_bodamma/screens/meals/widgets/packaged_food_editor.dart';
import 'package:trufit_bodamma/services/barcode_food_service.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';
import 'package:trufit_bodamma/widgets/app_bottom_sheet.dart';
import 'package:trufit_bodamma/widgets/primary_button.dart';

const _barcode = '8901262150217';
const _milk = PackagedFood(
  barcode: _barcode,
  name: 'Test milk',
  brand: 'Test dairy',
  basis: NutritionBasis.per100ml,
  kcal: 60,
  proteinG: 3,
  carbsG: 5,
  fatG: 3,
  packageQuantity: 500,
  packageUnit: FoodQuantityUnit.millilitres,
  servingQuantity: 200,
  servingUnit: FoodQuantityUnit.millilitres,
  source: PackagedFoodSource.openFoodFacts,
);

class _Auth implements AuthService {
  @override
  String? uid = 'first-user';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Lookup extends BarcodeFoodService {
  _Lookup(this.result)
    : super(
        client: MockClient(
          (_) async => throw StateError('No live requests in widget tests'),
        ),
      );
  final Future<PackagedFood> Function(String) result;
  final codes = <String>[];

  @override
  Future<PackagedFood> lookup(String barcode) {
    codes.add(barcode);
    return result(barcode);
  }
}

class _FailingStore extends BarcodeFoodStore {
  _FailingStore(super.preferences) : super(accountId: 'first-user');

  @override
  Future<void> remember(PackagedFood food, double amount) async {
    throw StateError('Shortcut write failed');
  }
}

class _MealCapture extends DailyMealLogNotifier {
  final items = <MealItemLog>[];
  String? date;
  String? slot;
  Completer<void>? pending;
  bool fail = false;

  @override
  DailyMealLog build() => DailyMealLog(date: '2026-10-02');

  @override
  Future<void> appendMealItem(
    String slotId,
    MealItemLog item, {
    String? targetDate,
    String? slotName,
    String? slotEmoji,
  }) async {
    items.add(item);
    date = targetDate;
    slot = slotId;
    if (fail) throw StateError('Save failed');
    if (pending != null) await pending!.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late BarcodeFoodStore store;
  late _Auth auth;
  late _MealCapture meals;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    store = BarcodeFoodStore(preferences, accountId: 'first-user');
    auth = _Auth();
    meals = _MealCapture();
  });

  Future<void> showSheet(
    WidgetTester tester,
    _Lookup service, {
    Size size = const Size(600, 1100),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(auth),
          barcodeFoodServiceProvider.overrideWithValue(service),
          barcodeFoodStoreProvider.overrideWithValue(store),
          dailyMealLogProvider.overrideWith(() => meals),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  child: const Text('Open packaged food'),
                  onPressed: () {
                    unawaited(
                      showAppBottomSheet<bool>(
                        context: context,
                        builder: (_) => BarcodeFoodSheet(
                          slotId: 'lunch',
                          slotDisplayName: 'Lunch',
                          targetDate: '2026-09-19',
                          autoScan: false,
                          scannerBuilder: (scannerContext) => Scaffold(
                            body: Center(
                              child: TextButton(
                                child: const Text('Return test barcode'),
                                onPressed: () =>
                                    Navigator.of(scannerContext).pop(_barcode),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open packaged food'));
    await tester.pumpAndSettle();
  }

  Future<void> scan(WidgetTester tester, {bool pending = false}) async {
    await tester.ensureVisible(find.text('Scan barcode'));
    await tester.tap(find.text('Scan barcode'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Return test barcode'));
    if (pending) {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    } else {
      await tester.pumpAndSettle();
    }
  }

  Future<void> amount(WidgetTester tester, String value) async {
    final field = find.byKey(const Key('packaged-food-amount'));
    await tester.ensureVisible(field);
    await tester.enterText(field, value);
    await tester.pump();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> editField(
    WidgetTester tester,
    String label,
    String value,
  ) async {
    final field = find.widgetWithText(TextFormField, label);
    await tester.ensureVisible(field);
    await tester.enterText(field, value);
    await tester.pump();
  }

  Future<void> chooseBasis(WidgetTester tester, String label) async {
    final dropdown = find.byType(DropdownButtonFormField<NutritionBasis>);
    await tapVisible(tester, dropdown);
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'scanned liquid shows live totals and saves captured date with ml',
    (tester) async {
      final lookup = _Lookup((_) async => _milk);
      await showSheet(tester, lookup);
      await scan(tester);
      expect(lookup.codes, [_barcode]);
      expect(find.text('Per 100 ml'), findsOneWidget);
      expect(
        tester
            .widget<PrimaryButton>(
              find.widgetWithText(PrimaryButton, 'Add to Lunch'),
            )
            .onPressed,
        isNull,
      );
      await amount(tester, '250');
      expect(find.text('150 kcal'), findsOneWidget);
      expect(find.text('Protein 7.5 g'), findsOneWidget);
      await tapVisible(tester, find.text('Add to Lunch'));
      expect(meals.items, hasLength(1));
      expect(meals.date, '2026-09-19');
      expect(meals.slot, 'lunch');
      final item = meals.items.single;
      expect(item.consumedMl, 250);
      expect(item.consumedGrams, isNull);
      expect(item.barcode, _barcode);
      expect(item.brand, 'Test dairy');
      expect(item.computedNutrition!.kcal, 150);
      expect(store.find(_barcode)!.lastAmount, 250);
    },
  );

  testWidgets('pack and serving shortcuts use compatible volume quantities', (
    tester,
  ) async {
    await showSheet(tester, _Lookup((_) async => _milk));
    await scan(tester);
    await tapVisible(tester, find.text('Half pack'));
    expect(find.text('150 kcal'), findsOneWidget);
    await tapVisible(tester, find.text('1 serving'));
    expect(find.text('120 kcal'), findsOneWidget);
    await tapVisible(tester, find.text('Whole pack'));
    expect(find.text('300 kcal'), findsOneWidget);
  });

  testWidgets('missing nutrient and basis require manual confirmation', (
    tester,
  ) async {
    final partial = PackagedFood.fromJson({
      ..._milk.toJson(),
      'basis': null,
      'fat_g': null,
    });
    await showSheet(tester, _Lookup((_) async => partial));
    await scan(tester);
    expect(find.text('Add to Lunch'), findsNothing);
    expect(find.text('Fat Unknown g'), findsOneWidget);
    await tapVisible(tester, find.text('Complete from label'));
    await tapVisible(tester, find.text('Use label values'));
    expect(find.text('Choose the basis printed on the label'), findsOneWidget);
    expect(find.text('Enter the label value'), findsOneWidget);
    await editField(tester, 'Fat (g)', '0');
    await chooseBasis(tester, 'Per 100 ml');
    await tapVisible(tester, find.text('Use label values'));
    expect(find.byType(PackagedFoodEditor), findsNothing);
    await amount(tester, '100');
    await tapVisible(tester, find.text('Add to Lunch'));
    expect(meals.items.single.computedNutrition!.fatG, 0);
    expect(meals.items.single.provenance, 'label');
  });

  testWidgets('missing product can be completed from label and added', (
    tester,
  ) async {
    final lookup = _Lookup(
      (_) async => throw const BarcodeLookupException(
        BarcodeLookupError.notFound,
        'This product is not in Open Food Facts yet.',
      ),
    );
    await showSheet(tester, lookup);
    await scan(tester);
    expect(find.text('Try lookup again'), findsNothing);
    await tapVisible(tester, find.text('Enter nutrition from label'));
    await editField(tester, 'Product name', 'My snack');
    await chooseBasis(tester, 'Per serving');
    await editField(tester, 'Energy (kcal)', '200');
    await editField(tester, 'Protein (g)', '10');
    await editField(tester, 'Carbohydrate (g)', '20');
    await editField(tester, 'Fat (g)', '8');
    await tapVisible(tester, find.text('Use label values'));
    await amount(tester, '0.5');
    await tapVisible(tester, find.text('Add to Lunch'));
    expect(meals.items.single.name, 'My snack');
    expect(meals.items.single.consumedServings, 0.5);
    expect(meals.items.single.computedNutrition!.kcal, 100);
    expect(store.find(_barcode)!.food.source, PackagedFoodSource.manual);
  });

  testWidgets(
    'saved recent product works offline and preserves fractional amount',
    (tester) async {
      await store.remember(_milk, 0.25);
      final lookup = _Lookup((_) async => throw StateError('Offline'));
      await showSheet(tester, lookup);
      expect(find.text('Recently added'), findsOneWidget);
      await tapVisible(tester, find.text('Test milk'));
      expect(lookup.codes, isEmpty);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('packaged-food-amount')))
            .controller!
            .text,
        '0.25',
      );
      await tapVisible(tester, find.text('Add to Lunch'));
      expect(meals.items.single.consumedMl, 0.25);
      expect(meals.items.single.computedNutrition!.kcal, 0.15);
    },
  );

  testWidgets('duplicate taps while saving append once', (tester) async {
    meals.pending = Completer<void>();
    await showSheet(tester, _Lookup((_) async => _milk));
    await scan(tester);
    await amount(tester, '250');
    final add = find.text('Add to Lunch');
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.tap(add);
    await tester.pump();
    expect(meals.items, hasLength(1));
    meals.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(BarcodeFoodSheet), findsNothing);
  });

  testWidgets('shortcut failure does not make a saved meal look unsaved', (
    tester,
  ) async {
    store = _FailingStore(store.preferences);
    await showSheet(tester, _Lookup((_) async => _milk));
    await scan(tester);
    await amount(tester, '250');
    await tapVisible(tester, find.text('Add to Lunch'));
    expect(meals.items, hasLength(1));
    expect(find.byType(BarcodeFoodSheet), findsNothing);
    expect(
      find.text('Food added. Could not save its shortcut on this device.'),
      findsOneWidget,
    );
  });

  testWidgets('account change blocks saving into the wrong account', (
    tester,
  ) async {
    await showSheet(tester, _Lookup((_) async => _milk));
    await scan(tester);
    await amount(tester, '250');
    auth.uid = 'another-user';
    await tapVisible(tester, find.text('Add to Lunch'));
    expect(meals.items, isEmpty);
    expect(
      find.text('Your account changed. Close this sheet and try again.'),
      findsOneWidget,
    );
  });

  testWidgets('cancelled lookup ignores its late product response', (
    tester,
  ) async {
    final pending = Completer<PackagedFood>();
    await showSheet(tester, _Lookup((_) => pending.future));
    await scan(tester, pending: true);
    expect(find.text('Cancel lookup'), findsOneWidget);
    await tapVisible(tester, find.text('Cancel lookup'));
    pending.complete(_milk);
    await tester.pumpAndSettle();
    expect(find.text('Test milk'), findsNothing);
    expect(find.text('Scan barcode'), findsOneWidget);
    expect(meals.items, isEmpty);
  });

  testWidgets('save error preserves entered product and amount for retry', (
    tester,
  ) async {
    meals.fail = true;
    await showSheet(tester, _Lookup((_) async => _milk));
    await scan(tester);
    await amount(tester, '250');
    await tapVisible(tester, find.text('Add to Lunch'));
    expect(find.byType(BarcodeFoodSheet), findsOneWidget);
    expect(
      find.text(
        'Could not add this food. Your entry is still here; please try again.',
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('packaged-food-amount')))
          .controller!
          .text,
      '250',
    );
    expect(store.recent, isEmpty);
  });

  testWidgets('review and manual editor remain usable at 320px and 2x text', (
    tester,
  ) async {
    await showSheet(
      tester,
      _Lookup((_) async => _milk),
      size: const Size(320, 900),
      textScale: 2,
    );
    await scan(tester);
    expect(tester.takeException(), isNull);
    await amount(tester, '250');
    await tester.ensureVisible(find.text('Add to Lunch'));
    expect(tester.takeException(), isNull);
    await tapVisible(tester, find.text('Edit label values'));
    await tester.ensureVisible(find.text('Use label values'));
    expect(tester.takeException(), isNull);
  });
}
