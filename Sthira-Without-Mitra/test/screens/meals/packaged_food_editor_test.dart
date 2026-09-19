import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/packaged_food.dart';
import 'package:trufit_bodamma/screens/meals/widgets/packaged_food_editor.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';
import 'package:trufit_bodamma/widgets/app_bottom_sheet.dart';

const _label = PackagedFood(
  barcode: '0012345678905',
  name: 'Plain yogurt',
  brand: 'Sample brand',
  basis: NutritionBasis.per100g,
  kcal: 80,
  proteinG: 5,
  carbsG: 7,
  fatG: 3,
  packageQuantity: 400,
  packageUnit: FoodQuantityUnit.grams,
  servingQuantity: 125,
  servingUnit: FoodQuantityUnit.grams,
  source: PackagedFoodSource.openFoodFacts,
);

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Future<void> _open(
  WidgetTester tester, {
  PackagedFood? food,
  double scale = 1,
  bool dark = false,
  required ValueChanged<PackagedFood?> onResult,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? AppTheme.dark : AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              final result = await showAppBottomSheet<PackagedFood>(
                context: context,
                builder: (_) =>
                    PackagedFoodEditor(barcode: '0012345678905', food: food),
              );
              onResult(result);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String label, String value) async {
  await tester.ensureVisible(_field(label));
  await tester.enterText(_field(label), value);
  await tester.pump();
}

Future<void> _basis(WidgetTester tester, String label) async {
  FocusManager.instance.primaryFocus?.unfocus();
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
  final dropdown = find.byType(DropdownButtonFormField<NutritionBasis>);
  await tester.ensureVisible(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _submit(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Use label values'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Use label values'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('partial product keeps unknown basis and nutrients unselected', (
    tester,
  ) async {
    var returned = false;
    await _open(
      tester,
      food: const PackagedFood(
        barcode: '0012345678905',
        name: 'Partial label',
        kcal: 90,
        carbsG: 8,
        source: PackagedFoodSource.openFoodFacts,
      ),
      onResult: (_) => returned = true,
    );
    final dropdown = tester.widget<DropdownButtonFormField<NutritionBasis>>(
      find.byType(DropdownButtonFormField<NutritionBasis>),
    );
    expect(dropdown.initialValue, isNull);
    expect(
      tester.widget<TextField>(_field('Energy (kcal)')).controller!.text,
      '90',
    );
    expect(
      tester.widget<TextField>(_field('Protein (g)')).controller!.text,
      isEmpty,
    );
    await _submit(tester);
    expect(returned, isFalse);
    expect(find.text('Choose the basis printed on the label'), findsOneWidget);
    expect(
      find.byType(DropdownButtonFormField<NutritionBasis>).hitTestable(),
      findsOneWidget,
    );
    expect(find.text('Enter the label value'), findsNWidgets(2));
  });

  testWidgets('missing nutrient cannot be saved as an implicit zero', (
    tester,
  ) async {
    var returned = false;
    await _open(tester, food: _label, onResult: (_) => returned = true);
    await _enter(tester, 'Fat (g)', '');
    await _submit(tester);
    expect(returned, isFalse);
    expect(find.text('Enter the label value'), findsOneWidget);
  });

  testWidgets('explicit zeros are accepted and barcode identity is preserved', (
    tester,
  ) async {
    PackagedFood? result;
    await _open(tester, onResult: (food) => result = food);
    await _enter(tester, 'Product name', '  Sparkling water  ');
    await _basis(tester, 'Per 100 ml');
    for (final name in [
      'Energy (kcal)',
      'Protein (g)',
      'Carbohydrate (g)',
      'Fat (g)',
    ]) {
      await _enter(tester, name, '0');
    }
    await _submit(tester);
    expect(result, isNotNull);
    expect(result!.barcode, '0012345678905');
    expect(result!.name, 'Sparkling water');
    expect(result!.source, PackagedFoodSource.manual);
    expect(result!.hasCompleteNutrition, isTrue);
    expect(result!.kcal, 0);
    expect(result!.proteinG, 0);
    expect(result!.carbsG, 0);
    expect(result!.fatG, 0);
  });

  testWidgets('liquid label keeps ml quantities and decimal nutrition', (
    tester,
  ) async {
    PackagedFood? result;
    await _open(tester, food: _label, onResult: (food) => result = food);
    await _basis(tester, 'Per 100 ml');
    expect(
      tester
          .widget<TextField>(_field('Pack size (ml, optional)'))
          .controller!
          .text,
      isEmpty,
    );
    expect(
      tester
          .widget<TextField>(_field('Serving size (ml, optional)'))
          .controller!
          .text,
      isEmpty,
    );
    await _enter(tester, 'Energy (kcal)', '42,5');
    await _enter(tester, 'Pack size (ml, optional)', '1000');
    await _enter(tester, 'Serving size (ml, optional)', '250');
    await _submit(tester);
    expect(result!.basis, NutritionBasis.per100ml);
    expect(result!.amountUnit, 'ml');
    expect(result!.packageQuantity, 1000);
    expect(result!.packageUnit, FoodQuantityUnit.millilitres);
    expect(result!.servingQuantity, 250);
    expect(result!.servingUnit, FoodQuantityUnit.millilitres);
    expect(result!.computeNutrition(250).kcal, 106.25);
  });

  testWidgets('per-serving labels do not invent a serving weight or volume', (
    tester,
  ) async {
    PackagedFood? result;
    await _open(tester, food: _label, onResult: (food) => result = food);
    await _basis(tester, 'Per serving');
    expect(find.text('Pack size (g, optional)'), findsNothing);
    expect(find.text('Serving size (g, optional)'), findsNothing);
    await _submit(tester);
    expect(result!.basis, NutritionBasis.perServing);
    expect(result!.packageQuantity, isNull);
    expect(result!.packageUnit, isNull);
    expect(result!.servingQuantity, isNull);
    expect(result!.servingUnit, isNull);
    expect(result!.amountUnit, 'servings');
    expect(result!.computeNutrition(2.5).kcal, 200);
  });

  testWidgets('nonfinite nutrition and nonpositive pack amounts are rejected', (
    tester,
  ) async {
    var returned = false;
    await _open(tester, food: _label, onResult: (_) => returned = true);
    await _enter(tester, 'Protein (g)', 'NaN');
    await _enter(tester, 'Fat (g)', '-3');
    await _enter(tester, 'Pack size (g, optional)', '0');
    await _submit(tester);
    expect(returned, isFalse);
    expect(find.text('Enter the label value'), findsNWidgets(2));
    expect(find.text('Enter an amount above zero'), findsOneWidget);
  });

  testWidgets('known label quantities remain editable without losing units', (
    tester,
  ) async {
    PackagedFood? result;
    await _open(tester, food: _label, onResult: (food) => result = food);
    expect(
      tester
          .widget<TextField>(_field('Pack size (g, optional)'))
          .controller!
          .text,
      '400',
    );
    expect(
      tester
          .widget<TextField>(_field('Serving size (g, optional)'))
          .controller!
          .text,
      '125',
    );
    await _enter(tester, 'Brand (optional)', '  Correct brand  ');
    await _submit(tester);
    expect(result!.brand, 'Correct brand');
    expect(result!.packageQuantity, 400);
    expect(result!.servingQuantity, 125);
    expect(result!.packageUnit, FoodQuantityUnit.grams);
    expect(result!.servingUnit, FoodQuantityUnit.grams);
  });

  testWidgets('narrow dark layout with large text remains scrollable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _open(tester, food: _label, scale: 2, dark: true, onResult: (_) {});
    expect(tester.takeException(), isNull);
    await _basis(tester, 'Per 100 ml');
    await tester.ensureVisible(find.text('Use label values'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Use label values'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester
          .getSize(find.widgetWithText(ElevatedButton, 'Use label values'))
          .height,
      greaterThanOrEqualTo(48),
    );
  });
}
