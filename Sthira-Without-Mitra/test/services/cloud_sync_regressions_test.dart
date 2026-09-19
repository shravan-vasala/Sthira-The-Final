import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:trufit_bodamma/interfaces/i_auth_service.dart';
import 'package:trufit_bodamma/models/app_config.dart';
import 'package:trufit_bodamma/models/body_stats.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/sync_queue_item.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/services/app_database_manager.dart';
import 'package:trufit_bodamma/services/cloud_record_store.dart';
import 'package:trufit_bodamma/services/cloud_sync_transport.dart';
import 'package:trufit_bodamma/services/firestore_sync_service.dart';

class _Auth extends Fake implements IAuthService {
  String? account;
  @override
  String? get uid => account;
  @override
  bool get isSignedIn => account != null;
}

class _Transport implements CloudSyncTransport {
  final records = <String, Map<String, Map<String, dynamic>>>{};
  final calls = <List<CloudWrite>>[];
  final profileEvents = StreamController<Map<String, dynamic>?>.broadcast();
  Future<void> Function()? onCommit;
  Object? readError;
  var reads = 0;
  @override
  Future<void> commit(String uid, List<CloudWrite> writes) async {
    calls.add(writes);
    await onCommit?.call();
    for (final write in writes) {
      final collection = records.putIfAbsent(write.collection, () => {});
      if (write.delete) {
        collection.remove(write.docId);
      } else {
        collection[write.docId] = Map<String, dynamic>.of(write.data);
      }
    }
  }

  @override
  Future<CloudSnapshot> readCollection(String uid, String collection) async {
    reads++;
    if (readError != null) throw readError!;
    return CloudSnapshot(
      Map<String, Map<String, dynamic>>.from(records[collection] ?? {}),
      authoritative: true,
    );
  }

  @override
  Stream<CloudSnapshot> watchCollection(String uid, String collection) =>
      const Stream.empty();
  @override
  Future<Map<String, dynamic>?> readProfile(String uid) async =>
      records['_profile_']?['profile'];
  @override
  Stream<Map<String, dynamic>?> watchProfile(String uid) =>
      profileEvents.stream;
  @override
  Future<Map<String, Map<String, dynamic>>> readGlobal(
    String collection,
  ) async => {};
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late Isar database;
  late _Auth auth;
  late _Transport transport;
  late FirestoreSyncService sync;
  var serial = 0;
  setUpAll(() async {
    await Isar.initializeIsarCore(download: false);
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('sthira_cloud_sync_');
    final uid = 'cloud_test_${serial++}';
    database = await Isar.open(
      AppDatabaseManager.schemas,
      directory: directory.path,
      name: uid,
    );
    auth = _Auth()..account = uid;
    transport = _Transport();
    sync = FirestoreSyncService(
      auth,
      databaseResolver: () => database,
      transport: transport,
      connectivity: const Stream<List<ConnectivityResult>>.empty(),
      requestTimeout: const Duration(milliseconds: 100),
      drainTimeout: const Duration(milliseconds: 20),
    );
  });
  tearDown(() async {
    await sync.dispose();
    await transport.profileEvents.close();
    await database.close();
    await directory.delete(recursive: true);
  });
  Future<void> queue(
    String collection,
    String id,
    Map<String, dynamic> data, {
    DateTime? time,
    bool quarantined = false,
  }) => database.writeTxn(() async {
    await database.syncQueueItems.put(
      SyncQueueItem(
        uid: database.name,
        collection: collection,
        docId: id,
        payload: jsonEncode(data),
        timestamp: time ?? DateTime.now(),
        quarantined: quarantined,
      ),
    );
  });
  test('permanent failure quarantines once without a retry loop', () async {
    transport.onCommit = () async {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
    };
    await queue('daily_logs', '2026-09-19', {'date': '2026-09-19', 'steps': 1});
    await sync.flushQueue();
    for (var i = 0; i < 5; i++) {
      await sync.flushQueue();
    }
    expect(transport.calls.length, 1);
    final item = database.syncQueueItems.where().findAllSync().single;
    expect(item.quarantined, isTrue);
    expect(item.attempts, 1);
    expect(sync.lastError, isNotNull);
  });
  test(
    'newer valid intent supersedes quarantined writes and removes obsolete queue protection',
    () async {
      await queue(
        'daily_logs',
        '2026-09-19',
        {'date': '2026-09-19', 'steps': 1},
        time: DateTime(2026, 9, 18),
        quarantined: true,
      );
      await queue('daily_logs', '2026-09-19', {
        'date': '2026-09-19',
        'steps': 2,
      }, time: DateTime(2026, 9, 19));
      await sync.flushQueue();
      expect(transport.records['daily_logs']!['2026-09-19']!['steps'], 2);
      expect(database.syncQueueItems.countSync(), 0);
    },
  );
  test(
    'malformed outbox data is quarantined while valid writes still commit',
    () async {
      await database.writeTxn(() async {
        await database.syncQueueItems.put(
          SyncQueueItem(
            uid: database.name,
            collection: 'daily_logs',
            docId: 'bad',
            payload: 'invalid json',
            timestamp: DateTime(2026, 9, 18),
          ),
        );
      });
      await queue('daily_logs', '2026-09-19', {
        'date': '2026-09-19',
        'steps': 4,
      });
      await sync.flushQueue();
      expect(transport.records['daily_logs']!['2026-09-19']!['steps'], 4);
      expect(
        database.syncQueueItems.where().findAllSync().single.quarantined,
        isTrue,
      );
    },
  );
  test(
    'pending local meal survives repository recreation and stale cloud data after acknowledgment',
    () async {
      final newer = DateTime.now();
      await database.writeTxn(() async {
        await database.dailyMealLogs.put(
          DailyMealLog(
            date: '2026-09-19',
            updatedAt: newer,
            customSlots: {'lunch': MealSlotLog(totalCalories: 650)},
          ),
        );
      });
      final local = database.dailyMealLogs
          .where()
          .findAllSync()
          .single
          .toJson();
      await queue('meal_logs', '2026-09-19', local, time: newer);
      final stale = {
        '2026-09-19': DailyMealLog(
          date: '2026-09-19',
          updatedAt: newer.subtract(const Duration(days: 1)),
          customSlots: {'lunch': MealSlotLog(totalCalories: 250)},
        ).toJson(),
      };
      await CloudRecordStore(database).apply('meal_logs', stale);
      expect(
        database.dailyMealLogs.where().findAllSync().single.totalCalories,
        650,
      );
      await sync.flushQueue();
      await CloudRecordStore(database).apply('meal_logs', stale);
      expect(
        database.dailyMealLogs.where().findAllSync().single.totalCalories,
        650,
      );
    },
  );
  test(
    'acknowledged delete leaves a durable tombstone against cached resurrection',
    () async {
      final older = DateTime.now().subtract(const Duration(days: 1));
      final stale = {
        '2026-09-19': {
          'date': '2026-09-19',
          'waist': 80,
          '_syncUpdatedAt': older.toIso8601String(),
        },
      };
      await queue('_delete_/body_stats', '2026-09-19', {});
      await sync.flushQueue();
      await CloudRecordStore(
        database,
      ).apply('body_stats', CloudSnapshot(stale));
      expect(database.bodyStats.countSync(), 0);
      await CloudRecordStore(database).apply('body_stats', {
        '2026-09-19': {
          'date': '2026-09-19',
          'waist': 82,
          '_syncUpdatedAt': DateTime.now()
              .add(const Duration(minutes: 1))
              .toIso8601String(),
        },
      });
      expect(database.bodyStats.where().findAllSync().single.waist, 82);
    },
  );
  test(
    'only authoritative snapshots remove seen records, cached snapshots cannot restore them',
    () async {
      final snapshot = {
        '2026-09-19': {'date': '2026-09-19', 'steps': 1},
      };
      final store = CloudRecordStore(database);
      await store.apply(
        'daily_logs',
        CloudSnapshot(snapshot, authoritative: true),
      );
      await store.apply('daily_logs', CloudSnapshot({}));
      expect(database.dailyLogs.countSync(), 1);
      await store.apply('daily_logs', CloudSnapshot({}, authoritative: true));
      expect(database.dailyLogs.countSync(), 0);
      await CloudRecordStore(
        database,
      ).apply('daily_logs', CloudSnapshot(snapshot));
      expect(database.dailyLogs.countSync(), 0);
    },
  );
  test(
    'incremental authoritative snapshots update changed rows without deleting unchanged rows',
    () async {
      final store = CloudRecordStore(database);
      await store.apply(
        'daily_logs',
        CloudSnapshot({
          '2026-09-18': {'date': '2026-09-18', 'steps': 1},
          '2026-09-19': {'date': '2026-09-19', 'steps': 2},
        }, authoritative: true),
      );
      await store.apply(
        'daily_logs',
        CloudSnapshot(
          {
            '2026-09-19': {'date': '2026-09-19', 'steps': 3},
          },
          authoritative: true,
          isComplete: false,
        ),
      );
      expect(database.dailyLogs.countSync(), 2);
      await store.apply(
        'daily_logs',
        CloudSnapshot(
          {},
          authoritative: true,
          isComplete: false,
          removedIds: {'2026-09-18'},
        ),
      );
      expect(database.dailyLogs.where().findAllSync().single.steps, 3);
    },
  );
  test(
    'pause and drain refuses to pretend a timed-out SDK commit was cancelled',
    () async {
      final entered = Completer<void>(), release = Completer<void>();
      transport.onCommit = () {
        if (!entered.isCompleted) entered.complete();
        return release.future;
      };
      await queue('daily_logs', '2026-09-19', {
        'date': '2026-09-19',
        'steps': 1,
      });
      final flushing = sync.flushQueue();
      await entered.future;
      await expectLater(
        sync.pauseAndDrainSync(),
        throwsA(isA<TimeoutException>()),
      );
      expect(database.syncQueueItems.countSync(), 1);
      release.complete();
      await flushing;
      expect(
        database.syncQueueItems.countSync(),
        1,
        reason:
            'Paused generation must not acknowledge work into a new lifecycle.',
      );
    },
  );
  test(
    'acknowledging an in-flight write preserves an edit queued while awaiting the server',
    () async {
      final entered = Completer<void>(), release = Completer<void>();
      transport.onCommit = () {
        if (!entered.isCompleted) entered.complete();
        return release.future;
      };
      await queue('daily_logs', '2026-09-19', {
        'date': '2026-09-19',
        'steps': 1,
      }, time: DateTime(2026, 9, 18));
      final flushing = sync.flushQueue();
      await entered.future;
      await queue('daily_logs', '2026-09-19', {
        'date': '2026-09-19',
        'steps': 2,
      }, time: DateTime(2026, 9, 19));
      release.complete();
      await flushing;
      expect(database.syncQueueItems.countSync(), 1);
      transport.onCommit = null;
      await sync.flushQueue();
      expect(database.syncQueueItems.countSync(), 0);
      expect(transport.records['daily_logs']!['2026-09-19']!['steps'], 2);
    },
  );
  test(
    'restore crash marker blocks imports and is replaced atomically by profile, writes and barriers',
    () async {
      await database.writeTxn(() async {
        await database.userProfiles.put(UserProfile(name: 'Asha'));
        await database.dailyLogs.put(DailyLog(date: '2026-09-19', steps: 7));
        await database.appConfigs.put(
          AppConfig(
            key: 'restore_reconciliation_pending',
            value: database.name,
          ),
        );
      });
      final store = CloudRecordStore(database);
      await store.apply('daily_logs', {
        '2026-09-19': {'date': '2026-09-19', 'steps': 1},
      });
      expect(database.dailyLogs.where().findAllSync().single.steps, 7);
      await store.enqueueSnapshot(replaceCloud: true);
      expect(
        database.appConfigs
            .where()
            .keyEqualTo('restore_reconciliation_pending')
            .findFirstSync(),
        isNull,
      );
      final queued = database.syncQueueItems.where().findAllSync();
      expect(queued.any((item) => item.collection == '_profile_'), isTrue);
      expect(queued.any((item) => item.collection == '_reconcile_'), isTrue);
      transport.records['daily_logs'] = {
        'obsolete': {'date': 'obsolete', 'steps': 9},
      };
      for (var i = 0; i < 20 && database.syncQueueItems.countSync() > 0; i++) {
        await sync.flushQueue();
      }
      expect(database.syncQueueItems.countSync(), 0);
      expect(transport.records['daily_logs']!.keys, ['2026-09-19']);
      expect(transport.records['_profile_']!['profile']!['name'], 'Asha');
      final tombstone = database.appConfigs.where().keyEqualTo(
        CloudRecordStore.versionKey('daily_logs', 'obsolete')).findFirstSync();
      expect(tombstone, isNotNull);
      expect(jsonDecode(tombstone!.value)['deleted'], isTrue);
      await CloudRecordStore(database).apply('daily_logs', CloudSnapshot({
        'obsolete': {'date': 'obsolete', 'steps': 9},
      }));
      expect(database.dailyLogs.countSync(), 1,
        reason: 'A stale cache must not resurrect a record deleted by restore cleanup.');
    },
  );
  test(
    'cloud cleanup waits for failed restored uploads and permission errors quarantine barriers',
    () async {
      await queue('daily_logs', '2026-09-19', {
        'date': '2026-09-19',
      }, quarantined: true);
      await queue('_reconcile_', 'daily_logs', {
        'ids': ['2026-09-19'],
      });
      await sync.flushQueue();
      expect(transport.reads, 0);
      await database.writeTxn(() async {
        await database.syncQueueItems
            .filter()
            .collectionEqualTo('daily_logs')
            .deleteAll();
      });
      transport.readError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
      await sync.flushQueue();
      await sync.flushQueue();
      expect(transport.reads, 1);
      expect(
        database.syncQueueItems.where().findAllSync().single.quarantined,
        isTrue,
      );
    },
  );
  test(
    'profile stream drops events after pause or an account switch',
    () async {
      final events = <Map<String, dynamic>?>[];
      final subscription = sync.streamProfile().listen(events.add);
      transport.profileEvents.add({'name': 'Asha'});
      await Future<void>.delayed(Duration.zero);
      sync.pauseSync();
      transport.profileEvents.add({'name': 'wrong lifecycle'});
      await Future<void>.delayed(Duration.zero);
      expect(events.length, 1);
      await subscription.cancel();
    },
  );
}
