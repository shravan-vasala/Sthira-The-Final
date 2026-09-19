import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import '../models/coach_context.dart';
import '../models/coach_note.dart';
import '../models/exercise_log.dart';
import '../services/ai_client.dart';
import '../utils/workout_completion.dart';
import 'app_providers.dart';

final coachContextProvider = Provider<CoachContext>((ref) {
  ref.watch(accountGenerationProvider);
  ref.watch(yearlyActivityChangesProvider);
  final date = DateTime.parse(ref.watch(dateStringProvider));
  final start = DateFormat(
    'yyyy-MM-dd',
  ).format(DateTime(date.year, date.month, date.day - 14));
  final previous = DateFormat(
    'yyyy-MM-dd',
  ).format(DateTime(date.year, date.month, date.day - 1));
  final key = DateFormat('yyyy-MM-dd').format(date);
  final database = ref.watch(activeDatabaseProvider);
  final exercises =
      database?.exerciseLogs.filter().dateBetween(start, key).findAllSync() ??
      [];
  return CoachContext.fromRecords(
    date: date,
    today: ref.watch(clockProvider),
    profile: ref.watch(profileProvider),
    log: ref.watch(dailyLogProvider),
    meals: ref.watch(dailyMealLogProvider),
    habits: ref.watch(allHabitsProvider),
    completions: ref.watch(habitCompletionsProvider),
    previousCompletions: ref.watch(habitRepoProvider).getCompletions(previous),
    history: ref.watch(dailyLogRepoProvider).getLogsInRange(start, key),
    exerciseDates: exercises
        .where(WorkoutCompletion.hasMeaningfulWork)
        .map((e) => e.date)
        .toSet(),
    workoutPlan: ref.watch(workoutPlanProvider),
    hasLog: ref.watch(exerciseLogRepoProvider).hasLog,
  );
});

final coachNotesChangesProvider = StreamProvider<void>((ref) {
  ref.watch(accountGenerationProvider);
  if (ref.watch(accountTransitionProvider)) return const Stream.empty();
  return ref.watch(coachNoteRepoProvider).watchUpdates;
});

final coachHistoryProvider = Provider<List<CoachNote>>((ref) {
  ref.watch(accountGenerationProvider);
  ref.watch(coachNotesChangesProvider);
  if (ref.watch(accountTransitionProvider)) return const [];
  return ref
      .watch(coachNoteRepoProvider)
      .getRecentNotes(
        7,
        throughDate: DateFormat('yyyy-MM-dd').format(ref.watch(clockProvider)),
      );
});

class CoachNoteFeedback {
  final bool refreshing;
  final String? message;
  const CoachNoteFeedback({this.refreshing = false, this.message});
}

final coachNoteFeedbackProvider = StateProvider<CoachNoteFeedback>((ref) {
  ref.watch(accountGenerationProvider);
  ref.watch(dateStringProvider);
  final waiting =
      ref.watch(accountTransitionProvider) ||
      ref.watch(accountHydratingProvider);
  if (!waiting) {
    ref.watch(coachContextProvider.select((context) => context.fingerprint));
    ref.watch(coachServiceProvider);
  }
  return const CoachNoteFeedback();
});

String _cacheKey(String account, String date) =>
    'coach_note_last_gen_${Uri.encodeComponent(account)}_$date';

final coachNoteOutdatedProvider = Provider<bool>((ref) {
  if (ref.watch(accountTransitionProvider) ||
      ref.watch(accountHydratingProvider)) {
    return false;
  }
  final note = ref.watch(coachNoteProvider).valueOrNull;
  if (note == null ||
      ref.watch(coachNoteRepoProvider).getNote(note.date) == null) {
    return false;
  }
  final context = ref.watch(coachContextProvider);
  final account = ref.watch(activeAccountIdProvider);
  final stored = ref
      .watch(sharedPreferencesProvider)
      .getString('${_cacheKey(account, context.dateKey)}_context');
  // Legacy/cloud notes have no matching local generation context.
  return stored != context.fingerprintForNote(note.note);
});

class CoachNoteNotifier extends AsyncNotifier<CoachNote> {
  late String dateStr;
  int _currentRequestId = 0;
  bool _isFetching = false;
  bool _disposed = false;
  CancellationToken? _cancellationToken;
  Timer? _refreshTimer;

  @override
  FutureOr<CoachNote> build() {
    dateStr = ref.watch(dateStringProvider);
    ref.watch(activeAccountIdProvider);
    ref.watch(accountGenerationProvider);
    final waiting =
        ref.watch(accountTransitionProvider) ||
        ref.watch(accountHydratingProvider);
    _disposed = false;
    final revision = ++_currentRequestId;
    _cancellationToken?.cancel();
    _isFetching = false;
    _refreshTimer?.cancel();
    ref.onDispose(() {
      _disposed = true;
      _currentRequestId++;
      _cancellationToken?.cancel();
      _refreshTimer?.cancel();
    });
    if (waiting) {
      return CoachNote(
        date: dateStr,
        note: 'Loading your coach notes...',
        isAi: false,
      );
    }
    ref.watch(coachContextProvider.select((context) => context.fingerprint));
    ref.watch(coachServiceProvider);
    ref.listen(coachNotesChangesProvider, (_, _) {
      if (!_isFetching && !_disposed) {
        final saved = ref.read(coachNoteRepoProvider).getNote(dateStr);
        if (saved != null) {
          if (!ref.read(coachContextProvider).isFuture) {
            state = AsyncData(saved);
          }
        } else {
          ref.invalidateSelf();
        }
      }
    });
    final context = ref.read(coachContextProvider);
    if (context.isFuture) {
      return CoachNote(
        date: dateStr,
        note: 'Coach notes will be available once this day arrives.',
        isAi: false,
      );
    }
    final cached = ref.read(coachNoteRepoProvider).getNote(dateStr);
    if (context.isToday) {
      _refreshTimer = Timer(const Duration(milliseconds: 600), () {
        if (!_disposed && revision == _currentRequestId) {
          unawaited(fetchNote(background: cached != null));
        }
      });
    }
    return cached ??
        CoachNote(
          date: dateStr,
          note: context.isFuture
              ? 'Coach notes will be available once this day arrives.'
              : context.isToday
              ? 'Your coach is getting ready...'
              : 'No coach note saved for this day yet.',
          isAi: false,
        );
  }

  Future<void> fetchNote({bool force = false, bool background = false}) async {
    if (_disposed ||
        (_isFetching && !force) ||
        ref.read(accountTransitionProvider) ||
        ref.read(accountHydratingProvider)) {
      return;
    }
    final context = ref.read(coachContextProvider);
    if (context.isFuture) return;
    final requestId = ++_currentRequestId;
    final targetDate = dateStr;
    final account = ref.read(activeAccountIdProvider);
    final generation = ref.read(accountGenerationProvider);
    final token = CancellationToken();
    bool current() =>
        !_disposed &&
        requestId == _currentRequestId &&
        !token.isCancelled &&
        dateStr == targetDate &&
        ref.read(activeAccountIdProvider) == account &&
        ref.read(accountGenerationProvider) == generation &&
        !ref.read(accountTransitionProvider) &&
        !ref.read(accountHydratingProvider) &&
        ref.read(coachContextProvider).fingerprint == context.fingerprint;
    final key = _cacheKey(account, targetDate);
    final repo = ref.read(coachNoteRepoProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final cached = repo.getNote(targetDate);
    final last = DateTime.tryParse(prefs.getString(key) ?? '');
    if (!force && cached != null && last != null) {
      final age = DateTime.now().difference(last);
      if (!age.isNegative && age < const Duration(hours: 4)) return;
    }
    _refreshTimer?.cancel();
    _cancellationToken?.cancel();
    _cancellationToken = token;
    _isFetching = true;
    ref.read(coachNoteFeedbackProvider.notifier).state =
        const CoachNoteFeedback(refreshing: true);
    if (!background) state = const AsyncLoading();
    var fallback = false;
    try {
      var text = '';
      var isAi = false;
      await for (final chunk
          in ref
              .read(coachServiceProvider)
              .generateNoteStream(context: context, cancellationToken: token)) {
        if (!current()) return;
        if (chunk == '__AI__') {
          isAi = true;
          continue;
        }
        if (chunk == '__FALLBACK__') {
          fallback = true;
          continue;
        }
        if (chunk == '__LOCAL__') {
          isAi = false;
          text = '';
          continue;
        }
        text += chunk;
        if (!background) {
          state = AsyncData(
            CoachNote(date: targetDate, note: text, isAi: isAi),
          );
        }
      }
      if (!current()) return;
      if (text.trim().isEmpty) throw StateError('No coach note was returned.');
      final note = CoachNote(date: targetDate, note: text, isAi: isAi);
      await repo.saveNote(note);
      if (!current()) return;
      await prefs.setString(key, DateTime.now().toIso8601String());
      if (!current()) return;
      await prefs.setString('${key}_context', context.fingerprintForNote(text));
      if (!current()) return;
      state = AsyncData(note);
      ref.read(coachNoteFeedbackProvider.notifier).state = CoachNoteFeedback(
        message: fallback
            ? 'AI is unavailable. Showing a note based on your records.'
            : null,
      );
    } catch (error, stack) {
      if (!current()) return;
      final latest = repo.getNote(targetDate);
      state = latest == null ? AsyncError(error, stack) : AsyncData(latest);
      ref
          .read(coachNoteFeedbackProvider.notifier)
          .state = const CoachNoteFeedback(
        message: 'Could not update your coach note. Please try again.',
      );
    } finally {
      if (_currentRequestId == requestId) {
        _isFetching = false;
        if (current()) {
          final feedback = ref.read(coachNoteFeedbackProvider);
          ref.read(coachNoteFeedbackProvider.notifier).state =
              CoachNoteFeedback(message: feedback.message);
        }
      }
    }
  }
}

final coachNoteProvider = AsyncNotifierProvider<CoachNoteNotifier, CoachNote>(
  CoachNoteNotifier.new,
);
