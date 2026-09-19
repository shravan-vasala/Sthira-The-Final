import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../providers/app_providers.dart';
import '../../../services/progress_aggregation_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_bottom_sheet.dart';
import '../../../widgets/primary_button.dart';
import '../progress_screen.dart';
import 'shared_chart_card.dart';

class ChartDrilldownSheet extends ConsumerStatefulWidget {
  const ChartDrilldownSheet({
    super.key,
    required this.bucket,
    required this.metric,
    this.useKg,
  });

  final ChartBucket bucket;
  final MetricType metric;

  /// Keeps a temporary chart unit choice when opening daily details.
  final bool? useKg;

  @override
  ConsumerState<ChartDrilldownSheet> createState() =>
      _ChartDrilldownSheetState();
}

class _ChartDrilldownSheetState extends ConsumerState<ChartDrilldownSheet> {
  DateTime? _selectedDate;

  @override
  void didUpdateWidget(covariant ChartDrilldownSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bucket.startDate != widget.bucket.startDate ||
        oldWidget.bucket.endDate != widget.bucket.endDate ||
        oldWidget.metric != widget.metric) {
      _selectedDate = null;
    }
  }

  MetricSpec _spec(bool useKg) => switch (widget.metric) {
    MetricType.weight => MetricSpec(title: 'Weight', unit: useKg ? 'kg' : 'lb'),
    MetricType.steps => const MetricSpec(
      title: 'Steps',
      unit: 'steps',
      isCount: true,
      plotType: ChartPlotType.bar,
    ),
    MetricType.sleep => const MetricSpec(
      title: 'Sleep',
      unit: 'h',
      isDuration: true,
      plotType: ChartPlotType.bar,
    ),
    MetricType.bmi => const MetricSpec(title: 'BMI', unit: ''),
    MetricType.bodyFat => const MetricSpec(title: 'Body fat', unit: '%'),
    MetricType.calories => const MetricSpec(
      title: 'Calories logged',
      unit: 'kcal',
      isCount: true,
      plotType: ChartPlotType.bar,
    ),
    MetricType.protein => const MetricSpec(
      title: 'Protein logged',
      unit: 'g',
      plotType: ChartPlotType.bar,
    ),
    MetricType.screenTime => const MetricSpec(
      title: 'Screen time',
      unit: 'h',
      isDuration: true,
      plotType: ChartPlotType.bar,
    ),
  };

  String _value(
    double? value,
    MetricSpec spec, {
    bool future = false,
    bool incomplete = false,
  }) {
    if (future) return 'Upcoming';
    if (incomplete) return 'Nutrition incomplete';
    if (value == null) return 'No entry';
    if (spec.isDuration) {
      final minutes = (value * 60).round();
      final hours = minutes ~/ 60;
      final remainder = minutes % 60;
      if (hours == 0) return '${remainder}m';
      return remainder == 0 ? '${hours}h' : '${hours}h ${remainder}m';
    }
    final formatted = spec.isCount
        ? NumberFormat.decimalPattern().format(value.round())
        : widget.metric == MetricType.protein
        ? NumberFormat('0.#').format(value)
        : value.toStringAsFixed(1);
    return spec.unit.isEmpty ? formatted : '$formatted ${spec.unit}';
  }

  void _select(ChartDataPoint point) {
    setState(() => _selectedDate = point.date);
  }

  void _viewDay(DateTime date) {
    final today = DateUtils.dateOnly(ref.read(clockProvider));
    if (date.isAfter(today)) return;
    ref.read(selectedDateProvider.notifier).state = date;
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final bucket = widget.bucket;
    final startStr = DateFormat('yyyy-MM-dd').format(bucket.startDate);
    final endStr = DateFormat('yyyy-MM-dd').format(bucket.endDate);
    final logs = ref.watch(dailyLogsRangeProvider((startStr, endStr)));
    final mealLogs = ref.watch(dailyMealLogsRangeProvider((startStr, endStr)));
    final profile = ref.watch(profileProvider);
    final useKg = widget.useKg ?? profile.useKg;
    final hasHeight =
        profile.height != null &&
        profile.height!.isFinite &&
        profile.height! > 0;
    final today = DateUtils.dateOnly(ref.watch(clockProvider));
    final dailyBuckets = ProgressAggregationService.aggregate(
      logs: logs,
      mealLogs: mealLogs,
      metric: widget.metric,
      range: TimeRange.oneMonth,
      rangeStart: bucket.startDate,
      rangeEnd: bucket.endDate,
      today: today,
      heightInMeters: hasHeight ? profile.heightInMeters : 0,
      useKg: useKg,
    );
    final data = dailyBuckets
        .map((day) => ChartDataPoint(day.startDate, day.average, bucket: day))
        .toList();
    final recorded = data.where((day) => day.value != null).toList();
    final incompleteDays = dailyBuckets.fold<int>(
      0,
      (sum, day) => sum + day.incompleteDaysCount,
    );
    final eligible = data.where((day) => !day.date.isAfter(today)).toList();
    ChartDataPoint? selected;
    for (final point in data) {
      if (DateUtils.isSameDay(point.date, _selectedDate)) selected = point;
    }
    selected ??= recorded.isNotEmpty
        ? recorded.last
        : eligible.isNotEmpty
        ? eligible.last
        : data.isNotEmpty
        ? data.first
        : null;
    final selectedPoint = selected;
    final spec = _spec(useKg);
    final future = selectedPoint?.date.isAfter(today) ?? false;
    final dateFormat = DateFormat('EEE, d MMM yyyy');

    return AppSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Daily details', style: context.text.screenTitle),
              ),
              IconButton(
                tooltip: 'Close daily details',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: Spacing.textPair),
          Text(
            '${DateFormat('d MMM yyyy').format(bucket.startDate)} \u2013 '
            '${DateFormat('d MMM yyyy').format(bucket.endDate)}',
            style: context.text.caption.copyWith(
              color: context.colors.textMedium,
            ),
          ),
          const SizedBox(height: Spacing.block),
          if (recorded.isNotEmpty)
            SharedChartCard(
              metric: spec,
              data: data,
              startDate: bucket.startDate,
              endDate: bucket.endDate,
              selectedDate: selectedPoint?.date,
              onPointTap: _select,
              useKg: useKg,
              statLabels: const [],
              statValues: const [],
              // Every point in this sheet is a day, including month drilldowns.
              timeFormat: data.length <= 7
                  ? ChartTimeFormat.weekly
                  : ChartTimeFormat.oneMonth,
            )
          else
            Container(
              padding: const EdgeInsets.all(Spacing.block),
              decoration: BoxDecoration(
                color: context.colors.insetSurface,
                borderRadius: BorderRadius.circular(Radii.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(spec.title, style: context.text.cardTitle),
                  const SizedBox(height: Spacing.inline),
                  Text(
                    widget.metric == MetricType.bmi && !hasHeight
                        ? 'Add your height in your profile to calculate BMI from your recorded weight.'
                        : eligible.isEmpty
                        ? 'This period is ahead of today. Entries will appear here when they are recorded.'
                        : incompleteDays > 0
                        ? 'Food entries are saved, but their nutrition is incomplete. View a day to review them.'
                        : 'No entries in this period. Choose a day below, then use View day to add an entry.',
                    style: context.text.body,
                  ),
                ],
              ),
            ),
          if (incompleteDays > 0) ...[
            const SizedBox(height: Spacing.inline),
            Text(
              '$incompleteDays ${incompleteDays == 1 ? 'day' : 'days'} with incomplete nutrition excluded.',
              style: context.text.caption,
            ),
          ],
          const SizedBox(height: Spacing.block),
          Semantics(
            liveRegion: true,
            child: Container(
              key: const Key('daily-detail-readout'),
              padding: const EdgeInsets.all(Spacing.block),
              decoration: BoxDecoration(
                color: context.colors.insetSurface,
                borderRadius: BorderRadius.circular(Radii.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedPoint == null
                        ? 'Choose a day'
                        : dateFormat.format(selectedPoint.date),
                    style: context.text.caption.copyWith(
                      color: context.colors.textMedium,
                    ),
                  ),
                  const SizedBox(height: Spacing.textPair),
                  Text(
                    _value(
                      selectedPoint?.value,
                      spec,
                      future: future,
                      incomplete:
                          (selectedPoint?.bucket?.incompleteDaysCount ?? 0) > 0,
                    ),
                    style: context.text.screenTitle,
                  ),
                  if (selectedPoint?.value == null && !future)
                    Text(
                      (selectedPoint?.bucket?.incompleteDaysCount ?? 0) > 0
                          ? 'Some nutrition values are unknown. This day is excluded from the chart.'
                          : 'Nothing recorded for this day.',
                      style: context.text.body,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spacing.inline),
          PrimaryButton(
            label: 'View day',
            onPressed: selectedPoint == null || future
                ? null
                : () => _viewDay(selectedPoint.date),
          ),
          const SizedBox(height: Spacing.block),
          ExpansionTile(
            key: const Key('daily-records'),
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            shape: const Border(),
            collapsedShape: const Border(),
            title: Text('Daily records', style: context.text.bodyStrong),
            subtitle: Text(
              '${recorded.length} of ${eligible.length} days recorded',
              style: context.text.caption,
            ),
            children: [
              for (final point in data)
                ListTile(
                  key: ValueKey(
                    'daily-record-${DateFormat('yyyy-MM-dd').format(point.date)}',
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Spacing.block,
                  ),
                  title: Text(dateFormat.format(point.date)),
                  subtitle: Text(
                    _value(
                      point.value,
                      spec,
                      future: point.date.isAfter(today),
                      incomplete: (point.bucket?.incompleteDaysCount ?? 0) > 0,
                    ),
                  ),
                  selected: DateUtils.isSameDay(
                    point.date,
                    selectedPoint?.date,
                  ),
                  selectedColor: context.colors.textDark,
                  selectedTileColor: context.colors.insetSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.control),
                  ),
                  onTap: () => _select(point),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
