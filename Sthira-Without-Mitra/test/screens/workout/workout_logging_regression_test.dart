import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trufit_bodamma/models/exercise_log.dart';
import 'package:trufit_bodamma/models/exercise_pr.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/models/workout_plan.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/repositories/exercise_log_repository.dart';
import 'package:trufit_bodamma/repositories/profile_repository.dart';
import 'package:trufit_bodamma/screens/workout/log_data_dialog.dart';
import 'package:trufit_bodamma/screens/workout/workout_screen.dart';
import 'package:trufit_bodamma/screens/workout/widgets/exercise_card.dart';
import 'package:trufit_bodamma/screens/workout/youtube_player_screen.dart';
import 'package:trufit_bodamma/screens/workout/exercise_progress_screen.dart';
import 'package:trufit_bodamma/utils/exercise_log_save.dart';
import 'package:trufit_bodamma/widgets/app_bottom_sheet.dart';

class _Logs extends ExerciseLogRepository {
  final logs = <String, ExerciseLog>{};
  final prs = <String, ExercisePr>{};
  bool fail = false;
  int deletes = 0;
  @override
  ExerciseLog? getLog(String date, String id) => logs['${date}_$id'];
  @override
  bool hasLog(String date, String id) =>
      getLog(date, id)?.sets.isNotEmpty ?? false;
  @override
  List<ExerciseLog> getLogsForExercise(String name) =>
      logs.values.where((log) => log.exerciseName == name).toList();
  @override
  ExerciseLog? getLastLog(String name, {String? beforeDate}) {
    final previous = getLogsForExercise(name)
        .where(
          (log) => beforeDate == null || log.date.compareTo(beforeDate) < 0,
        )
        .toList();
    return previous.isEmpty ? null : previous.last;
  }

  @override
  ExercisePr? getPr(String name) => prs[name];
  @override
  Future<void> saveLog(ExerciseLog log) async {
    if (fail) throw Exception('Disk unavailable');
    logs[log.key] = log;
  }

  @override
  Future<void> savePr(ExercisePr pr) async {
    prs[pr.exerciseName] = pr;
  }

  @override
  Future<void> deleteLog(String date, String id) async {
    deletes++;
    logs.remove('${date}_$id');
  }
}

class _Profiles extends ProfileRepository {
  _Profiles(this.profile);
  UserProfile profile;
  @override
  UserProfile getProfile() => profile;
  @override
  Stream<UserProfile?> watchProfile() => const Stream.empty();
  @override
  Future<void> saveProfile(UserProfile value) async {
    profile = value;
  }
}

void main() {
  final date = DateTime(2026, 9, 19);
  late _Logs logs;
  late ProviderContainer container;
  setUp(() {
    logs = _Logs();
    container = ProviderContainer(
      overrides: [
        exerciseLogRepoProvider.overrideWithValue(logs),
        profileRepoProvider.overrideWithValue(_Profiles(UserProfile())),
        activeDatabaseProvider.overrideWithValue(null),
        selectedDateProvider.overrideWith((ref) => date),
        clockProvider.overrideWith((ref) => date),
      ],
    );
  });
  tearDown(() => container.dispose());
  Exercise exercise({List<String> reps = const ['10', '12'], double? weight}) =>
      Exercise(name: 'Push up', reps: reps, weightKg: weight)
        ..instanceId = 'push-1';

  Future<void> openSheet(
    WidgetTester tester,
    Exercise ex, {
    double scale = 1,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showAppBottomSheet(
                  context: context,
                  builder: (_) => LogDataDialog(exercise: ex),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Save Log'));
    await tester.tap(find.text('Save Log'));
    await tester.pumpAndSettle();
  }

  test(
    'planned logging preserves individual sets and never turns time into reps',
    () {
      expect(plannedRepTargets(exercise(reps: ['10', '10'])), [10, 10]);
      expect(plannedRepTargets(exercise(reps: ['12', '8-10', '6'])), [
        12,
        10,
        6,
      ]);
      for (final target in ['20s', '30 sec', '5 min', '2 km', 'AMRAP']) {
        expect(plannedRepTargets(exercise(reps: [target])), isEmpty);
      }
      expect(supportsRepLogging(exercise(reps: ['20s'])), isFalse);
      expect(
        plannedRepTargets(Exercise(reps: ['20'], durationSeconds: 20)),
        isEmpty,
      );
    },
  );

  testWidgets(
    'timed sets save and reopen as seconds without fake reps or strength PRs',
    (tester) async {
      final timed = Exercise(name: 'Cooldown', reps: ['1'], durationSeconds: 20)
        ..instanceId = 'cooldown';
      expect(plannedDurationTargets(timed), [20]);
      expect(plannedDurationTargets(Exercise(reps: ['2 min', '30 s'])), [
        120,
        30,
      ]);
      expect(plannedDurationTargets(Exercise(reps: ['2 km'])), isEmpty);
      await openSheet(tester, timed);
      expect(find.text('Seconds'), findsOneWidget);
      expect(find.byKey(const ValueKey('weight-0')), findsNothing);
      await tester.enterText(find.byKey(const ValueKey('duration-0')), '25');
      await save(tester);
      final recorded = logs.getLog('2026-09-19', 'cooldown')!;
      expect(recorded.sets.single.durationSeconds, 25);
      expect(recorded.sets.single.reps, isNull);
      expect(logs.prs, isEmpty);
      await openSheet(tester, timed);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('duration-0')))
            .controller!
            .text,
        '25',
      );
    },
  );

  testWidgets('bodyweight and original per-set targets save without deleting', (
    tester,
  ) async {
    await openSheet(tester, exercise());
    await save(tester);
    final log = logs.getLog('2026-09-19', 'push-1')!;
    expect(log.sets.map((set) => set.reps), [10, 12]);
    expect(log.sets.map((set) => set.weight), [0, 0]);
    expect(logs.deletes, 0);
  });

  testWidgets('unchanged pound values preserve exact original kilograms', (
    tester,
  ) async {
    await container
        .read(profileProvider.notifier)
        .updateProfile(UserProfile(useKg: false));
    await openSheet(tester, exercise(reps: ['10'], weight: 12.5));
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('weight-0')))
          .controller!
          .text,
      '27.56',
    );
    await save(tester);
    expect(logs.getLog('2026-09-19', 'push-1')!.sets.single.weight, 12.5);
  });

  testWidgets('editing a partial log preserves original set numbers', (
    tester,
  ) async {
    logs.logs['2026-09-19_push-1'] = ExerciseLog(
      date: '2026-09-19',
      instanceId: 'push-1',
      exerciseName: 'Push up',
      sets: [SetLog(setNumber: 3, reps: 8, weight: 0)],
    );
    await openSheet(tester, exercise());
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('reps-0')))
          .controller!
          .text,
      '',
    );
    await save(tester);
    expect(logs.getLog('2026-09-19', 'push-1')!.sets.single.setNumber, 3);
    expect(logs.getLog('2026-09-19', 'push-1')!.sets.single.reps, 8);
  });

  testWidgets('invalid weight keeps the existing log and draft visible', (
    tester,
  ) async {
    logs.logs['2026-09-19_push-1'] = ExerciseLog(
      date: '2026-09-19',
      instanceId: 'push-1',
      exerciseName: 'Push up',
      sets: [SetLog(setNumber: 1, reps: 10, weight: 12.5)],
    );
    await openSheet(tester, exercise(reps: ['10']));
    await tester.enterText(find.byKey(const ValueKey('weight-0')), '-3');
    await save(tester);
    expect(find.text('Enter 0 or a positive weight'), findsOneWidget);
    expect(logs.getLog('2026-09-19', 'push-1')!.sets.single.weight, 12.5);
    expect(logs.deletes, 0);
  });

  testWidgets('sheet saves to the date it opened even after calendar changes', (
    tester,
  ) async {
    await openSheet(tester, exercise());
    container.read(selectedDateProvider.notifier).state = DateTime(2026, 9, 18);
    await save(tester);
    expect(logs.getLog('2026-09-19', 'push-1'), isNotNull);
    expect(logs.getLog('2026-09-18', 'push-1'), isNull);
  });

  testWidgets('sheet cannot write after account generation changes', (
    tester,
  ) async {
    await openSheet(tester, exercise());
    container.read(accountGenerationProvider.notifier).state++;
    await save(tester);
    expect(logs.logs, isEmpty);
    expect(find.textContaining('Your account changed'), findsOneWidget);
  });

  testWidgets('failed saves retain values and can retry', (tester) async {
    await openSheet(tester, exercise(reps: ['10'], weight: 12.5));
    logs.fail = true;
    await save(tester);
    expect(find.textContaining('Your entries are still here'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('weight-0')))
          .controller!
          .text,
      '12.5',
    );
    logs.fail = false;
    await save(tester);
    expect(logs.getLog('2026-09-19', 'push-1')!.sets.single.weight, 12.5);
  });

  testWidgets('as-planned button is disabled on future dates', (tester) async {
    container.read(selectedDateProvider.notifier).state = date.add(
      const Duration(days: 1),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: ExerciseCard(exercise: exercise(), dayId: 'saturday'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('As planned'));
    await tester.pumpAndSettle();
    expect(logs.logs, isEmpty);
    await tester.tap(find.text('Adjust'));
    await tester.pumpAndSettle();
    expect(find.byType(LogDataDialog), findsNothing);
  });

  testWidgets('as-planned card saves 10 reps for both sets', (tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: ExerciseCard(
              exercise: exercise(reps: ['10', '10']),
              dayId: 'saturday',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('As planned'));
    await tester.pumpAndSettle();
    expect(logs.getLog('2026-09-19', 'push-1')!.sets.map((set) => set.reps), [
      10,
      10,
    ]);
  });

  testWidgets('numeric editor fits 320px at 200 percent text with keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await openSheet(tester, exercise(reps: ['10'], weight: 12.5), scale: 2);
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    expect(tester.takeException(), isNull);
    final field = find.byKey(const ValueKey('weight-0'));
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    expect(tester.getSize(field).width, greaterThan(220));
    expect(tester.widget<TextFormField>(field).controller!.text, '12.5');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'unsupported distance target can finish without fabricated rep logs',
    (tester) async {
      String? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await showWorkoutFinishConfirmation(
                    context: context,
                    date: '2026-09-19',
                    completed: 0,
                    total: 2,
                    hasUnsupportedTargets: true,
                  );
                },
                child: const Text('Finish'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          'Distance or unclear targets are not stored as repetitions.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Finish without rep logs'));
      await tester.pumpAndSettle();
      expect(result, 'partial');
      expect(logs.logs, isEmpty);
    },
  );

  testWidgets('missing video ID renders retry without constructing player', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: YoutubePlayerScreen(
          videoId: '',
          title: 'Squat',
          subtitle: '',
          reps: '10',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Invalid or missing video ID.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('malformed exercise history does not crash date rendering', (
    tester,
  ) async {
    logs.logs['bad'] = ExerciseLog(
      date: 'not-a-date',
      instanceId: 'push-1',
      exerciseName: 'Push up',
      sets: [SetLog(setNumber: 1, reps: 10, weight: 12.5)],
    );
    container.dispose();
    container = ProviderContainer(
      overrides: [
        exerciseLogRepoProvider.overrideWithValue(logs),
        profileRepoProvider.overrideWithValue(_Profiles(UserProfile())),
        activeDatabaseProvider.overrideWithValue(null),
        workoutPlanProvider.overrideWithValue(null),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: ExerciseProgressScreen(exerciseName: 'Push up'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No valid logs to display'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
