import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/friend.dart';
import 'package:trufit_bodamma/models/social_profile.dart';
import 'package:trufit_bodamma/repositories/friend_repository.dart';
import 'package:trufit_bodamma/services/social_sync_service.dart';
import 'package:trufit_bodamma/services/social_relationship_coordinator.dart';

class _Friends implements FriendRepository {
  final records = <String, Friend>{};
  Completer<void>? hold;
  final adding = Completer<void>();
  final removing = Completer<void>();
  @override
  List<Friend> getAllFriends() => records.values.toList();
  @override
  Future<void> addFriend(String uid, String name, {String? avatarUrl}) async {
    if (!adding.isCompleted) adding.complete();
    await hold?.future;
    records[uid] = Friend()
      ..uid = uid
      ..name = name
      ..addedAt = DateTime.now();
  }

  @override
  Future<void> removeFriend(String uid) async {
    records.remove(uid);
    if (!removing.isCompleted) removing.complete();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Social implements SocialSyncService {
  final events = StreamController<List<Map<String, dynamic>>>.broadcast();
  final rosterEvents = StreamController<List<String>>.broadcast();
  final roster = <String>[];
  Completer<void>? fetchHold;
  final fetchStarted = Completer<void>();
  String? failUid;
  int removals = 0;
  final acknowledged = <String>[];
  final pending = <Map<String, dynamic>>[];
  bool accept = true;
  String? deniedUid;
  int subscriptions = 0;
  @override
  bool get canSync => true;
  @override
  Stream<List<Map<String, dynamic>>> streamPendingAcceptances() {
    subscriptions++;
    return events.stream;
  }

  @override
  Stream<List<String>> streamFriendUids() => rosterEvents.stream;

  @override
  Future<void> removeFriendAccess(String uid) async {
    removals++;
    roster.remove(uid);
  }

  @override
  Future<List<String>> getFriendUids() async => List.of(roster);
  @override
  Future<List<Map<String, dynamic>>> getPendingAcceptances() async =>
      List.of(pending);
  @override
  Future<SocialProfile?> fetchProfileOnce(String uid) async {
    if (!fetchStarted.isCompleted) fetchStarted.complete();
    await fetchHold?.future;
    if (uid == failUid)
      throw const SocialSyncException('unavailable', 'Temporary failure');
    if (uid == deniedUid)
      throw const SocialSyncException('permission-denied', 'Not shared');
    return SocialProfile(
      uid: uid,
      name: uid,
      todaySteps: 0,
      todayWorkouts: 0,
      currentStreak: 0,
      weeklySteps: 0,
      weeklyWorkouts: 0,
      lastUpdatedAt: DateTime.now(),
    );
  }

  @override
  Future<bool> processPendingAcceptance(String uid, {String? requestId}) async {
    acknowledged.add(uid);
    pending.removeWhere((m) => m['fromUid'] == uid);
    if (accept && !roster.contains(uid)) roster.add(uid);
    return accept;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _marker(String uid) => {
  'fromUid': uid,
  'requestId': 'request',
};

void main() {
  test('acknowledgement waits for durable local friend save', () async {
    final service = _Social();
    final friends = _Friends()..hold = Completer<void>();
    final coordinator = SocialRelationshipCoordinator(
      service: service,
      friends: friends,
      isCurrent: () => true,
    );
    addTearDown(() async {
      coordinator.dispose();
      await service.events.close();
      await service.rosterEvents.close();
    });
    service.pending.add(_marker('friend'));
    final work = coordinator.refresh();
    await friends.adding.future;
    expect(service.acknowledged, isEmpty);
    friends.hold!.complete();
    await work;
    expect(service.acknowledged, ['friend']);
    expect(friends.records.keys, ['friend']);
  });
  test(
    'a stale generation cannot acknowledge old work after a pending save',
    () async {
      var current = true;
      final service = _Social();
      final friends = _Friends()..hold = Completer<void>();
      final coordinator = SocialRelationshipCoordinator(
        service: service,
        friends: friends,
        isCurrent: () => current,
      );
      addTearDown(() async {
        coordinator.dispose();
        await service.events.close();
        await service.rosterEvents.close();
      });
      service.pending.add(_marker('old-friend'));
      final work = coordinator.refresh();
      await friends.adding.future;
      current = false;
      friends.hold!.complete();
      await work;
      expect(service.acknowledged, isEmpty);
      expect(service.pending, hasLength(1));
    },
  );
  test(
    'revoked stale marker rolls back the temporary local insertion',
    () async {
      final service = _Social()..accept = false;
      final friends = _Friends();
      final coordinator = SocialRelationshipCoordinator(
        service: service,
        friends: friends,
        isCurrent: () => true,
      );
      addTearDown(() async {
        coordinator.dispose();
        await service.events.close();
        await service.rosterEvents.close();
      });
      service.pending.add(_marker('removed-friend'));
      await coordinator.refresh();
      expect(friends.records, isEmpty);
    },
  );
  test(
    'one inaccessible profile does not block other accepted friends',
    () async {
      final service = _Social()..deniedUid = 'unavailable';
      final friends = _Friends();
      final errors = <Object>[];
      final coordinator = SocialRelationshipCoordinator(
        service: service,
        friends: friends,
        isCurrent: () => true,
        onError: errors.add,
      );
      addTearDown(() async {
        coordinator.dispose();
        await service.events.close();
        await service.rosterEvents.close();
      });
      service.pending.addAll([_marker('unavailable'), _marker('available')]);
      await coordinator.refresh();
      expect(service.acknowledged, ['available']);
      expect(errors, hasLength(1));
      expect(service.pending.single['fromUid'], 'unavailable');
    },
  );
  test('retry restores a failed acceptance subscription', () async {
    final service = _Social();
    final friends = _Friends();
    final coordinator = SocialRelationshipCoordinator(
      service: service,
      friends: friends,
      isCurrent: () => true,
      onError: (_) {},
    );
    addTearDown(() async {
      coordinator.dispose();
      await service.events.close();
      await service.rosterEvents.close();
    });
    coordinator.start();
    service.events.addError(
      const SocialSyncException('unavailable', 'Offline'),
    );
    await Future<void>.delayed(Duration.zero);
    await coordinator.refresh();
    expect(service.subscriptions, 2);
    service.pending.add(_marker('reconnected'));
    service.events.add(List.of(service.pending));
    await Future<void>.delayed(Duration.zero);
    await coordinator.refresh();
    expect(service.acknowledged, ['reconnected']);
  });

  test(
    'one transient roster profile failure does not block remaining connections',
    () async {
      final service = _Social()
        ..failUid = 'bad'
        ..roster.addAll(['bad', 'good']);
      final friends = _Friends();
      final errors = <Object>[];
      final coordinator = SocialRelationshipCoordinator(
        service: service,
        friends: friends,
        isCurrent: () => true,
        onError: errors.add,
      );
      addTearDown(() async {
        coordinator.dispose();
        await service.events.close();
        await service.rosterEvents.close();
      });
      await coordinator.refresh();
      expect(friends.records.keys, ['good']);
      expect(errors, hasLength(1));
    },
  );

  test(
    'confirmed roster removal on another device updates local connections live',
    () async {
      final service = _Social()..roster.add('friend');
      final friends = _Friends();
      final coordinator = SocialRelationshipCoordinator(
        service: service,
        friends: friends,
        isCurrent: () => true,
      );
      addTearDown(() async {
        coordinator.dispose();
        await service.events.close();
        await service.rosterEvents.close();
      });
      await coordinator.refresh();
      expect(friends.records.keys, ['friend']);
      service.roster.clear();
      service.rosterEvents.add([]);
      await friends.removing.future;
      expect(friends.records, isEmpty);
    },
  );

  test(
    'removal is serialized after a delayed recovery fetch and cannot be undone by it',
    () async {
      final service = _Social()
        ..roster.add('friend')
        ..fetchHold = Completer<void>();
      final friends = _Friends();
      final coordinator = SocialRelationshipCoordinator(
        service: service,
        friends: friends,
        isCurrent: () => true,
      );
      addTearDown(() async {
        coordinator.dispose();
        await service.events.close();
        await service.rosterEvents.close();
      });
      coordinator.start();
      await service.fetchStarted.future;
      final removal = coordinator.removeFriend('friend');
      expect(service.removals, 0);
      service.fetchHold!.complete();
      await removal;
      expect(service.removals, 1);
      expect(service.roster, isEmpty);
      expect(friends.records, isEmpty);
    },
  );
}
