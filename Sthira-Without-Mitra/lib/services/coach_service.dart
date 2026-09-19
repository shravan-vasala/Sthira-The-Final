import 'package:flutter/foundation.dart';
import '../models/coach_context.dart';
import '../models/feature_availability.dart';
import 'ai_client.dart';

class CoachService {
  final String? apiKey;
  final AiClient aiClient;

  CoachService({this.apiKey, required this.aiClient});

  FeatureAvailability get availability => apiKey == null || apiKey!.isEmpty
      ? FeatureAvailability.disabled
      : FeatureAvailability.available;

  Stream<String> generateNoteStream({
    required CoachContext context,
    CancellationToken? cancellationToken,
  }) async* {
    if (cancellationToken?.isCancelled ?? false) return;
    if (context.isFuture) {
      yield '__LOCAL__';
      yield 'Coach notes will be available once this day arrives.';
      return;
    }
    if (availability == FeatureAvailability.disabled || !context.hasEntries) {
      yield '__LOCAL__';
      yield _localNote(context);
      return;
    }

    final prompt =
        '''
Client name: ${context.name}
${context.evidence}
''';
    final instruction =
        '''
You are a supportive fitness coach named ${context.coachLabel}.
Write 1-2 brief, encouraging sentences grounded only in the supplied records.
Address the selected date. For historical dates, reflect in the past tense;
do not describe that date as today or give time-of-day greetings.
Missing data is unknown, not zero or evidence of failure. Recorded calorie
totals may be partial; never infer a deficit, surplus or food quality.
A rest day is a schedule, not a completed workout. Section counts are parts
of one workout. Do not invent previous effort, streaks, causes or health
outcomes. Do not praise weight loss/gain as desirable without goal context.
Prefer one supported observation and one gentle, optional next step.
Use a friendly tone and at most one emoji. Return only the note text.
''';
    try {
      yield '__AI__';
      await for (final chunk in aiClient.generateTextStream(
        prompt: prompt,
        systemInstruction: instruction,
        apiKey: apiKey,
        cancellationToken: cancellationToken,
        overallDeadline: DateTime.now().add(const Duration(seconds: 10)),
      )) {
        if (cancellationToken?.isCancelled ?? false) return;
        yield chunk;
      }
      return;
    } catch (error) {
      debugPrint('Coach note generation failed: $error');
    }
    if (cancellationToken?.isCancelled ?? false) return;
    yield '__FALLBACK__';
    yield '__LOCAL__';
    yield _localNote(context);
  }

  String _localNote(CoachContext c) {
    final when = c.isToday ? 'today' : 'on ${c.dateKey}';
    if (c.sectionsTotal > 0 && c.sectionsDone == c.sectionsTotal) {
      return 'All planned workout sections are logged $when, ${c.name}. Take a moment to appreciate that effort.';
    }
    if (c.habitsTotal > 0 && c.habitsDone == c.habitsTotal) {
      return 'You met all ${c.habitsTotal} scheduled habit goals $when, ${c.name}. Each check-in helps you see your progress.';
    }
    if ((c.steps ?? 0) > 10000) {
      return 'You recorded ${c.steps} steps $when, ${c.name}. That is a useful check-in on your movement.';
    }
    if (c.isRestDay) {
      return 'Your plan scheduled rest $when, ${c.name}. Rest days are part of the routine too.';
    }
    if (!c.hasEntries) {
      return c.isToday
          ? 'Whenever you are ready, ${c.name}, log a meal, habit or activity to give your coach some context.'
          : 'There are no coaching records for ${c.dateKey} yet, ${c.name}.';
    }
    return 'Thanks for checking in $when, ${c.name}. Your records help you notice what works for you.';
  }
}
