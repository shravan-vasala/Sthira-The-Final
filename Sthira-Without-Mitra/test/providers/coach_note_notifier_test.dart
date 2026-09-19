import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/coach_context.dart';
import 'dart:async';
import 'package:trufit_bodamma/services/coach_service.dart';
import 'package:trufit_bodamma/services/ai_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/repositories/coach_note_repository.dart';
import 'package:trufit_bodamma/repositories/daily_log_repository.dart';
import 'package:trufit_bodamma/repositories/habit_repository.dart';
import 'package:trufit_bodamma/repositories/meal_repository.dart';
import 'package:trufit_bodamma/repositories/profile_repository.dart';
import 'package:trufit_bodamma/repositories/workout_repository.dart';
import 'package:trufit_bodamma/repositories/exercise_log_repository.dart';
import 'package:trufit_bodamma/models/coach_note.dart';
import 'package:isar/isar.dart';
import '../helpers/test_isar_setup.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';

class _ControlledCoach extends CoachService {
  final List<StreamController<String>> sources;
  int calls = 0;
  _ControlledCoach(this.sources) : super(aiClient: AiClient());
  @override
  Stream<String> generateNoteStream({
    required CoachContext context,
    CancellationToken? cancellationToken,
  }) => sources[calls++].stream;
}

class _RecordingCoach extends CoachService {
  final contexts = <CoachContext>[];
  _RecordingCoach() : super(aiClient: AiClient());
  @override
  Stream<String> generateNoteStream({
    required CoachContext context,
    CancellationToken? cancellationToken,
  }) async* {
    contexts.add(context);
    yield '__LOCAL__';
    yield 'Recorded ${context.steps} steps for ${context.dateKey}';
  }
}

void main() {
  if (Platform.isLinux) {
    test('Skipping Isar tests on Linux CI due to binary linking issues', () {});
    return;
  }

  late ProviderContainer container;
  late CoachNoteRepository coachNoteRepo;
  late Isar isar;
  CoachService? coachOverride;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    coachOverride = null;
    isar = await setUpTestIsar();

    coachNoteRepo = CoachNoteRepository();
    await coachNoteRepo.init(isar);

    final profileRepo = ProfileRepository();
    await profileRepo.init(isar);

    final dailyLogRepo = DailyLogRepository();
    await dailyLogRepo.init(isar);

    final habitRepo = HabitRepository();
    await habitRepo.init(isar);

    final mealRepo = MealRepository();
    await mealRepo.init(isar);

    final workoutRepo = WorkoutRepository();
    await workoutRepo.init(isar);

    final exerciseLogRepo = ExerciseLogRepository();
    await exerciseLogRepo.init(isar);

    container = ProviderContainer(
      overrides: [
        coachServiceProvider.overrideWith(
          (ref) => coachOverride ?? CoachService(aiClient: AiClient()),
        ),
        coachNoteRepoProvider.overrideWithValue(coachNoteRepo),
        profileRepoProvider.overrideWithValue(profileRepo),
        dailyLogRepoProvider.overrideWithValue(dailyLogRepo),
        habitRepoProvider.overrideWithValue(habitRepo),
        mealRepoProvider.overrideWithValue(mealRepo),
        workoutRepoProvider.overrideWithValue(workoutRepo),
        exerciseLogRepoProvider.overrideWithValue(exerciseLogRepo),
        selectedDateProvider.overrideWith((ref) => DateTime(2023, 10, 2)),
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
      ],
    );
  });

  tearDown(() async {
    try {
      container.dispose();
    } catch (_) {
    } finally {
      await tearDownTestIsar(isar);
    }
  });

  test('CoachNoteNotifier uses cache hit', () async {
    final note = CoachNote(
      date: '2023-10-02',
      note: 'Cached Note',
      isAi: false,
    );
    await coachNoteRepo.saveNote(note);

    final value = await container.read(coachNoteProvider.future);
    expect(value.note, 'Cached Note');
  });

  test('CoachNoteNotifier force refresh bypasses cache', () async {
    final note = CoachNote(
      date: '2023-10-02',
      note: 'Cached Note',
      isAi: false,
    );
    await coachNoteRepo.saveNote(note);

    container.listen(coachNoteProvider, (_, _) {});

    await container.read(coachNoteProvider.notifier).fetchNote(force: true);

    final asyncValue = container.read(coachNoteProvider);
    // Templated fallback uses the profile name (empty → "friend"), not "Bodamma"
    expect(asyncValue.value?.note, isNotNull);
    expect(asyncValue.value!.note.isNotEmpty, isTrue);
    expect(asyncValue.value?.note, isNot('Cached Note'));
    expect(asyncValue.value?.isAi, false);
  });

  test('CoachNoteNotifier fallback without API key', () async {
    container.listen(coachNoteProvider, (_, _) {});

    await container.read(coachNoteProvider.notifier).fetchNote(force: true);

    final asyncValue = container.read(coachNoteProvider);
    expect(asyncValue.hasValue, isTrue);
    expect(asyncValue.value?.note, isNotNull);
    expect(asyncValue.value!.note.isNotEmpty, isTrue);
    expect(asyncValue.value?.isAi, false);
  });
  test(
    'new refresh owns visible state and storage despite late old chunks',
    () async {
      await coachNoteRepo.saveNote(
        CoachNote(date: '2023-10-02', note: 'Original', isAi: false),
      );
      final first = StreamController<String>();
      final second = StreamController<String>();
      final controlled = _ControlledCoach([first, second]);
      coachOverride = controlled;
      container.invalidate(coachServiceProvider);
      container.listen(coachNoteProvider, (_, _) {});
      await container.read(coachNoteProvider.future);
      final oldFetch = container
          .read(coachNoteProvider.notifier)
          .fetchNote(force: true);
      first.add('__AI__');
      first.add('Old partial');
      await Future<void>.delayed(Duration.zero);
      final newFetch = container
          .read(coachNoteProvider.notifier)
          .fetchNote(force: true);
      second.add('__AI__');
      second.add('New complete');
      first.add('__LOCAL__');
      first.add('Stale fallback');
      await second.close();
      await newFetch;
      await oldFetch;
      await first.close();
      expect(container.read(coachNoteProvider).value!.note, 'New complete');
      expect(coachNoteRepo.getNote('2023-10-02')!.note, 'New complete');
      final prefs = container.read(sharedPreferencesProvider);
      expect(prefs.getString('coach_note_last_gen_2023-10-02'), isNull);
      expect(
        prefs.getString(
          'coach_note_last_gen_${Uri.encodeComponent(isar.name)}_2023-10-02',
        ),
        isNotNull,
      );
    },
  );

  test('account generation cancels stale coach work before storage', () async {
    await coachNoteRepo.saveNote(
      CoachNote(date: '2023-10-02', note: 'Original', isAi: false),
    );
    final source = StreamController<String>();
    coachOverride = _ControlledCoach([source]);
    container.invalidate(coachServiceProvider);
    container.listen(coachNoteProvider, (_, _) {});
    await container.read(coachNoteProvider.future);
    final pending = container
        .read(coachNoteProvider.notifier)
        .fetchNote(force: true);
    source.add('__AI__');
    source.add('Old account partial');
    await Future<void>.delayed(Duration.zero);
    container.read(accountGenerationProvider.notifier).state++;
    await container.read(coachNoteProvider.future);
    source.add('Old account complete');
    await source.close();
    await pending;
    expect(coachNoteRepo.getNote('2023-10-02')!.note, 'Original');
    expect(container.read(coachNoteProvider).value!.note, 'Original');
  });

  test(
    'hydration and future dates never generate or store coach notes',
    () async {
      final coach = _RecordingCoach();
      coachOverride = coach;
      container.read(accountHydratingProvider.notifier).state = true;
      container.listen(coachNoteProvider, (_, _) {});
      await container.read(coachNoteProvider.future);
      await container.read(coachNoteProvider.notifier).fetchNote(force: true);
      expect(coach.contexts, isEmpty);
      expect(coachNoteRepo.getNote('2023-10-02'), isNull);
      container.read(accountHydratingProvider.notifier).state = false;
      container.read(selectedDateProvider.notifier).state = DateTime(
        2099,
        1,
        1,
      );
      await container.read(coachNoteProvider.future);
      await container.read(coachNoteProvider.notifier).fetchNote(force: true);
      expect(coach.contexts, isEmpty);
      expect(coachNoteRepo.getNote('2099-01-01'), isNull);
    },
  );

  test(
    'changed records mark cached context outdated without automatic AI churn',
    () async {
      final coach = _RecordingCoach();
      coachOverride = coach;
      container.listen(coachNoteProvider, (_, _) {});
      await container.read(coachNoteProvider.future);
      await container.read(coachNoteProvider.notifier).fetchNote(force: true);
      expect(container.read(coachNoteOutdatedProvider), isFalse);
      await container
          .read(dailyLogRepoProvider)
          .saveLog(DailyLog(date: '2023-10-02', steps: 4000));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await container.read(coachNoteProvider.future);
      expect(container.read(coachNoteOutdatedProvider), isTrue);
      await container.read(coachNoteProvider.notifier).fetchNote();
      expect(coach.contexts, hasLength(1));
      await container.read(coachNoteProvider.notifier).fetchNote(force: true);
      expect(coach.contexts, hasLength(2));
      expect(coach.contexts.last.steps, 4000);
      expect(container.read(coachNoteOutdatedProvider), isFalse);
      expect(container.read(coachNoteFeedbackProvider).refreshing, isFalse);
    },
  );

  test(
    'changed inputs cancel partial output and release refresh control',
    () async {
      await coachNoteRepo.saveNote(
        CoachNote(date: '2023-10-02', note: 'Saved earlier', isAi: true),
      );
      final source = StreamController<String>();
      coachOverride = _ControlledCoach([source]);
      container.listen(coachNoteProvider, (_, _) {});
      await container.read(coachNoteProvider.future);
      final pending = container
          .read(coachNoteProvider.notifier)
          .fetchNote(force: true);
      source.add('__AI__');
      source.add('Before new records');
      await Future<void>.delayed(Duration.zero);
      await container
          .read(dailyLogRepoProvider)
          .saveLog(DailyLog(date: '2023-10-02', steps: 25));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await container.read(coachNoteProvider.future);
      source.add(' obsolete conclusion');
      await source.close();
      await pending;
      expect(coachNoteRepo.getNote('2023-10-02')!.note, 'Saved earlier');
      expect(container.read(coachNoteProvider).value!.note, 'Saved earlier');
      expect(container.read(coachNoteFeedbackProvider).refreshing, isFalse);
    },
  );

  test(
    'saved notes arriving from another source update visible history and note',
    () async {
      container.listen(coachNoteProvider, (_, _) {});
      container.listen(coachHistoryProvider, (_, _) {});
      await container.read(coachNoteProvider.future);
      await coachNoteRepo.saveNote(
        CoachNote(date: '2023-10-02', note: 'Synced reflection', isAi: true),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(
        container.read(coachNoteProvider).value!.note,
        'Synced reflection',
      );
      expect(
        container.read(coachHistoryProvider).single.note,
        'Synced reflection',
      );
    },
  );

  test(
    'future imported notes stay hidden and deletion clears selected history',
    () async {
      await coachNoteRepo.saveNote(
        CoachNote(
          date: '2099-01-01',
          note: 'Imported future claim',
          isAi: true,
        ),
      );
      container.read(selectedDateProvider.notifier).state = DateTime(
        2099,
        1,
        1,
      );
      container.listen(coachNoteProvider, (_, _) {});
      container.listen(coachHistoryProvider, (_, _) {});
      expect(
        (await container.read(coachNoteProvider.future)).note,
        isNot(contains('Imported future claim')),
      );
      expect(container.read(coachHistoryProvider), isEmpty);
      container.read(selectedDateProvider.notifier).state = DateTime(
        2023,
        10,
        2,
      );
      await coachNoteRepo.saveNote(
        CoachNote(date: '2023-10-02', note: 'Soon removed', isAi: true),
      );
      await container.read(coachNoteProvider.future);
      final saved = coachNoteRepo.getNote('2023-10-02')!;
      await isar.writeTxn(() => isar.coachNotes.delete(saved.id));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(
        (await container.read(coachNoteProvider.future)).note,
        isNot(contains('Soon removed')),
      );
      expect(container.read(coachHistoryProvider), isEmpty);
    },
  );

  test(
    'failed refresh falls back to current storage after sync replaces its starting cache',
    () async {
      await coachNoteRepo.saveNote(
        CoachNote(date: '2023-10-02', note: 'Old cached note', isAi: true),
      );
      final source = StreamController<String>();
      coachOverride = _ControlledCoach([source]);
      container.listen(coachNoteProvider, (_, _) {});
      await container.read(coachNoteProvider.future);
      final pending = container
          .read(coachNoteProvider.notifier)
          .fetchNote(force: true);
      await coachNoteRepo.saveNote(
        CoachNote(
          date: '2023-10-02',
          note: 'New synchronized note',
          isAi: true,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      source.addError(StateError('Refresh failed'));
      await source.close();
      await pending;
      expect(
        container.read(coachNoteProvider).value!.note,
        'New synchronized note',
      );
      expect(
        container.read(coachNoteFeedbackProvider).message,
        contains('Could not update'),
      );
    },
  );
}
