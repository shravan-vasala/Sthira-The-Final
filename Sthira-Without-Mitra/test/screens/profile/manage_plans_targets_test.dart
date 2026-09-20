import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/repositories/meal_repository.dart';
import 'package:trufit_bodamma/repositories/workout_repository.dart';
import 'package:trufit_bodamma/screens/profile/manage_plans_screen.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';
import 'package:trufit_bodamma/utils/target_calculator.dart';
import 'package:trufit_bodamma/widgets/target_estimate_sheet.dart';

class _Workout extends WorkoutRepository {
  @override
  List<String> getPlanKeys() => [];
}

class _Meals extends MealRepository {
  int writes = 0;
  @override
  List<String> getPlanKeys() => [];
  @override
  Future<void> savePlanJson(String key, String raw) async {
    writes++;
  }
}

class _Profile extends ProfileNotifier {
  _Profile(this.initial);
  final UserProfile initial;
  final writes = <UserProfile>[];
  Completer<void>? pendingSave;
  bool failSave = false;

  @override
  UserProfile build() => initial;

  @override
  Future<void> updateProfile(UserProfile profile) async {
    writes.add(profile);
    if (failSave) throw StateError('Fixture save failure');
    if (pendingSave != null) await pendingSave!.future;
    state = profile;
  }

  void replace(UserProfile profile) => state = profile;
}

Future<ProviderContainer> _mount(
  WidgetTester tester,
  _Profile profile, {
  _Meals? meals,
}) async {
  tester.view.physicalSize = const Size(390, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        workoutRepoProvider.overrideWithValue(_Workout()),
        mealRepoProvider.overrideWithValue(meals ?? _Meals()),
        profileProvider.overrideWith(() => profile),
      ],
      child: MaterialApp(theme: AppTheme.dark, home: const ManagePlansScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(
    tester.element(find.byType(ManagePlansScreen)),
  );
}

Future<TargetEstimateSheet> openEstimate(WidgetTester tester) async {
  await tester.tap(find.text('Recalculate'));
  await tester.pumpAndSettle();
  return tester.widget<TargetEstimateSheet>(find.byType(TargetEstimateSheet));
}

Future<void> returnEstimate(
  WidgetTester tester,
  TargetEstimate? estimate,
) async {
  Navigator.of(tester.element(find.byType(TargetEstimateSheet))).pop(estimate);
  await tester.pumpAndSettle();
}

const revised = TargetEstimateInputs(
  heightCm: 172,
  weightKg: 78,
  age: 37,
  gender: 'M',
  activityLevel: 'Moderately active',
  goal: 'Lose weight',
);

void main() {
  testWidgets('missing values use dedication defaults without goal weight', (
    tester,
  ) async {
    final profile = _Profile(UserProfile(targetWeight: 49));
    await _mount(tester, profile);
    final sheet = await openEstimate(tester);
    expect(sheet.initialInputs.heightCm, 153);
    expect(sheet.initialInputs.weightKg, 66);
    expect(sheet.initialInputs.age, 29);
    expect(sheet.initialInputs.gender, 'F');
    expect(sheet.initialInputs.activityLevel, 'Sedentary');
    expect(sheet.initialInputs.goal, TargetCalculator.normalizeGoal(null));
    await returnEstimate(tester, null);
    expect(profile.writes, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'saved personal values take precedence and cancelling writes nothing',
    (tester) async {
      final profile = _Profile(
        UserProfile(
          height: 179,
          currentWeight: 83,
          targetWeight: 65,
          age: 41,
          gender: 'M',
          activityLevel: 'light',
          primaryGoal: 'Build muscle',
          useKg: false,
        ),
      );
      await _mount(tester, profile);
      final sheet = await openEstimate(tester);
      expect(sheet.initialInputs.heightCm, 179);
      expect(sheet.initialInputs.weightKg, 83);
      expect(sheet.initialInputs.age, 41);
      expect(sheet.initialInputs.gender, 'M');
      expect(
        sheet.initialInputs.activityLevel,
        TargetCalculator.normalizeActivityLevel('light'),
      );
      expect(
        sheet.initialInputs.goal,
        TargetCalculator.normalizeGoal('Build muscle'),
      );
      expect(sheet.useKg, isFalse);
      await returnEstimate(tester, null);
      expect(profile.writes, isEmpty);
    },
  );

  testWidgets(
    'accepting saves inputs and macros once while preserving expert plan',
    (tester) async {
      final profile = _Profile(
        UserProfile(activeMealPlan: 'Expert meals', targetWeight: 60),
      );
      final meals = _Meals();
      await _mount(tester, profile, meals: meals);
      await openEstimate(tester);
      // A newer unrelated edit must survive the estimator result.
      profile.replace(profile.initial.copyWith(name: 'Updated name'));
      final estimate = TargetCalculator.estimate(revised);
      await returnEstimate(tester, estimate);
      expect(profile.writes, hasLength(1));
      final saved = profile.writes.single;
      expect(saved.name, 'Updated name');
      expect(saved.height, revised.heightCm);
      expect(saved.currentWeight, revised.weightKg);
      expect(saved.age, revised.age);
      expect(saved.gender, revised.gender);
      expect(saved.activityLevel, revised.activityLevel);
      expect(saved.primaryGoal, estimate.inputs.goal);
      expect(saved.targetCalories, estimate.targets.calories);
      expect(saved.targetProteinG, estimate.targets.proteinG);
      expect(saved.targetCarbsG, estimate.targets.carbsG);
      expect(saved.targetFatG, estimate.targets.fatG);
      expect(saved.activeMealPlan, 'Expert meals');
      expect(saved.targetWeight, 60);
      expect(meals.writes, 0);
      expect(find.text('Daily targets updated'), findsOneWidget);
    },
  );

  for (final boundary in ['account', 'transition', 'hydration']) {
    testWidgets('estimate cannot apply after $boundary changes', (
      tester,
    ) async {
      final profile = _Profile(UserProfile());
      final container = await _mount(tester, profile);
      await openEstimate(tester);
      if (boundary == 'account') {
        container.read(accountGenerationProvider.notifier).state++;
      } else if (boundary == 'transition') {
        container.read(accountTransitionProvider.notifier).state = true;
      } else {
        container.read(accountHydratingProvider.notifier).state = true;
      }
      await tester.pump();
      await returnEstimate(tester, TargetCalculator.estimate(revised));
      expect(profile.writes, isEmpty);
      expect(find.text('Daily targets updated'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'failed persistence keeps a retry draft and announces the error',
    (tester) async {
      final profile = _Profile(UserProfile())..failSave = true;
      await _mount(tester, profile);
      await openEstimate(tester);
      await returnEstimate(tester, TargetCalculator.estimate(revised));
      final error = find.text(
        'Could not save your targets. Tap Recalculate to review and try again.',
      );
      expect(error, findsOneWidget);
      final liveRegion = find.ancestor(
        of: error,
        matching: find.byType(Semantics),
      );
      expect(
        tester
            .widgetList<Semantics>(liveRegion)
            .any((semantics) => semantics.properties.liveRegion == true),
        isTrue,
      );
      expect(find.text('Daily targets updated'), findsNothing);
      final retry = await openEstimate(tester);
      expect(retry.initialInputs.heightCm, revised.heightCm);
      expect(retry.initialInputs.weightKg, revised.weightKg);
      expect(retry.initialInputs.age, revised.age);
      profile.failSave = false;
      await returnEstimate(tester, TargetCalculator.estimate(revised));
      expect(profile.writes, hasLength(2));
      expect(find.text('Daily targets updated'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('save is awaited and duplicate recalculation stays disabled', (
    tester,
  ) async {
    final pending = Completer<void>();
    final profile = _Profile(UserProfile())..pendingSave = pending;
    await _mount(tester, profile);
    await openEstimate(tester);
    await returnEstimate(tester, TargetCalculator.estimate(revised));
    expect(profile.writes, hasLength(1));
    expect(find.text('Daily targets updated'), findsNothing);
    final button = find.widgetWithText(TextButton, 'Saving...');
    expect(button, findsOneWidget);
    expect(tester.widget<TextButton>(button).onPressed, isNull);
    await tester.tap(button);
    await tester.pump();
    expect(profile.writes, hasLength(1));
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('Daily targets updated'), findsOneWidget);
    expect(find.text('Recalculate'), findsOneWidget);
  });
}
