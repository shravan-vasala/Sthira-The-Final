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
import 'package:trufit_bodamma/screens/social/widgets/friend_avatar.dart';
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

SocialProfile profile(
  String uid, {
  int steps = 0,
  int score = 50,
  String? name,
  bool recorded = true,
}) => SocialProfile(
  uid: uid,
  name: name ?? (uid == myUid ? 'Sister' : 'Alexandra Catherine'),
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
  todayScore: recorded ? score : null,
  weekScore: recorded ? score : null,
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
  double width = 320,
  double? contentWidth,
  SocialProfile? mine,
  bool light = false,
  List<Friend> friends = const [],
  Stream<List<Friend>> Function()? friendsStream,
  Stream<List<Map<String, dynamic>>> Function()? requests,
  Map<String, SocialProfile?> profiles = const {},
}) async {
  tester.view.physicalSize = Size(width, 844);
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
          mine ?? profile(myUid, recorded: false),
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
          child: contentWidth == null
              ? child!
              : Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(width: contentWidth, child: child!),
                ),
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
  testWidgets('distinct leaders remain tappable inside the podium at 360px', (
    tester,
  ) async {
    final people = [
      friend('asha', name: 'Asha'),
      friend('bela', name: 'Bela'),
      friend('cora', name: 'Cora'),
      friend('devi', name: 'Devi'),
    ];
    await showSocial(
      tester,
      service: _Social(),
      repository: _Friends(),
      width: 360,
      mine: profile(myUid, score: 40),
      friends: people,
      profiles: {
        for (var i = 0; i < people.length; i++)
          people[i].uid: profile(
            people[i].uid,
            name: people[i].name,
            score: 95 - i * 10,
          ),
      },
    );
    await tester.tap(find.text('Leaderboard'));
    await tester.pumpAndSettle();
    Finder avatar(String name) => find.byWidgetPredicate(
      (widget) => widget is FriendAvatar && widget.name == name,
    );
    final semantics = tester.ensureSemantics();
    try {
      final leader = tester.getSemantics(
        find.bySemanticsLabel('Rank 1, Asha, 95 out of 100'),
      );
      expect(
        leader,
        matchesSemantics(
          label: 'Rank 1, Asha, 95 out of 100',
          isButton: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
    } finally {
      semantics.dispose();
    }
    final first = tester.getRect(avatar('Asha'));
    final second = tester.getRect(avatar('Bela'));
    final third = tester.getRect(avatar('Cora'));
    expect(first.width, greaterThan(second.width));
    expect(first.center.dx, greaterThan(second.center.dx));
    expect(first.center.dx, lessThan(third.center.dx));
    expect(find.text('Today’s score'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(avatar('Asha'));
    await tester.tap(avatar('Asha'));
    await tester.pumpAndSettle();
    expect(find.text('Friend details'), findsOneWidget);
    expect(find.text('Daily score'), findsOneWidget);
    await tester.tap(find.byTooltip('Close friend details'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Devi'));
    await tester.tap(find.text('Devi'));
    await tester.pumpAndSettle();
    expect(find.text('Friend details'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final scores in [
    [90, 90, 70],
    [90, 80, 70, 70],
  ]) {
    testWidgets('tied podium positions receive equal row emphasis $scores', (
      tester,
    ) async {
      final people = [
        for (var i = 0; i < scores.length; i++)
          friend('person-$i', name: 'Friend $i'),
      ];
      await showSocial(
        tester,
        service: _Social(),
        repository: _Friends(),
        width: 390,
        friends: people,
        profiles: {
          for (var i = 0; i < people.length; i++)
            people[i].uid: profile(
              people[i].uid,
              name: people[i].name,
              score: scores[i],
            ),
        },
      );
      await tester.tap(find.text('Leaderboard'));
      await tester.pumpAndSettle();
      final portraits = tester
          .widgetList<FriendAvatar>(find.byType(FriendAvatar))
          .toList();
      expect(portraits.length, people.length);
      final bounds = [
        for (final person in people)
          tester.getRect(
            find.byWidgetPredicate(
              (widget) => widget is FriendAvatar && widget.name == person.name,
            ),
          ),
      ];
      expect(bounds.map((rect) => rect.width).toSet().length, 1);
      for (var i = 1; i < bounds.length; i++) {
        expect(bounds[i].top, greaterThanOrEqualTo(bounds[i - 1].bottom));
      }
      expect(
        find.text(scores.first == scores[1] ? '#1' : '#3'),
        findsNWidgets(2),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a narrow parent uses rows even on a wider viewport', (
    tester,
  ) async {
    final people = [
      for (var i = 0; i < 3; i++) friend('person-$i', name: 'Friend $i'),
    ];
    await showSocial(
      tester,
      service: _Social(),
      repository: _Friends(),
      width: 480,
      contentWidth: 320,
      friends: people,
      profiles: {
        for (var i = 0; i < 3; i++)
          people[i].uid: profile(
            people[i].uid,
            name: people[i].name,
            score: 90 - i * 10,
          ),
      },
    );
    await tester.tap(find.text('Leaderboard'));
    await tester.pumpAndSettle();
    final portraits = [
      for (final person in people)
        tester.getRect(
          find.byWidgetPredicate(
            (widget) => widget is FriendAvatar && widget.name == person.name,
          ),
        ),
    ];
    expect(portraits.map((rect) => rect.width).toSet().length, 1);
    expect(portraits[1].top, greaterThan(portraits[0].bottom));
    expect(tester.takeException(), isNull);
  });

  for (final light in [false, true]) {
    testWidgets(
      'populated rankings and filters stay usable at 320/200 light=$light',
      (tester) async {
        final people = [
          for (var i = 0; i < 3; i++)
            friend('person-$i', name: 'Alexandra Catherine Vasala $i'),
        ];
        await showSocial(
          tester,
          service: _Social(),
          repository: _Friends(),
          scale: 2,
          light: light,
          friends: people,
          profiles: {
            for (var i = 0; i < 3; i++)
              people[i].uid: profile(
                people[i].uid,
                name: people[i].name,
                score: 90 - i * 10,
                steps: 123456 - i * 1000,
              ),
          },
        );
        await tester.ensureVisible(find.text('Leaderboard'));
        await tester.tap(find.text('Leaderboard'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Week'));
        await tester.pumpAndSettle();
        expect(find.text('Weekly average score'), findsOneWidget);
        await tester.tap(find.text('Steps'));
        await tester.pumpAndSettle();
        expect(find.text('This week’s steps'), findsOneWidget);
        expect(find.text('123,456 steps'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text(people.first.name));
        await tester.pumpAndSettle();
        await tester.tap(find.text(people.first.name));
        await tester.pumpAndSettle();
        expect(find.text('Friend details'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
