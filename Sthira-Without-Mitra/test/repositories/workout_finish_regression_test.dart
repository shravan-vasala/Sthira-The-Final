import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/models/sync_queue_item.dart';
import 'package:trufit_bodamma/models/workout_session.dart';
import 'package:trufit_bodamma/repositories/workout_repository.dart';
import '../helpers/test_isar_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  if (Platform.isLinux) return;
  late Isar database;
  late WorkoutRepository repository;
  setUp(() async {
    database = await setUpTestIsar();
    repository = WorkoutRepository();
    await repository.init(database);
    await database.writeTxn(() async {
      await database.syncQueueItems.clear();
    });
  });
  tearDown(() => tearDownTestIsar(database));

  test(
    'finish commits session and selected daily log while preserving other data',
    () async {
      await database.writeTxn(() async {
        await database.dailyLogs.put(
          DailyLog(
            date: '2026-09-14',
            steps: 6321,
            waterMl: 1200,
            dayNote: 'Good day',
          ),
        );
        await database.dailyLogs.put(DailyLog(date: '2026-09-15', steps: 42));
      });
      await repository.finishWorkout('2026-09-14', 'monday');
      final log = database.dailyLogs
          .where()
          .dateEqualTo('2026-09-14')
          .findFirstSync()!;
      expect(log.workoutStatus, 'completed');
      expect(log.workoutDayId, 'monday');
      expect(log.steps, 6321);
      expect(log.waterMl, 1200);
      expect(log.dayNote, 'Good day');
      expect(log.updatedAt, isNotNull);
      expect(
        database.dailyLogs
            .where()
            .dateEqualTo('2026-09-15')
            .findFirstSync()!
            .workoutStatus,
        isNull,
      );
      final session = database.workoutSessions
          .where()
          .keyEqualTo('2026-09-14_monday')
          .findFirstSync()!;
      expect(jsonDecode(session.jsonStr)['status'], 'completed');
      final outbox = database.syncQueueItems.where().findAllSync();
      expect(outbox.map((item) => item.collection).toSet(), {
        'daily_logs',
        'workout_sessions',
      });
      expect(
        outbox.every(
          (item) => jsonDecode(item.payload)['date'] == '2026-09-14',
        ),
        isTrue,
      );
    },
  );

  test(
    'a partial or skipped session can later be completed without duplicate records',
    () async {
      await repository.finishWorkout('2026-09-14', 'monday', status: 'skipped');
      expect(
        database.dailyLogs
            .where()
            .dateEqualTo('2026-09-14')
            .findFirstSync()!
            .workoutCompleted,
        isFalse,
      );
      await repository.finishWorkout('2026-09-14', 'monday', status: 'partial');
      await repository.finishWorkout('2026-09-14', 'monday');
      expect(
        database.dailyLogs
            .where()
            .dateEqualTo('2026-09-14')
            .findFirstSync()!
            .workoutCompleted,
        isTrue,
      );
      expect(
        database.workoutSessions
            .where()
            .keyEqualTo('2026-09-14_monday')
            .countSync(),
        1,
      );
      expect(
        database.dailyLogs.where().dateEqualTo('2026-09-14').countSync(),
        1,
      );
    },
  );

  test(
    'invalid status creates neither daily state nor outbox entries',
    () async {
      await expectLater(
        repository.finishWorkout('2026-09-14', 'monday', status: 'unknown'),
        throwsArgumentError,
      );
      expect(
        database.dailyLogs.where().dateEqualTo('2026-09-14').findFirstSync(),
        isNull,
      );
      expect(
        database.workoutSessions
            .where()
            .keyEqualTo('2026-09-14_monday')
            .findFirstSync(),
        isNull,
      );
      expect(database.syncQueueItems.countSync(), 0);
    },
  );
  test(
    'first finish atomically starts the program on the logged date once',
    () async {
      await database.writeTxn(() async {
        await database.userProfiles.put(
          UserProfile(name: 'Asha', targetCalories: 1850),
        );
      });
      await repository.finishWorkout('2026-09-14', 'monday');
      final profile = database.userProfiles.where().findFirstSync()!;
      expect(profile.planStartDate, DateTime(2026, 9, 14));
      expect(profile.name, 'Asha');
      expect(profile.targetCalories, 1850);
      final queuedProfile = database.syncQueueItems
          .where()
          .findAllSync()
          .where((item) => item.collection == '_profile_')
          .single;
      expect(
        jsonDecode(queuedProfile.payload)['planStartDate'],
        '2026-09-14T00:00:00.000',
      );
      expect(
        database.dailyLogs
            .where()
            .dateEqualTo('2026-09-14')
            .findFirstSync()!
            .workoutCompleted,
        isTrue,
      );
      expect(repository.isWorkoutFinished('2026-09-14', 'monday'), isTrue);
      await repository.finishWorkout('2026-09-15', 'tuesday');
      expect(
        database.userProfiles.where().findFirstSync()!.planStartDate,
        DateTime(2026, 9, 14),
      );
      expect(
        database.syncQueueItems.where().findAllSync().where(
          (item) => item.collection == '_profile_',
        ),
        hasLength(1),
      );
    },
  );
}
