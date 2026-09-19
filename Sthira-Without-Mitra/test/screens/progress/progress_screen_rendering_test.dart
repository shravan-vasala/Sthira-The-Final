import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/habit.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/screens/progress/progress_screen.dart';
import 'package:trufit_bodamma/screens/progress/widgets/chart_drilldown_sheet.dart';
import 'package:trufit_bodamma/screens/progress/widgets/shared_chart_card.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';
import 'package:trufit_bodamma/widgets/app_navigation_bar.dart';
import 'package:trufit_bodamma/widgets/rest_timer_bar.dart';

class _Profile extends ProfileNotifier {
  _Profile(this.height);
  final double? height;
  @override
  UserProfile build() =>
      UserProfile(useKg: true, height: height, targetWeight: 75);
}

List<DailyLog> _readings() => [
  DailyLog(date: '2026-09-01', weight: 82),
  DailyLog(date: '2026-09-10', weight: 81),
  DailyLog(date: '2026-09-13', steps: 4000, sleepHours: 7),
  DailyLog(date: '2026-09-14', steps: 0, sleepHours: 7.5),
  DailyLog(date: '2026-09-15', steps: 6500, sleepHours: 8),
  DailyLog(date: '2026-09-16', weight: 83, steps: 8000, sleepHours: 7.25),
  DailyLog(date: '2026-09-17', weight: 80.5, steps: 8500, sleepHours: 7.75),
  DailyLog(date: '2026-09-18', steps: 10000, sleepHours: 8),
  DailyLog(date: '2026-09-19', steps: 2000, sleepHours: 7.5),
];

Future<ProviderContainer> _show(
  WidgetTester tester, {
  MetricType metric = MetricType.weight,
  List<DailyLog>? logs,
  List<Habit> goals = const [],
  List<DailyMealLog> meals = const [],
  double? height = 180,
  Size size = const Size(390, 844),
  double textScale = 1,
  bool dark = true,
  bool canPop = false,
  bool withDock = false,
  bool timer = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      profileProvider.overrideWith(() => _Profile(height)),
      dailyLogsRangeProvider.overrideWith((ref, _) => logs ?? _readings()),
      dailyMealLogsRangeProvider.overrideWith((ref, _) => meals),
      allHabitsProvider.overrideWithValue(goals),
      habitsProvider.overrideWithValue([]),
      clockProvider.overrideWithValue(DateTime(2026, 9, 19, 14)),
      selectedDateProvider.overrideWith((ref) => DateTime(2026, 8, 1)),
    ],
  );
  addTearDown(container.dispose);
  final router = GoRouter(
    initialLocation: canPop ? '/home' : '/progress',
    routes: [
      GoRoute(
        path: '/progress',
        builder: (_, _) => withDock
            ? Scaffold(
                extendBody: true,
                body: ProgressScreen(initialMetric: metric),
                bottomNavigationBar: AppNavigationDock(
                  currentIndex: 1,
                  onItemSelected: (_) {},
                  restTimer: timer
                      ? RestTimerBar(
                          remainingSeconds: 75,
                          isPaused: false,
                          exerciseName: 'Dumbbell rows',
                          onAddSeconds: (_) {},
                          onTogglePause: () {},
                          onClose: () {},
                        )
                      : null,
                ),
              )
            : ProgressScreen(initialMetric: metric),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('Home day')),
        routes: [
          GoRoute(
            path: 'meals',
            builder: (_, _) => const Scaffold(body: Text('Meal logging')),
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        builder: (_, _) => const Scaffold(body: Text('Profile details')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: dark ? AppTheme.dark : AppTheme.light,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            padding: withDock ? const EdgeInsets.only(bottom: 34) : null,
            viewPadding: withDock ? const EdgeInsets.only(bottom: 34) : null,
          ),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (canPop) {
    unawaited(router.push('/progress'));
    await tester.pumpAndSettle();
  }
  return container;
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _metric(WidgetTester tester, String label) async {
  await _tap(tester, find.byKey(const Key('progress-metric-picker')));
  final sheet = find.text('Choose a metric');
  expect(sheet, findsOneWidget);
  final row = find.widgetWithText(ListTile, label);
  await _tap(tester, row);
}

SharedChartCard _chart(WidgetTester tester) =>
    tester.widget<SharedChartCard>(find.byType(SharedChartCard));
String? _hero(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('progress-hero'))).data;

void main() {
  for (final timer in [false, true]) {
    testWidgets('last Progress record clears the measured dock, timer=$timer', (
      tester,
    ) async {
      await _show(
        tester,
        metric: MetricType.steps,
        size: const Size(320, 844),
        textScale: 2,
        withDock: true,
        timer: timer,
      );
      await _tap(tester, find.text('Daily records'));
      final scroll = tester
          .widget<SingleChildScrollView>(
            find.byKey(const Key('progress-scroll')),
          )
          .controller!;
      scroll.jumpTo(scroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
      final records = find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'progress-record-',
            ),
      );
      expect(records, findsWidgets);
      final bottom = records
          .evaluate()
          .map(
            (element) => tester.getRect(find.byWidget(element.widget)).bottom,
          )
          .reduce((first, second) => first > second ? first : second);
      final footer = timer
          ? find.byType(RestTimerBar)
          : find.byType(AppNavigationBar);
      expect(bottom, lessThan(tester.getRect(footer).top));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }

  testWidgets('empty period has useful logging action and no fabricated hero', (
    tester,
  ) async {
    await _show(tester, logs: []);
    expect(find.text('No recorded data for this period.'), findsOneWidget);
    expect(find.byKey(const Key('progress-hero')), findsNothing);
    await tester.ensureVisible(find.text('Log weight'));
    expect(find.text('Log weight'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'grouped body chart hero uses latest actual reading and its date',
    (tester) async {
      await _show(tester);
      expect(_hero(tester), '80.5');
      expect(find.text('Recorded 17 Sep 2026'), findsOneWidget);
      await _tap(tester, find.text('3M'));
      expect(_chart(tester).timeFormat, ChartTimeFormat.threeMonths);
      expect(_hero(tester), '80.5');
      expect(find.text('Recorded 17 Sep 2026'), findsOneWidget);
      final last = _chart(
        tester,
      ).data.lastWhere((point) => point.value != null);
      expect(last.value, 81.75);
    },
  );

  testWidgets(
    'weight unit toggle converts hero and chart without changing profile',
    (tester) async {
      final container = await _show(tester);
      await _tap(tester, find.text('KG'));
      expect(_hero(tester), '177.5');
      expect(find.text('latest lb'), findsOneWidget);
      expect(_chart(tester).useKg, isFalse);
      expect(
        _chart(tester).data.lastWhere((point) => point.value != null).value,
        closeTo(177.47191, .00001),
      );
      expect(container.read(profileProvider).useKg, isTrue);
    },
  );

  testWidgets('metric selector remembers the chosen range for each metric', (
    tester,
  ) async {
    await _show(tester);
    await _tap(tester, find.text('3M'));
    final scroll = tester
        .widget<SingleChildScrollView>(find.byKey(const Key('progress-scroll')))
        .controller!;
    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(scroll.offset, greaterThan(0));
    await _metric(tester, 'Steps');
    expect(scroll.offset, 0);
    expect(
      find.byKey(const Key('progress-hero')).hitTestable(),
      findsOneWidget,
    );
    expect(_chart(tester).timeFormat, ChartTimeFormat.weekly);
    await _tap(tester, find.text('6M'));
    await _metric(tester, 'Weight');
    expect(_chart(tester).timeFormat, ChartTimeFormat.threeMonths);
    await _metric(tester, 'Steps');
    expect(_chart(tester).timeFormat, ChartTimeFormat.sixMonths);
  });

  testWidgets('tapping a daily value previews it until View day is pressed', (
    tester,
  ) async {
    final container = await _show(tester, metric: MetricType.steps);
    final chart = _chart(tester);
    final point = chart.data.firstWhere(
      (point) => point.date == DateTime(2026, 9, 14),
    );
    chart.onPointTap!(point);
    await tester.pumpAndSettle();
    expect(find.byType(ProgressScreen), findsOneWidget);
    expect(container.read(selectedDateProvider), DateTime(2026, 8, 1));
    expect(
      tester
          .widget<Text>(find.byKey(const Key('progress-selected-value')))
          .data,
      '0 steps',
    );
    await _tap(tester, find.text('View day'));
    expect(container.read(selectedDateProvider), DateTime(2026, 9, 14));
    expect(find.text('Home day'), findsOneWidget);
  });

  testWidgets('grouped selection opens daily details only on explicit action', (
    tester,
  ) async {
    await _show(tester);
    await _tap(tester, find.text('KG'));
    await _tap(tester, find.text('3M'));
    final chart = _chart(tester);
    chart.onPointTap!(chart.data.lastWhere((point) => point.value != null));
    await tester.pumpAndSettle();
    expect(find.byType(ChartDrilldownSheet), findsNothing);
    await _tap(tester, find.text('View daily details'));
    expect(find.byType(ChartDrilldownSheet), findsOneWidget);
    expect(
      tester
          .widget<ChartDrilldownSheet>(find.byType(ChartDrilldownSheet))
          .useKg,
      isFalse,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('daily-detail-readout')),
        matching: find.text('177.5 lb'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'missing height explains BMI and opens profile instead of guessing',
    (tester) async {
      await _show(tester, metric: MetricType.bmi, height: null);
      expect(find.byKey(const Key('progress-hero')), findsNothing);
      expect(
        find.text('Add your height in Profile to calculate BMI.'),
        findsOneWidget,
      );
      await _tap(tester, find.text('Open Profile'));
      expect(find.text('Profile details'), findsOneWidget);
    },
  );

  testWidgets(
    'large sleep title with back navigation keeps words and actions readable',
    (tester) async {
      final font = FontLoader('Cabinet Grotesk');
      font.addFont(rootBundle.load('assets/fonts/CabinetGrotesk-Bold.ttf'));
      await font.load();
      await _show(
        tester,
        metric: MetricType.sleep,
        size: const Size(320, 640),
        textScale: 2,
        canPop: true,
      );
      final title = find.descendant(
        of: find.byKey(const Key('progress-metric-picker')),
        matching: find.text('Sleep duration'),
      );
      final paragraph = tester.renderObject<RenderParagraph>(title);
      final durationBoxes = paragraph.getBoxesForSelection(
        const TextSelection(baseOffset: 6, extentOffset: 14),
      );
      expect(durationBoxes, hasLength(1));
      expect(
        durationBoxes.single.right,
        lessThanOrEqualTo(paragraph.size.width),
      );
      expect(title.hitTestable(), findsOneWidget);
      expect(find.byTooltip('Back').hitTestable(), findsOneWidget);
      expect(find.byTooltip('Yearly activity').hitTestable(), findsOneWidget);
      expect(
        find.byTooltip('Log sleep duration today').hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('populated 320px chart stays usable with double text size', (
    tester,
  ) async {
    await _show(
      tester,
      metric: MetricType.steps,
      size: const Size(320, 640),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byType(SharedChartCard));
    await tester.pumpAndSettle();
    final chart = _chart(tester);
    chart.onPointTap!(chart.data.first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('View day'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _tap(tester, find.text('Daily records'));
    await tester.ensureVisible(
      find.byKey(
        ValueKey('progress-record-${DateTime(2026, 9, 14).toIso8601String()}'),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _metric(tester, 'Calories logged');
    expect(find.byKey(const Key('progress-metric-picker')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final metric in [MetricType.steps, MetricType.sleep]) {
    testWidgets('${metric.name} goal survives Home date changes', (
      tester,
    ) async {
      final target = metric == MetricType.steps ? 8000.0 : 8.0;
      final container = await _show(
        tester,
        metric: metric,
        goals: [
          Habit(
            id: 'target',
            name: 'Target',
            icon: 'check',
            target: target,
            type: metric == MetricType.steps
                ? HabitType.autoSteps
                : HabitType.autoSleep,
            activeDays: [1, 2, 3, 4, 5],
            initialCreatedAt: DateTime(2020),
          ),
        ],
      );
      expect(_chart(tester).targetValue, target);
      container.read(selectedDateProvider.notifier).state = DateTime(
        2026,
        9,
        13,
      );
      await tester.pumpAndSettle();
      expect(_chart(tester).targetValue, target);
    });
  }
  testWidgets(
    'varying scheduled goals are explained instead of arbitrarily chosen',
    (tester) async {
      await _show(
        tester,
        metric: MetricType.steps,
        goals: [
          for (final entry in [
            ('weekdays', 8000.0, [1, 2, 3, 4, 5]),
            ('weekend', 6000.0, [6, 7]),
          ])
            Habit(
              id: entry.$1,
              name: entry.$1,
              icon: 'check',
              target: entry.$2,
              activeDays: entry.$3,
              type: HabitType.autoSteps,
              initialCreatedAt: DateTime(2020),
            ),
        ],
      );
      expect(_chart(tester).targetValue, isNull);
      expect(
        find.textContaining('targets vary by habit or day'),
        findsOneWidget,
      );
    },
  );
  for (final metric in [MetricType.calories, MetricType.protein]) {
    testWidgets('empty ${metric.name} opens current-day meal logging', (
      tester,
    ) async {
      final container = await _show(tester, metric: metric);
      container.read(weekOffsetProvider.notifier).state = -7;
      await _tap(tester, find.text('Log a meal'));
      expect(find.text('Meal logging'), findsOneWidget);
      expect(container.read(selectedDateProvider), DateTime(2026, 9, 19));
      expect(container.read(weekOffsetProvider), 0);
    });
  }

  testWidgets(
    'incomplete food coverage remains visible when protein chart is empty',
    (tester) async {
      await _show(
        tester,
        metric: MetricType.protein,
        meals: [
          DailyMealLog(
            date: '2026-09-19',
            customSlots: {
              'lunch': MealSlotLog(
                totalCalories: 400,
                totalProtein: 30,
                confidence: 'planned',
              ),
            },
          ),
        ],
      );
      expect(find.byKey(const Key('progress-hero')), findsNothing);
      expect(
        find.textContaining('excluded: macros incomplete'),
        findsOneWidget,
      );
      expect(find.text('Log a meal'), findsOneWidget);
    },
  );
}
