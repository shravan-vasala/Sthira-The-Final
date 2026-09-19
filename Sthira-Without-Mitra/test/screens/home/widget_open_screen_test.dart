import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/models/workout_plan.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/screens/home/widget_open_screen.dart';

class _Profile extends ProfileNotifier {
  _Profile(this.start);
  final DateTime? start;
  @override
  UserProfile build() => UserProfile(planStartDate: start);
}

ProviderContainer _container({
  required DateTime Function() clock,
  WorkoutPlan? plan,
  DateTime? start,
  bool hydrating = false,
  bool transitioning = false,
}) => ProviderContainer(
  overrides: [
    clockProvider.overrideWith((ref) => clock()),
    workoutPlanProvider.overrideWithValue(plan),
    profileProvider.overrideWith(() => _Profile(start)),
    selectedDateProvider.overrideWith((ref) => DateTime(2020, 1, 1)),
    weekOffsetProvider.overrideWith((ref) => -12),
    accountHydratingProvider.overrideWith((ref) => hydrating),
    accountTransitionProvider.overrideWith((ref) => transitioning),
  ],
);

Future<GoRouter> _mount(
  WidgetTester tester,
  ProviderContainer container,
  String action,
) async {
  final router = GoRouter(
    initialLocation: '/widget/$action',
    routes: [
      GoRoute(
        path: '/widget/:action',
        builder: (context, state) =>
            WidgetOpenScreen(action: state.pathParameters['action']!),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) =>
            const Scaffold(body: Text('Home destination')),
      ),
      GoRoute(
        path: '/home/meals',
        builder: (context, state) =>
            const Scaffold(body: Text('Meal destination')),
      ),
      GoRoute(
        path: '/home/workout/:dayId',
        builder: (context, state) =>
            Scaffold(body: Text('Workout ${state.pathParameters['dayId']}')),
      ),
      GoRoute(
        path: '/progress',
        builder: (context, state) => Scaffold(
          body: Text('Progress ${state.uri.queryParameters['metric']}'),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  return router;
}

WorkoutDay _training(String dayId) => WorkoutDay(
  dayId: dayId,
  sections: [
    WorkoutSection(
      title: 'Workout',
      exercises: [
        Exercise(name: 'Squat', reps: ['10']),
      ],
    ),
  ],
);

WorkoutPlan _tenWeeks() => WorkoutPlan(
  planName: 'Ten week routine',
  days: [],
  weeks: List.generate(
    10,
    (index) => WorkoutWeek(
      weekNumber: index + 1,
      days: [
        _training('monday'),
        index == 9
            ? _training('Saturday')
            : WorkoutDay(
                dayId: 'saturday',
                sections: [WorkoutSection(title: 'Rest', exercises: [])],
              ),
      ],
    ),
  ),
);

void main() {
  for (final entry in {
    'home': '/home',
    'steps': '/progress?metric=steps',
    'meals': '/home/meals',
    'unknown': '/home',
  }.entries) {
    testWidgets(
      '${entry.key} launcher resets historical date before opening destination',
      (tester) async {
        final now = DateTime(2026, 9, 19, 16, 45);
        final container = _container(clock: () => now);
        addTearDown(container.dispose);
        final router = await _mount(tester, container, entry.key);
        await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.toString(),
          entry.value,
        );
        expect(container.read(selectedDateProvider), DateTime(2026, 9, 19));
        expect(container.read(weekOffsetProvider), 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'workout launcher resolves today in week ten instead of first or eighth week',
    (tester) async {
      final now = DateTime(2026, 9, 19, 9);
      final container = _container(
        clock: () => now,
        plan: _tenWeeks(),
        start: DateTime(2026, 7, 18),
      );
      addTearDown(container.dispose);
      final router = await _mount(tester, container, 'workout');
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/home/workout/Saturday',
      );
      expect(find.text('Workout Saturday'), findsOneWidget);
      expect(container.read(selectedDateProvider), DateTime(2026, 9, 19));
      expect(tester.takeException(), isNull);
    },
  );

  for (final hasPlan in [false, true]) {
    testWidgets(
      'workout launcher uses Home for ${hasPlan ? 'an empty-section rest day' : 'no plan'}',
      (tester) async {
        final now = DateTime(2026, 9, 20);
        final plan = hasPlan
            ? WorkoutPlan(
                planName: 'Weekly',
                days: [
                  _training('monday'),
                  WorkoutDay(
                    dayId: 'sunday',
                    sections: [
                      WorkoutSection(title: 'Rest Day', exercises: []),
                    ],
                  ),
                ],
              )
            : null;
        final container = _container(clock: () => now, plan: plan);
        addTearDown(container.dispose);
        final router = await _mount(tester, container, 'workout');
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/home');
        expect(container.read(selectedDateProvider), now);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'waits for account hydration and transition then refreshes a cached previous day',
    (tester) async {
      var now = DateTime(2026, 9, 18, 23, 59);
      final container = _container(
        clock: () => now,
        plan: _tenWeeks(),
        start: DateTime(2026, 7, 18),
        hydrating: true,
        transitioning: true,
      );
      addTearDown(container.dispose);
      expect(container.read(clockProvider).day, 18);
      final router = await _mount(tester, container, 'workout');
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(WidgetOpenScreen), findsOneWidget);
      expect(container.read(selectedDateProvider), DateTime(2020, 1, 1));
      container.read(accountHydratingProvider.notifier).state = false;
      await tester.pump(const Duration(milliseconds: 200));
      expect(router.routeInformationProvider.value.uri.path, '/widget/workout');
      now = DateTime(2026, 9, 19, 0, 1);
      container.read(accountGenerationProvider.notifier).state++;
      container.read(accountTransitionProvider.notifier).state = false;
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/home/workout/Saturday',
      );
      expect(container.read(selectedDateProvider), DateTime(2026, 9, 19));
      expect(container.read(weekOffsetProvider), 0);
      expect(tester.takeException(), isNull);
    },
  );
}
