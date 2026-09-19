const bool kEnableAiProfiling = bool.fromEnvironment(
  'AI_PROFILE',
  defaultValue: false,
);

enum TerminalOutcome { success, partial, error, cancelled, cacheCompletion }

class AiProfileSession {
  final Map<String, Stopwatch> _timers = {};
  final Map<String, int> phaseMs = {};

  String? modelUsed;
  int attemptCount = 0;
  int imageCount = 0;
  int totalBytesSent = 0;
  int promptChars = 0;

  int? promptTokenCount;
  int? candidatesTokenCount;
  int? thoughtsTokenCount;
  int? cachedContentTokenCount;

  // New detailed UX metrics
  TerminalOutcome? terminalOutcome;
  String? failureReason;
  bool cacheHit = false;
  int retryCount = 0;

  void startPhase(String phaseName) {
    if (!kEnableAiProfiling) return;
    _timers[phaseName] = Stopwatch()..start();
  }

  void endPhase(String phaseName) {
    if (!kEnableAiProfiling) return;
    final timer = _timers.remove(phaseName);
    if (timer != null) {
      timer.stop();
      phaseMs[phaseName] =
          (phaseMs[phaseName] ?? 0) + timer.elapsedMilliseconds;
    }
  }

  void recordMetadata({
    String? modelUsed,
    int? attemptCount,
    int? imageCount,
    int? totalBytesSent,
    int? promptChars,
    int? promptTokenCount,
    int? candidatesTokenCount,
    int? thoughtsTokenCount,
    int? cachedContentTokenCount,
    TerminalOutcome? terminalOutcome,
    String? failureReason,
    bool? cacheHit,
    int? retryCount,
  }) {
    if (modelUsed != null) this.modelUsed = modelUsed;
    if (attemptCount != null) this.attemptCount = attemptCount;
    if (imageCount != null) this.imageCount = imageCount;
    if (totalBytesSent != null) this.totalBytesSent = totalBytesSent;
    if (promptChars != null) this.promptChars = promptChars;
    if (promptTokenCount != null) this.promptTokenCount = promptTokenCount;
    if (candidatesTokenCount != null)
      this.candidatesTokenCount = candidatesTokenCount;
    if (thoughtsTokenCount != null)
      this.thoughtsTokenCount = thoughtsTokenCount;
    if (cachedContentTokenCount != null)
      this.cachedContentTokenCount = cachedContentTokenCount;
    if (terminalOutcome != null) this.terminalOutcome = terminalOutcome;
    if (failureReason != null) this.failureReason = failureReason;
    if (cacheHit != null) this.cacheHit = cacheHit;
    if (retryCount != null) this.retryCount = retryCount;
  }

  // Pre-aggregated summary for logging/benchmarking
  Map<String, dynamic> toMap() {
    return {
      'uiTapMs': phaseMs['uiTapMs'],
      'selectionDwellMs': phaseMs['selectionDwellMs'],
      'pickMs': phaseMs['pickMs'],
      'fileReadMs': phaseMs['fileReadMs'],
      'preprocessMs': phaseMs['preprocessMs'],
      'hashMs': phaseMs['hashMs'],
      'cacheLookupMs': phaseMs['cacheLookupMs'],
      'uploadWaitMs': phaseMs['uploadWaitMs'],
      'networkMs': phaseMs['networkMs'],
      'bodyParseMs': phaseMs['bodyParseMs'],
      'parseMs': phaseMs['parseMs'],
      'cacheWriteMs': phaseMs['cacheWriteMs'],
      'nutritionLoadMs': phaseMs['nutritionLoadMs'],
      'nutritionMatchMs': phaseMs['nutritionMatchMs'],
      'firstUsableFrameMs': phaseMs['firstUsableFrameMs'],
      'correctionTimeMs': phaseMs['correctionTimeMs'],
      'durableSaveMs': phaseMs['durableSaveMs'],
      'totalMs': phaseMs['totalMs'],
      'modelUsed': modelUsed,
      'attemptCount': attemptCount,
      'imageCount': imageCount,
      'totalBytesSent': totalBytesSent,
      'promptChars': promptChars,
      'promptTokenCount': promptTokenCount,
      'candidatesTokenCount': candidatesTokenCount,
      'thoughtsTokenCount': thoughtsTokenCount,
      'cachedContentTokenCount': cachedContentTokenCount,
      'terminalOutcome': terminalOutcome?.name,
      'failureReason': failureReason,
      'cacheHit': cacheHit,
      'retryCount': retryCount,
    };
  }
}
