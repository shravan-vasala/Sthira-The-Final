class AiLogEntry {
  final DateTime timestamp;
  final String purpose;
  final String model;
  final int durationMs;
  final int? preprocessMs;
  final int? cacheMs;
  final int? fallbackMs;
  final int? firstTokenMs;
  final String outcome;
  final String? scanId;
  final int? runNumber;
  final int? attemptNumber;

  AiLogEntry({
    required this.timestamp,
    required this.purpose,
    required this.model,
    required this.durationMs,
    this.preprocessMs,
    this.cacheMs,
    this.fallbackMs,
    this.firstTokenMs,
    required this.outcome,
    this.scanId,
    this.runNumber,
    this.attemptNumber,
  });
}

/// One tap through to editable results, an error, or cancellation.
class AiScanRun {
  final int runNumber;
  final DateTime startedAt;
  final DateTime finishedAt;
  final int durationMs;
  final int requestCount;
  final String outcome;
  final String? failureReason;

  const AiScanRun({
    required this.runNumber,
    required this.startedAt,
    required this.finishedAt,
    required this.durationMs,
    required this.requestCount,
    required this.outcome,
    this.failureReason,
  });
}

class AiScanSummary {
  final String scanId;
  final DateTime startedAt;
  final List<AiScanRun> runs = [];
  int requestCount = 0;
  int activeDurationMs = 0;

  AiScanSummary({required this.scanId, required this.startedAt});

  AiScanRun get latest => runs.last;
  int get tapCount => latest.runNumber;
  int get retryTapCount => tapCount > 0 ? tapCount - 1 : 0;
  int get elapsedMs =>
      latest.finishedAt.difference(startedAt).inMilliseconds.clamp(0, 1 << 53);
  bool get firstTapSuccess =>
      tapCount == 1 &&
      (latest.outcome == 'success' || latest.outcome == 'cacheCompletion');
}

class AiActivity {
  final AiScanSummary? scan;
  final List<AiLogEntry> attempts;

  AiActivity({this.scan, required this.attempts});

  DateTime get timestamp => scan?.latest.finishedAt ?? attempts.first.timestamp;
}

class AiLogger {
  // Memory only. Keep enough request detail to inspect recent manual retries.
  static final List<AiLogEntry> logs = [];
  static final List<AiScanSummary> scans = [];
  static int _nextScan = 0;

  static String newScanId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${++_nextScan}';

  static void clear() {
    logs.clear();
    scans.clear();
  }

  static void finishScan({required String scanId, required AiScanRun run}) {
    final index = scans.indexWhere((scan) => scan.scanId == scanId);
    final scan = index < 0
        ? AiScanSummary(scanId: scanId, startedAt: run.startedAt)
        : scans[index];
    // A stale completion/cancellation cannot overwrite a later run.
    if (scan.runs.isNotEmpty && run.runNumber <= scan.latest.runNumber) return;
    if (index >= 0) scans.removeAt(index);
    scan.requestCount += run.requestCount;
    scan.activeDurationMs += run.durationMs;
    scan.runs.add(run);
    if (scan.runs.length > 20) scan.runs.removeAt(0);
    scans.insert(0, scan);
    if (scans.length > 20) scans.removeLast();
  }

  static List<AiActivity> get activities {
    final grouped = <String, List<AiLogEntry>>{};
    final activities = <AiActivity>[];
    for (final log in logs) {
      final id = log.scanId;
      if (id == null) {
        activities.add(AiActivity(attempts: [log]));
      } else {
        (grouped[id] ??= []).add(log);
      }
    }
    for (final scan in scans) {
      activities.add(
        AiActivity(scan: scan, attempts: grouped.remove(scan.scanId) ?? []),
      );
    }
    activities.addAll(grouped.values.map((logs) => AiActivity(attempts: logs)));
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return activities.take(20).toList(growable: false);
  }

  static void log({
    required String purpose,
    required String model,
    required int durationMs,
    int? preprocessMs,
    int? cacheMs,
    int? fallbackMs,
    int? firstTokenMs,
    required String outcome,
    String? scanId,
    int? runNumber,
    int? attemptNumber,
  }) {
    logs.insert(
      0,
      AiLogEntry(
        timestamp: DateTime.now(),
        purpose: purpose,
        model: model,
        durationMs: durationMs,
        preprocessMs: preprocessMs,
        cacheMs: cacheMs,
        fallbackMs: fallbackMs,
        firstTokenMs: firstTokenMs,
        outcome: outcome,
        scanId: scanId,
        runNumber: runNumber,
        attemptNumber: attemptNumber,
      ),
    );
    if (logs.length > 100) {
      logs.removeLast();
    }
  }
}
