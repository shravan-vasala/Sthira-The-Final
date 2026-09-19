import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import '../../../services/haptics.dart';
import '../../../services/progress_aggregation_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/layout_insets.dart';

enum ChartTimeFormat {
  weekly,
  monthly,
  oneMonth,
  threeMonths,
  sixMonths,
  twelveMonths,
  allTime,
}

class ChartDataPoint {
  final DateTime date;
  final double? value;
  final ChartBucket? bucket;
  ChartDataPoint(this.date, this.value, {this.bucket});
}

enum ChartPlotType { bar, line }

class MetricSpec {
  final String title;
  final String unit;
  final bool isCount;

  /// Duration values use decimal hours in the model.
  final bool isDuration;
  final ChartPlotType plotType;
  final bool showKgLbToggle;

  const MetricSpec({
    required this.title,
    required this.unit,
    this.isCount = false,
    this.isDuration = false,
    this.plotType = ChartPlotType.line,
    this.showKgLbToggle = false,
  });
}

class SharedChartCard extends StatelessWidget {
  const SharedChartCard({
    super.key,
    required this.metric,
    this.subtitle,
    required this.data,
    this.trendData,
    required this.startDate,
    required this.endDate,
    this.useKg = true,
    this.onToggleUnit,
    required this.statLabels,
    required this.statValues,
    this.timeFormat = ChartTimeFormat.monthly,
    this.emptyMessage = 'No data available for this period',
    this.targetValue,
    this.minY,
    this.maxY,
    this.onPointLongPress,
    this.onPointTap,
    this.selectedDate,
    this.expandChart = false,
  });

  final MetricSpec metric;
  final String? subtitle;
  final List<ChartDataPoint> data;
  final List<ChartDataPoint>? trendData;
  final DateTime startDate;
  final DateTime endDate;
  final bool useKg;
  final VoidCallback? onToggleUnit;
  final List<String> statLabels;
  final List<String> statValues;
  final ChartTimeFormat timeFormat;
  final String emptyMessage;
  final double? targetValue;

  /// Fixed bounds for metrics with a defined scale, such as a score out of 100.
  final double? minY;
  final double? maxY;
  final void Function(ChartDataPoint point)? onPointLongPress;

  /// Inspects a date on tap or horizontal drag, including an unrecorded day.
  final void Function(ChartDataPoint point)? onPointTap;
  final DateTime? selectedDate;
  final bool expandChart;

  bool get _daily =>
      timeFormat == ChartTimeFormat.weekly ||
      timeFormat == ChartTimeFormat.monthly ||
      timeFormat == ChartTimeFormat.oneMonth;
  bool get _aggregated => !_daily && data.any((p) => p.bucket != null);
  bool get _useBars => metric.plotType == ChartPlotType.bar && _daily;
  bool _valid(double? value) => value != null && value.isFinite;
  // A distant weight goal should not flatten the observed weight changes.
  bool get _goalOutsideChart {
    if (!metric.showKgLbToggle || !_valid(targetValue)) return false;
    final values = data
        .where((point) => _valid(point.value))
        .map((point) => point.value!)
        .toList();
    if (values.isEmpty) return false;
    final low = values.reduce(min);
    final high = values.reduce(max);
    final span = max(high - low, max((high + low).abs() * .01, 1.0));
    return targetValue! < low - span * 2 || targetValue! > high + span * 2;
  }

  String get _goalPosition {
    final first = data.firstWhere((point) => _valid(point.value)).value!;
    return targetValue! < first ? 'below chart' : 'above chart';
  }

  bool get _hasTrend => trendData?.any((p) => _valid(p.value)) ?? false;
  bool get _hasData => data.any((p) => _valid(p.value)) || _hasTrend;
  int get _selectedIndex => selectedDate == null
      ? -1
      : data.indexWhere((p) => DateUtils.isSameDay(p.date, selectedDate));

  String _formatValue(double value, {bool compact = false}) {
    if (metric.isDuration) {
      final minutes = (value.abs() * 60).round();
      final hours = minutes ~/ 60;
      final rest = minutes % 60;
      final sign = value < 0 ? '-' : '';
      if (rest == 0) return '$sign${hours}h';
      if (hours == 0) return '$sign${rest}m';
      return '$sign${hours}h ${rest}m';
    }
    if (metric.isCount) {
      if (compact && value.abs() >= 1000) {
        return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}k';
      }
      return NumberFormat.decimalPattern().format(value.round());
    }
    return value.toStringAsFixed(1);
  }

  String get _unitSuffix {
    if (metric.isDuration) return '';
    if (metric.showKgLbToggle) return useKg ? ' kg' : ' lb';
    return metric.unit.isEmpty ? '' : ' ${metric.unit}';
  }

  Widget _header(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          subtitle?.isNotEmpty == true ? subtitle! : metric.title,
          style:
              (subtitle?.isNotEmpty == true
                      ? context.text.body
                      : context.text.cardTitle)
                  .copyWith(color: context.colors.textDark),
        ),
      ),
      if (metric.showKgLbToggle) ...[
        const SizedBox(width: Spacing.inline),
        TextButton(
          onPressed: onToggleUnit,
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: context.colors.accentText,
            backgroundColor: context.colors.insetSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Semantics(
            label: useKg
                ? 'Kilograms. Switch to pounds'
                : 'Pounds. Switch to kilograms',
            excludeSemantics: true,
            child: Text(useKg ? 'KG' : 'LB', style: context.text.micro),
          ),
        ),
      ],
    ],
  );

  Widget _legendItem(
    BuildContext context,
    String label, {
    bool dot = false,
    bool goal = false,
  }) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: dot ? 7 : 16,
        height: dot ? 7 : 2,
        decoration: BoxDecoration(
          color: goal ? context.colors.textMedium : context.colors.accentText,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          label,
          style: context.text.micro.copyWith(color: context.colors.textMedium),
        ),
      ),
    ],
  );

  Widget _legend(BuildContext context) => Wrap(
    spacing: 16,
    runSpacing: 8,
    children: [
      _legendItem(
        context,
        _aggregated ? 'Period average' : 'Recorded',
        dot: true,
      ),
      if (_hasTrend) _legendItem(context, '7-day average'),
      if (_valid(targetValue))
        _legendItem(
          context,
          'Current goal ${_formatValue(targetValue!)}$_unitSuffix${_goalOutsideChart ? ' · $_goalPosition' : ''}',
          goal: true,
        ),
    ],
  );

  Widget _inspectionReadout(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const hint = 'Tap or drag to inspect';
      final style = context.text.body.copyWith(fontWeight: FontWeight.w500);
      String label(ChartDataPoint point) {
        final date = DateFormat(
          _daily ? 'EEE, d MMM' : 'd MMM yyyy',
        ).format(point.date);
        final value = _valid(point.value)
            ? '${_formatValue(point.value!)}$_unitSuffix${_aggregated ? ' average' : ''}'
            : (point.bucket?.incompleteDaysCount ?? 0) > 0
            ? 'Nutrition incomplete'
            : 'No entry';
        return '$date \u00b7 $value';
      }

      var height = 0.0;
      // Keep the plot stationary under a dragging finger, including at large text sizes.
      for (final text in [hint, ...data.map(label)]) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: TextDirection.ltr,
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        height = max(height, painter.height);
      }
      final index = _selectedIndex;
      return SizedBox(
        key: const ValueKey('chart-inline-readout'),
        height: height,
        width: double.infinity,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            index < 0 ? hint : label(data[index]),
            style: style.copyWith(
              color: index < 0
                  ? context.colors.textMedium
                  : context.colors.textDark,
            ),
          ),
        ),
      );
    },
  );

  Widget _statistics(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final count = min(statLabels.length, statValues.length);
      final scale = MediaQuery.textScalerOf(context).scale(13) / 13;
      final columns = max(
        1,
        min(count, (constraints.maxWidth / (104 * scale)).floor()),
      );
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(kCardRadius),
        ),
        child: Wrap(
          runSpacing: 20,
          children: List.generate(
            count,
            (index) => SizedBox(
              width: constraints.maxWidth / columns,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    Text(
                      statLabels[index],
                      textAlign: TextAlign.center,
                      style: context.text.micro.copyWith(
                        color: context.colors.textMedium,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statValues[index],
                      textAlign: TextAlign.center,
                      style: context.text.cardTitle.copyWith(
                        color: context.colors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(13) / 13;
    Widget chartArea = _hasData
        ? LayoutBuilder(builder: _plot)
        : Center(
            child: Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: context.text.body.copyWith(
                color: context.colors.textMedium,
              ),
            ),
          );
    chartArea = expandChart
        ? Expanded(child: chartArea)
        : SizedBox(
            height: 220 + 40 * (scale - 1).clamp(0, 2),
            child: chartArea,
          );
    Widget card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context),
          if (_hasData) ...[
            const SizedBox(height: 12),
            _legend(context),
            if (onPointTap != null) ...[
              const SizedBox(height: 16),
              _inspectionReadout(context),
            ],
          ],
          const SizedBox(height: 24),
          chartArea,
        ],
      ),
    );
    if (expandChart) card = Expanded(child: card);
    return Column(
      children: [
        card,
        if (statLabels.isNotEmpty && statValues.isNotEmpty) ...[
          const SizedBox(height: Spacing.inline),
          _statistics(context),
        ],
      ],
    );
  }

  (double, double) _yRange() {
    final values = <double>[
      for (final p in [...data, ...?trendData])
        if (_valid(p.value)) p.value!,
      if (_valid(targetValue) && !_goalOutsideChart) targetValue!,
    ];
    if (values.isEmpty) return (0, 10);
    var low = values.reduce(min);
    var high = values.reduce(max);
    final padding = high == low
        ? max(high.abs() * 0.05, 1.0)
        : (high - low) * 0.15;
    low -= padding;
    high += padding;
    if (values.every((v) => v >= 0)) low = max(0, low);
    if (_useBars) low = 0;
    final lower = _valid(minY) ? minY! : low;
    final upper = _valid(maxY) ? maxY! : high;
    return upper > lower ? (lower, upper) : (low, high);
  }

  String _dateLabel(int index) {
    final date = data[index].date;
    if (timeFormat == ChartTimeFormat.weekly) {
      return DateFormat('E').format(date);
    }
    if (_daily || !_aggregated) return DateFormat('d MMM').format(date);
    if (timeFormat == ChartTimeFormat.allTime ||
        timeFormat == ChartTimeFormat.twelveMonths) {
      return DateFormat('MMM yy').format(date);
    }
    return DateFormat('d MMM').format(date);
  }

  double _measure(BuildContext context, String text) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: context.text.micro),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    return painter.width;
  }

  FlTitlesData _titles(
    BuildContext context,
    double plotWidth,
    double leftSize,
    double bottomSize,
    double low,
    double high,
  ) {
    final maxLabelWidth = data.isEmpty
        ? 40.0
        : data
              .asMap()
              .keys
              .map((i) => _measure(context, _dateLabel(i)))
              .reduce(max);
    final visibleCount = max(
      1,
      min(data.length, (plotWidth / (maxLabelWidth + 18)).floor()),
    );
    final indices = <int>{
      if (visibleCount == 1) (data.length - 1) ~/ 2,
      if (visibleCount > 1)
        for (var i = 0; i < visibleCount; i++)
          (i * (data.length - 1) / (visibleCount - 1)).round(),
    };
    final roughInterval = max((high - low) / 3, metric.isCount ? 1.0 : 0.1);
    final magnitude = pow(10, (log(roughInterval) / ln10).floor()).toDouble();
    final interval = metric.isDuration
        ? [
            1 / 60,
            5 / 60,
            0.25,
            0.5,
            1.0,
            2.0,
            4.0,
            8.0,
            12.0,
            24.0,
          ].firstWhere(
            (step) => step >= (high - low) / 3,
            orElse: () => ((high - low) / 72).ceil() * 24.0,
          )
        : [
                1.0,
                2.0,
                2.5,
                5.0,
                10.0,
              ].firstWhere((step) => step * magnitude >= roughInterval) *
              magnitude;
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          reservedSize: bottomSize,
          getTitlesWidget: (value, meta) {
            final index = value.round();
            if ((value - index).abs() > 0.001 || !indices.contains(index)) {
              return const SizedBox.shrink();
            }
            return SideTitleWidget(
              meta: meta,
              space: 12,
              fitInside: SideTitleFitInsideData(
                enabled: true,
                axisPosition: meta.axisPosition,
                parentAxisSize: meta.parentAxisSize,
                distanceFromEdge: 0,
              ),
              child: Text(
                _dateLabel(index),
                key: ValueKey('chart-date-$index'),
                style: context.text.micro.copyWith(
                  color: context.colors.textMedium,
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: leftSize,
          interval: interval,
          minIncluded: false,
          maxIncluded: false,
          getTitlesWidget: (value, meta) => SideTitleWidget(
            meta: meta,
            space: 10,
            child: Text(
              _formatValue(value, compact: true),
              style: context.text.micro.copyWith(
                color: context.colors.textMedium,
              ),
            ),
          ),
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  Widget _plot(BuildContext context, BoxConstraints constraints) {
    final (low, high) = _yRange();
    final labelHeight = MediaQuery.textScalerOf(context).scale(13) * 1.5;
    final leftSize =
        max(
          _measure(context, _formatValue(high, compact: true)),
          _measure(context, _formatValue(low, compact: true)),
        ) +
        12;
    final bottomSize = labelHeight + 20;
    final plotWidth = max(1.0, constraints.maxWidth - leftSize);
    final plotHeight = max(1.0, constraints.maxHeight - bottomSize);
    final titles = _titles(context, plotWidth, leftSize, bottomSize, low, high);
    final duration =
        MediaQuery.disableAnimationsOf(context) || selectedDate != null
        ? Duration.zero
        : const Duration(milliseconds: 180);
    final chart = _useBars
        ? _barChart(context, titles, low, high, duration)
        : _lineChart(context, titles, low, high, duration);
    final selected = _selectedIndex;
    double xPosition(int index) => _useBars
        ? (index + 0.5) / data.length * plotWidth
        : data.length <= 1
        ? plotWidth / 2
        : index / (data.length - 1) * plotWidth;
    void inspect(Offset local, {bool longPress = false, bool haptic = false}) {
      if (data.isEmpty) return;
      final fraction = ((local.dx - leftSize) / plotWidth).clamp(0.0, 1.0);
      final index =
          (_useBars
                  ? (fraction * data.length).floor()
                  : (fraction * (data.length - 1)).round())
              .clamp(0, data.length - 1);
      if (haptic) Haptics.tap();
      if (longPress) {
        onPointLongPress?.call(data[index]);
      } else {
        onPointTap?.call(data[index]);
      }
    }

    final recorded = data.where((p) => _valid(p.value)).length;
    return Semantics(
      label:
          '${metric.title} chart. $recorded recorded ${_aggregated ? 'periods' : 'days'} out of ${data.length}. '
          '${DateFormat('d MMM yyyy').format(startDate)} to ${DateFormat('d MMM yyyy').format(endDate)}.',
      child: Stack(
        children: [
          Positioned.fill(child: chart),
          if (selected >= 0)
            Positioned(
              left: leftSize + xPosition(selected) - 0.5,
              top: 0,
              height: plotHeight,
              width: 1,
              child: IgnorePointer(
                child: ColoredBox(
                  key: const ValueKey('chart-selection-line'),
                  color: context.colors.textMedium.withValues(alpha: 0.45),
                ),
              ),
            ),
          if (_useBars)
            for (var i = 0; i < data.length; i++)
              if (data[i].value == 0)
                Positioned(
                  left: leftSize + xPosition(i) - 3,
                  top: plotHeight - 4,
                  width: 6,
                  height: 6,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      key: ValueKey('chart-recorded-zero-$i'),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.colors.card,
                        border: Border.all(
                          color: context.colors.accentText,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
          if (onPointTap != null || onPointLongPress != null)
            Positioned.fill(
              child: GestureDetector(
                key: const ValueKey('chart-inspection-surface'),
                behavior: HitTestBehavior.translucent,
                excludeFromSemantics: true,
                onTapUp: onPointTap == null
                    ? null
                    : (d) => inspect(d.localPosition, haptic: true),
                onHorizontalDragStart: onPointTap == null
                    ? null
                    : (d) => inspect(d.localPosition),
                onHorizontalDragUpdate: onPointTap == null
                    ? null
                    : (d) => inspect(d.localPosition),
                onLongPressStart: onPointLongPress == null
                    ? null
                    : (d) => inspect(
                        d.localPosition,
                        longPress: true,
                        haptic: true,
                      ),
              ),
            ),
        ],
      ),
    );
  }

  ExtraLinesData get _emptyLines => const ExtraLinesData();
  ExtraLinesData _goalLines(BuildContext context) =>
      !_valid(targetValue) || _goalOutsideChart
      ? _emptyLines
      : ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: targetValue!,
              color: context.colors.textMedium.withValues(alpha: 0.65),
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ],
        );

  String _tooltip(ChartDataPoint point) =>
      '${DateFormat('d MMM yyyy').format(point.date)}\n'
      '${_valid(point.value) ? '${_formatValue(point.value!)}$_unitSuffix' : 'No entry'}';

  Widget _barChart(
    BuildContext context,
    FlTitlesData titles,
    double low,
    double high,
    Duration duration,
  ) => BarChart(
    BarChartData(
      minY: low,
      maxY: high,
      alignment: BarChartAlignment.spaceAround,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: titles,
      extraLinesData: _goalLines(context),
      barGroups: [
        for (var i = 0; i < data.length; i++)
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: _valid(data[i].value) ? data[i].value! : 0,
                width: data.length <= 7 ? 14 : 6,
                color: !_valid(data[i].value)
                    ? Colors.transparent
                    : context.colors.primary.withValues(
                        alpha: _selectedIndex < 0 || _selectedIndex == i
                            ? 1
                            : 0.6,
                      ),
                borderSide: _valid(data[i].value)
                    ? BorderSide(color: context.colors.accentText, width: 1)
                    : BorderSide.none,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          ),
      ],
      barTouchData: BarTouchData(
        enabled: onPointTap == null && onPointLongPress == null,
        touchTooltipData: BarTouchTooltipData(
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipColor: (_) => context.colors.textDark,
          getTooltipItem: (group, groupIndex, rod, rodIndex) =>
              !_valid(data[group.x].value)
              ? null
              : BarTooltipItem(
                  _tooltip(data[group.x]),
                  context.text.micro.copyWith(color: context.colors.card),
                ),
        ),
      ),
    ),
    duration: duration,
  );

  List<List<FlSpot>> _segments(List<ChartDataPoint> points) {
    final result = <List<FlSpot>>[];
    var segment = <FlSpot>[];
    DateTime? previousDate;
    final indexByDay = {
      for (var i = 0; i < data.length; i++) DateUtils.dateOnly(data[i].date): i,
    };
    for (final point in points) {
      final index = indexByDay[DateUtils.dateOnly(point.date)];
      final gap =
          segment.isNotEmpty &&
          (index == null ||
              index != segment.last.x + 1 ||
              (_daily &&
                  previousDate != null &&
                  DateUtils.dateOnly(
                        point.date,
                      ).difference(DateUtils.dateOnly(previousDate)).inDays >
                      1));
      if (!_valid(point.value) || gap || index == null) {
        if (segment.isNotEmpty) result.add(segment);
        segment = <FlSpot>[];
      }
      if (_valid(point.value) && index != null) {
        segment.add(FlSpot(index.toDouble(), point.value!));
      }
      previousDate = point.date;
    }
    if (segment.isNotEmpty) result.add(segment);
    return result;
  }

  Widget _lineChart(
    BuildContext context,
    FlTitlesData titles,
    double low,
    double high,
    Duration duration,
  ) {
    final recorded = _segments(data);
    final trends = _hasTrend ? _segments(trendData!) : <List<FlSpot>>[];
    final primary = context.colors.accentText;
    final selected = _selectedIndex;
    LineChartBarData series(List<FlSpot> segment, {required bool trend}) {
      final subtle = _hasTrend && !trend;
      return LineChartBarData(
        spots: segment,
        // Straight segments preserve the observed values without spline overshoot.
        isCurved: false,
        barWidth: subtle ? 0 : 2.5,
        color: primary,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: !trend || segment.length == 1,
          checkToShowDot: (spot, bar) =>
              subtle ||
              recorded.expand((s) => s).length <= 31 ||
              segment.length == 1 ||
              spot.x == selected,
          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
            radius: spot.x == selected
                ? 4.5
                : subtle
                ? 2.5
                : 3,
            color: subtle && spot.x != selected
                ? primary.withValues(alpha: 0.75)
                : primary,
            strokeColor: context.colors.card,
            strokeWidth: spot.x == selected ? 2 : 1,
          ),
        ),
        // Only a single continuous series gets shading; gaps stay visually open.
        belowBarData: BarAreaData(
          show:
              !subtle &&
              segment.length > 1 &&
              (trend ? trends.length == 1 : recorded.length == 1),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primary.withValues(alpha: 0.12),
              primary.withValues(alpha: 0),
            ],
          ),
        ),
      );
    }

    return LineChart(
      LineChartData(
        minX: data.length <= 1 ? -0.5 : 0,
        maxX: data.length <= 1 ? 0.5 : (data.length - 1).toDouble(),
        minY: low,
        maxY: high,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: titles,
        extraLinesData: _goalLines(context),
        lineBarsData: [
          for (final segment in recorded) series(segment, trend: false),
          for (final segment in trends) series(segment, trend: true),
        ],
        lineTouchData: LineTouchData(
          enabled: onPointTap == null && onPointLongPress == null,
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipColor: (_) => context.colors.textDark,
            getTooltipItems: (spots) => spots.map((spot) {
              if (spot.barIndex >= recorded.length) return null;
              return LineTooltipItem(
                _tooltip(data[spot.x.round()]),
                context.text.micro.copyWith(color: context.colors.card),
              );
            }).toList(),
          ),
        ),
      ),
      duration: duration,
    );
  }
}
