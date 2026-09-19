import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/providers/weekly_summary_provider.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/screens/home/widgets/daily_score_sheet.dart';
import 'package:trufit_bodamma/screens/progress/weekly_summary_screen.dart';
import 'package:trufit_bodamma/screens/progress/widgets/shared_chart_card.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';

class _Profile extends ProfileNotifier {
  @override
  UserProfile build() => UserProfile(name: 'Alex');
}

Widget _app(Widget child, {double scale = 1}) => MaterialApp(
  theme: AppTheme.dark,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
    child: child!,
  ),
  home: child,
);
DailyScore _score({bool rest = false}) => DailyScore(
  totalScore: 100,
  isFutureDate: false,
  habitsScore: 50,
  habitsMax: 50,
  workoutsScore: 0,
  workoutsMax: 0,
  mealsScore: 0,
  mealsMax: 0,
  totalMax: 50,
  isRestDay: rest,
  date: DateTime(2026, 9, 14),
);
WeeklySummary _week({bool partial = true, int value = 80}) => WeeklySummary(
  workoutsCompleted: 1,
  workoutsTotal: 2,
  habitCompletionRate: .75,
  avgSteps: 10500,
  bestSteps: 18000,
  avgSleep: 7.5,
  nightsUnder7h: 1,
  avgCalories: 2100,
  targetCalories: 2200,
  daysOverCalories: 1,
  daysUnderCalories: 4,
  weightDelta: -.7,
  dailyHabitRates: [.5, .75, 1, .75, .75, 0, 0],
  dailyHabitsCompleted: [2, 3, 4, 3, 3, 0, 0],
  dailyHabitsRecorded: [4, 4, 4, 4, 4, 0, 0],
  dailyHabitsTotal: [4, 4, 4, 4, 4, 0, 0],
  dailyScores: partial
      ? [value, value, value, value, value, null, null]
      : List.filled(7, value),
  weekScore: value,
  elapsedDays: partial ? 5 : 7,
  scoreDays: partial ? 5 : 7,
  stepsDays: 5,
  sleepNights: 5,
  foodDays: 5,
  weightMeasurements: 2,
  isPartialWeek: partial,
);
WeeklySummary _habitWeek({bool scheduled = true, bool recorded = false}) =>
    WeeklySummary(
      workoutsCompleted: 0,
      workoutsTotal: 0,
      habitCompletionRate: 0,
      avgSteps: 0,
      bestSteps: 0,
      avgSleep: 0,
      nightsUnder7h: 0,
      avgCalories: 0,
      targetCalories: 2000,
      daysOverCalories: 0,
      daysUnderCalories: 0,
      weightDelta: 0,
      dailyHabitRates: List.filled(7, 0),
      dailyHabitsTotal: scheduled ? [2, 2, 0, 0, 0, 0, 0] : List.filled(7, 0),
      dailyHabitsCompleted: List.filled(7, 0),
      dailyHabitsRecorded: recorded ? [1, 0, 0, 0, 0, 0, 0] : List.filled(7, 0),
      dailyScores: recorded
          ? [0, null, null, null, null, null, null]
          : List.filled(7, null),
      weekScore: 0,
      elapsedDays: 2,
      scoreDays: recorded ? 1 : 0,
      isPartialWeek: true,
    );
Future<ProviderContainer> _showWeek(
  WidgetTester tester,
  WeeklySummary summary,
) async {
  final container = ProviderContainer(
    overrides: [
      weeklySummaryProvider.overrideWithValue(summary),
      profileProvider.overrideWith(_Profile.new),
      selectedDateProvider.overrideWith((ref) => DateTime(2026, 9, 14)),
      clockProvider.overrideWithValue(DateTime(2026, 9, 15)),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: _app(const WeeklySummaryScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('Daily hero always presents a normalized denominator', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dailyScoreProvider.overrideWithValue(_score())],
        child: _app(const Scaffold(body: DailyScoreSheet())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('of 100'), findsOneWidget);
    expect(find.text('of 50'), findsNothing);
    expect(find.textContaining('Perfect day'), findsOneWidget);
  });
  testWidgets('Completed training is not described as a rest day', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dailyScoreProvider.overrideWithValue(
            DailyScore(
              totalScore: 100,
              isFutureDate: false,
              habitsScore: 0,
              habitsMax: 0,
              workoutsScore: 30,
              workoutsMax: 30,
              mealsScore: 0,
              mealsMax: 0,
              totalMax: 30,
              workoutConfigured: true,
              isRestDay: false,
            ),
          ),
        ],
        child: _app(const Scaffold(body: DailyScoreSheet())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Rest day'), findsNothing);
    expect(find.text('30 / 30'), findsOneWidget);
  });
  testWidgets('Daily breakdown wraps at 320px and 200% text', (tester) async {
    tester.view.physicalSize = const Size(320, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dailyScoreProvider.overrideWithValue(_score())],
        child: _app(const Scaffold(body: DailyScoreSheet()), scale: 2),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('An unfinished 80-point week is not a perfect week', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weeklySummaryProvider.overrideWithValue(_week()),
          profileProvider.overrideWith(_Profile.new),
          selectedDateProvider.overrideWith((ref) => DateTime(2026, 9, 14)),
          clockProvider.overrideWithValue(DateTime(2026, 9, 18)),
        ],
        child: _app(const WeeklySummaryScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('PERFECT WEEK'), findsNothing);
    expect(find.text('Week Score so far'), findsOneWidget);
    expect(find.text('5 of 5 elapsed days scored'), findsOneWidget);
    final scoreChart = tester.widget<BarChart>(find.byType(BarChart).first);
    expect(scoreChart.data.minY, 0);
    expect(scoreChart.data.maxY, 100);
  });
  testWidgets('Weekly stats and inspection fit 320px and 200% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weeklySummaryProvider.overrideWithValue(_week(partial: false)),
          profileProvider.overrideWith(_Profile.new),
          selectedDateProvider.overrideWith((ref) => DateTime(2026, 9, 14)),
          clockProvider.overrideWithValue(DateTime(2026, 9, 28)),
        ],
        child: _app(const WeeklySummaryScreen(), scale: 2),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Calories logged'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'no scheduled habits and scheduled but unrecorded habits stay neutral',
    (tester) async {
      await _showWeek(tester, _habitWeek(scheduled: false));
      expect(find.text('No habits scheduled'), findsOneWidget);
      expect(find.byKey(const ValueKey('weekly-habit-chart')), findsNothing);
      await _showWeek(tester, _habitWeek());
      expect(find.text('No habit entries recorded'), findsOneWidget);
      expect(find.text('No habit entries recorded this week.'), findsOneWidget);
      expect(find.textContaining('below'), findsNothing);
    },
  );
  testWidgets(
    'recorded zero habit bar is inspectable without changing the Home day',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final container = await _showWeek(tester, _habitWeek(recorded: true));
        final chart = tester.widget<SharedChartCard>(
          find.byKey(const ValueKey('weekly-habit-chart')),
        );
        expect(chart.data.first.value, 0);
        expect(chart.data[1].value, isNull);
        chart.onPointTap!(chart.data.first);
        await tester.pumpAndSettle();
        expect(
          find.text('Monday, 14 Sep · 0 of 2 completed · 1 recorded'),
          findsOneWidget,
        );
        expect(container.read(selectedDateProvider), DateTime(2026, 9, 14));
        final records = find.byKey(const ValueKey('weekly-habit-records'));
        await tester.ensureVisible(records);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Daily habit records'));
        await tester.pumpAndSettle();
        final day = find.byKey(const ValueKey('weekly-habit-day-1'));
        await tester.ensureVisible(day);
        await tester.pumpAndSettle();
        expect(
          tester.getSemantics(day).label,
          contains('No entries recorded · 2 scheduled'),
        );
        await tester.tap(day);
        await tester.pumpAndSettle();
        expect(
          find.text('Tuesday, 15 Sep · No entries recorded · 2 scheduled'),
          findsOneWidget,
        );
        expect(container.read(selectedDateProvider), DateTime(2026, 9, 14));
      } finally {
        semantics.dispose();
      }
    },
  );
}
