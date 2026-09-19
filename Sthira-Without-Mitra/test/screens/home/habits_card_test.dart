import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/habit.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/screens/home/sleep_entry_dialog.dart';
import 'package:trufit_bodamma/screens/home/water_entry_dialog.dart';
import 'package:trufit_bodamma/screens/home/widgets/habits_card.dart';
import 'package:trufit_bodamma/screens/home/widgets/timer_entry_dialog.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';

class _Completions extends HabitCompletionsNotifier {
  _Completions(this.initial);
  final HabitCompletion initial;
  final progressWrites = <(String, double)>[];
  final overrideWrites = <(String, String?)>[];
  final toggles = <String>[];

  @override
  HabitCompletion build() => initial;

  @override
  Future<void> updateProgress(String habitId, double progress) async {
    progressWrites.add((habitId, progress));
    state = state.updateProgress(habitId, progress);
  }

  @override
  Future<void> setOverride(String habitId, String? value) async {
    overrideWrites.add((habitId, value));
    state = state.setOverride(habitId, value);
  }

  @override
  Future<void> toggle(String habitId) async {
    toggles.add(habitId);
    state = state.toggleCheckbox(habitId);
  }
}

class _Daily extends DailyLogNotifier {
  @override
  DailyLog build() => DailyLog(date: '2026-09-19');
}

Habit _habit({
  String id = 'read',
  String name = 'Read a few pages before bedtime',
  HabitType type = HabitType.counter,
}) => Habit(
  id: id,
  name: name,
  icon: 'check',
  type: type,
  target: 8,
  step: 1,
  unit: 'pages',
  initialCreatedAt: DateTime(2020),
);

Future<_Completions> _show(
  WidgetTester tester, {
  required Habit habit,
  double width = 390,
  double scale = 1,
  bool dark = false,
  bool future = false,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final date = future ? '2026-09-20' : '2026-09-19';
  final completions = _Completions(
    HabitCompletion(date: date, completions: {habit.id: 2.0}),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        habitsProvider.overrideWithValue([habit]),
        habitCompletionsProvider.overrideWith(() => completions),
        habitStreakProvider(habit.id).overrideWithValue(123),
        dailyLogProvider.overrideWith(_Daily.new),
        dateStringProvider.overrideWithValue(date),
        clockProvider.overrideWithValue(DateTime(2026, 9, 19)),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const Scaffold(body: SingleChildScrollView(child: HabitsCard())),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return completions;
}

void main() {
  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'counter metadata and separate controls fit 320px scale=$scale dark=$dark',
        (tester) async {
          final habit = _habit();
          final completions = await _show(
            tester,
            habit: habit,
            width: 320,
            scale: scale,
            dark: dark,
          );
          expect(find.text(habit.name), findsOneWidget);
          expect(find.text('2 / 8 pages'), findsOneWidget);
          expect(find.text('123 Day Streak'), findsOneWidget);
          expect(tester.takeException(), isNull);
          final increase = find.byTooltip('Increase ${habit.name}');
          final decrease = find.byTooltip('Decrease ${habit.name}');
          expect(tester.getSize(increase), const Size(48, 48));
          expect(tester.getSize(decrease), const Size(48, 48));
          expect(
            tester.getTopLeft(increase).dy,
            greaterThan(tester.getBottomLeft(find.text('123 Day Streak')).dy),
          );
          await tester.ensureVisible(increase);
          await tester.tap(increase);
          await tester.pumpAndSettle();
          expect(find.text('3 / 8 pages'), findsOneWidget);
          await tester.tap(decrease);
          await tester.pumpAndSettle();
          expect(completions.progressWrites, [('read', 3.0), ('read', 2.0)]);
          expect(completions.overrideWrites, isEmpty);
          expect(completions.toggles, isEmpty);
          expect(find.byType(SnackBar), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final width in [390.0, 430.0]) {
    testWidgets('counter controls remain inline when there is room at $width', (
      tester,
    ) async {
      final habit = _habit(name: 'Read');
      await _show(tester, habit: habit, width: width);
      expect(
        tester.getCenter(find.byTooltip('Increase Read')).dy,
        inInclusiveRange(
          tester.getTopLeft(find.text('Read')).dy,
          tester.getBottomLeft(find.text('123 Day Streak')).dy,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('future habits block taps, long presses and swipes', (
    tester,
  ) async {
    final habit = _habit();
    final completions = await _show(
      tester,
      habit: habit,
      width: 320,
      scale: 2,
      future: true,
    );
    expect(find.byTooltip('Increase ${habit.name}'), findsNothing);
    expect(find.byTooltip('Decrease ${habit.name}'), findsNothing);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    await tester.tap(find.text(habit.name));
    await tester.longPress(find.text(habit.name));
    await tester.drag(find.byKey(ValueKey(habit.id)), const Offset(240, 0));
    await tester.pumpAndSettle();
    expect(completions.progressWrites, isEmpty);
    expect(completions.overrideWrites, isEmpty);
    expect(completions.toggles, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('counter swipe and undo keep working after controls wrap', (
    tester,
  ) async {
    final completions = await _show(tester, habit: _habit(), width: 320);
    await tester.drag(find.byKey(const ValueKey('read')), const Offset(220, 0));
    await tester.pumpAndSettle();
    expect(find.text('3 / 8 pages'), findsOneWidget);
    await tester.tap(find.text('UNDO'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 8 pages'), findsOneWidget);
    expect(completions.progressWrites, [('read', 3.0), ('read', 2.0)]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('checkbox row still toggles directly with undo', (tester) async {
    final habit = _habit(name: 'Read', type: HabitType.checkbox);
    final completions = await _show(tester, habit: habit, width: 320, scale: 2);
    await tester.tap(find.text('Read'));
    await tester.pumpAndSettle();
    expect(completions.toggles, ['read']);
    expect(find.text('Completed Read'), findsOneWidget);
    await tester.tap(find.text('UNDO'));
    await tester.pumpAndSettle();
    expect(completions.toggles, ['read', 'read']);
    expect(tester.takeException(), isNull);
  });

  for (final (id, type, editor) in [
    ('water', HabitType.checkbox, WaterEntryDialog),
    ('sleep', HabitType.autoSleep, SleepEntryDialog),
    ('timer', HabitType.timer, TimerEntryDialog),
  ]) {
    testWidgets('$id row still opens its direct editor', (tester) async {
      final habit = _habit(id: id, name: 'My $id habit', type: type);
      final completions = await _show(tester, habit: habit);
      await tester.tap(find.text(habit.name));
      await tester.pumpAndSettle();
      expect(find.byType(editor), findsOneWidget);
      expect(completions.progressWrites, isEmpty);
      expect(completions.overrideWrites, isEmpty);
      expect(completions.toggles, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }
}
