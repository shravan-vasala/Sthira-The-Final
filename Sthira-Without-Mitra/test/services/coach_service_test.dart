import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/coach_context.dart';
import 'package:trufit_bodamma/services/coach_service.dart';
import 'package:trufit_bodamma/services/ai_client.dart';

void main() {
  test(
    'historical prompt preserves unknown values and forbids invented claims',
    () async {
      String? capturedPrompt;
      String? capturedInstruction;
      final client = AiClient(
        mockCallModelStream:
            ({
              required modelName,
              required prompt,
              required systemInstruction,
              apiKey,
            }) async* {
              capturedPrompt = prompt;
              capturedInstruction = systemInstruction;
              yield 'Supported note';
            },
      );
      final chunks = await CoachService(apiKey: 'key', aiClient: client)
          .generateNoteStream(
            context: CoachContext(
              date: DateTime(2026, 9, 18),
              today: DateTime(2026, 9, 21),
              steps: 0,
              hasEntries: true,
            ),
          )
          .toList();
      expect(chunks.join(), contains('Supported note'));
      expect(capturedPrompt, contains('2026-09-18 (historical day)'));
      expect(capturedPrompt, contains('Steps: 0'));
      expect(capturedPrompt, contains('Sleep hours: not recorded'));
      expect(capturedInstruction, contains('Missing data is unknown'));
      expect(capturedInstruction, contains('Section counts are parts'));
    },
  );

  test(
    'local empty/no-plan note does not invent rest, effort or a streak',
    () async {
      final text =
          (await CoachService(aiClient: AiClient())
                  .generateNoteStream(
                    context: CoachContext(
                      date: DateTime(2026, 9, 21),
                      today: DateTime(2026, 9, 21),
                    ),
                  )
                  .toList())
              .join();
      expect(text, contains('log a meal, habit or activity'));
      expect(text, isNot(contains('earned')));
      expect(text, isNot(contains('rest day')));
      expect(text, isNot(contains('streak')));
    },
  );

  test(
    'AI failure signals visible fallback and retains historical wording',
    () async {
      final client = AiClient(
        mockCallModelStream:
            ({
              required modelName,
              required prompt,
              required systemInstruction,
              apiKey,
            }) async* {
              throw AiException('unavailable', cause: AiErrorCause.invalidKey);
            },
      );
      final chunks = await CoachService(apiKey: 'key', aiClient: client)
          .generateNoteStream(
            context: CoachContext(
              date: DateTime(2026, 9, 18),
              today: DateTime(2026, 9, 21),
              steps: 5,
              hasEntries: true,
            ),
          )
          .toList();
      expect(chunks, contains('__FALLBACK__'));
      expect(chunks, contains('__LOCAL__'));
      expect(chunks.last, contains('on 2026-09-18'));
      expect(chunks.last, isNot(contains('today')));
    },
  );
}
