import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/progress_insight_service.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import 'shared_chart_card.dart';
import '../../../widgets/surface_card.dart';

/// The overview can grow and scroll; chart space never competes with text.
class ProgressChartContent extends StatelessWidget {
  const ProgressChartContent({
    super.key,
    required this.metric,
    required this.data,
    required this.insight,
    required this.startDate,
    required this.endDate,
    required this.timeFormat,
    required this.rangeSelector,
    required this.useKg,
    required this.onToggleUnit,
    required this.onInspect,
    required this.onOpenPoint,
    required this.onClearSelection,
    required this.emptyMessage,
    this.trendData,
    this.targetValue,
    this.goalContext,
    this.selectedDate,
    this.emptyAction,
  });
  final MetricSpec metric;
  final List<ChartDataPoint> data;
  final List<ChartDataPoint>? trendData;
  final MetricInsight insight;
  final DateTime startDate, endDate;
  final ChartTimeFormat timeFormat;
  final Widget rangeSelector;
  final bool useKg;
  final VoidCallback onToggleUnit, onClearSelection;
  final ValueChanged<ChartDataPoint> onInspect, onOpenPoint;
  final double? targetValue;
  final String? goalContext;
  final DateTime? selectedDate;
  final String emptyMessage;
  final Widget? emptyAction;

  bool get daily =>
      timeFormat == ChartTimeFormat.weekly ||
      timeFormat == ChartTimeFormat.oneMonth;
  String get aggregation => daily
      ? metric.plotType == ChartPlotType.line
            ? 'Daily measurements'
            : 'Daily values'
      : 'Weekly averages';

  static String dateSpan(DateTime start, DateTime end) {
    final format = start.year == end.year ? 'd MMM' : 'd MMM yyyy';
    return '${DateFormat(format).format(start)} \u2013 ${DateFormat('d MMM yyyy').format(end)}';
  }

  String valueText(double value, {bool withUnit = true}) {
    if (metric.isDuration) {
      final minutes = (value * 60).round();
      if (minutes < 60) return '${minutes}m';
      if (minutes % 60 == 0) return '${minutes ~/ 60}h';
      return '${minutes ~/ 60}h ${minutes % 60}m';
    }
    final text = metric.isCount
        ? NumberFormat('#,##0').format(value.round())
        : value.toStringAsFixed(1);
    final unit = metric.showKgLbToggle ? (useKg ? 'kg' : 'lb') : metric.unit;
    return withUnit && unit.isNotEmpty ? '$text $unit' : text;
  }

  String pointLabel(ChartDataPoint point) => daily
      ? DateFormat('EEE, d MMM yyyy').format(point.date)
      : dateSpan(
          point.bucket?.startDate ?? point.date,
          point.bucket?.endDate ?? point.date,
        );

  Widget _hero(BuildContext context) => Column(
    children: [
      Text(
        insight.heroLabel,
        style: context.text.caption,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: Spacing.inline),
      Text(
        valueText(insight.heroValue!, withUnit: false),
        key: const Key('progress-hero'),
        textAlign: TextAlign.center,
        style: MediaQuery.textScalerOf(context).scale(1) > 1.5
            ? context.text.display
            : context.text.metric,
      ),
      for (final stat in insight.stats.where(
        (stat) =>
            stat.label == 'Change in range' &&
            stat.value != 'Need another entry',
      )) ...[
        const SizedBox(height: Spacing.inline),
        Text(
          '${stat.value} in this range',
          key: const Key('progress-range-change'),
          style: context.text.bodyStrong,
          textAlign: TextAlign.center,
        ),
      ],
      if (insight.heroDate != null) ...[
        const SizedBox(height: Spacing.inline),
        Text(
          'Recorded ${DateFormat('d MMM yyyy').format(insight.heroDate!)}',
          style: context.text.caption,
          textAlign: TextAlign.center,
        ),
      ],
    ],
  );

  Widget _stats(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(1);
      final columns = math.min(
        insight.stats.length,
        math.max(1, (constraints.maxWidth / (100 * scale)).floor()),
      );
      final width =
          (constraints.maxWidth - Spacing.inline * (columns - 1)) / columns;
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: Spacing.inline,
        runSpacing: Spacing.section,
        children: [
          for (int i = 0; i < insight.stats.length; i++)
            SizedBox(
              width: width,
              child: Column(
                children: [
                  Text(
                    insight.stats[i].value,
                    style: context.text.cardTitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Spacing.inline),
                  Text(
                    insight.stats[i].label,
                    style: context.text.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      );
    },
  );

  Widget _selection(BuildContext context) {
    final index = data.indexWhere((p) => p.date == selectedDate);
    if (index < 0) return const SizedBox.shrink();
    final point = data[index];
    final value = point.value;
    final b = point.bucket;
    final isToday =
        daily &&
        point.date == endDate &&
        metric.plotType == ChartPlotType.bar &&
        metric.title != 'Sleep duration';
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.block),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.card),
        child: Padding(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                liveRegion: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isToday && value != null)
                      Text('Today so far', style: context.text.caption),
                    if (!daily && b != null)
                      Text(
                        'Average \u00b7 ${b.validDaysCount} of ${b.eligibleDaysCount} days recorded',
                        style: context.text.caption,
                      ),
                    if (b != null && b.incompleteDaysCount > 0)
                      Text(
                        '${b.incompleteDaysCount} ${b.incompleteDaysCount == 1 ? 'day' : 'days'} with incomplete nutrition excluded.',
                        style: context.text.caption,
                      ),
                    if (targetValue != null && value != null)
                      Text(
                        '${value >= targetValue! ? '+' : '\u2212'}${valueText((value - targetValue!).abs())} vs current goal',
                        style: context.text.caption,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.inline),
              Wrap(
                spacing: Spacing.inline,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Previous chart value',
                    onPressed: index > 0
                        ? () => onInspect(data[index - 1])
                        : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  IconButton(
                    tooltip: 'Next chart value',
                    onPressed: index < data.length - 1
                        ? () => onInspect(data[index + 1])
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                  TextButton(
                    onPressed: () => onOpenPoint(point),
                    child: Text(daily ? 'View day' : 'View daily details'),
                  ),
                  IconButton(
                    tooltip: 'Clear chart selection',
                    onPressed: onClearSelection,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _records(BuildContext context) => Material(
    color: Colors.transparent,
    child: ExpansionTile(
      key: ValueKey('details-${metric.title}-$timeFormat'),
      tilePadding: EdgeInsets.zero,
      title: Text('Details', style: context.text.bodyStrong),
      shape: const Border(),
      collapsedShape: const Border(),
      children: [
        Text(dateSpan(startDate, endDate), style: context.text.caption),
        if (insight.insightText != null) ...[
          const SizedBox(height: Spacing.block),
          Text(insight.insightText!, style: context.text.body),
        ],
        if (goalContext != null) ...[
          const SizedBox(height: Spacing.inline),
          Text(goalContext!, style: context.text.caption),
        ],
        if (insight.stats.isNotEmpty) ...[
          const SizedBox(height: Spacing.block),
          _stats(context),
        ],
        const SizedBox(height: Spacing.block),
        Text(
          daily ? 'Daily records' : 'Weekly records',
          style: context.text.bodyStrong,
        ),
        for (final point in data)
          ListTile(
            key: ValueKey('progress-record-${point.date.toIso8601String()}'),
            contentPadding: EdgeInsets.zero,
            title: Text(pointLabel(point), style: context.text.caption),
            subtitle: Text(
              point.value == null
                  ? (point.bucket?.incompleteDaysCount ?? 0) > 0
                        ? 'Nutrition incomplete'
                        : 'No entry recorded'
                  : valueText(point.value!),
              style: context.text.bodyStrong,
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => onOpenPoint(point),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final hasData = data.any((p) => p.value != null && p.value!.isFinite);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasData && insight.heroValue != null) ...[
          _hero(context),
          const SizedBox(height: Spacing.section),
        ],
        SurfaceCard(
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              rangeSelector,
              const SizedBox(height: Spacing.block),
              SharedChartCard(
                metric: metric,
                subtitle: aggregation,
                embedded: true,
                compactLegend: true,
                data: data,
                trendData: trendData,
                startDate: startDate,
                endDate: endDate,
                useKg: useKg,
                onToggleUnit: onToggleUnit,
                statLabels: const [],
                statValues: const [],
                timeFormat: timeFormat,
                emptyMessage: emptyMessage,
                targetValue: targetValue,
                selectedDate: selectedDate,
                onPointTap: onInspect,
              ),
              if (hasData) _selection(context),
              if (insight.coverageText.isNotEmpty) ...[
                const SizedBox(height: Spacing.block),
                Text(insight.coverageText, style: context.text.caption),
              ],
              if (!hasData && emptyAction != null) emptyAction!,
            ],
          ),
        ),
        if (hasData) ...[
          const SizedBox(height: Spacing.stack),
          _records(context),
        ],
      ],
    );
  }
}
