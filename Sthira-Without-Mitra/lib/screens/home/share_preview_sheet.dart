import 'package:trufit_bodamma/theme/app_typography.dart';
import 'package:trufit_bodamma/theme/app_colors.dart';
import 'package:trufit_bodamma/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../share/share_card_exporter.dart';
import '../../share/daily_share_layout.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/primary_button.dart';
import '../../theme/layout_insets.dart';
import '../../theme/app_motion.dart';
import '../../models/habit.dart';

class SharePreviewSheet extends ConsumerStatefulWidget {
  const SharePreviewSheet({super.key});

  @override
  ConsumerState<SharePreviewSheet> createState() => _SharePreviewSheetState();
}

class _SharePreviewSheetState extends ConsumerState<SharePreviewSheet> {
  ShareFormat _format = ShareFormat.post;
  bool _isSharing = false;

  void _shareImage(Widget layout, String subtitle) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      final success = await ShareCardExporter.exportAndShareWidget(
        context: context,
        widget: layout,
        fileName: 'sthira_daily_status',
        text: subtitle,
        format: _format,
      );
      if (success == ShareExportResult.success && mounted) {
        Navigator.of(context).pop();
      } else if (success == ShareExportResult.failed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not prepare the share image. Try again.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to prepare share image'),
            backgroundColor: context.colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  String _getSubtitle(int totalScore) {
    if (totalScore >= 100) return 'Crushed all daily goals! 🔥';
    if (totalScore >= 80) return 'Almost perfect today! ⭐';
    if (totalScore >= 50) return 'Making steady progress 🌿';
    if (totalScore >= 20) return 'Getting moving today 🏃';
    return 'Just getting started 🌅';
  }

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(profileProvider.select((p) => p.name));
    final scoreData = ref.watch(dailyScoreProvider);
    final score = scoreData.totalScore;
    final selectedDate = ref.watch(selectedDateProvider);

    final dailyLog = ref.watch(dailyLogProvider);
    final mealsLog = ref.watch(dailyMealLogProvider);
    final habits = DailyScore.habitsForDate(
      ref.watch(allHabitsProvider),
      selectedDate,
    );
    final completions = ref.watch(habitCompletionsProvider);
    final habitsCount = habits.length;
    final habitsCompleted = habits
        .where((h) => isHabitCompleted(h, completions, dailyLog))
        .length;

    final steps = dailyLog.steps ?? 0;
    final mealsKcal = mealsLog.totalCalories;
    final workoutDone = dailyLog.workoutCompleted;
    final habitsDone = habitsCount > 0
        ? '$habitsCompleted/$habitsCount'
        : '0/0';

    final subtitle = _getSubtitle(score);
    // Base color tied to score
    Color baseColor = context.colors.green;
    if (score < 50) {
      baseColor = context.colors.red;
    } else if (score < 80) {
      baseColor = context.colors.orange;
    }

    final layout = DailyShareLayout(
      format: _format,
      userName: name,
      score: score,
      subtitle: subtitle,
      steps: steps,
      mealsKcal: mealsLog.hasCompleteCalories ? mealsKcal : 0,
      workoutDone: workoutDone,
      habitsDone: habitsDone,
      baseColor: baseColor,
      date: selectedDate,
    );

    final previewWidth = 360.0;
    final previewHeight = _format == ShareFormat.post ? 450.0 : 640.0;

    return AppSheet(
      title: 'Share Your Progress',
      scrollable: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Format Toggle Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FormatChip(
                label: 'Post 4:5',
                isSelected: _format == ShareFormat.post,
                onTap: () => setState(() => _format = ShareFormat.post),
              ),
              const SizedBox(width: 8),
              _FormatChip(
                label: 'Story 9:16',
                isSelected: _format == ShareFormat.story,
                onTap: () => setState(() => _format = ShareFormat.story),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Live Preview Box bounded by constraints
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AnimatedContainer(
              duration: Motion.standard,
              curve: Motion.enter,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: AspectRatio(
                aspectRatio: previewWidth / previewHeight,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: previewWidth,
                    height: previewHeight,
                    child: layout,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
          PrimaryButton(
            label: _isSharing ? 'Preparing...' : 'Share Image',
            onPressed: _isSharing ? null : () => _shareImage(layout, subtitle),
            icon: Icons.ios_share_rounded,
            isLoading: _isSharing,
          ),
        ],
      ),
    );
  }
}

class _FormatChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: Motion.standard,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.colors.primary : context.colors.surface,
          borderRadius: BorderRadius.circular(Radii.chip),
          border: Border.all(
            color: isSelected ? Colors.transparent : context.colors.border,
          ),
        ),
        child: Text(
          label,
          style: context.text.caption.copyWith(
            color: isSelected
                ? context.colors.onPrimary
                : context.colors.textMedium,
          ),
        ),
      ),
    );
  }
}
