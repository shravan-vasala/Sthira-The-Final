import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/habit.dart';
import '../../../providers/app_providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_motion.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/layout_insets.dart';
import '../../../widgets/app_bottom_sheet.dart';
import 'daily_score_sheet.dart';
import 'past_day_summary_sheet.dart';

// Listen to all dates, including changes received from another device.
final calendarHabitChangesProvider = StreamProvider.autoDispose<void>((ref) {
  final database = ref.watch(activeDatabaseProvider);
  if (database == null) return const Stream.empty();
  final changes = StreamController<void>();
  final subscriptions = [
    database.habits.watchLazy().listen((_) => changes.add(null)),
    database.habitCompletions.watchLazy().listen((_) => changes.add(null)),
  ];
  ref.onDispose(() {
    for (final subscription in subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(changes.close());
  });
  return changes.stream;
});

/// A dot means an entry was logged, not that every goal was completed.
final calendarWeekActivityProvider = Provider.autoDispose
    .family<Map<String, bool>, String>((ref, weekStartStr) {
      ref.watch(accountGenerationProvider);
      ref.watch(dailyLogsUpdateProvider);
      ref.watch(dailyMealLogsUpdateProvider);
      ref.watch(exerciseRecordsUpdateProvider);
      ref.watch(exerciseLogsUpdateProvider);
      ref.watch(calendarHabitChangesProvider);
      final weekStart = DateTime.parse(weekStartStr);
      final dailyLogRepo = ref.watch(dailyLogRepoProvider);
      final mealRepo = ref.watch(mealRepoProvider);
      final habitRepo = ref.watch(habitRepoProvider);
      final exerciseRepo = ref.watch(exerciseLogRepoProvider);
      final habits = habitRepo.getHabits();
      return {
        for (var i = 0; i < 7; i++)
          DateFormat('yyyy-MM-dd').format(_addDays(weekStart, i)): (() {
            final date = _addDays(weekStart, i);
            final key = DateFormat('yyyy-MM-dd').format(date);
            final completions = habitRepo.getCompletions(key);
            return dailyLogRepo.hasActivityOnDate(key) ||
                mealRepo.getDailyLog(key).loggedSlotsCount > 0 ||
                exerciseRepo.getLogsForDate(key).isNotEmpty ||
                habits.any(
                  (habit) =>
                      !_dateOnly(habit.createdAt).isAfter(date) &&
                      (habit.activeDays == null ||
                          habit.activeDays!.contains(date.weekday)) &&
                      (completions.completions.containsKey(habit.id) ||
                          completions.overrides.containsKey(habit.id)),
                );
          })(),
      };
    });

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
DateTime _addDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);
DateTime _monday(DateTime date) => _addDays(date, 1 - date.weekday);
int _weeksBetween(DateTime date, DateTime anchor) {
  final monday = _monday(date);
  final start = _monday(anchor);
  // Calendar arithmetic must not lose a day across daylight-saving boundaries.
  return DateTime.utc(
        monday.year,
        monday.month,
        monday.day,
      ).difference(DateTime.utc(start.year, start.month, start.day)).inDays ~/
      7;
}

class WeekCalendarStrip extends ConsumerStatefulWidget {
  const WeekCalendarStrip({super.key});
  @override
  ConsumerState<WeekCalendarStrip> createState() => _WeekCalendarStripState();
}

class _WeekCalendarStripState extends ConsumerState<WeekCalendarStrip> {
  static const _basePage = 10000;
  late final DateTime _anchorWeek;
  late final PageController _pageController;
  int? _targetPage;
  bool _updatingFromSwipe = false;

  @override
  void initState() {
    super.initState();
    _anchorWeek = _monday(ref.read(clockProvider));
    _pageController = PageController(
      initialPage: _basePage + ref.read(weekOffsetProvider),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showWeek(DateTime date) {
    final target = _basePage + _weeksBetween(date, _anchorWeek);
    if (!_pageController.hasClients ||
        _targetPage == target ||
        (_pageController.page! - target).abs() < .01)
      return;
    _targetPage = target;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pageController.jumpToPage(target);
      _targetPage = null;
    } else {
      _pageController
          .animateToPage(target, duration: Motion.standard, curve: Motion.enter)
          .whenComplete(() {
            if (_targetPage == target) _targetPage = null;
          });
    }
  }

  void _selectDate(DateTime date) {
    ref.read(selectedDateProvider.notifier).state = _dateOnly(date);
    ref.read(weekOffsetProvider.notifier).state = _weeksBetween(
      date,
      ref.read(clockProvider),
    );
    _showWeek(date);
  }

  Future<void> _pickDate() async {
    final selected = ref.read(selectedDateProvider);
    final now = ref.read(clockProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: selected,
      firstDate: DateTime(math.min(1900, selected.year)),
      lastDate: DateTime(math.max(now.year + 10, selected.year), 12, 31),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: context.colors.primary,
            surface: context.colors.card,
            onSurface: context.colors.textDark,
          ),
          dialogTheme: DialogThemeData(backgroundColor: context.colors.card),
        ),
        child: child!,
      ),
    );
    if (mounted && picked != null) _selectDate(picked);
  }

  String _weekLabel(DateTime start, DateTime today, int offset) {
    if (offset == 0) return 'This week';
    final end = _addDays(start, 6);
    if (start.year != today.year || end.year != today.year) {
      return '${DateFormat('d MMM y').format(start)} – ${DateFormat('d MMM y').format(end)}';
    }
    if (start.month == end.month) {
      return '${start.day}–${DateFormat('d MMM').format(end)}';
    }
    return '${DateFormat('d MMM').format(start)} – ${DateFormat('d MMM').format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedDateProvider);
    final today = _dateOnly(ref.watch(clockProvider));
    final offset = ref.watch(weekOffsetProvider);
    final weekStart = _addDays(_monday(today), offset * 7);
    ref.listen<int>(weekOffsetProvider, (_, next) {
      if (_updatingFromSwipe) return;
      _showWeek(_addDays(_monday(ref.read(clockProvider)), next * 7));
    });
    ref.listen<DateTime>(selectedDateProvider, (_, next) {
      ref.read(weekOffsetProvider.notifier).state = _weeksBetween(
        next,
        ref.read(clockProvider),
      );
      _showWeek(next);
    });
    ref.listen<DateTime>(clockProvider, (_, next) {
      // Midnight/resume may advance today's week while reviewing a past date.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _selectDate(ref.read(selectedDateProvider));
      });
    });

    Widget arrow(bool next) => IconButton(
      tooltip: next ? 'Next week' : 'Previous week',
      onPressed: () =>
          ref.read(weekOffsetProvider.notifier).state += next ? 1 : -1,
      icon: Container(
        padding: const EdgeInsets.all(Gap.x4),
        decoration: BoxDecoration(
          color: context.colors.border.withValues(alpha: .3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          next ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
          color: context.colors.textDark,
          size: IconSize.row,
        ),
      ),
    );
    final label = Tooltip(
      message: 'Choose a date',
      child: InkWell(
        onTap: _pickDate,
        borderRadius: BorderRadius.circular(Radii.chip),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  _weekLabel(weekStart, today, offset),
                  style: context.text.sectionLabel,
                ),
              ),
              const SizedBox(width: Gap.x4),
              Icon(
                Icons.expand_more_rounded,
                size: IconSize.inline,
                color: context.colors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kScreenPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scaler = MediaQuery.textScalerOf(context);
          final stacked = constraints.maxWidth < 260 || scaler.scale(16) > 20;
          final controls = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _DailyScoreBadge(),
              const SizedBox(width: Gap.x4),
              arrow(false),
              arrow(true),
            ],
          );
          final returnToToday = offset != 0
              ? TextButton(
                  onPressed: () => _selectDate(today),
                  child: const Text('Today'),
                )
              : null;
          return Column(
            children: [
              if (stacked) ...[
                Row(
                  children: [
                    Expanded(child: label),
                    if (returnToToday != null) returnToToday,
                  ],
                ),
                Align(alignment: Alignment.centerRight, child: controls),
              ] else ...[
                Row(
                  children: [
                    Expanded(child: label),
                    controls,
                  ],
                ),
                if (returnToToday != null)
                  Align(alignment: Alignment.centerLeft, child: returnToToday),
              ],
              const SizedBox(height: Spacing.stack),
              SizedBox(
                height:
                    scaler.scale(12) * 1.3 +
                    math.max(34, scaler.scale(15) * 1.45 + Gap.x4) +
                    2 * Spacing.inline +
                    Gap.x8,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    if (_targetPage != null && _targetPage != index) return;
                    final visibleWeek = _addDays(
                      _anchorWeek,
                      (index - _basePage) * 7,
                    );
                    // Reflect a swipe without starting a second page animation.
                    _updatingFromSwipe = true;
                    try {
                      ref.read(weekOffsetProvider.notifier).state =
                          _weeksBetween(visibleWeek, ref.read(clockProvider));
                    } finally {
                      _updatingFromSwipe = false;
                    }
                  },
                  itemBuilder: (context, index) => _WeekDaysRow(
                    weekStart: _addDays(_anchorWeek, (index - _basePage) * 7),
                    today: today,
                    selectedDate: selected,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WeekDaysRow extends ConsumerWidget {
  const _WeekDaysRow({
    required this.weekStart,
    required this.today,
    required this.selectedDate,
  });
  final DateTime weekStart;
  final DateTime today;
  final DateTime selectedDate;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(
      calendarWeekActivityProvider(DateFormat('yyyy-MM-dd').format(weekStart)),
    );
    return Row(
      children: List.generate(7, (index) {
        final date = _addDays(weekStart, index);
        return Expanded(
          child: _DayCircle(
            date: date,
            isSelected: DateUtils.isSameDay(date, selectedDate),
            isToday: DateUtils.isSameDay(date, today),
            isFuture: date.isAfter(today),
            hasActivity:
                activity[DateFormat('yyyy-MM-dd').format(date)] ?? false,
          ),
        );
      }),
    );
  }
}

class _DayCircle extends ConsumerWidget {
  const _DayCircle({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.isFuture,
    required this.hasActivity,
  });
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool isFuture;
  final bool hasActivity;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fullDate = DateFormat('EEEE, MMMM d, y').format(date);
    final label =
        '${isToday ? 'Today, ' : ''}$fullDate, ${hasActivity ? 'Activity logged' : 'No entries logged'}';
    final scaler = MediaQuery.textScalerOf(context);
    final dotColor = hasActivity && !isFuture
        ? context.colors.green
        : context.colors.border;
    void selectDate() {
      if (!isSelected) {
        ref.read(selectedDateProvider.notifier).state = date;
      } else if (!isFuture && !isToday) {
        showAppBottomSheet(
          context: context,
          builder: (_) => PastDaySummarySheet(date: date),
        );
      }
    }

    return Semantics(
      label: label,
      button: true,
      selected: isSelected,
      onTap: selectDate,
      excludeSemantics: true,
      child: InkWell(
        onTap: selectDate,
        excludeFromSemantics: true,
        borderRadius: BorderRadius.circular(Radii.chip),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final shortLabel = scaler.scale(12) * 2.5 > constraints.maxWidth;
            return Column(
              children: [
                Text(
                  (shortLabel
                          ? DateFormat.E().format(date).substring(0, 1)
                          : DateFormat.E().format(date))
                      .toUpperCase(),
                  maxLines: 1,
                  style: context.text.micro.copyWith(
                    color: context.colors.textLight,
                  ),
                ),
                const SizedBox(height: Spacing.inline),
                AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : Motion.standard,
                  width: math.min(
                    constraints.maxWidth,
                    math.max(34, scaler.scale(15) * 2),
                  ),
                  height: math.max(34, scaler.scale(15) * 1.45 + Gap.x4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: isSelected
                        ? context.colors.primary
                        : Colors.transparent,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${date.day}',
                    style: context.text.body.copyWith(
                      color: isSelected
                          ? context.colors.onPrimary
                          : isToday
                          ? context.colors.primary
                          : context.colors.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.inline),
                Container(
                  width: Gap.x4,
                  height: Gap.x4,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DailyScoreBadge extends ConsumerStatefulWidget {
  const _DailyScoreBadge();

  @override
  ConsumerState<_DailyScoreBadge> createState() => _DailyScoreBadgeState();
}

class _DailyScoreBadgeState extends ConsumerState<_DailyScoreBadge> {
  @override
  Widget build(BuildContext context) {
    final scoreData = ref.watch(dailyScoreProvider);

    final score = scoreData.totalScore;
    final isFuture = scoreData.isFutureDate;

    final percentage = score.toDouble();

    Color iconColor;
    Color textColor;
    List<Color>? gradientColors;
    final IconData iconData = Icons.local_fire_department_rounded;

    if (isFuture) {
      iconColor = context.colors.textLight;
      textColor = context.colors.textLight;
      gradientColors = null;
    } else if (percentage == 0) {
      iconColor = context.colors.textLight;
      textColor = context.colors.textDark.withValues(alpha: 0.7);
      gradientColors = [
        context.colors.border.withValues(alpha: 0.3),
        context.colors.border.withValues(alpha: 0.1),
      ];
    } else if (percentage < 50) {
      // Starting to warm up
      iconColor = context.colors.orange;
      textColor = context.colors.textDark;
      gradientColors = [
        context.colors.orange.withValues(alpha: 0.15),
        context.colors.orange.withValues(alpha: 0.05),
      ];
    } else if (percentage < 90) {
      // Getting hot!
      iconColor = context.colors.red;
      textColor = context.colors.textDark;
      gradientColors = [
        context.colors.red.withValues(alpha: 0.15),
        context.colors.red.withValues(alpha: 0.05),
      ];
    } else {
      // Top Tier Bodamma Flame!
      iconColor = context.colors.primary;
      textColor = context.colors.primary;
      gradientColors = [
        context.colors.primary.withValues(alpha: 0.25),
        context.colors.primary.withValues(alpha: 0.05),
      ];
    }

    final semanticsLabel = isFuture
        ? 'Daily score unavailable for a future date'
        : 'Daily score for ${DateFormat.yMMMd().format(ref.watch(selectedDateProvider))}: $score out of 100';

    void openScore() => showAppBottomSheet(
      context: context,
      builder: (_) => const DailyScoreSheet(),
    );

    return Semantics(
      label: semanticsLabel,
      button: !isFuture,
      onTap: isFuture ? null : openScore,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: isFuture ? null : openScore,
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.stack,
                vertical: Gap.x4,
              ),
              decoration: BoxDecoration(
                gradient: gradientColors == null
                    ? null
                    : LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: gradientColors == null
                    ? context.colors.border.withValues(alpha: 0.5)
                    : null,
                borderRadius: BorderRadius.circular(20),
                // Sthira: No borders! Let the soft gradient fill float the pill.
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(iconData, size: 16, color: iconColor),
                  const SizedBox(width: 4),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: isFuture ? 0 : score),
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : Motion.deliberate,
                    curve: Motion.enter,
                    builder: (context, value, child) {
                      return Text(
                        isFuture ? '--' : value.toString(),
                        style: context.text.micro.copyWith(color: textColor),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
