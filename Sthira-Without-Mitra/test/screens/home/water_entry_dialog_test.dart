import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/habit.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/screens/home/water_entry_dialog.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';
import 'package:trufit_bodamma/widgets/app_bottom_sheet.dart';

class _WaterLog extends DailyLogNotifier {
  _WaterLog({this.initialWater = 2500});
  final int initialWater;
  final writes = <(String, int)>[];
  final clears = <String>[];
  bool fail = false;
  @override
  DailyLog build() => DailyLog(date: '2026-09-19', waterMl: initialWater);
  @override
  Future<void> updateWaterForDate(String date, int value) async {
    writes.add((date, value));
    if (fail) throw StateError('Test save failure');
    state = DailyLog(date: date, waterMl: value);
  }

  @override
  Future<void> clearWaterForDate(String date) async {
    clears.add(date);
    if (fail) throw StateError('Test clear failure');
    state = DailyLog(date: date);
  }
}

Future<_WaterLog> _open(
  WidgetTester tester, {
  List<Habit> habits = const [],
  int water = 2500,
  double width = 390,
  double scale = 1,
  bool dark = false,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final log = _WaterLog(initialWater: water);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dailyLogProvider.overrideWith(() => log),
        habitsProvider.overrideWithValue(habits),
        dateStringProvider.overrideWithValue('2026-09-19'),
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
                builder: (_) => const WaterEntryDialog(),
              ),
              child: const Text('Open water'),
            ),
          ),
        ),
      ),
    ),
  );
  await _tap(tester, find.text('Open water'));
  return log;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Habit _waterHabit({
  String name = 'Drink water',
  GoalDirection direction = GoalDirection.atLeast,
}) => Habit(
  id: 'water',
  name: name,
  icon: 'water',
  target: 3,
  unit: 'L',
  goalDirection: direction,
  initialCreatedAt: DateTime(2020),
);

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'reached water goal fits 320px at 200 percent text in ${dark ? "dark" : "light"} theme',
      (tester) async {
        await _open(
          tester,
          habits: [_waterHabit()],
          water: 3000,
          width: 320,
          scale: 2,
          dark: dark,
        );
        expect(find.text('Goal reached'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('renaming default water habit retains its goal', (tester) async {
    await _open(tester, habits: [_waterHabit(name: 'Hydration')]);
    expect(find.text('Goal: 3000 ml'), findsOneWidget);
  });
  testWidgets('invalid drafts never report an at-most goal as reached', (
    tester,
  ) async {
    await _open(tester, habits: [_waterHabit(direction: GoalDirection.atMost)]);
    expect(find.text('Goal reached'), findsOneWidget);
    for (final draft in ['invalid', '-1', '']) {
      await tester.enterText(find.byType(TextField), draft);
      await tester.pumpAndSettle();
      expect(find.text('Goal reached'), findsNothing);
    }
    await tester.enterText(find.byType(TextField), '0');
    await tester.pumpAndSettle();
    expect(find.text('Goal reached'), findsOneWidget);
  });
  testWidgets(
    'invalid water input never clears a previous entry and preserves the draft',
    (tester) async {
      final log = await _open(tester);
      for (final value in ['invalid', '12.5', '-1', '']) {
        await tester.enterText(find.byType(TextField), value);
        await _tap(tester, find.text('Save Intake'));
        expect(log.writes, isEmpty);
        expect(log.clears, isEmpty);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          value,
        );
        expect(
          find.text(
            'Enter a whole number of ml (0 or more). Use Clear to remove an entry.',
          ),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'zero is recorded and deletion remains an explicit Clear action',
    (tester) async {
      final log = await _open(tester);
      await tester.enterText(find.byType(TextField), '0');
      await _tap(tester, find.text('Save Intake'));
      expect(log.writes, [('2026-09-19', 0)]);
      expect(log.clears, isEmpty);
      expect(find.byType(WaterEntryDialog), findsNothing);
      await _tap(tester, find.text('Open water'));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '0',
      );
      await _tap(tester, find.text('Clear'));
      expect(log.clears, ['2026-09-19']);
      expect(find.byType(WaterEntryDialog), findsNothing);
    },
  );
  for (final action in ['Save Intake', 'Clear']) {
    testWidgets('failed water $action keeps the draft and supports retry', (
      tester,
    ) async {
      final log = await _open(tester);
      log.fail = true;
      await tester.enterText(find.byType(TextField), '3000');
      await _tap(tester, find.text(action));
      expect(
        find.text('Could not save. Your entry is kept. Try again.'),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '3000',
      );
      log.fail = false;
      await _tap(tester, find.text(action));
      expect(action == 'Clear' ? log.clears.length : log.writes.length, 2);
      expect(find.byType(WaterEntryDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
