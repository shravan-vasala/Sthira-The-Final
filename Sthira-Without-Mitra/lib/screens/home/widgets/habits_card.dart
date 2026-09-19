import 'package:flutter/material.dart';
import '../../../services/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/layout_insets.dart';
import '../../../providers/app_providers.dart';
import '../../../models/habit.dart';
import '../../../utils/habit_icons.dart';
import '../../../widgets/surface_card.dart';
import '../../../widgets/app_bottom_sheet.dart';
import '../sleep_entry_dialog.dart';
import '../water_entry_dialog.dart';
import 'timer_entry_dialog.dart';
import '../../../widgets/empty_state_view.dart';
import '../../../theme/app_spacing.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';
import '../../../theme/app_motion.dart';

class HabitsCard extends ConsumerWidget {
  const HabitsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
    final completions = ref.watch(habitCompletionsProvider);
    final dailyLog = ref.watch(dailyLogProvider);

    final selectedDateStr = ref.watch(dateStringProvider);
    final selectedDate = DateTime.parse(selectedDateStr);
    final now = ref.watch(clockProvider);
    final today = DateTime(now.year, now.month, now.day);
    final isFuture = selectedDate.isAfter(today);

    return SurfaceCard(
      margin: const EdgeInsets.symmetric(horizontal: kScreenPadding),
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Gap.x8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < habits.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.screen,
                  vertical: Spacing.stack,
                ),
                child: _HabitItem(
                  habit: habits[i],
                  isCompleted: isHabitCompleted(
                    habits[i],
                    completions,
                    dailyLog,
                  ),
                  isFuture: isFuture,
                  progress: getHabitProgress(habits[i], completions, dailyLog),
                ),
              ),
            if (habits.isEmpty)
              const EmptyStateView(
                icon: Icons.self_improvement_rounded,
                title: 'No habits yet',
                subtitle: 'Tap edit to add a few — water, sleep, or a walk.',
              ),
          ],
        ),
      ),
    );
  }
}

class _HabitItem extends ConsumerWidget {
  final Habit habit;
  final bool isCompleted;
  final bool isFuture;
  final double progress;

  const _HabitItem({
    required this.habit,
    required this.isCompleted,
    required this.isFuture,
    required this.progress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      label:
          '${habit.name}, ${isCompleted ? 'completed' : 'incomplete'}${isFuture ? ', locked' : ''}',
      button: true,
      enabled: !isFuture,
      onTapHint: isCompleted ? 'Mark as incomplete' : 'Mark as complete',
      child: Dismissible(
        key: ValueKey(habit.id),
        direction: isFuture
            ? DismissDirection.none
            : DismissDirection.horizontal,
        confirmDismiss: (direction) => _handleSwipe(direction, context, ref),
        background: _buildSwipeBackground(context, true),
        secondaryBackground: _buildSwipeBackground(context, false),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showCounter = habit.type == HabitType.counter && !isFuture;
            final textScale = MediaQuery.textScalerOf(context).scale(15) / 15;
            // Keep the label readable before placing controls beside it.
            final inlineLabelWidth =
                constraints.maxWidth -
                48 -
                Spacing.inline -
                104 -
                Spacing.inline -
                24;
            final controlsBelow =
                showCounter && inlineLabelWidth < 112 * textScale;
            final row = Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: isFuture ? null : () => _handleTap(context, ref),
                    onLongPress: isFuture
                        ? null
                        : () => _handleLongPress(context, ref),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(
                            child: _LivelyHabitCircle(
                              isCompleted: isCompleted,
                              isFuture: isFuture,
                              progress: progress,
                              target: habit.target,
                            ),
                          ),
                        ),
                        const SizedBox(width: Spacing.inline),
                        Expanded(child: _buildDetails(context, ref)),
                      ],
                    ),
                  ),
                ),
                if (showCounter && !controlsBelow) _buildCounter(context, ref),
                const SizedBox(width: Spacing.inline),
                _buildIcon(context, habit.icon),
              ],
            );
            if (!controlsBelow) return row;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                row,
                const SizedBox(height: Spacing.textPair),
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildCounter(context, ref),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetails(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(habitStreakProvider(habit.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          habit.name,
          style: context.text.body.copyWith(color: context.colors.textDark),
        ),
        if (habit.type == HabitType.checkbox &&
            habit.unit.isNotEmpty &&
            habit.target > 0)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.textPair),
            child: Text(
              'Goal: ${habit.target == habit.target.roundToDouble() ? habit.target.toInt() : habit.target} ${habit.unit}',
              style: context.text.micro.copyWith(
                color: context.colors.textMedium,
              ),
            ),
          ),
        if (habit.type != HabitType.checkbox || streak > 1)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.textPair),
            child: Wrap(
              spacing: Spacing.inline,
              runSpacing: Spacing.textPair,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (habit.type != HabitType.checkbox)
                  Text(
                    _formatProgress(),
                    style: context.text.micro.copyWith(
                      color: context.colors.textMedium,
                    ),
                  ),
                if (streak > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.inline,
                      vertical: Gap.x2,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Radii.micro),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department_outlined,
                          size: IconSize.inline,
                          color: context.colors.orange,
                        ),
                        const SizedBox(width: Gap.x2),
                        Flexible(
                          child: Text(
                            '$streak Day Streak',
                            style: context.text.micro.copyWith(
                              color: context.colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCounter(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MiniButton(
          label: 'Decrease ${habit.name}',
          icon: Icons.remove_rounded,
          onTap: () {
            final newProg = (progress - habit.step).clamp(0.0, habit.target);
            ref
                .read(habitCompletionsProvider.notifier)
                .updateProgress(habit.id, newProg);
          },
        ),
        const SizedBox(width: Spacing.inline),
        _MiniButton(
          label: 'Increase ${habit.name}',
          icon: Icons.add_rounded,
          onTap: () {
            final newProg = (progress + habit.step).clamp(0.0, habit.target);
            ref
                .read(habitCompletionsProvider.notifier)
                .updateProgress(habit.id, newProg);
          },
        ),
      ],
    );
  }

  Widget _buildSwipeBackground(BuildContext context, bool isRight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isRight
            ? context.colors.green.withValues(alpha: 0.1)
            : context.colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: isRight ? Alignment.centerLeft : Alignment.centerRight,
      child: Icon(
        isRight ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
        color: isRight ? context.colors.green : context.colors.red,
      ),
    );
  }

  Future<bool?> _handleSwipe(
    DismissDirection direction,
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (direction == DismissDirection.startToEnd) {
      // Swipe Right -> Complete
      if (habit.type == HabitType.counter) {
        final newProg = (progress + habit.step).clamp(0.0, habit.target);
        // ignore: unawaited_futures
        ref
            .read(habitCompletionsProvider.notifier)
            .updateProgress(habit.id, newProg);
        _showUndo(context, 'Incremented ${habit.name}', () {
          final oldProg = (newProg - habit.step).clamp(0.0, habit.target);
          ref
              .read(habitCompletionsProvider.notifier)
              .updateProgress(habit.id, oldProg);
        });
      } else {
        if (!isCompleted) {
          // ignore: unawaited_futures
          ref
              .read(habitCompletionsProvider.notifier)
              .setOverride(habit.id, 'done');
          _showUndo(context, 'Completed ${habit.name}', () {
            ref
                .read(habitCompletionsProvider.notifier)
                .setOverride(habit.id, null);
          });
        }
      }
    } else if (direction == DismissDirection.endToStart) {
      // Swipe Left -> Not done
      if (habit.type == HabitType.counter) {
        final newProg = (progress - habit.step).clamp(0.0, habit.target);
        // ignore: unawaited_futures
        ref
            .read(habitCompletionsProvider.notifier)
            .updateProgress(habit.id, newProg);
        _showUndo(context, 'Decremented ${habit.name}', () {
          final oldProg = (newProg + habit.step).clamp(0.0, habit.target);
          ref
              .read(habitCompletionsProvider.notifier)
              .updateProgress(habit.id, oldProg);
        });
      } else {
        // ignore: unawaited_futures
        ref
            .read(habitCompletionsProvider.notifier)
            .setOverride(habit.id, 'notDone');
        _showUndo(context, 'Marked ${habit.name} incomplete', () {
          ref
              .read(habitCompletionsProvider.notifier)
              .setOverride(habit.id, null);
        });
      }
    }
    return false; // Prevent dismiss
  }

  void _showUndo(BuildContext context, String message, VoidCallback onUndo) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(label: 'UNDO', onPressed: onUndo),
      ),
    );
  }

  Widget _buildIcon(BuildContext context, String iconKey) {
    return Icon(HabitIcons.resolve(iconKey), color: context.colors.textLight);
  }

  String _formatProgress() {
    final String pStr = progress == progress.toInt()
        ? progress.toInt().toString()
        : progress.toStringAsFixed(1);
    final String tStr = habit.target == habit.target.toInt()
        ? habit.target.toInt().toString()
        : habit.target.toStringAsFixed(1);
    return '$pStr / $tStr ${habit.unit}';
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    if (habit.type == HabitType.autoSleep) {
      showAppBottomSheet(
        context: context,
        builder: (_) => const SleepEntryDialog(),
      );
      return;
    }

    if (habit.id == 'water') {
      showAppBottomSheet(
        context: context,
        builder: (_) => const WaterEntryDialog(),
      );
      return;
    }

    if (habit.type == HabitType.timer) {
      showAppBottomSheet(
        context: context,
        builder: (_) => TimerEntryDialog(habit: habit),
      );
      return;
    }

    if (habit.type == HabitType.checkbox) {
      ref.read(habitCompletionsProvider.notifier).toggle(habit.id);
      if (!isCompleted) {
        _showUndo(context, 'Completed ${habit.name}', () {
          ref.read(habitCompletionsProvider.notifier).toggle(habit.id);
        });
      } else {
        _showUndo(context, 'Marked ${habit.name} incomplete', () {
          ref.read(habitCompletionsProvider.notifier).toggle(habit.id);
        });
      }
      return;
    }

    final override = ref.read(habitCompletionsProvider).overrides[habit.id];
    final isSyncCompleted = isCompleted && override == null;

    if ((habit.type == HabitType.autoSteps ||
            habit.type == HabitType.autoSleep) &&
        isSyncCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completed from Samsung Health. Long press to override as not done.',
          ),
        ),
      );
      return;
    }

    String? newOverride;
    String message;
    if (isCompleted) {
      if (override == 'done') {
        newOverride = null;
      } else {
        newOverride = 'notDone';
      }
      message = 'Marked ${habit.name} incomplete';
    } else {
      newOverride = 'done';
      message = 'Completed ${habit.name}';
    }

    ref
        .read(habitCompletionsProvider.notifier)
        .setOverride(habit.id, newOverride);

    _showUndo(context, message, () {
      ref
          .read(habitCompletionsProvider.notifier)
          .setOverride(habit.id, override);
    });
  }

  void _handleLongPress(BuildContext context, WidgetRef ref) {
    final override = ref.read(habitCompletionsProvider).overrides[habit.id];

    if (override != null) {
      ref.read(habitCompletionsProvider.notifier).setOverride(habit.id, null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed manual override for ${habit.name}')),
      );
      return;
    }

    if (habit.type != HabitType.autoSteps &&
        habit.type != HabitType.autoSleep) {
      return;
    }

    final isSyncCompleted = isCompleted && override == null;

    if (isSyncCompleted) {
      ref
          .read(habitCompletionsProvider.notifier)
          .setOverride(habit.id, 'notDone');
    }
  }
}

class _MiniButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MiniButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.chip),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(Gap.x4),
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(Radii.micro),
                ),
                child: Icon(
                  icon,
                  size: IconSize.inline,
                  color: context.colors.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LivelyHabitCircle extends StatefulWidget {
  final bool isCompleted;
  final bool isFuture;
  final double progress;
  final double target;

  const _LivelyHabitCircle({
    required this.isCompleted,
    required this.isFuture,
    required this.progress,
    required this.target,
  });

  @override
  State<_LivelyHabitCircle> createState() => _LivelyHabitCircleState();
}

class _LivelyHabitCircleState extends State<_LivelyHabitCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Motion.deliberate);
    _scaleAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.25,
        ).chain(CurveTween(curve: Motion.enter)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.25,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(_LivelyHabitCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted && !oldWidget.isCompleted) {
      Haptics.tap();
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedContainer(
        duration: Motion.standard,
        curve: Motion.enter,
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Sthira: No borders!
          color: widget.isCompleted
              ? context.colors.green
              : (widget.isFuture
                    ? context.colors.textLight.withValues(alpha: 0.1)
                    : context.colors.textLight.withValues(
                        alpha: 0.15,
                      )), // Soft alpha fill instead of border
          boxShadow: widget.isCompleted
              ? [
                  BoxShadow(
                    color: context.colors.green.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            widget.isCompleted
                ? Icon(
                    Icons.check_rounded,
                    color: context.colors.onPrimary,
                    size: 16,
                  )
                : (widget.isFuture
                      ? Icon(
                          Icons.lock_outline_rounded,
                          color: context.colors.textLight.withValues(
                            alpha: 0.5,
                          ),
                          size: 14,
                        )
                      : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}
