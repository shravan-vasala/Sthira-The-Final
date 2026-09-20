import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/repositories/daily_log_repository.dart';
import 'package:trufit_bodamma/screens/home/widgets/day_feeling_card.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';

class _DailyRepository extends DailyLogRepository {
  final saves = <({String date, String? feeling, String? note})>[];
  bool fail = false;
  Completer<void>? pauseFirstSave;
  int started = 0;

  @override
  Future<void> updateCheckIn(String date, String? feeling, String? note) async {
    started++;
    if (started == 1) await pauseFirstSave?.future;
    if (fail) throw StateError('Disk unavailable');
    saves.add((date: date, feeling: feeling, note: note));
  }

  @override
  Future<void> removeCheckIn(String date) async {
    if (fail) throw StateError('Disk unavailable');
    saves.add((date: date, feeling: null, note: null));
  }
}

typedef _Day = ({String date, String? feeling, String? note});

Future<void> _show(
  WidgetTester tester,
  _DailyRepository repository,
  ValueNotifier<_Day> day, {
  double textScale = 1,
  bool light = false,
  bool reducedMotion = false,
  ValueNotifier<bool>? visible,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dailyLogRepoProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(DateTime(2026, 9, 19)),
      ],
      child: MaterialApp(
        theme: light ? AppTheme.light : AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reducedMotion,
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ValueListenableBuilder<_Day>(
              valueListenable: day,
              builder: (context, value, child) {
                Widget card() => DayFeelingCard(
                  dateStr: value.date,
                  initialFeeling: value.feeling,
                  initialNote: value.note,
                );
                return visible == null
                    ? card()
                    : ValueListenableBuilder<bool>(
                        valueListenable: visible,
                        builder: (context, shown, _) =>
                            shown ? card() : const SizedBox.shrink(),
                      );
              },
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _typeNote(WidgetTester tester, String note) async {
  await tester.tap(find.byTooltip('Edit reflection note'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), note);
}

void main() {
  testWidgets(
    'switching dates saves a debounced note only to its originating day',
    (tester) async {
      final repository = _DailyRepository();
      final day = ValueNotifier<_Day>((
        date: '2026-09-19',
        feeling: 'good',
        note: '',
      ));
      addTearDown(day.dispose);
      await _show(tester, repository, day);
      await _typeNote(tester, 'A steady Saturday');
      day.value = (date: '2026-09-18', feeling: 'low', note: '');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(repository.saves, [
        (date: '2026-09-19', feeling: 'good', note: 'A steady Saturday'),
      ]);
      expect(find.text('How did this day feel?'), findsOneWidget);
      await tester.tap(find.byTooltip('Edit reflection note'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('account changes cancel pending reflection work', (tester) async {
    final repository = _DailyRepository();
    final day = ValueNotifier<_Day>((
      date: '2026-09-19',
      feeling: 'good',
      note: '',
    ));
    addTearDown(day.dispose);
    await _show(tester, repository, day);
    await _typeNote(tester, 'Belongs to the original account');
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DayFeelingCard)),
    );
    container.read(accountGenerationProvider.notifier).state++;
    await tester.pump(const Duration(seconds: 1));
    expect(repository.saves, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping the selected feeling preserves its queued note', (
    tester,
  ) async {
    final repository = _DailyRepository();
    final day = ValueNotifier<_Day>((
      date: '2026-09-19',
      feeling: 'good',
      note: '',
    ));
    addTearDown(day.dispose);
    await _show(tester, repository, day);
    await _typeNote(tester, 'This should be cleared');
    await tester.tap(find.bySemanticsLabel('Steady, 4 of 5'));
    await tester.pump(const Duration(seconds: 1));
    expect(repository.saves, [
      (date: '2026-09-19', feeling: 'good', note: 'This should be cleared'),
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed note save keeps the draft and offers a working retry', (
    tester,
  ) async {
    final repository = _DailyRepository()..fail = true;
    final day = ValueNotifier<_Day>((
      date: '2026-09-19',
      feeling: 'good',
      note: '',
    ));
    addTearDown(day.dispose);
    await _show(tester, repository, day);
    await _typeNote(tester, 'Keep this reflection');
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Not saved. Your draft is here.'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Keep this reflection',
    );
    repository.fail = false;
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(repository.saves.single.note, 'Keep this reflection');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'leaving the card flushes the last edit before its debounce expires',
    (tester) async {
      final repository = _DailyRepository();
      final day = ValueNotifier<_Day>((
        date: '2026-09-19',
        feeling: 'good',
        note: '',
      ));
      addTearDown(day.dispose);
      await _show(tester, repository, day);
      await _typeNote(tester, 'Save before leaving');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(repository.saves.single.note, 'Save before leaving');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reflection choices have visible labels and fit large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    final repository = _DailyRepository();
    final day = ValueNotifier<_Day>((
      date: '2026-09-19',
      feeling: null,
      note: null,
    ));
    addTearDown(day.dispose);
    await _show(tester, repository, day, textScale: 2);
    expect(find.text('How did today feel?'), findsOneWidget);
    for (final label in [
      'Struggled, 1 of 5',
      'Tired, 2 of 5',
      'Okay, 3 of 5',
      'Steady, 4 of 5',
      'Thriving, 5 of 5',
    ]) {
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('a note can be saved and reopened without choosing a feeling', (
    tester,
  ) async {
    final repository = _DailyRepository();
    final day = ValueNotifier<_Day>((
      date: '2026-09-19',
      feeling: null,
      note: 'A quiet day',
    ));
    addTearDown(day.dispose);
    await _show(tester, repository, day);
    expect(find.text('A quiet day'), findsOneWidget);
    await _typeNote(tester, 'A quiet day with family');
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(repository.saves.single, (
      date: '2026-09-19',
      feeling: null,
      note: 'A quiet day with family',
    ));
    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets(
    'rapid feeling and note edits wait for older writes and keep the latest choice',
    (tester) async {
      final pause = Completer<void>();
      final repository = _DailyRepository()..pauseFirstSave = pause;
      final day = ValueNotifier<_Day>((
        date: '2026-09-19',
        feeling: null,
        note: null,
      ));
      addTearDown(day.dispose);
      await _show(tester, repository, day);
      await tester.tap(find.bySemanticsLabel('Tired, 2 of 5'));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Steady, 4 of 5'));
      await tester.pump();
      await _typeNote(tester, 'Better after a walk');
      await tester.pump(const Duration(seconds: 1));
      expect(repository.started, 1);
      expect(find.text('Saving…'), findsOneWidget);
      pause.complete();
      await tester.pump();
      expect(repository.saves.last, (
        date: '2026-09-19',
        feeling: 'good',
        note: 'Better after a walk',
      ));
      expect(find.text('Saved'), findsOneWidget);
    },
  );

  testWidgets(
    'an account change discards queued writes behind an in-flight save',
    (tester) async {
      final pause = Completer<void>();
      final repository = _DailyRepository()..pauseFirstSave = pause;
      final day = ValueNotifier<_Day>((
        date: '2026-09-19',
        feeling: null,
        note: null,
      ));
      addTearDown(day.dispose);
      await _show(tester, repository, day);
      await tester.tap(find.bySemanticsLabel('Tired, 2 of 5'));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Steady, 4 of 5'));
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(DayFeelingCard)),
      );
      container.read(accountGenerationProvider.notifier).state++;
      await tester.pump();
      pause.complete();
      await tester.pump();
      expect(repository.saves.length, 1);
      expect(repository.saves.single.feeling, 'low');
      expect(find.text('Optional'), findsOneWidget);
      expect(find.text('Saved'), findsNothing);
    },
  );

  testWidgets(
    'clearing a written check-in requires an explicit choice and cancels queued typing',
    (tester) async {
      final repository = _DailyRepository();
      final day = ValueNotifier<_Day>((
        date: '2026-09-19',
        feeling: 'good',
        note: 'Keep me',
      ));
      addTearDown(day.dispose);
      await _show(tester, repository, day);
      await tester.tap(find.text('Clear check-in'));
      await tester.pumpAndSettle();
      expect(find.text('Clear this check-in?'), findsOneWidget);
      await tester.tap(find.text('Keep it'));
      await tester.pumpAndSettle();
      expect(repository.saves, isEmpty);
      expect(find.text('Keep me'), findsOneWidget);
      await tester.tap(find.text('Clear check-in'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(repository.saves.single, (
        date: '2026-09-19',
        feeling: null,
        note: null,
      ));
      expect(find.text('Keep me'), findsNothing);
      expect(find.text('Cleared'), findsNothing);
      expect(find.text('Optional'), findsOneWidget);
    },
  );

  testWidgets('future dates cannot create a daily reflection', (tester) async {
    final repository = _DailyRepository();
    final day = ValueNotifier<_Day>((
      date: '2026-09-20',
      feeling: null,
      note: null,
    ));
    addTearDown(day.dispose);
    await _show(tester, repository, day);
    expect(find.text('Check in when this day arrives.'), findsOneWidget);
    expect(find.bySemanticsLabel('Steady, 4 of 5'), findsNothing);
    expect(find.byTooltip('Edit reflection note'), findsNothing);
    expect(repository.saves, isEmpty);
  });

  testWidgets('a feeling can be chosen with the keyboard', (tester) async {
    final repository = _DailyRepository();
    final day = ValueNotifier<_Day>((
      date: '2026-09-19',
      feeling: null,
      note: null,
    ));
    addTearDown(day.dispose);
    await _show(tester, repository, day);
    final feeling = find.bySemanticsLabel('Okay, 3 of 5');
    final ink = find
        .descendant(of: feeling, matching: find.byType(InkWell))
        .first;
    final focus = find.descendant(of: ink, matching: find.byType(Focus)).first;
    Focus.of(
      tester.element(
        find
            .descendant(of: focus, matching: find.byType(GestureDetector))
            .first,
      ),
    ).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(repository.saves.single.feeling, 'okay');
  });

  testWidgets(
    'light theme and large text preserve labels, note and clear controls without animation',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _DailyRepository();
      final day = ValueNotifier<_Day>((
        date: '2026-09-19',
        feeling: 'good',
        note: 'A note worth remembering',
      ));
      addTearDown(day.dispose);
      await _show(
        tester,
        repository,
        day,
        textScale: 2,
        light: true,
        reducedMotion: true,
      );
      for (final label in [
        'Struggled',
        'Tired',
        'Okay',
        'Steady',
        'Thriving',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      await _typeNote(tester, 'A note worth remembering');
      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byType(DayFeelingCard),
          matching: find.byType(AnimatedSize),
        ),
        findsNothing,
      );
      for (final bar in tester.widgetList<AnimatedContainer>(
        find.descendant(
          of: find.byType(DayFeelingCard),
          matching: find.byType(AnimatedContainer),
        ),
      )) {
        expect(bar.duration, Duration.zero);
      }
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets('a remote update cannot replace a failed local draft', (
    tester,
  ) async {
    final repository = _DailyRepository()..fail = true;
    final day = ValueNotifier<_Day>((
      date: '2026-09-19',
      feeling: 'good',
      note: 'Earlier note',
    ));
    addTearDown(day.dispose);
    await _show(tester, repository, day);
    await _typeNote(tester, 'Keep the local draft');
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    day.value = (date: '2026-09-19', feeling: 'low', note: 'Remote update');
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Keep the local draft',
    );
    repository.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(repository.saves.single, (
      date: '2026-09-19',
      feeling: 'good',
      note: 'Keep the local draft',
    ));
  });

  testWidgets(
    'a focused clean editor accepts synced corrections before another choice',
    (tester) async {
      final repository = _DailyRepository();
      final day = ValueNotifier<_Day>((
        date: '2026-09-19',
        feeling: 'good',
        note: 'Earlier',
      ));
      addTearDown(day.dispose);
      await _show(tester, repository, day);
      await tester.tap(find.byTooltip('Edit reflection note'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextField));
      await tester.pump();
      day.value = (
        date: '2026-09-19',
        feeling: 'low',
        note: 'Updated elsewhere',
      );
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Updated elsewhere',
      );
      await tester.tap(find.bySemanticsLabel('Okay, 3 of 5'));
      await tester.pump();
      expect(repository.saves.single, (
        date: '2026-09-19',
        feeling: 'okay',
        note: 'Updated elsewhere',
      ));
    },
  );

  testWidgets(
    'a failed originating-day save is recoverable after navigating back',
    (tester) async {
      final repository = _DailyRepository()..fail = true;
      final day = ValueNotifier<_Day>((
        date: '2026-09-19',
        feeling: 'good',
        note: 'Earlier',
      ));
      addTearDown(day.dispose);
      await _show(tester, repository, day);
      await _typeNote(tester, 'Keep after navigation');
      day.value = (date: '2026-09-18', feeling: null, note: null);
      await tester.pump();
      await tester.pump();
      expect(find.text('Keep after navigation'), findsNothing);
      day.value = (date: '2026-09-19', feeling: 'good', note: 'Earlier');
      await tester.pumpAndSettle();
      expect(find.text('Keep after navigation'), findsOneWidget);
      expect(find.text('Not saved. Your draft is here.'), findsOneWidget);
      repository.fail = false;
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(repository.saves.single.note, 'Keep after navigation');
      expect(find.text('Saved'), findsOneWidget);
    },
  );

  testWidgets('leaving and reopening the page retains a failed account draft', (
    tester,
  ) async {
    final repository = _DailyRepository()..fail = true;
    final visible = ValueNotifier(true);
    final day = ValueNotifier<_Day>((
      date: '2026-09-19',
      feeling: null,
      note: null,
    ));
    addTearDown(day.dispose);
    addTearDown(visible.dispose);
    await _show(tester, repository, day, visible: visible);
    await _typeNote(tester, 'Remember after reopening');
    visible.value = false;
    await tester.pump();
    await tester.pump();
    visible.value = true;
    await tester.pumpAndSettle();
    expect(find.text('Remember after reopening'), findsOneWidget);
    expect(find.text('Not saved. Your draft is here.'), findsOneWidget);
    repository.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(repository.saves.single.note, 'Remember after reopening');
  });

  testWidgets(
    'reopening while a save is running preserves ordering between editors',
    (tester) async {
      final pause = Completer<void>();
      final repository = _DailyRepository()..pauseFirstSave = pause;
      final visible = ValueNotifier(true);
      final day = ValueNotifier<_Day>((
        date: '2026-09-19',
        feeling: null,
        note: null,
      ));
      addTearDown(day.dispose);
      addTearDown(visible.dispose);
      await _show(tester, repository, day, visible: visible);
      await tester.tap(find.bySemanticsLabel('Tired, 2 of 5'));
      await tester.pump();
      visible.value = false;
      await tester.pump();
      visible.value = true;
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Steady, 4 of 5'));
      await tester.pump();
      expect(repository.started, 1);
      pause.complete();
      await tester.pump();
      expect(repository.saves.map((s) => s.feeling), ['low', 'good']);
      expect(find.text('Saved'), findsOneWidget);
    },
  );

  testWidgets('failed drafts cannot reappear in a different account', (
    tester,
  ) async {
    final repository = _DailyRepository()..fail = true;
    final visible = ValueNotifier(true);
    final day = ValueNotifier<_Day>((
      date: '2026-09-19',
      feeling: null,
      note: null,
    ));
    addTearDown(day.dispose);
    addTearDown(visible.dispose);
    await _show(tester, repository, day, visible: visible);
    await _typeNote(tester, 'Account A only');
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DayFeelingCard)),
    );
    container.read(accountGenerationProvider.notifier).state++;
    await tester.pump();
    visible.value = false;
    await tester.pump();
    visible.value = true;
    await tester.pumpAndSettle();
    expect(find.text('Account A only'), findsNothing);
    expect(find.text('Not saved. Your draft is here.'), findsNothing);
    expect(find.text('Optional'), findsOneWidget);
  });
}
