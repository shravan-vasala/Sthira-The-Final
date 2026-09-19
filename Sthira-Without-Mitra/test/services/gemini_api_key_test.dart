import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/services/gemini_food_service.dart';
import 'package:trufit_bodamma/services/ai_client.dart';
import 'package:trufit_bodamma/services/nutrition_lookup_service.dart';

// Test setup using dart:io HttpOverrides to capture outgoing googleai_dart requests
class MockHttpOverrides extends HttpOverrides {
  final Future<HttpClientResponse> Function(HttpClientRequest request) handler;
  MockHttpOverrides(this.handler);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient(handler);
  }
}

class MockHttpClient implements HttpClient {
  final Future<HttpClientResponse> Function(HttpClientRequest request) handler;
  MockHttpClient(this.handler);

  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}
  @override
  void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials) {}
  @override
  set authenticate(Future<bool> Function(Uri url, String scheme, String? realm)? f) {}
  @override
  set authenticateProxy(Future<bool> Function(String host, int port, String scheme, String? realm)? f) {}
  @override
  set badCertificateCallback(bool Function(X509Certificate cert, String host, int port)? callback) {}
  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> open(String method, String host, int port, String path) async => throw UnimplementedError();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return MockHttpClientRequest(url, handler);
  }
  @override
  Future<HttpClientRequest> delete(String host, int port, String path) async => throw UnimplementedError();
  @override
  Future<HttpClientRequest> deleteUrl(Uri url) async => throw UnimplementedError();
  @override
  Future<HttpClientRequest> get(String host, int port, String path) async => throw UnimplementedError();
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => throw UnimplementedError();
  @override
  Future<HttpClientRequest> head(String host, int port, String path) async => throw UnimplementedError();
  @override
  Future<HttpClientRequest> headUrl(Uri url) async => throw UnimplementedError();
  @override
  Future<HttpClientRequest> patch(String host, int port, String path) async => throw UnimplementedError();
  @override
  Future<HttpClientRequest> patchUrl(Uri url) async => throw UnimplementedError();
  @override
  Future<HttpClientRequest> post(String host, int port, String path) async => throw UnimplementedError();
  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    return MockHttpClientRequest(url, handler);
  }
  @override
  Future<HttpClientRequest> put(String host, int port, String path) async => throw UnimplementedError();
  @override
  Future<HttpClientRequest> putUrl(Uri url) async => throw UnimplementedError();
  
  @override
  set connectionFactory(Future<ConnectionTask<Socket>> Function(Uri url, String? proxyHost, int? proxyPort)? f) {}
  @override
  set keyLog(void Function(String line)? callback) {}
  @override
  set findProxy(String Function(Uri url)? f) {}
}

class MockHttpClientRequest implements HttpClientRequest {
  final Uri _url;
  final HttpHeaders _headers = MockHttpHeaders();
  final Future<HttpClientResponse> Function(HttpClientRequest request) handler;
  MockHttpClientRequest(this._url, this.handler);

  @override
  Uri get uri => _url;
  @override
  HttpHeaders get headers => _headers;
  
  @override
  bool bufferOutput = true;
  @override
  int contentLength = -1;
  @override
  late Encoding encoding;
  @override
  bool followRedirects = true;
  @override
  bool persistentConnection = true;
  @override
  final List<Cookie> cookies = [];
  @override
  int maxRedirects = 5;
  @override
  String get method => 'POST';
  @override
  HttpConnectionInfo? get connectionInfo => null;
  @override
  Future<HttpClientResponse> get done => throw UnimplementedError();

  @override
  void add(List<int> data) {}
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future<void> addStream(Stream<List<int>> stream) async {}
  @override
  Future<void> flush() async {}
  @override
  void write(Object? obj) {}
  @override
  void writeAll(Iterable objects, [String separator = ""]) {}
  @override
  void writeCharCode(int charCode) {}
  @override
  void writeln([Object? obj = ""]) {}
  @override
  Future<HttpClientResponse> close() async {
    return handler(this);
  }
  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}
}

class MockHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _headers = {};

  @override
  bool chunkedTransferEncoding = false;
  @override
  int contentLength = -1;
  @override
  ContentType? contentType;
  @override
  DateTime? date;
  @override
  DateTime? expires;
  @override
  String? host;
  @override
  DateTime? ifModifiedSince;
  @override
  bool persistentConnection = true;
  @override
  int? port;

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void clear() {}
  @override
  void forEach(void Function(String name, List<String> values) action) {}
  @override
  String? hostPort() => null;
  @override
  void noFolding(String name) {}
  @override
  void remove(String name, Object value) {}
  @override
  void removeAll(String name) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  String? value(String name) => null;
  @override
  List<String>? operator [](String name) => _headers[name];
}

class MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  final int _statusCode;
  final String _body;
  
  MockHttpClientResponse(this._statusCode, this._body);
  
  @override
  int get statusCode => _statusCode;
  
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream.value(utf8.encode(_body)).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
  
  // Stubs for other methods
  @override HttpConnectionInfo? get connectionInfo => null;
  @override int get contentLength => -1;
  @override HttpHeaders get headers => MockHttpHeaders();
  @override bool get isRedirect => false;
  @override bool get persistentConnection => true;
  @override String get reasonPhrase => '';
  @override final List<Cookie> cookies = [];
  @override X509Certificate? get certificate => null;
  @override List<RedirectInfo> get redirects => [];
  @override HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;
  @override Future<Socket> detachSocket() async => throw UnimplementedError();
  @override Future<HttpClientResponse> redirect([String? method, Uri? url, bool? followLoops]) async => throw UnimplementedError();
  @override Future<Socket> asSocket() async => throw UnimplementedError();
}

void main() {
  group('Gemini API Provider Resilience Tests', () {
    late GeminiFoodService service;
    late AiClient dummyAiClient;
    late NutritionLookupService dummyLookupService;

    setUp(() {
      dummyAiClient = AiClient();
      dummyLookupService = NutritionLookupService();
      service = GeminiFoodService(
        aiClient: dummyAiClient,
        nutritionLookup: dummyLookupService,
      );
    });

    tearDown(() {
      HttpOverrides.global = null;
    });

    test('1. Successful verification', () async {
      HttpOverrides.global = MockHttpOverrides((req) async {
        return MockHttpClientResponse(200, '{"candidates": [{"content": {"parts": [{"text": "pong"}]}}]}');
      });

      await expectLater(service.verifyApiKey('valid_key'), completes);
    });

    test('2. Slow request completing within deadline', () async {
      HttpOverrides.global = MockHttpOverrides((req) async {
        await Future.delayed(const Duration(seconds: 2)); // Under 10s budget per attempt
        return MockHttpClientResponse(200, '{"candidates": []}');
      });

      await expectLater(service.verifyApiKey('slow_key'), completes);
    });

    test('3. Timeout reported as timeout, not offline', () async {
      HttpOverrides.global = MockHttpOverrides((req) async {
        throw TimeoutException('Simulated timeout');
      });

      await expectLater(
        service.verifyApiKey('timeout_key'),
        throwsA(isA<AiException>().having((e) => e.cause, 'cause', AiErrorCause.timeout)),
      );
    });

    test('4. Genuine transport failure (SocketException)', () async {
      HttpOverrides.global = MockHttpOverrides((req) async {
        throw const SocketException('Failed host lookup');
      });

      await expectLater(
        service.verifyApiKey('offline_key'),
        throwsA(isA<AiException>().having((e) => e.cause, 'cause', AiErrorCause.offline)),
      );
    });

    test('5. Invalid credential', () async {
      HttpOverrides.global = MockHttpOverrides((req) async {
        return MockHttpClientResponse(400, '{"error": {"message": "API_KEY_INVALID"}}');
      });

      await expectLater(
        service.verifyApiKey('bad_key'),
        throwsA(isA<AiException>().having((e) => e.cause, 'cause', AiErrorCause.invalidKey)),
      );
    });

    test('6. Permission restriction', () async {
      HttpOverrides.global = MockHttpOverrides((req) async {
        return MockHttpClientResponse(403, '{"error": {"message": "PERMISSION_DENIED"}}');
      });

      await expectLater(
        service.verifyApiKey('denied_key'),
        throwsA(isA<AiException>().having((e) => e.cause, 'cause', AiErrorCause.invalidKey)),
      );
    });

    test('8. Model 404 with bounded fallback', () async {
      int attempts = 0;
      HttpOverrides.global = MockHttpOverrides((req) async {
        attempts++;
        if (req.uri.path.contains('gemini-3.5-flash-lite')) {
          return MockHttpClientResponse(404, '{"error": {"message": "models/gemini-3.5-flash-lite not found"}}');
        }
        return MockHttpClientResponse(200, '{"candidates": []}');
      });

      await expectLater(service.verifyApiKey('fallback_key'), completes);
      expect(attempts, 2);
    });

    test('9. All models unavailable, without claiming valid', () async {
      HttpOverrides.global = MockHttpOverrides((req) async {
        return MockHttpClientResponse(404, '{"error": {"message": "not found"}}');
      });

      await expectLater(
        service.verifyApiKey('missing_models_key'),
        throwsA(isA<AiException>().having((e) => e.cause, 'cause', AiErrorCause.notFound)),
      );
    });

    test('10. Quota rate limit stops promptly', () async {
      int attempts = 0;
      HttpOverrides.global = MockHttpOverrides((req) async {
        attempts++;
        return MockHttpClientResponse(429, '{"error": {"message": "quota exceeded"}}');
      });

      await expectLater(
        service.verifyApiKey('quota_key'),
        throwsA(isA<AiException>().having((e) => e.cause, 'cause', AiErrorCause.rateLimited)),
      );
      expect(attempts, 4, reason: 'Should not iterate models on quota hits (SDK retries 3 times)');
    });

    test('11. Invalid SDK parsing drops to unknown safely', () async {
      HttpOverrides.global = MockHttpOverrides((req) async {
        return MockHttpClientResponse(200, 'Not A valid JSON');
      });

      await expectLater(
        service.verifyApiKey('bad_json_key'),
        throwsA(isA<AiException>()),
      );
    });
  });
}
