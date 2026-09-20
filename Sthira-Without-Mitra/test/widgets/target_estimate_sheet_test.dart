import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';
import 'package:trufit_bodamma/utils/target_calculator.dart';
import 'package:trufit_bodamma/widgets/app_bottom_sheet.dart';
import 'package:trufit_bodamma/widgets/primary_button.dart';
import 'package:trufit_bodamma/widgets/target_estimate_sheet.dart';

class _SheetResult {
  TargetEstimate? value;
  bool completed = false;
}

TargetEstimateInputs _defaults() => const TargetEstimateInputs(
  age: 29,
  gender: 'F',
  heightCm: 153,
  weightKg: 66,
  activityLevel: 'Sedentary',
  goal: 'Maintain',
);

Future<_SheetResult> _showSheet(
  WidgetTester tester, {
  TargetEstimateInputs? inputs,
  bool useKg = true,
  bool dark = false,
  double scale = 1,
  Size size = const Size(500, 1100),
}) async {
  final result = _SheetResult();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
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
            child: const Text('Open estimator'),
            onPressed: () async {
              result.value = await showAppBottomSheet<TargetEstimate>(
                context: context,
                builder: (_) => TargetEstimateSheet(
                  initialInputs: inputs ?? _defaults(),
                  useKg: useKg,
                ),
              );
              result.completed = true;
            },
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open estimator'));
  await tester.pumpAndSettle();
  return result;
}

Finder _field(String name) => find.byKey(ValueKey('estimate-$name'));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String name, String value) async {
  await tester.ensureVisible(_field(name));
  await tester.enterText(_field(name), value);
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, String name, String value) async {
  await _tap(tester, _field(name));
  await _tap(tester, find.text(value).last);
}

void _expectEstimate(TargetEstimate? actual, TargetEstimate expected) {
  expect(actual, isNotNull);
  expect(actual!.inputs.age, expected.inputs.age);
  expect(actual.inputs.gender, expected.inputs.gender);
  expect(actual.inputs.heightCm, expected.inputs.heightCm);
  expect(actual.inputs.weightKg, expected.inputs.weightKg);
  expect(actual.inputs.activityLevel, expected.inputs.activityLevel);
  expect(actual.inputs.goal, expected.inputs.goal);
  expect(actual.maintenanceCalories, expected.maintenanceCalories);
  expect(actual.targets.calories, expected.targets.calories);
  expect(actual.targets.proteinG, expected.targets.proteinG);
  expect(actual.targets.carbsG, expected.targets.carbsG);
  expect(actual.targets.fatG, expected.targets.fatG);
}

void main() {
  testWidgets(
    'confirmed defaults are editable and only returned after applying',
    (tester) async {
      final result = await _showSheet(tester);
      expect(tester.widget<TextField>(_field('age')).controller!.text, '29');
      expect(
        tester.widget<TextField>(_field('height')).controller!.text,
        '153',
      );
      expect(tester.widget<TextField>(_field('weight')).controller!.text, '66');
      expect(find.text('Female'), findsOneWidget);
      expect(find.text('Sedentary'), findsOneWidget);
      expect(
        tester.widget<ChoiceChip>(_field('goal-Maintain')).selected,
        isTrue,
      );
      final expected = TargetCalculator.estimate(_defaults());
      expect(find.text('${expected.targets.calories} kcal'), findsOneWidget);
      expect(
        find.text('Maintenance estimate: ${expected.maintenanceCalories} kcal'),
        findsOneWidget,
      );
      expect(result.completed, isFalse);
      await _tap(tester, find.text('Use these targets'));
      expect(result.completed, isTrue);
      _expectEstimate(result.value, expected);
    },
  );

  testWidgets('all six input edits update the preview and applied estimate', (
    tester,
  ) async {
    final result = await _showSheet(tester);
    await _enter(tester, 'age', '42');
    await _enter(tester, 'height', '180');
    await _enter(tester, 'weight', '80.5');
    await _choose(tester, 'gender', 'Male');
    await _choose(tester, 'activity', 'Very active');
    await _tap(tester, _field('goal-Lose weight'));
    final expected = TargetCalculator.estimate(
      const TargetEstimateInputs(
        age: 42,
        gender: 'M',
        heightCm: 180,
        weightKg: 80.5,
        activityLevel: 'Very active',
        goal: 'Lose weight',
      ),
    );
    expect(find.text('${expected.targets.calories} kcal'), findsOneWidget);
    expect(find.text('Protein ${expected.targets.proteinG} g'), findsOneWidget);
    expect(find.text('Carbs ${expected.targets.carbsG} g'), findsOneWidget);
    expect(find.text('Fat ${expected.targets.fatG} g'), findsOneWidget);
    await _tap(tester, find.text('Use these targets'));
    _expectEstimate(result.value, expected);
  });

  testWidgets('closing after draft changes returns no targets', (tester) async {
    final result = await _showSheet(tester);
    await _enter(tester, 'age', '45');
    await _tap(tester, find.byTooltip('Close'));
    expect(result.completed, isTrue);
    expect(result.value, isNull);
    expect(find.byType(TargetEstimateSheet), findsNothing);
  });

  testWidgets('invalid input removes stale preview and disables applying', (
    tester,
  ) async {
    final result = await _showSheet(tester);
    for (final entry in {
      'age': '17',
      'height': '99',
      'weight': 'NaN',
    }.entries) {
      await _enter(tester, entry.key, entry.value);
      expect(find.byKey(const Key('estimate-calories')), findsNothing);
      expect(
        tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
        isNull,
      );
      expect(result.completed, isFalse);
      await _enter(
        tester,
        entry.key,
        {'age': '29', 'height': '153', 'weight': '66'}[entry.key]!,
      );
      expect(find.byKey(const Key('estimate-calories')), findsOneWidget);
    }
    await _enter(tester, 'age', '');
    expect(find.text('Enter an age from 18 to 100'), findsOneWidget);
    expect(
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
      isNull,
    );
  });

  for (final useKg in [true, false]) {
    testWidgets(
      'unchanged measurements retain full precision with useKg=$useKg',
      (tester) async {
        const inputs = TargetEstimateInputs(
          age: 37,
          gender: 'M',
          heightCm: 176.123456,
          weightKg: 72.345678,
          activityLevel: 'Lightly active',
          goal: 'Maintain',
        );
        final result = await _showSheet(tester, inputs: inputs, useKg: useKg);
        expect(find.text(useKg ? 'kg' : 'lb'), findsOneWidget);
        await _tap(tester, find.text('Use these targets'));
        _expectEstimate(result.value, TargetCalculator.estimate(inputs));
      },
    );
  }

  testWidgets('edited pounds are converted once to kilograms', (tester) async {
    final result = await _showSheet(tester, useKg: false);
    await _enter(tester, 'weight', '176.3696');
    await _tap(tester, find.text('Use these targets'));
    expect(result.value!.inputs.weightKg, closeTo(80, 0.000001));
  });

  for (final dark in [false, true]) {
    testWidgets(
      '320px large text supports fields, menus and apply above keyboard dark=$dark',
      (tester) async {
        final result = await _showSheet(
          tester,
          dark: dark,
          scale: 2,
          size: const Size(320, 740),
        );
        tester.view.viewInsets = const FakeViewPadding(bottom: 250);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await _enter(tester, 'height', '160');
        await _enter(tester, 'weight', '65');
        expect(tester.takeException(), isNull);
        await _choose(tester, 'gender', 'Male');
        await _choose(tester, 'activity', 'Moderately active');
        await _tap(tester, _field('goal-Gain weight'));
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Use these targets'));
        await tester.pumpAndSettle();
        final buttonRect = tester.getRect(find.byType(PrimaryButton));
        expect(buttonRect.bottom, lessThanOrEqualTo(490));
        await _tap(tester, find.text('Use these targets'));
        expect(tester.takeException(), isNull);
        expect(result.completed, isTrue);
        expect(result.value!.inputs.heightCm, 160);
        expect(result.value!.inputs.weightKg, 65);
        expect(result.value!.inputs.gender, 'M');
        expect(result.value!.inputs.activityLevel, 'Moderately active');
        expect(result.value!.inputs.goal, 'Gain weight');
      },
    );
  }
}
