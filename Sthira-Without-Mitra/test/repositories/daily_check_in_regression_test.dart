import 'package:trufit_bodamma/models/exercise_log.dart';
import 'package:trufit_bodamma/models/coach_context.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/habit.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:trufit_bodamma/interfaces/i_cloud_sync_service.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/sync_queue_item.dart';
import 'package:trufit_bodamma/repositories/daily_log_repository.dart';
import 'package:trufit_bodamma/services/csv_export_service.dart';
import '../helpers/test_isar_setup.dart';

class _Sync extends Fake implements ICloudSyncService {
  final String uid;
  final bool failFlush;
  int flushes = 0;
  _Sync(this.uid, {this.failFlush = false});
  @override
  String? get currentUid => uid;
  @override
  bool get canSync => true;
  @override
  void triggerFlush() {
    flushes++;
    if (failFlush) throw StateError('Network flush is unavailable');
  }
}

class _Paths extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String directory;
  _Paths(this.directory);
  @override
  Future<String?> getTemporaryPath() async => directory;
}

const _date = '2026-09-19';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Isar database;
  late DailyLogRepository repository;

  setUp(() async {
    database = await setUpTestIsar();
    repository = DailyLogRepository();
    await repository.init(database);
  });
  tearDown(() async {
    await repository.detachSync();
    repository.dispose();
    await tearDownTestIsar(database);
  });

  test(
    'null and blank notes remove old text while preserving health fields',
    () async {
      await repository.saveLog(
        DailyLog(
          date: _date,
          steps: 4000,
          sleepHours: 7,
          waterMl: 1000,
          bodyFat: 20,
        ),
      );
      for (final cleared in <String?>[null, '', '   \n ']) {
        await repository.updateCheckIn(_date, 'good', 'Old reflection');
        await repository.updateCheckIn(_date, 'okay', cleared);
        final log = repository.getOrCreate(_date);
        expect(log.dayFeeling, 'okay');
        expect(log.dayNote, isNull);
        expect(log.checkInUpdatedAt, isNotNull);
        expect(log.steps, 4000);
        expect(log.sleepHours, 7);
        expect(log.waterMl, 1000);
        expect(log.bodyFat, 20);
        expect(DailyLog.fromJson(log.toJson()).dayNote, isNull);
      }
    },
  );

  test(
    'note-only check-in is preserved and fully empty input removes reflection',
    () async {
      await repository.updateCheckIn(_date, null, '  A quiet afternoon.  ');
      final noteOnly = repository.getOrCreate(_date);
      expect(noteOnly.dayFeeling, isNull);
      expect(noteOnly.dayNote, 'A quiet afternoon.');
      expect(repository.hasActivityOnDate(_date), isTrue);
      expect(
        repository.exportForCloud()[_date]!['dayNote'],
        'A quiet afternoon.',
      );
      await repository.updateCheckIn(_date, '', ' ');
      final cleared = repository.getOrCreate(_date);
      expect(cleared.dayFeeling, isNull);
      expect(cleared.dayNote, isNull);
      expect(cleared.checkInUpdatedAt, isNull);
      expect(repository.hasActivityOnDate(_date), isFalse);
    },
  );

  test(
    'parallel narrow updates preserve a new reflection and unrelated values',
    () async {
      await repository.saveLog(
        DailyLog(date: _date, bodyFat: 20, waterMl: 100),
      );
      await Future.wait([
        repository.updateCheckIn(_date, 'low', 'A difficult day.'),
        repository.updateWater(_date, 500),
        repository.updateSteps(_date, 1234),
        repository.clearBodyFat(_date),
      ]);
      var log = repository.getOrCreate(_date);
      expect(log.dayFeeling, 'low');
      expect(log.dayNote, 'A difficult day.');
      expect(log.waterMl, 500);
      expect(log.steps, 1234);
      expect(log.bodyFat, isNull);
      await Future.wait([
        repository.updateCheckIn(_date, 'good', 'A calmer evening.'),
        repository.clearWater(_date),
      ]);
      log = repository.getOrCreate(_date);
      expect(log.dayNote, 'A calmer evening.');
      expect(log.waterMl, isNull);
      expect(log.steps, 1234);
    },
  );

  test(
    'removal is queued as cleared fields and pending intent defeats old cloud notes',
    () async {
      await repository.updateSteps(_date, 50);
      await repository.updateCheckIn(_date, 'great', 'Private reflection');
      final previous = repository.exportForCloud();
      await repository.removeCheckIn(_date);
      await repository.importFromCloud(previous);
      expect(repository.getOrCreate(_date).dayNote, isNull);
      expect(repository.getOrCreate(_date).dayFeeling, isNull);
      expect(repository.getOrCreate(_date).steps, 50);
      final writes =
          database.syncQueueItems
              .where()
              .findAllSync()
              .where((item) => item.collection == 'daily_logs')
              .toList()
            ..sort((a, b) => a.id.compareTo(b.id));
      final payload = jsonDecode(writes.last.payload) as Map<String, dynamic>;
      expect(payload.containsKey('dayNote'), isFalse);
      expect(payload.containsKey('dayFeeling'), isFalse);
      expect(payload.containsKey('checkInUpdatedAt'), isFalse);
      expect(payload['steps'], 50);
    },
  );

  test(
    'in-flight save stays with its originating account after repository rebind',
    () async {
      final other = await setUpTestIsar();
      final sync = _Sync(database.name);
      await repository.attachSync(sync, listen: false);
      try {
        final pending = repository.updateCheckIn(
          _date,
          'low',
          'First account only',
        );
        await repository.init(other);
        await pending;
        expect(
          database.dailyLogs
              .where()
              .dateEqualTo(_date)
              .findFirstSync()!
              .dayNote,
          'First account only',
        );
        expect(
          other.dailyLogs.where().dateEqualTo(_date).findFirstSync(),
          isNull,
        );
        expect(
          database.syncQueueItems.where().findAllSync().every(
            (item) => item.uid == database.name,
          ),
          isTrue,
        );
        expect(other.syncQueueItems.countSync(), 0);
        expect(sync.flushes, 0);
      } finally {
        await repository.init(database);
        await tearDownTestIsar(other);
      }
    },
  );

  test(
    'post-commit flush failure does not report a durable check-in as failed',
    () async {
      final sync = _Sync(database.name, failFlush: true);
      await repository.attachSync(sync, listen: false);
      await repository.updateCheckIn(_date, 'good', 'Saved locally');
      expect(repository.getOrCreate(_date).dayNote, 'Saved locally');
      expect(database.syncQueueItems.countSync(), 1);
      expect(sync.flushes, 1);
    },
  );

  test(
    'failed outbox write rolls back reflection and a later retry succeeds',
    () async {
      final directory = Directory.systemTemp.createTempSync(
        'check_in_rollback_',
      );
      final incomplete = await Isar.open(
        [DailyLogSchema],
        directory: directory.path,
        name: 'check_in_rollback_${DateTime.now().microsecondsSinceEpoch}',
      );
      try {
        await incomplete.writeTxn(
          () => incomplete.dailyLogs.put(
            DailyLog(
              date: _date,
              steps: 12,
              dayFeeling: 'okay',
              dayNote: 'Before failure',
            ),
          ),
        );
        await repository.init(incomplete);
        await expectLater(
          repository.updateCheckIn(_date, 'good', 'Retry this note'),
          throwsA(anything),
        );
        expect(repository.getOrCreate(_date).dayNote, 'Before failure');
        expect(repository.getOrCreate(_date).steps, 12);
        await repository.init(database);
        await repository.updateCheckIn(_date, 'good', 'Retry this note');
        expect(repository.getOrCreate(_date).dayNote, 'Retry this note');
      } finally {
        await repository.init(database);
        await tearDownTestIsar(incomplete);
      }
    },
  );

  test(
    'recorded zero water/body fat and reflection-only days count as activity',
    () async {
      final records = [
        DailyLog(date: '2026-09-15', waterMl: 0),
        DailyLog(date: '2026-09-16', bodyFat: 0),
        DailyLog(date: '2026-09-17', dayFeeling: 'veryLow'),
        DailyLog(date: '2026-09-18', dayNote: 'A note without a rating'),
      ];
      for (final record in records) {
        await repository.saveLog(record);
        expect(repository.hasActivityOnDate(record.date), isTrue);
      }
      expect(
        DailyLog(date: _date, dayFeeling: ' ', dayNote: '\n').hasAnyActivity,
        isFalse,
      );
    },
  );

  test(
    'daily CSV headers align with private reflection values and sanitize formulas',
    () async {
      final exportDirectory = Directory.systemTemp.createTempSync(
        'check_in_csv_',
      );
      final originalPaths = PathProviderPlatform.instance;
      PathProviderPlatform.instance = _Paths(exportDirectory.path);
      try {
        await repository.updateSteps(_date, 1234);
        await repository.updateCheckIn(_date, 'good', '=SUM(A1)');
        await database.writeTxn(
          () => database.exerciseLogs.put(
            ExerciseLog(
              date: _date,
              instanceId: 'timed-1',
              exerciseName: 'Plank',
              sets: [SetLog(setNumber: 1, durationSeconds: 45)],
            ),
          ),
        );
        final result = await CsvExportService(
          databaseResolver: () => database,
        ).exportData(null);
        expect(result.isSuccess, isTrue, reason: result.errorMessage);
        final archive = ZipDecoder().decodeBytes(
          await File(result.filePath!).readAsBytes(),
        );
        final text = utf8.decode(archive.findFile('daily_logs.csv')!.content);
        final rows = csv.decode(text);
        final header = rows.first;
        final values = rows[1];
        expect(values.length, header.length);
        expect(header, isNot(contains('Duration (seconds)')));
        expect(values[header.indexOf('Steps')].toString(), '1234');
        expect(values[header.indexOf('Day Feeling')], 'good');
        expect(values[header.indexOf('Day Note')], "'=SUM(A1)");
        final exerciseRows = csv.decode(
          utf8.decode(archive.findFile('exercise_logs.csv')!.content),
        );
        expect(exerciseRows[1].length, exerciseRows.first.length);
        expect(
          exerciseRows[1][exerciseRows.first.indexOf('Duration (seconds)')]
              .toString(),
          '45',
        );
        expect(
          values[header.indexOf('Check-in Updated At')].toString(),
          isNotEmpty,
        );
      } finally {
        PathProviderPlatform.instance = originalPaths;
        await exportDirectory.delete(recursive: true);
      }
    },
  );

  test(
    'private feelings and notes do not become coach prompt data or AI activity',
    () async {
      await repository.updateCheckIn(
        _date,
        'veryLow',
        'PRIVATE reflection text',
      );
      CoachContext context(DailyLog log) => CoachContext.fromRecords(
        date: DateTime(2026, 9, 19),
        today: DateTime(2026, 9, 19),
        profile: UserProfile(name: 'Alex'),
        log: log,
        meals: DailyMealLog(date: _date),
        habits: const [],
        completions: HabitCompletion(date: _date),
        previousCompletions: HabitCompletion(date: '2026-09-18'),
        history: const [],
        exerciseDates: const {},
        hasLog: (_, _) => false,
      );
      final reflected = context(repository.getOrCreate(_date));
      final empty = context(DailyLog(date: _date));
      expect(reflected.evidence, isNot(contains('PRIVATE')));
      expect(reflected.evidence, isNot(contains('veryLow')));
      expect(reflected.fingerprint, empty.fingerprint);
      expect(reflected.hasEntries, isFalse);
    },
  );
}
