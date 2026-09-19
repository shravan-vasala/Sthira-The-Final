import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/body_stats.dart';
import 'package:trufit_bodamma/models/exercise_log.dart';
import 'package:trufit_bodamma/models/friend.dart';
import 'package:trufit_bodamma/models/sync_queue_item.dart';
import 'package:trufit_bodamma/repositories/body_stats_repository.dart';
import 'package:trufit_bodamma/repositories/exercise_log_repository.dart';
import 'package:trufit_bodamma/repositories/friend_repository.dart';
import 'package:trufit_bodamma/services/app_database_manager.dart';

class _Paths extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _Paths(this.path);
  final String path;
  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  final opened = <Isar>[];
  setUpAll(() async {
    await Isar.initializeIsarCore(download: false);
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('sthira_ownership_');
    PathProviderPlatform.instance = _Paths(directory.path);
  });
  tearDown(() async {
    for (final database in opened) {
      if (database.isOpen) await database.close();
    }
    opened.clear();
    await directory.delete(recursive: true);
  });
  Future<Isar> open(String name) async {
    final database = await AppDatabaseManager.openDatabaseForUser(name);
    opened.add(database);
    return database;
  }

  test(
    'legacy database has one durable owner and never reappears after local deletion',
    () async {
      final legacy = await Isar.open(
        AppDatabaseManager.schemas,
        directory: directory.path,
      );
      await legacy.writeTxn(() async {
        await legacy.dailyLogs.put(DailyLog(date: '2026-09-19', steps: 1234));
      });
      await legacy.close();
      final a = await open('owner_a');
      final b = await open('owner_b');
      expect(a.dailyLogs.where().findAllSync().single.steps, 1234);
      expect(b.dailyLogs.countSync(), 0);
      expect(
        await File(
          '${directory.path}/legacy_database_owner.json',
        ).readAsString(),
        contains('owner_a'),
      );
      await a.close(deleteFromDisk: true);
      final reopened = await open('owner_a');
      expect(reopened.dailyLogs.countSync(), 0);
    },
  );
  test(
    'malformed legacy owner marker never assigns data to another account',
    () async {
      final legacy = await Isar.open(
        AppDatabaseManager.schemas,
        directory: directory.path,
      );
      await legacy.writeTxn(() async {
        await legacy.dailyLogs.put(DailyLog(date: '2026-09-19', steps: 7));
      });
      await legacy.close();
      await File(
        '${directory.path}/legacy_database_owner.json',
      ).writeAsString('incomplete marker');
      final account = await open('other');
      expect(account.dailyLogs.countSync(), 0);
      expect(await File('${directory.path}/default.isar').exists(), isTrue);
    },
  );
  test(
    'async mutations remain on their original database during repository rebinding',
    () async {
      final a = await open('mutation_a');
      final b = await open('mutation_b');
      final body = BodyStatsRepository();
      final exercises = ExerciseLogRepository();
      final friends = FriendRepository(a);
      await body.init(a);
      await exercises.init(a);
      // Either finish against A or abort. Neither outcome may write through B.
      final bodySave = body
          .saveStats(BodyStats(date: '2026-09-19', waist: 80))
          .catchError((Object error) {
            expect(error, isA<StateError>());
          });
      final exerciseSave = exercises
          .saveLog(
            ExerciseLog(
              date: '2026-09-19',
              instanceId: 'one',
              exerciseName: 'Push-ups',
              sets: [SetLog(reps: 10, weight: 0)],
            ),
          )
          .catchError((Object error) {
            expect(error, isA<StateError>());
          });
      final friendSave = friends.addFriend('friend_a', 'Asha').catchError((
        Object error,
      ) {
        expect(error, isA<StateError>());
      });
      await body.init(b);
      await exercises.init(b);
      await friends.init(b);
      await Future.wait([bodySave, exerciseSave, friendSave]);
      expect(b.bodyStats.countSync(), 0);
      expect(b.exerciseLogs.countSync(), 0);
      expect(b.friends.countSync(), 0);
      expect(b.syncQueueItems.countSync(), 0);
      expect(
        a.syncQueueItems.where().findAllSync().every(
          (item) => item.uid == 'mutation_a',
        ),
        isTrue,
      );
    },
  );
  test(
    'saved exercise and its pending outgoing mutation commit together',
    () async {
      final a = await open('mutation_queue');
      final exercises = ExerciseLogRepository();
      await exercises.init(a);
      await exercises.saveLog(
        ExerciseLog(
          date: '2026-09-19',
          instanceId: 'one',
          exerciseName: 'Push-ups',
          sets: [SetLog(reps: 10)],
        ),
      );
      expect(a.exerciseLogs.countSync(), 1);
      expect(a.syncQueueItems.countSync(), 1);
      expect(
        a.syncQueueItems.where().findAllSync().single.uid,
        'mutation_queue',
      );
    },
  );
}
