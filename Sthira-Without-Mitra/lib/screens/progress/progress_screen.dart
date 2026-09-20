import 'package:trufit_bodamma/theme/app_typography.dart';
import 'package:trufit_bodamma/theme/app_colors.dart';
import 'package:trufit_bodamma/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'widgets/progress_chart_content.dart';
import '../../services/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../providers/app_providers.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_profile.dart';
import 'widgets/shared_chart_card.dart';
import '../home/steps_entry_dialog.dart';
import '../home/sleep_entry_dialog.dart';
import '../home/body_fat_entry_dialog.dart';
import '../home/weight_entry_dialog.dart';
import 'widgets/chart_drilldown_sheet.dart';
import '../../providers/progress_chart_provider.dart';
import '../../providers/progress_goal_provider.dart';
import '../../services/progress_aggregation_service.dart';
import '../../services/progress_insight_service.dart';
import '../../models/habit.dart';
import '../../theme/layout_insets.dart';
import '../../theme/app_motion.dart';

enum MetricType {
  weight,
  steps,
  sleep,
  bmi,
  bodyFat,
  calories,
  protein,
  screenTime,
}

enum TimeRange { weekly, oneMonth, threeMonths, sixMonths, twelveMonths }

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key, this.initialMetric});

  final MetricType? initialMetric;

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  late MetricType _selectedMetric;
  final Map<MetricType, TimeRange> _selectedRanges = {};
  DateTime? _selectedDate;
  bool? _useKgOverride;
  final ScrollController _scrollController = ScrollController();

  TimeRange get _selectedRange {
    if (_selectedRanges.containsKey(_selectedMetric)) {
      return _selectedRanges[_selectedMetric]!;
    }
    // Default: daily activity/nutrition to 1W, body measurements to 1M
    final isBody =
        _selectedMetric == MetricType.weight ||
        _selectedMetric == MetricType.bodyFat ||
        _selectedMetric == MetricType.bmi;
    return isBody ? TimeRange.oneMonth : TimeRange.weekly;
  }

  void _setRange(TimeRange range) {
    setState(() {
      _selectedRanges[_selectedMetric] = range;
      _selectedDate = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedMetric = widget.initialMetric ?? MetricType.weight;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _chooseMetric() async {
    final chosen = await showAppBottomSheet<MetricType>(
      context: context,
      builder: (context) => AppSheet(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Choose a metric', style: context.text.screenTitle),
            const SizedBox(height: Spacing.block),
            for (final metric in MetricType.values)
              Material(
                color: Colors.transparent,
                child: ListTile(
                  title: Text(_metricTitle(metric), style: context.text.body),
                  selected: metric == _selectedMetric,
                  selectedColor: context.colors.accentText,
                  trailing: metric == _selectedMetric
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () => Navigator.of(context).pop(metric),
                ),
              ),
          ],
        ),
      ),
    );
    if (!mounted || chosen == null || chosen == _selectedMetric) return;
    Haptics.tap();
    setState(() {
      _selectedMetric = chosen;
      _selectedDate = null;
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  DateTime _calcStartDate(DateTime now) {
    final d = DateTime(now.year, now.month, now.day);
    switch (_selectedRange) {
      case TimeRange.weekly:
        return DateTime(d.year, d.month, d.day - 6);
      case TimeRange.oneMonth:
        final m = _clampMonth(d, 1);
        return DateTime(m.year, m.month, m.day + 1);
      case TimeRange.threeMonths:
        final m = _clampMonth(d, 3);
        return DateTime(m.year, m.month, m.day + 1);
      case TimeRange.sixMonths:
        final m = _clampMonth(d, 6);
        return DateTime(m.year, m.month, m.day + 1);
      case TimeRange.twelveMonths:
        final m = _clampMonth(d, 12);
        return DateTime(m.year, m.month, m.day + 1);
    }
  }

  DateTime _calcPrevStartDate(DateTime start, DateTime end) {
    final days =
        DateTime.utc(
          end.year,
          end.month,
          end.day,
        ).difference(DateTime.utc(start.year, start.month, start.day)).inDays +
        1;
    return DateTime(start.year, start.month, start.day - days);
  }

  DateTime _clampMonth(DateTime date, int monthsBack) {
    int targetYear = date.year;
    int targetMonth = date.month - monthsBack;
    while (targetMonth <= 0) {
      targetMonth += 12;
      targetYear--;
    }
    final int lastDay = DateTime(targetYear, targetMonth + 1, 0).day;
    final int targetDay = date.day > lastDay ? lastDay : date.day;
    return DateTime(targetYear, targetMonth, targetDay);
  }

  DateTime _calcEndDate(DateTime now) {
    return DateTime(now.year, now.month, now.day);
  }

  void _openManualEntry() {
    final today = ref.read(clockProvider);
    ref.read(selectedDateProvider.notifier).state = DateTime(
      today.year,
      today.month,
      today.day,
    );
    if (_selectedMetric == MetricType.weight ||
        _selectedMetric == MetricType.bmi) {
      showAppBottomSheet(
        context: context,
        builder: (_) => const WeightEntryDialog(),
      );
    } else if (_selectedMetric == MetricType.bodyFat) {
      showAppBottomSheet(
        context: context,
        builder: (_) => const BodyFatEntryDialog(),
      );
    } else if (_selectedMetric == MetricType.steps) {
      showAppBottomSheet(
        context: context,
        builder: (_) => const StepsEntryDialog(),
      );
    } else if (_selectedMetric == MetricType.sleep) {
      showAppBottomSheet(
        context: context,
        builder: (_) => const SleepEntryDialog(),
      );
    }
  }

  void _openDrilldownSheet(ChartBucket bucket, bool useKg) {
    showAppBottomSheet(
      context: context,
      builder: (_) => ChartDrilldownSheet(
        bucket: bucket,
        metric: _selectedMetric,
        useKg: useKg,
      ),
    );
  }

  List<ChartDataPoint> _calculateTrendData(List<ChartDataPoint> data) {
    if (data.isEmpty) return [];
    final trend = <ChartDataPoint>[];
    for (int i = 0; i < data.length; i++) {
      final windowStart = data[i].date.subtract(const Duration(days: 6));
      final window = data
          .where(
            (d) =>
                d.value != null &&
                !d.date.isBefore(windowStart) &&
                !d.date.isAfter(data[i].date),
          )
          .toList();
      if (data[i].value != null && window.length >= 3) {
        final sum = window.fold<double>(0, (p, c) => p + c.value!);
        trend.add(
          ChartDataPoint(
            data[i].date,
            sum / window.length,
            bucket: data[i].bucket,
          ),
        );
      } else {
        trend.add(ChartDataPoint(data[i].date, null, bucket: data[i].bucket));
      }
    }
    return trend;
  }

  MetricSpec _getMetricSpec(MetricType metric, bool useKg) {
    switch (metric) {
      case MetricType.weight:
        return MetricSpec(
          title: 'Weight',
          unit: useKg ? 'kg' : 'lb',
          isCount: false,
          plotType: ChartPlotType.line,
          showKgLbToggle: true,
        );
      case MetricType.steps:
        return const MetricSpec(
          title: 'Steps',
          unit: 'steps',
          isCount: true,
          plotType: ChartPlotType.bar,
        );
      case MetricType.sleep:
        return const MetricSpec(
          title: 'Sleep duration',
          isDuration: true,
          unit: 'h',
          isCount: false,
          plotType: ChartPlotType.bar,
        );
      case MetricType.bmi:
        return const MetricSpec(
          title: 'BMI',
          unit: '',
          isCount: false,
          plotType: ChartPlotType.line,
        );
      case MetricType.bodyFat:
        return const MetricSpec(
          title: 'Body fat',
          unit: '%',
          isCount: false,
          plotType: ChartPlotType.line,
        );
      case MetricType.calories:
        return const MetricSpec(
          title: 'Calories logged',
          unit: 'kcal',
          isCount: true,
          plotType: ChartPlotType.bar,
        );
      case MetricType.protein:
        return const MetricSpec(
          title: 'Protein logged',
          unit: 'g',
          isCount: false,
          plotType: ChartPlotType.bar,
        );
      case MetricType.screenTime:
        return const MetricSpec(
          title: 'Screen time',
          isDuration: true,
          unit: 'h',
          isCount: false,
          plotType: ChartPlotType.bar,
        );
    }
  }

  Widget _buildChart(
    List<ChartDataPoint> data,
    bool useKg,
    MetricInsight insight,
    UserProfile profile,
    DateTime startDate,
    DateTime endDate,
    double? targetValue,
    String? goalContext,
  ) {
    final daily =
        _selectedRange == TimeRange.weekly ||
        _selectedRange == TimeRange.oneMonth;
    final isBody =
        _selectedMetric == MetricType.weight ||
        _selectedMetric == MetricType.bodyFat ||
        _selectedMetric == MetricType.bmi;
    final format = switch (_selectedRange) {
      TimeRange.weekly => ChartTimeFormat.weekly,
      TimeRange.oneMonth => ChartTimeFormat.oneMonth,
      TimeRange.threeMonths => ChartTimeFormat.threeMonths,
      TimeRange.sixMonths => ChartTimeFormat.sixMonths,
      TimeRange.twelveMonths => ChartTimeFormat.twelveMonths,
    };
    final trend = daily && isBody ? _calculateTrendData(data) : null;
    final needsHeight =
        _selectedMetric == MetricType.bmi &&
        (profile.height == null ||
            !profile.height!.isFinite ||
            profile.height! <= 0);
    final canLog = [
      MetricType.weight,
      MetricType.bmi,
      MetricType.steps,
      MetricType.sleep,
      MetricType.bodyFat,
    ].contains(_selectedMetric);
    return ProgressChartContent(
      metric: _getMetricSpec(_selectedMetric, useKg),
      data: data,
      trendData:
          trend != null && trend.where((p) => p.value != null).length >= 2
          ? trend
          : null,
      insight: insight,
      startDate: startDate,
      endDate: endDate,
      timeFormat: format,
      useKg: useKg,
      targetValue: targetValue,
      goalContext: goalContext,
      selectedDate: _selectedDate,
      onInspect: (point) {
        if (_selectedDate != point.date) {
          setState(() => _selectedDate = point.date);
        }
      },
      onClearSelection: () => setState(() => _selectedDate = null),
      onToggleUnit: () {
        Haptics.tap();
        setState(() => _useKgOverride = !useKg);
      },
      onOpenPoint: (point) {
        if (daily) {
          ref.read(selectedDateProvider.notifier).state = point.date;
          context.go('/home');
        } else if (point.bucket != null) {
          _openDrilldownSheet(point.bucket!, useKg);
        }
      },
      emptyMessage: needsHeight
          ? 'Add your height in Profile to calculate BMI.'
          : 'No recorded data for this period.',
      emptyAction: needsHeight
          ? TextButton(
              onPressed: () => context.go('/profile'),
              child: const Text('Open Profile'),
            )
          : _selectedMetric == MetricType.calories ||
                _selectedMetric == MetricType.protein
          ? TextButton.icon(
              onPressed: () {
                final today = ref.read(clockProvider);
                ref.read(selectedDateProvider.notifier).state = DateTime(
                  today.year,
                  today.month,
                  today.day,
                );
                ref.read(weekOffsetProvider.notifier).state = 0;
                context.go('/home/meals');
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Log a meal'),
            )
          : canLog
          ? TextButton.icon(
              onPressed: _openManualEntry,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Log ${_selectedMetric == MetricType.bmi ? 'weight' : _metricTitle(_selectedMetric).toLowerCase()}',
              ),
            )
          : null,
      rangeSelector: Center(
        child: SingleChildScrollView(
          key: PageStorageKey('progress-ranges-$_selectedMetric'),
          scrollDirection: Axis.horizontal,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: context.colors.card.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRangeTab(context, '1W', TimeRange.weekly),
                _buildRangeTab(context, '1M', TimeRange.oneMonth),
                _buildRangeTab(context, '3M', TimeRange.threeMonths),
                _buildRangeTab(context, '6M', TimeRange.sixMonths),
                _buildRangeTab(context, '12M', TimeRange.twelveMonths),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<ChartBucket> _displayBuckets(
    List<ChartBucket> buckets,
    bool profileKg,
    bool useKg,
  ) {
    if (_selectedMetric != MetricType.weight || profileKg == useKg) {
      return buckets;
    }
    final factor = useKg ? 1 / 2.20462 : 2.20462;
    return buckets
        .map(
          (bucket) => ChartBucket(
            startDate: bucket.startDate,
            endDate: bucket.endDate,
            average: bucket.average == null ? null : bucket.average! * factor,
            min: bucket.min == null ? null : bucket.min! * factor,
            max: bucket.max == null ? null : bucket.max! * factor,
            validDaysCount: bucket.validDaysCount,
            eligibleDaysCount: bucket.eligibleDaysCount,
            incompleteDaysCount: bucket.incompleteDaysCount,
            isPartial: bucket.isPartial,
            observations: bucket.observations
                .map(
                  (o) =>
                      ChartObservation(date: o.date, value: o.value * factor),
                )
                .toList(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider);
    final startDate = _calcStartDate(now);
    final endDate = _calcEndDate(now);

    final profile = ref.watch(profileProvider);
    final useKg = _useKgOverride ?? profile.useKg;

    final rawBuckets = ref.watch(
      aggregatedChartProvider((
        metric: _selectedMetric,
        range: _selectedRange,
        start: startDate,
        end: endDate,
      )),
    );

    final buckets = _displayBuckets(rawBuckets, profile.useKg, useKg);
    final data = buckets
        .map((b) => ChartDataPoint(b.startDate, b.average, bucket: b))
        .toList();

    double? targetValue;
    String? goalContext;
    if (_selectedMetric == MetricType.weight && profile.targetWeight != null) {
      targetValue = useKg
          ? profile.targetWeight as double
          : (profile.targetWeight as double) * 2.20462;
    } else if (_selectedMetric == MetricType.calories) {
      targetValue = profile.targetCalories.toDouble();
    } else if (_selectedMetric == MetricType.protein) {
      targetValue = profile.targetProteinG.toDouble();
    } else if (_selectedMetric == MetricType.steps ||
        _selectedMetric == MetricType.sleep) {
      final habitType = _selectedMetric == MetricType.steps
          ? HabitType.autoSteps
          : HabitType.autoSleep;
      final goal = ref.watch(progressHabitGoalProvider(habitType));
      targetValue = goal.value;
      goalContext = goal.context;
    }

    final prevStartDate = _calcPrevStartDate(startDate, endDate);
    final prevEndDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day - 1,
    );
    final rawPrevBuckets = ref.watch(
      aggregatedChartProvider((
        metric: _selectedMetric,
        range: _selectedRange,
        start: prevStartDate,
        end: prevEndDate,
      )),
    );

    final prevBuckets = _displayBuckets(rawPrevBuckets, profile.useKg, useKg);
    if (targetValue != null && (!targetValue.isFinite || targetValue <= 0)) {
      targetValue = null;
    }
    final insight = ProgressInsightService.buildInsight(
      metric: _selectedMetric,
      range: _selectedRange,
      currentBuckets: buckets,
      previousBuckets: prevBuckets,
      today: now,
      useKg: useKg,
      targetValue: targetValue,
    );

    final separateActions =
        MediaQuery.sizeOf(context).width < 400 &&
        MediaQuery.textScalerOf(context).scale(24) > 36;
    final toolbarActions = <Widget>[
      IconButton(
        tooltip: 'Yearly activity',
        icon: const Icon(Icons.calendar_month_rounded),
        onPressed: () {
          Haptics.tap();
          context.push('/progress/yearly-activity');
        },
      ),
      if (_selectedMetric != MetricType.bmi &&
          _selectedMetric != MetricType.calories &&
          _selectedMetric != MetricType.protein &&
          _selectedMetric != MetricType.screenTime)
        IconButton(
          tooltip: 'Log ${_metricTitle(_selectedMetric).toLowerCase()} today',
          icon: const Icon(Icons.add_rounded),
          onPressed: () {
            Haptics.tap();
            _openManualEntry();
          },
        ),
    ];

    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      appBar: AppBar(
        toolbarHeight: math.max(
          56,
          MediaQuery.textScalerOf(context).scale(24) * 2.5,
        ),
        title: TextButton(
          key: const Key('progress-metric-picker'),
          onPressed: _chooseMetric,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(48, 48),
            alignment: Alignment.centerLeft,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  _metricTitle(_selectedMetric),
                  style: context.text.screenTitle,
                ),
              ),
              const SizedBox(width: Spacing.inline),
              const Icon(Icons.expand_more_rounded),
            ],
          ),
        ),
        leading: Navigator.canPop(context)
            ? IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: separateActions ? null : toolbarActions,
        bottom: separateActions
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: toolbarActions,
                  ),
                ),
              )
            : null,
      ),
      body: SafeArea(
        bottom: false,
        top: false,
        child: SingleChildScrollView(
          key: const Key('progress-scroll'),
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(
            Spacing.screen,
            0,
            Spacing.screen,
            shellScrollBottomPadding(context),
          ),
          child: AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : Motion.standard,
            switchInCurve: Motion.enter,
            switchOutCurve: Motion.exit,
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: KeyedSubtree(
              key: ValueKey('$_selectedMetric-$_selectedRange'),
              child: _buildChart(
                data,
                useKg,
                insight,
                profile,
                startDate,
                endDate,
                targetValue,
                goalContext,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _metricTitle(MetricType metric) {
    switch (metric) {
      case MetricType.weight:
        return 'Weight';
      case MetricType.steps:
        return 'Steps';
      case MetricType.sleep:
        return 'Sleep duration';
      case MetricType.bmi:
        return 'BMI';
      case MetricType.bodyFat:
        return 'Body fat';
      case MetricType.calories:
        return 'Calories logged';
      case MetricType.protein:
        return 'Protein logged';
      case MetricType.screenTime:
        return 'Screen time';
    }
  }

  Widget _buildRangeTab(BuildContext context, String label, TimeRange range) {
    final isSelected = _selectedRange == range;
    final semanticLabel = switch (range) {
      TimeRange.weekly => '1 week',
      TimeRange.oneMonth => '1 month',
      TimeRange.threeMonths => '3 months',
      TimeRange.sixMonths => '6 months',
      TimeRange.twelveMonths => '12 months',
    };
    void selectRange() {
      Haptics.tap();
      _setRange(range);
    }

    return Semantics(
      label: semanticLabel,
      button: true,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      onTap: selectRange,
      excludeSemantics: true,
      child: InkWell(
        onTap: selectRange,
        excludeFromSemantics: true,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : Motion.standard,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? context.colors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                label,
                style: context.text.caption.copyWith(
                  color: isSelected
                      ? context.colors.onPrimary
                      : context.colors.textMedium,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
