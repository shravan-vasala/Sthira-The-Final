import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../../../models/workout_plan.dart';
import '../../../utils/exercise_log_save.dart';
import '../../../widgets/surface_card.dart';
import '../../../widgets/app_bottom_sheet.dart';
import '../../../theme/app_theme.dart';
import '../log_data_dialog.dart';
import '../../../utils/format_units.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_motion.dart';

class ExerciseCard extends ConsumerStatefulWidget {
  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.dayId,
    this.highlight = false,
  });

  final Exercise exercise;
  final String dayId;
  final bool highlight;

  @override
  ConsumerState<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends ConsumerState<ExerciseCard> {
  bool _saving = false;
  Exercise get exercise => widget.exercise;
  bool get highlight => widget.highlight;

  @override
  Widget build(BuildContext context) {
    ref.watch(exerciseLogsUpdateProvider);
    ref.watch(exerciseRecordsUpdateProvider);
    ref.watch(accountGenerationProvider);
    final pr = ref.watch(exercisePrProvider(exercise.name ?? ''));
    final logRepo = ref.watch(exerciseLogRepoProvider);
    final profile = ref.watch(profileProvider);
    final useKg = profile.useKg;
    final dateStr = ref.watch(dateStringProvider);
    final log = logRepo.getLog(
      dateStr,
      exercise.instanceId ?? exercise.name ?? '',
    );
    final isCompleted = logRepo.hasLog(
      dateStr,
      exercise.instanceId ?? exercise.name ?? '',
    );

    final selectedDate = ref.watch(selectedDateProvider);
    final now = ref.watch(clockProvider);
    final today = DateTime(now.year, now.month, now.day);
    final isFuture = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    ).isAfter(today);

    String? loggedText;
    if (log != null && log.sets.isNotEmpty) {
      final repsList = log.sets
          .map((s) {
            if ((s.durationSeconds ?? 0) > 0) return '${s.durationSeconds} s';
            if ((s.weight ?? 0) > 0) {
              final w = convertFromKg(profile, s.weight!);
              return '${s.reps} × ${w.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} ${useKg ? 'kg' : 'lb'}';
            }
            return '${s.reps}';
          })
          .join(', ');
      loggedText = 'Done: $repsList';
    }

    return SurfaceCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(Spacing.cardPadTight),
      elevation: SurfaceCardElevation.home,
      color: highlight ? context.colors.primary.withValues(alpha: 0.05) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // YouTube Thumbnail
              Semantics(
                label:
                    'Play ${exercise.displayName ?? exercise.name ?? ''} video tutorial',
                button: true,
                child: GestureDetector(
                  onTap: () async {
                    final videoId = exercise.youtubeVideoId;
                    if (videoId != null &&
                        videoId != 'XXXX' &&
                        videoId.isNotEmpty) {
                      // ignore: unawaited_futures
                      context.push(
                        '/youtube-player?videoId=$videoId&title=${Uri.encodeComponent(exercise.displayName ?? exercise.name ?? '')}&subtitle=${Uri.encodeComponent(exercise.name ?? '')}&reps=${Uri.encodeComponent(exercise.repsDisplay)}',
                      );
                    } else {
                      final query = Uri.encodeComponent(
                        '${exercise.displayName ?? exercise.name ?? ''} exercise tutorial',
                      );
                      final url = Uri.parse(
                        'https://www.youtube.com/results?search_query=$query',
                      );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    }
                  },
                  child: Container(
                    width: 90,
                    height: 68,
                    decoration: BoxDecoration(
                      color: context.colors.insetSurface,
                      borderRadius: BorderRadius.circular(Radii.chip),
                    ),
                    child:
                        (exercise.youtubeVideoId == null ||
                            exercise.youtubeVideoId == 'XXXX' ||
                            exercise.youtubeVideoId!.isEmpty)
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_rounded,
                                color: context.colors.primary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Search YT',
                                style: context.text.micro.copyWith(
                                  color: context.colors.primary,
                                ),
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(Radii.chip),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (exercise.thumbnailUrl.isNotEmpty)
                                  CachedNetworkImage(
                                    imageUrl: exercise.thumbnailUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (ctx, url) => Center(
                                      child: Icon(
                                        Icons.fitness_center_rounded,
                                        color: context.colors.primary,
                                        size: 30,
                                      ),
                                    ),
                                    errorWidget: (ctx, url, error) => Center(
                                      child: Icon(
                                        Icons.fitness_center_rounded,
                                        color: context.colors.primary,
                                        size: 30,
                                      ),
                                    ),
                                  )
                                else
                                  Center(
                                    child: Icon(
                                      Icons.fitness_center_rounded,
                                      color: context.colors.primary,
                                      size: 30,
                                    ),
                                  ),
                                // Play overlay
                                if (exercise.youtubeUrl != null &&
                                    exercise.youtubeUrl!.isNotEmpty)
                                  Center(
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.5,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.play_arrow_rounded,
                                        color: context.colors.card,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: Spacing.stack),

              // Exercise info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.displayName ?? exercise.name ?? '',
                      style: context.text.bodyStrong.copyWith(
                        color: context.colors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: Spacing.inline,
                      runSpacing: Spacing.textPair,
                      children: [
                        Text(
                          plannedDurationTargets(exercise).isNotEmpty
                              ? exercise.repsDisplay
                              : '${exercise.repsDisplay} Reps',
                          style: AppTheme.numeric(
                            context.text.caption.copyWith(
                              color: context.colors.primary,
                            ),
                          ),
                        ),
                        if (exercise.weightKg != null) ...[
                          Text(
                            '•',
                            style: context.text.micro.copyWith(
                              color: context.colors.border,
                            ),
                          ),
                          Text(
                            '${convertFromKg(profile, exercise.weightKg!).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} ${useKg ? 'kg' : 'lb'}',
                            style: AppTheme.numeric(
                              context.text.caption.copyWith(
                                color: context.colors.primary,
                              ),
                            ),
                          ),
                        ],
                        if (exercise.sideInfo != 'None') ...[
                          Text(
                            '•',
                            style: context.text.micro.copyWith(
                              color: context.colors.border,
                            ),
                          ),
                          Text(
                            exercise.sideInfo,
                            style: context.text.micro.copyWith(
                              color: context.colors.mintIcon,
                            ),
                          ),
                        ],
                        if (pr != null &&
                            (pr.maxReps > 0 || pr.maxWeight > 0)) ...[
                          Text(
                            '•',
                            style: context.text.micro.copyWith(
                              color: context.colors.border,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.emoji_events_rounded,
                                size: 14,
                                color: Color(0xFFB8860B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                pr.maxWeight > 0
                                    ? '${convertFromKg(profile, pr.maxWeight).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}${useKg ? 'kg' : 'lb'}'
                                    : '${pr.maxReps} reps',
                                style: AppTheme.numeric(
                                  context.text.micro.copyWith(
                                    color: const Color(0xFFB8860B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    if (loggedText != null) ...[
                      const SizedBox(height: Spacing.textPair),
                      Text(
                        loggedText,
                        style: context.text.micro.copyWith(
                          color: context.colors.green,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Checkmark
              Semantics(
                label:
                    '${isCompleted ? 'Edit log for' : 'Log'} ${exercise.displayName ?? exercise.name ?? ''}',
                button: true,
                child: GestureDetector(
                  onTap: isFuture || _saving
                      ? null
                      : () {
                          showAppBottomSheet(
                            context: context,
                            builder: (_) => LogDataDialog(exercise: exercise),
                          );
                        },
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: AnimatedContainer(
                        duration: Motion.standard,
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? context.colors.green
                              : context.colors.textLight.withValues(
                                  alpha: 0.15,
                                ),
                        ),
                        child: isCompleted
                            ? TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0, end: 1),
                                duration: Motion.deliberate,
                                curve: Motion.enter,
                                builder: (context, scale, child) {
                                  return Transform.scale(
                                    scale: scale,
                                    child: Icon(
                                      Icons.check_rounded,
                                      color: context.colors.onPrimary,
                                      size: 18,
                                    ),
                                  );
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (exercise.name == 'Home Cardio' &&
              exercise.durationSeconds == null &&
              exercise.reps.length == 1 &&
              exercise.reps.single == '1')
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.stack),
              child: Text(
                'Expert target: 1. No duration is specified; follow the expert video for session guidance.',
                style: context.text.caption.copyWith(
                  color: context.colors.textMedium,
                ),
              ),
            ),

          // Coach note
          if (exercise.note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.colors.insetSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 16,
                      color: context.colors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        exercise.note,
                        style: context.text.caption.copyWith(
                          color: context.colors.textMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Button row
          Wrap(
            spacing: Spacing.inline,
            runSpacing: Spacing.textPair,
            children: [
              if (!isCompleted &&
                  (plannedRepTargets(exercise).isNotEmpty ||
                      plannedDurationTargets(exercise).isNotEmpty))
                _MinimalAction(
                  label: _saving ? 'Saving…' : 'As planned',
                  icon: Icons.check_circle_outline_rounded,
                  onTap: isFuture || _saving
                      ? null
                      : () => _logAsPlanned(context, ref),
                  color: context.colors.primary,
                ),
              _MinimalAction(
                label: isCompleted ? 'Edit Log' : 'Adjust',
                icon: Icons.edit_outlined,
                onTap: isFuture || _saving
                    ? null
                    : () => _openLogSheet(context),
              ),
              _MinimalAction(
                label: 'Progress',
                icon: Icons.bar_chart_rounded,
                onTap: () {
                  context.push(
                    '/exercise-progress?name=${Uri.encodeComponent(exercise.name ?? '')}',
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openLogSheet(BuildContext context) {
    showAppBottomSheet(
      context: context,
      builder: (_) => LogDataDialog(exercise: exercise),
    );
  }

  Future<void> _logAsPlanned(BuildContext context, WidgetRef ref) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final prResult = await saveExerciseAsPlanned(
        ref: ref,
        exercise: exercise,
      );
      if (!context.mounted) return;

      final profile = ref.read(profileProvider);
      final useKg = profile.useKg;

      String msg = 'Logged ${exercise.name}';
      if (prResult.hasAnyNewPr) {
        if (prResult.isNewMaxWeight) {
          final w = convertFromKg(
            profile,
            prResult.newPr.maxWeight,
          ).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
          msg = 'New PR! $w${useKg ? 'kg' : 'lb'}';
        } else if (prResult.isNewMaxReps) {
          msg = 'New PR! ${prResult.newPr.maxReps} reps';
        } else if (prResult.isNewMaxVolume) {
          msg = 'New PR! ${prResult.newPr.maxVolume} vol';
        } else if (prResult.isNew1RM) {
          msg = 'New 1RM PR!';
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: prResult.hasAnyNewPr
              ? context.colors.green
              : context.colors.primary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (error) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is StateError
                  ? error.message.toString()
                  : 'Could not finish saving. Please try again.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _MinimalAction extends StatelessWidget {
  const _MinimalAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final baseColor = onTap == null
        ? context.colors.textLight
        : color ?? context.colors.textMedium;
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: baseColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: context.text.caption.copyWith(color: baseColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
