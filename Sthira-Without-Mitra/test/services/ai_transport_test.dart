import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/services/ai_client.dart';

class _RedirectClient implements HttpClient {
  final HttpClient delegate;
  final Uri local;
  final List<Uri> urls = [];
  _RedirectClient(this.delegate, this.local);
  @override
  Future<HttpClientRequest> postUrl(Uri url) {
    urls.add(url);
    return delegate.postUrl(local);
  }

  @override
  void close({bool force = false}) => delegate.close(force: force);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

String _response(List<Map<String, dynamic>> parts, {String finish = 'STOP'}) =>
    jsonEncode({
      'candidates': [
        {
          'finishReason': finish,
          'content': {'parts': parts},
        },
      ],
    });

void main() {
  late HttpServer server;
  late _RedirectClient transport;
  late AiClient client;
  late Future<void> Function(HttpRequest) handler;
  int clientsCreated = 0;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    transport = _RedirectClient(
      HttpClient(),
      Uri.parse('http://127.0.0.1:' + server.port.toString()),
    );
    client = AiClient();
    clientsCreated = 0;
    server.listen((request) async {
      try {
        await handler(request);
      } on SocketException {
        // Expected when a deadline/cancellation disconnects an active response.
      } on HttpException {
        // Expected when a deadline/cancellation disconnects an active response.
      }
    });
  });

  tearDown(() async {
    client.dispose();
    transport.close(force: true);
    await server.close(force: true);
  });

  Future<T> withTransport<T>(Future<T> Function() action) =>
      HttpOverrides.runZoned(
        action,
        createHttpClient: (_) {
          clientsCreated++;
          return transport;
        },
      );

  Future<Map<String, dynamic>?> request({
    CancellationToken? token,
    DateTime? deadline,
    void Function(AiScanStage)? onProgress,
  }) => client.generateJson(
    prompt: 'meal',
    systemInstruction: 'JSON only',
    apiKey: 'test-key',
    cancellationToken: token,
    overallDeadline: deadline,
    onProgress: onProgress,
  );

  test('valid payload, multipart answers and reusable connections', () async {
    final ports = <int>[];
    handler = (req) async {
      ports.add(req.connectionInfo!.remotePort);
      expect(req.headers.value('x-goog-api-key'), 'test-key');
      final payload = jsonDecode(await utf8.decoder.bind(req).join()) as Map;
      final config = payload['generationConfig'] as Map;
      expect(config['thinkingConfig'], {'thinkingLevel': 'low'});
      expect(config['responseMimeType'], 'application/json');
      expect(config.containsKey('candidate_count'), isFalse);
      expect(config.containsKey('temperature'), isFalse);
      req.response.write(
        _response([
          {'thought': true, 'text': 'not JSON'},
          {'text': '{"items":'},
          {'text': '[]}'},
        ]),
      );
      await req.response.close();
    };
    await withTransport(() async {
      expect(await request(), {'items': []});
      expect(await request(), {'items': []});
    });
    expect(clientsCreated, 1);
    expect(ports.toSet().length, 1);
    expect(transport.urls.every((uri) => uri.query.isEmpty), isTrue);
  });

  test('overall deadline includes a body stalled after headers', () async {
    final bodyStarted = Completer<void>();
    handler = (req) async {
      await req.drain<void>();
      req.response.bufferOutput = false;
      req.response.write('{"candidates":');
      await req.response.flush();
      bodyStarted.complete();
    };
    final sw = Stopwatch()..start();
    await withTransport(() async {
      final pending = request(
        deadline: DateTime.now().add(const Duration(milliseconds: 300)),
      );
      final checked = expectLater(
        pending,
        throwsA(
          isA<AiException>().having(
            (e) => e.cause,
            'cause',
            AiErrorCause.timeout,
          ),
        ),
      );
      await bodyStarted.future;
      await checked;
    });
    expect(sw.elapsed, lessThan(const Duration(seconds: 2)));
  });

  test('cancelling one body does not cancel another request', () async {
    final bodyStarted = Completer<void>();
    int calls = 0;
    handler = (req) async {
      await req.drain<void>();
      if (calls++ == 0) {
        req.response.bufferOutput = false;
        req.response.write('{"candidates":');
        await req.response.flush();
        bodyStarted.complete();
      } else {
        req.response.write(
          _response([
            {'text': '{"ok":true}'},
          ]),
        );
        await req.response.close();
      }
    };
    await withTransport(() async {
      final token = CancellationToken();
      final first = request(token: token);
      final checked = expectLater(
        first,
        throwsA(
          isA<AiException>().having(
            (e) => e.cause,
            'cause',
            AiErrorCause.cancelled,
          ),
        ),
      );
      await bodyStarted.future;
      final second = request();
      token.cancel();
      await checked;
      expect(await second, {'ok': true});
    });
    expect(calls, 2);
  });

  test(
    '404 falls back even in debug builds and preserves status for HTML errors',
    () async {
      int calls = 0;
      handler = (req) async {
        await req.drain<void>();
        if (calls++ == 0) {
          req.response.statusCode = 404;
          req.response.write('<html>Not found</html>');
        } else {
          req.response.write(
            _response([
              {'text': '{"ok":true}'},
            ]),
          );
        }
        await req.response.close();
      };
      await withTransport(() async => expect(await request(), {'ok': true}));
      expect(calls, 2);
      expect(transport.urls.last.path, contains(AiClient.textModelsToTry.last));
    },
  );

  test(
    'cancel during retry backoff returns promptly without another request',
    () async {
      int calls = 0;
      handler = (req) async {
        calls++;
        await req.drain<void>();
        req.response.statusCode = 503;
        req.response.write('busy');
        await req.response.close();
      };
      await withTransport(() async {
        final token = CancellationToken();
        final sw = Stopwatch()..start();
        await expectLater(
          request(
            token: token,
            onProgress: (stage) {
              if (stage == AiScanStage.retrying) token.cancel();
            },
          ),
          throwsA(
            isA<AiException>().having(
              (e) => e.cause,
              'cause',
              AiErrorCause.cancelled,
            ),
          ),
        );
        expect(sw.elapsed, lessThan(const Duration(milliseconds: 750)));
      });
      expect(calls, 1);
    },
  );

  test(
    'truncated model output is rejected instead of cached as complete',
    () async {
      handler = (req) async {
        await req.drain<void>();
        req.response.write(
          _response([
            {'text': '{"ok":true}'},
          ], finish: 'MAX_TOKENS'),
        );
        await req.response.close();
      };
      await withTransport(
        () => expectLater(
          request(),
          throwsA(
            isA<AiException>().having(
              (e) => e.cause,
              'cause',
              AiErrorCause.parse,
            ),
          ),
        ),
      );
    },
  );

  test(
    'SSE ignores thought parts and accepts a terminal-only STOP event',
    () async {
      handler = (req) async {
        await req.drain<void>();
        req.response.headers.contentType = ContentType('text', 'event-stream');
        req.response.write(
          'data: ${jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'thought': true, 'text': 'hidden'},
                    {'text': 'Complete answer'},
                  ],
                },
              },
            ],
          })}\n\n',
        );
        req.response.write(
          'data: ${jsonEncode({
            'candidates': [
              {'finishReason': 'STOP'},
            ],
          })}\n\n',
        );
        await req.response.close();
      };
      final chunks = await withTransport(
        () => client
            .generateTextStream(
              prompt: 'text',
              systemInstruction: 's',
              apiKey: 'key',
            )
            .toList(),
      );
      expect(chunks.join(), 'Complete answer');
    },
  );

  for (final finish in ['MAX_TOKENS', 'SAFETY', 'MISSING']) {
    test(
      'SSE rejects incomplete terminal state $finish after partial text',
      () async {
        handler = (req) async {
          await req.drain<void>();
          req.response.headers.contentType = ContentType(
            'text',
            'event-stream',
          );
          req.response.write(
            'data: ${jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': 'Partial answer'},
                    ],
                  },
                },
              ],
            })}\n\n',
          );
          if (finish != 'MISSING') {
            req.response.write(
              'data: ${jsonEncode({
                'candidates': [
                  {'finishReason': finish},
                ],
              })}\n\n',
            );
          }
          await req.response.close();
        };
        await withTransport(
          () => expectLater(
            client
                .generateTextStream(
                  prompt: 'text',
                  systemInstruction: 's',
                  apiKey: 'key',
                )
                .toList(),
            throwsA(
              isA<AiException>().having(
                (e) => e.cause,
                'cause',
                AiErrorCause.parse,
              ),
            ),
          ),
        );
      },
    );
  }

  test(
    'SSE token cancellation aborts before headers without closing shared transport',
    () async {
      final slowStarted = Completer<void>();
      handler = (req) async {
        final payload = jsonDecode(await utf8.decoder.bind(req).join()) as Map;
        if (payload['contents'][0]['parts'][0]['text'] == 'slow') {
          slowStarted.complete();
          return; // Deliberately never send response headers.
        }
        req.response.headers.contentType = ContentType('text', 'event-stream');
        req.response.write(
          'data: ${_response([
            {'text': 'other request complete'},
          ])}\n\n',
        );
        await req.response.close();
      };
      await withTransport(() async {
        final token = CancellationToken();
        final slow = client
            .generateTextStream(
              prompt: 'slow',
              systemInstruction: 's',
              apiKey: 'key',
              cancellationToken: token,
            )
            .toList();
        final assertion = expectLater(
          slow.timeout(const Duration(seconds: 2)),
          throwsA(
            isA<AiException>().having(
              (e) => e.cause,
              'cause',
              AiErrorCause.cancelled,
            ),
          ),
        );
        await slowStarted.future;
        token.cancel();
        await assertion;
        expect(
          await client
              .generateTextStream(
                prompt: 'fast',
                systemInstruction: 's',
                apiKey: 'key',
              )
              .join(),
          'other request complete',
        );
      });
      expect(clientsCreated, 1);
    },
  );
  test(
    'SSE HTTP 400 key errors use provider reason and finish the response',
    () async {
      handler = (request) async {
        await request.drain<void>();
        request.response.statusCode = 400;
        request.response.write('{"error":{"message":"API_KEY_INVALID"}}');
        await request.response.close();
      };
      await withTransport(
        () => expectLater(
          client
              .generateTextStream(
                prompt: 'text',
                systemInstruction: 's',
                apiKey: 'key',
              )
              .toList(),
          throwsA(
            isA<AiException>().having(
              (e) => e.cause,
              'cause',
              AiErrorCause.invalidKey,
            ),
          ),
        ),
      );
      expect(transport.urls, hasLength(1));
    },
  );
}
