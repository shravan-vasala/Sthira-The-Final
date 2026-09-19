import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/friend.dart';
import '../../models/social_profile.dart';
import '../../providers/app_providers.dart';
import '../../services/social_sync_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/layout_insets.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/surface_card.dart';
import 'widgets/friend_status_card.dart';
import 'widgets/friend_avatar.dart';
import 'widgets/friend_details_sheet.dart';
import 'widgets/social_sign_in_prompt.dart';

class SocialFeedScreen extends ConsumerStatefulWidget {
  const SocialFeedScreen({super.key});
  @override
  ConsumerState<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends ConsumerState<SocialFeedScreen> {
  bool _refreshing = false;
  Future<void> _refresh() async {
    if (_refreshing) return;
    final generation = ref.read(accountGenerationProvider);
    final service = ref.read(socialSyncServiceProvider);
    final coordinator = ref.read(socialRelationshipProvider);
    bool current() =>
        mounted &&
        generation == ref.read(accountGenerationProvider) &&
        !ref.read(accountTransitionProvider) &&
        service.canSync;
    setState(() => _refreshing = true);
    ref.read(socialErrorProvider.notifier).state = null;
    ref.invalidate(friendRequestsProvider);
    ref.invalidate(friendsListStreamProvider);
    ref.invalidate(friendProfileStreamProvider);
    try {
      await coordinator?.refresh();
      if (current()) await service.flushProfile();
    } catch (_) {
      if (current())
        ref.read(socialErrorProvider.notifier).state = 'Refresh failed';
    } finally {
      if (mounted && generation == ref.read(accountGenerationProvider)) {
        setState(() => _refreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final generation = ref.watch(accountGenerationProvider);
    ref.listen(accountGenerationProvider, (_, __) {
      setState(() => _refreshing = false);
    });
    final auth = ref.watch(authServiceProvider);
    final transitioning =
        ref.watch(accountTransitionProvider) ||
        ref.watch(accountHydratingProvider);
    final signedIn =
        auth.isSignedIn &&
        auth.uid != null &&
        auth.currentUser?.isAnonymous != true;
    final count = signedIn && !transitioning
        ? ref.watch(friendRequestsCountProvider).valueOrNull ?? 0
        : 0;
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
    return DefaultTabController(
      key: ValueKey(generation),
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Social'),
          actions: signedIn && !transitioning
              ? [
                  IconButton(
                    tooltip: 'Connect with friends',
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    onPressed: () => context.push('/social/connect'),
                  ),
                ]
              : null,
          bottom: signedIn && !transitioning
              ? TabBar(
                  isScrollable: largeText,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                  tabAlignment: largeText
                      ? TabAlignment.start
                      : TabAlignment.fill,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Friends'),
                          if (count > 0) ...[
                            const SizedBox(width: 8),
                            Badge(
                              label: Text(count.toString()),
                              backgroundColor: context.colors.accentText,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Tab(text: 'Leaderboard'),
                  ],
                )
              : null,
        ),
        body: transitioning
            ? const Center(child: CircularProgressIndicator())
            : !signedIn
            ? const SocialSignInPrompt()
            : Column(
                children: [
                  if (ref.watch(socialErrorProvider) != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.screen,
                        vertical: Spacing.stack,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shared activity could not refresh. Your saved connections are kept.',
                            style: context.text.caption.copyWith(
                              color: context.colors.textMedium,
                            ),
                          ),
                          TextButton(
                            onPressed: _refreshing ? null : _refresh,
                            child: Text(
                              _refreshing ? 'Refreshing…' : 'Retry refresh',
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _FriendsTab(onRefresh: _refresh),
                        const _LeaderboardTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _FriendsTab extends ConsumerStatefulWidget {
  const _FriendsTab({required this.onRefresh});
  final Future<void> Function() onRefresh;
  @override
  ConsumerState<_FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends ConsumerState<_FriendsTab> {
  final _processing = <String>{};
  Future<void> _respond(Map<String, dynamic> request, bool accept) async {
    final uid = request['fromUid'];
    if (uid is! String || _processing.contains(uid)) return;
    final generation = ref.read(accountGenerationProvider);
    final service = ref.read(socialSyncServiceProvider);
    final repository = ref.read(friendRepoProvider);
    bool current() =>
        mounted &&
        generation == ref.read(accountGenerationProvider) &&
        !ref.read(accountTransitionProvider) &&
        service.canSync;
    if (!current()) return;
    setState(() => _processing.add(uid));
    try {
      if (accept) {
        await service.acceptFriendRequest(uid);
        if (!current()) return;
        await repository.addFriend(
          uid,
          request['fromName'] is String
              ? request['fromName'] as String
              : 'Friend',
          avatarUrl: request['fromAvatar'] is String
              ? request['fromAvatar'] as String
              : null,
        );
        if (!current()) return;
        ref.invalidate(friendProfileStreamProvider(uid));
      } else {
        await service.declineFriendRequest(uid);
      }
    } catch (error) {
      if (mounted && current()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is SocialSyncException
                  ? error.message
                  : 'Could not update this request. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (current()) setState(() => _processing.remove(uid));
    }
  }

  Widget _request(Map<String, dynamic> request) {
    final uid = request['fromUid'];
    if (uid is! String || uid.isEmpty) return const SizedBox.shrink();
    final rawName = request['fromName'];
    final name = rawName is String && rawName.trim().isNotEmpty
        ? rawName.trim()
        : 'Friend';
    final avatar = request['fromAvatar'] is String
        ? request['fromAvatar'] as String
        : null;
    final busy = _processing.contains(uid);
    return Padding(
      key: ValueKey('request-$uid'),
      padding: const EdgeInsets.only(bottom: Spacing.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              FriendAvatar(name: name, avatarUrl: avatar),
              const SizedBox(width: Spacing.stack),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: context.text.bodyStrong),
                    Text(
                      'Wants to connect',
                      style: context.text.caption.copyWith(
                        color: context.colors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.stack),
          if (busy)
            Semantics(
              liveRegion: true,
              label: 'Updating friend request',
              child: SizedBox(
                height: 48,
                child: Center(
                  child: SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: Spacing.stack,
              children: [
                FilledButton.icon(
                  onPressed: () => _respond(request, true),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Accept'),
                ),
                TextButton(
                  onPressed: () => _respond(request, false),
                  child: const Text('Decline'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(friendRequestsProvider);
    final friends = ref.watch(friendsListStreamProvider);
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              Spacing.screen,
              Spacing.section,
              Spacing.screen,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: requests.when(
                skipLoadingOnReload: false,
                data: (items) => items.isEmpty
                    ? const SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('FRIEND REQUESTS', style: context.text.eyebrow),
                          const SizedBox(height: Spacing.section),
                          ...items.map(_request),
                        ],
                      ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(Spacing.stack),
                  child: LinearProgressIndicator(
                    semanticsLabel: 'Loading friend requests',
                  ),
                ),
                error: (_, __) => _RetryMessage(
                  message: 'Could not load friend requests.',
                  label: 'Retry requests',
                  onRetry: () => ref.invalidate(friendRequestsProvider),
                ),
              ),
            ),
          ),
          friends.when(
            skipLoadingOnReload: false,
            data: (items) => items.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.screen),
                      child: Column(
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 48,
                            color: context.colors.textMedium,
                          ),
                          const SizedBox(height: Spacing.section),
                          Text(
                            'Your people, at your pace',
                            style: context.text.cardTitle,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: Spacing.stack),
                          Text(
                            'Connect with someone you know to see each other’s shared activity.',
                            style: context.text.body.copyWith(
                              color: context.colors.textMedium,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: Spacing.section),
                          PrimaryButton(
                            label: 'Connect with friends',
                            onPressed: () => context.push('/social/connect'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.screen,
                    ),
                    sliver: SliverList.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: Spacing.section),
                        child: FriendStatusCard(
                          key: ValueKey(items[index].uid),
                          friend: items[index],
                        ),
                      ),
                    ),
                  ),
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(Spacing.major),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (_, __) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.screen),
                child: _RetryMessage(
                  message: 'Could not load your saved friends.',
                  label: 'Retry friends',
                  onRetry: () => ref.invalidate(friendsListStreamProvider),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: shellScrollBottomPadding(context)),
          ),
        ],
      ),
    );
  }
}

class _RetryMessage extends StatelessWidget {
  const _RetryMessage({
    required this.message,
    required this.label,
    required this.onRetry,
  });
  final String message, label;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        message,
        style: context.text.body.copyWith(color: context.colors.textMedium),
      ),
      TextButton(onPressed: onRetry, child: Text(label)),
    ],
  );
}

enum LeaderboardMetric { steps, score }

enum LeaderboardPeriod { today, week }

/// Missing/stale activity stays unranked; an explicitly recorded zero is valid.
int? leaderboardValue(
  SocialProfile profile,
  LeaderboardPeriod period,
  LeaderboardMetric metric,
  DateTime now,
) {
  if (period == LeaderboardPeriod.today) {
    if (!profile.isCurrentDay(now)) return null;
    return metric == LeaderboardMetric.steps
        ? profile.hasKnownTodaySteps
              ? profile.todaySteps
              : null
        : profile.todayScore;
  }
  if (!profile.isCurrentWeek(now)) return null;
  return metric == LeaderboardMetric.steps
      ? profile.hasKnownWeeklySteps
            ? profile.weeklySteps
            : null
      : profile.hasKnownWeekScore
      ? profile.weekScore
      : null;
}

typedef _RankedFriend = ({SocialProfile profile, Friend? friend, int value});

class _LeaderboardTab extends ConsumerStatefulWidget {
  const _LeaderboardTab();
  @override
  ConsumerState<_LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends ConsumerState<_LeaderboardTab> {
  LeaderboardPeriod _period = LeaderboardPeriod.today;
  LeaderboardMetric _metric = LeaderboardMetric.score;

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider);
    final friendsAsync = ref.watch(friendsListStreamProvider);
    final mine = ref.watch(mySocialProfileProvider);
    if (friendsAsync.isLoading)
      return const Center(child: CircularProgressIndicator());
    if (friendsAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.all(Spacing.screen),
        child: _RetryMessage(
          message: 'Could not load the leaderboard.',
          label: 'Retry leaderboard',
          onRetry: () => ref.invalidate(friendsListStreamProvider),
        ),
      );
    }
    final friends = friendsAsync.valueOrNull ?? [];
    final ranked = <_RankedFriend>[];
    final unranked = <Widget>[];
    final myValue = leaderboardValue(mine, _period, _metric, now);
    if (myValue != null)
      ranked.add((profile: mine, friend: null, value: myValue));
    for (final friend in friends) {
      final data = ref.watch(friendProfileStreamProvider(friend.uid));
      final profile = data.valueOrNull;
      final value = !data.isLoading && !data.hasError && profile != null
          ? leaderboardValue(profile, _period, _metric, now)
          : null;
      if (value != null) {
        ranked.add((profile: profile!, friend: friend, value: value));
      } else {
        unranked.add(
          _unranked(
            friend,
            data.isLoading
                ? 'Loading shared activity…'
                : data.hasError || profile == null
                ? 'Shared details unavailable'
                : 'No shared ${_period == LeaderboardPeriod.today ? 'today' : 'this week'} ${_metric == LeaderboardMetric.steps ? 'steps' : 'score'}',
          ),
        );
      }
    }
    ranked.sort((a, b) {
      final order = b.value.compareTo(a.value);
      return order != 0
          ? order
          : a.profile.name.toLowerCase().compareTo(
              b.profile.name.toLowerCase(),
            );
    });
    final ranks = <int>[];
    for (var i = 0; i < ranked.length; i++) {
      ranks.add(
        i > 0 && ranked[i].value == ranked[i - 1].value ? ranks.last : i + 1,
      );
    }
    // Equal ranks at the top or across the third-place cutoff use equal rows.
    final podiumRanks = ranks.take(4);
    final hasPodiumTie = podiumRanks.toSet().length != podiumRanks.length;
    final title = _metric == LeaderboardMetric.score
        ? _period == LeaderboardPeriod.week
              ? 'Weekly average score'
              : 'Today’s score'
        : _period == LeaderboardPeriod.week
        ? 'This week’s steps'
        : 'Today’s steps';
    final explanation = _metric == LeaderboardMetric.score
        ? _period == LeaderboardPeriod.week
              ? 'Average score across recorded days, Monday to today. Each person follows their own plan.'
              : 'Today’s plan and logging score. Each person follows their own plan.'
        : _period == LeaderboardPeriod.week
        ? 'Recorded steps from Monday to today.'
        : 'Steps shared for today.';
    return LayoutBuilder(
      builder: (context, constraints) {
        final podiumWidth =
            constraints.maxWidth - 2 * Spacing.screen - 2 * Spacing.cardPad;
        final usePodium =
            ranked.length >= 3 &&
            !hasPodiumTie &&
            podiumWidth >= 280 &&
            MediaQuery.textScalerOf(context).scale(14) <= 18;
        final hasRemaining =
            ranked.length > 3 || myValue == null || unranked.isNotEmpty;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            Spacing.screen,
            Spacing.section,
            Spacing.screen,
            shellScrollBottomPadding(context),
          ),
          children: [
            Wrap(
              spacing: Spacing.stack,
              runSpacing: Spacing.stack,
              alignment: WrapAlignment.center,
              children: [
                SegmentedButton<LeaderboardPeriod>(
                  segments: const [
                    ButtonSegment(
                      value: LeaderboardPeriod.today,
                      label: Text('Today'),
                    ),
                    ButtonSegment(
                      value: LeaderboardPeriod.week,
                      label: Text('Week'),
                    ),
                  ],
                  selected: {_period},
                  onSelectionChanged: (value) =>
                      setState(() => _period = value.first),
                ),
                SegmentedButton<LeaderboardMetric>(
                  segments: const [
                    ButtonSegment(
                      value: LeaderboardMetric.score,
                      label: Text('Score'),
                    ),
                    ButtonSegment(
                      value: LeaderboardMetric.steps,
                      label: Text('Steps'),
                    ),
                  ],
                  selected: {_metric},
                  onSelectionChanged: (value) =>
                      setState(() => _metric = value.first),
                ),
              ],
            ),
            const SizedBox(height: Spacing.section),
            if (friends.isEmpty) ...[
              Text('Invite someone to join you', style: context.text.cardTitle),
              const SizedBox(height: Spacing.stack),
              PrimaryButton(
                label: 'Connect with friends',
                onPressed: () => context.push('/social/connect'),
              ),
              const SizedBox(height: Spacing.section),
            ],
            _leaderboardCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: context.text.cardTitle),
                  const SizedBox(height: Spacing.textPair),
                  Text(
                    explanation,
                    style: context.text.caption.copyWith(
                      color: context.colors.textMedium,
                    ),
                  ),
                  const SizedBox(height: Spacing.block),
                  if (usePodium)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final index in [1, 0, 2])
                          Expanded(
                            child: _podium(
                              ranked[index],
                              ranks[index],
                              index == 0,
                            ),
                          ),
                      ],
                    )
                  else
                    _rankingDetails(
                      ranked,
                      ranks,
                      0,
                      myValue == null,
                      unranked,
                    ),
                ],
              ),
            ),
            if (usePodium && hasRemaining) ...[
              const SizedBox(height: Spacing.stack),
              _leaderboardCard(
                child: _rankingDetails(
                  ranked,
                  ranks,
                  3,
                  myValue == null,
                  unranked,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _leaderboardCard({required Widget child}) => SurfaceCard(
    margin: EdgeInsets.zero,
    child: Material(
      // Paint focus and tap feedback above the card's opaque background.
      type: MaterialType.transparency,
      textStyle: DefaultTextStyle.of(context).style,
      child: child,
    ),
  );

  Widget _rankingDetails(
    List<_RankedFriend> ranked,
    List<int> ranks,
    int start,
    bool selfUnranked,
    List<Widget> unranked,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = start; i < ranked.length; i++) ...[
        if (i > start) const SizedBox(height: Spacing.inline),
        _row(ranked[i], ranks[i]),
      ],
      if (selfUnranked)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.stack),
          child: Text(
            'You · No recorded ${_metric == LeaderboardMetric.steps ? 'steps' : 'score'} for this period',
            style: context.text.body.copyWith(color: context.colors.textMedium),
          ),
        ),
      if (unranked.isNotEmpty) ...[
        if (ranked.length > start || selfUnranked)
          const SizedBox(height: Spacing.block),
        Text('AWAITING SHARED ACTIVITY', style: context.text.eyebrow),
        const SizedBox(height: Spacing.stack),
        ...unranked,
      ],
    ],
  );

  String _value(int value) => _metric == LeaderboardMetric.steps
      ? NumberFormat.decimalPattern().format(value)
      : '$value';
  String _name(_RankedFriend entry) =>
      entry.friend == null ? 'You' : entry.profile.name;
  void _open(_RankedFriend entry) {
    if (entry.friend != null) showFriendDetailsSheet(context, entry.friend!);
  }

  Widget _row(_RankedFriend entry, int rank) => Material(
    color: entry.friend == null
        ? context.colors.primary.withValues(alpha: .1)
        : Colors.transparent,
    borderRadius: BorderRadius.circular(Radii.card),
    child: InkWell(
      onTap: entry.friend == null ? null : () => _open(entry),
      borderRadius: BorderRadius.circular(Radii.card),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.stack),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stackDetails =
                constraints.maxWidth < 320 &&
                MediaQuery.textScalerOf(context).scale(14) > 18;
            final rankLabel = Text(
              '#$rank',
              style: context.text.bodyStrong.copyWith(
                color: context.colors.accentText,
              ),
            );
            final avatar = FriendAvatar(
              name: entry.profile.name,
              avatarUrl: entry.profile.avatarUrl,
              size: 36,
            );
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_name(entry), style: context.text.bodyStrong),
                Text(
                  '${_value(entry.value)} ${_metric == LeaderboardMetric.steps ? 'steps' : '/ 100'}',
                  style: context.text.body.copyWith(
                    color: context.colors.textMedium,
                  ),
                ),
              ],
            );
            if (stackDetails) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      rankLabel,
                      const SizedBox(width: Spacing.stack),
                      avatar,
                      const Spacer(),
                      if (entry.friend != null)
                        const Icon(Icons.chevron_right_rounded, size: 20),
                    ],
                  ),
                  const SizedBox(height: Spacing.stack),
                  details,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 32, child: rankLabel),
                avatar,
                const SizedBox(width: Spacing.stack),
                Expanded(child: details),
                if (entry.friend != null)
                  const Icon(Icons.chevron_right_rounded, size: 20),
              ],
            );
          },
        ),
      ),
    ),
  );

  Widget _podium(_RankedFriend entry, int rank, bool first) {
    final color = rank == 1
        ? context.colors.gold
        : rank == 2
        ? context.colors.silver
        : context.colors.bronze;
    return Semantics(
      button: entry.friend != null,
      label:
          'Rank $rank, ${_name(entry)}, ${_value(entry.value)} ${_metric == LeaderboardMetric.steps ? 'steps' : 'out of 100'}',
      child: InkWell(
        onTap: entry.friend == null ? null : () => _open(entry),
        borderRadius: BorderRadius.circular(Radii.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: Spacing.stack,
          ),
          child: ExcludeSemantics(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: FriendAvatar(
                    name: entry.profile.name,
                    avatarUrl: entry.profile.avatarUrl,
                    size: first ? 64 : 48,
                  ),
                ),
                const SizedBox(height: Spacing.stack),
                Text(
                  _name(entry),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.caption.copyWith(
                    color: context.colors.textDark,
                  ),
                ),
                Text(
                  '#$rank',
                  style: context.text.caption.copyWith(
                    color: context.colors.textMedium,
                  ),
                ),
                Text(
                  _metric == LeaderboardMetric.steps
                      ? NumberFormat.compact().format(entry.value)
                      : '${entry.value}',
                  style: context.text.cardTitle.copyWith(
                    color: context.colors.accentText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _unranked(Friend friend, String status) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: FriendAvatar(
      name: friend.name,
      avatarUrl: friend.avatarUrl,
      size: 36,
    ),
    title: Text(friend.name, style: context.text.bodyStrong),
    subtitle: Text(
      status,
      style: context.text.caption.copyWith(color: context.colors.textMedium),
    ),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: () => showFriendDetailsSheet(context, friend),
  );
}
