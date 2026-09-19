import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/providers/progress_chart_provider.dart';
import 'package:trufit_bodamma/screens/home/widgets/meals_card.dart';
import 'package:trufit_bodamma/screens/progress/progress_screen.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';

class _Profile extends ProfileNotifier {
  @override
  UserProfile build() => UserProfile(name: 'Alex', height: 180);
}

class _Meals extends DailyMealLogNotifier {
  @override
  DailyMealLog build() => DailyMealLog(
    date: '2026-09-19',
    customSlots: {
      'lunch': MealSlotLog(
        totalCalories: 1800,
        totalProtein: 120,
        totalCarbs: 210,
        totalFat: 75,
      ),
    },
  );
}

Widget _largeTextApp(Widget child) => MaterialApp(
  theme: AppTheme.dark,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: const TextScaler.linear(2), disableAnimations: true),
    child: child!,
  ),
  home: child,
);

void main() {
  testWidgets('meal macros wrap on narrow screens with larger text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith(_Profile.new),
          dailyMealLogProvider.overrideWith(_Meals.new),
          mealPlanProvider.overrideWithValue(null),
          dateStringProvider.overrideWithValue('2026-09-19'),
        ],
        child: _largeTextApp(
          const Scaffold(body: SingleChildScrollView(child: MealsCard())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('P: 120g'), findsOneWidget);
    expect(find.text('C: 210g'), findsOneWidget);
    expect(find.text('F: 75g'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('F: 75g')).dy,
      greaterThan(tester.getTopLeft(find.text('P: 120g')).dy),
    );
  });

  testWidgets(
    'large-text progress ranges stay reachable and announce selection',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              profileProvider.overrideWith(_Profile.new),
              aggregatedChartProvider.overrideWith((ref, args) => []),
            ],
            child: _largeTextApp(const ProgressScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final selected = find.bySemanticsLabel('1 month');
        expect(
          tester.getSemantics(selected).hasFlag(SemanticsFlag.isSelected),
          isTrue,
        );
        expect(tester.getSize(selected).height, greaterThanOrEqualTo(48));
        expect(tester.getSize(selected).width, greaterThanOrEqualTo(48));

        await tester.ensureVisible(find.text('12M'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('12M'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('12 months'))
              .hasFlag(SemanticsFlag.isSelected),
          isTrue,
        );
      } finally {
        semantics.dispose();
      }
    },
  );
}
