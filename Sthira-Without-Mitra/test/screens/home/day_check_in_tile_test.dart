import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/repositories/daily_log_repository.dart';
import 'package:trufit_bodamma/screens/home/widgets/day_feeling_card.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';
import 'package:trufit_bodamma/widgets/app_bottom_sheet.dart';

const _today = '2026-09-19';
final _now = DateTime(2026, 9, 19, 10);
typedef _Save = ({String date, String? feeling, String? note});

class _DailyRepository extends DailyLogRepository {
  final logs = <String, DailyLog>{};
  final saves = <_Save>[];
  final _changes = StreamController<DailyLog>.broadcast(sync: true);
  Completer<void>? pauseFirstSave;
  Completer<void>? pauseSecondSave;
  bool fail = false;
  int started = 0;

  void publish(DailyLog log) {
    logs[log.date] = log;
    _changes.add(log);
  }

  @override
  DailyLog? getLog(String date) => logs[date];

  @override
  DailyLog getOrCreate(String date) => logs[date] ?? DailyLog(date: date);

  @override
  Stream<DailyLog?> watchLog(String date) =>
      _changes.stream.where((log) => log.date == date);

  @override
  Future<void> updateCheckIn(String date, String? feeling, String? note) async {
    started++;
    if (started == 1) await pauseFirstSave?.future;
    if (started == 2) await pauseSecondSave?.future;
    if (fail) throw StateError('Disk unavailable');
    final log = DailyLog(
      date: date,
      dayFeeling: feeling,
      dayNote: note,
      checkInUpdatedAt: _now,
    );
    saves.add((date: date, feeling: feeling, note: note));
    logs[date] = log;
    _changes.add(log);
  }

  @override
  Future<void> removeCheckIn(String date) => updateCheckIn(date, null, null);

  @override
  void dispose() {
    _changes.close();
    super.dispose();
  }
}

Future<ProviderContainer> _show(
  WidgetTester tester,
  _DailyRepository repository, {
  DateTime? selected,
  double width = 390,
  double textScale = 1,
  double keyboardInset = 0,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(repository.dispose);
  final container = ProviderContainer(
    overrides: [
      dailyLogRepoProvider.overrideWithValue(repository),
      clockProvider.overrideWithValue(_now),
      selectedDateProvider.overrideWith((ref) => selected ?? _now),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            viewInsets: EdgeInsets.only(bottom: keyboardInset),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: DayCheckInTile(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Daily check-in'));
  await tester.pumpAndSettle();
  expect(find.byType(AppSheet), findsOneWidget);
}

Future<void> _close(WidgetTester tester) async {
  final done = find.text('Done');
  await tester.ensureVisible(done);
  await tester.tap(done);
  // Route removal must finish before asserting the editor's disposal flush.
  await tester.pumpAndSettle();
  expect(find.byType(AppSheet), findsNothing);
}

void main() {
  testWidgets('the compact tile keeps a saved note private until opened', (
    tester,
  ) async {
    final repository = _DailyRepository();
    repository.logs[_today] = DailyLog(
      date: _today,
      dayFeeling: 'good',
      dayNote: 'Only for me',
    );
    await _show(tester, repository);

    expect(find.text('Daily check-in'), findsOneWidget);
    expect(find.text('Steady \u00b7 Note added'), findsOneWidget);
    expect(find.text('Only for me'), findsNothing);
    expect(find.byType(TextField), findsNothing);

    await _open(tester);
    expect(find.text('Sat, 19 Sep 2026'), findsOneWidget);
    expect(find.text('How did today feel?'), findsOneWidget);
    for (final label in ['Struggled', 'Tired', 'Okay', 'Steady', 'Thriving']) {
      expect(find.text(label), findsOneWidget);
    }
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'Only for me');
    expect(field.autofocus, isFalse);
    await _close(tester);
    expect(find.text('Only for me'), findsNothing);
    expect(repository.saves, isEmpty);
  });

  testWidgets('closing before debounce saves the note and updates the tile', (
    tester,
  ) async {
    final repository = _DailyRepository();
    await _show(tester, repository);
    expect(find.text('How did today feel?'), findsOneWidget);
    await _open(tester);
    await tester.enterText(find.byType(TextField), 'A quiet evening');
    expect(repository.started, 0);

    await _close(tester);

    expect(repository.saves, [
      (date: _today, feeling: null, note: 'A quiet evening'),
    ]);
    expect(find.text('Note added'), findsOneWidget);
    expect(find.text('A quiet evening'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a delayed failure after closing remains visible and retryable', (
    tester,
  ) async {
    final pause = Completer<void>();
    final repository = _DailyRepository()
      ..pauseFirstSave = pause
      ..fail = true;
    await _show(tester, repository);
    await _open(tester);
    await tester.enterText(find.byType(TextField), 'Keep the unsaved note');
    await _close(tester);
    expect(repository.started, 1);
    expect(find.text('Saving\u2026'), findsOneWidget);

    pause.complete();
    await tester.pumpAndSettle();
    expect(find.text('Not saved. Tap to retry.'), findsOneWidget);
    expect(find.text('Keep the unsaved note'), findsNothing);

    await _open(tester);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Keep the unsaved note',
    );
    final retryPause = Completer<void>();
    repository.fail = false;
    repository.pauseSecondSave = retryPause;
    final retry = find.text('Retry');
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    await _close(tester);
    expect(repository.started, 2);
    expect(find.text('Saving\u2026'), findsOneWidget);
    expect(find.text('Not saved. Tap to retry.'), findsNothing);
    retryPause.complete();
    await tester.pumpAndSettle();

    expect(repository.saves.single.note, 'Keep the unsaved note');
    expect(find.text('Note added'), findsOneWidget);
    expect(find.text('Not saved. Tap to retry.'), findsNothing);
  });

  testWidgets('an open editor stays on its date when Home selection changes', (
    tester,
  ) async {
    final repository = _DailyRepository();
    final container = await _show(tester, repository);
    await _open(tester);
    await tester.enterText(find.byType(TextField), 'Saturday reflection');
    container.read(selectedDateProvider.notifier).state = DateTime(2026, 9, 18);
    await tester.pump();

    expect(find.text('Sat, 19 Sep 2026'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Saturday reflection',
    );
    await _close(tester);
    expect(repository.saves.single.date, _today);
    expect(repository.getLog('2026-09-18'), isNull);
    expect(find.text('How did this day feel?'), findsOneWidget);

    container.read(selectedDateProvider.notifier).state = _now;
    await tester.pumpAndSettle();
    expect(find.text('Note added'), findsOneWidget);
  });

  testWidgets(
    'synced corrections reach the captured date after Home selection changes',
    (tester) async {
      final repository = _DailyRepository();
      repository.logs[_today] = DailyLog(
        date: _today,
        dayFeeling: 'good',
        dayNote: 'Earlier note',
      );
      final container = await _show(tester, repository);
      await _open(tester);
      container.read(selectedDateProvider.notifier).state = DateTime(
        2026,
        9,
        18,
      );
      await tester.pumpAndSettle();

      repository.publish(
        DailyLog(
          date: _today,
          dayFeeling: 'low',
          dayNote: 'Updated on another device',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sat, 19 Sep 2026'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Updated on another device',
      );
      expect(repository.saves, isEmpty);

      final choice = find.text('Okay');
      await tester.ensureVisible(choice);
      await tester.tap(choice);
      await tester.pumpAndSettle();
      await _close(tester);
      expect(repository.saves.single, (
        date: _today,
        feeling: 'okay',
        note: 'Updated on another device',
      ));
      expect(repository.getLog('2026-09-18'), isNull);
      expect(find.text('How did this day feel?'), findsOneWidget);
    },
  );

  testWidgets(
    'an account transition closes the clear confirmation and editor without deleting',
    (tester) async {
      final repository = _DailyRepository();
      repository.logs[_today] = DailyLog(
        date: _today,
        dayFeeling: 'good',
        dayNote: 'Keep the original reflection',
      );
      final container = await _show(tester, repository);
      await _open(tester);
      final clear = find.text('Clear check-in');
      await tester.ensureVisible(clear);
      await tester.tap(clear);
      await tester.pumpAndSettle();
      expect(find.text('Clear this check-in?'), findsOneWidget);

      container.read(accountTransitionProvider.notifier).state = true;
      await tester.pumpAndSettle();

      expect(find.text('Clear this check-in?'), findsNothing);
      expect(find.byType(AppSheet), findsNothing);
      expect(repository.saves, isEmpty);
      expect(
        repository.getLog(_today)!.dayNote,
        'Keep the original reflection',
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final transition in [true, false]) {
    testWidgets(
      '${transition ? 'starting an account transition' : 'changing account generation'} closes the editor and cancels a draft',
      (tester) async {
        final repository = _DailyRepository();
        final container = await _show(tester, repository);
        await _open(tester);
        await tester.enterText(find.byType(TextField), 'Original account only');
        if (transition) {
          container.read(accountTransitionProvider.notifier).state = true;
        } else {
          container.read(accountGenerationProvider.notifier).state++;
        }
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(AppSheet), findsNothing);
        expect(find.text('Original account only'), findsNothing);
        expect(repository.saves, isEmpty);
        if (transition) {
          container.read(accountGenerationProvider.notifier).state++;
          container.read(accountTransitionProvider.notifier).state = false;
          await tester.pumpAndSettle();
        }
        await _open(tester);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          isEmpty,
        );
        await _close(tester);
        expect(repository.saves, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('future days cannot open or save a check-in', (tester) async {
    final repository = _DailyRepository();
    await _show(tester, repository, selected: DateTime(2026, 9, 20));
    expect(find.text('Check in when this day arrives.'), findsOneWidget);
    await tester.tap(find.text('Daily check-in'));
    await tester.pumpAndSettle();

    expect(find.byType(AppSheet), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(repository.saves, isEmpty);
  });

  testWidgets('clearing returns the tile to the ordinary empty prompt', (
    tester,
  ) async {
    final repository = _DailyRepository();
    repository.logs[_today] = DailyLog(
      date: _today,
      dayFeeling: 'good',
      dayNote: 'A note to clear',
    );
    await _show(tester, repository);
    await _open(tester);
    final clear = find.text('Clear check-in');
    await tester.ensureVisible(clear);
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(find.text('Clear this check-in?'), findsOneWidget);
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    await _close(tester);

    expect(repository.saves.single, (date: _today, feeling: null, note: null));
    expect(find.text('How did today feel?'), findsOneWidget);
    expect(find.text('Cleared'), findsNothing);
    expect(find.text('Note added'), findsNothing);
  });

  testWidgets('large text and the keyboard keep all sheet controls reachable', (
    tester,
  ) async {
    final repository = _DailyRepository();
    await _show(
      tester,
      repository,
      width: 320,
      textScale: 2,
      keyboardInset: 280,
    );
    await _open(tester);
    expect(tester.takeException(), isNull);

    for (final label in ['Struggled', 'Tired', 'Okay', 'Steady', 'Thriving']) {
      final choice = find.text(label);
      await tester.ensureVisible(choice);
      await tester.pumpAndSettle();
      expect(choice.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Large text reflection');
    // Text entry schedules a post-frame caret reveal. Let it finish before
    // scrolling to another control, as a user would after typing.
    await tester.pumpAndSettle();
    final done = find.text('Done');
    await tester.ensureVisible(done);
    await tester.pumpAndSettle();
    expect(done.hitTestable(), findsOneWidget);
    await tester.tap(done);
    await tester.pumpAndSettle();

    expect(repository.saves.single.note, 'Large text reflection');
    expect(find.text('Note added'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
