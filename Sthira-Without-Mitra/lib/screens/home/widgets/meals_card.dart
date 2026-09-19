import 'package:trufit_bodamma/theme/app_typography.dart';
import 'package:trufit_bodamma/theme/app_colors.dart';
import 'package:trufit_bodamma/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import '../../../utils/meal_completion.dart';
import '../../../services/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/layout_insets.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/app_providers.dart';
import '../../../widgets/surface_card.dart';
import '../../../theme/app_motion.dart';

class MealsCard extends ConsumerWidget {
  const MealsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyLog = ref.watch(dailyMealLogProvider);
    final profile = ref.watch(profileProvider);
    final mealPlan = ref.watch(mealPlanProvider);
    final activePlanName = mealPlan?.planName ?? 'Meal Plan';
    final planName = activePlanName;

    final selectedDateStr = ref.watch(dateStringProvider);
    final selectedDate = DateTime.parse(selectedDateStr);
    final now = ref.watch(clockProvider);
    final today = DateTime(now.year, now.month, now.day);
    final isFuture = selectedDate.isAfter(today);
    final isToday = selectedDate.isAtSameMomentAs(today);

    final int totalMeals = MealCompletion.calculateTotalMeals(
      profile,
      dailyLog,
    );

    final completedMeals = dailyLog.loggedSlotsCount;
    final completedCal = dailyLog.totalCalories;
    final totalCal = profile.targetCalories;
    final progress = totalCal > 0
        ? (completedCal / totalCal).clamp(0.0, 1.0)
        : 0.0;
    final isOverTarget = totalCal > 0 && completedCal > totalCal;
    final summary = completedMeals == 0
        ? (isToday
              ? 'Add a meal to start your daily log.'
              : 'No meals logged for this day.')
        : !dailyLog.hasCompleteCalories || !dailyLog.hasCompleteMacros
        ? 'Some logged foods have incomplete nutrition. Open meals to review.'
        : totalCal <= 0
        ? 'Nutrition totals reflect your logged meals.'
        : isOverTarget
        ? '${completedCal - totalCal} kcal above target, based on logged meals'
        : isToday
        ? '${totalCal - completedCal} kcal to target \u00b7 ${(profile.targetProteinG - dailyLog.totalProtein).clamp(0, double.infinity).toStringAsFixed(0)}g protein to target'
        : 'Totals reflect logged meals, which may be incomplete.';

    return Semantics(
      button: true,
      label:
          'Meals Card. $completedMeals of $totalMeals meals logged. $completedCal calories logged. Daily target $totalCal calories.',
      child: GestureDetector(
        onTap: () {
          Haptics.tap();
          context.go('/home/meals');
        },
        behavior: HitTestBehavior.opaque,
        child: SurfaceCard(
          margin: const EdgeInsets.symmetric(horizontal: kScreenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isToday
                              ? "Today's Meals"
                              : (isFuture ? "Upcoming Meals" : "Meals"),
                          style: context.text.cardTitle.copyWith(
                            color: context.colors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          planName,
                          style: context.text.caption.copyWith(
                            color: context.colors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.colors.textLight,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: Spacing.block),
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.micro),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: context.colors.primary.withValues(
                    alpha: 0.12,
                  ),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOverTarget ? context.colors.orange : context.colors.green,
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: Spacing.stack),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: completedCal),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : Motion.deliberate,
                curve: Motion.enter,
                builder: (context, val, child) {
                  return Text(
                    totalCal > 0
                        ? '$completedMeals/$totalMeals meals  \u00b7  $val/$totalCal kcal logged'
                        : '$completedMeals/$totalMeals meals  \u00b7  $val kcal logged',
                    style: AppTheme.numeric(
                      context.text.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.textMedium,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: Spacing.inline),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (!dailyLog.hasCompleteMacros)
                    Text('Macros incomplete', style: context.text.caption),
                  if (dailyLog.hasCompleteMacros)
                    _MacroPill(
                      label: 'P',
                      value: dailyLog.totalProtein,
                      color: context.colors.green,
                    ),
                  if (dailyLog.hasCompleteMacros)
                    _MacroPill(
                      label: 'C',
                      value: dailyLog.totalCarbs,
                      color: context.colors.orange,
                    ),
                  if (dailyLog.hasCompleteMacros)
                    _MacroPill(
                      label: 'F',
                      value: dailyLog.totalFat,
                      color: context.colors.primary,
                    ),
                ],
              ),
              const SizedBox(height: Spacing.stack),
              Text(
                summary,
                style: context.text.micro.copyWith(
                  color: context.colors.textMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  const _MacroPill({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.15,
        ), // Bumped alpha slightly after removing border
        borderRadius: BorderRadius.circular(Radii.micro),
        // Sthira: Borders eradicated
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: value),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : Motion.deliberate,
        curve: Motion.enter,
        builder: (context, val, child) {
          return Text(
            '$label: ${val.toStringAsFixed(0)}g',
            style: AppTheme.numeric(context.text.micro.copyWith(color: color)),
          );
        },
      ),
    );
  }
}
