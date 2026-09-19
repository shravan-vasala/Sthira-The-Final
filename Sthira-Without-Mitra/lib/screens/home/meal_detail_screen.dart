import 'package:trufit_bodamma/theme/app_typography.dart';
import '../../theme/app_motion.dart';

import 'package:trufit_bodamma/theme/app_colors.dart';
import 'package:trufit_bodamma/theme/app_spacing.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/layout_insets.dart';
import '../../providers/app_providers.dart';
import '../../models/daily_meal_log.dart';
import '../../models/meal_plan.dart';
import '../../utils/meal_plan_complete.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/surface_card.dart';
import '../../widgets/primary_button.dart';
import '../../utils/meal_icons.dart';
import 'widgets/photo_calorie_scanner_sheet.dart';
import 'widgets/add_meal_slot_dialog.dart';
import 'widgets/ai_meal_suggestion_card.dart';
import '../meals/widgets/barcode_food_sheet.dart';
import '../../theme/app_theme.dart';

class MealDetailScreen extends ConsumerWidget {
  const MealDetailScreen({super.key});

  void _openAddSlotDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const AddMealSlotDialog());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyLog = ref.watch(dailyMealLogProvider);
    final profile = ref.watch(profileProvider);
    final mealPlan = ref.watch(mealPlanProvider);
    final activePlanName = mealPlan?.planName ?? 'Meal Plan';
    final planName = activePlanName;

    final targetCalories = profile.targetCalories;
    final isOverTarget =
        targetCalories > 0 && dailyLog.totalCalories > targetCalories;
    final progressRatio = targetCalories > 0
        ? (dailyLog.totalCalories / targetCalories).clamp(0.0, 1.0)
        : (dailyLog.totalCalories > 0 ? 1.0 : 0.0);

    final pinnedDateStr = ref.watch(dateStringProvider);
    final pinnedDate = DateTime.parse(pinnedDateStr);
    final now = ref.watch(clockProvider);
    final isToday = pinnedDateStr == DateFormat('yyyy-MM-dd').format(now);
    final titleText = isToday ? "Today's meals" : 'Meals';
    final subtitle = isToday
        ? planName
        : '${DateFormat('MMM d, yyyy').format(pinnedDate)} \u00b7 $planName';
    final textScaler = MediaQuery.textScalerOf(context);

    final List<({String id, String name, String emoji})> slotsToDisplay = [];
    final recurringIds = <String>{};

    for (final s in profile.customMealSlots) {
      final id = s['id'] as String;
      recurringIds.add(id);
      slotsToDisplay.add((
        id: id,
        name: s['name'] as String,
        emoji: s['emoji'] as String,
      ));
    }

    for (final entry in dailyLog.customSlots.entries) {
      if (!recurringIds.contains(entry.key)) {
        final log = entry.value;
        slotsToDisplay.add((
          id: entry.key,
          name: log.name ?? 'Meal',
          emoji: log.emoji ?? '🍽️',
        ));
      }
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: context.colors.scaffoldBg,
      appBar: AppBar(
        toolbarHeight: math.max(
          kToolbarHeight,
          textScaler.scale(24) * 1.15 + textScaler.scale(13) * 1.4 + 16,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(titleText, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.caption.copyWith(
                color: context.colors.textMedium,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          shellScrollBottomPadding(context),
        ),
        itemCount: slotsToDisplay.length + 4,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              children: [
                _CalorieHeader(
                  eaten: dailyLog.totalCalories,
                  target: targetCalories,
                  progress: progressRatio,
                  isOverTarget: isOverTarget,
                  protein: dailyLog.totalProtein,
                  carbs: dailyLog.totalCarbs,
                  fat: dailyLog.totalFat,
                  proteinTarget: profile.targetProteinG.toDouble(),
                  carbsTarget: profile.targetCarbsG.toDouble(),
                  fatTarget: profile.targetFatG.toDouble(),
                  completeCalories: dailyLog.hasCompleteCalories,
                  completeMacros: dailyLog.hasCompleteMacros,
                ),
                if (mealPlan != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${mealPlan.source == 'seed'
                        ? 'Expert-suggested plan'
                        : mealPlan.basedOnPlanName != null
                        ? 'Your customized expert plan'
                        : 'Meal plan'}: ${mealPlan.totalCalories} kcal. Your daily target is $targetCalories kcal; changing it does not change the plan portions.',
                    style: context.text.caption.copyWith(
                      color: context.colors.textMedium,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            );
          } else if (index <= slotsToDisplay.length) {
            final s = slotsToDisplay[index - 1];
            final shouldAnimate = !MediaQuery.disableAnimationsOf(context);
            return _MealSlotCard(
                  key: ValueKey(s.id),
                  slotId: s.id,
                  slotName: s.name,
                  slotEmoji: s.emoji,
                  slotLog: dailyLog.customSlots[s.id],
                  plannedMeal: MealPlanComplete.plannedForSlot(mealPlan, s.id),
                )
                .animate()
                .fadeIn(
                  duration: shouldAnimate ? Motion.deliberate : Motion.instant,
                  curve: Motion.enter,
                )
                .slideY(
                  begin: 0.05,
                  end: 0,
                  duration: shouldAnimate ? Motion.deliberate : Motion.instant,
                  curve: Motion.enter,
                );
          } else if (index == slotsToDisplay.length + 1) {
            if (!isToday ||
                targetCalories <= 0 ||
                !dailyLog.hasCompleteCalories ||
                !dailyLog.hasCompleteMacros)
              return const SizedBox.shrink();
            final unloggedSlots = slotsToDisplay.where((s) {
              final slotLog = dailyLog.customSlots[s.id];
              return slotLog?.isLogged != true;
            }).toList();
            final mealsLeft = unloggedSlots.length;
            final mealName = unloggedSlots.isNotEmpty
                ? unloggedSlots.first.name
                : null;

            return AIMealSuggestionCard(
              remainingCalories: targetCalories - dailyLog.totalCalories,
              remainingProtein: profile.targetProteinG > 0
                  ? math.max(
                      0.0,
                      profile.targetProteinG - dailyLog.totalProtein,
                    )
                  : null,
              remainingCarbs: profile.targetCarbsG > 0
                  ? math.max(0.0, profile.targetCarbsG - dailyLog.totalCarbs)
                  : null,
              remainingFat: profile.targetFatG > 0
                  ? math.max(0.0, profile.targetFatG - dailyLog.totalFat)
                  : null,
              mealName: mealName,
              mealsLeft: mealsLeft,
            );
          } else if (index == slotsToDisplay.length + 2) {
            return const SizedBox(height: 16);
          } else {
            return Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openAddSlotDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(
                      'Add another meal',
                      textAlign: TextAlign.center,
                      style: context.text.bodyStrong,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.colors.primary,
                      backgroundColor: context.colors.primary.withValues(
                        alpha: 0.12,
                      ),
                      side: BorderSide.none,
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

class _CalorieHeader extends StatelessWidget {
  const _CalorieHeader({
    required this.eaten,
    required this.target,
    required this.progress,
    required this.isOverTarget,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.proteinTarget,
    required this.carbsTarget,
    required this.fatTarget,
    this.completeCalories = true,
    this.completeMacros = true,
  });

  final int eaten;
  final int target;
  final double progress;
  final bool isOverTarget;
  final double protein;
  final double carbs;
  final double fat;
  final double proteinTarget;
  final double carbsTarget;
  final double fatTarget;
  final bool completeCalories;
  final bool completeMacros;

  @override
  Widget build(BuildContext context) {
    final accent = isOverTarget
        ? context.colors.orange
        : context.colors.primary;
    final shouldAnimate = !MediaQuery.disableAnimationsOf(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            completeCalories ? 'Calories logged' : 'Known calories logged',
            style: context.text.caption.copyWith(
              color: context.colors.textMedium,
            ),
          ),
          const SizedBox(height: Spacing.textPair),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: Spacing.inline,
            runSpacing: Spacing.textPair,
            children: [
              TweenAnimationBuilder<int>(
                tween: IntTween(
                  begin: shouldAnimate ? 0 : eaten.toInt(),
                  end: eaten.toInt(),
                ),
                duration: shouldAnimate ? Motion.deliberate : Duration.zero,
                curve: Motion.enter,
                builder: (context, val, child) {
                  return Text(
                    '$val',
                    style: context.text.metric.copyWith(
                      color: context.colors.textDark,
                    ),
                  );
                },
              ),
              if (target <= 0)
                Text(
                  ' kcal',
                  style: context.text.body.copyWith(
                    color: context.colors.textMedium,
                  ),
                )
              else if (isOverTarget)
                Text(
                  '${eaten - target} kcal above target',
                  style: context.text.body.copyWith(
                    color: context.colors.orange,
                  ),
                )
              else
                Text(
                  '/ ${target.toInt()} kcal',
                  style: context.text.body.copyWith(
                    color: context.colors.textMedium,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: context.colors.border,
              color: accent,
              minHeight: 2,
            ),
          ),
          if (!completeCalories || !completeMacros) ...[
            const SizedBox(height: 12),
            Text(
              'Some logged foods have incomplete nutrition. Unknown macros are excluded from progress comparisons.',
              style: context.text.caption.copyWith(
                color: context.colors.textMedium,
              ),
            ),
          ],
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final scale = MediaQuery.textScalerOf(context).scale(15) / 15;
              final columns = (constraints.maxWidth / (92 * scale))
                  .floor()
                  .clamp(1, 3);
              final width =
                  (constraints.maxWidth - Spacing.stack * (columns - 1)) /
                  columns;
              return Wrap(
                spacing: Spacing.stack,
                runSpacing: Spacing.stack,
                children: [
                  for (final stat in [
                    (label: 'Protein', current: protein, target: proteinTarget),
                    (label: 'Carbs', current: carbs, target: carbsTarget),
                    (label: 'Fat', current: fat, target: fatTarget),
                  ])
                    SizedBox(
                      width: width,
                      child: _MinimalMacroStat(
                        label: stat.label,
                        current: stat.current,
                        target: stat.target,
                        compact: columns == 1,
                        complete: completeMacros,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MinimalMacroStat extends StatelessWidget {
  const _MinimalMacroStat({
    required this.label,
    required this.current,
    required this.target,
    this.compact = false,
    this.complete = true,
  });

  final String label;
  final double current;
  final double target;
  final bool compact;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final amount = !complete
        ? (current > 0 ? '${current.round()}g known' : 'Unknown')
        : target <= 0
        ? '${current.round()}g'
        : '${current.round()} / ${target.round()}g';
    if (compact) {
      return Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.text.micro.copyWith(
                color: context.colors.textMedium,
              ),
            ),
          ),
          Flexible(
            child: Text(
              amount,
              textAlign: TextAlign.end,
              style: AppTheme.numeric(
                context.text.body.copyWith(color: context.colors.textDark),
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        Text(
          label,
          style: context.text.micro.copyWith(color: context.colors.textMedium),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: AppTheme.numeric(
            context.text.body.copyWith(color: context.colors.textDark),
          ),
        ),
      ],
    );
  }
}

class _MealSlotCard extends ConsumerStatefulWidget {
  const _MealSlotCard({
    super.key,
    required this.slotId,
    required this.slotName,
    required this.slotEmoji,
    this.slotLog,
    this.plannedMeal,
  });

  final String slotId;
  final String slotName;
  final String slotEmoji;
  final MealSlotLog? slotLog;
  final Meal? plannedMeal;

  @override
  ConsumerState<_MealSlotCard> createState() => _MealSlotCardState();
}

class _MealSlotCardState extends ConsumerState<_MealSlotCard> {
  bool _showSuggestions = false;

  bool _isSaving = false;

  bool get _hasLog => MealPlanComplete.isSlotLogged(widget.slotLog);

  bool get _isPlannedComplete =>
      MealPlanComplete.isPlannedComplete(widget.slotLog);

  Future<void> _repeatMeal() async {
    final oldLog = widget.slotLog;
    if (_isSaving || oldLog == null || !MealPlanComplete.isSlotLogged(oldLog)) {
      return;
    }

    final repo = ref.read(mealRepoProvider);
    final now = ref.read(clockProvider);
    final targetDateStr = DateFormat('yyyy-MM-dd').format(now);
    final profile = ref.read(profileProvider);

    // Repeat into today without replacing an already logged meal.
    final targetLog = repo.getDailyLog(targetDateStr);
    String targetSlotId = widget.slotId;

    if (MealPlanComplete.isSlotLogged(targetLog.customSlots[targetSlotId])) {
      final recurringIds = profile.customMealSlots
          .map((s) => s['id'] as String)
          .toList();
      String? nextEmpty;
      for (final id in recurringIds) {
        final slot = targetLog.customSlots[id];
        if (!MealPlanComplete.isSlotLogged(slot)) {
          nextEmpty = id;
          break;
        }
      }
      if (nextEmpty != null) {
        targetSlotId = nextEmpty;
      } else {
        // If all are full, we just use a fallback slot
        targetSlotId = 'repeated_${DateTime.now().millisecondsSinceEpoch}';
      }
    }

    final destination = profile.customMealSlots
        .where((slot) => slot['id'] == targetSlotId)
        .firstOrNull;
    final destinationName = destination?['name'] as String? ?? widget.slotName;
    final destinationEmoji =
        destination?['emoji'] as String? ?? widget.slotEmoji;
    final newItems = oldLog.items.map((item) => item.copy()).toList();

    final newSlotLog = MealSlotLog(
      name: destinationName,
      emoji: destinationEmoji,
      items: newItems,
      totalCalories: oldLog.totalCalories,
      totalProtein: oldLog.totalProtein,
      totalCarbs: oldLog.totalCarbs,
      totalFat: oldLog.totalFat,
      photoPath: oldLog.photoPath,
      photoPaths: List.of(oldLog.photoPaths),
      confidence: oldLog.confidence,
      caloriesComplete: oldLog.hasCompleteCalories,
      macrosComplete: oldLog.hasCompleteMacros,
    );

    setState(() => _isSaving = true);
    try {
      await ref
          .read(dailyMealLogProvider.notifier)
          .saveMealSlot(targetSlotId, newSlotLog, targetDate: targetDateStr);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added to today \u00b7 $destinationName'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not repeat this meal. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final planned = widget.plannedMeal;
    final slotLog = widget.slotLog;
    final shouldAnimate = !MediaQuery.disableAnimationsOf(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SurfaceCard(
        margin: EdgeInsets.zero,
        child: AnimatedSize(
          duration: shouldAnimate ? Motion.standard : Motion.instant,
          curve: Motion.enter,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    MealIcons.resolve(widget.slotEmoji),
                    color: context.colors.textDark,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.slotName,
                          style: context.text.cardTitle.copyWith(
                            color: context.colors.textDark,
                          ),
                        ),
                        if (_hasLog)
                          TweenAnimationBuilder<double>(
                            key: ValueKey(slotLog!.totalCalories),
                            tween: Tween(
                              begin: shouldAnimate ? 0.0 : 1.0,
                              end: 1.0,
                            ),
                            duration: shouldAnimate
                                ? Motion.deliberate
                                : Duration.zero,
                            curve: Motion.enter,
                            builder: (context, val, _) {
                              final cal = (slotLog.totalCalories * val).toInt();
                              final p = (slotLog.knownProtein * val).round();
                              final c = (slotLog.knownCarbs * val).round();
                              final f = (slotLog.knownFat * val).round();

                              return Wrap(
                                spacing: Spacing.inline,
                                runSpacing: Spacing.textPair,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    slotLog.hasCompleteCalories
                                        ? '$cal kcal'
                                        : '$cal kcal known',
                                    style: AppTheme.numeric(
                                      context.text.body.copyWith(
                                        color: context.colors.primary,
                                      ),
                                    ),
                                  ),
                                  if (!slotLog.hasCompleteMacros)
                                    Text(
                                      'Macros incomplete',
                                      style: context.text.caption,
                                    ),
                                  if (slotLog.hasCompleteMacros)
                                    for (final macro in [
                                      (
                                        label: 'P',
                                        value: p,
                                        color: context.colors.green,
                                      ),
                                      (
                                        label: 'C',
                                        value: c,
                                        color: context.colors.orange,
                                      ),
                                      (
                                        label: 'F',
                                        value: f,
                                        color: context.colors.primary,
                                      ),
                                    ])
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: '${macro.label}: ',
                                              style: context.text.micro
                                                  .copyWith(color: macro.color),
                                            ),
                                            TextSpan(text: '${macro.value}g'),
                                          ],
                                        ),
                                        style: AppTheme.numeric(
                                          context.text.caption.copyWith(
                                            color: context.colors.textMedium,
                                          ),
                                        ),
                                      ),
                                ],
                              );
                            },
                          )
                        else if (planned != null && planned.calories > 0)
                          Text(
                            'Target ~${planned.calories} kcal',
                            style: context.text.caption.copyWith(
                              color: context.colors.textMedium,
                            ),
                          )
                        else
                          Text(
                            'Not logged yet',
                            style: context.text.caption.copyWith(
                              color: context.colors.textMedium,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_hasLog)
                    TweenAnimationBuilder<double>(
                      key: const ValueKey('check'),
                      tween: Tween(begin: shouldAnimate ? 0.0 : 1.0, end: 1.0),
                      duration: shouldAnimate
                          ? Motion.deliberate
                          : Duration.zero,
                      curve: Motion.enter,
                      builder: (context, val, child) {
                        return Transform.scale(
                          scale: val,
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: context.colors.green,
                            size: 20,
                          ),
                        );
                      },
                    ),
                ],
              ),

              // State dependent body
              AnimatedSwitcher(
                duration: shouldAnimate ? Motion.standard : Duration.zero,
                switchInCurve: Motion.enter,
                switchOutCurve: Motion.exit,
                child: KeyedSubtree(
                  key: ValueKey(_hasLog),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_hasLog) ...[
                        const SizedBox(height: 20),

                        // Logged Items
                        if (slotLog!.photoPath != null) ...[
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  backgroundColor: context.colors.card
                                      .withValues(alpha: 0),
                                  insetPadding: EdgeInsets.zero,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      InteractiveViewer(
                                        child: kIsWeb
                                            ? Image.network(slotLog.photoPath!)
                                            : Image.file(
                                                File(
                                                  ref
                                                      .read(mediaRepoProvider)
                                                      .getAbsolutePath(
                                                        slotLog.photoPath!,
                                                      ),
                                                ),
                                              ),
                                      ),
                                      Positioned(
                                        top:
                                            MediaQuery.paddingOf(context).top +
                                            16,
                                        right: 16,
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.close_rounded,
                                            color: context.colors.onPrimary,
                                            size: 32,
                                          ),
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: kIsWeb
                                  ? Image.network(
                                      slotLog.photoPath!,
                                      width: double.infinity,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(
                                        ref
                                            .read(mediaRepoProvider)
                                            .getAbsolutePath(
                                              slotLog.photoPath!,
                                            ),
                                      ),
                                      width: double.infinity,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (slotLog.items.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final item in slotLog.items)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: Spacing.textPair,
                                  ),
                                  child: Wrap(
                                    spacing: Spacing.inline,
                                    runSpacing: Spacing.textPair,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        '${item.portion ?? ''} ${item.name ?? 'Food'}'
                                            .trim(),
                                        style: context.text.caption.copyWith(
                                          color: context.colors.textMedium,
                                        ),
                                      ),
                                      if (item.provenance != null)
                                        _ProvenanceBadge(
                                          provenance: item.provenance,
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),

                        const SizedBox(height: 12),
                        Wrap(
                          spacing: Spacing.inline,
                          runSpacing: Spacing.textPair,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: context.colors.primary,
                                minimumSize: const Size(48, 48),
                              ),
                              onPressed: () =>
                                  _openScanner(context, false, append: true),
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                                size: IconSize.inline,
                              ),
                              label: Text(
                                'Add Serving',
                                style: context.text.caption,
                              ),
                            ),
                            if (DateTime.parse(
                              ref.watch(dateStringProvider),
                            ).isBefore(
                              DateUtils.dateOnly(ref.watch(clockProvider)),
                            ))
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: context.colors.textMedium,
                                  minimumSize: const Size(48, 48),
                                ),
                                onPressed: _isSaving ? null : _repeatMeal,
                                icon: const Icon(
                                  Icons.copy_rounded,
                                  size: IconSize.inline,
                                ),
                                label: Text(
                                  'Repeat today',
                                  style: context.text.caption,
                                ),
                              )
                            else
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: context.colors.textMedium,
                                  minimumSize: const Size(48, 48),
                                ),
                                onPressed: () => _openScanner(context, false),
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: IconSize.inline,
                                ),
                                label: Text(
                                  'Replace',
                                  style: context.text.caption,
                                ),
                              ),
                            IconButton(
                              tooltip: 'Remove ${widget.slotName}',
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: context.colors.textMedium,
                                size: 20,
                              ),
                              onPressed: () {
                                final targetDateStr = ref.read(
                                  dateStringProvider,
                                );
                                final oldLog = widget.slotLog;
                                ref
                                    .read(dailyMealLogProvider.notifier)
                                    .clearMealSlot(
                                      widget.slotId,
                                      targetDate: targetDateStr,
                                    );

                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${widget.slotName} removed'),
                                    behavior: SnackBarBehavior.floating,
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      textColor: context.colors.primary,
                                      onPressed: () {
                                        if (oldLog != null) {
                                          ref
                                              .read(
                                                dailyMealLogProvider.notifier,
                                              )
                                              .saveMealSlot(
                                                widget.slotId,
                                                oldLog,
                                                targetDate: targetDateStr,
                                              );
                                        }
                                      },
                                    ),
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ] else ...[
                        // NOT logged actions
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                              child: CompactButton(
                                label: 'Take photo',
                                icon: Icons.camera_alt_outlined,
                                filled: true,
                                onPressed: () => _openScanner(context, false),
                              ),
                            ),
                            const SizedBox(width: Spacing.stack),
                            Expanded(
                              child: CompactButton(
                                label: 'Describe',
                                icon: Icons.notes_rounded,
                                filled: false,
                                onPressed: () => _openScanner(context, true),
                              ),
                            ),
                          ],
                        ),
                        if (planned != null) ...[
                          const SizedBox(height: 20),
                          Center(
                            child: TextButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => _toggleCompletedAsPlanned(planned),
                              child: Text(
                                planned.items.any(
                                      (item) => item.needsFoodOrPortionChoice,
                                    )
                                    ? 'Choose foods and portions'
                                    : 'Mark completed as planned',
                                style: context.text.caption.copyWith(
                                  color: context.colors.textMedium,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: Spacing.inline),
                      SizedBox(
                        width: double.infinity,
                        child: CompactButton(
                          label: 'Scan packaged food',
                          icon: Icons.qr_code_scanner,
                          filled: false,
                          onPressed: () => _openBarcode(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Suggestions
              if (planned != null && planned.suggestions.isNotEmpty)
                _buildSuggestions(context, planned),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions(BuildContext context, Meal planned) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() => _showSuggestions = !_showSuggestions);
              Haptics.tap();
            },
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 16,
                  color: context.colors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Plan guidelines',
                    style: context.text.body.copyWith(
                      color: context.colors.textDark,
                    ),
                  ),
                ),
                Icon(
                  _showSuggestions
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: context.colors.textMedium,
                  size: 20,
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: Motion.standard,
            curve: Motion.enter,
            alignment: Alignment.topCenter,
            child: !_showSuggestions
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      ...planned.suggestions.expand((suggestion) {
                        final items = suggestion
                            .split('•')
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty);

                        return items.map((item) {
                          String qty = '';
                          String name = item;
                          final words = item.split(' ');
                          int splitIndex = -1;
                          for (int i = 0; i < words.length; i++) {
                            final w = words[i];
                            // Find first capitalized word that isn't just numbers/symbols
                            if (w.isNotEmpty &&
                                w[0] == w[0].toUpperCase() &&
                                w[0] != w[0].toLowerCase() &&
                                !w.contains(RegExp(r'[0-9]'))) {
                              splitIndex = i;
                              break;
                            }
                          }

                          if (splitIndex > 0) {
                            qty = words.sublist(0, splitIndex).join(' ');
                            name = words.sublist(splitIndex).join(' ');
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    right: 12,
                                  ),
                                  child: Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: context.colors.primary.withValues(
                                        alpha: 0.6,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        if (qty.isNotEmpty)
                                          TextSpan(
                                            text: '$qty  ',
                                            style: context.text.caption
                                                .copyWith(
                                                  color: context.colors.primary
                                                      .withValues(alpha: 0.9),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        TextSpan(
                                          text: name,
                                          style: context.text.caption.copyWith(
                                            color: context.colors.textMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        });
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleCompletedAsPlanned(Meal planned) async {
    if (_isSaving) return;

    final targetDateStr = ref.read(dateStringProvider);
    final targetAccount = ref.read(accountGenerationProvider);
    if (!_isPlannedComplete &&
        planned.items.any((item) => item.needsFoodOrPortionChoice)) {
      final describe = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('What did you eat?'),
          content: const Text(
            'This expert plan includes choices or variable portions. Describe the specific foods and amounts you ate, then review their nutrition before saving. The original plan stays available below.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Describe meal'),
            ),
          ],
        ),
      );
      if (mounted &&
          describe == true &&
          targetAccount == ref.read(accountGenerationProvider) &&
          targetDateStr == ref.read(dateStringProvider)) {
        _openScanner(context, true);
      }
      return;
    }
    final notifier = ref.read(dailyMealLogProvider.notifier);

    if (_isPlannedComplete) {
      setState(() => _isSaving = true);
      try {
        Haptics.tap();
        await notifier.clearMealSlot(widget.slotId, targetDate: targetDateStr);
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
      return;
    }

    if (_hasLog) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Overwrite Meal?'),
          content: const Text(
            'This will remove your scanned photos and macros and replace them with the planned meal. Are you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                'Overwrite',
                style: context.text.body.copyWith(color: context.colors.red),
              ),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    if (!mounted || targetAccount != ref.read(accountGenerationProvider))
      return;

    setState(() => _isSaving = true);
    try {
      final profile = ref.read(profileProvider);
      final log = MealPlanComplete.buildSlotLog(
        planned: planned,
        slotName: widget.slotName,
        slotEmoji: widget.slotEmoji,
        profile: profile,
      );

      Haptics.toggle();
      await notifier.saveMealSlot(
        widget.slotId,
        log,
        targetDate: targetDateStr,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _openBarcode(BuildContext context) {
    final targetDate = ref.read(dateStringProvider);
    showAppBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => BarcodeFoodSheet(
        slotId: widget.slotId,
        slotDisplayName: widget.slotName,
        slotEmoji: widget.slotEmoji,
        targetDate: targetDate,
      ),
    );
  }

  void _openScanner(
    BuildContext context,
    bool isManualEntry, {
    bool append = false,
  }) {
    showAppBottomSheet(
      context: context,
      builder: (_) => PhotoCalorieScannerSheet(
        slotId: widget.slotId,
        slotDisplayName: widget.slotName,
        isManualEntry: isManualEntry,
        appendToLog: append ? widget.slotLog : null,
      ),
    );
  }
}

class _ProvenanceBadge extends StatelessWidget {
  const _ProvenanceBadge({this.provenance});
  final String? provenance;

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color color;
    final validProvenance = (provenance != null && provenance!.isNotEmpty)
        ? provenance!
        : 'unknown';
    String label = validProvenance;

    switch (validProvenance) {
      case 'verified':
        iconData = Icons.verified_outlined;
        color = context.colors.textMedium;
        break;
      case 'estimated':
      case 'ai_estimate':
        iconData = Icons.auto_awesome_rounded;
        color = context.colors.primary.withValues(alpha: 0.8);
        label = 'estimated';
        break;
      case 'barcode':
        iconData = Icons.qr_code_scanner;
        color = context.colors.textMedium;
        label = 'packaged';
        break;
      case 'label':
        iconData = Icons.edit_outlined;
        color = context.colors.textMedium;
        break;
      case 'database':
        iconData = Icons.storage_rounded;
        color = context.colors.textMedium;
        break;
      case 'legacy':
        iconData = Icons.history_rounded;
        color = context.colors.textLight;
        break;
      case 'yours':
        iconData = Icons.edit_outlined;
        color = context.colors.textLight;
        break;
      case 'expert_plan':
      case 'meal_plan':
        iconData = Icons.verified_user_rounded;
        color = context.colors.indigo;
        label = 'plan';
        break;
      default:
        iconData = Icons.info_outline_rounded;
        color = context.colors.textLight;
        label = 'unknown';
    }

    return TextButton.icon(
      onPressed: () {
        Haptics.tap();
        showAppBottomSheet(
          context: context,
          builder: (ctx) => _ProvenanceExplanationSheet(provenance: provenance),
        );
      },
      style: TextButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.textPair,
          vertical: Spacing.inline,
        ),
        textStyle: context.text.micro,
      ),
      icon: Icon(iconData, size: IconSize.inline),
      label: Text(label.substring(0, 1).toUpperCase() + label.substring(1)),
    );
  }
}

class _ProvenanceExplanationSheet extends StatelessWidget {
  const _ProvenanceExplanationSheet({this.provenance});
  final String? provenance;

  @override
  Widget build(BuildContext context) {
    String title, desc;

    final validProvenance = (provenance != null && provenance!.isNotEmpty)
        ? provenance!
        : 'unknown';

    if (validProvenance == 'barcode') {
      title = 'Packaged food';
      desc =
          'Nutrition from Open Food Facts, scaled to the amount you entered. '
          'Check your pack: community database entries may be incomplete or outdated. '
          'This meal keeps the values saved when you added it.';
    } else if (validProvenance == 'label') {
      title = 'Your package label';
      desc =
          'You entered or confirmed these label values for this barcode. '
          'The meal records the nutrition for your chosen amount.';
    } else if (validProvenance == 'verified') {
      title = 'Verified Local Food';
      desc =
          'This item was matched against your personal food database. Nutrition depends on that entry and the portion you logged.';
    } else if (validProvenance == 'estimated' ||
        validProvenance == 'ai_estimate') {
      title = 'AI Estimated';
      desc =
          'Gemini estimated the macros for this food based on its nutritional profile. The values are an AI approximation and not exact.';
    } else if (validProvenance == 'database') {
      title = 'Database Match';
      desc =
          'Nutrition is based on a food database match. Ingredients and portions can vary.';
    } else if (validProvenance == 'legacy') {
      title = 'Legacy Item';
      desc =
          'This item was recorded before provenance tracking was introduced.';
    } else if (validProvenance == 'yours') {
      title = 'Yours';
      desc = 'You manually adjusted the macros or portion size for this item.';
    } else if (validProvenance == 'expert_plan' ||
        validProvenance == 'meal_plan') {
      title = 'Meal plan entry';
      desc =
          'Nutrition is based on the selected meal plan. Check that the portion matches what you ate.';
    } else {
      title = 'Unknown Origin';
      desc = 'This is a legacy item with no recorded provenance or origin.';
    }

    return AppSheet(
      title: title,
      subtitle: desc,
      scrollable: true,
      child: const SizedBox(height: 28),
    );
  }
}
