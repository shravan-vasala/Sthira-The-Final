import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/screens/progress/widgets/shared_chart_card.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';

final _start = DateTime(2026, 9, 1);
List<ChartDataPoint> _points(List<double?> values) => [
  for (var i = 0; i < values.length; i++)
    ChartDataPoint(_start.add(Duration(days: i)), values[i]),
];

Widget _app(
  Widget child, {
  double scale = 1,
  bool dark = false,
  bool reduceMotion = false,
}) => MaterialApp(
  theme: dark ? AppTheme.dark : AppTheme.light,
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
        disableAnimations: reduceMotion,
      ),
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    ),
  ),
);

SharedChartCard _card(
  List<ChartDataPoint> points, {
  ChartPlotType type = ChartPlotType.line,
  List<ChartDataPoint>? trend,
  DateTime? selectedDate,
  void Function(ChartDataPoint)? onSelect,
  ChartTimeFormat timeFormat = ChartTimeFormat.weekly,
  double? target,
  List<String> labels = const [],
  List<String> values = const [],
}) => SharedChartCard(
  metric: MetricSpec(title: 'Weight', unit: 'kg', plotType: type),
  data: points,
  trendData: trend,
  startDate: _start,
  endDate: points.last.date,
  selectedDate: selectedDate,
  onPointTap: onSelect,
  timeFormat: timeFormat,
  statLabels: labels,
  statValues: values,
  targetValue: target,
);

Offset _barPoint(WidgetTester tester, int index, int count) {
  final area = tester.getRect(
    find.byKey(const ValueKey('chart-inspection-surface')),
  );
  final chart = tester.widget<BarChart>(find.byType(BarChart));
  final left = chart.data.titlesData.leftTitles.sideTitles.reservedSize;
  return Offset(
    area.left + left + (index + 0.5) / count * (area.width - left),
    area.center.dy,
  );
}

void main() {
  for (final range in [
    ChartTimeFormat.weekly,
    ChartTimeFormat.oneMonth,
    ChartTimeFormat.threeMonths,
    ChartTimeFormat.sixMonths,
    ChartTimeFormat.twelveMonths,
  ]) {
    testWidgets(
      'Activity charts preserve short-range bars and long-range lines: $range',
      (tester) async {
        await tester.pumpWidget(
          _app(
            _card(
              _points([4000, 0, null, 7000]),
              type: ChartPlotType.bar,
              timeFormat: range,
            ),
          ),
        );
        final daily =
            range == ChartTimeFormat.weekly ||
            range == ChartTimeFormat.oneMonth;
        expect(find.byType(BarChart), daily ? findsOneWidget : findsNothing);
        expect(find.byType(LineChart), daily ? findsNothing : findsOneWidget);
        if (daily) {
          expect(
            find.byKey(const ValueKey('chart-recorded-zero-1')),
            findsOneWidget,
          );
        } else {
          final chart = tester.widget<LineChart>(find.byType(LineChart));
          expect(chart.data.lineBarsData, hasLength(2));
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final range in [ChartTimeFormat.weekly, ChartTimeFormat.oneMonth]) {
    testWidgets(
      'Body measurements retain their existing short-range lines: $range',
      (tester) async {
        await tester.pumpWidget(
          _app(_card(_points([80, 79.8, 80.1]), timeFormat: range)),
        );
        expect(find.byType(LineChart), findsOneWidget);
        expect(find.byType(BarChart), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('All missing readings show the empty state, not a zero graph', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_card(_points([null, null, double.nan]))));
    expect(find.text('No data available for this period'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
    expect(find.byType(BarChart), findsNothing);
  });

  testWidgets('Zero is visible and selectable; an absent day stays absent', (
    tester,
  ) async {
    ChartDataPoint? selected;
    final points = _points([0, null, 5]);
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => _card(
            points,
            type: ChartPlotType.bar,
            selectedDate: selected?.date,
            onSelect: (point) => setState(() => selected = point),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('chart-recorded-zero-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('chart-recorded-zero-1')), findsNothing);
    await tester.tapAt(_barPoint(tester, 0, 3));
    await tester.pump();
    expect(selected?.value, 0);
    expect(find.byKey(const ValueKey('chart-selection-line')), findsOneWidget);
    await tester.tapAt(_barPoint(tester, 1, 3));
    await tester.pump();
    expect(selected?.date, points[1].date);
    expect(selected?.value, isNull);
  });

  testWidgets('Horizontal scrubbing inspects dates without navigating', (
    tester,
  ) async {
    final selected = <ChartDataPoint>[];
    final points = _points([1, 2, 3, 4, 5, 6, 7]);
    await tester.pumpWidget(
      _app(_card(points, type: ChartPlotType.bar, onSelect: selected.add)),
    );
    final first = _barPoint(tester, 0, 7);
    final last = _barPoint(tester, 6, 7);
    await tester.dragFrom(first, last - first);
    await tester.pump();
    expect(selected.length, greaterThan(1));
    expect(selected.last.date, points.last.date);
    expect(find.byType(SharedChartCard), findsOneWidget);
  });

  testWidgets('Measured and trend series preserve missing-day gaps', (
    tester,
  ) async {
    final points = _points([70, 71, null, 72, 73]);
    await tester.pumpWidget(
      _app(
        _card(points, trend: _points([70, 70.5, null, 72, 72.5]), target: 65),
      ),
    );
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final series = chart.data.lineBarsData;
    expect(series, hasLength(4));
    expect(series.every((line) => line.spots.length == 2), isTrue);
    expect(series.every((line) => !line.belowBarData.show), isTrue);
    expect(chart.data.extraLinesData.horizontalLines, hasLength(1));
    expect(chart.data.extraLinesData.horizontalLines.single.strokeWidth, 1);
    expect(find.text('Current goal 65.0 kg'), findsOneWidget);
    expect(find.text('7-day average'), findsOneWidget);
    expect(find.textContaining('Min '), findsNothing);
  });

  testWidgets(
    'Sparse calendar data does not imply a line through missing days',
    (tester) async {
      await tester.pumpWidget(
        _app(
          _card([
            ChartDataPoint(_start, 70),
            ChartDataPoint(_start.add(const Duration(days: 8)), 68),
          ]),
        ),
      );
      final chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.data.lineBarsData, hasLength(2));
      expect(
        chart.data.lineBarsData.every((line) => line.spots.length == 1),
        isTrue,
      );
    },
  );

  testWidgets('A single observation has a usable domain and point', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_card(_points([70]))));
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.maxX, greaterThan(chart.data.minX));
    expect(chart.data.maxY, greaterThan(chart.data.minY));
    expect(chart.data.lineBarsData.single.dotData.show, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Monthly duration uses daily bars and hours/minutes', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SharedChartCard(
          metric: const MetricSpec(
            title: 'Sleep duration',
            unit: 'h',
            isDuration: true,
            plotType: ChartPlotType.bar,
          ),
          data: _points([7.5, 8, 6]),
          startDate: _start,
          endDate: _start.add(const Duration(days: 2)),
          timeFormat: ChartTimeFormat.monthly,
          statLabels: const [],
          statValues: const [],
          targetValue: 7.5,
        ),
      ),
    );
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.text('Current goal 7h 30m'), findsOneWidget);
  });

  testWidgets('KG/LB toggle has a 48px target and calls its action', (
    tester,
  ) async {
    var toggles = 0;
    await tester.pumpWidget(
      _app(
        SharedChartCard(
          metric: const MetricSpec(
            title: 'Weight',
            unit: 'kg',
            showKgLbToggle: true,
          ),
          data: _points([70]),
          startDate: _start,
          endDate: _start,
          statLabels: const [],
          statValues: const [],
          onToggleUnit: () => toggles++,
        ),
      ),
    );
    final button = find.widgetWithText(TextButton, 'KG');
    expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
    await tester.tap(button);
    expect(toggles, 1);
  });

  for (final dark in [false, true]) {
    testWidgets(
      'Large text fits a 320px screen with distinct dates (dark=$dark)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          _app(
            _card(
              _points(List.generate(30, (i) => 7500 + i * 200.0)),
              timeFormat: ChartTimeFormat.monthly,
              type: ChartPlotType.bar,
              target: 10000,
              labels: [
                'DAILY AVERAGE',
                'RECORDED DAYS',
                'CHANGE FROM PREVIOUS',
              ],
              values: ['10,450 steps', '30 of 30 days', '+2,100 steps'],
            ),
            scale: 2,
            dark: dark,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final labels = find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>).value.startsWith('chart-date-'),
        );
        expect(labels.evaluate().length, inInclusiveRange(1, 2));
        final rects = [
          for (final element in labels.evaluate())
            tester.getRect(find.byWidget(element.widget)),
        ]..sort((a, b) => a.left.compareTo(b.left));
        for (var i = 1; i < rects.length; i++) {
          expect(rects[i - 1].right, lessThanOrEqualTo(rects[i].left));
        }
        expect(
          tester.getSize(find.byType(BarChart)).height,
          greaterThanOrEqualTo(260),
        );
      },
    );
  }

  testWidgets('Inline inspection is immediate and never moves the plot', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ChartDataPoint? selected;
    final points = _points([0, null, 12345.6]);
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => _card(
            points,
            type: ChartPlotType.bar,
            selectedDate: selected?.date,
            onSelect: (point) => setState(() => selected = point),
          ),
        ),
        scale: 2,
      ),
    );
    expect(find.text('Tap or drag to inspect'), findsOneWidget);
    final before = tester.getRect(find.byType(BarChart));
    await tester.tapAt(_barPoint(tester, 2, 3));
    await tester.pump();
    expect(find.textContaining('12345.6 kg'), findsOneWidget);
    expect(tester.getRect(find.byType(BarChart)), before);
    await tester.tapAt(_barPoint(tester, 1, 3));
    await tester.pump();
    expect(find.textContaining('No entry'), findsOneWidget);
    expect(tester.getRect(find.byType(BarChart)), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Narrow measurement ranges use distinguishable axis precision', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_card(_points([70, 70.1]))));
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(
      chart.data.titlesData.leftTitles.sideTitles.interval,
      greaterThanOrEqualTo(0.1),
    );
  });

  testWidgets('Reduced motion disables chart interpolation', (tester) async {
    await tester.pumpWidget(_app(_card(_points([70, 69])), reduceMotion: true));
    expect(
      tester.widget<LineChart>(find.byType(LineChart)).duration,
      Duration.zero,
    );
  });
  testWidgets(
    'distant weight goal is annotated without flattening measured changes',
    (tester) async {
      await tester.pumpWidget(
        _app(
          SharedChartCard(
            metric: const MetricSpec(
              title: 'Weight',
              unit: 'kg',
              showKgLbToggle: true,
            ),
            data: _points([80, 80.2, 80.4]),
            startDate: _start,
            endDate: DateTime(2026, 9, 3),
            statLabels: const [],
            statValues: const [],
            targetValue: 60,
          ),
        ),
      );
      final chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.data.minY, greaterThan(75));
      expect(chart.data.extraLinesData.horizontalLines, isEmpty);
      expect(find.text('Current goal 60.0 kg · below chart'), findsOneWidget);
    },
  );
  testWidgets('nearby weight goal keeps its reference line', (tester) async {
    await tester.pumpWidget(
      _app(
        SharedChartCard(
          metric: const MetricSpec(
            title: 'Weight',
            unit: 'kg',
            showKgLbToggle: true,
          ),
          data: _points([80, 80.2, 80.4]),
          startDate: _start,
          endDate: DateTime(2026, 9, 3),
          statLabels: const [],
          statValues: const [],
          targetValue: 79,
        ),
      ),
    );
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.extraLinesData.horizontalLines.single.y, 79);
    expect(find.text('Current goal 79.0 kg'), findsOneWidget);
  });
}
