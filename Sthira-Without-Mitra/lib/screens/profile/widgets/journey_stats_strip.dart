import 'package:isar/isar.dart';
import '../../../models/daily_log.dart';
import '../../../models/daily_meal_log.dart';
import '../../../models/exercise_log.dart';
import '../../../models/habit.dart';
import '../../../providers/badge_engine_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../../../theme/app_spacing.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';
import '../../../theme/app_motion.dart';

class JourneyStats {
  final int streak;
  final int completedWorkouts;
  final int trackedDays;
  final int earnedBadges;
  final DateTime? firstTrackedDate;
  const JourneyStats({
    this.streak = 0,
    this.completedWorkouts = 0,
    this.trackedDays = 0,
    this.earnedBadges = 0,
    this.firstTrackedDate,
  });

  factory JourneyStats.fromRecords({
    required Iterable<DailyLog> daily,
    required Iterable<DailyMealLog> meals,
    required Iterable<HabitCompletion> habits,
    required Iterable<ExerciseLog> exercises,
    required DateTime now,
    int earnedBadges = 0,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    bool eligible(String key) {
      final date = DateTime.tryParse(key);
      return date != null && !date.isAfter(today);
    }

    final active = <String>{};
    final workouts = <String>{};
    for (final log in daily) {
      if (!eligible(log.date)) continue;
      if (log.hasAnyActivity) active.add(log.date);
      if (log.workoutCompleted) workouts.add(log.date);
    }
    for (final log in meals) {
      if (eligible(log.date) && log.loggedSlotsCount > 0) active.add(log.date);
    }
    for (final log in habits) {
      final recorded =
          log.completions.values.any(
            (value) =>
                value is bool || (value is num && value.isFinite && value >= 0),
          ) ||
          log.overrides.values.any(
            (value) => value == 'done' || value == 'notDone',
          );
      if (eligible(log.date) && recorded) active.add(log.date);
    }
    for (final log in exercises) {
      if (eligible(log.date)) active.add(log.date);
    }
    final ordered = active.toList()..sort();
    return JourneyStats(
      streak: currentRecordedStreak(active, now),
      completedWorkouts: workouts.length,
      trackedDays: active.length,
      earnedBadges: earnedBadges,
      firstTrackedDate: ordered.isEmpty
          ? null
          : DateTime.tryParse(ordered.first),
    );
  }
}

final journeyStatsProvider = Provider<JourneyStats>((ref) {
  ref.watch(accountGenerationProvider);
  ref.watch(yearlyActivityChangesProvider);
  ref.watch(dailyLogsUpdateProvider);
  ref.watch(dailyMealLogsUpdateProvider);
  ref.watch(badgeRecordsUpdateProvider);
  final now = ref.watch(clockProvider);
  final database = ref.watch(activeDatabaseProvider);
  if (ref.watch(accountTransitionProvider) || database == null) {
    return const JourneyStats();
  }
  return JourneyStats.fromRecords(
    daily: ref.watch(dailyLogRepoProvider).getAllLogs(),
    meals: ref.watch(mealRepoProvider).getAllLogs(),
    habits: database.habitCompletions.where().findAllSync(),
    exercises: database.exerciseLogs.where().findAllSync(),
    earnedBadges: ref
        .watch(badgeRepoProvider)
        .getAllBadges()
        .where((b) => b.isUnlocked)
        .length,
    now: now,
  );
});

class JourneyStatsStrip extends ConsumerWidget {
  const JourneyStatsStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(journeyStatsProvider);
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns =
                constraints.maxWidth < 300 ||
                    MediaQuery.textScalerOf(context).scale(14) > 20
                ? 1
                : 2;
            final width =
                (constraints.maxWidth - Spacing.stack * (columns - 1)) /
                columns;
            return Wrap(
              spacing: Spacing.stack,
              runSpacing: Spacing.stack,
              children: [
                for (final value in [
                  (
                    title: 'Streak',
                    value: stats.streak,
                    unit: 'Logged days',
                    icon: Icons.local_fire_department_rounded,
                  ),
                  (
                    title: 'Workouts',
                    value: stats.completedWorkouts,
                    unit: 'Finished',
                    icon: Icons.fitness_center_rounded,
                  ),
                  (
                    title: 'Tracked',
                    value: stats.trackedDays,
                    unit: 'Days',
                    icon: Icons.calendar_month_rounded,
                  ),
                  (
                    title: 'Badges',
                    value: stats.earnedBadges,
                    unit: 'Earned',
                    icon: Icons.military_tech_rounded,
                  ),
                ])
                  SizedBox(
                    width: width,
                    child: _StatCard(
                      title: value.title,
                      value: value.value,
                      unit: value.unit,
                      icon: value.icon,
                      color: context.colors.primary,
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: Spacing.block),
        Text(
          stats.firstTrackedDate == null
              ? 'Your journey starts with your first log.'
              : 'Tracking since ${DateFormat('MMMM yyyy').format(stats.firstTrackedDate!)}',
          style: context.text.micro.copyWith(color: context.colors.textMedium),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  final String title;
  final int value;
  final String unit;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color;

    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final duration = disableAnimations ? Duration.zero : Motion.deliberate;

    return Container(
      padding: const EdgeInsets.all(Spacing.cardPadTight),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(icon, size: 16, color: effectiveColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: context.text.micro.copyWith(color: effectiveColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              TweenAnimationBuilder<int>(
                tween: IntTween(
                  begin: disableAnimations ? value : 0,
                  end: value,
                ),
                duration: duration,
                curve: Motion.enter,
                builder: (context, val, _) {
                  return Text(
                    val.toString(),
                    style: context.text.screenTitle.copyWith(
                      color: context.colors.textDark,
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: context.text.micro.copyWith(
                    color: context.colors.textMedium,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
