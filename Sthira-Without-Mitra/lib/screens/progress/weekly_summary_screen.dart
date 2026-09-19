import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/section_header.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../providers/weekly_summary_provider.dart';
import '../../providers/app_providers.dart';
import '../../share/share_card_exporter.dart';
import '../../share/weekly_share_layout.dart';
import '../../../widgets/primary_button.dart';
import '../../theme/app_spacing.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';
import '../../theme/layout_insets.dart';
import '../../theme/app_motion.dart';
import 'widgets/shared_chart_card.dart';

class WeeklySummaryScreen extends ConsumerWidget {
  const WeeklySummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(weeklySummaryProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    // Get week bounds for title
    final weekday = selectedDate.weekday;
    final startOfWeek = selectedDate.subtract(Duration(days: weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final titleText =
        '${DateFormat('d MMM yyyy').format(startOfWeek)} \u2013 ${DateFormat('d MMM yyyy').format(endOfWeek)}';

    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(context).scale(24) > 36
            ? 96
            : 56,
        title: const Text('Weekly Progress'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            shellScrollBottomPadding(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                titleText,
                style: context.text.body.copyWith(
                  color: context.colors.textMedium,
                ),
                textAlign: TextAlign.center,
              ).animate().fade().slideY(begin: -0.2),

              const SizedBox(height: Spacing.major),

              // 3.1 Animated Score Card Hero
              _ScoreHeroCard(summary: summary)
                  .animate()
                  .fade(delay: Motion.instant)
                  .scale(begin: const Offset(0.95, 0.95)),

              const SizedBox(height: Spacing.major),

              // 3.4 Insights Strip
              _InsightsStrip(
                summary: summary,
              ).animate().fade(delay: Motion.standard),

              const SizedBox(height: Spacing.section),

              // 3.2 Daily Scores Chart
              _DailyScoresChartCard(
                dailyScores: summary.dailyScores,
                startOfWeek: startOfWeek,
              ).animate().fade(delay: Motion.standard).slideY(begin: 0.1),

              // Secondary Habit Chart
              if (summary.scheduledHabitInstances > 0) ...[
                const SizedBox(height: Spacing.section),
                _HabitChartCard(
                  rates: summary.dailyHabitRates,
                  totals: summary.dailyHabitsTotal,
                  completed: summary.dailyHabitsCompleted,
                  recorded: summary.dailyHabitsRecorded,
                  startOfWeek: startOfWeek,
                ).animate().fade(delay: Motion.deliberate).slideY(begin: 0.1),
              ],

              const SizedBox(height: Spacing.section),

              const SectionHeader(
                'STATS OVERVIEW',
                horizontalPadding: 0,
              ).animate().fade(delay: Motion.deliberate),
              const SizedBox(height: Spacing.section),

              // 3.3 Grid Stats with Trend Deltas
              LayoutBuilder(
                builder: (context, constraints) {
                  final scale = MediaQuery.textScalerOf(context).scale(15) / 15;
                  final columns = constraints.maxWidth >= 300 * scale ? 2 : 1;
                  final width =
                      (constraints.maxWidth - 16 * (columns - 1)) / columns;
                  final cards =
                      [
                            _StatCard(
                              title: 'Workouts',
                              icon: Icons.fitness_center_rounded,
                              primaryValue: summary.workoutsTotal == 0
                                  ? '\u2014'
                                  : '${summary.workoutsCompleted}/${summary.workoutsTotal}',
                              subtitle: summary.isFutureWeek
                                  ? 'Upcoming week'
                                  : summary.workoutsTotal == 0
                                  ? 'No training scheduled'
                                  : summary.isPartialWeek
                                  ? 'Sessions so far'
                                  : 'Training sessions',
                              trendValue: _calculateTrendInt(
                                summary.workoutsCompleted,
                                summary.prevWorkoutsCompleted,
                              ),
                            ),
                            _StatCard(
                              title: 'Habits',
                              icon: Icons.checklist_rounded,
                              numericValue: summary.hasHabitRecords
                                  ? summary.habitCompletionRate * 100
                                  : null,
                              primaryValue: summary.hasHabitRecords
                                  ? null
                                  : '\u2014',
                              unit: '%',
                              subtitle: summary.isFutureWeek
                                  ? 'Upcoming week'
                                  : summary.scheduledHabitInstances == 0
                                  ? 'No habits scheduled'
                                  : !summary.hasHabitRecords
                                  ? 'No habit entries recorded'
                                  : '${summary.completedHabitInstances} of ${summary.scheduledHabitInstances} scheduled completed · ${summary.recordedHabitInstances} recorded',
                              trendValue: _calculateTrendDouble(
                                summary.habitCompletionRate,
                                summary.prevHabitCompletionRate,
                                isPercent: true,
                              ),
                            ),
                            _StatCard(
                              title: 'Steps',
                              icon: Icons.directions_walk_rounded,
                              numericValue: summary.stepsDays > 0
                                  ? summary.avgSteps.toDouble()
                                  : null,
                              primaryValue: summary.stepsDays > 0
                                  ? null
                                  : '\u2014',
                              subtitle: '${summary.stepsDays} recorded days',
                              trendValue: _calculateTrendInt(
                                summary.avgSteps,
                                summary.prevAvgSteps,
                              ),
                            ),
                            _StatCard(
                              title: 'Sleep',
                              icon: Icons.nightlight_round_rounded,
                              numericValue: summary.sleepNights > 0
                                  ? summary.avgSleep
                                  : null,
                              primaryValue: summary.sleepNights > 0
                                  ? null
                                  : '\u2014',
                              unit: 'h',
                              decimals: 1,
                              subtitle:
                                  '${summary.sleepNights} recorded nights',
                              trendValue: _calculateTrendDouble(
                                summary.avgSleep,
                                summary.prevAvgSleep,
                              ),
                            ),
                            _StatCard(
                              title: 'Calories logged',
                              icon: Icons.local_fire_department_rounded,
                              numericValue: summary.foodDays > 0
                                  ? summary.avgCalories.toDouble()
                                  : null,
                              primaryValue: summary.foodDays > 0
                                  ? null
                                  : '\u2014',
                              subtitle:
                                  '${summary.foodDays} food-log days \u00b7 avg kcal${summary.incompleteFoodDays > 0 ? ' · ${summary.incompleteFoodDays} incomplete excluded' : ''}',
                              trendValue: _calculateTrendInt(
                                summary.avgCalories,
                                summary.prevAvgCalories,
                              ),
                            ),
                            _StatCard(
                              title: 'Weight',
                              icon: Icons.monitor_weight_rounded,
                              primaryValue: summary.weightMeasurements < 2
                                  ? '\u2014'
                                  : '${summary.weightDelta > 0 ? '+' : ''}${summary.weightDelta.toStringAsFixed(1)} ${summary.useKg ? 'kg' : 'lb'}',
                              subtitle: summary.weightMeasurements < 2
                                  ? 'Need two measurements'
                                  : 'Change across ${summary.weightMeasurements} measurements',
                            ),
                          ]
                          .animate(interval: Motion.instant)
                          .fade(delay: Motion.deliberate)
                          .scale(begin: const Offset(0.9, 0.9));
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (final card in cards)
                        SizedBox(width: width, child: card),
                    ],
                  );
                },
              ),
              const SizedBox(height: Spacing.section),
              // Share Section
              if (summary.hasScoreData)
                _WeeklyShareSection(
                  summary: summary,
                  titleText: titleText,
                ).animate().fade(delay: Motion.deliberate),
              const SizedBox(height: Spacing.section),
            ],
          ),
        ),
      ),
    );
  }

  String? _calculateTrendInt(int current, int? prev) {
    if (prev == null || prev == 0) return null;
    final diff = current - prev;
    if (diff == 0) return null;
    final sign = diff > 0 ? '+' : '';
    return '$sign$diff';
  }

  String? _calculateTrendDouble(
    double current,
    double? prev, {
    bool isPercent = false,
  }) {
    if (prev == null || prev == 0) return null;
    final diff = current - prev;
    if (diff.abs() < (isPercent ? 0.005 : 0.05)) return null;
    final sign = diff > 0 ? '+' : '';
    if (isPercent) {
      return '$sign${(diff * 100).round()} pp';
    }
    return '$sign${diff.toStringAsFixed(1)}';
  }
}

class _ScoreHeroCard extends StatelessWidget {
  final WeeklySummary summary;
  const _ScoreHeroCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final score = summary.weekScore;
    final prevScore = summary.previousWeekScore;
    final dailyScores = summary.dailyScores;
    String message;
    if (!summary.hasScoreData) {
      message = summary.isFutureWeek
          ? 'This week is ahead'
          : 'Log a day to get started';
    } else if (summary.isPartialWeek) {
      message = 'Your week is still in progress';
    } else if (summary.scoreDays < summary.elapsedDays) {
      message = 'Based on your scored days';
    } else if (score >= 90) {
      message = 'Crushing it!';
    } else if (score >= 70) {
      message = 'Great week!';
    } else if (score >= 50) {
      message = 'Good effort!';
    } else {
      message = 'Room to grow';
    }

    // Check for perfect week (all elapsed days >= 80)
    int elapsedDays = 0;
    for (var s in dailyScores) {
      if (s != null) {
        elapsedDays++;
      }
    }
    final isPerfectWeek =
        !summary.isPartialWeek &&
        !summary.isFutureWeek &&
        elapsedDays == 7 &&
        dailyScores.every((score) => score == 100);

    return Container(
      padding: const EdgeInsets.all(Spacing.cardPad),
      child: Column(
        children: [
          if (isPerfectWeek)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: context.colors.green,
                borderRadius: BorderRadius.circular(Radii.chip),
              ),
              child: Text(
                'PERFECT WEEK ✨',
                style: context.text.micro.copyWith(
                  color: context.colors.onPrimary,
                ),
              ),
            )
          else
            Text(
              summary.isPartialWeek ? 'Week Score so far' : 'Week Score',
              style: context.text.body.copyWith(
                color: context.colors.textMedium,
              ),
            ),

          const SizedBox(height: 12),

          Builder(
            builder: (context) {
              final intScore = score;
              Color scoreColor = context.colors.green;
              if (intScore < 50) {
                scoreColor = context.colors.red;
              } else if (intScore < 80)
                scoreColor = context.colors.orange;

              if (!summary.hasScoreData) scoreColor = context.colors.textMedium;
              if (isPerfectWeek) scoreColor = context.colors.green;

              return Column(
                children: [
                  Text(
                    summary.hasScoreData ? '$intScore' : '\u2014',
                    style: AppTheme.numeric(
                      context.text.metric.copyWith(color: scoreColor),
                    ),
                  ),
                  if (summary.hasScoreData) ...[
                    const SizedBox(height: 8),
                    Text('of 100', style: context.text.caption),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: context.text.cardTitle.copyWith(
                      color: context.colors.textDark,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),
          Text(
            '${summary.scoreDays} of ${summary.elapsedDays} elapsed days scored',
            textAlign: TextAlign.center,
            style: context.text.caption,
          ),
          if (prevScore != null) ...[
            const SizedBox(height: 20),
            _DeltaChip(
              current: score,
              previous: prevScore,
              label: 'vs previous completed week',
            ),
          ],
        ],
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({
    required this.current,
    required this.previous,
    required this.label,
  });

  final int current;
  final int previous;
  final String label;

  @override
  Widget build(BuildContext context) {
    final diff = current - previous;
    if (diff == 0) return const SizedBox.shrink();

    final isPositive = diff > 0;
    final color = isPositive ? context.colors.green : context.colors.red;
    final icon = isPositive
        ? Icons.arrow_drop_up_rounded
        : Icons.arrow_drop_down_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Radii.control),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          Flexible(
            child: Text(
              '${diff.abs()} $label',
              style: AppTheme.numeric(
                context.text.caption.copyWith(color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightsStrip extends StatelessWidget {
  final WeeklySummary summary;
  const _InsightsStrip({required this.summary});

  @override
  Widget build(BuildContext context) {
    final insights = <String>[];

    if (summary.hasHabitRecords &&
        (summary.habitCompletionRate > .8 ||
            summary.habitCompletionRate < .4)) {
      insights.add(
        '${summary.completedHabitInstances} of ${summary.scheduledHabitInstances} scheduled habits completed; ${summary.recordedHabitInstances} entries recorded.',
      );
    }

    if (summary.workoutsCompleted == summary.workoutsTotal &&
        summary.workoutsTotal > 0) {
      insights.add(
        summary.isPartialWeek
            ? 'Completed every training session scheduled so far.'
            : 'Completed every planned training session.',
      );
    }

    if (summary.sleepNights >= 3 &&
        summary.nightsUnder7h == 0 &&
        summary.avgSleep >= 7) {
      insights.add(
        'All ${summary.sleepNights} recorded nights were at least 7 hours.',
      );
    }

    if (insights.isEmpty) {
      insights.add(
        summary.scheduledHabitInstances > 0 && !summary.hasHabitRecords
            ? 'No habit entries recorded for this period.'
            : summary.hasScoreData
            ? 'Scores reflect your logged activity and current plan.'
            : 'No scored activity recorded yet. Missing days stay unscored.',
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.lavender.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(Radii.chip),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: context.colors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insights.first,
              style: context.text.caption.copyWith(
                color: context.colors.accentText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyScoresChartCard extends ConsumerStatefulWidget {
  final List<int?> dailyScores;
  final DateTime startOfWeek;
  const _DailyScoresChartCard({
    required this.dailyScores,
    required this.startOfWeek,
  });
  @override
  ConsumerState<_DailyScoresChartCard> createState() =>
      _DailyScoresChartCardState();
}

class _DailyScoresChartCardState extends ConsumerState<_DailyScoresChartCard> {
  int? selected;
  @override
  Widget build(BuildContext context) {
    final today = ref.watch(clockProvider);
    final todayDate = DateTime(today.year, today.month, today.day);
    final points = List.generate(
      7,
      (i) => ChartDataPoint(
        DateTime(
          widget.startOfWeek.year,
          widget.startOfWeek.month,
          widget.startOfWeek.day + i,
        ),
        widget.dailyScores[i]?.toDouble(),
      ),
    );
    final canOpen =
        selected != null && !points[selected!].date.isAfter(todayDate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SharedChartCard(
          metric: const MetricSpec(
            title: 'Daily scores',
            unit: 'points',
            isCount: true,
            plotType: ChartPlotType.bar,
          ),
          data: points,
          startDate: points.first.date,
          endDate: points.last.date,
          timeFormat: ChartTimeFormat.weekly,
          minY: 0,
          maxY: 100,
          statLabels: const [],
          statValues: const [],
          emptyMessage: 'No scored days yet.',
          selectedDate: selected == null ? null : points[selected!].date,
          onPointTap: (point) =>
              setState(() => selected = points.indexOf(point)),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              tooltip: 'Previous day score',
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: selected != null && selected! > 0
                  ? () => setState(() => selected = selected! - 1)
                  : null,
            ),
            IconButton(
              tooltip: 'Next day score',
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: selected == null || selected! < 6
                  ? () => setState(
                      () => selected = selected == null ? 0 : selected! + 1,
                    )
                  : null,
            ),
            TextButton(
              onPressed: !canOpen
                  ? null
                  : () {
                      ref.read(selectedDateProvider.notifier).state =
                          points[selected!].date;
                      context.pop();
                    },
              child: Text(
                selected == null
                    ? 'Select a day'
                    : canOpen
                    ? 'View day'
                    : 'Upcoming day',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HabitChartCard extends ConsumerStatefulWidget {
  const _HabitChartCard({
    required this.rates,
    required this.totals,
    required this.completed,
    required this.recorded,
    required this.startOfWeek,
  });
  final List<double> rates;
  final List<int> totals, completed, recorded;
  final DateTime startOfWeek;
  @override
  ConsumerState<_HabitChartCard> createState() => _HabitChartCardState();
}

class _HabitChartCardState extends ConsumerState<_HabitChartCard> {
  int? selected;
  int _count(List<int> values, int index) =>
      index < values.length ? values[index] : 0;
  DateTime _day(int index) => DateTime(
    widget.startOfWeek.year,
    widget.startOfWeek.month,
    widget.startOfWeek.day + index,
  );
  String _description(int index, DateTime today) {
    if (_day(index).isAfter(today)) return 'Upcoming day';
    final total = _count(widget.totals, index);
    final recorded = _count(widget.recorded, index);
    if (total == 0) return 'No habits scheduled';
    if (recorded == 0) return 'No entries recorded · $total scheduled';
    return '${_count(widget.completed, index)} of $total completed · $recorded recorded';
  }

  @override
  Widget build(BuildContext context) {
    final clock = ref.watch(clockProvider);
    final today = DateTime(clock.year, clock.month, clock.day);
    final points = List.generate(
      7,
      (index) => ChartDataPoint(
        _day(index),
        _count(widget.totals, index) > 0 &&
                _count(widget.recorded, index) > 0 &&
                !_day(index).isAfter(today)
            ? widget.rates[index] * 100
            : null,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SharedChartCard(
          key: const ValueKey('weekly-habit-chart'),
          metric: const MetricSpec(
            title: 'Habit completion',
            unit: '%',
            isCount: true,
            plotType: ChartPlotType.bar,
          ),
          data: points,
          startDate: points.first.date,
          endDate: points.last.date,
          timeFormat: ChartTimeFormat.weekly,
          minY: 0,
          maxY: 100,
          statLabels: const [],
          statValues: const [],
          emptyMessage: 'No habit entries recorded this week.',
          selectedDate: selected == null ? null : points[selected!].date,
          onPointTap: (point) =>
              setState(() => selected = points.indexOf(point)),
        ),
        if (selected != null) ...[
          const SizedBox(height: Spacing.block),
          Semantics(
            liveRegion: true,
            child: Text(
              '${DateFormat('EEEE, d MMM').format(_day(selected!))} · ${_description(selected!, today)}',
              key: const ValueKey('weekly-habit-readout'),
              style: context.text.body,
            ),
          ),
        ],
        ExpansionTile(
          key: const ValueKey('weekly-habit-records'),
          tilePadding: EdgeInsets.zero,
          title: Text('Daily habit records', style: context.text.bodyStrong),
          subtitle: Text(
            'Completed, recorded and scheduled counts',
            style: context.text.caption,
          ),
          children: [
            for (var index = 0; index < 7; index++)
              ListTile(
                key: ValueKey('weekly-habit-day-$index'),
                contentPadding: EdgeInsets.zero,
                title: Text(DateFormat('EEEE, d MMM').format(_day(index))),
                subtitle: Text(_description(index, today)),
                selected: selected == index,
                onTap: () => setState(() => selected = index),
              ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? primaryValue;
  final double? numericValue;
  final String? unit;
  final int decimals;
  final String subtitle;
  final String? trendValue;

  const _StatCard({
    required this.title,
    required this.icon,
    this.primaryValue,
    this.numericValue,
    this.unit,
    this.decimals = 0,
    required this.subtitle,
    this.trendValue,
  });

  @override
  Widget build(BuildContext context) {
    final trendColor = context.colors.textMedium;

    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      padding: const EdgeInsets.all(Spacing.cardPadTight),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: context.colors.lavender,
                  borderRadius: BorderRadius.circular(Radii.micro),
                ),
                child: Icon(icon, size: 16, color: context.colors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: context.text.caption.copyWith(
                    color: context.colors.textMedium,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.block),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              if (numericValue != null)
                Builder(
                  builder: (context) {
                    final display =
                        '${numericValue!.toStringAsFixed(decimals)}${unit ?? ''}';
                    return Text(
                      display,
                      style: AppTheme.numeric(
                        context.text.screenTitle.copyWith(
                          color: context.colors.textDark,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                )
              else
                Text(
                  primaryValue ?? '',
                  style: AppTheme.numeric(
                    context.text.screenTitle.copyWith(
                      color: context.colors.textDark,
                    ),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (trendValue != null) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: Text(
                    trendValue!,
                    style: AppTheme.numeric(
                      context.text.micro.copyWith(color: trendColor),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: context.text.micro.copyWith(color: context.colors.textLight),
          ),
        ],
      ),
    );
  }
}

class _WeeklyShareSection extends ConsumerStatefulWidget {
  final WeeklySummary summary;
  final String titleText;

  const _WeeklyShareSection({required this.summary, required this.titleText});

  @override
  ConsumerState<_WeeklyShareSection> createState() =>
      _WeeklyShareSectionState();
}

class _WeeklyShareSectionState extends ConsumerState<_WeeklyShareSection> {
  bool _isSharing = false;

  void _shareImage(
    BuildContext context,
    WeeklySummary summary,
    String title,
    String name,
  ) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      Color baseColor = context.colors.green;
      if (summary.weekScore < 50) {
        baseColor = context.colors.red;
      } else if (summary.weekScore < 80)
        baseColor = context.colors.orange;

      final layout = WeeklyShareLayout(
        format: ShareFormat.post,
        userName: name,
        dateRange: title,
        weekScore: summary.weekScore,
        prevWeekScore: summary.previousWeekScore,
        dailyScores: summary.dailyScores,
        workoutsCompleted: summary.workoutsCompleted,
        workoutsTotal: summary.workoutsTotal,
        avgSteps: summary.avgSteps,
        habitCompletionPercent: summary.hasHabitRecords
            ? (summary.habitCompletionRate * 100).round()
            : null,
        stepsDays: summary.stepsDays,
        scoreDays: summary.scoreDays,
        elapsedDays: summary.elapsedDays,
        scheduledHabitInstances: summary.scheduledHabitInstances,
        recordedHabitInstances: summary.recordedHabitInstances,
        isPartialWeek: summary.isPartialWeek,
        baseColor: baseColor,
      );

      final result = await ShareCardExporter.exportAndShareWidget(
        context: context,
        widget: layout,
        fileName: 'sthira_weekly_summary',
        text: summary.generateShareText(),
        format: ShareFormat.post,
      );
      if (result == ShareExportResult.success && mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Weekly summary shared successfully!')),
        );
      } else if ((result == ShareExportResult.failed ||
              result == ShareExportResult.unavailable) &&
          mounted &&
          context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The summary could not be shared. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _shareText() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null && box.hasSize
          ? box.localToGlobal(Offset.zero) & box.size
          : null;
      // ignore: deprecated_member_use
      final result = await Share.share(
        widget.summary.generateShareText(),
        sharePositionOrigin: origin,
      );
      if (result.status == ShareResultStatus.unavailable && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sharing is unavailable. Please try again.'),
          ),
        );
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The summary could not be shared. Please try again.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(profileProvider).name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrimaryButton(
          onPressed: () =>
              _shareImage(context, widget.summary, widget.titleText, name),
          isLoading: _isSharing,
          icon: Icons.ios_share_rounded,
          label: _isSharing ? 'Generating...' : 'Share Summary Image',
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isSharing ? null : _shareText,
          child: Text(
            'Share as text',
            style: context.text.body.copyWith(color: context.colors.textMedium),
          ),
        ),
      ],
    );
  }
}
