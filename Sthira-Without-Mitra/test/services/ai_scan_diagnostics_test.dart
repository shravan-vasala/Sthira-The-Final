import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/services/ai_logger.dart';
import 'package:trufit_bodamma/services/ai_profiler.dart';

void main() {
  setUp(AiLogger.clear);
  tearDown(AiLogger.clear);

  test(
    'elapsed scan timing works without detailed profiling and finishes once',
    () async {
      final session = AiProfileSession();
      session.recordMetadata(attemptCount: 2);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      session.finish(TerminalOutcome.success);
      final duration = session.elapsedMs;
      session.finish(TerminalOutcome.cancelled);

      expect(duration, greaterThan(0));
      expect(AiLogger.scans, hasLength(1));
      expect(AiLogger.scans.single.runs, hasLength(1));
      expect(AiLogger.scans.single.latest.outcome, 'success');
      expect(AiLogger.scans.single.requestCount, 2);
      expect(AiLogger.scans.single.firstTapSuccess, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(
        session.elapsedMs,
        duration,
        reason: 'Review time must not be counted',
      );
    },
  );

  test(
    'groups manual retries separately from automatic requests and dwell',
    () {
      final started = DateTime(2026, 9, 20, 12);
      for (var run = 1; run <= 2; run++) {
        for (var attempt = 1; attempt <= 2; attempt++) {
          AiLogger.log(
            purpose: 'scan plate (vision)',
            model: 'fixture-model',
            durationMs: 2000,
            outcome: 'success',
            scanId: 'scan-one',
            runNumber: run,
            attemptNumber: attempt,
          );
        }
        AiLogger.finishScan(
          scanId: 'scan-one',
          run: AiScanRun(
            runNumber: run,
            startedAt: started.add(Duration(seconds: (run - 1) * 10)),
            finishedAt: started.add(Duration(seconds: (run - 1) * 10 + 5)),
            durationMs: 5000,
            requestCount: 2,
            outcome: run == 1 ? 'error' : 'success',
          ),
        );
      }
      final activity = AiLogger.activities.single;
      expect(activity.attempts, hasLength(4));
      expect(activity.scan!.tapCount, 2);
      expect(activity.scan!.retryTapCount, 1);
      expect(activity.scan!.requestCount, 4);
      expect(activity.scan!.activeDurationMs, 10000);
      expect(activity.scan!.elapsedMs, 15000);
      expect(activity.scan!.firstTapSuccess, isFalse);
    },
  );

  test(
    'partial results are distinct from completed results and cached results',
    () {
      final partial = AiProfileSession();
      partial.finish(TerminalOutcome.partial);
      expect(AiLogger.scans.first.latest.outcome, 'partial');
      expect(AiLogger.scans.first.firstTapSuccess, isFalse);
      final cached = AiProfileSession();
      cached.finish(TerminalOutcome.cacheCompletion);
      expect(AiLogger.scans.first.latest.outcome, 'cacheCompletion');
      expect(AiLogger.scans.first.requestCount, 0);
      expect(AiLogger.scans.first.firstTapSuccess, isTrue);
    },
  );

  test('late completion cannot overwrite a more recent retry', () {
    final first = AiProfileSession(scanId: 'scan-one');
    final retry = AiProfileSession(scanId: 'scan-one', runNumber: 2);
    retry.finish(TerminalOutcome.success);
    first.finish(TerminalOutcome.cancelled);
    expect(AiLogger.scans.single.latest.runNumber, 2);
    expect(AiLogger.scans.single.latest.outcome, 'success');
  });

  test('local diagnostics and nested retry detail stay bounded', () {
    for (var index = 0; index < 120; index++) {
      final session = AiProfileSession();
      AiLogger.log(
        purpose: 'scan plate (vision)',
        model: 'fixture-model',
        durationMs: 1,
        outcome: 'success',
        scanId: session.scanId,
        runNumber: 1,
        attemptNumber: 1,
      );
      session.finish(TerminalOutcome.success);
    }
    expect(AiLogger.logs, hasLength(100));
    expect(AiLogger.scans, hasLength(20));
    expect(AiLogger.activities, hasLength(20));
    for (var run = 1; run <= 30; run++) {
      AiProfileSession(scanId: 'many-retries', runNumber: run)
        ..recordMetadata(attemptCount: 1)
        ..finish(TerminalOutcome.error);
    }
    expect(AiLogger.scans.first.runs, hasLength(20));
    expect(AiLogger.scans.first.tapCount, 30);
    expect(AiLogger.scans.first.requestCount, 30);
  });
}
