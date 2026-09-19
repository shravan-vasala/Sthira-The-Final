import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/friend.dart';
import '../../../models/social_profile.dart';
import '../../../providers/app_providers.dart';
import '../../../services/social_sync_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_bottom_sheet.dart';
import 'friend_avatar.dart';

Future<void> showFriendDetailsSheet(BuildContext context, Friend friend) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final generation = container.read(accountGenerationProvider);
  await showAppBottomSheet<void>(
    context: context,
    builder: (_) => FriendDetailsSheet(friend: friend, generation: generation),
  );
}

String friendSharingMessage(Object? error) {
  final code = error is FirebaseException
      ? error.code
      : error is SocialSyncException
      ? error.code
      : null;
  if (code == 'permission-denied') {
    return 'Shared activity is not available to your account.';
  }
  return error == null
      ? 'No shared activity is available yet.'
      : 'Could not load shared activity. Please try again.';
}

String friendLastSharedLabel(SocialProfile profile, DateTime now) {
  final shared = profile.lastUpdatedAt.toLocal();
  if (!profile.hasValidSharedTimestamp ||
      shared.isAfter(now.toLocal().add(const Duration(minutes: 5)))) {
    return 'Last shared time unavailable';
  }
  return 'Last shared ${DateFormat.yMMMd().add_jm().format(shared)}';
}

class FriendDetailsSheet extends ConsumerWidget {
  const FriendDetailsSheet({
    super.key,
    required this.friend,
    required this.generation,
  });
  final Friend friend;
  final int generation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final changed =
        ref.watch(accountGenerationProvider) != generation ||
        ref.watch(accountTransitionProvider);
    final now = ref.watch(clockProvider);
    final roster = changed
        ? null
        : ref.watch(friendsListStreamProvider).valueOrNull;
    final removed =
        roster != null && !roster.any((value) => value.uid == friend.uid);
    return AppSheet(
      title: 'Friend details',
      titleAction: IconButton(
        tooltip: 'Close friend details',
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.close_rounded),
      ),
      child: changed
          ? Text(
              'Your account changed. Close this sheet to continue.',
              style: context.text.body,
            )
          : removed
          ? Text(
              'This friend has been removed. Close this sheet to continue.',
              style: context.text.body,
            )
          : ref
                .watch(friendProfileStreamProvider(friend.uid))
                .when(
                  skipLoadingOnRefresh: false,
                  skipLoadingOnReload: false,
                  data: (profile) => profile == null
                      ? _Unavailable(friend: friend)
                      : _SharedDetails(
                          profile: profile,
                          now: now,
                          sharedNow: ref.read(socialSnapshotClockProvider)(),
                        ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(Spacing.section),
                    child: Center(
                      child: CircularProgressIndicator(
                        semanticsLabel: 'Loading shared activity',
                      ),
                    ),
                  ),
                  error: (error, _) =>
                      _Unavailable(friend: friend, error: error),
                ),
    );
  }
}

class _Unavailable extends ConsumerWidget {
  const _Unavailable({required this.friend, this.error});
  final Friend friend;
  final Object? error;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(friendSharingMessage(error), style: context.text.body),
      const SizedBox(height: Spacing.stack),
      TextButton.icon(
        onPressed: () =>
            ref.invalidate(friendProfileStreamProvider(friend.uid)),
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Retry'),
      ),
    ],
  );
}

class _SharedDetails extends StatelessWidget {
  const _SharedDetails({
    required this.profile,
    required this.now,
    required this.sharedNow,
  });
  final SocialProfile profile;
  final DateTime now;
  final DateTime sharedNow;
  String number(int? value) => value == null
      ? 'Not shared'
      : NumberFormat.decimalPattern().format(value);

  @override
  Widget build(BuildContext context) {
    final day = profile.statsDay;
    final today = DateTime(now.year, now.month, now.day);
    final validDay = day != null && !day.isAfter(today);
    final week = profile.sharedWeekStart;
    final validWeek = week != null && !week.isAfter(today) && validDay;
    final stepsDays = profile.weeklyStepsRecordedDays;
    final scoreDays = profile.weekScoreRecordedDays;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            FriendAvatar(
              name: profile.name,
              avatarUrl: profile.avatarUrl,
              size: 56,
            ),
            const SizedBox(width: Spacing.stack),
            Expanded(
              child: Text(
                profile.name.trim().isEmpty ? 'Friend' : profile.name,
                style: context.text.cardTitle,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.stack),
        Text(
          friendLastSharedLabel(profile, sharedNow),
          style: context.text.caption.copyWith(
            color: context.colors.textMedium,
          ),
        ),
        const SizedBox(height: Spacing.section),
        Text(
          validDay
              ? 'Daily snapshot · ${DateFormat.yMMMd().format(day)}'
              : 'Daily snapshot date unavailable',
          style: context.text.bodyStrong,
        ),
        const SizedBox(height: Spacing.stack),
        _DetailValue(
          label: 'Steps',
          value: number(
            validDay && profile.hasKnownTodaySteps ? profile.todaySteps : null,
          ),
        ),
        _DetailValue(
          label: 'Completed workouts',
          value: number(validDay ? profile.todayWorkoutsValue : null),
        ),
        _DetailValue(
          label: 'Daily score',
          value: validDay && profile.todayScore != null
              ? '${profile.todayScore} / 100'
              : 'Not shared',
        ),
        _DetailValue(
          label: 'Step-goal streak',
          value: validDay && profile.currentStreakValue != null
              ? '${profile.currentStreakValue} days'
              : 'Not shared',
        ),
        Text(
          'The streak counts consecutive scheduled step-goal days, as last shared.',
          style: context.text.caption.copyWith(
            color: context.colors.textMedium,
          ),
        ),
        const SizedBox(height: Spacing.section),
        Text(
          validWeek
              ? 'Week of ${DateFormat.yMMMd().format(week)}'
              : 'Weekly snapshot date unavailable',
          style: context.text.bodyStrong,
        ),
        const SizedBox(height: Spacing.stack),
        _DetailValue(
          label: 'Recorded steps',
          value: number(
            validWeek && profile.hasKnownWeeklySteps
                ? profile.weeklySteps
                : null,
          ),
        ),
        Text(
          !validWeek || stepsDays == null
              ? 'Step recording coverage was not shared.'
              : '$stepsDays ${stepsDays == 1 ? 'day' : 'days'} with recorded steps.',
          style: context.text.caption.copyWith(
            color: context.colors.textMedium,
          ),
        ),
        _DetailValue(
          label: 'Completed workouts',
          value: number(validWeek ? profile.weeklyWorkoutsValue : null),
        ),
        _DetailValue(
          label: 'Average daily score',
          value: validWeek && profile.hasKnownWeekScore
              ? '${profile.weekScore} / 100'
              : 'Not shared',
        ),
        Text(
          validWeek && profile.hasKnownWeekScore
              ? 'Based on $scoreDays recorded ${scoreDays == 1 ? 'day' : 'days'} in this week.'
              : 'A dated weekly score and its recording coverage have not been shared.',
          style: context.text.caption.copyWith(
            color: context.colors.textMedium,
          ),
        ),
        const SizedBox(height: Spacing.section),
        Text(
          'Figures reflect the last shared snapshot.',
          style: context.text.caption.copyWith(
            color: context.colors.textMedium,
          ),
        ),
      ],
    );
  }
}

class _DetailValue extends StatelessWidget {
  const _DetailValue({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Spacing.stack),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            constraints.maxWidth < 280 ||
            MediaQuery.textScalerOf(context).scale(14) > 20;
        final title = Text(
          label,
          style: context.text.body.copyWith(color: context.colors.textMedium),
        );
        final data = Text(value, style: context.text.bodyStrong);
        return Semantics(
          label: '$label: $value',
          excludeSemantics: true,
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: Spacing.textPair),
                    data,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: Spacing.stack),
                    Flexible(child: data),
                  ],
                ),
        );
      },
    ),
  );
}
