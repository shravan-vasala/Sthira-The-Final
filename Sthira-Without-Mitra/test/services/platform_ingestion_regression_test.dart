import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/repositories/daily_log_repository.dart';
import 'package:trufit_bodamma/services/health_connect_service.dart';
import '../helpers/test_isar_setup.dart';

class _HistoryHealth extends HealthConnectService {
  int reads = 0;
  bool failOne = true;
  String? failedDate;
  @override
  Future<bool> isAuthorized() async => true;
  @override
  Future<HealthReadResult<int>> getStepsForDate(DateTime date) async {
    reads++;
    failedDate ??= date.toIso8601String();
    return failOne && date.toIso8601String() == failedDate
        ? HealthReadResult.error()
        : HealthReadResult.success(100);
  }

  @override
  Future<HealthReadResult<double>> getSleepForDate(DateTime date) async =>
      HealthReadResult.success(8);
}

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
    repository.dispose();
    await tearDownTestIsar(database);
  });

  HealthDailyData reading(
    String date, {
    HealthReadResult<int>? steps,
    HealthReadResult<double>? sleep,
  }) => HealthDailyData(
    dateStr: date,
    stepsResult: steps ?? HealthReadResult.empty(),
    sleepResult: sleep ?? HealthReadResult.empty(),
  );

  test(
    'missing health measurements do not create recorded zero days',
    () async {
      await repository.updateFromHealthConnect([reading('2026-09-10')]);
      expect(repository.getLog('2026-09-10'), isNull);
      await repository.updateFromHealthConnect([
        reading(
          '2026-09-11',
          steps: HealthReadResult.success(0),
          sleep: HealthReadResult.success(0),
        ),
      ]);
      expect(repository.getLog('2026-09-11')!.steps, 0);
      expect(repository.getLog('2026-09-11')!.sleepHours, 0);
    },
  );

  test('empty readings retain existing data and manual entries win', () async {
    await repository.updateFromHealthConnect([
      reading(
        '2026-09-10',
        steps: HealthReadResult.success(500),
        sleep: HealthReadResult.success(8),
      ),
    ]);
    await repository.updateSleep('2026-09-10', 7, source: 'manual');
    await repository.updateFromHealthConnect([
      reading('2026-09-10', sleep: HealthReadResult.success(9)),
    ]);
    expect(repository.getLog('2026-09-10')!.steps, 500);
    expect(repository.getLog('2026-09-10')!.sleepHours, 7);
  });

  test(
    'unchanged health batch emits no update and retains timestamp',
    () async {
      final data = reading('2026-09-10', steps: HealthReadResult.success(500));
      await repository.updateFromHealthConnect([data]);
      final timestamp = repository.getLog('2026-09-10')!.updatedAt;
      var changes = 0;
      final subscription = repository.watchUpdates.listen((_) => changes++);
      await repository.updateFromHealthConnect([data]);
      await Future<void>.delayed(Duration.zero);
      expect(changes, 0);
      expect(repository.getLog('2026-09-10')!.updatedAt, timestamp);
      await subscription.cancel();
    },
  );

  test('revoked account ownership prevents a late health batch', () async {
    await repository.updateFromHealthConnect([
      reading('2026-09-10', steps: HealthReadResult.success(500)),
    ], isCurrent: () => false);
    expect(repository.getLog('2026-09-10'), isNull);
  });

  test(
    'backfill retries only failed dates and completes after both metrics succeed',
    () async {
      final health = _HistoryHealth();
      await health.init(database);
      final persisted = <HealthDailyData>[];
      await health.backfillInBatches(
        persist: (batch) async {
          persisted.addAll(batch);
        },
        isCurrent: () => true,
      );
      expect(persisted.length, 90);
      expect(health.isBackfillDone, isFalse);
      expect(health.reads, 90);
      health.failOne = false;
      await health.backfillInBatches(
        persist: (batch) async {
          persisted.addAll(batch);
        },
        isCurrent: () => true,
      );
      expect(health.reads, 91);
      expect(health.isBackfillDone, isTrue);
    },
  );

  test(
    'a failed persistence does not advance the history checkpoint',
    () async {
      final health = _HistoryHealth()..failOne = false;
      await health.init(database);
      await expectLater(
        health.backfillInBatches(
          persist: (_) async {
            throw StateError('disk write failed');
          },
          isCurrent: () => true,
        ),
        throwsStateError,
      );
      expect(health.isBackfillDone, isFalse);
      final before = health.reads;
      await health.backfillInBatches(
        persist: (_) async {},
        isCurrent: () => true,
      );
      expect(health.reads - before, 90);
      expect(health.isBackfillDone, isTrue);
    },
  );
}
