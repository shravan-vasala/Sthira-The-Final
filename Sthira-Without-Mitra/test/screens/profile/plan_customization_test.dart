import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/models/workout_plan.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/repositories/workout_repository.dart';
import 'package:trufit_bodamma/repositories/meal_repository.dart';
import 'package:trufit_bodamma/screens/profile/manage_plans_screen.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';

class _Plans extends WorkoutRepository {
  final plans = <String, WorkoutPlan>{
    'Expert routine': WorkoutPlan(
      planName: 'Expert routine',
      source: 'seed',
      seedVersion: 2,
      durationWeeks: 8,
      days: [
        WorkoutDay(
          dayId: 'monday',
          sections: [
            WorkoutSection(
              title: 'Workout',
              exercises: [
                Exercise(name: 'Squat', reps: ['8', '10']),
              ],
            ),
          ],
        ),
      ],
    )..ensureExerciseIds(),
  };
  @override
  List<String> getPlanKeys() => plans.keys.toList();
  @override
  String? getRawPlanJson(String key) =>
      plans[key] == null ? null : jsonEncode(plans[key]!.toJson());
  @override
  Future<void> savePlanJson(String key, String data) async {
    plans[key] = WorkoutPlan.fromJson(jsonDecode(data) as Map<String, dynamic>);
  }
}

class _Meals extends MealRepository {
  final plans = <String, Map<String, dynamic>>{};
  @override
  List<String> getPlanKeys() => plans.keys.toList();
  @override
  String? getRawPlanJson(String key) =>
      plans[key] == null ? null : jsonEncode(plans[key]);
  @override
  Future<void> savePlanJson(String key, String data) async {
    final decoded = jsonDecode(data) as Map<String, dynamic>;
    if (decoded['meals'] is! List) {
      throw const FormatException('The meals field must be an array.');
    }
    plans[key] = decoded;
  }
}

class _Profile extends ProfileNotifier {
  @override
  UserProfile build() => UserProfile(activeWorkoutPlan: 'Expert routine');
  @override
  Future<void> updateProfile(UserProfile value) async {
    state = value;
  }
}

Future<void> _pumpPlans(
  WidgetTester tester,
  _Plans plans, {
  _Meals? meals,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        workoutRepoProvider.overrideWithValue(plans),
        mealRepoProvider.overrideWithValue(meals ?? _Meals()),
        profileProvider.overrideWith(_Profile.new),
        activeDatabaseProvider.overrideWithValue(null),
      ],
      child: MaterialApp(theme: AppTheme.dark, home: const ManagePlansScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(
  WidgetTester tester,
  Finder target, {
  double delta = 180,
}) async {
  final scrollable = find
      .byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      )
      .first;
  await tester.scrollUntilVisible(
    target,
    delta,
    scrollable: scrollable,
    maxScrolls: 50,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'a malformed meal draft reports validation without crashing summary',
    (tester) async {
      final meals = _Meals();
      final saved = <String, dynamic>{
        'planName': 'My meals',
        'source': 'user',
        'meals': [
          {'mealId': 'lunch', 'name': 'Lunch', 'calories': 400, 'items': []},
        ],
      };
      meals.plans['My meals'] = saved;
      await _pumpPlans(tester, _Plans(), meals: meals);
      await tester.tap(find.text('Meal Plans'));
      await tester.pumpAndSettle();
      await _scrollTo(tester, find.text('Edit plan JSON'));
      await tester.tap(find.text('Edit plan JSON'));
      await tester.pumpAndSettle();
      final json = find.byKey(const ValueKey('meal-plan-json'));
      await _scrollTo(tester, json);
      final draftController = tester.widget<TextField>(json).controller!;
      await tester.enterText(
        json,
        jsonEncode({...saved, 'meals': 'not an array'}),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      await _scrollTo(tester, find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await _scrollTo(tester, find.text('The meals field must be an array.'));
      expect(find.text('The meals field must be an array.'), findsOneWidget);
      expect(meals.plans['My meals'], saved);
      expect(draftController.text, contains('not an array'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('an unspecified routine stays ongoing after customize and save', (
    tester,
  ) async {
    final plans = _Plans();
    final original = plans.plans['Expert routine']!.toJson()
      ..remove('durationWeeks');
    plans.plans['Expert routine'] = WorkoutPlan.fromJson(original);
    await _pumpPlans(tester, plans);
    final length = find.byKey(const ValueKey('program-weeks'));
    expect(tester.widget<TextField>(length).controller!.text, isEmpty);
    await tester.tap(find.text('Customize'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(length).controller!.text, isEmpty);
    await _scrollTo(tester, find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(plans.plans['Expert routine (Custom)']!.durationWeeks, isNull);
    expect(plans.plans['Expert routine']!.durationWeeks, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid weeks draft is retained and rejected before save', (
    tester,
  ) async {
    final plans = _Plans();
    await _pumpPlans(tester, plans);
    await tester.tap(find.text('Customize'));
    await tester.pumpAndSettle();
    final saved = plans.getRawPlanJson('Expert routine (Custom)');
    final draft = jsonDecode(saved!) as Map<String, dynamic>;
    draft['weeks'] = 'not an array';
    await _scrollTo(tester, find.text('Edit plan JSON'));
    await tester.tap(find.text('Edit plan JSON'));
    await tester.pumpAndSettle();
    final json = find.byKey(const ValueKey('workout-plan-json'));
    await _scrollTo(tester, json);
    final draftController = tester.widget<TextField>(json).controller!;
    await tester.enterText(json, jsonEncode(draft));
    await tester.pump();
    await _scrollTo(tester, find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('The weeks field must be an array.'));
    expect(find.text('The weeks field must be an array.'), findsOneWidget);
    expect(plans.getRawPlanJson('Expert routine (Custom)'), saved);
    expect(draftController.text, contains('not an array'));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'customizing preserves expert original and visibly saves a 10 week override',
    (tester) async {
      final plans = _Plans();
      final original = plans.getRawPlanJson('Expert routine');
      final container = ProviderContainer(
        overrides: [
          workoutRepoProvider.overrideWithValue(plans),
          mealRepoProvider.overrideWithValue(_Meals()),
          profileProvider.overrideWith(_Profile.new),
          activeDatabaseProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const ManagePlansScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Customize'));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      expect(
        find.text('Your custom plan · Based on Expert routine'),
        findsOneWidget,
      );
      expect(plans.plans['Expert routine (Custom)']!.source, 'user');
      expect(
        plans.plans['Expert routine (Custom)']!.basedOnPlanName,
        'Expert routine',
      );
      expect(
        container.read(profileProvider).activeWorkoutPlan,
        'Expert routine (Custom)',
      );
      final length = find.byKey(const ValueKey('program-weeks'));
      await tester.ensureVisible(length);
      await tester.enterText(length, '10');
      await tester.pump();
      await tester.tap(find.text('Meal Plans'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Workout Plans'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(length).controller!.text, '10');
      await tester.ensureVisible(find.text('Save and use'));
      await tester.tap(find.text('Save and use'));
      await tester.pumpAndSettle();
      expect(plans.plans['Expert routine (Custom)']!.durationWeeks, 10);
      expect(plans.getRawPlanJson('Expert routine'), original);
      expect(find.text('Unsaved changes'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'leaving Manage Plans keeps unsaved drafts until explicitly discarded',
    (tester) async {
      final plans = _Plans();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workoutRepoProvider.overrideWithValue(plans),
            mealRepoProvider.overrideWithValue(_Meals()),
            profileProvider.overrideWith(_Profile.new),
            activeDatabaseProvider.overrideWithValue(null),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const ManagePlansScreen(),
                    ),
                  ),
                  child: const Text('Open plans'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open plans'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Customize'));
      await tester.pumpAndSettle();
      final length = find.byKey(const ValueKey('program-weeks'));
      await tester.ensureVisible(length);
      await tester.enterText(length, '10');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
      await tester.pumpAndSettle();
      expect(find.text('Discard unsaved plan changes?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(length).controller!.text, '10');
      expect(plans.plans['Expert routine (Custom)']!.durationWeeks, 8);
      expect(tester.takeException(), isNull);
    },
  );
}
