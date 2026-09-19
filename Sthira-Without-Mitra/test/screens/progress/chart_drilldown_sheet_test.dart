import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/screens/progress/progress_screen.dart';
import 'package:trufit_bodamma/screens/progress/widgets/chart_drilldown_sheet.dart';
import 'package:trufit_bodamma/screens/progress/widgets/shared_chart_card.dart';
import 'package:trufit_bodamma/services/progress_aggregation_service.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';
import 'package:trufit_bodamma/widgets/app_bottom_sheet.dart';

class _Profile extends ProfileNotifier {
  _Profile(this.useKg, this.height);
  final bool useKg;
  final double? height;
  @override
  UserProfile build() => UserProfile(useKg: useKg, height: height);
}

Future<ProviderContainer> _open(
  WidgetTester tester, {
  MetricType metric = MetricType.steps,
  List<DailyLog> logs = const [],
  List<DailyMealLog> meals = const [],
  DateTime? start,
  DateTime? end,
  DateTime? today,
  bool? useKg,
  bool profileUsesKg = true,
  double? profileHeight = 180,
  double textScale = 1,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      profileProvider.overrideWith(
        () => _Profile(profileUsesKg, profileHeight),
      ),
      dailyLogsRangeProvider.overrideWith((ref, _) => logs),
      dailyMealLogsRangeProvider.overrideWith((ref, _) => meals),
      clockProvider.overrideWithValue(today ?? DateTime(2026, 9, 19)),
      selectedDateProvider.overrideWith((ref) => DateTime(2026, 8, 1)),
    ],
  );
  addTearDown(container.dispose);
  final bucket = ChartBucket(
    startDate: start ?? DateTime(2026, 9, 1),
    endDate: end ?? DateTime(2026, 9, 7),
    validDaysCount: logs.length,
    eligibleDaysCount: 7,
  );
  final router = GoRouter(
    initialLocation: '/progress',
    routes: [
      GoRoute(
        path: '/progress',
        builder: (context, _) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showAppBottomSheet<void>(
                context: context,
                builder: (_) => ChartDrilldownSheet(
                  bucket: bucket,
                  metric: metric,
                  useKg: useKg,
                ),
              ),
              child: const Text('Open details'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('Home day')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.dark,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open details'));
  await tester.pumpAndSettle();
  return container;
}

Finder _readout(String text) => find.descendant(
  of: find.byKey(const Key('daily-detail-readout')),
  matching: find.text(text),
);

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('month drilldown uses daily bars and one-month day labels', (
    tester,
  ) async {
    await _open(
      tester,
      end: DateTime(2026, 9, 30),
      logs: [DailyLog(date: '2026-09-03', steps: 8500)],
    );
    final chart = tester.widget<SharedChartCard>(find.byType(SharedChartCard));
    expect(chart.timeFormat, ChartTimeFormat.oneMonth);
    expect(chart.data, hasLength(30));
    expect(chart.data[2].date, DateTime(2026, 9, 3));
    expect(chart.data[2].value, 8500);
    expect(find.byType(BarChart), findsOneWidget);
    expect(_readout('8,500 steps'), findsOneWidget);
    expect(_readout('Thu, 3 Sep 2026'), findsOneWidget);
  });

  testWidgets(
    'local pounds choice is inherited without changing profile units',
    (tester) async {
      final container = await _open(
        tester,
        metric: MetricType.weight,
        useKg: false,
        logs: [DailyLog(date: '2026-09-03', weight: 80)],
      );
      expect(_readout('176.4 lb'), findsOneWidget);
      expect(container.read(profileProvider).useKg, isTrue);
      expect(
        tester.widget<SharedChartCard>(find.byType(SharedChartCard)).useKg,
        isFalse,
      );
    },
  );

  testWidgets('omitting local units uses the profile preference', (
    tester,
  ) async {
    await _open(
      tester,
      metric: MetricType.weight,
      profileUsesKg: false,
      logs: [DailyLog(date: '2026-09-03', weight: 80)],
    );
    expect(_readout('176.4 lb'), findsOneWidget);
  });

  testWidgets(
    'chart selection changes readout, only View day changes navigation',
    (tester) async {
      final container = await _open(
        tester,
        logs: [
          DailyLog(date: '2026-09-01', steps: 4200),
          DailyLog(date: '2026-09-03', steps: 8500),
        ],
      );
      final chart = tester.widget<SharedChartCard>(
        find.byType(SharedChartCard),
      );
      chart.onPointTap!(chart.data.first);
      await tester.pumpAndSettle();
      expect(_readout('4,200 steps'), findsOneWidget);
      expect(_readout('Tue, 1 Sep 2026'), findsOneWidget);
      expect(container.read(selectedDateProvider), DateTime(2026, 8, 1));
      expect(find.text('Home day'), findsNothing);
      await _tapVisible(tester, find.text('View day'));
      expect(container.read(selectedDateProvider), DateTime(2026, 9, 1));
      expect(find.text('Home day'), findsOneWidget);
      expect(find.byType(ChartDrilldownSheet), findsNothing);
    },
  );

  testWidgets(
    'daily records distinguish zero, missing, and future days accessibly',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final container = await _open(
        tester,
        end: DateTime(2026, 9, 3),
        today: DateTime(2026, 9, 2),
        logs: [
          DailyLog(date: '2026-09-01', steps: 0),
          DailyLog(date: '2026-09-03', steps: 9999),
        ],
      );
      expect(_readout('0 steps'), findsOneWidget);
      await _tapVisible(tester, find.text('Daily records'));
      final zero = find.byKey(const ValueKey('daily-record-2026-09-01'));
      expect(tester.getSemantics(zero).label, contains('0 steps'));
      await _tapVisible(
        tester,
        find.byKey(const ValueKey('daily-record-2026-09-02')),
      );
      expect(_readout('No entry'), findsOneWidget);
      expect(container.read(selectedDateProvider), DateTime(2026, 8, 1));
      await _tapVisible(
        tester,
        find.byKey(const ValueKey('daily-record-2026-09-03')),
      );
      expect(_readout('Upcoming'), findsOneWidget);
      final viewDay = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'View day'),
      );
      expect(viewDay.onPressed, isNull);
      expect(find.text('9,999 steps'), findsNothing);
      semantics.dispose();
    },
  );

  for (final metric in [MetricType.sleep, MetricType.screenTime]) {
    testWidgets('${metric.name} readout uses hours and minutes', (
      tester,
    ) async {
      await _open(
        tester,
        metric: metric,
        logs: [
          DailyLog(date: '2026-09-03', sleepHours: 7.5, screenTimeMinutes: 61),
        ],
      );
      expect(
        _readout(metric == MetricType.sleep ? '7h 30m' : '1h 1m'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<SharedChartCard>(find.byType(SharedChartCard))
            .metric
            .isDuration,
        isTrue,
      );
    });
  }

  for (final entry in [
    (MetricType.calories, 'Calories logged'),
    (MetricType.protein, 'Protein logged'),
  ]) {
    testWidgets('${entry.$2} empty state offers a day to add entries', (
      tester,
    ) async {
      final container = await _open(tester, metric: entry.$1);
      expect(find.text(entry.$2), findsOneWidget);
      expect(
        find.text(
          'No entries in this period. Choose a day below, then use View day to add an entry.',
        ),
        findsOneWidget,
      );
      expect(find.byType(SharedChartCard), findsNothing);
      await _tapVisible(tester, find.text('View day'));
      expect(container.read(selectedDateProvider), DateTime(2026, 9, 7));
      expect(find.text('Home day'), findsOneWidget);
    });
  }

  testWidgets(
    'large text keeps chart, day action, and daily records reachable',
    (tester) async {
      await _open(
        tester,
        metric: MetricType.sleep,
        textScale: 2,
        size: const Size(320, 640),
        end: DateTime(2026, 9, 30),
        logs: [DailyLog(date: '2026-09-03', sleepHours: 7.5)],
      );
      expect(tester.takeException(), isNull);
      await _tapVisible(tester, find.text('Daily records'));
      final record = find.byKey(const ValueKey('daily-record-2026-09-03'));
      await tester.ensureVisible(record);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: record, matching: find.text('7h 30m')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('View day'));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.widgetWithText(ElevatedButton, 'View day')).height,
        greaterThanOrEqualTo(48),
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('BMI needs a recorded height instead of assuming one', (
    tester,
  ) async {
    await _open(
      tester,
      metric: MetricType.bmi,
      profileHeight: null,
      logs: [DailyLog(date: '2026-09-03', weight: 80)],
    );
    expect(find.byType(SharedChartCard), findsNothing);
    expect(
      find.text(
        'Add your height in your profile to calculate BMI from your recorded weight.',
      ),
      findsOneWidget,
    );
  });

  for (final metric in [MetricType.protein, MetricType.calories]) {
    testWidgets(
      '${metric.name} distinguishes saved incomplete nutrition from zero',
      (tester) async {
        final container = await _open(
          tester,
          metric: metric,
          meals: [
            DailyMealLog(
              date: '2026-09-07',
              customSlots: {
                'lunch': MealSlotLog(
                  totalCalories: 400,
                  totalProtein: 30,
                  confidence: 'planned',
                  caloriesComplete: metric == MetricType.calories
                      ? false
                      : true,
                ),
              },
            ),
          ],
        );
        expect(_readout('Nutrition incomplete'), findsOneWidget);
        expect(_readout('0 g'), findsNothing);
        expect(_readout('No entry'), findsNothing);
        expect(
          find.text('1 day with incomplete nutrition excluded.'),
          findsOneWidget,
        );
        expect(find.byType(SharedChartCard), findsNothing);
        await _tapVisible(tester, find.text('View day'));
        expect(container.read(selectedDateProvider), DateTime(2026, 9, 7));
        expect(find.text('Home day'), findsOneWidget);
      },
    );
  }
}
