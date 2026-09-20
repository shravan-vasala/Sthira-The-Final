import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/habit.dart';
import 'package:trufit_bodamma/models/insight.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/models/workout_plan.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/providers/badge_engine_provider.dart';
import 'package:trufit_bodamma/providers/insights_provider.dart';
import 'package:trufit_bodamma/providers/midnight_tick_provider.dart';
import 'package:trufit_bodamma/repositories/exercise_log_repository.dart';
import 'package:trufit_bodamma/repositories/media_repository.dart';
import 'package:trufit_bodamma/screens/home/home_screen.dart';
import 'package:trufit_bodamma/screens/home/widgets/meals_card.dart';
import 'package:trufit_bodamma/screens/home/widgets/week_calendar_strip.dart';
import 'package:trufit_bodamma/services/health_connect_service.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';
import 'package:trufit_bodamma/widgets/surface_card.dart';

final _now = DateTime(2026, 9, 19, 10);

class _Profile extends ProfileNotifier {
  @override
  UserProfile build() =>
      UserProfile(name: 'Tabitha', planStartDate: DateTime(2026, 9, 14));
}

class _Daily extends DailyLogNotifier {
  @override
  DailyLog build() => DailyLog(date: ref.watch(dateStringProvider), weight: 72);
}

class _Meals extends DailyMealLogNotifier {
  @override
  DailyMealLog build() => DailyMealLog(date: ref.watch(dateStringProvider));
}

class _Habits extends HabitCompletionsNotifier {
  @override
  HabitCompletion build() =>
      HabitCompletion(date: ref.watch(dateStringProvider));
}

class _Sync extends SyncController {
  @override
  bool build() => false;
  @override
  Future<void> sync({
    bool isManualRefresh = false,
    String? explicitTargetDate,
  }) async {}
}

class _Midnight extends MidnightTickNotifier {
  @override
  void build() {}
}

class _Badges implements BadgeEngine {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Exercises extends ExerciseLogRepository {
  @override
  bool hasLog(String date, String instanceId) => false;
}

class _Media extends MediaRepository {
  @override
  List<MapEntry<String, List<String>>> getAllProgressPhotos() => [];
}

class _Health implements HealthConnectService {
  @override
  Future<bool> canReadSteps() async => false;
  @override
  Future<bool> isAuthorized() async => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

WorkoutPlan _program({int weeks = 8}) => WorkoutPlan(
  planName: 'Expert program',
  days: [],
  weeks: [
    for (var week = 1; week <= weeks; week++)
      WorkoutWeek(
        weekNumber: week,
        days: [
          for (final day in [
            'monday',
            'tuesday',
            'wednesday',
            'thursday',
            'friday',
            'saturday',
            'sunday',
          ])
            WorkoutDay(
              dayId: day,
              sections: [
                WorkoutSection(
                  title: 'Week $week strength',
                  exercises: [
                    Exercise(name: 'Squat', reps: ['10'])
                      ..instanceId = 'squat-$week-$day',
                  ],
                ),
              ],
            ),
        ],
      ),
  ],
);
Future<({ProviderContainer container, GoRouter router})> _show(
  WidgetTester tester, {
  WorkoutPlan? plan,
  DateTime? selected,
  double width = 390,
  double scale = 1,
  bool light = false,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      profileProvider.overrideWith(_Profile.new),
      dailyLogProvider.overrideWith(_Daily.new),
      dailyMealLogProvider.overrideWith(_Meals.new),
      habitCompletionsProvider.overrideWith(_Habits.new),
      allHabitsProvider.overrideWithValue([]),
      workoutPlanProvider.overrideWithValue(plan),
      mealPlanProvider.overrideWithValue(null),
      clockProvider.overrideWithValue(_now),
      selectedDateProvider.overrideWith(
        (ref) => selected ?? DateTime(2026, 9, 19),
      ),
      midnightTickProvider.overrideWith(_Midnight.new),
      syncControllerProvider.overrideWith(_Sync.new),
      sharedPreferencesProvider.overrideWithValue(prefs),
      badgeEngineProvider.overrideWithValue(_Badges()),
      exerciseLogRepoProvider.overrideWithValue(_Exercises()),
      mediaRepoProvider.overrideWithValue(_Media()),
      healthConnectServiceProvider.overrideWithValue(_Health()),
      phaseProgressProvider.overrideWith(
        (ref) => PhaseProgress.calculate(
          plan: plan,
          planStartDate: DateTime(2026, 9, 14),
          date: ref.watch(selectedDateProvider),
          today: _now,
          getLog: (_) => null,
          hasLog: (_, _) => false,
        ),
      ),
      dailyScoreProvider.overrideWithValue(
        DailyScore(
          totalScore: 0,
          isFutureDate: false,
          habitsScore: 0,
          habitsMax: 0,
          workoutsScore: 0,
          workoutsMax: 40,
          mealsScore: 0,
          mealsMax: 20,
          totalMax: 60,
          date: _now,
        ),
      ),
      calendarWeekActivityProvider.overrideWith((ref, week) => {}),
      insightsProvider.overrideWithValue([
        Insight(
          id: 'sample',
          type: InsightType.trend,
          title: 'Recent activity',
          description: 'Recorded days help you see your progress.',
          severity: InsightSeverity.neutral,
          dateGenerated: _now,
          icon: Icons.insights_rounded,
        ),
      ]),
    ],
  );
  addTearDown(container.dispose);
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: '/home/meals',
        builder: (_, _) => const Scaffold(body: Text('Meal destination')),
      ),
      GoRoute(
        path: '/home/workout/:day',
        builder: (_, state) => Scaffold(
          body: Text('Workout destination: ${state.pathParameters['day']}'),
        ),
      ),
      GoRoute(
        path: '/progress/weekly-summary',
        builder: (_, _) => Consumer(
          builder: (_, ref, _) => Scaffold(
            body: Text('Summary for ${ref.watch(dateStringProvider)}'),
          ),
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, _) => const Scaffold(body: Text('Profile destination')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: light ? AppTheme.light : AppTheme.dark,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (container: container, router: router);
}

Finder _workoutCard() => find.ancestor(
  of: find.text('Week 1 strength'),
  matching: find.byType(SurfaceCard),
);
Future<void> _visible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  for (final duration in [8, 10]) {
    testWidgets(
      '$duration-week programs appear on Home and open the selected workout',
      (tester) async {
        await _show(tester, plan: _program(weeks: duration));
        expect(find.text('Week 1 strength'), findsOneWidget);
        expect(find.text('Week 1 of $duration'), findsOneWidget);
        await _visible(tester, find.text('Week 1 strength'));
        await tester.tap(find.text('Week 1 strength'));
        await tester.pumpAndSettle();
        expect(find.text('Workout destination: saturday'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  testWidgets(
    'upcoming workouts are clearly scheduled and do not offer an inactive action',
    (tester) async {
      final app = await _show(
        tester,
        plan: _program(),
        selected: DateTime(2026, 9, 20),
      );
      final card = _workoutCard();
      expect(find.text('1 exercise · Upcoming workout'), findsOneWidget);
      expect(find.textContaining('Ready to start'), findsNothing);
      expect(tester.widget<SurfaceCard>(card).onTap, isNull);
      expect(
        find.descendant(
          of: card,
          matching: find.byIcon(Icons.chevron_right_rounded),
        ),
        findsNothing,
      );
      await _visible(tester, find.text('Week 1 strength'));
      await tester.tap(find.text('Week 1 strength'));
      await tester.pumpAndSettle();
      expect(app.router.routeInformationProvider.value.uri.path, '/home');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'weekly summary keeps its selected historical date and accurate label',
    (tester) async {
      await _show(tester, selected: DateTime(2026, 9, 8));
      expect(find.text("This week's summary"), findsNothing);
      await _visible(tester, find.text('Weekly summary'));
      await tester.tap(find.text('Weekly summary'));
      await tester.pumpAndSettle();
      expect(find.text('Summary for 2026-09-08'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'meal gutters remain scrollable and the actual tile opens meals',
    (tester) async {
      final app = await _show(tester);
      final card = find.descendant(
        of: find.byType(MealsCard),
        matching: find.byType(SurfaceCard),
      );
      await _visible(tester, card);
      final rect = tester.getRect(card);
      await tester.tapAt(Offset(8, rect.center.dy));
      await tester.pumpAndSettle();
      expect(app.router.routeInformationProvider.value.uri.path, '/home');
      await tester.tap(find.text("Today's Meals"));
      await tester.pumpAndSettle();
      expect(find.text('Meal destination'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'meal tile is a keyboard accessible action with its nutrition summary',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _show(tester);
        final card = find.descendant(
          of: find.byType(MealsCard),
          matching: find.byType(SurfaceCard),
        );
        await _visible(tester, card);
        final ink = find.descendant(of: card, matching: find.byType(InkWell));
        final focus = Focus.of(
          tester.element(
            find.descendant(of: ink, matching: find.byType(Padding)).last,
          ),
        );
        focus.requestFocus();
        await tester.pump();
        final node = tester.getSemantics(ink);
        expect(node.flagsCollection.isButton, isTrue);
        expect(node.getSemanticsData().label, contains('calories logged'));
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.text('Meal destination'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        semantics.dispose();
      }
    },
  );
  for (final light in [false, true]) {
    testWidgets(
      'Home sections and one Today action remain usable at320/200 light=$light',
      (tester) async {
        final app = await _show(
          tester,
          plan: _program(),
          width: 320,
          scale: 2,
          light: light,
          selected: DateTime(2026, 9, 18),
        );
        expect(find.text('Today'), findsOneWidget);
        expect(find.text('Return to today'), findsNothing);
        await _visible(tester, find.text('Today'));
        await tester.tap(find.text('Today'));
        await tester.pumpAndSettle();
        expect(app.container.read(selectedDateProvider), DateTime(2026, 9, 19));
        expect(find.text('Today'), findsNothing);
        for (final section in [
          'Week 1 strength',
          'Habits',
          'Meals',
          'Daily progress',
          'Recent activity',
          'Daily check-in',
        ]) {
          await _visible(tester, find.text(section).first);
          expect(tester.takeException(), isNull);
        }
        expect(find.text('How did today feel?'), findsOneWidget);
        expect(find.text('Struggled'), findsNothing);
        expect(find.byType(TextField), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
