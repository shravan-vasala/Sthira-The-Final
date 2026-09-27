import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:trufit_bodamma/services/ai_cache.dart';
import 'package:trufit_bodamma/services/ai_client.dart';

final _photo = Uint8List.fromList(
  img.encodeJpg(img.Image(width: 12, height: 12)),
);

class _MemoryCache extends AiCache {
  Map<String, dynamic>? result;

  @override
  AiCache forRequest() => this;

  @override
  Map<String, dynamic>? get(
    String prompt,
    String? systemInstruction, [
    String? imageContext,
    String? schemaStr,
  ]) => result;

  @override
  Future<void> set(
    String prompt,
    String? systemInstruction,
    Map<String, dynamic> result, [
    String? imageContext,
    String? schemaStr,
  ]) async {}
}

AiClient _client({
  required DateTime Function() now,
  required FutureOr<String?> Function(String model, String key) respond,
  AiCache? cache,
}) {
  final client = AiClient(
    cache: cache,
    availabilityClock: now,
    mockCallModel:
        ({
          required String modelName,
          required String prompt,
          String? systemInstruction,
          String? apiKey,
          List<Uint8List>? imageBytesList,
          String? mimeType,
          Duration? timeout,
          Map<String, dynamic>? responseSchema,
        }) async => respond(modelName, apiKey!),
  );
  addTearDown(client.dispose);
  return client;
}

Future<Map<String, dynamic>?> _scan(
  AiClient client, {
  String key = 'test-key',
  CancellationToken? token,
  void Function(AiScanStage)? onProgress,
}) => client.generateJson(
  prompt: 'Identify this meal.',
  systemInstruction: 'Return a meal as JSON.',
  imageBytesList: [_photo],
  mimeType: 'image/jpeg',
  isAlreadyProcessed: true,
  apiKey: key,
  cancellationToken: token,
  onProgress: onProgress,
);

Future<AiException> _failure(Future<dynamic> request) async {
  try {
    await request;
  } catch (error) {
    expect(error, isA<AiException>());
    return error as AiException;
  }
  throw TestFailure('Expected the request to fail.');
}

AiException _busy({Duration? retryAfter}) => AiException(
  'Service unavailable',
  cause: AiErrorCause.overloaded,
  statusCode: 503,
  providerCode: 'UNAVAILABLE',
  retryAfter: retryAfter,
);

void main() {
  final primary = AiClient.visionModelsToTry.first;
  final secondary = AiClient.visionModelsToTry.last;
  late DateTime now;

  setUp(() => now = DateTime.utc(2030, 1, 1));

  test(
    'a successful fallback is reused until the busy primary can be probed',
    () async {
      final calls = <String>[];
      var primaryBusy = true;
      final client = _client(
        now: () => now,
        respond: (model, _) {
          calls.add(model);
          if (model == primary && primaryBusy) throw _busy();
          return '{"food":"oats"}';
        },
      );

      expect(await _scan(client), {'food': 'oats'});
      expect(calls, [primary, secondary]);

      now = now.add(const Duration(seconds: 59));
      expect(await _scan(client), {'food': 'oats'});
      expect(calls, [primary, secondary, secondary]);

      primaryBusy = false;
      now = now.add(const Duration(seconds: 1));
      expect(await _scan(client), {'food': 'oats'});
      expect(calls, [primary, secondary, secondary, primary]);
    },
  );

  test(
    'both busy models block repeated taps until the earliest recovery time',
    () async {
      final calls = <String>[];
      var serviceBusy = true;
      final client = _client(
        now: () => now,
        respond: (model, _) {
          calls.add(model);
          if (!serviceBusy) return '{"food":"rice"}';
          if (model == secondary) now = now.add(const Duration(seconds: 2));
          throw _busy();
        },
      );

      final initial = await _failure(_scan(client));
      expect(initial.cause, AiErrorCause.overloaded);
      expect(initial.retryAfter, const Duration(seconds: 58));
      expect(calls, [primary, secondary]);

      for (var tap = 0; tap < 3; tap++) {
        final blocked = await _failure(_scan(client));
        expect(blocked.cause, AiErrorCause.overloaded);
        expect(blocked.retryAfter, const Duration(seconds: 58));
      }
      expect(calls, [primary, secondary]);

      now = now.add(const Duration(seconds: 57));
      final almostReady = await _failure(_scan(client));
      expect(almostReady.retryAfter, const Duration(seconds: 1));
      expect(calls, [primary, secondary]);

      now = now.add(const Duration(seconds: 1));
      serviceBusy = false;
      expect(await _scan(client), {'food': 'rice'});
      // Suppressed taps must not activate an additional 90-second circuit break.
      expect(calls, [primary, secondary, primary]);
    },
  );

  test(
    'a fallback that recovers during the primary attempt can still run',
    () async {
      final calls = <String>[];
      var recovering = false;
      final client = _client(
        now: () => now,
        respond: (model, _) {
          calls.add(model);
          if (!recovering) {
            if (model == secondary) {
              now = now.add(const Duration(seconds: 2));
            }
            throw _busy();
          }
          if (model == primary) {
            // The secondary was still cooling down when this scan started.
            now = now.add(const Duration(seconds: 3));
            throw _busy();
          }
          return '{"food":"rice"}';
        },
      );

      await _failure(_scan(client));
      now = now.add(const Duration(seconds: 58));
      recovering = true;
      expect(await _scan(client), {'food': 'rice'});
      expect(calls, [primary, secondary, primary, secondary]);
    },
  );

  test('changing credentials clears the old connection cooldown', () async {
    final calls = <String>[];
    final client = _client(
      now: () => now,
      respond: (model, key) {
        calls.add('$key/$model');
        if (key == 'old-key') throw _busy();
        return '{"food":"oats"}';
      },
    );

    await _failure(_scan(client, key: 'old-key'));
    expect(await _scan(client, key: 'new-key'), {'food': 'oats'});
    expect(calls, [
      'old-key/$primary',
      'old-key/$secondary',
      'new-key/$primary',
    ]);
  });

  test(
    'a late response from old credentials cannot cool down the new connection',
    () async {
      final calls = <String>[];
      final oldStarted = Completer<void>();
      final oldResponse = Completer<String?>();
      final client = _client(
        now: () => now,
        respond: (model, key) {
          calls.add('$key/$model');
          if (key == 'old-key' && model == primary) {
            oldStarted.complete();
            return oldResponse.future;
          }
          if (key == 'old-key') throw _busy();
          return '{"food":"oats"}';
        },
      );

      final pendingOld = _failure(_scan(client, key: 'old-key'));
      await oldStarted.future;
      expect(await _scan(client, key: 'new-key'), {'food': 'oats'});
      oldResponse.completeError(_busy());
      await pendingOld;

      expect(await _scan(client, key: 'new-key'), {'food': 'oats'});
      expect(calls.where((call) => call.startsWith('new-key/')), [
        'new-key/$primary',
        'new-key/$primary',
      ]);
    },
  );

  test(
    'an explicit provider cooldown blocks later taps across photo models',
    () async {
      final calls = <String>[];
      final client = _client(
        now: () => now,
        respond: (model, _) {
          calls.add(model);
          if (calls.length == 1) {
            throw _busy(retryAfter: const Duration(seconds: 90));
          }
          return '{"food":"oats"}';
        },
      );

      final failure = await _failure(_scan(client));
      expect(failure.retryAfter, const Duration(seconds: 90));
      now = now.add(const Duration(seconds: 10));
      final blocked = await _failure(_scan(client));
      expect(blocked.retryAfter, const Duration(seconds: 80));
      expect(calls, [primary]);

      now = now.add(const Duration(seconds: 80));
      expect(await _scan(client), {'food': 'oats'});
      expect(calls, [primary, primary]);
    },
  );

  test(
    'a short provider cooldown permits one same-model recovery attempt',
    () async {
      final calls = <String>[];
      final client = _client(
        now: DateTime.now,
        respond: (model, _) {
          calls.add(model);
          if (calls.length == 1) {
            throw _busy(retryAfter: const Duration(milliseconds: 50));
          }
          return '{"food":"oats"}';
        },
      );

      expect(await _scan(client), {'food': 'oats'});
      expect(await _scan(client), {'food': 'oats'});
      expect(calls, [primary, primary, primary]);
    },
  );

  test('exhausted quota preserves an explicit hold without retrying', () async {
    var calls = 0;
    final client = _client(
      now: () => now,
      respond: (_, _) {
        calls++;
        throw AiException(
          'Daily quota exhausted',
          cause: AiErrorCause.rateLimited,
          statusCode: 429,
          quotaExhausted: true,
          retryAfter: const Duration(seconds: 120),
        );
      },
    );
    expect((await _failure(_scan(client))).canRetry, isFalse);
    now = now.add(const Duration(seconds: 10));
    final blocked = await _failure(_scan(client));
    expect(blocked.quotaExhausted, isTrue);
    expect(blocked.retryAfter, const Duration(seconds: 110));
    expect(calls, 1);
  });

  test('a fractional cooldown remainder is awaited before retrying', () async {
    final calls = <String>[];
    var failed = false;
    var cooldownClockReads = 0;
    final client = _client(
      now: () {
        if (!failed) return now;
        cooldownClockReads++;
        if (cooldownClockReads == 1) return now;
        if (cooldownClockReads == 2) {
          return now.add(const Duration(microseconds: 999));
        }
        return now.add(const Duration(milliseconds: 1));
      },
      respond: (model, _) {
        calls.add(model);
        if (calls.length == 1) {
          failed = true;
          throw _busy(retryAfter: const Duration(milliseconds: 1));
        }
        return '{"food":"oats"}';
      },
    );

    expect(await _scan(client), {'food': 'oats'});
    expect(cooldownClockReads, greaterThanOrEqualTo(3));
    expect(calls, [primary, primary]);
  });

  test(
    'a concurrent provider cooldown extension stops an already waiting retry',
    () async {
      final calls = <String>[];
      final firstStarted = Completer<void>();
      final secondStarted = Completer<void>();
      final retryWaiting = Completer<void>();
      final firstResponse = Completer<String?>();
      final secondResponse = Completer<String?>();
      final client = _client(
        now: DateTime.now,
        respond: (model, _) {
          calls.add(model);
          if (calls.length == 1) {
            firstStarted.complete();
            return firstResponse.future;
          }
          if (calls.length == 2) {
            secondStarted.complete();
            return secondResponse.future;
          }
          throw TestFailure(
            'A provider cooldown must block another HTTP attempt.',
          );
        },
      );

      final first = _failure(
        _scan(
          client,
          onProgress: (stage) {
            if (stage == AiScanStage.retrying && !retryWaiting.isCompleted) {
              retryWaiting.complete();
            }
          },
        ),
      );
      await firstStarted.future;
      final second = _failure(_scan(client));
      await secondStarted.future;
      firstResponse.completeError(
        _busy(retryAfter: const Duration(milliseconds: 50)),
      );
      await retryWaiting.future;
      secondResponse.completeError(
        _busy(retryAfter: const Duration(seconds: 90)),
      );

      final secondFailure = await second;
      expect(
        secondFailure.retryAfter,
        greaterThan(const Duration(seconds: 80)),
      );
      final firstFailure = await first;
      expect(firstFailure.cause, AiErrorCause.overloaded);
      expect(firstFailure.retryAfter, greaterThan(const Duration(seconds: 80)));
      expect(calls, [primary, primary]);
    },
  );

  test(
    'rate limits without Retry-After impose a hold without changing models',
    () async {
      final calls = <String>[];
      var elapsed = Duration.zero;
      var limited = true;
      final client = _client(
        now: () => DateTime.now().add(elapsed),
        respond: (model, _) {
          calls.add(model);
          if (limited) {
            throw AiException(
              'Request limit reached',
              cause: AiErrorCause.rateLimited,
              statusCode: 429,
              providerCode: 'RESOURCE_EXHAUSTED',
            );
          }
          return '{"food":"oats"}';
        },
      );

      final failure = await _failure(_scan(client));
      expect(failure.cause, AiErrorCause.rateLimited);
      expect(calls, [primary, primary]);
      final blocked = await _failure(_scan(client));
      expect(blocked.cause, AiErrorCause.rateLimited);
      expect(blocked.retryAfter, isNotNull);
      expect(blocked.retryAfter!, greaterThan(Duration.zero));
      expect(
        blocked.retryAfter!,
        lessThanOrEqualTo(const Duration(seconds: 60)),
      );
      expect(calls, [primary, primary]);

      elapsed += blocked.retryAfter!;
      limited = false;
      expect(await _scan(client), {'food': 'oats'});
      expect(calls, [primary, primary, primary]);
    },
  );

  for (final cause in [
    AiErrorCause.parse,
    AiErrorCause.invalidKey,
    AiErrorCause.cancelled,
  ]) {
    test('$cause does not mark a model busy', () async {
      final calls = <String>[];
      final client = _client(
        now: () => now,
        respond: (model, _) {
          calls.add(model);
          if (calls.length == 1) {
            throw AiException('Request failed', cause: cause);
          }
          return '{"food":"oats"}';
        },
      );

      expect((await _failure(_scan(client))).cause, cause);
      expect(await _scan(client), {'food': 'oats'});
      expect(calls, [primary, primary]);
    });
  }

  test('cancellation still wins when every model is cooling down', () async {
    var calls = 0;
    final client = _client(
      now: () => now,
      respond: (_, _) {
        calls++;
        throw _busy();
      },
    );
    await _failure(_scan(client));
    final token = CancellationToken()..cancel();
    final cancelled = await _failure(_scan(client, token: token));
    expect(cancelled.cause, AiErrorCause.cancelled);
    expect(calls, 2);
  });

  test(
    'a valid cached meal remains available while both models cool down',
    () async {
      var calls = 0;
      final cache = _MemoryCache();
      final client = _client(
        now: () => now,
        cache: cache,
        respond: (_, _) {
          calls++;
          throw _busy();
        },
      );
      await _failure(_scan(client));
      cache.result = {'food': 'cached oats'};
      expect(await _scan(client), {'food': 'cached oats'});
      expect(calls, 2);
    },
  );
}
