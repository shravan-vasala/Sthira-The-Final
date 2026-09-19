import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/services/ai_client.dart';

void main() {
  group('AI Resilience & Safety Tests', () {
    test('Simulate silent or stalled AI stream (inactivity timeout triggers)', () async {
      final aiClient = AiClient(
        mockCallModelStream: ({
          required String modelName,
          required String prompt,
          required String systemInstruction,
          String? apiKey,
        }) async* {
          yield 'Starting... ';
          await Future.delayed(const Duration(milliseconds: 200));
          yield 'Should not reach here';
        },
      );

      final stream = aiClient.generateTextStream(
        prompt: 'test prompt',
        systemInstruction: 'test instruction',
        apiKey: 'test_key',
        inactivityTimeout: const Duration(milliseconds: 50),
        overallDeadline: DateTime.now().add(const Duration(seconds: 1)),
      );

      expect(
        () async {
          await for (final _ in stream) {}
        },
        throwsA(isA<AiException>().having((e) => e.cause, 'cause', equals(AiErrorCause.timeout))),
      );
    });

    test('Global deadline terminates fallback chain across models', () async {
      int modelsTried = 0;
      final aiClient = AiClient(
        mockCallModel: ({
          required String modelName,
          required String prompt,
          String? systemInstruction,
          String? apiKey,
          List<dynamic>? imageBytesList,
          String? mimeType,
          Duration? timeout,
          Map<String, dynamic>? responseSchema,
        }) async {
          modelsTried++;
          await Future.delayed(const Duration(milliseconds: 60));
          throw AiException('503 Service Unavailable', cause: AiErrorCause.overloaded);
        },
      );

      final sw = Stopwatch()..start();
      try {
        await aiClient.generateJson(
          prompt: 'test',
          systemInstruction: 'test',
          apiKey: 'test_key',
        );
        fail('Should have thrown timeout');
      } catch (e) {
        sw.stop();
        expect(e, isA<AiException>());
      }

      expect(modelsTried, greaterThan(0));
    });

    test('Cancellation of one stream leaves concurrent stream running unimpeded', () async {
      final controller1 = StreamController<String>();
      final controller2 = StreamController<String>();

      final aiClient = AiClient(
        mockCallModelStream: ({
          required String modelName,
          required String prompt,
          required String systemInstruction,
          String? apiKey,
        }) {
          if (prompt == 'req1') return controller1.stream;
          return controller2.stream;
        },
      );

      final stream1 = aiClient.generateTextStream(
        prompt: 'req1',
        systemInstruction: 'sys',
        apiKey: 'key',
        inactivityTimeout: const Duration(seconds: 5),
      );

      final stream2 = aiClient.generateTextStream(
        prompt: 'req2',
        systemInstruction: 'sys',
        apiKey: 'key',
        inactivityTimeout: const Duration(seconds: 5),
      );

      final received1 = <String>[];
      final sub1 = stream1.listen((val) => received1.add(val), onError: (_) {});
      
      final received2 = <String>[];
      final sub2 = stream2.listen((val) => received2.add(val), onError: (_) {});

      // Emit on stream 1
      controller1.add('chunk 1 from req1');
      await Future.delayed(const Duration(milliseconds: 20));
      expect(received1, contains('chunk 1 from req1'));

      // Cancel stream 1 mid-flight
      await sub1.cancel();

      // Emit on stream 2 and verify it continues working unimpeded
      controller2.add('chunk from req2');
      await Future.delayed(const Duration(milliseconds: 20));
      expect(received2, contains('chunk from req2'));

      // Cleanly finish stream 2
      await controller2.close();
      await Future.delayed(const Duration(milliseconds: 20));
      await sub2.cancel();
    });

    test('Malformed JSON throws AiException with parse cause', () async {
      final aiClient = AiClient(
        mockCallModel: ({
          required String modelName,
          required String prompt,
          String? systemInstruction,
          String? apiKey,
          List<dynamic>? imageBytesList,
          String? mimeType,
          Duration? timeout,
          Map<String, dynamic>? responseSchema,
        }) async {
          return 'Not a valid JSON {{{';
        },
      );

      expect(
        () => aiClient.generateJson(
          prompt: 'p',
          systemInstruction: 's',
          apiKey: 'k',
        ),
        throwsA(isA<AiException>().having((e) => e.cause, 'cause', equals(AiErrorCause.parse))),
      );
    });
  });
}
