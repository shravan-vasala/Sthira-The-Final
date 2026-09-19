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
  });
}

class AiLogger {
  static final List<AiLogEntry> logs = [];

  static void log({
    required String purpose,
    required String model,
    required int durationMs,
    int? preprocessMs,
    int? cacheMs,
    int? fallbackMs,
    int? firstTokenMs,
    required String outcome,
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
      ),
    );
    if (logs.length > 20) {
      logs.removeLast();
    }
  }
}
