import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:trufit_bodamma/interfaces/i_auth_service.dart';
import 'package:trufit_bodamma/models/friend.dart';
import 'package:trufit_bodamma/models/social_profile.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/repositories/friend_repository.dart';
import 'package:trufit_bodamma/services/social_sync_service.dart';
import 'package:trufit_bodamma/screens/social/connect_screen.dart';
import 'package:trufit_bodamma/screens/social/social_feed_screen.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';

const myUid = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const otherUid = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbb';
final now = DateTime(2026, 9, 19, 12);

class _Auth implements IAuthService {
  bool signedIn = true;
  @override
  bool get isSignedIn => signedIn;
  @override
  String? get uid => signedIn ? myUid : null;
  @override
  User? get currentUser => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Profile extends ProfileNotifier {
  @override
  UserProfile build() =>
      UserProfile(name: 'Sister', photoPath: 'private/photo.jpg');
}

class _Friends implements FriendRepository {
  final records = <String, Friend>{};
  @override
  Friend? getFriend(String uid) => records[uid];
  @override
  Future<void> addFriend(String uid, String name, {String? avatarUrl}) async {
    records[uid] = Friend()
      ..uid = uid
      ..name = name
      ..avatarUrl = avatarUrl
      ..addedAt = now;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Social implements SocialSyncService {
  bool available = true;
  Object? failure;
  Completer<void>? hold;
  final sent = <({String uid, String? avatar})>[];
  final accepted = <String>[];
  final declined = <String>[];
  @override
  bool get canSync => available;
  @override
  String? get currentUid => available ? myUid : null;
  @override
  Future<void> sendFriendRequest(
    String uid,
    String name,
    String? avatar,
  ) async {
    sent.add((uid: uid, avatar: avatar));
    await hold?.future;
    if (failure != null) throw failure!;
  }

  @override
  Future<void> acceptFriendRequest(String uid) async {
    accepted.add(uid);
    await hold?.future;
    if (failure != null) throw failure!;
  }

  @override
  Future<void> declineFriendRequest(String uid) async {
    declined.add(uid);
    await hold?.future;
    if (failure != null) throw failure!;
  }

  @override
  Future<void> flushProfile() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SocialProfile profile(String uid, {int steps = 0, bool recorded = true}) =>
    SocialProfile(
      uid: uid,
      name: uid == myUid ? 'Sister' : 'Alexandra Catherine',
      todaySteps: steps,
      todayWorkouts: 0,
      currentStreak: 0,
      weeklySteps: steps,
      weeklyWorkouts: 0,
      lastUpdatedAt: now,
      statsDate: '2026-09-19',
      weekStartDate: '2026-09-14',
      hasStepsRecord: recorded,
      weeklyStepsRecordedDays: recorded ? 1 : 0,
      todayScore: recorded ? 50 : null,
      weekScore: recorded ? 50 : null,
      weekScoreRecordedDays: recorded ? 1 : 0,
    );
Friend friend(String uid, {String name = 'Alexandra Catherine'}) => Friend()
  ..uid = uid
  ..name = name
  ..addedAt = now;

Future<void> showSocial(
  WidgetTester tester, {
  required _Social service,
  required _Friends repository,
  _Auth? auth,
  bool connect = false,
  double scale = 1,
  bool light = false,
  List<Friend> friends = const [],
  Stream<List<Friend>> Function()? friendsStream,
  Stream<List<Map<String, dynamic>>> Function()? requests,
  Map<String, SocialProfile?> profiles = const {},
}) async {
  tester.view.physicalSize = const Size(320, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    initialLocation: connect ? '/social/connect' : '/social',
    routes: [
      GoRoute(path: '/social', builder: (_, __) => const SocialFeedScreen()),
      GoRoute(
        path: '/social/connect',
        builder: (_, __) => const ConnectScreen(),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(auth ?? _Auth()),
        socialSyncServiceProvider.overrideWithValue(service),
        socialRelationshipProvider.overrideWithValue(null),
        friendRepoProvider.overrideWithValue(repository),
        profileProvider.overrideWith(_Profile.new),
        clockProvider.overrideWithValue(now),
        friendsListStreamProvider.overrideWith(
          (ref) => friendsStream?.call() ?? Stream.value(friends),
        ),
        friendRequestsProvider.overrideWith(
          (ref) => requests?.call() ?? Stream.value([]),
        ),
        mySocialProfileProvider.overrideWithValue(
          profile(myUid, recorded: false),
        ),
        for (final person in friends)
          friendProfileStreamProvider(
            person.uid,
          ).overrideWith((ref) => Stream.value(profiles[person.uid])),
      ],
      child: MaterialApp.router(
        theme: light ? AppTheme.light : AppTheme.dark,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> enterId(WidgetTester tester, String value) async {
  await tester.tap(find.text('Enter ID'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), value);
}

void main() {
  testWidgets('guests see a sign-in path instead of misleading empty friends', (
    tester,
  ) async {
    await showSocial(
      tester,
      service: _Social(),
      repository: _Friends(),
      auth: _Auth()..signedIn = false,
    );
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Leaderboard'), findsNothing);
    expect(find.text('Your people, at your pace'), findsNothing);
  });

  testWidgets('empty friends has a named direct connection action', (
    tester,
  ) async {
    await showSocial(tester, service: _Social(), repository: _Friends());
    await tester.tap(find.text('Connect with friends'));
    await tester.pumpAndSettle();
    expect(find.text('My ID'), findsOneWidget);
    expect(find.text('Enter ID'), findsOneWidget);
  });

  testWidgets('invalid and self IDs stay editable and make no request', (
    tester,
  ) async {
    final service = _Social();
    await showSocial(
      tester,
      service: service,
      repository: _Friends(),
      connect: true,
    );
    await enterId(tester, 'short');
    await tester.tap(find.text('Send request'));
    await tester.pump();
    expect(
      find.text('Enter the full friend ID, or paste their invitation.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), myUid);
    await tester.tap(find.text('Send request'));
    await tester.pump();
    expect(
      find.text('This is your ID. Ask your friend to share theirs.'),
      findsOneWidget,
    );
    expect(service.sent, isEmpty);
  });

  testWidgets(
    'sending a pasted invitation waits once and never shares local image paths',
    (tester) async {
      final hold = Completer<void>();
      final service = _Social()..hold = hold;
      await showSocial(
        tester,
        service: service,
        repository: _Friends(),
        connect: true,
      );
      await enterId(
        tester,
        'Connect with me on Sthira! My friend ID is: $otherUid',
      );
      await tester.tap(find.text('Send request'));
      await tester.pump();
      expect(service.sent, [(uid: otherUid, avatar: null)]);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      await tester.testTextInput.receiveAction(TextInputAction.send);
      expect(service.sent, hasLength(1));
      hold.complete();
      await tester.pumpAndSettle();
      expect(find.text('Request sent'), findsOneWidget);
      expect(find.text(otherUid), findsOneWidget);
    },
  );

  testWidgets('failed requests keep their ID and retry successfully', (
    tester,
  ) async {
    final service = _Social()
      ..failure = const SocialSyncException(
        'unavailable',
        'Try again when connected.',
      );
    await showSocial(
      tester,
      service: service,
      repository: _Friends(),
      connect: true,
    );
    await enterId(tester, otherUid);
    await tester.tap(find.text('Send request'));
    await tester.pumpAndSettle();
    expect(find.text('Try again when connected.'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      otherUid,
    );
    service.failure = null;
    await tester.tap(find.text('Send request'));
    await tester.pumpAndSettle();
    expect(find.text('Request sent'), findsOneWidget);
    expect(service.sent, hasLength(2));
  });

  testWidgets('already pending has an honest waiting state', (tester) async {
    final service = _Social()
      ..failure = const SocialSyncException(
        'already-pending',
        'Already waiting',
      );
    await showSocial(
      tester,
      service: service,
      repository: _Friends(),
      connect: true,
    );
    await enterId(tester, otherUid);
    await tester.tap(find.text('Send request'));
    await tester.pumpAndSettle();
    expect(find.text('Request sent'), findsOneWidget);
    expect(find.textContaining('Waiting for your friend'), findsOneWidget);
  });

  testWidgets('late send completion cannot populate a new account screen', (
    tester,
  ) async {
    final hold = Completer<void>();
    final service = _Social()..hold = hold;
    await showSocial(
      tester,
      service: service,
      repository: _Friends(),
      connect: true,
    );
    await enterId(tester, otherUid);
    await tester.tap(find.text('Send request'));
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ConnectScreen)),
    );
    container.read(accountGenerationProvider.notifier).state++;
    await tester.pumpAndSettle();
    hold.complete();
    await tester.pumpAndSettle();
    expect(find.text('Request sent'), findsNothing);
    expect(find.text('Copy ID'), findsOneWidget);
  });

  testWidgets('paste accepts the exact shared invitation', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.getData')
            return {
              'text': 'Connect with me on Sthira! My friend ID is: $otherUid',
            };
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await showSocial(
      tester,
      service: _Social(),
      repository: _Friends(),
      connect: true,
    );
    await enterId(tester, '');
    await tester.tap(find.text('Paste'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      otherUid,
    );
  });

  testWidgets('request load errors offer an actual resubscribe retry', (
    tester,
  ) async {
    var subscriptions = 0;
    await showSocial(
      tester,
      service: _Social(),
      repository: _Friends(),
      requests: () {
        subscriptions++;
        return subscriptions == 1
            ? Stream.error(StateError('offline'))
            : Stream.value([]);
      },
    );
    expect(find.text('Retry requests'), findsOneWidget);
    await tester.tap(find.text('Retry requests'));
    await tester.pumpAndSettle();
    expect(subscriptions, 2);
    expect(find.text('Retry requests'), findsNothing);
  });

  testWidgets(
    'accept request guards duplicate taps and saves friend metadata',
    (tester) async {
      final hold = Completer<void>();
      final service = _Social()..hold = hold;
      final repository = _Friends();
      await showSocial(
        tester,
        service: service,
        repository: repository,
        requests: () => Stream.value([
          {
            'fromUid': otherUid,
            'fromName': 'My sister',
            'fromAvatar': 'assets/avatars/owl.png',
          },
        ]),
      );
      await tester.tap(find.text('Accept'));
      await tester.pump();
      expect(service.accepted, [otherUid]);
      expect(find.text('Accept'), findsNothing);
      hold.complete();
      await tester.pumpAndSettle();
      expect(repository.records[otherUid]?.name, 'My sister');
    },
  );

  testWidgets(
    'a late acceptance cannot show errors or add a friend to a new account',
    (tester) async {
      final hold = Completer<void>();
      final service = _Social()..hold = hold;
      final repository = _Friends();
      await showSocial(
        tester,
        service: service,
        repository: repository,
        requests: () => Stream.value([
          {'fromUid': otherUid, 'fromName': 'Original account friend'},
        ]),
      );
      await tester.tap(find.text('Accept'));
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SocialFeedScreen)),
      );
      container.read(accountGenerationProvider.notifier).state++;
      await tester.pump();
      hold.complete();
      await tester.pumpAndSettle();
      expect(repository.records, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  for (final light in [false, true]) {
    testWidgets(
      'long requests and leaderboard filters fit 320px at 200 percent light=$light',
      (tester) async {
        final person = friend(
          otherUid,
          name: 'Alexandra Catherine Vasala and a very long family name',
        );
        await showSocial(
          tester,
          service: _Social(),
          repository: _Friends(),
          scale: 2,
          light: light,
          friends: [person],
          profiles: {otherUid: profile(otherUid)},
          requests: () => Stream.value([
            {'fromUid': otherUid, 'fromName': person.name},
          ]),
        );
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Leaderboard'));
        await tester.tap(find.text('Leaderboard'));
        await tester.pumpAndSettle();
        expect(find.text('Today'), findsOneWidget);
        expect(find.text('Week'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'unavailable shared activity stays visible and opens retryable friend details',
    (tester) async {
      final person = friend(otherUid);
      await showSocial(
        tester,
        service: _Social(),
        repository: _Friends(),
        friends: [person],
      );
      await tester.ensureVisible(find.text('Leaderboard'));
      await tester.tap(find.text('Leaderboard'));
      await tester.pumpAndSettle();
      expect(find.text('Shared details unavailable'), findsOneWidget);
      await tester.tap(find.text('Shared details unavailable'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Alexandra'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('the sent invitation updates live when the friend connects', (
    tester,
  ) async {
    final roster = StreamController<List<Friend>>.broadcast();
    addTearDown(roster.close);
    await showSocial(
      tester,
      service: _Social(),
      repository: _Friends(),
      connect: true,
      friendsStream: () => roster.stream,
    );
    await enterId(tester, otherUid);
    await tester.tap(find.text('Send request'));
    await tester.pumpAndSettle();
    expect(find.text('Request sent'), findsOneWidget);
    roster.add([friend(otherUid)]);
    await tester.pumpAndSettle();
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('View friend details'), findsOneWidget);
    expect(find.textContaining('Waiting for your friend'), findsNothing);
  });
}
