import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/repositories/workout_repository.dart';
import 'package:trufit_bodamma/repositories/meal_repository.dart';
import 'package:trufit_bodamma/screens/profile/manage_plans_screen.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';

class _Workout extends WorkoutRepository {
  @override
  List<String> getPlanKeys() => [];
}

class _Meals extends MealRepository {
  @override
  List<String> getPlanKeys() => [];
}

class _Profile extends ProfileNotifier {
  @override
  UserProfile build() => UserProfile();
}

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'Manage Plans mounts with scrolling tabs at 320px and scale $scale',
      (tester) async {
        tester.view.physicalSize = const Size(320, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              workoutRepoProvider.overrideWithValue(_Workout()),
              mealRepoProvider.overrideWithValue(_Meals()),
              profileProvider.overrideWith(_Profile.new),
            ],
            child: MaterialApp(
              theme: AppTheme.dark,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: const ManagePlansScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Manage Plans'), findsOneWidget);
        expect(
          tester.widget<TabBar>(find.byType(TabBar)).tabAlignment,
          TabAlignment.start,
        );
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(TabBar), const Offset(-600, 0));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Meal Slots'));
        await tester.pumpAndSettle();
        expect(find.text('Breakfast'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
