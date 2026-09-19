import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'ai_logger.dart';

import 'package:googleai_dart/googleai_dart.dart'
    show ApiException, GoogleAIException;
import 'package:crypto/crypto.dart';

import 'ai_cache.dart';

import 'dart:async';
import 'dart:io';

import 'image_preprocessor.dart';
import 'ai_profiler.dart';

class CancellationToken {
  bool _isCancelled = false;
  bool get isCancelled => _isCancelled;
  final _completer = Completer<void>();
  Future<void> get onCancelled => _completer.future;

  void throwIfCancelled() {
    if (_isCancelled) {
      throw AiException(
        'Operation was cancelled.',
        cause: AiErrorCause.cancelled,
      );
    }
  }

  /// Bounds the whole operation and releases listeners/timers when it finishes.
  Future<T> waitFor<T>(
    Future<T> operation, {
    Duration? timeout,
    void Function()? onInterrupted,
  }) async {
    final interrupted = Completer<T>();
    Timer? timer;
    void interrupt(AiException error) {
      if (interrupted.isCompleted) return;
      onInterrupted?.call();
      interrupted.completeError(error);
    }

    final subscription = onCancelled.asStream().listen((_) {
      interrupt(
        AiException('Operation was cancelled.', cause: AiErrorCause.cancelled),
      );
    });
    if (_isCancelled) {
      interrupt(
        AiException('Operation was cancelled.', cause: AiErrorCause.cancelled),
      );
    } else if (timeout != null) {
      timer = Timer(timeout.isNegative ? Duration.zero : timeout, () {
        interrupt(
          AiException(
            'The AI is taking too long. Please try again.',
            cause: AiErrorCause.timeout,
          ),
        );
      });
    }
    try {
      return await Future.any([operation, interrupted.future]);
    } finally {
      timer?.cancel();
      await subscription.cancel();
    }
  }

  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    _completer.complete();
  }
}

enum AiScanStage { preparing, analyzing, retrying, resolving }

enum AiErrorCause {
  invalidKey,
  offline,
  notFound,
  rateLimited,
  overloaded,
  parse,
  timeout,
  cancelled,
  unknown,
}

class AiException implements Exception {
  final String message;
  final AiErrorCause? cause;
  AiException(this.message, {this.cause});
  @override
  String toString() => message;
}

AiErrorCause classifyAiError(Object error, {int? statusCode}) {
  if (error is AiException && error.cause != null) return error.cause!;
  if (error is SocketException) return AiErrorCause.offline;
  if (error is TimeoutException) return AiErrorCause.timeout;
  if (error is FormatException) return AiErrorCause.parse;
  final message =
      (error is GoogleAIException ? error.message : error.toString())
          .toLowerCase();
  // Numeric status is authoritative. Never scan correlation IDs, URLs or latency.
  final status = error is ApiException ? error.statusCode : statusCode;
  switch (status) {
    case 401:
    case 403:
      return AiErrorCause.invalidKey;
    case 404:
      return AiErrorCause.notFound;
    case 429:
      return AiErrorCause.rateLimited;
    case 408:
    case 504:
      return AiErrorCause.timeout;
    case 500:
    case 502:
    case 503:
      return AiErrorCause.overloaded;
  }
  if (message.contains('api_key_invalid') ||
      message.contains('api key not valid') ||
      message.contains('service_disabled') ||
      message.contains('has not been used in project') ||
      message.contains('permission_denied') ||
      message.contains('deactivated')) {
    return AiErrorCause.invalidKey;
  }
  if (message.contains('socketexception') ||
      message.contains('failed host lookup'))
    return AiErrorCause.offline;
  if (message.contains('resource_exhausted') || message.contains('quota'))
    return AiErrorCause.rateLimited;
  if (message.contains('not found')) return AiErrorCause.notFound;
  if (message.contains('unavailable') || message.contains('overloaded'))
    return AiErrorCause.overloaded;
  if (message.contains('timeout') || message.contains('timed out'))
    return AiErrorCause.timeout;
  if (message.contains('cancelled') || message.contains('aborted'))
    return AiErrorCause.cancelled;
  if (message.contains('formatexception') ||
      message.contains('json') ||
      message.contains('parse'))
    return AiErrorCause.parse;
  // Compatibility for explicit HTTP strings at older call sites/tests only.
  if (status == null) {
    final match = RegExp(
      r'^(?:exception: )?(?:http\s+)?(401|403|404|408|429|500|502|503|504)\b',
    ).firstMatch(message);
    if (match != null)
      return classifyAiError('', statusCode: int.parse(match.group(1)!));
  }
  return AiErrorCause.unknown;
}

class AiClientCircuitBreaker {
  int consecutiveFailures = 0;
  DateTime? lastFailureTime;
  static const int maxFailures = 3;
  static const Duration resetTimeout = Duration(seconds: 90);

  bool get isOpen {
    if (consecutiveFailures >= maxFailures) {
      if (lastFailureTime != null &&
          DateTime.now().difference(lastFailureTime!) > resetTimeout) {
        // Half-open state
        consecutiveFailures = 0;
        return false;
      }
      return true;
    }
    return false;
  }

  void recordFailure() {
    consecutiveFailures++;
    lastFailureTime = DateTime.now();
  }

  void recordSuccess() {
    consecutiveFailures = 0;
    lastFailureTime = null;
  }
}

class AiClient {
  final AiCache? cache;
  final AiClientCircuitBreaker _visionCircuitBreaker = AiClientCircuitBreaker();
  final AiClientCircuitBreaker _textCircuitBreaker = AiClientCircuitBreaker();

  // Verified Sept 2026: https://ai.google.dev/gemini-api/docs/models
  // Keep the existing vision models until a weighed-photo benchmark supports
  // an accuracy/latency tradeoff. No measured ranking is available yet.
  static const visionModelsToTry = ['gemini-3.8-flash', 'gemini-3.7-flash'];

  static const textModelsToTry = [
    'gemini-3.5-flash-lite',
    'gemini-3.1-flash-lite',
  ];
  HttpClient? _httpClient;

  @visibleForTesting
  Future<String?> Function({
    required String modelName,
    required String prompt,
    String? systemInstruction,
    String? apiKey,
    List<Uint8List>? imageBytesList,
    String? mimeType,
    Duration timeout,
    Map<String, dynamic>? responseSchema,
  })?
  mockCallModel;

  @visibleForTesting
  Stream<String?> Function({
    required String modelName,
    required String prompt,
    required String systemInstruction,
    String? apiKey,
  })?
  mockCallModelStream;

  AiClient({this.cache, this.mockCallModel, this.mockCallModelStream});

  void dispose() {
    _httpClient?.close(force: true);
    _httpClient = null;
  }

  Future<Map<String, dynamic>?> generateJson({
    AiProfileSession? profiler,
    required String prompt,
    required String systemInstruction,
    List<Uint8List>? imageBytesList,
    String? mimeType,
    required String apiKey,
    bool skipCache = false,
    bool isAlreadyProcessed = false,
    Map<String, dynamic>? responseSchema,
    CancellationToken? cancellationToken,
    DateTime? overallDeadline,
    void Function(AiScanStage)? onProgress,
    void Function(Map<String, dynamic>)? validateResponse,
  }) async {
    if (apiKey.isEmpty) {
      throw AiException(
        'API Key is required. Add it in Profile -> AI Settings.',
        cause: AiErrorCause.invalidKey,
      );
    }

    AiCache? requestCache;
    try {
      requestCache = cache?.forRequest();
    } catch (_) {
      // Account/database changes must not prevent an otherwise usable scan.
    }

    final token = cancellationToken ?? CancellationToken();
    token.throwIfCancelled();
    final isVision = imageBytesList != null && imageBytesList.isNotEmpty;
    // Include preparation, upload, response headers AND response body in the budget.
    final computedDeadline =
        overallDeadline ??
        DateTime.now().add(Duration(seconds: isVision ? 30 : 20));
    Duration remainingTime() => computedDeadline.difference(DateTime.now());
    int? preprocessMs;

    String? imageContext;
    final List<Uint8List> processedImages = [];
    String? actualMimeType = mimeType;
    if (isVision) {
      onProgress?.call(AiScanStage.preparing);
      final prepSw = Stopwatch()..start();
      profiler?.startPhase('preprocessMs');
      try {
        if (isAlreadyProcessed) {
          processedImages.addAll(imageBytesList);
        } else {
          final results = await token.waitFor(
            Future.wait(
              imageBytesList.map(
                (bytes) => ImagePreprocessor.processImage(
                  bytes,
                  mimeType ?? 'image/jpeg',
                ),
              ),
            ),
            timeout: remainingTime(),
          );
          for (final processed in results) {
            processedImages.add(processed.$1);
            actualMimeType = processed.$2;
          }
        }
        profiler?.startPhase('hashMs');
        try {
          imageContext = await token.waitFor(
            compute(_hashImages, processedImages),
            timeout: remainingTime(),
          );
        } finally {
          profiler?.endPhase('hashMs');
        }
      } finally {
        profiler?.endPhase('preprocessMs');
        preprocessMs = prepSw.elapsedMilliseconds;
      }
    }
    token.throwIfCancelled();
    profiler?.recordMetadata(
      imageCount: processedImages.length,
      totalBytesSent: processedImages.fold<int>(
        0,
        (sum, bytes) => sum + bytes.length,
      ),
      promptChars: prompt.length + systemInstruction.length,
    );

    final schemaKey = 'scan-v3:' + (responseSchema?.toString() ?? '');
    if (requestCache != null && !skipCache) {
      profiler?.startPhase('cacheLookupMs');
      try {
        final cachedResult = requestCache.get(
          prompt,
          systemInstruction,
          imageContext,
          schemaKey,
        );
        if (cachedResult != null) {
          validateResponse?.call(cachedResult);
          profiler?.recordMetadata(cacheHit: true);
          return cachedResult;
        }
      } catch (_) {
        // Cache/storage failures and invalid old responses are cache misses.
        // They must never prevent a fresh scan from reaching the service.
      } finally {
        profiler?.endPhase('cacheLookupMs');
      }
    }

    final breaker = isVision ? _visionCircuitBreaker : _textCircuitBreaker;

    if (breaker.isOpen) {
      throw AiException(
        'Our AI is taking a quick breather to handle traffic. Give it about a minute.',
        cause: AiErrorCause.rateLimited,
      );
    }

    if (cancellationToken?.isCancelled ?? false) {
      throw AiException(
        'Operation was cancelled.',
        cause: AiErrorCause.cancelled,
      );
    }

    final modelsToUse = isVision ? visionModelsToTry : textModelsToTry;
    final perAttemptTimeout = Duration(seconds: isVision ? 20 : 15);

    AiErrorCause? lastCause;
    int attempts = 0;

    for (int i = 0; i < modelsToUse.length; i++) {
      if (DateTime.now().isAfter(computedDeadline)) break;
      final modelName = modelsToUse[i];
      final int maxRetries =
          1; // max 2 attempts total per model for transient errors
      int attempt = 0;

      while (attempt <= maxRetries) {
        if (cancellationToken?.isCancelled ?? false) {
          throw AiException(
            'Operation was cancelled.',
            cause: AiErrorCause.cancelled,
          );
        }
        if (DateTime.now().isAfter(computedDeadline)) break;
        final remaining = computedDeadline.difference(DateTime.now());
        final attemptTimeout = remaining < perAttemptTimeout
            ? remaining
            : perAttemptTimeout;

        final sw = Stopwatch()..start();
        try {
          debugPrint(
            'AiClient: Trying model: $modelName (attempt ${attempt + 1})...',
          );

          attempts++;
          onProgress?.call(
            attempts == 1 ? AiScanStage.analyzing : AiScanStage.retrying,
          );
          profiler?.recordMetadata(
            modelUsed: modelName,
            attemptCount: attempts,
            retryCount: attempts - 1,
          );
          final waitFuture = _callModel(
            profiler: profiler,
            cancellationToken: token,
            modelName: modelName,
            prompt: prompt,
            systemInstruction: systemInstruction,
            apiKey: apiKey,
            imageBytesList: processedImages.isNotEmpty ? processedImages : null,
            mimeType: actualMimeType,
            timeout: attemptTimeout,
            responseSchema: responseSchema,
          );

          final response = await token.waitFor(
            waitFuture,
            timeout: attemptTimeout,
          );
          token.throwIfCancelled();

          sw.stop();

          if (response == null || response.isEmpty)
            throw AiException("Empty response", cause: AiErrorCause.unknown);

          profiler?.startPhase('parseMs');
          late final Map<String, dynamic> json;
          try {
            json = _parseJson(response);
            validateResponse?.call(json);
          } finally {
            profiler?.endPhase('parseMs');
          }

          AiLogger.log(
            purpose: isVision ? 'scan plate (vision)' : 'scan description',
            model: modelName,
            durationMs: sw.elapsedMilliseconds,
            preprocessMs: preprocessMs,
            outcome: 'success',
          );

          breaker.recordSuccess();
          final writeCache = requestCache;
          if (writeCache != null) {
            unawaited(
              Future(() async {
                try {
                  profiler?.startPhase('cacheWriteMs');
                  await writeCache.set(
                    prompt,
                    systemInstruction,
                    json,
                    imageContext,
                    schemaKey,
                  );
                } catch (e) {
                  debugPrint('Cache write failed: $e');
                } finally {
                  profiler?.endPhase('cacheWriteMs');
                }
              }),
            );
          }
          return json;
        } catch (e) {
          sw.stop();
          final errStr = e.toString();
          final cause = (e is AiException && e.cause != null)
              ? e.cause!
              : classifyAiError(e);
          lastCause = cause;

          AiLogger.log(
            purpose: 'AI error fallback',
            model: modelName,
            durationMs: sw.elapsedMilliseconds,
            preprocessMs: preprocessMs,
            outcome: cause.toString(),
          );

          if (cause == AiErrorCause.cancelled) rethrow;
          if (cause == AiErrorCause.invalidKey) {
            throw AiException(
              'This API key is invalid, disabled, or restricted. Please check Google AI Studio and ensure no IP or app restrictions are applied.',
              cause: cause,
            );
          } else if (cause == AiErrorCause.offline) {
            throw AiException(
              'You seem to be offline. Please check your internet connection.',
              cause: cause,
            );
          } else if (cause == AiErrorCause.parse) {
            throw AiException(
              'AI returned an invalid format. Please try again.\nDetails: $errStr',
              cause: cause,
            );
          } else if (cause == AiErrorCause.notFound) {
            debugPrint('AI model unavailable: $modelName; trying fallback.');
            break; // Next model
          } else if (cause == AiErrorCause.rateLimited ||
              cause == AiErrorCause.overloaded) {
            if (attempt < maxRetries) {
              final delay = attempt + 1; // 1 second delay
              if (DateTime.now()
                  .add(Duration(seconds: delay))
                  .isAfter(computedDeadline)) {
                break;
              }
              if (cancellationToken?.isCancelled ?? false) break;
              onProgress?.call(AiScanStage.retrying);
              await token.waitFor(
                Future<void>.delayed(Duration(seconds: delay)),
                timeout: remainingTime(),
              );
              if (cancellationToken?.isCancelled ?? false) break;
              attempt++;
              continue;
            } else {
              break; // Next model
            }
          } else if (cause == AiErrorCause.timeout) {
            break; // Next model immediately
          }
          break; // Unknown error -> next model
        }
      }
    }

    if (cancellationToken?.isCancelled ?? false) {
      throw AiException(
        'Operation was cancelled.',
        cause: AiErrorCause.cancelled,
      );
    }

    if (DateTime.now().isAfter(computedDeadline)) {
      throw AiException(
        'The AI is taking too long right now. Please try again.',
        cause: AiErrorCause.timeout,
      );
    }

    if (lastCause == AiErrorCause.rateLimited ||
        lastCause == AiErrorCause.overloaded) {
      breaker.recordFailure();
    }

    throw AiException(
      'Couldn\'t analyze right now. Try again in a minute.',
      cause: lastCause,
    );
  }

  static String _hashImages(List<Uint8List> images) =>
      images.map((bytes) => sha256.convert(bytes).toString()).join('_');

  static String _encodeRequest(Map<String, dynamic> input) {
    final images = input.remove('images') as List<Uint8List>?;
    final mimeType = input.remove('mimeType') as String?;
    final parts = (input['contents'] as List).first['parts'] as List;
    if (images != null) {
      for (final bytes in images) {
        parts.add({
          'inlineData': {
            'mimeType': mimeType ?? 'image/jpeg',
            'data': base64Encode(bytes),
          },
        });
      }
    }
    return jsonEncode(input);
  }

  Future<String?> _callModel({
    AiProfileSession? profiler,
    required String modelName,
    required String prompt,
    String? systemInstruction,
    String? apiKey,
    List<Uint8List>? imageBytesList,
    String? mimeType,
    Map<String, dynamic>? responseSchema,
    required CancellationToken cancellationToken,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (mockCallModel != null) {
      return mockCallModel!(
        modelName: modelName,
        prompt: prompt,
        systemInstruction: systemInstruction,
        apiKey: apiKey,
        imageBytesList: imageBytesList,
        mimeType: mimeType,
        timeout: timeout,
        responseSchema: responseSchema,
      );
    }
    final url = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$modelName:generateContent',
    );
    final payload = <String, dynamic>{
      if (systemInstruction != null)
        'systemInstruction': {
          'parts': [
            {'text': systemInstruction},
          ],
        },
      'generationConfig': {
        'responseMimeType': 'application/json',
        if (responseSchema != null) 'responseSchema': responseSchema,
        // generateContent nests thinkingLevel under thinkingConfig.
        // https://ai.google.dev/gemini-api/docs/generate-content/latest-model
        'thinkingConfig': {'thinkingLevel': 'low'},
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'images': imageBytesList,
      'mimeType': mimeType,
    };

    HttpClientRequest? request;
    StreamSubscription<String>? bodySubscription;
    Completer<String>? bodyCompleter;
    bool interrupted = false;
    final client = _httpClient ??= HttpClient();
    Future<String?> send() async {
      // Encoding multiple photos can block animation frames on slower phones.
      final body = imageBytesList?.isNotEmpty == true
          ? await compute(_encodeRequest, payload)
          : _encodeRequest(payload);
      cancellationToken.throwIfCancelled();
      if (interrupted) return null;
      final opened = await client.postUrl(url);
      request = opened;
      if (interrupted) {
        opened.abort();
        return null;
      }
      opened.headers.contentType = ContentType.json;
      opened.headers.set('x-goog-api-key', apiKey!);
      opened.write(body);
      final response = await opened.close();
      final bodyResult = bodyCompleter = Completer<String>();
      final buffer = StringBuffer();
      bodySubscription = response
          .transform(utf8.decoder)
          .listen(
            buffer.write,
            onError: (Object error, StackTrace stack) {
              if (!bodyResult.isCompleted)
                bodyResult.completeError(error, stack);
            },
            onDone: () {
              if (!bodyResult.isCompleted)
                bodyResult.complete(buffer.toString());
            },
            cancelOnError: true,
          );
      final responseBody = await bodyResult.future;
      if (response.statusCode != HttpStatus.ok) {
        // Preserve status even when a proxy returns an HTML/non-JSON error.
        throw AiException(
          'AI request failed (HTTP ' + response.statusCode.toString() + ').',
          cause: classifyAiError(responseBody, statusCode: response.statusCode),
        );
      }
      profiler?.startPhase('bodyParseMs');
      try {
        final json = jsonDecode(responseBody) as Map<String, dynamic>;
        final usage = json['usageMetadata'] as Map<String, dynamic>?;
        profiler?.recordMetadata(
          promptTokenCount: usage?['promptTokenCount'] as int?,
          candidatesTokenCount: usage?['candidatesTokenCount'] as int?,
          thoughtsTokenCount: usage?['thoughtsTokenCount'] as int?,
          cachedContentTokenCount: usage?['cachedContentTokenCount'] as int?,
        );
        final candidates = json['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) {
          throw AiException(
            'No meal result was returned. Try a clearer photo.',
            cause: AiErrorCause.parse,
          );
        }
        final candidate = candidates.first as Map;
        if (candidate['finishReason'] != null &&
            candidate['finishReason'] != 'STOP') {
          throw AiException(
            'The meal result was incomplete. Please try again.',
            cause: AiErrorCause.parse,
          );
        }
        final parts = candidate['content']?['parts'] as List? ?? [];
        final answer = parts
            .whereType<Map>()
            .where((part) => part['thought'] != true && part['text'] is String)
            .map((part) => part['text'] as String)
            .join();
        if (answer.trim().isEmpty) {
          throw AiException(
            'No meal result was returned. Try a clearer photo.',
            cause: AiErrorCause.parse,
          );
        }
        return answer;
      } on TypeError {
        throw AiException(
          'AI returned an invalid response. Please try again.',
          cause: AiErrorCause.parse,
        );
      } on FormatException {
        throw AiException(
          'AI returned an invalid response. Please try again.',
          cause: AiErrorCause.parse,
        );
      } finally {
        profiler?.endPhase('bodyParseMs');
      }
    }

    profiler?.startPhase('networkMs');
    try {
      return await cancellationToken.waitFor(
        send(),
        timeout: timeout,
        onInterrupted: () {
          interrupted = true;
          request?.abort();
          unawaited(bodySubscription?.cancel());
          final bodyResult = bodyCompleter;
          if (bodyResult != null && !bodyResult.isCompleted) {
            bodyResult.completeError(
              AiException(
                'AI request interrupted.',
                cause: cancellationToken.isCancelled
                    ? AiErrorCause.cancelled
                    : AiErrorCause.timeout,
              ),
            );
          }
        },
      );
    } finally {
      await bodySubscription?.cancel();
      profiler?.endPhase('networkMs');
    }
  }

  Stream<String> generateTextStream({
    required String prompt,
    required String systemInstruction,
    String? apiKey,
    Duration inactivityTimeout = const Duration(seconds: 15),
    CancellationToken? cancellationToken,
    DateTime? overallDeadline,
  }) {
    final token = cancellationToken ?? CancellationToken();
    late StreamController<String> controller;
    StreamSubscription<String?>? upstream;
    StreamSubscription<void>? cancellation;
    CancellationToken? attemptToken;
    Timer? inactivity;
    Timer? deadline;
    bool ended = false;
    bool yielded = false;
    int generation = 0;
    int modelIndex = 0;
    AiErrorCause lastCause = AiErrorCause.unknown;

    void cancelAttempt() {
      generation++;
      inactivity?.cancel();
      attemptToken?.cancel();
      // A stalled source's cancel Future must not hold the UI/fallback hostage.
      unawaited(upstream?.cancel());
      upstream = null;
    }

    void finish([AiException? error]) {
      if (ended) return;
      ended = true;
      cancelAttempt();
      deadline?.cancel();
      unawaited(cancellation?.cancel());
      if (error != null) controller.addError(error);
      unawaited(controller.close());
    }

    late void Function() startAttempt;
    void failed(Object error) {
      if (ended) return;
      lastCause = classifyAiError(error);
      if (token.isCancelled) lastCause = AiErrorCause.cancelled;
      if (yielded ||
          [
            AiErrorCause.cancelled,
            AiErrorCause.invalidKey,
            AiErrorCause.offline,
            AiErrorCause.parse,
          ].contains(lastCause)) {
        finish(
          AiException(
            'The response could not be completed. Please try again.',
            cause: lastCause,
          ),
        );
      } else {
        startAttempt();
      }
    }

    startAttempt = () {
      cancelAttempt();
      if (ended) return;
      if (token.isCancelled) {
        finish(
          AiException(
            'Operation was cancelled.',
            cause: AiErrorCause.cancelled,
          ),
        );
        return;
      }
      if (modelIndex >= textModelsToTry.length) {
        if (lastCause == AiErrorCause.rateLimited ||
            lastCause == AiErrorCause.overloaded) {
          _textCircuitBreaker.recordFailure();
        }
        finish(
          AiException(
            'Could not generate a response. Please try again.',
            cause: lastCause,
          ),
        );
        return;
      }
      final current = generation;
      final model = textModelsToTry[modelIndex++];
      final requestToken = attemptToken = CancellationToken();
      final watch = Stopwatch()..start();
      int? firstTokenMs;
      void resetTimer() {
        inactivity?.cancel();
        inactivity = Timer(inactivityTimeout, () {
          if (!ended && current == generation) {
            failed(
              AiException('AI stream timed out.', cause: AiErrorCause.timeout),
            );
          }
        });
      }

      resetTimer();
      try {
        upstream =
            _callModelStream(
              modelName: model,
              prompt: prompt,
              systemInstruction: systemInstruction,
              apiKey: apiKey,
              cancellationToken: requestToken,
            ).listen(
              (chunk) {
                if (ended ||
                    current != generation ||
                    chunk == null ||
                    chunk.isEmpty)
                  return;
                firstTokenMs ??= watch.elapsedMilliseconds;
                yielded = true;
                resetTimer();
                controller.add(chunk);
              },
              onError: (Object error) {
                if (ended || current != generation) return;
                AiLogger.log(
                  purpose: 'text stream fallback',
                  model: model,
                  durationMs: watch.elapsedMilliseconds,
                  firstTokenMs: firstTokenMs,
                  outcome: classifyAiError(error).toString(),
                );
                failed(error);
              },
              onDone: () {
                if (ended || current != generation) return;
                if (!yielded) {
                  failed(
                    AiException('Empty response.', cause: AiErrorCause.unknown),
                  );
                  return;
                }
                _textCircuitBreaker.recordSuccess();
                AiLogger.log(
                  purpose: 'text stream',
                  model: model,
                  durationMs: watch.elapsedMilliseconds,
                  firstTokenMs: firstTokenMs,
                  outcome: 'success',
                );
                finish();
              },
            );
      } catch (error) {
        failed(error);
      }
    };
    controller = StreamController<String>(
      onListen: () {
        cancellation = token.onCancelled.asStream().listen((_) {
          finish(
            AiException(
              'Operation was cancelled.',
              cause: AiErrorCause.cancelled,
            ),
          );
        });
        if (token.isCancelled) {
          finish(
            AiException(
              'Operation was cancelled.',
              cause: AiErrorCause.cancelled,
            ),
          );
          return;
        }
        if (_textCircuitBreaker.isOpen) {
          finish(
            AiException(
              'AI is busy. Please try again shortly.',
              cause: AiErrorCause.rateLimited,
            ),
          );
          return;
        }
        final remaining =
            (overallDeadline ?? DateTime.now().add(const Duration(seconds: 30)))
                .difference(DateTime.now());
        if (remaining <= Duration.zero) {
          finish(
            AiException(
              'Operation deadline exceeded.',
              cause: AiErrorCause.timeout,
            ),
          );
          return;
        }
        deadline = Timer(
          remaining,
          () => finish(
            AiException(
              'Operation deadline exceeded.',
              cause: AiErrorCause.timeout,
            ),
          ),
        );
        startAttempt();
      },
      onCancel: () {
        ended = true;
        cancelAttempt();
        deadline?.cancel();
        unawaited(cancellation?.cancel());
      },
    );
    return controller.stream;
  }

  Stream<String?> _callModelStream({
    required String modelName,
    required String prompt,
    required String systemInstruction,
    required CancellationToken cancellationToken,
    String? apiKey,
  }) {
    if (mockCallModelStream != null) {
      // Legacy high-level test hook represents already validated text.
      return mockCallModelStream!(
        modelName: modelName,
        prompt: prompt,
        systemInstruction: systemInstruction,
        apiKey: apiKey,
      );
    }
    late StreamController<String?> output;
    HttpClientRequest? request;
    StreamSubscription<String>? body;
    StreamSubscription<void>? cancellation;
    bool ended = false;
    bool complete = false;
    int receivedBytes = 0;
    final event = <String>[];
    void disposeTransport() {
      request?.abort();
      unawaited(body?.cancel());
      unawaited(cancellation?.cancel());
    }

    void finish([Object? error]) {
      if (ended) return;
      ended = true;
      disposeTransport();
      if (error != null) output.addError(error);
      unawaited(output.close());
    }

    void parseEvent() {
      if (event.isEmpty || ended) return;
      final data = event.join('\n');
      event.clear();
      if (data == '[DONE]') return;
      final decoded = jsonDecode(data) as Map<String, dynamic>;
      if (decoded['error'] case final Map error) {
        throw AiException(
          'AI stream request failed.',
          cause: classifyAiError(
            error['message']?.toString() ?? '',
            statusCode: error['code'] as int?,
          ),
        );
      }
      final candidates = decoded['candidates'] as List? ?? [];
      if (candidates.isEmpty) {
        if (decoded['promptFeedback'] != null) {
          throw AiException(
            'The response could not be completed. Please try again.',
            cause: AiErrorCause.parse,
          );
        }
        return;
      }
      final candidate = candidates.first as Map;
      final reason = candidate['finishReason'];
      if (reason != null && reason != 'STOP') {
        throw AiException(
          'The AI response was incomplete. Please try again.',
          cause: AiErrorCause.parse,
        );
      }
      final parts = candidate['content']?['parts'] as List? ?? [];
      final text = parts
          .whereType<Map>()
          .where((p) => p['thought'] != true && p['text'] is String)
          .map((p) => p['text'] as String)
          .join();
      if (text.isNotEmpty) output.add(text);
      if (reason == 'STOP') complete = true;
    }

    Future<void> send() async {
      try {
        cancellationToken.throwIfCancelled();
        if (apiKey == null || apiKey.isEmpty) {
          throw AiException(
            'API key is required.',
            cause: AiErrorCause.invalidKey,
          );
        }
        final client = _httpClient ??= HttpClient();
        final opened = await client.postUrl(
          Uri.https(
            'generativelanguage.googleapis.com',
            '/v1beta/models/$modelName:streamGenerateContent',
            {'alt': 'sse'},
          ),
        );
        request = opened;
        if (ended) {
          opened.abort();
          return;
        }
        opened.followRedirects = false;
        opened.headers.contentType = ContentType.json;
        opened.headers.set('x-goog-api-key', apiKey!);
        opened.write(
          jsonEncode({
            'systemInstruction': {
              'parts': [
                {'text': systemInstruction},
              ],
            },
            'generationConfig': {'responseMimeType': 'text/plain'},
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': prompt},
                ],
              },
            ],
          }),
        );
        final response = await opened.close();
        if (ended) return;
        if (response.statusCode != HttpStatus.ok) {
          final errorBody = StringBuffer();
          void finishHttpError() => finish(
            AiException(
              'AI request failed.',
              cause: classifyAiError(
                errorBody.toString(),
                statusCode: response.statusCode,
              ),
            ),
          );
          body = response
              .transform(utf8.decoder)
              .listen(
                (chunk) {
                  if (ended) return;
                  final remaining = 4096 - errorBody.length;
                  errorBody.write(
                    chunk.length > remaining
                        ? chunk.substring(0, remaining)
                        : chunk,
                  );
                  if (errorBody.length >= 4096) finishHttpError();
                },
                onError: (Object _) => finishHttpError(),
                onDone: finishHttpError,
              );
          return;
        }
        body = response
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
              (line) {
                if (ended) return;
                receivedBytes += line.length;
                try {
                  if (receivedBytes > 1024 * 1024)
                    throw const FormatException('Response too large');
                  if (line.isEmpty) {
                    parseEvent();
                  } else if (line.startsWith('data:')) {
                    event.add(line.substring(5).trimLeft());
                  }
                } catch (error) {
                  finish(
                    error is AiException
                        ? error
                        : AiException(
                            'The AI response was incomplete. Please try again.',
                            cause: AiErrorCause.parse,
                          ),
                  );
                }
              },
              onError: (Object error) => finish(error),
              onDone: () {
                if (ended) return;
                try {
                  parseEvent();
                } catch (_) {
                  complete = false;
                }
                finish(
                  complete
                      ? null
                      : AiException(
                          'The AI response ended early. Please try again.',
                          cause: AiErrorCause.parse,
                        ),
                );
              },
            );
      } catch (error) {
        finish(error);
      }
    }

    output = StreamController<String?>(
      onListen: () {
        cancellation = cancellationToken.onCancelled.asStream().listen(
          (_) => finish(
            AiException(
              'Operation was cancelled.',
              cause: AiErrorCause.cancelled,
            ),
          ),
        );
        unawaited(send());
      },
      onCancel: () {
        ended = true;
        disposeTransport();
      },
    );
    return output.stream;
  }

  Map<String, dynamic> _parseJson(String text) {
    try {
      final cleaned = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      throw AiException(
        'Something went wrong parsing the response. Please try again.',
        cause: AiErrorCause.parse,
      );
    }
  }
}
