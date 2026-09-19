import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:trufit_bodamma/repositories/daily_log_repository.dart';
import 'package:trufit_bodamma/repositories/meal_repository.dart';
import 'package:trufit_bodamma/repositories/habit_repository.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/app_config.dart';
import 'package:trufit_bodamma/interfaces/i_cloud_sync_service.dart';
import 'dart:io';
import '../helpers/test_isar_setup.dart';

class MockCloudSyncService implements ICloudSyncService {
  @override
  String get currentUid => 'test_user';
  @override
  bool get canSync => true;

  final List<String> syncEvents = [];
  final List<String> queuedSyncs = [];
  bool flushTriggered = false;
  bool shouldThrow = false;

  @override
  void triggerFlush() {
    flushTriggered = true;
  }

  @override
  void queueSyncInTxn(Isar isar, String collection, String docId, Map<String, dynamic> data) {
    if (shouldThrow) throw Exception('Simulated Txn Failure');
    queuedSyncs.add('$collection:$docId');
  }

  @override
  void queueDeleteInTxn(Isar isar, String collection, String docId) {
    queuedSyncs.add('DELETE-$collection:$docId');
  }

  @override
  Stream<Map<String, Map<String, dynamic>>> streamCollection(String collection) => const Stream.empty();
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
  void queueProfileInTxn(Isar isar, Map<String, dynamic> data) {}
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

  group('DailyLogRepository Concurrency', () {
    test('Overlapping mutable updates correctly isolate (weight + steps)', () async {
      final repo = DailyLogRepository();
      await repo.init(isar);
      await repo.attachSync(sync);
      
      final date = '2023-11-01';

      // Fire BOTH updates identically without waiting explicitly. 
      // Before Prompt 02, the second write overrode the first by branching from a stale baseline read.
      await Future.wait([
        repo.updateWeight(date, 72.5),
        repo.updateSteps(date, 5000, source: 'manual'),
      ]);

      final log = repo.getLog(date);
      expect(log, isNotNull);
      expect(log!.weight, 72.5, reason: 'Weight edit was discarded by stale read');
      expect(log.steps, 5000, reason: 'Steps edit was discarded by stale read');
    });
  });

  group('MealRepository Concurrency', () {
    test('Parallel slot overrides strictly aggregate without data loss', () async {
      final repo = MealRepository();
      await repo.init(isar);
      await repo.attachSync(sync);

      final date = '2023-11-01';

      await Future.wait([
        repo.saveMealSlot(date, 'breakfast', MealSlotLog(totalCalories: 300, items: [])),
        repo.saveMealSlot(date, 'lunch', MealSlotLog(totalCalories: 600, items: []))
      ]);

      var log = repo.getDailyLog(date);
      expect(log.customSlots.containsKey('breakfast'), isTrue);
      expect(log.customSlots.containsKey('lunch'), isTrue);
      
      // Fire parallel Clear A + Save B
      await Future.wait([
        repo.clearMealSlot(date, 'breakfast'),
        repo.saveMealSlot(date, 'dinner', MealSlotLog(totalCalories: 500, items: []))
      ]);

      log = repo.getDailyLog(date);
      expect(log.customSlots.containsKey('breakfast'), isFalse);
      expect(log.customSlots.containsKey('lunch'), isTrue);
      expect(log.customSlots.containsKey('dinner'), isTrue);
    });
  });

  group('HabitRepository Concurrency & Empty Lifecycle', () {
    test('Overlapping habit completions do not destroy siblings', () async {
      final repo = HabitRepository();
      await repo.init(isar);
      repo.attachSync(sync);

      final date = '2023-11-01';
      // Setup initial complex state
      await repo.setOverride(date, 'water', 'done');
      await repo.setCompletion(date, 'walk', 4000.0);

      // Mutate concurrently
      await Future.wait([
        repo.toggleCheckboxCompletion(date, 'sleep'), // auto-generates bool toggles
        repo.updateProgress(date, 'walk', 6000.0),
      ]);

      final c = repo.getCompletions(date);
      expect(c.completions['sleep'], isTrue);
      expect(c.completions['walk'], 6000.0);
      expect(c.overrides, containsPair('water', 'done'), reason: 'Previous overrides demolished during rewrite');
    });

    test('reorderHabits atomic list map avoids UI layout shifting gaps', () async {
       final repo = HabitRepository();
       await repo.init(isar);
       final habits = repo.getHabits(); // 3 default initially
       final rev = habits.reversed.toList();
       await repo.reorderHabits(rev); // Must use single putAll equivalent

       final newHabits = repo.getHabits();
       expect(newHabits.first.id, rev.first.id);
       expect(newHabits.last.id, rev.last.id);
    });

    test('Discarding final habit prevents seeding reset loop', () async {
       final repo = HabitRepository();
       await repo.init(isar);

       final habits = repo.getHabits();
       expect(habits, isNotEmpty); // Seeded.
       
       for (var h in habits) {
         await repo.deleteHabit(h.id);
       }
       
       expect(repo.getHabits(), isEmpty, reason: 'Manually dumped');

       // Re-initialize!
       final repo2 = HabitRepository();
       await repo2.init(isar); 

       expect(repo2.getHabits(), isEmpty, reason: 'Empty list should remain intentionally empty due to flag cache, avoiding defaults popping back up');
       
       final flag = isar.appConfigs.where().keyEqualTo('habits_seeded').findFirstSync();
       expect(flag, isNotNull);
    });

    test('Database transaction rollbacks omit partial UI invalidations', () async {
       final repo = HabitRepository();
       await repo.init(isar);
       repo.attachSync(sync);
       
       // Force a crash at the queue boundary
       sync.shouldThrow = true;
       
       var watcherFired = false;
       final sub = repo.watchUpdates.skip(1).listen((_) { watcherFired = true; });
       
       try {
         await repo.toggleCheckboxCompletion('2030-01-01', 'water');
       } catch (e) {
         // Expected Txn Failure 
       }
       
       expect(watcherFired, isFalse, reason: 'Emitting UI watchers during an actively crashing tx misleads the visual layer');
       sub.cancel();
    });
  });
}
