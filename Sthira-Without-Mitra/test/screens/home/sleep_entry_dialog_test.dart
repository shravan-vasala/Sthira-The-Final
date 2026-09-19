import 'dart:ui' show SemanticsAction, Tristate;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/habit.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/screens/home/sleep_entry_dialog.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';
import 'package:trufit_bodamma/widgets/app_bottom_sheet.dart';

const _date = '2026-09-19';

class _SleepLog extends DailyLogNotifier {
  _SleepLog({this.sleep});
  final double? sleep;
  double? savedSleep;
  @override
  DailyLog build() => DailyLog(date: _date, sleepHours: sleep);
  @override
  Future<void> updateSleepForDate(
    String date,
    double value, {
    String? source,
  }) async {
    savedSleep = value;
  }
}

Future<void> _open(
  WidgetTester tester,
  _SleepLog log, {
  double width = 390,
  double scale = 1,
  bool dark = false,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dailyLogProvider.overrideWith(() => log),
        habitsProvider.overrideWithValue([]),
        dateStringProvider.overrideWithValue(_date),
        clockProvider.overrideWithValue(DateTime(2026, 9, 19)),
      ],
      child: MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAppBottomSheet<void>(
                context: context,
                builder: (_) => const SleepEntryDialog(),
              ),
              child: const Text('Open sleep'),
            ),
          ),
        ),
      ),
    ),
  );
  await _tap(tester, find.text('Open sleep'));
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _chooseTime(
  WidgetTester tester,
  String label,
  TimeOfDay time,
) async {
  await _tap(tester, find.text(label));
  Navigator.of(tester.element(find.byType(TimePickerDialog))).pop(time);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'time calculation preserves exact minutes and does not round up an eight-hour goal',
    (tester) async {
      final log = _SleepLog();
      await _open(tester, log);
      await _chooseTime(
        tester,
        'Bedtime',
        const TimeOfDay(hour: 22, minute: 2),
      );
      await _chooseTime(tester, 'Wake up', const TimeOfDay(hour: 6, minute: 0));
      expect(find.text('7h 58m'), findsOneWidget);
      await _tap(tester, find.text('Save Sleep'));
      expect(log.savedSleep, closeTo(478 / 60, .000001));
      expect(
        isHabitCompleted(
          Habit.defaults.firstWhere((h) => h.id == 'sleep'),
          HabitCompletion(date: _date),
          DailyLog(date: _date, sleepHours: log.savedSleep),
        ),
        isFalse,
      );
    },
  );

  testWidgets('unchanged precise sleep reading survives reopening and saving', (
    tester,
  ) async {
    final log = _SleepLog(sleep: 478 / 60);
    await _open(tester, log);
    expect(find.text('7h 58m'), findsOneWidget);
    await _tap(tester, find.text('Save Sleep'));
    expect(log.savedSleep, closeTo(478 / 60, .000001));
  });

  testWidgets(
    'manual editing replaces the precise draft and clears stale calculated times',
    (tester) async {
      final log = _SleepLog(sleep: 478 / 60);
      await _open(tester, log);
      await _chooseTime(
        tester,
        'Bedtime',
        const TimeOfDay(hour: 22, minute: 2),
      );
      await _chooseTime(tester, 'Wake up', const TimeOfDay(hour: 6, minute: 0));
      await tester.enterText(find.byType(TextField), '6.5');
      await tester.pumpAndSettle();
      expect(find.text('6h 30m'), findsOneWidget);
      expect(find.text('--:--'), findsNWidgets(2));
      await _tap(tester, find.text('Save Sleep'));
      expect(log.savedSleep, 6.5);
    },
  );

  for (final dark in [false, true]) {
    testWidgets(
      'selected sleep times fit 320px at 200 percent text in ${dark ? "dark" : "light"} theme',
      (tester) async {
        await _open(tester, _SleepLog(), width: 320, scale: 2, dark: dark);
        await _chooseTime(
          tester,
          'Bedtime',
          const TimeOfDay(hour: 22, minute: 2),
        );
        await _chooseTime(
          tester,
          'Wake up',
          const TimeOfDay(hour: 6, minute: 0),
        );
        expect(find.text('7h 58m'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'both time controls expose button semantics and keyboard activation',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _open(tester, _SleepLog());
        for (final entry in [
          ('Bedtime', 'sleep-time-bedtime'),
          ('Wake up', 'sleep-time-wake'),
        ]) {
          final control = find.byKey(ValueKey(entry.$2));
          await tester.ensureVisible(control);
          await tester.pumpAndSettle();
          final data = tester.getSemantics(control).getSemanticsData();
          expect(data.flagsCollection.isButton, isTrue);
          expect(data.flagsCollection.isEnabled, Tristate.isTrue);
          expect(data.hasAction(SemanticsAction.tap), isTrue);
          expect(data.label, contains(entry.$1));
          Focus.of(tester.element(find.text(entry.$1))).requestFocus();
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          expect(find.byType(TimePickerDialog), findsOneWidget);
          Navigator.of(tester.element(find.byType(TimePickerDialog))).pop();
          await tester.pumpAndSettle();
        }
      } finally {
        semantics.dispose();
      }
    },
  );
}
