import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'share_card_exporter.dart';

class WeeklyShareLayout extends StatelessWidget {
  const WeeklyShareLayout({
    super.key,
    required this.format,
    required this.userName,
    required this.dateRange,
    required this.weekScore,
    required this.prevWeekScore,
    required this.dailyScores,
    required this.workoutsCompleted,
    required this.workoutsTotal,
    required this.avgSteps,
    required this.habitCompletionPercent,
    required this.baseColor,
    this.stepsDays = 0,
    this.scoreDays = 0,
    this.elapsedDays = 0,
    this.scheduledHabitInstances = 0,
    this.recordedHabitInstances = 0,
    this.isPartialWeek = false,
  });
  final ShareFormat format;
  final String userName, dateRange;
  final int weekScore, workoutsCompleted, workoutsTotal, avgSteps;
  final int? prevWeekScore, habitCompletionPercent;
  final List<int?> dailyScores;
  final Color baseColor;
  final int stepsDays,
      scoreDays,
      elapsedDays,
      scheduledHabitInstances,
      recordedHabitInstances;
  final bool isPartialWeek;

  @override
  Widget build(BuildContext context) {
    final story = format == ShareFormat.story;
    final foreground = AppColors.dark.textDark;
    final muted = AppColors.dark.textMedium;
    final delta = prevWeekScore == null ? null : weekScore - prevWeekScore!;
    return ColoredBox(
      color: AppColors.dark.surface,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Spacing.cardPad,
          vertical: story ? Spacing.major : Spacing.block,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'STHIRA',
                  style: context.text.micro.copyWith(color: muted),
                ),
                const SizedBox(width: Spacing.inline),
                Expanded(
                  child: Text(
                    dateRange,
                    textAlign: TextAlign.end,
                    style: context.text.micro.copyWith(color: muted),
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.stack),
            Text(
              "$userName's week",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.screenTitle.copyWith(color: foreground),
            ),
            const SizedBox(height: Spacing.textPair),
            Text(
              '${isPartialWeek ? 'Week in progress' : 'Weekly summary'} · $scoreDays of $elapsedDays days scored',
              style: context.text.micro.copyWith(color: muted),
            ),
            const SizedBox(height: Spacing.stack),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      scoreDays > 0 ? '$weekScore / 100' : '—',
                      key: const ValueKey('weekly-share-score'),
                      style: context.text.metric.copyWith(
                        color: scoreDays > 0 ? baseColor : muted,
                      ),
                    ),
                    const SizedBox(height: Spacing.textPair),
                    Text(
                      'Plan & logging score',
                      style: context.text.micro.copyWith(color: muted),
                    ),
                  ],
                ),
                if (scoreDays > 0 && delta != null && delta != 0) ...[
                  const SizedBox(width: Spacing.inline),
                  Flexible(
                    child: Text(
                      '${delta > 0 ? '+' : ''}$delta vs previous week',
                      style: context.text.micro.copyWith(color: muted),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: Spacing.stack),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(Spacing.inline),
                decoration: BoxDecoration(
                  color: AppColors.dark.scaffoldBg.withValues(alpha: .5),
                  borderRadius: BorderRadius.circular(Radii.card),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) => _MiniChart(
                    dailyScores: dailyScores,
                    barHeight: math.max(
                      0.0,
                      math.min(
                        story ? 90.0 : 60.0,
                        constraints.maxHeight - 18.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.stack),
            Row(
              children: [
                Expanded(
                  child: _WeeklyStatBox(
                    label: 'Workouts',
                    value: workoutsTotal == 0
                        ? '—'
                        : '$workoutsCompleted/$workoutsTotal',
                    contextLabel: workoutsTotal == 0
                        ? 'Not scheduled'
                        : isPartialWeek
                        ? 'So far'
                        : 'Planned sessions',
                  ),
                ),
                const SizedBox(width: Spacing.inline),
                Expanded(
                  child: _WeeklyStatBox(
                    label: 'Avg steps',
                    value: stepsDays > 0
                        ? NumberFormat('#,##0').format(avgSteps)
                        : '—',
                    contextLabel: stepsDays > 0
                        ? '$stepsDays recorded days'
                        : 'No entries',
                  ),
                ),
                const SizedBox(width: Spacing.inline),
                Expanded(
                  child: _WeeklyStatBox(
                    label: 'Habits',
                    value:
                        recordedHabitInstances > 0 &&
                            habitCompletionPercent != null
                        ? '$habitCompletionPercent%'
                        : '—',
                    contextLabel: scheduledHabitInstances == 0
                        ? 'Not scheduled'
                        : recordedHabitInstances == 0
                        ? 'No entries'
                        : '$recordedHabitInstances/$scheduledHabitInstances recorded',
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.stack),
            Text(
              'Tracked with Sthira',
              textAlign: TextAlign.center,
              style: context.text.micro.copyWith(
                color: AppColors.dark.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChart extends StatelessWidget {
  const _MiniChart({required this.dailyScores, required this.barHeight});
  final List<int?> dailyScores;
  final double barHeight;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: List.generate(7, (index) {
      final score = index < dailyScores.length ? dailyScores[index] : null;
      return Semantics(
        label:
            '${['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][index]}, ${score == null ? 'unscored' : '$score of 100'}',
        excludeSemantics: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              key: ValueKey('weekly-share-bar-$index'),
              width: 16,
              height: barHeight,
              alignment: Alignment.bottomCenter,
              decoration: BoxDecoration(
                color: AppColors.dark.border.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(Radii.micro),
              ),
              child: score == null
                  ? null
                  : Container(
                      width: 16,
                      height: math.min(
                        barHeight,
                        math.max(2.0, barHeight * (score / 100).clamp(0, 1)),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.dark.primary,
                        borderRadius: BorderRadius.circular(Radii.micro),
                      ),
                    ),
            ),
            const SizedBox(height: Spacing.textPair),
            Text(
              ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index],
              style: context.text.micro.copyWith(
                color: AppColors.dark.textMedium,
              ),
            ),
          ],
        ),
      );
    }),
  );
}

class _WeeklyStatBox extends StatelessWidget {
  const _WeeklyStatBox({
    required this.label,
    required this.value,
    required this.contextLabel,
  });
  final String label, value, contextLabel;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      vertical: Spacing.inline,
      horizontal: Spacing.textPair,
    ),
    decoration: BoxDecoration(
      color: AppColors.dark.scaffoldBg.withValues(alpha: .5),
      borderRadius: BorderRadius.circular(Radii.control),
    ),
    child: Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.cardTitle.copyWith(
            color: AppColors.dark.textDark,
          ),
        ),
        const SizedBox(height: Spacing.textPair),
        Text(
          label,
          style: context.text.micro.copyWith(color: AppColors.dark.textMedium),
        ),
        const SizedBox(height: Spacing.textPair),
        Text(
          contextLabel,
          maxLines: 2,
          textAlign: TextAlign.center,
          style: context.text.micro.copyWith(color: AppColors.dark.textMedium),
        ),
      ],
    ),
  );
}
