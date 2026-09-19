import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../providers/app_providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_bottom_sheet.dart';
import '../../../widgets/surface_card.dart';
import '../../../widgets/section_header.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';
import '../../../theme/app_motion.dart';

class DailyScoreSheet extends ConsumerStatefulWidget {
  const DailyScoreSheet({super.key});

  @override
  ConsumerState<DailyScoreSheet> createState() => _DailyScoreSheetState();
}

class _DailyScoreSheetState extends ConsumerState<DailyScoreSheet> {
  @override
  Widget build(BuildContext context) {
    final scoreData = ref.watch(dailyScoreProvider);

    if (scoreData.isFutureDate) {
      return AppSheet(
        title: 'Daily Score',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Text(
              'Data not available for future dates.',
              style: context.text.bodyStrong.copyWith(
                color: context.colors.textLight,
              ),
            ),
          ),
        ),
      );
    }

    return AppSheet(
      title: 'Daily Score',
      subtitle: scoreData.date == null
          ? null
          : '${DateFormat('EEE, d MMM').format(scoreData.date!)}${scoreData.isToday ? ' \u00b7 Today so far' : ''}',
      scrollable: true,
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 2.2 Animated Score Card
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0,
                  end: scoreData.totalScore.toDouble(),
                ),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : Motion.deliberate,
                curve: Motion.enter,
                builder: (context, value, child) {
                  final intScore = value.round();

                  final int currentPercentage = intScore;

                  // Color dynamically shifts during animation
                  Color animColor = context.colors.green;
                  if (currentPercentage < 50) {
                    animColor = context.colors.red;
                  } else if (currentPercentage < 80) {
                    animColor = context.colors.orange;
                  }

                  return Column(
                    children: [
                      Text(
                        scoreData.totalMax > 0 ? '$intScore' : '\u2014',
                        style: AppTheme.numeric(
                          context.text.metric.copyWith(
                            color: intScore == 100 && scoreData.totalMax > 0
                                ? context.colors.green
                                : animColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        scoreData.totalMax > 0
                            ? 'of 100'
                            : 'No active categories',
                        style: context.text.body.copyWith(
                          color: context.colors.textMedium,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ).animate().fade().scale(begin: const Offset(0.95, 0.95)),

            Builder(
              builder: (context) {
                final showComparison =
                    !scoreData.isToday &&
                    scoreData.yesterdayScore != null &&
                    (scoreData.totalScore - scoreData.yesterdayScore!) != 0;
                final showAverage = scoreData.sevenDayAverage != null;

                if (!showComparison && !showAverage) {
                  return const SizedBox(height: 24);
                }

                return Column(
                  children: [
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        if (showComparison) ...[
                          _DeltaChip(
                            current: scoreData.totalScore,
                            previous: scoreData.yesterdayScore!,
                            label: 'vs yesterday',
                          ),
                          if (showAverage) const SizedBox(height: 8),
                        ],
                        if (showAverage)
                          Text(
                            'Previous 7 days: ${scoreData.sevenDayAverage} average${scoreData.sevenDayRecordedDays > 0 ? ' \u00b7 ${scoreData.sevenDayRecordedDays} recorded days' : ''}',
                            style: AppTheme.numeric(
                              context.text.caption.copyWith(
                                color: context.colors.textMedium,
                              ),
                            ),
                          ),
                      ],
                    ).animate().fade(delay: Motion.deliberate),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),

            const SectionHeader('Score breakdown', horizontalPadding: 0),
            const SizedBox(height: 12),

            // 2.3 Breakdown as progress bars (Staggered)
            SurfaceCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(12),
              border: null,
              child: Column(
                children: [
                  _AnimatedProgressBarRow(
                    label: 'Habits',
                    score: scoreData.habitsScore,
                    max: scoreData.habitsMax,
                    icon: Icons.check_circle_outline_rounded,
                    color: context.colors.primary,
                    onTap: scoreData.remainingLabels.contains('habits')
                        ? () => Navigator.pop(context)
                        : null,
                  ).animate().fade(delay: Motion.instant).slideX(begin: 0.05),
                  const SizedBox(height: 4),
                  _AnimatedProgressBarRow(
                    label: 'Workouts',
                    score: scoreData.workoutsScore,
                    max: scoreData.workoutsMax,
                    icon: Icons.fitness_center_rounded,
                    color: context.colors.orange,
                    isRestDay: scoreData.isRestDay,
                    onTap: scoreData.remainingLabels.contains('workout')
                        ? () {
                            Navigator.pop(context);
                            context.go('/workout');
                          }
                        : null,
                  ).animate().fade(delay: Motion.standard).slideX(begin: 0.05),
                  const SizedBox(height: 4),
                  _AnimatedProgressBarRow(
                    label: 'Meals',
                    score: scoreData.mealsScore,
                    max: scoreData.mealsMax,
                    icon: Icons.restaurant_rounded,
                    color: context.colors.green,
                    onTap: scoreData.remainingLabels.contains('meals')
                        ? () {
                            Navigator.pop(context);
                            context.go('/home/meals');
                          }
                        : null,
                  ).animate().fade(delay: Motion.standard).slideX(begin: 0.05),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 2.3a No categories scheduled state
            if (scoreData.totalMax <= 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.border.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.self_improvement_rounded,
                      color: context.colors.textMedium,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No categories scheduled today.',
                        style: context.text.body.copyWith(
                          color: context.colors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fade(delay: Motion.deliberate),
            ]
            // 2.4 Perfect day state (retained)
            else if (scoreData.isPrimaryComplete) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: context.colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Perfect day — everything done ✨',
                        style: context.text.body.copyWith(
                          color: context.colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fade(delay: Motion.deliberate),
            ],

            const SizedBox(height: 24),

            // 2.5 Footer Disclosure
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'How scoring works',
                  style: context.text.bodyStrong.copyWith(
                    color: context.colors.textDark,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'Your score is out of 100, using the categories configured for this day. Habits contribute up to 50 points, workouts up to 30, and meals up to 20 before scaling. Planned rest earns the workout points. Meal points include up to 14 for logging and 6 for being near your calorie target; a food log may not represent a complete day. Scores reflect your current plan and targets.',
                      style: context.text.caption.copyWith(
                        color: context.colors.textMedium,
                      ),
                      textAlign: TextAlign.start,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          Flexible(
            child: Text(
              '${diff.abs()} $label',
              style: AppTheme.numeric(
                context.text.caption.copyWith(color: color),
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedProgressBarRow extends StatelessWidget {
  const _AnimatedProgressBarRow({
    required this.label,
    required this.score,
    required this.max,
    required this.icon,
    required this.color,
    this.isRestDay = false,
    this.onTap,
  });

  final String label;
  final double score;
  final double max;
  final IconData icon;
  final Color color;
  final bool isRestDay;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fraction = max > 0 ? (score / max).clamp(0.0, 1.0) : 0.0;
    final isConfigured = max > 0 || isRestDay;

    String statusText;
    if (isRestDay) {
      statusText = 'Rest day';
    } else if (max <= 0) {
      statusText = 'Not configured';
    } else {
      statusText =
          '${score == score.toInt() ? score.toInt().toString() : score.toStringAsFixed(1)} / ${max.toStringAsFixed(0)}';
    }

    return Semantics(
      label:
          '$label category. $statusText. ${onTap != null ? 'Double tap to open' : ''}',
      button: onTap != null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Opacity(
            opacity: !isConfigured ? 0.5 : 1.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              label,
                              style: context.text.body.copyWith(
                                color: context.colors.textDark,
                              ),
                            ),
                            Wrap(
                              spacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (isRestDay) ...[
                                  Icon(
                                    Icons.spa_rounded,
                                    color: context.colors.green,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  statusText,
                                  style: AppTheme.numeric(
                                    context.text.caption.copyWith(
                                      color: context.colors.textMedium,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: 0,
                            end: isRestDay ? 1.0 : fraction,
                          ),
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : Motion.deliberate,
                          curve: Motion.enter,
                          builder: (context, val, _) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: val,
                                backgroundColor: context.colors.primary
                                    .withValues(alpha: 0.12),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isRestDay ? context.colors.green : color,
                                ),
                                minHeight: 2,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: context.colors.textMedium.withValues(alpha: 0.5),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
