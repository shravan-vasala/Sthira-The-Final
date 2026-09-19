import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:trufit_bodamma/repositories/badge_repository.dart';
import 'package:trufit_bodamma/models/badge.dart';
import 'package:trufit_bodamma/interfaces/i_cloud_sync_service.dart';
import 'dart:io';
import '../helpers/test_isar_setup.dart';

class MockCloudSyncService implements ICloudSyncService {
  @override
  String get currentUid => 'test_user';
  @override
  bool get canSync => true;

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
  
  // Stubs for other methods
  @override
  Future<Map<String, Map<String, dynamic>>> pullCollection(String collection) async => {};
  @override
  Future<Map<String, Map<String, dynamic>>> pullGlobalCollection(String collection) async => {};
  @override
  Future<void> stopSync() async {}
  @override
  void syncToCloud(String collection, String docId, Map<String, dynamic> data) {}
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
  TestWidgetsFlutterBinding.ensureInitialized();
  if (Platform.isLinux) {
    test('Skipping Isar GUI linking tests on Linux CI', () {});
    return;
  }

  late Isar isar;
  late MockCloudSyncService sync;

  setUp(() async {
    isar = await setUpTestIsar();
    sync = MockCloudSyncService();
  });

  tearDown(() async {
    await tearDownTestIsar(isar);
  });

  group('BadgeRepository Merge Policies', () {
    test('importFromCloud: older locked payload does not overwrite local unlocked badge', () async {
      final repo = BadgeRepository();
      await repo.init(isar);

      final date = DateTime.parse('2024-01-01');
      await repo.saveBadge(Badge(
        id: 'workout_10',
        category: 'workout',
        title: 'Consistency',
        description: 'Log 10 workouts',
        iconEmoji: '🔥',
        requiredProgress: 10,
        currentProgress: 10,
        unlockedAt: date,
      ));

      final staleCloudData = {
        'workout_10': {
          'id': 'workout_10',
          'category': 'workout',
          'title': 'Consistency',
          'description': 'Log 10 workouts',
          'iconEmoji': '🔥',
          'requiredProgress': 10,
          'currentProgress': 5,
          'unlockedAt': null,
        }
      };

      await repo.importFromCloud(staleCloudData);

      final badge = repo.getBadge('workout_10');
      expect(badge, isNotNull);
      expect(badge!.isUnlocked, isTrue);
      expect(badge.currentProgress, 10);
      expect(badge.unlockedAt, date);
    });

    test('attachSync stream: duplicate json payloads do not create duplicates', () async {
      final repo = BadgeRepository();
      await repo.init(isar);
      await repo.attachSync(sync);

      final liveUpdate = {
        'streak_3': {
          'id': 'streak_3',
          'category': 'streak',
          'title': 'Momentum',
          'description': '3 Days',
          'iconEmoji': '⚡',
          'requiredProgress': 3,
          'currentProgress': 2,
          'unlockedAt': null,
        }
      };

      // Emit identical payload multiple times
      sync.getController('badges').add(liveUpdate);
      sync.getController('badges').add(liveUpdate);

      // Wait a moment for stream to process
      await Future.delayed(const Duration(milliseconds: 100));

      // There should only be one 'streak_3' badge row
      final allBadges = repo.getAllBadges().where((b) => b.id == 'streak_3').toList();
      expect(allBadges.length, 1);
      expect(allBadges.first.currentProgress, 2);
    });

    test('_mergeCloudBadgeSafe: newer valid payload updates local successfully', () async {
      final repo = BadgeRepository();
      await repo.init(isar);

      // local progress is 5
      await repo.saveBadge(Badge(
        id: 'workout_50',
        category: 'workout',
        title: 'Iron Lifter',
        description: 'Log 50 workouts',
        iconEmoji: '🦍',
        requiredProgress: 50,
        currentProgress: 5,
        unlockedAt: null,
      ));

      final newerCloudData = {
        'workout_50': {
          'id': 'workout_50',
          'category': 'workout',
          'title': 'Iron Lifter',
          'description': 'Log 50 workouts',
          'iconEmoji': '🦍',
          'requiredProgress': 50,
          'currentProgress': 20,
          'unlockedAt': null,
        }
      };

      await repo.importFromCloud(newerCloudData);

      final badge = repo.getBadge('workout_50');
      expect(badge!.currentProgress, 20);
    });

    test('_mergeCloudBadgeSafe: cloud schema tweaks are discarded in favor of local', () async {
      final repo = BadgeRepository();
      await repo.init(isar);
      
      final localDef = repo.getBadge('streak_7')!;
      expect(localDef.requiredProgress, 7);
      expect(localDef.title, 'Unstoppable');

      // A stale cloud payload that has old/wrong title and requiredProgress
      // but higher progress.
      final invalidSchemaCloudData = {
        'streak_7': {
          'id': 'streak_7',
          'category': 'streak',
          'title': '7 Day Streak Old',
          'description': 'Do 7',
          'iconEmoji': 'X',
          'requiredProgress': 5, // Cloud says it only takes 5
          'currentProgress': 6,
          'unlockedAt': DateTime.parse('2030-01-01').toIso8601String(), // It was "unlocked" on cloud
        }
      };

      await repo.importFromCloud(invalidSchemaCloudData);

      final merged = repo.getBadge('streak_7')!;
      
      // Kept local structural integrity
      expect(merged.requiredProgress, 7);
      expect(merged.title, 'Unstoppable');
      expect(merged.iconEmoji, '🔥');
      
      // But merged the progress
      expect(merged.currentProgress, 6);
      expect(merged.unlockedAt, isNotNull);
    });

    test('_mergeCloudBadgeSafe: earlier timestamp is preserved', () async {
      final repo = BadgeRepository();
      await repo.init(isar);
      
      final cloudTime = DateTime.parse('2024-05-01');
      final localTime = DateTime.parse('2023-01-01');

      // Setup local with older (better) time
      await repo.saveBadge(Badge(
        id: 'workout_10',
        category: 'workout',
        title: 'Consistency',
        description: 'Log 10 workouts',
        iconEmoji: '🔥',
        requiredProgress: 10,
        currentProgress: 10,
        unlockedAt: localTime,
      ));

      final cloudData = {
        'workout_10': {
          'id': 'workout_10',
          'category': 'workout',
          'title': 'Consistency',
          'description': 'Log 10 workouts',
          'iconEmoji': '🔥',
          'requiredProgress': 10,
          'currentProgress': 10,
          'unlockedAt': cloudTime.toIso8601String(),
        }
      };

      await repo.importFromCloud(cloudData);

      final badge = repo.getBadge('workout_10');
      // local time should survive
      expect(badge!.unlockedAt, localTime);
    });

    test('default seeding does not overwrite earned badges', () async {
       final repo = BadgeRepository();
       // initialize
       await repo.init(isar);
       
       // user earns badge
       await repo.saveBadge(Badge(
         id: 'first_workout',
         category: 'workout',
         title: 'Welcome',
         description: 'First',
         iconEmoji: 'A',
         requiredProgress: 1,
         currentProgress: 1,
         unlockedAt: DateTime.now(),
       ));
       
       // Restart the app/repository effectively hitting init again
       final repo2 = BadgeRepository();
       await repo2.init(isar);
       
       final badge = repo2.getBadge('first_workout');
       expect(badge!.isUnlocked, isTrue, reason: 'Seeding overrode earned badge');
       expect(badge.currentProgress, 1);
    });
    
    test('fresh device import fully adopts cloud payload', () async {
       final repo = BadgeRepository();
       // don't init default seeds to pretend perfect fresh state, wait init() is forced 
       await repo.init(isar);
       
       // user deletes local db for fresh sync test (let's manually clear)
       await isar.writeTxn(() async {
         await isar.badges.clear();
       });
       
       final cloudData = {
         'new_cloud_only': {
           'id': 'new_cloud_only',
           'category': 'bonus',
           'title': 'Cloud',
           'description': 'Sync',
           'iconEmoji': '☁️',
           'requiredProgress': 1,
           'currentProgress': 1,
           'unlockedAt': DateTime.now().toIso8601String(),
         }
       };
       
       await repo.importFromCloud(cloudData);
       
       final badge = repo.getBadge('new_cloud_only');
       expect(badge, isNotNull);
       expect(badge!.isUnlocked, isTrue);
    });
  });
}
