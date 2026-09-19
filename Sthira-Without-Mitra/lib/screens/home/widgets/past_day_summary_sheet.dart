import 'package:trufit_bodamma/theme/app_typography.dart';
import 'package:trufit_bodamma/theme/app_colors.dart';
import 'package:trufit_bodamma/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/app_providers.dart';
import '../../../models/habit.dart';
import '../../../models/daily_log.dart';
import '../../../models/daily_meal_log.dart';
import '../../../router/app_router.dart';
import '../../../utils/workout_completion.dart';
import '../../../utils/meal_icons.dart';
import '../../../models/daily_stats_snapshot.dart';
import '../../../widgets/app_bottom_sheet.dart';
import 'day_feeling_card.dart';

// A long-pressed day need not be the globally selected day. Subscribe to the
// sheet's date so reflection edits and incoming updates refresh the right view.
final _summaryDailyLogProvider = StreamProvider.autoDispose
    .family<DailyLog?, String>((ref, date) {
      ref.watch(accountGenerationProvider);
      return ref.watch(dailyLogRepoProvider).watchLog(date);
    });
final _summaryMealLogProvider = StreamProvider.autoDispose
    .family<DailyMealLog?, String>((ref, date) {
      ref.watch(accountGenerationProvider);
      return ref.watch(mealRepoProvider).watchDailyLog(date);
    });
final _summaryCompletionProvider = StreamProvider.autoDispose
    .family<HabitCompletion?, String>((ref, date) {
      ref.watch(accountGenerationProvider);
      return ref.watch(habitRepoProvider).watchCompletions(date);
    });
final _summaryHabitUpdatesProvider = StreamProvider.autoDispose<void>((ref) {
  ref.watch(accountGenerationProvider);
  return ref.watch(habitRepoProvider).watchUpdates;
});

class PastDaySummarySheet extends ConsumerWidget {
  final DateTime date;

  const PastDaySummarySheet({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    ref.watch(accountGenerationProvider);
    ref.watch(_summaryHabitUpdatesProvider);
    ref.watch(exerciseLogsUpdateProvider);
    ref.watch(exerciseRecordsUpdateProvider);

    final dailyLog =
        ref.watch(_summaryDailyLogProvider(dateStr)).valueOrNull ??
        ref.read(dailyLogRepoProvider).getOrCreate(dateStr);
    final mealLog =
        ref.watch(_summaryMealLogProvider(dateStr)).valueOrNull ??
        ref.read(mealRepoProvider).getDailyLog(dateStr);
    final allHabits = ref.read(habitRepoProvider).getHabits();
    final habitCompletions =
        ref.watch(_summaryCompletionProvider(dateStr)).valueOrNull ??
        ref.read(habitRepoProvider).getCompletions(dateStr);

    final applicableHabits = allHabits
        .where((habit) => isHabitScheduledOn(habit, date))
        .toList();

    final workoutPlan = ref.watch(workoutPlanProvider);
    final mealPlan = ref.watch(mealPlanProvider);
    final profile = ref.watch(profileProvider);
    final logRepo = ref.read(exerciseLogRepoProvider);
    final dailyLogRepo = ref.read(dailyLogRepoProvider);

    final stats = DailyStatsSnapshot.compute(
      date: date,
      dateStr: dateStr,
      habits: applicableHabits,
      habitCompletions: habitCompletions,
      dailyLog: dailyLog,
      workoutPlan: workoutPlan,
      hasLog: (d, e) => logRepo.hasLog(d, e),
      mealPlan: mealPlan,
      mealLog: mealLog,
      targetWeight: profile.targetWeight ?? 0,
      dailyLogRepo: dailyLogRepo,
      profile: profile,
    );

    // 1) Compute workout status for UI
    final workoutConfigured = WorkoutCompletion.hasSchedule(workoutPlan);
    String workoutDayName = 'No workout plan selected';
    String? currentWorkoutDayId;

    if (workoutConfigured && workoutPlan != null) {
      workoutDayName = 'Rest Day';
      final workoutDay = WorkoutCompletion.resolveWorkoutDay(
        workoutPlan,
        date,
        planStartDate: profile.planStartDate,
      );
      if (!stats.isRestDay) {
        workoutDayName = workoutDay.label ?? 'Workout Day';
        currentWorkoutDayId = dailyLog.workoutDayId ?? workoutDay.dayId;
      }
    }

    // 2) Compute totals
    final loggedIds = mealLog.customSlots.keys.toSet();
    final List<IconData> loggedIcons = [];
    for (final slotId in loggedIds) {
      final log = mealLog.customSlots[slotId];
      if (log != null && log.isLogged) {
        if (log.emoji != null) {
          loggedIcons.add(MealIcons.resolve(log.emoji));
        } else {
          final profileSlot = profile.customMealSlots.firstWhere(
            (s) => s['id'] == slotId,
            orElse: () => <String, dynamic>{},
          );
          if (profileSlot.isNotEmpty) {
            loggedIcons.add(MealIcons.resolve(profileSlot['emoji'] as String?));
          }
        }
      }
    }

    final completedMeals = stats.mealsLogged;
    final totalMealsTarget = stats.mealsTotal;
    final completedHabits = stats.habitsDone;
    final totalHabitsTarget = stats.habitsTotal;
    final isRestDay = workoutConfigured && stats.isRestDay;
    final workoutRequired =
        workoutConfigured && !isRestDay && stats.workoutsTotal > 0;
    final workoutDayDone =
        workoutRequired && stats.workoutsDone >= stats.workoutsTotal;

    final totalThings =
        totalMealsTarget + totalHabitsTarget + (workoutRequired ? 1 : 0);
    final totalDone =
        completedMeals + completedHabits + (workoutDayDone ? 1 : 0);
    final hasRecords =
        dailyLog.hasAnyActivity ||
        mealLog.loggedSlotsCount > 0 ||
        applicableHabits.any(
          (habit) => hasHabitRecord(habit, habitCompletions, dailyLog),
        ) ||
        logRepo
            .getLogsForDate(dateStr)
            .any(WorkoutCompletion.hasMeaningfulWork);

    // Reflection and partial readings are entries even when no goal was met.
    String statusText = hasRecords ? 'Entries recorded' : 'No entries logged';
    Color statusColor = context.colors.textMedium;
    if (totalThings > 0 && totalDone >= totalThings) {
      statusText = 'Goals complete';
      statusColor = context.colors.green;
    } else if (totalDone > 0) {
      statusText = 'Partially complete';
      statusColor = context.colors.orange;
    } else if (!hasRecords && isRestDay) {
      statusText = 'Rest day';
    }

    final unmetHabits = applicableHabits
        .where(
          (habit) =>
              hasHabitRecord(habit, habitCompletions, dailyLog) &&
              !isHabitCompleted(habit, habitCompletions, dailyLog),
        )
        .map((habit) => habit.name)
        .join(', ');
    final unrecordedHabits = applicableHabits
        .where((habit) => !hasHabitRecord(habit, habitCompletions, dailyLog))
        .map((habit) => habit.name)
        .join(', ');
    final habitSummary = totalHabitsTarget == 0
        ? 'No habits scheduled'
        : completedHabits == totalHabitsTarget
        ? 'All habits completed!'
        : [
            if (unmetHabits.isNotEmpty) 'Not met: $unmetHabits',
            if (unrecordedHabits.isNotEmpty) 'Not recorded: $unrecordedHabits',
          ].join('\n');

    Habit? waterHabit;
    try {
      waterHabit = applicableHabits.firstWhere((h) => h.id == 'water');
    } catch (_) {}

    return AppSheet(
      title: DateFormat('EEE, dd MMM').format(date),
      subtitle: totalThings == 0
          ? 'No goals scheduled'
          : '$totalDone of $totalThings things completed',
      scrollable: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusText,
                style: context.text.caption.copyWith(color: statusColor),
              ),
            ),
          ),
          const SizedBox(height: Spacing.section),

          // Rows
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Workout Row
                _SummaryRow(
                  icon: Icons.fitness_center_rounded,
                  color: context.colors.primary,
                  titleWidget: Text(
                    workoutDayName,
                    style: context.text.bodyStrong.copyWith(
                      color: context.colors.textDark,
                    ),
                  ),
                  subtitle: !workoutConfigured
                      ? 'Workout goals are not included.'
                      : isRestDay
                      ? 'Recovery day'
                      : '${stats.workoutsDone}/${stats.workoutsTotal} sections completed',
                  isDone: workoutDayDone,
                  onTap: currentWorkoutDayId == null
                      ? null
                      : () {
                          ref.read(selectedDateProvider.notifier).state = date;
                          final parentContext =
                              rootNavigatorKey.currentContext!;
                          Navigator.of(context).pop();
                          parentContext.go(
                            '/home/workout/$currentWorkoutDayId',
                          );
                        },
                ),
                const SizedBox(height: Spacing.stack),

                // Meals Row
                _SummaryRow(
                  icon: Icons.restaurant_rounded,
                  color: context.colors.green,
                  titleWidget: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (loggedIcons.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: Spacing.inline,
                          ),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              for (final icon in loggedIcons)
                                Icon(
                                  icon,
                                  size: 16,
                                  color: context.colors.textDark,
                                ),
                            ],
                          ),
                        ),
                      Text(
                        mealLog.hasCompleteCalories
                            ? '$completedMeals/$totalMealsTarget logged · ${mealLog.totalCalories} / ${profile.targetCalories} kcal'
                            : '$completedMeals/$totalMealsTarget logged · ${mealLog.totalCalories} known kcal',
                        style: context.text.bodyStrong.copyWith(
                          color: context.colors.textDark,
                        ),
                      ),
                    ],
                  ),
                  subtitle: mealLog.hasCompleteMacros
                      ? 'P: ${mealLog.totalProtein}g   C: ${mealLog.totalCarbs}g   F: ${mealLog.totalFat}g'
                      : 'Known macros: P ${mealLog.totalProtein}g · C ${mealLog.totalCarbs}g · F ${mealLog.totalFat}g. Some nutrition is missing.',
                  isDone:
                      totalMealsTarget > 0 &&
                      completedMeals >= totalMealsTarget,
                  onTap: () {
                    ref.read(selectedDateProvider.notifier).state = date;
                    final parentContext = rootNavigatorKey.currentContext!;
                    Navigator.of(context).pop();
                    parentContext.go('/home/meals');
                  },
                ),
                const SizedBox(height: Spacing.stack),

                // Habits Row
                _SummaryRow(
                  icon: Icons.checklist_rounded,
                  color: context.colors.primary,
                  titleWidget: Text(
                    'Habits ($completedHabits/$totalHabitsTarget)',
                    style: context.text.bodyStrong.copyWith(
                      color: context.colors.textDark,
                    ),
                  ),
                  subtitle: habitSummary,
                  isDone:
                      totalHabitsTarget > 0 &&
                      completedHabits == totalHabitsTarget,
                  onTap: () {
                    ref.read(selectedDateProvider.notifier).state = date;
                    final parentContext = rootNavigatorKey.currentContext!;
                    Navigator.of(context).pop();
                    parentContext.go('/home');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.section),

          // Day Feeling Reflection
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: DayFeelingCard(
              dateStr: dateStr,
              initialFeeling: dailyLog.dayFeeling,
              initialNote: dailyLog.dayNote,
            ),
          ),
          const SizedBox(height: Spacing.section),

          // Metrics 2x2 Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _MetricBox(
                    icon: Icons.directions_walk_rounded,
                    label: 'Steps',
                    value: dailyLog.steps?.toString() ?? '—',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricBox(
                    icon: Icons.bedtime_rounded,
                    label: 'Sleep',
                    value: dailyLog.sleepHours != null
                        ? '${dailyLog.sleepHours}h'
                        : '—',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _MetricBox(
                    icon: Icons.monitor_weight_rounded,
                    label: 'Weight',
                    value: dailyLog.weight != null
                        ? '${dailyLog.weight} kg'
                        : '—',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricBox(
                    icon: Icons.water_drop_rounded,
                    label: 'Water',
                    value: waterHabit == null
                        ? '—'
                        : (isHabitCompleted(
                                waterHabit,
                                habitCompletions,
                                dailyLog,
                              )
                              ? 'Done · ${waterHabit.target == waterHabit.target.roundToDouble() ? waterHabit.target.toInt() : waterHabit.target} ${waterHabit.unit.isNotEmpty ? waterHabit.unit : 'L'}'
                              : 'Goal ${waterHabit.target == waterHabit.target.roundToDouble() ? waterHabit.target.toInt() : waterHabit.target} ${waterHabit.unit.isNotEmpty ? waterHabit.unit : 'L'}'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.major),

          // Action Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  ref.read(selectedDateProvider.notifier).state = date;
                  final parentContext = rootNavigatorKey.currentContext!;
                  Navigator.of(context).pop();
                  parentContext.go('/home');
                },
                child: Text(
                  'Open full day',
                  style: context.text.bodyStrong.copyWith(
                    color: context.colors.onPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Widget titleWidget;
  final String subtitle;
  final bool isDone;
  final VoidCallback? onTap;

  const _SummaryRow({
    required this.icon,
    required this.color,
    required this.titleWidget,
    required this.subtitle,
    required this.isDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleWidget,
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: context.text.caption.copyWith(
                      color: context.colors.textLight,
                    ),
                    softWrap: true,
                  ),
                ],
              ),
            ),
            if (isDone)
              Icon(Icons.check_circle_rounded, color: context.colors.green)
            else if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: context.colors.textLight,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: context.colors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.text.micro.copyWith(
                    color: context.colors.textLight,
                  ),
                ),
                Text(
                  value,
                  style: context.text.body.copyWith(
                    color: context.colors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
