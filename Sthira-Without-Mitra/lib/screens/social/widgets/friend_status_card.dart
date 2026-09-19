import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/friend.dart';
import '../../../models/social_profile.dart';
import '../../../providers/app_providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/surface_card.dart';
import 'friend_avatar.dart';
import 'friend_details_sheet.dart';

class FriendStatusCard extends ConsumerWidget {
  final Friend friend;
  const FriendStatusCard({super.key, required this.friend});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(accountGenerationProvider);
    if (ref.watch(accountTransitionProvider)) return const SizedBox.shrink();
    final now = ref.watch(clockProvider);
    final profileAsync = ref.watch(friendProfileStreamProvider(friend.uid));
    return SurfaceCard(
      margin: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        textStyle: DefaultTextStyle.of(context).style,
        child: profileAsync.when(
          skipLoadingOnRefresh: false,
          skipLoadingOnReload: false,
          data: (profile) => _content(context, ref, now, profile: profile),
          loading: () => _content(context, ref, now, loading: true),
          error: (error, _) => _content(context, ref, now, error: error),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    WidgetRef ref,
    DateTime now, {
    SocialProfile? profile,
    Object? error,
    bool loading = false,
  }) {
    final name = profile?.name.trim().isNotEmpty == true
        ? profile!.name
        : friend.name.trim().isNotEmpty
        ? friend.name
        : 'Friend';
    final current = profile?.isCurrentDay(now) ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FriendAvatar(
              name: name,
              avatarUrl: profile?.avatarUrl ?? friend.avatarUrl,
            ),
            const SizedBox(width: Spacing.inline),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: context.text.bodyStrong),
                  if (profile != null) ...[
                    const SizedBox(height: Spacing.textPair),
                    Text(
                      friendLastSharedLabel(
                        profile,
                        ref.read(socialSnapshotClockProvider)(),
                      ),
                      style: context.text.caption.copyWith(
                        color: context.colors.textMedium,
                      ),
                    ),
                  ],
                  if (current && profile?.todayScore != null) ...[
                    const SizedBox(height: Spacing.inline),
                    _ScoreBadge(score: profile!.todayScore!),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Options for $name',
              icon: Icon(
                Icons.more_vert_rounded,
                color: context.colors.textMedium,
              ),
              onSelected: (value) {
                if (value == 'remove') {
                  final generation = ref.read(accountGenerationProvider);
                  showDialog<void>(
                    context: context,
                    builder: (_) => _RemoveFriendDialog(
                      friend: friend,
                      generation: generation,
                    ),
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'remove', child: Text('Remove friend')),
              ],
            ),
          ],
        ),
        const SizedBox(height: Spacing.stack),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: Spacing.stack),
            child: Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Loading shared activity',
              ),
            ),
          )
        else if (profile == null) ...[
          Text(
            friendSharingMessage(error),
            style: context.text.body.copyWith(color: context.colors.textMedium),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () =>
                  ref.invalidate(friendProfileStreamProvider(friend.uid)),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ),
        ] else ...[
          if (!current)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.stack),
              child: Text(
                'Today’s activity has not been shared.',
                style: context.text.caption.copyWith(
                  color: context.colors.textMedium,
                ),
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final large = MediaQuery.textScalerOf(context).scale(14) > 20;
              final columns = large
                  ? 1
                  : constraints.maxWidth < 260
                  ? 2
                  : 3;
              final width =
                  (constraints.maxWidth - Spacing.stack * (columns - 1)) /
                  columns;
              return Wrap(
                spacing: Spacing.stack,
                runSpacing: Spacing.stack,
                children: [
                  SizedBox(
                    width: width,
                    child: _StatBlock(
                      icon: Icons.directions_walk_rounded,
                      value: current && profile.hasKnownTodaySteps
                          ? profile.todaySteps
                          : null,
                      label: 'Steps',
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _StatBlock(
                      icon: Icons.fitness_center_rounded,
                      value: current ? profile.todayWorkoutsValue : null,
                      label: 'Completed workouts',
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _StatBlock(
                      icon: Icons.local_fire_department_rounded,
                      value: current ? profile.currentStreakValue : null,
                      label: 'Step-goal streak',
                    ),
                  ),
                ],
              );
            },
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => showFriendDetailsSheet(context, friend),
              icon: const Icon(Icons.chevron_right_rounded),
              label: const Text('View details'),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final int? value;
  final String label;
  @override
  Widget build(BuildContext context) {
    final display = value == null
        ? '—'
        : NumberFormat.decimalPattern().format(value);
    return Semantics(
      label: '$label: ${value == null ? 'not shared for today' : display}',
      excludeSemantics: true,
      child: Column(
        children: [
          Icon(icon, color: context.colors.primary, size: IconSize.row),
          const SizedBox(height: Spacing.textPair),
          Text(display, style: AppTheme.numeric(context.text.cardTitle)),
          Text(
            label,
            textAlign: TextAlign.center,
            style: context.text.caption.copyWith(
              color: context.colors.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});
  final int score;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Daily score: $score out of 100',
    excludeSemantics: true,
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.inline,
        vertical: Spacing.textPair,
      ),
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(Radii.micro),
      ),
      child: Text(
        '$score / 100',
        style: AppTheme.numeric(
          context.text.micro.copyWith(color: context.colors.accentText),
        ),
      ),
    ),
  );
}

class _RemoveFriendDialog extends ConsumerStatefulWidget {
  const _RemoveFriendDialog({required this.friend, required this.generation});
  final Friend friend;
  final int generation;
  @override
  ConsumerState<_RemoveFriendDialog> createState() =>
      _RemoveFriendDialogState();
}

class _RemoveFriendDialogState extends ConsumerState<_RemoveFriendDialog> {
  bool _removing = false;
  String? _error;

  Future<void> _remove() async {
    if (_removing ||
        ref.read(accountGenerationProvider) != widget.generation ||
        ref.read(accountTransitionProvider)) {
      return;
    }
    final generation = ref.read(accountGenerationProvider.notifier);
    final transition = ref.read(accountTransitionProvider.notifier);
    final coordinator = ref.read(socialRelationshipProvider);
    if (coordinator == null) {
      setState(() => _error = 'Friends are still loading. Please try again.');
      return;
    }
    bool ownsAccount() =>
        generation.mounted &&
        transition.mounted &&
        generation.state == widget.generation &&
        !transition.state;
    setState(() {
      _removing = true;
      _error = null;
    });
    try {
      await coordinator.removeFriend(widget.friend.uid);
      if (!ownsAccount()) return;
      if (mounted && ownsAccount()) Navigator.of(context).pop();
    } catch (_) {
      if (mounted && ownsAccount()) {
        setState(
          () => _error = 'Could not remove this friend. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _removing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final changed =
        ref.watch(accountGenerationProvider) != widget.generation ||
        ref.watch(accountTransitionProvider);
    return AlertDialog(
      title: const Text('Remove friend?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            changed
                ? 'Your account changed. Close this dialog to continue.'
                : 'Remove ${widget.friend.name} and stop sharing your activity with them? They may retain an earlier shared snapshot.',
          ),
          if (_error != null && !changed) ...[
            const SizedBox(height: Spacing.stack),
            Text(
              _error!,
              style: context.text.caption.copyWith(
                color: context.colors.textMedium,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(changed ? 'Close' : 'Cancel'),
        ),
        if (!changed)
          TextButton(
            onPressed: _removing ? null : _remove,
            child: Text(_removing ? 'Removing…' : 'Remove'),
          ),
      ],
    );
  }
}
