import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/habit.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/repositories/habit_repository.dart';
import 'package:trufit_bodamma/screens/profile/manage_habits_screen.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';
import 'package:trufit_bodamma/widgets/app_navigation_bar.dart';
import 'package:trufit_bodamma/widgets/rest_timer_bar.dart';

class _Habits extends HabitRepository {
  _Habits(this.items);
  final List<Habit> items;
  final List<Habit> saved = [];
  @override
  List<Habit> getHabits() => List.of(items);
  @override
  Future<void> saveHabit(Habit habit) async {
    saved.add(habit);
    final index = items.indexWhere((item) => item.id == habit.id);
    if (index < 0) {
      items.add(habit);
    } else {
      items[index] = habit;
    }
  }
}

void main() {
  final created = DateTime.utc(2024, 2, 3, 10, 15);
  Habit limit() => Habit(
    id: 'limit',
    name: 'Evening limit',
    icon: 'timer',
    type: HabitType.counter,
    target: 60,
    unit: 'min',
    step: 5,
    goalDirection: GoalDirection.atMost,
    initialCreatedAt: created,
    activeDays: [1, 3],
    order: 4,
  );

  Future<ProviderContainer> app(
    WidgetTester tester,
    _Habits repository, {
    bool withDock = false,
  }) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        habitRepoProvider.overrideWithValue(repository),
        activeDatabaseProvider.overrideWithValue(null),
        selectedDateProvider.overrideWith((ref) => DateTime(2026, 9, 19)),
        clockProvider.overrideWithValue(DateTime(2026, 9, 19)),
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
              textScaler: const TextScaler.linear(2),
              padding: withDock
                  ? const EdgeInsets.only(bottom: 34)
                  : MediaQuery.paddingOf(context),
              viewPadding: withDock
                  ? const EdgeInsets.only(bottom: 34)
                  : MediaQuery.viewPaddingOf(context),
            ),
            child: child!,
          ),
          home: withDock
              ? Scaffold(
                  extendBody: true,
                  body: const ManageHabitsScreen(),
                  bottomNavigationBar: AppNavigationDock(
                    currentIndex: 0,
                    onItemSelected: (_) {},
                    restTimer: RestTimerBar(
                      remainingSeconds: 75,
                      isPaused: false,
                      onAddSeconds: (_) {},
                      onTogglePause: () {},
                      onClose: () {},
                    ),
                  ),
                )
              : const ManageHabitsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> edit(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'management includes paused and off-day habits at 320px and 200 percent',
    (tester) async {
      final repository = _Habits([
        Habit(
          id: 'paused',
          name: 'Paused habit',
          icon: 'check',
          target: 1,
          initialCreatedAt: created,
          activeDays: [],
        ),
        Habit(
          id: 'monday',
          name: 'Monday habit',
          icon: 'check',
          target: 1,
          initialCreatedAt: created,
          activeDays: [1],
        ),
      ]);
      final container = await app(tester, repository);
      expect(container.read(habitsProvider), isEmpty);
      expect(find.text('Paused habit'), findsOneWidget);
      expect(find.text('Monday habit'), findsOneWidget);
      expect(find.byType(PopupMenuButton<String>), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'renaming preserves creation date and at-most goal with wrapping weekdays',
    (tester) async {
      final repository = _Habits([limit()]);
      await app(tester, repository);
      await edit(tester);
      final name = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Habit name',
      );
      await tester.enterText(name, 'Evening screen limit');
      final chips = find.byType(FilterChip);
      expect(chips, findsNWidgets(7));
      final selected = tester
          .widgetList<FilterChip>(chips)
          .map((chip) => chip.selected)
          .toList();
      expect(selected, [true, false, true, false, false, false, false]);
      for (var i = 0; i < 7; i++) {
        await tester.ensureVisible(chips.at(i));
        await tester.pump();
        final rect = tester.getRect(chips.at(i));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(320));
      }
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final saved = repository.saved.single;
      expect(saved.name, 'Evening screen limit');
      expect(saved.createdAt, created);
      expect(saved.goalDirection, GoalDirection.atMost);
      expect(saved.activeDays, [1, 3]);
      expect(saved.target, 60);
      expect(saved.order, 4);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('open habit editor cannot save into a changed account', (
    tester,
  ) async {
    final repository = _Habits([limit()]);
    final container = await app(tester, repository);
    await edit(tester);
    container.read(accountGenerationProvider.notifier).state++;
    await tester.pump();
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repository.saved, isEmpty);
    expect(find.text('Edit Habit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'last habit menu clears active timer, navigation and Add Habit at 320/200%',
    (tester) async {
      final repository = _Habits([
        for (var i = 0; i < 20; i++)
          Habit(
            id: 'habit-$i',
            name: i == 19 ? 'Last habit' : 'Habit $i',
            icon: 'check',
            target: 1,
            initialCreatedAt: created,
          ),
      ]);
      await app(tester, repository, withDock: true);
      await tester.dragFrom(const Offset(160, 200), const Offset(0, -10000));
      await tester.pumpAndSettle();
      expect(find.text('Last habit'), findsOneWidget);
      final lastMenu = find.byType(PopupMenuButton<String>).last;
      final add = tester.getRect(find.byType(FloatingActionButton));
      final timer = tester.getRect(find.byType(RestTimerBar));
      expect(tester.getRect(lastMenu).bottom, lessThan(add.top));
      expect(add.bottom, lessThan(timer.top));
      await tester.tap(lastMenu);
      await tester.pumpAndSettle();
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
