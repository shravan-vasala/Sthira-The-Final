import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/friend.dart';
import 'package:trufit_bodamma/models/social_profile.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/repositories/friend_repository.dart';
import 'package:trufit_bodamma/services/social_sync_service.dart';
import 'package:trufit_bodamma/services/social_relationship_coordinator.dart';
import 'package:trufit_bodamma/screens/social/widgets/friend_details_sheet.dart';
import 'package:trufit_bodamma/screens/social/widgets/friend_status_card.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';

final _now = StateProvider<DateTime>((ref) => DateTime(2026, 9, 19, 12));
final _friend = Friend()
  ..uid = 'friend-id'
  ..name = 'Asha with a very long family name'
  ..addedAt = DateTime(2026, 9, 1);
final _roster = StateProvider<List<Friend>>((ref) => [_friend]);
SocialProfile _profile({
  String date = '2026-09-19',
  int steps = 0,
  bool known = true,
  String? avatar,
  bool datedWeek = true,
  DateTime? sharedAt,
}) => SocialProfile(
  uid: _friend.uid,
  name: _friend.name,
  avatarUrl: avatar,
  todaySteps: steps,
  hasStepsRecord: known,
  todayWorkouts: 0,
  currentStreak: 3,
  weeklySteps: 7500,
  weeklyWorkouts: 2,
  todayScore: 75,
  weekScore: 60,
  statsDate: date,
  weekStartDate: datedWeek ? '2026-09-14' : null,
  weeklyStepsRecordedDays: 2,
  weekScoreRecordedDays: datedWeek ? 3 : null,
  lastUpdatedAt: sharedAt ?? DateTime(2026, 9, 19, 11),
);

class _Social implements SocialSyncService {
  @override
  bool get canSync => true;
  int removes = 0;
  bool fail = false;
  Completer<void>? pending;
  @override
  Future<void> removeFriendAccess(String uid) async {
    removes++;
    await pending?.future;
    if (fail) throw StateError('Unavailable');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Friends implements FriendRepository {
  final removed = <String>[];
  @override
  Future<void> removeFriend(String uid) async => removed.add(uid);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    for (final entry in {
      'General Sans': ['GeneralSans-Regular.ttf', 'GeneralSans-Semibold.ttf'],
      'Cabinet Grotesk': ['CabinetGrotesk-Extrabold.ttf'],
    }.entries) {
      final loader = FontLoader(entry.key);
      for (final font in entry.value) {
        loader.addFont(rootBundle.load('assets/fonts/$font'));
      }
      await loader.load();
    }
  });

  Future<ProviderContainer> show(
    WidgetTester tester, {
    Stream<SocialProfile?> Function()? stream,
    SocialProfile? profile,
    bool light = false,
    double scale = 1,
    _Social? service,
    _Friends? repository,
    DateTime? snapshotTime,
  }) async {
    final scope = ProviderContainer(
      overrides: [
        clockProvider.overrideWith((ref) => ref.watch(_now)),
        socialSnapshotClockProvider.overrideWithValue(
          () => snapshotTime ?? DateTime(2026, 9, 19, 12),
        ),
        friendsListStreamProvider.overrideWith(
          (ref) => Stream.value(ref.watch(_roster)),
        ),
        socialRelationshipProvider.overrideWith((ref) {
          if (service == null || repository == null) return null;
          final generation = ref.read(accountGenerationProvider);
          final coordinator = SocialRelationshipCoordinator(
            service: service,
            friends: repository,
            isCurrent: () =>
                ref.read(accountGenerationProvider) == generation &&
                !ref.read(accountTransitionProvider),
          );
          ref.onDispose(coordinator.dispose);
          return coordinator;
        }),
        friendProfileStreamProvider.overrideWith(
          (ref, uid) => stream?.call() ?? Stream.value(profile),
        ),
        if (service != null)
          socialSyncServiceProvider.overrideWithValue(service),
        if (repository != null)
          friendRepoProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(scope.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: scope,
        child: MaterialApp(
          theme: light ? AppTheme.light : AppTheme.dark,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: FriendStatusCard(friend: _friend),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return scope;
  }

  testWidgets(
    'Recorded zero and unknown steps have different accessible values',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final changes = StreamController<SocialProfile?>.broadcast();
        addTearDown(changes.close);
        changes.add(_profile());
        // Use an initial event for each subscriber, then live changes.
        await show(
          tester,
          stream: () async* {
            yield _profile();
            yield* changes.stream;
          },
        );
        expect(find.bySemanticsLabel('Steps: 0'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsNothing);
        changes.add(_profile(known: false));
        await tester.pumpAndSettle();
        expect(
          find.bySemanticsLabel('Steps: not shared for today'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'A midnight clock change retires yesterday daily readings without a network update',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final scope = await show(tester, profile: _profile(steps: 7500));
        expect(find.bySemanticsLabel('Steps: 7,500'), findsOneWidget);
        scope.read(_now.notifier).state = DateTime(2026, 9, 20);
        await tester.pumpAndSettle();
        expect(
          find.bySemanticsLabel('Steps: not shared for today'),
          findsOneWidget,
        );
        expect(
          find.text('Today’s activity has not been shared.'),
          findsOneWidget,
        );
        expect(find.text('75 / 100'), findsNothing);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'Details subscribe live, keep coverage, and remove values after access is revoked',
    (tester) async {
      final changes = StreamController<SocialProfile?>.broadcast();
      addTearDown(changes.close);
      await show(
        tester,
        stream: () async* {
          yield _profile();
          yield* changes.stream;
        },
      );
      await tester.tap(find.text('View details'));
      await tester.pumpAndSettle();
      expect(find.byType(FriendDetailsSheet), findsOneWidget);
      expect(find.text('2 days with recorded steps.'), findsOneWidget);
      expect(
        find.text('Based on 3 recorded days in this week.'),
        findsOneWidget,
      );
      changes.add(_profile(steps: 9876));
      await tester.pumpAndSettle();
      expect(find.text('9,876'), findsWidgets);
      changes.addError(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
      await tester.pumpAndSettle();
      expect(find.text('9,876'), findsNothing);
      expect(
        find.text('Shared activity is not available to your account.'),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Legacy seven-day score is not labeled a weekly average in details',
    (tester) async {
      await show(tester, profile: _profile(datedWeek: false));
      await tester.tap(find.text('View details'));
      await tester.pumpAndSettle();
      expect(find.text('60 / 100'), findsNothing);
      expect(
        find.text(
          'A dated weekly score and its recording coverage have not been shared.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('An open details sheet retires old-account data', (tester) async {
    final scope = await show(tester, profile: _profile(steps: 9876));
    await tester.tap(find.text('View details'));
    await tester.pumpAndSettle();
    scope.read(accountTransitionProvider.notifier).state = true;
    scope.read(accountGenerationProvider.notifier).state++;
    await tester.pumpAndSettle();
    expect(find.text('9,876'), findsNothing);
    expect(
      find.text('Your account changed. Close this sheet to continue.'),
      findsOneWidget,
    );
  });

  testWidgets('An open details sheet clears a removed friend snapshot', (
    tester,
  ) async {
    final scope = await show(tester, profile: _profile(steps: 9876));
    await tester.tap(find.text('View details'));
    await tester.pumpAndSettle();
    scope.read(_roster.notifier).state = [];
    await tester.pumpAndSettle();
    final sheet = find.byType(FriendDetailsSheet);
    expect(
      find.descendant(of: sheet, matching: find.text('9,876')),
      findsNothing,
    );
    expect(
      find.text('This friend has been removed. Close this sheet to continue.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Unavailable profile remains retryable rather than claiming no activity',
    (tester) async {
      var subscriptions = 0;
      await show(
        tester,
        stream: () {
          subscriptions++;
          return Stream.value(null);
        },
      );
      expect(find.text('No shared activity is available yet.'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(subscriptions, 2);
      expect(find.text('No recent activity.'), findsNothing);
    },
  );

  for (final light in [false, true]) {
    testWidgets(
      'Card and details preserve full labels at 320/200 light=$light',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await show(
          tester,
          profile: _profile(steps: 123456, avatar: 'assets/missing-avatar.png'),
          light: light,
          scale: 2,
        );
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('View details'));
        await tester.tap(find.text('View details'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(
          find.text('Figures reflect the last shared snapshot.'),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Close friend details'));
        await tester.pumpAndSettle();
        expect(find.byType(FriendDetailsSheet), findsNothing);
      },
    );
  }

  testWidgets(
    'Account change while removal is pending cannot remove a new-account friend',
    (tester) async {
      final pending = Completer<void>();
      final service = _Social()..pending = pending;
      final repository = _Friends();
      final scope = await show(
        tester,
        profile: _profile(),
        service: service,
        repository: repository,
      );
      await tester.tap(find.byTooltip('Options for ${_friend.name}'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove friend'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pump();
      expect(service.removes, 1);
      scope.read(accountGenerationProvider.notifier).state++;
      await tester.pump();
      pending.complete();
      await tester.pumpAndSettle();
      expect(repository.removed, isEmpty);
      expect(
        find.text('Your account changed. Close this dialog to continue.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Failed removal keeps its dialog and offers a working retry', (
    tester,
  ) async {
    final service = _Social()..fail = true;
    final repository = _Friends();
    await show(
      tester,
      profile: _profile(),
      service: service,
      repository: repository,
    );
    await tester.tap(find.byTooltip('Options for ${_friend.name}'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove friend'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not remove this friend. Please try again.'),
      findsOneWidget,
    );
    expect(repository.removed, isEmpty);
    service.fail = false;
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(repository.removed, [_friend.uid]);
    expect(find.byType(AlertDialog), findsNothing);
  });
  testWidgets('fresh shared time does not depend on the cached day clock', (
    tester,
  ) async {
    await show(
      tester,
      profile: _profile(sharedAt: DateTime(2026, 9, 19, 12, 30)),
      snapshotTime: DateTime(2026, 9, 19, 12, 31),
    );
    expect(find.text('Last shared time unavailable'), findsNothing);
    expect(find.textContaining('12:30'), findsOneWidget);
    await tester.tap(find.text('View details'));
    await tester.pumpAndSettle();
    expect(find.text('Friend details'), findsOneWidget);
    expect(find.text('Last shared time unavailable'), findsNothing);
    expect(find.textContaining('12:30'), findsWidgets);
  });
}
