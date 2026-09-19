import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../providers/badge_engine_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../models/badge.dart';
import '../../../share/share_card_exporter.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_bottom_sheet.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/surface_card.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';
import '../../../theme/app_motion.dart';

class TrophyRoomCard extends ConsumerWidget {
  const TrophyRoomCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badges = ref.watch(badgesProvider);
    if (badges.isEmpty) return const SizedBox.shrink();

    final unlocked = badges.where((b) => b.isUnlocked).length;

    // Sorting
    final sortedBadges = List<Badge>.from(badges);
    sortedBadges.sort((a, b) {
      if (a.isUnlocked && !b.isUnlocked) return -1;
      if (!a.isUnlocked && b.isUnlocked) return 1;
      if (a.isUnlocked && b.isUnlocked) {
        final dateA = a.unlockedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.unlockedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      }
      final progA = a.requiredProgress > 0
          ? a.currentProgress / a.requiredProgress
          : 0.0;
      final progB = b.requiredProgress > 0
          ? b.currentProgress / b.requiredProgress
          : 0.0;
      return progB.compareTo(progA);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Spacing.stack),
          child: TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: unlocked),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : Motion.deliberate,
            curve: Motion.enter,
            builder: (context, val, child) {
              return SectionHeader(
                'Trophy room ($val/${badges.length})',
                horizontalPadding: 0,
              );
            },
          ),
        ),
        SurfaceCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(Spacing.cardPad),
          color: context.colors.card,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Keep the familiar three-column shelf where it fits, then give
              // larger system text more room without clipping badge names.
              final captionSize = context.text.caption.fontSize!;
              final textScale =
                  MediaQuery.textScalerOf(context).scale(captionSize) /
                  captionSize;
              final minimumTileWidth =
                  88 * textScale.clamp(1.0, double.infinity);
              final columns =
                  ((constraints.maxWidth + Spacing.inline) /
                          (minimumTileWidth + Spacing.inline))
                      .floor()
                      .clamp(1, 3);
              final tileWidth =
                  (constraints.maxWidth - Spacing.inline * (columns - 1)) /
                  columns;

              return Wrap(
                spacing: Spacing.inline,
                runSpacing: Spacing.section,
                children: [
                  for (final badge in sortedBadges)
                    SizedBox(
                      width: tileWidth,
                      child: _BadgeItem(badge: badge),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final Badge badge;

  const _BadgeItem({required this.badge});

  static void showDetailSheet(BuildContext context, Badge badge) {
    HapticFeedback.lightImpact();
    // Wrap with the generic bottom sheet handler
    showAppBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final isUnlocked = badge.isUnlocked;
        final disableAnimations = MediaQuery.disableAnimationsOf(context);
        return AppSheet(
          title: badge.title,
          subtitle: badge.description,
          scrollable: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isUnlocked
                          ? context.colors.primary.withValues(alpha: 0.1)
                          : context.colors.inputFill,
                      border: Border.all(
                        color: isUnlocked
                            ? context.colors.primary.withValues(alpha: 0.45)
                            : context.colors.border,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: isUnlocked ? 1.0 : 0.4,
                      child: Text(
                        badge.iconEmoji,
                        textScaler: TextScaler.noScaling,
                        style: context.text.metric,
                      ),
                    ),
                  )
                  .animate(target: (isUnlocked && !disableAnimations) ? 1 : 0)
                  .shimmer(duration: Motion.deliberate, color: Colors.white24),

              const SizedBox(height: 32),

              if (isUnlocked) ...[
                Text(
                  'Unlocked ${DateFormat('MMMM d, yyyy').format(badge.unlockedAt ?? DateTime.now())}',
                  style: context.text.caption.copyWith(
                    color: context.colors.textMedium,
                  ),
                ),
              ] else ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'HOW TO EARN:',
                    style: context.text.eyebrow.copyWith(
                      color: context.colors.textLight,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: badge.requiredProgress > 0
                        ? badge.currentProgress / badge.requiredProgress
                        : 0,
                    backgroundColor: context.colors.border,
                    color: context.colors.textMedium,
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Progress',
                      style: context.text.caption.copyWith(
                        color: context.colors.textMedium,
                      ),
                    ),
                    Text(
                      '${badge.currentProgress} / ${badge.requiredProgress}',
                      style: AppTheme.numeric(
                        context.text.body.copyWith(
                          color: context.colors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              if (isUnlocked)
                _BadgeShareButton(badge: badge)
              else
                PrimaryButton(
                  onPressed: () => Navigator.of(context).pop(),
                  label: 'Got it',
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUnlocked = badge.isUnlocked;
    final progressFrac = badge.requiredProgress > 0
        ? badge.currentProgress / badge.requiredProgress
        : 0.0;

    Widget medallion = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isUnlocked
            ? context.colors.primary.withValues(alpha: 0.1)
            : context.colors.inputFill,
        border: isUnlocked
            ? Border.all(
                color: context.colors.primary.withValues(alpha: 0.45),
                width: 1.5,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.4,
        child: Text(
          badge.iconEmoji,
          textScaler: TextScaler.noScaling,
          style: context.text.screenTitle,
        ),
      ),
    );

    if (!isUnlocked) {
      if (badge.currentProgress > 0) {
        medallion = Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: CircularProgressIndicator(
                value: progressFrac,
                strokeWidth: 2,
                backgroundColor: context.colors.border,
                color: context.colors.textMedium,
              ),
            ),
            medallion,
          ],
        );
      }
    }

    final status = isUnlocked
        ? 'Unlocked ${DateFormat('MMMM d, yyyy').format(badge.unlockedAt!)}'
        : 'Locked. ${badge.currentProgress} of ${badge.requiredProgress} completed';
    Widget tile = Semantics(
      button: true,
      label: '${badge.title}. $status',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.control),
        child: InkWell(
          onTap: () => showDetailSheet(context, badge),
          borderRadius: BorderRadius.circular(Radii.control),
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.textPair,
                vertical: Spacing.inline,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  medallion,
                  const SizedBox(height: Spacing.stack),
                  Text(
                    badge.title,
                    textAlign: TextAlign.center,
                    style: context.text.caption.copyWith(
                      color: isUnlocked
                          ? context.colors.textDark
                          : context.colors.textMedium,
                    ),
                  ),
                  const SizedBox(height: Spacing.textPair),
                  if (!isUnlocked)
                    Text(
                      '${badge.currentProgress}/${badge.requiredProgress}',
                      textAlign: TextAlign.center,
                      style: AppTheme.numeric(context.text.caption),
                    )
                  else
                    Text(
                      DateFormat('MMM d').format(badge.unlockedAt!),
                      textAlign: TextAlign.center,
                      style: context.text.caption,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (isUnlocked && !disableAnimations) {
      tile = tile.animate().shimmer(
        delay: Motion.standard,
        duration: Motion.deliberate,
        color: Colors.white.withValues(alpha: 0.2),
      );
    }

    return tile;
  }
}

class _BadgeShareCard extends StatelessWidget {
  final Badge badge;
  const _BadgeShareCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      height: 450,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.colors.primary.withValues(alpha: 0.15),
              border: Border.all(
                color: context.colors.primary.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              badge.iconEmoji,
              textScaler: TextScaler.noScaling,
              style: context.text.metric,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            badge.title,
            style: context.text.display.copyWith(
              color: context.colors.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              badge.description,
              style: context.text.bodyStrong.copyWith(
                color: context.colors.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Unlocked on ${DateFormat('MMMM d, yyyy').format(badge.unlockedAt ?? DateTime.now())}',
            style: context.text.body.copyWith(color: context.colors.primary),
          ),
        ],
      ),
    );
  }
}

class _BadgeShareButton extends StatefulWidget {
  const _BadgeShareButton({required this.badge});
  final Badge badge;
  @override
  State<_BadgeShareButton> createState() => _BadgeShareButtonState();
}

class _BadgeShareButtonState extends State<_BadgeShareButton> {
  bool _sharing = false;
  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final result = await ShareCardExporter.exportAndShareWidget(
      context: context,
      widget: _BadgeShareCard(badge: widget.badge),
      fileName: 'sthira_badge_${widget.badge.id}',
      text: 'I earned the ${widget.badge.title} badge in Sthira!',
    );
    if (!mounted) return;
    setState(() => _sharing = false);
    if (result == ShareExportResult.success) {
      Navigator.of(context).pop();
    } else if (result == ShareExportResult.failed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not prepare the badge image. Try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => PrimaryButton(
    label: 'Share Badge',
    icon: Icons.share_rounded,
    isLoading: _sharing,
    onPressed: _sharing ? null : _share,
  );
}
