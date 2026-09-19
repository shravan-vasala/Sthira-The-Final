import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../models/yearly_activity.dart';
import '../../../providers/app_providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_bottom_sheet.dart';
import '../../../widgets/surface_card.dart';

String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
Color _heatColor(BuildContext context, int intensity) {
  if (intensity == 0) return context.colors.border.withValues(alpha: .65);
  return Color.alphaBlend(
    context.colors.primary.withValues(
      alpha: [0.0, .30, .52, .76, 1.0][intensity.clamp(0, 4)],
    ),
    context.colors.insetSurface,
  );
}

String _areaLabel(ActivityArea area, String? status) => switch (area) {
  ActivityArea.habits => 'Habits recorded',
  ActivityArea.workouts => switch (status) {
    'skipped' => 'Workout marked skipped',
    'partial' => 'Workout finished early',
    'completed' => 'Workout completed',
    _ => 'Workout recorded',
  },
  ActivityArea.meals => 'Meals recorded',
  ActivityArea.wellbeing => 'Wellbeing recorded',
};

class ActivityHeatmap extends ConsumerWidget {
  const ActivityHeatmap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(selectedYearProvider);
    final now = ref.watch(clockProvider);
    final activity = ref.watch(yearlyActivityHeatmapProvider(year));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Previous year',
              onPressed: year > 1
                  ? () => ref.read(selectedYearProvider.notifier).state--
                  : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '$year',
                  style: context.text.display,
                  semanticsLabel: 'Activity for $year',
                ),
              ),
            ),
            IconButton(
              tooltip: 'Next year',
              onPressed: year < now.year
                  ? () => ref.read(selectedYearProvider.notifier).state++
                  : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        if (year != now.year)
          Center(
            child: TextButton(
              onPressed: () =>
                  ref.read(selectedYearProvider.notifier).state = now.year,
              child: const Text('Current year'),
            ),
          ),
        const SizedBox(height: Spacing.block),
        activity.when(
          data: (data) => _YearOverview(data: data),
          loading: () => const Padding(
            padding: EdgeInsets.all(Spacing.major),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => SurfaceCard(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                Text(
                  'Your activity could not be loaded.',
                  style: context.text.body,
                ),
                const SizedBox(height: Spacing.inline),
                TextButton.icon(
                  onPressed: () =>
                      ref.invalidate(yearlyActivityHeatmapProvider(year)),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _YearOverview extends StatelessWidget {
  const _YearOverview({required this.data});
  final YearlyActivity data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SurfaceCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(Spacing.cardPadTight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your year at a glance', style: context.text.cardTitle),
              const SizedBox(height: Spacing.textPair),
              Text(
                'Tap a month to explore.',
                style: context.text.caption.copyWith(
                  color: context.colors.textMedium,
                ),
              ),
              const SizedBox(height: Spacing.section),
              LayoutBuilder(
                builder: (context, constraints) {
                  final largeText =
                      MediaQuery.textScalerOf(context).scale(13) > 20;
                  final columns = constraints.maxWidth >= 600 && !largeText
                      ? 4
                      : constraints.maxWidth >= 280 && !largeText
                      ? 3
                      : 2;
                  final width =
                      (constraints.maxWidth - Spacing.block * (columns - 1)) /
                      columns;
                  return Wrap(
                    spacing: Spacing.block,
                    runSpacing: Spacing.block,
                    children: [
                      for (var month = 1; month <= 12; month++)
                        SizedBox(
                          width: width,
                          child: _MonthTile(data: data, month: month),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: Spacing.section),
              const _HeatLegend(),
            ],
          ),
        ),
        const SizedBox(height: Spacing.section),
        SurfaceCard(
          margin: EdgeInsets.zero,
          color: Color.alphaBlend(
            context.colors.primary.withValues(alpha: .07),
            context.colors.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DAYS RECORDED', style: context.text.eyebrow),
              const SizedBox(height: Spacing.inline),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: Spacing.stack,
                children: [
                  Semantics(
                    key: const ValueKey('heatmap-recorded-days'),
                    label: '${data.recordedDays} days recorded in ${data.year}',
                    excludeSemantics: true,
                    child: Text(
                      '${data.recordedDays}',
                      style: context.text.metric.copyWith(
                        color: context.colors.accentText,
                      ),
                    ),
                  ),
                  Text(
                    data.year == data.today.year
                        ? 'so far this year'
                        : 'in ${data.year}',
                    style: context.text.caption.copyWith(
                      color: context.colors.textMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.block),
              Divider(color: context.colors.divider, height: 1),
              const SizedBox(height: Spacing.block),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stats = [
                    _Stat(
                      label: 'Longest run',
                      value:
                          '${data.longestStreak} ${data.longestStreak == 1 ? 'day' : 'days'}',
                    ),
                    _Stat(
                      label: 'Months recorded',
                      value: '${data.recordedMonths} of 12',
                    ),
                  ];
                  if (MediaQuery.textScalerOf(context).scale(13) > 20) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        stats[0],
                        const SizedBox(height: Spacing.block),
                        stats[1],
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: stats[0]),
                      const SizedBox(width: Spacing.block),
                      Expanded(child: stats[1]),
                    ],
                  );
                },
              ),
              if (data.recordedDays == 0) ...[
                const SizedBox(height: Spacing.block),
                Text(
                  'No entries recorded this year.',
                  style: context.text.caption,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: context.text.bodyStrong),
      const SizedBox(height: Spacing.textPair),
      Text(
        label,
        style: context.text.caption.copyWith(color: context.colors.textMedium),
      ),
    ],
  );
}

class _MonthTile extends StatelessWidget {
  const _MonthTile({required this.data, required this.month});
  final YearlyActivity data;
  final int month;
  @override
  Widget build(BuildContext context) {
    final date = DateTime(data.year, month);
    final count = data.recordedInMonth(month);
    final current = data.year == data.today.year && month == data.today.month;
    final future = date.isAfter(data.today);
    void openMonth() => showAppBottomSheet(
      context: context,
      builder: (_) => _MonthDetail(year: data.year, month: month),
    );
    return Semantics(
      key: ValueKey('heatmap-month-$month'),
      label: '${DateFormat.yMMMM().format(date)}, $count days recorded',
      button: true,
      onTap: openMonth,
      excludeSemantics: true,
      child: InkWell(
        onTap: openMonth,
        excludeFromSemantics: true,
        borderRadius: BorderRadius.circular(Radii.micro),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat.MMM().format(date),
              style: context.text.bodyStrong.copyWith(
                color: current
                    ? context.colors.accentText
                    : future
                    ? context.colors.textLight
                    : context.colors.textDark,
              ),
            ),
            const SizedBox(height: Spacing.inline),
            AspectRatio(
              aspectRatio: 7 / 6,
              child: CustomPaint(
                painter: _MonthPainter(
                  year: data.year,
                  month: month,
                  today: data.today,
                  days: data.days,
                  colors: List.generate(5, (i) => _heatColor(context, i)),
                  futureColor: context.colors.border.withValues(alpha: .5),
                  todayColor: context.colors.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Overview cells are visual marks; the whole month is the accessible target.
class _MonthPainter extends CustomPainter {
  _MonthPainter({
    required this.year,
    required this.month,
    required this.today,
    required this.days,
    required this.colors,
    required this.futureColor,
    required this.todayColor,
  });
  final int year;
  final int month;
  final DateTime today;
  final Map<DateTime, ActivityDay> days;
  final List<Color> colors;
  final Color futureColor;
  final Color todayColor;
  @override
  void paint(Canvas canvas, Size size) {
    final offset = DateTime(year, month).weekday - DateTime.monday;
    final count = DateUtils.getDaysInMonth(year, month);
    final step = size.width / 7;
    final cell = math.min(step - Gap.x2, size.height / 6 - Gap.x2);
    for (var day = 1; day <= count; day++) {
      final date = DateTime(year, month, day);
      final index = offset + day - 1;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          (index % 7) * step + 1,
          (index ~/ 7) * (size.height / 6) + 1,
          cell,
          cell,
        ),
        const Radius.circular(Radii.micro / 2),
      );
      final future = date.isAfter(today);
      canvas.drawRRect(
        rect,
        Paint()
          ..color = future ? futureColor : colors[days[date]?.intensity ?? 0]
          ..style = future ? PaintingStyle.stroke : PaintingStyle.fill
          ..strokeWidth = 1,
      );
      if (DateUtils.isSameDay(date, today)) {
        canvas.drawRRect(
          rect.deflate(1),
          Paint()
            ..color = todayColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MonthPainter old) =>
      old.days != days ||
      old.year != year ||
      old.month != month ||
      old.today != today ||
      old.colors[0] != colors[0] ||
      old.colors[4] != colors[4];
}

class _HeatLegend extends StatelessWidget {
  const _HeatLegend();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: Spacing.inline,
        runSpacing: Spacing.inline,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Areas logged', style: context.text.micro),
          for (var value = 1; value <= 4; value++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: Gap.x12,
                  height: Gap.x12,
                  decoration: BoxDecoration(
                    color: _heatColor(context, value),
                    borderRadius: BorderRadius.circular(Radii.micro / 2),
                  ),
                ),
                const SizedBox(width: Gap.x4),
                Text('$value', style: context.text.micro),
              ],
            ),
        ],
      ),
      const SizedBox(height: Spacing.inline),
      Text(
        'Habits · Workouts · Meals · Wellbeing',
        style: context.text.micro.copyWith(color: context.colors.textMedium),
      ),
      const SizedBox(height: Spacing.inline),
      Wrap(
        spacing: Spacing.block,
        runSpacing: Spacing.inline,
        children: [
          _LegendState(label: 'No entries', color: _heatColor(context, 0)),
          _LegendState(
            label: 'Future',
            color: context.colors.border,
            outlined: true,
          ),
        ],
      ),
    ],
  );
}

class _LegendState extends StatelessWidget {
  const _LegendState({
    required this.label,
    required this.color,
    this.outlined = false,
  });
  final String label;
  final Color color;
  final bool outlined;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: Gap.x12,
        height: Gap.x12,
        decoration: BoxDecoration(
          color: outlined ? null : color,
          border: outlined ? Border.all(color: color) : null,
          borderRadius: BorderRadius.circular(Radii.micro / 2),
        ),
      ),
      const SizedBox(width: Gap.x4),
      Text(
        label,
        style: context.text.micro.copyWith(color: context.colors.textMedium),
      ),
    ],
  );
}

class _MonthDetail extends ConsumerStatefulWidget {
  const _MonthDetail({required this.year, required this.month});
  final int year;
  final int month;
  @override
  ConsumerState<_MonthDetail> createState() => _MonthDetailState();
}

class _MonthDetailState extends ConsumerState<_MonthDetail> {
  late DateTime _selected;
  @override
  void initState() {
    super.initState();
    final now = ref.read(clockProvider);
    _selected = DateTime(
      widget.year,
      widget.month,
      widget.year == now.year && widget.month == now.month ? now.day : 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final activity = ref.watch(yearlyActivityHeatmapProvider(widget.year));
    return AppSheet(
      title: DateFormat.yMMMM().format(DateTime(widget.year, widget.month)),
      child: activity.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => TextButton(
          onPressed: () =>
              ref.invalidate(yearlyActivityHeatmapProvider(widget.year)),
          child: const Text('Retry'),
        ),
        data: (data) {
          final selected = data.day(_selected);
          final future = _selected.isAfter(data.today);
          final count = DateUtils.getDaysInMonth(widget.year, widget.month);
          final offset = DateTime(widget.year, widget.month).weekday - 1;
          final rows = ((offset + count) / 7).ceil();
          return Column(
            key: const ValueKey('heatmap-month-detail'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${data.recordedInMonth(widget.month)} days recorded',
                style: context.text.caption.copyWith(
                  color: context.colors.textMedium,
                ),
              ),
              const SizedBox(height: Spacing.block),
              Row(
                children: [
                  for (final label in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                    Expanded(
                      child: Center(
                        child: Text(label, style: context.text.micro),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: Spacing.inline),
              for (var row = 0; row < rows; row++)
                Row(
                  children: [
                    for (var column = 0; column < 7; column++)
                      Expanded(
                        child: _dayCell(
                          context,
                          data,
                          row * 7 + column - offset + 1,
                          count,
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: Spacing.section),
              SurfaceCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(Spacing.cardPadTight),
                color: context.colors.insetSurface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, d MMMM').format(_selected),
                      key: const ValueKey('heatmap-selected-date'),
                      style: context.text.bodyStrong,
                    ),
                    const SizedBox(height: Spacing.inline),
                    if (future)
                      Text('This day is ahead.', style: context.text.caption)
                    else if (!selected.hasEntries)
                      Text('No entries recorded.', style: context.text.caption)
                    else
                      for (final area in ActivityArea.values)
                        if (selected.areas.contains(area))
                          Padding(
                            padding: const EdgeInsets.only(bottom: Gap.x4),
                            child: Text(
                              _areaLabel(area, selected.workoutStatus),
                              style: context.text.caption,
                            ),
                          ),
                    if (!future) ...[
                      const SizedBox(height: Spacing.inline),
                      TextButton.icon(
                        onPressed: () {
                          final router = GoRouter.of(context);
                          ref.read(selectedDateProvider.notifier).state =
                              _selected;
                          final monday = DateTime(
                            _selected.year,
                            _selected.month,
                            _selected.day - _selected.weekday + 1,
                          );
                          final todayMonday = DateTime(
                            data.today.year,
                            data.today.month,
                            data.today.day - data.today.weekday + 1,
                          );
                          ref.read(weekOffsetProvider.notifier).state =
                              DateTime.utc(
                                    monday.year,
                                    monday.month,
                                    monday.day,
                                  )
                                  .difference(
                                    DateTime.utc(
                                      todayMonday.year,
                                      todayMonday.month,
                                      todayMonday.day,
                                    ),
                                  )
                                  .inDays ~/
                              7;
                          Navigator.of(context).pop();
                          router.go('/home');
                        },
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('View day'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _dayCell(
    BuildContext context,
    YearlyActivity data,
    int number,
    int count,
  ) {
    if (number < 1 || number > count) return const SizedBox.shrink();
    final date = DateTime(widget.year, widget.month, number);
    final future = date.isAfter(data.today);
    final day = data.day(date);
    final selected = date == _selected;
    final scaler = MediaQuery.textScalerOf(context);
    final height = math.max(48.0, scaler.scale(15) * 1.45 + Spacing.inline);
    void select() => setState(() => _selected = date);
    return Semantics(
      key: ValueKey('heatmap-day-${_dateKey(date)}'),
      label:
          '${DateFormat.yMMMMEEEEd().format(date)}, ${future
              ? 'Future date'
              : day.hasEntries
              ? '${day.intensity} areas recorded'
              : 'No entries recorded'}',
      button: true,
      enabled: !future,
      selected: selected,
      onTap: future ? null : select,
      excludeSemantics: true,
      child: InkWell(
        onTap: future ? null : select,
        excludeFromSemantics: true,
        borderRadius: BorderRadius.circular(Radii.micro),
        child: Container(
          height: height,
          margin: const EdgeInsets.symmetric(vertical: Gap.x2),
          decoration: BoxDecoration(
            color: selected
                ? context.colors.primary
                : future
                ? null
                : day.hasEntries
                ? _heatColor(context, day.intensity).withValues(alpha: .25)
                : null,
            borderRadius: BorderRadius.circular(Radii.micro),
            border: !selected && DateUtils.isSameDay(date, data.today)
                ? Border.all(color: context.colors.primary)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$number',
                maxLines: 1,
                softWrap: false,
                style: context.text.body.copyWith(
                  color: selected
                      ? context.colors.onPrimary
                      : future
                      ? context.colors.textLight
                      : context.colors.textDark,
                ),
              ),
              if (day.hasEntries)
                Container(
                  width: Gap.x4,
                  height: Gap.x4,
                  decoration: BoxDecoration(
                    color: selected
                        ? context.colors.onPrimary
                        : context.colors.accentText,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
