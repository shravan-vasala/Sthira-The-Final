import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/workout_completion.dart';
import '../../utils/exercise_log_save.dart';
import '../../services/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/section_header.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../models/workout_plan.dart';
import 'widgets/exercise_card.dart';
import 'widgets/rest_timer_label.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../widgets/primary_button.dart';
import '../../theme/app_spacing.dart';
import '../../utils/workout_formatting.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';
import '../../theme/layout_insets.dart';
import '../../theme/app_motion.dart';

Future<String?> showWorkoutFinishConfirmation({
  required BuildContext context,
  required String date,
  required int completed,
  required int total,
  required bool hasUnsupportedTargets,
}) {
  final withoutRepLogs = completed == 0 && hasUnsupportedTargets;
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      scrollable: true,
      title: Text(
        withoutRepLogs
            ? 'Finish this session?'
            : completed == 0
            ? 'Skip workout?'
            : 'Finish early?',
      ),
      content: Text(
        withoutRepLogs
            ? 'Distance or unclear targets are not stored as repetitions. You can finish this session without rep logs or mark it skipped.'
            : completed == 0
            ? 'No exercises logged for ${DateFormat('d MMM').format(DateTime.parse(date))}. Mark this workout as skipped?'
            : '$completed of $total exercises logged. You can continue logging later.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Keep going'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(ctx, completed == 0 ? 'skipped' : 'partial'),
          child: Text(completed == 0 ? 'Skip workout' : 'Finish early'),
        ),
        if (withoutRepLogs)
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'partial'),
            child: const Text('Finish without rep logs'),
          ),
      ],
    ),
  );
}

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({
    super.key,
    required this.dayId,
    this.sectionIndex,
    this.jumpToIndex,
  });

  final String dayId;

  /// null = show all sections; 0+ = show that specific section only
  final int? sectionIndex;
  final int? jumpToIndex;

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  /// When non-null, only show that section. When null, show all.
  int? _activeSectionIndex;
  bool _finishing = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _activeSectionIndex = widget.sectionIndex;
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(workoutPlanProvider);
    if (plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: const Center(child: Text('No workout plan found')),
      );
    }

    final selectedDate = ref.watch(selectedDateProvider);
    final scheduledDays = WorkoutCompletion.scheduledDays(
      plan,
      selectedDate,
      planStartDate: ref.watch(profileProvider).planStartDate,
    );
    WorkoutDay? day;
    for (final d in scheduledDays) {
      if (d.dayId == widget.dayId) {
        day = d;
        break;
      }
    }

    if (day == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: const Center(child: Text('Workout day not found')),
      );
    }

    final workoutDay = day;

    final logRepo = ref.watch(exerciseLogRepoProvider);
    final dateStr = ref.watch(dateStringProvider);
    ref.watch(exerciseLogsUpdateProvider);
    ref.watch(exerciseRecordsUpdateProvider);
    ref.watch(accountGenerationProvider);

    final totalExercises = workoutDay.sections.fold<int>(
      0,
      (sum, s) => sum + s.exercises.length,
    );
    final completedExercises = workoutDay.sections.fold<int>(
      0,
      (sum, s) =>
          sum +
          s.exercises
              .where(
                (e) => logRepo.hasLog(dateStr, e.instanceId ?? e.name ?? ''),
              )
              .length,
    );

    final isFinished = ref
        .watch(workoutRepoProvider)
        .isWorkoutFinished(dateStr, widget.dayId);

    final dailyLog = ref.watch(dailyLogProvider);
    final status = dailyLog.workoutDayId == widget.dayId
        ? dailyLog.workoutStatus
        : null;
    final statusLabel = switch (status) {
      'partial' => 'Finished early',
      'skipped' => 'Skipped',
      'completed' => 'Completed',
      _ => isFinished ? 'Finished' : null,
    };
    final now = ref.watch(clockProvider);
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final isFuture = selectedDay.isAfter(today);

    final phaseProgress = ref.watch(phaseProgressProvider);

    // Determine which sections to display
    final bool isFiltered =
        _activeSectionIndex != null &&
        _activeSectionIndex! >= 0 &&
        _activeSectionIndex! < workoutDay.sections.length;
    final sectionsToShow = isFiltered
        ? [workoutDay.sections[_activeSectionIndex!]]
        : workoutDay.sections;

    // Title: use section name when filtered, day label when showing all
    final String appBarTitle = isFiltered
        ? formatSectionTitle(
            workoutDay.sections[_activeSectionIndex!].title,
            _activeSectionIndex!,
          )
        : workoutDay.label ?? workoutDay.dayId ?? '';

    // Progress counts for current view
    final viewExercises = isFiltered
        ? workoutDay.sections[_activeSectionIndex!].exercises.length
        : totalExercises;
    final viewCompleted = isFiltered
        ? workoutDay.sections[_activeSectionIndex!].exercises
              .where(
                (e) => logRepo.hasLog(dateStr, e.instanceId ?? e.name ?? ''),
              )
              .length
        : completedExercises;

    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      appBar: AppBar(
        centerTitle: false,
        toolbarHeight:
            64 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.8),
        title: widget.sectionIndex != null
            ? Hero(
                tag: 'workout-${widget.dayId}-section-${widget.sectionIndex}',
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    appBarTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.screenTitle.copyWith(
                      color: context.colors.textDark,
                    ),
                  ),
                ),
              )
            : Text(
                appBarTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.screenTitle.copyWith(
                  color: context.colors.textDark,
                ),
              ),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.screen),
            child: Column(
              children: [
                const SizedBox(height: Spacing.stack),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: Spacing.stack,
                    runSpacing: Spacing.inline,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEE, d MMM').format(selectedDate),
                        style: context.text.caption,
                      ),
                      if (statusLabel != null)
                        Text(
                          statusLabel,
                          style: context.text.caption.copyWith(
                            color: status == 'completed'
                                ? context.colors.green
                                : context.colors.textMedium,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.inline),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${phaseProgress.isPhaseActive ? 'Week ${phaseProgress.currentWeek} of ${phaseProgress.totalWeeks} · ' : ''}$viewCompleted/$viewExercises exercises logged',
                    style: context.text.caption.copyWith(
                      color: context.colors.textMedium,
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.stack),

                // ── Progress bar (always total day progress) ─────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.micro),
                  child: LinearProgressIndicator(
                    value: totalExercises > 0
                        ? completedExercises / totalExercises
                        : 0,
                    backgroundColor: context.colors.primary.withValues(
                      alpha: 0.12,
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      context.colors.green,
                    ),
                    minHeight: 6,
                  ),
                ),
                if (totalExercises > 0) ...[
                  const SizedBox(height: Spacing.textPair),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Day total: $completedExercises/$totalExercises',
                        style: AppTheme.numeric(
                          context.text.micro.copyWith(
                            color: context.colors.textLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: Spacing.stack),

                // ── "Show all sections" banner when filtered ─────────────────
                if (isFiltered)
                  GestureDetector(
                    onTap: () => setState(() => _activeSectionIndex = null),
                    child: Container(
                      margin: EdgeInsets.only(bottom: Spacing.stack),
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.block,
                        vertical: Spacing.stack,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.insetSurface,
                        borderRadius: BorderRadius.circular(Radii.control),
                        // Sthira: No borders! Let floating backgrounds separate space
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.grid_view_rounded,
                            color: context.colors.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Showing: ${formatSectionTitle(workoutDay.sections[_activeSectionIndex!].title, _activeSectionIndex!)}',
                              style: context.text.caption.copyWith(
                                color: context.colors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: Spacing.inline),
                          Flexible(
                            child: Text(
                              'Show all →',
                              style: context.text.micro.copyWith(
                                color: context.colors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Sections list ─────────────────────────────────────────────
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                      bottom: shellScrollBottomPadding(context),
                    ),
                    itemCount: sectionsToShow.length,
                    itemBuilder: (context, listIndex) {
                      // Map back to original section index for consistency
                      final sectionIndex = isFiltered
                          ? _activeSectionIndex!
                          : listIndex;
                      final section = sectionsToShow[listIndex];
                      return _SectionWidget(
                            section: section,
                            sectionIndex: sectionIndex,
                            dayId: widget.dayId,
                            jumpToIndex: (widget.sectionIndex == sectionIndex)
                                ? widget.jumpToIndex
                                : null,
                          )
                          .animate(delay: (listIndex * 100).ms)
                          .fadeIn(
                            duration: Motion.deliberate,
                            curve: Motion.enter,
                          )
                          .slideY(
                            begin: 0.1,
                            end: 0,
                            duration: Motion.deliberate,
                            curve: Motion.enter,
                          );
                    },
                  ),
                ),

                // ── Rest Timer Floating Bar ───────────────────────────────────

                // ── Finish Workout Button ─────────────────────────────────────
                if (status != 'completed')
                  Padding(
                    padding: const EdgeInsets.only(
                      top: Spacing.stack,
                      bottom: Spacing.block,
                    ),
                    child: PrimaryButton(
                      label: _finishing ? 'Saving…' : 'Finish Workout',
                      icon: Icons.emoji_events_rounded,
                      onPressed: isFuture || _finishing || totalExercises == 0
                          ? null
                          : () => _finishWorkout(
                              context,
                              ref,
                              widget.dayId,
                              completedExercises,
                              totalExercises,
                              hasUnsupportedTargets: workoutDay.sections.any(
                                (section) => section.exercises.any(
                                  (exercise) =>
                                      !supportsExerciseLogging(exercise),
                                ),
                              ),
                            ),
                    ),
                  ),
              ],
            ), // closes Column
          ), // closes Padding
        ), // closes Builder
      ), // closes SafeArea
    ); // closes Scaffold
  }

  Future<void> _finishWorkout(
    BuildContext context,
    WidgetRef ref,
    String dayId,
    int completed,
    int total, {
    required bool hasUnsupportedTargets,
  }) async {
    if (_finishing) return;
    final date = ref.read(dateStringProvider);
    final generation = ref.read(accountGenerationProvider);
    var status = completed == 0
        ? 'skipped'
        : completed < total
        ? 'partial'
        : 'completed';
    setState(() => _finishing = true);
    try {
      ensureExerciseSaveScope(ref, generation, date);
      if (status != 'completed') {
        final choice = await showWorkoutFinishConfirmation(
          context: context,
          date: date,
          completed: completed,
          total: total,
          hasUnsupportedTargets: hasUnsupportedTargets,
        );
        if (choice == null || !mounted) return;
        status = choice;
      }
      ensureExerciseSaveScope(ref, generation, date);
      await ref
          .read(workoutRepoProvider)
          .finishWorkout(date, dayId, status: status);
      ensureExerciseSaveScope(ref, generation, date);
      if (!mounted) return;
      setState(() {});
      Haptics.success();
      final name = ref.read(profileProvider).name.trim();
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: Icon(
            status == 'completed'
                ? Icons.emoji_events_rounded
                : Icons.check_circle_outline_rounded,
            color: status == 'completed'
                ? const Color(0xFFB8860B)
                : context.colors.primary,
            size: 40,
          ),
          title: Text(
            status == 'skipped'
                ? 'Workout skipped'
                : status == 'partial'
                ? 'Session saved'
                : name.isEmpty
                ? 'Workout complete!'
                : 'Nice work, $name!',
          ),
          content: Text(
            '${DateFormat('EEE, d MMM').format(DateTime.parse(date))} · $completed/$total exercises logged.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/home');
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is StateError
                  ? error.message.toString()
                  : 'Could not save this session. Please try again.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }
}

// ─── Section Widget ───────────────────────────────────────────────────────────

class _SectionWidget extends StatefulWidget {
  const _SectionWidget({
    required this.section,
    required this.sectionIndex,
    required this.dayId,
    this.jumpToIndex,
  });

  final WorkoutSection section;
  final int sectionIndex;
  final String dayId;
  final int? jumpToIndex;

  @override
  State<_SectionWidget> createState() => _SectionWidgetState();
}

class _SectionWidgetState extends State<_SectionWidget> {
  final _jumpKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.jumpToIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_jumpKey.currentContext != null) {
          Scrollable.ensureVisible(
            _jumpKey.currentContext!,
            duration: Motion.deliberate,
            curve: Motion.enter,
            alignment: 0.2,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.major),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sticky-style section header
          SectionHeader(
            formatSectionTitle(widget.section.title, widget.sectionIndex),
            horizontalPadding: 0,
            countLabel: Text(
              '${widget.section.exercises.length} exercises',
              style: context.text.micro.copyWith(
                color: context.colors.textMedium,
              ),
            ),
          ),
          const SizedBox(height: Spacing.stack),
          if (widget.section.exercises.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.block),
              child: Text(
                'No exercises in this section.',
                style: context.text.body.copyWith(
                  color: context.colors.textMedium,
                ),
              ),
            )
          else
            ...List.generate(widget.section.exercises.length * 2 - 1, (index) {
              if (index.isOdd) {
                final exerciseIndex = index ~/ 2;
                final exercise = widget.section.exercises[exerciseIndex];
                if (exercise.restSecondsAfterSet > 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: Spacing.stack,
                    ),
                    child: Center(
                      child: RestTimerLabel(
                        seconds: exercise.restSecondsAfterSet,
                        exerciseName: exercise.name ?? '',
                      ),
                    ),
                  );
                }
                return const SizedBox(height: Spacing.stack);
              }
              final exerciseIndex = index ~/ 2;
              final exercise = widget.section.exercises[exerciseIndex];
              return Container(
                key: (widget.jumpToIndex == exerciseIndex) ? _jumpKey : null,
                child: ExerciseCard(
                  exercise: exercise,
                  dayId: widget.dayId,
                  highlight: widget.jumpToIndex == exerciseIndex,
                ),
              );
            }),
        ],
      ),
    );
  }
}
