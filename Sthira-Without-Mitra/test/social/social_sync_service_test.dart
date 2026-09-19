// SDK boundary fakes are test-only; production uses the Firestore implementation.
// ignore_for_file: subtype_of_sealed_class

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trufit_bodamma/interfaces/i_auth_service.dart';
import 'package:trufit_bodamma/models/social_profile.dart';
import 'package:trufit_bodamma/services/social_sync_service.dart';

const _me = 'aaaaaaaaaaaaaaaaaaaa';
const _friend = 'bbbbbbbbbbbbbbbbbbbb';
const _other = 'cccccccccccccccccccc';

class _Auth extends Fake implements IAuthService {
  String? account = _me;
  @override
  String? get uid => account;
  @override
  bool get isSignedIn => account != null;
}

class _Meta extends Fake implements SnapshotMetadata {
  final bool cached;
  final bool pending;
  _Meta(this.cached, this.pending);
  @override
  bool get isFromCache => cached;
  @override
  bool get hasPendingWrites => pending;
}

class _Snapshot<T> extends Fake implements DocumentSnapshot<T> {
  final DocumentReference<T> document;
  final T? value;
  final bool cached;
  final bool pending;
  _Snapshot(
    this.document,
    this.value, {
    this.cached = false,
    this.pending = false,
  });
  @override
  T? data() => value;
  @override
  bool get exists => value != null;
  @override
  String get id => document.id;
  @override
  SnapshotMetadata get metadata => _Meta(cached, pending);
}

class _Collection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final _Firestore database;
  @override
  final String path;
  _Collection(this.database, this.path);
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _Document(database, '${this.path}/$path');
}

class _Document extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  final _Firestore database;
  @override
  final String path;
  _Document(this.database, this.path);
  @override
  String get id => path.split('/').last;
  @override
  CollectionReference<Map<String, dynamic>> collection(String name) =>
      _Collection(database, '$path/$name');
  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async {
    await database.holdRead?.future;
    return _Snapshot(this, database.records[path]);
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    database.apply(path, data, options);
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) => database.events
      .putIfAbsent(
        path,
        () =>
            StreamController<
              DocumentSnapshot<Map<String, dynamic>>
            >.broadcast(),
      )
      .stream;
}

class _Transaction extends Fake implements Transaction {
  final _Firestore database;
  final writes = <void Function()>[];
  _Transaction(this.database);
  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> reference,
  ) async {
    await database.holdRead?.future;
    return _Snapshot(reference, database.records[reference.path] as T?);
  }

  @override
  Transaction set<T>(
    DocumentReference<T> reference,
    T data, [
    SetOptions? options,
  ]) {
    writes.add(
      () =>
          database.apply(reference.path, data as Map<String, dynamic>, options),
    );
    return this;
  }

  @override
  Transaction update(DocumentReference reference, Map<String, dynamic> data) {
    writes.add(
      () => database.apply(reference.path, data, SetOptions(merge: true)),
    );
    return this;
  }

  @override
  Transaction delete(DocumentReference reference) {
    writes.add(() {
      database.deleted.add(reference.path);
      database.records.remove(reference.path);
    });
    return this;
  }
}

class _Firestore extends Fake implements FirebaseFirestore {
  final records = <String, Map<String, dynamic>>{};
  final events =
      <String, StreamController<DocumentSnapshot<Map<String, dynamic>>>>{};
  final deleted = <String>[];
  int writes = 0;
  Completer<void>? holdRead;
  FirebaseException? transactionError;
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection(this, path);
  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    final transaction = _Transaction(this);
    final result = await transactionHandler(transaction);
    if (transactionError != null) throw transactionError!;
    for (final write in transaction.writes) {
      write();
    }
    return result;
  }

  void apply(String path, Map<String, dynamic> data, SetOptions? options) {
    writes++;
    records[path] = {if (options?.merge == true) ...?records[path], ...data};
  }

  void emit(
    String path,
    Map<String, dynamic>? data, {
    bool cached = false,
    bool pending = false,
  }) {
    events[path]?.add(
      _Snapshot(_Document(this, path), data, cached: cached, pending: pending),
    );
  }

  Future<void> dispose() async {
    for (final controller in events.values) {
      await controller.close();
    }
  }
}

SocialProfile _profile({int? score, List<String>? readers}) => SocialProfile(
  uid: _me,
  name: 'Alex',
  todaySteps: 10,
  todayWorkouts: 0,
  currentStreak: 0,
  weeklySteps: 10,
  weeklyWorkouts: 0,
  lastUpdatedAt: DateTime(2026, 9, 19),
  todayScore: score,
  weekScore: score,
  allowedReaders: readers,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Firestore database;
  late _Auth auth;
  late SocialSyncService service;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = _Firestore();
    auth = _Auth();
    service = SocialSyncService(auth, firestore: database, accountId: _me);
  });
  tearDown(() async {
    service.dispose();
    await database.dispose();
  });

  test(
    'profile merge clears optional scores without restoring old sharing grants',
    () async {
      database.records['social_profiles/$_me'] = {
        'uid': _me,
        'allowedReaders': [_friend],
      };
      await service.pushProfile(_profile(score: 90, readers: [_other]));
      await service.flushProfile();
      await service.pushProfile(_profile());
      await service.flushProfile();
      final saved = database.records['social_profiles/$_me']!;
      expect(saved['todayScore'], isNull);
      expect(saved['weekScore'], isNull);
      expect(saved['allowedReaders'], [_friend]);
      expect(
        (await SharedPreferences.getInstance()).getString(
          'social_profile_outbox_v1_$_me',
        ),
        isNull,
      );
    },
  );

  test(
    'restored pending snapshots clear absent scores and discard stored permissions',
    () async {
      database.records['social_profiles/$_me'] = {
        'uid': _me,
        'todayScore': 80,
        'weekScore': 70,
        'allowedReaders': [_friend],
      };
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'social_profile_outbox_v1_$_me',
        '{"uid":"$_me","name":"Alex","allowedReaders":["$_other"]}',
      );
      await service.flushProfile();
      final saved = database.records['social_profiles/$_me']!;
      expect(saved['todayScore'], isNull);
      expect(saved['weekScore'], isNull);
      expect(saved['allowedReaders'], [_friend]);
    },
  );

  test(
    'sending twice preserves pending identity and never resets accepted requests',
    () async {
      await service.sendFriendRequest(_friend, 'Alex', null);
      final path = 'friend_requests/$_friend/requests/$_me';
      final first = Map<String, dynamic>.of(database.records[path]!);
      await expectLater(
        service.sendFriendRequest(_friend, 'Renamed', null),
        throwsA(
          isA<SocialSyncException>().having(
            (e) => e.code,
            'code',
            'already-pending',
          ),
        ),
      );
      expect(database.records[path], first);
      database.records[path] = {...first, 'accepted': true};
      await expectLater(
        service.sendFriendRequest(_friend, 'Alex', null),
        throwsA(
          isA<SocialSyncException>().having(
            (e) => e.code,
            'code',
            'request-accepted',
          ),
        ),
      );
      expect(database.records[path]!['accepted'], isTrue);
      expect(database.records[path]!['requestId'], first['requestId']);
    },
  );

  test(
    'missing/unavailable target has request-specific error wording',
    () async {
      database.transactionError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
      await expectLater(
        service.sendFriendRequest(_friend, 'Alex', null),
        throwsA(
          isA<SocialSyncException>()
              .having((e) => e.code, 'code', 'id-unavailable')
              .having((e) => e.message, 'message', contains('finish syncing')),
        ),
      );
      expect(database.records, isEmpty);
    },
  );

  test(
    'a changed account cannot commit a request after a pending read',
    () async {
      database.holdRead = Completer<void>();
      final pending = service.sendFriendRequest(_friend, 'Alex', null);
      final result = expectLater(
        pending,
        throwsA(
          isA<SocialSyncException>().having(
            (e) => e.code,
            'code',
            'account-changed',
          ),
        ),
      );
      auth.account = _other;
      database.holdRead!.complete();
      await result;
      expect(database.writes, 0);
    },
  );

  test(
    'decline is idempotent but refuses to remove an already accepted request',
    () async {
      final path = 'friend_requests/$_me/requests/$_friend';
      database.records[path] = {'kind': 'request', 'accepted': false};
      await service.declineFriendRequest(_friend);
      await service.declineFriendRequest(_friend);
      expect(database.records[path], isNull);
      database.records[path] = {'kind': 'request', 'accepted': true};
      await expectLater(
        service.declineFriendRequest(_friend),
        throwsA(
          isA<SocialSyncException>().having(
            (e) => e.code,
            'code',
            'request-changed',
          ),
        ),
      );
      expect(database.records[path]!['accepted'], isTrue);
    },
  );

  test(
    'friend identity comes from its document and late account stream values are rejected',
    () async {
      final path = 'social_profiles/$_friend';
      database.records[path] = {..._profile().toJson(), 'uid': _other};
      expect((await service.fetchProfileOnce(_friend))!.uid, _friend);
      final pending = service.streamFriendProfile(_friend).first;
      final result = expectLater(
        pending,
        throwsA(
          isA<SocialSyncException>().having(
            (e) => e.code,
            'code',
            'account-changed',
          ),
        ),
      );
      auth.account = _other;
      database.emit(path, database.records[path]);
      await result;
    },
  );

  test(
    'roster emits only distinct confirmed membership, never offline/pending removals',
    () async {
      final memberships = <List<String>>[];
      final subscription = service.streamFriendUids().listen(memberships.add);
      await Future<void>.delayed(Duration.zero);
      final path = 'social_profiles/$_me';
      database.emit(path, {
        'allowedReaders': [_friend],
      });
      database.emit(path, {'allowedReaders': []}, cached: true);
      database.emit(path, {'allowedReaders': []}, pending: true);
      database.emit(path, {
        'allowedReaders': [_friend],
        'todayScore': 90,
      });
      database.emit(path, {'allowedReaders': []});
      await Future<void>.delayed(Duration.zero);
      expect(memberships, [
        [_friend],
        <String>[],
      ]);
      await subscription.cancel();
    },
  );
}
