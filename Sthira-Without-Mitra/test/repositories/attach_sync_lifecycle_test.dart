import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:trufit_bodamma/interfaces/i_cloud_sync_service.dart';
import 'package:trufit_bodamma/repositories/meal_repository.dart';
import 'package:trufit_bodamma/repositories/daily_log_repository.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/sync_queue_item.dart';
import 'dart:io';
import '../helpers/test_isar_setup.dart';

class MockCloudSyncService implements ICloudSyncService {
  @override
  bool canSync = true;

  @override
  String? currentUid;

  final Map<String, StreamController<Map<String, Map<String, dynamic>>>> controllers = {};

  StreamController<Map<String, Map<String, dynamic>>> getController(String collection) {
    return controllers.putIfAbsent(
      collection,
      () => StreamController<Map<String, Map<String, dynamic>>>.broadcast(),
    );
  }

  @override
  Stream<Map<String, Map<String, dynamic>>> streamCollection(String collection) {
    return getController(collection).stream;
  }

  final List<Map<String, dynamic>> syncedDocs = [];

  @override
  void syncToCloud(String collection, String docId, Map<String, dynamic> data) {
    syncedDocs.add({'collection': collection, 'docId': docId, 'data': data});
  }

  @override
  void deleteFromCloud(String collection, String docId) {}

  @override
  void queueSyncInTxn(Isar isar, String collection, String docId, Map<String, dynamic> data) {}

  @override
  void queueDeleteInTxn(Isar isar, String collection, String docId) {}

  @override
  void queueProfileInTxn(Isar isar, Map<String, dynamic> data) {}

  @override
  void triggerFlush() {}

  @override
  void syncProfile(Map<String, dynamic> data) {}

  @override
  Future<void> pushProfileNow(Map<String, dynamic> data) async {}

  @override
  Future<Map<String, Map<String, dynamic>>> pullCollection(String collection) async => {};

  @override
  Future<Map<String, Map<String, dynamic>>> pullGlobalCollection(String collection) async => {};

  @override
  Future<Map<String, dynamic>?> pullProfile() async => null;

  @override
  Future<bool> hasCloudData() async => false;

  @override
  Future<void> bulkSync(String collection, Map<String, Map<String, dynamic>> docs) async {}

  @override
  Stream<int> get pendingCountStream => Stream.value(0);

  @override
  Future<void> flushNow() async {}

  @override
  void pauseSync() {}

  @override
  void resumeSync() {}

  @override
  Future<void> pauseAndDrainSync() async {}
}

void main() {
  if (Platform.isLinux) {
    test(
      'Skipping Isar tests on Linux CI due to binary linking issues',
      () {},
    );
    return;
  }

  TestWidgetsFlutterBinding.ensureInitialized();
  late Isar isar;

  setUp(() async {
    isar = await setUpTestIsar();
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  group('attachSync Lifecycle and Data Protection', () {
    test('Repeated attachment cancels previous listeners and does not duplicate writes', () async {
      final repo = MealRepository();
      await repo.init(isar);
      final sync = MockCloudSyncService()..currentUid = 'user_123';

      // Attach first time
      await repo.attachSync(sync);
      // Attach second time (should cleanly cancel previous subscription)
      await repo.attachSync(sync);

      final mealController = sync.getController('meal_logs');
      mealController.add({
        '2026-09-13': {
          'date': '2026-09-13',
          'customSlots': {},
          'updatedAt': DateTime.now().toIso8601String(),
        }
      });

      // Allow event loop to process
      await Future.delayed(const Duration(milliseconds: 500));
      await pumpEventQueue(times: 20);

      final count = isar.dailyMealLogs.where().countSync();
      expect(count, equals(1), reason: 'Should not create duplicate records from duplicate listeners');
      
      await repo.detachSync();
    });

    test('Account switching prevents stale in-flight events from writing to database', () async {
      final repo = MealRepository();
      await repo.init(isar);

      final syncA = MockCloudSyncService()..currentUid = 'account_A';
      await repo.attachSync(syncA);

      // Now account changes before event arrives
      final syncB = MockCloudSyncService()..currentUid = 'account_B';
      await repo.attachSync(syncB);

      // Event arrives on Account A's stream
      final mealControllerA = syncA.getController('meal_logs');
      mealControllerA.add({
        '2026-09-14': {
          'date': '2026-09-14',
          'customSlots': {},
          'updatedAt': DateTime.now().toIso8601String(),
        }
      });

      await Future.delayed(const Duration(milliseconds: 500));
      await pumpEventQueue(times: 20);

      final log = isar.dailyMealLogs.where().dateEqualTo('2026-09-14').findFirstSync();
      expect(log, isNull, reason: 'Event from Account A must not write after switching to Account B');

      await repo.detachSync();
    });

    test('Older stream event does not overwrite newer local edits in DailyLogRepository', () async {
      final repo = DailyLogRepository();
      await repo.init(isar);

      final sync = MockCloudSyncService()..currentUid = 'user_123';
      await repo.attachSync(sync);

      final date = '2026-09-15';
      // Local save with weight 75.0 (timestamp now)
      await repo.updateWeight(date, 75.0);
      final localLog = repo.getLog(date);
      expect(localLog?.weight, equals(75.0));

      // Incoming cloud event has older timestamp and weight 80.0
      final dailyController = sync.getController('daily_logs');
      dailyController.add({
        date: {
          'date': date,
          'weight': 80.0,
          'updatedAt': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
        }
      });

      await Future.delayed(const Duration(milliseconds: 500));
      await pumpEventQueue(times: 20);

      final refreshedLog = repo.getLog(date);
      expect(refreshedLog?.weight, equals(75.0), reason: 'Newer local edit must be preserved over older cloud event');

      await repo.detachSync();
    });

    test('New queue records arriving during a flush are preserved and only acknowledged batch records are deleted', () async {
      final userA = 'user_A';
      final userB = 'user_B';

      // Seed queue with records for userA and userB
      final item1 = SyncQueueItem(
        collection: 'meal_logs',
        docId: '2026-09-01',
        payload: '{"test": 1}',
        timestamp: DateTime.now(),
        uid: userA,
      );
      final item2 = SyncQueueItem(
        collection: 'meal_logs',
        docId: '2026-09-02',
        payload: '{"test": 2}',
        timestamp: DateTime.now(),
        uid: userA,
      );
      final itemOtherUser = SyncQueueItem(
        collection: 'meal_logs',
        docId: '2026-09-03',
        payload: '{"test": 3}',
        timestamp: DateTime.now(),
        uid: userB,
      );

      await isar.writeTxn(() async {
        await isar.syncQueueItems.putAll([item1, item2, itemOtherUser]);
      });

      // Fetch batch for userA (as FirestoreSyncService does)
      final batchToFlush = await isar.syncQueueItems.where()
          .filter()
          .uidEqualTo(userA)
          .findAll();

      expect(batchToFlush.length, equals(2));
      final batchIds = batchToFlush.map((e) => e.id).toList();

      // Simulate a new record arriving while the flush is in-flight
      final newItemDuringFlush = SyncQueueItem(
        collection: 'meal_logs',
        docId: '2026-09-04',
        payload: '{"test": 4}',
        timestamp: DateTime.now(),
        uid: userA,
      );
      await isar.writeTxn(() async {
        await isar.syncQueueItems.put(newItemDuringFlush);
      });

      // Acknowledgment arrives: only successfully flushed IDs are deleted
      await isar.writeTxn(() async {
        await isar.syncQueueItems.deleteAll(batchIds);
      });

      // Verify that the new item for userA and the other user's item are preserved!
      final remainingUserA = await isar.syncQueueItems.where().filter().uidEqualTo(userA).findAll();
      expect(remainingUserA.length, equals(1));
      expect(remainingUserA.first.docId, equals('2026-09-04'));

      final remainingUserB = await isar.syncQueueItems.where().filter().uidEqualTo(userB).findAll();
      expect(remainingUserB.length, equals(1));
      expect(remainingUserB.first.docId, equals('2026-09-03'));
    });
  });
}
