import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/habit.dart';
import 'package:trufit_bodamma/models/exercise_log.dart';
import 'package:trufit_bodamma/models/workout_plan.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/repositories/daily_log_repository.dart';
import 'package:trufit_bodamma/repositories/meal_repository.dart';
import 'package:trufit_bodamma/repositories/habit_repository.dart';
import 'package:trufit_bodamma/repositories/exercise_log_repository.dart';
import 'package:trufit_bodamma/screens/home/widgets/past_day_summary_sheet.dart';
import 'package:trufit_bodamma/theme/app_theme.dart';

class _Daily extends DailyLogRepository {
  final values = <String, DailyLog>{};
  final changes = StreamController<DailyLog?>.broadcast();
  final watchedDates = <String>[];
  @override
  DailyLog? getLog(String date) => values[date];
  @override
  DailyLog getOrCreate(String date) => getLog(date) ?? DailyLog(date: date);
  @override
  Stream<DailyLog?> watchLog(String date) {
    watchedDates.add(date);
    return changes.stream.where((log) => log?.date == date);
  }
}

class _Meals extends MealRepository {
  final values = <String, DailyMealLog>{};
  @override
  DailyMealLog getDailyLog(String date) =>
      values[date] ?? DailyMealLog(date: date);
  @override
  Stream<DailyMealLog?> watchDailyLog(String date) => const Stream.empty();
}

class _Habits extends HabitRepository {
  final List<Habit> habits;
  final values = <String, HabitCompletion>{};
  final changes = StreamController<HabitCompletion?>.broadcast();
  final watchedDates = <String>[];
  _Habits(this.habits);
  @override
  List<Habit> getHabits() => habits;
  @override
  HabitCompletion getCompletions(String date) =>
      values[date] ?? HabitCompletion(date: date);
  @override
  Stream<void> get watchUpdates => const Stream.empty();
  @override
  Stream<HabitCompletion?> watchCompletions(String date) {
    watchedDates.add(date);
    return changes.stream.where((value) => value?.date == date);
  }
}

class _Exercise extends ExerciseLogRepository {
  @override
  bool hasLog(String date, String instanceId) => false;
  @override
  List<ExerciseLog> getLogsForDate(String date) => [];
}

class _Profile extends ProfileNotifier {
  final UserProfile value;
  _Profile(this.value);
  @override
  UserProfile build() => value;
}

Habit _habit(String id, String name, {List<int>? days, DateTime? createdAt}) =>
    Habit(
      id: id,
      name: name,
      icon: 'check',
      target: 1,
      activeDays: days,
      initialCreatedAt: createdAt ?? DateTime(2026, 1, 1),
    );

Future<void> _show(
  WidgetTester tester, {
  required _Daily daily,
  required _Habits habits,
  _Meals? meals,
  UserProfile? profile,
  WorkoutPlan? workoutPlan,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dailyLogRepoProvider.overrideWithValue(daily),
        habitRepoProvider.overrideWithValue(habits),
        mealRepoProvider.overrideWithValue(meals ?? _Meals()),
        exerciseLogRepoProvider.overrideWithValue(_Exercise()),
        exerciseRecordsUpdateProvider.overrideWith(
          (ref) => const Stream.empty(),
        ),
        workoutPlanProvider.overrideWithValue(workoutPlan),
        mealPlanProvider.overrideWithValue(null),
        profileProvider.overrideWith(
          () => _Profile(profile ?? UserProfile(customMealSlots: [])),
        ),
        selectedDateProvider.overrideWith((ref) => DateTime(2026, 9, 19)),
        clockProvider.overrideWithValue(DateTime(2026, 9, 19)),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: PastDaySummarySheet(date: DateTime(2026, 9, 18)),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('No plan and no records are not presented as a rest day', (
    tester,
  ) async {
    final daily = _Daily();
    final habits = _Habits([]);
    addTearDown(daily.changes.close);
    addTearDown(habits.changes.close);
    await _show(tester, daily: daily, habits: habits);
    expect(find.text('No entries logged'), findsOneWidget);
    expect(find.text('No workout plan selected'), findsOneWidget);
    expect(find.text('No goals scheduled'), findsOneWidget);
    expect(find.text('Rest day'), findsNothing);
    expect(find.text('Recovery day'), findsNothing);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'A saved reflection is an entry without claiming goals were met',
    (tester) async {
      final daily = _Daily();
      daily.values['2026-09-18'] = DailyLog(
        date: '2026-09-18',
        dayFeeling: 'veryLow',
        dayNote: 'A difficult day',
      );
      final habits = _Habits([_habit('walk', 'Walk')]);
      addTearDown(daily.changes.close);
      addTearDown(habits.changes.close);
      await _show(tester, daily: daily, habits: habits);
      expect(find.text('Entries recorded'), findsOneWidget);
      expect(find.text('No entries logged'), findsNothing);
      expect(find.text('Goals complete'), findsNothing);
      expect(find.text('Not recorded: Walk'), findsOneWidget);
      expect(find.textContaining('Missed:'), findsNothing);
      expect(find.text('0 of 1 things completed'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Habit history distinguishes an observed miss from no check-in', (
    tester,
  ) async {
    final daily = _Daily();
    final habits = _Habits([_habit('read', 'Read'), _habit('walk', 'Walk')]);
    habits.values['2026-09-18'] = HabitCompletion(
      date: '2026-09-18',
      completions: {'read': false},
    );
    addTearDown(daily.changes.close);
    addTearDown(habits.changes.close);
    await _show(tester, daily: daily, habits: habits);
    expect(find.text('Not met: Read\nNot recorded: Walk'), findsOneWidget);
    expect(find.text('Entries recorded'), findsOneWidget);
    expect(find.text('0 of 2 things completed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('An explicitly scheduled rest day remains a recovery day', (
    tester,
  ) async {
    final daily = _Daily();
    final habits = _Habits([]);
    addTearDown(daily.changes.close);
    addTearDown(habits.changes.close);
    await _show(
      tester,
      daily: daily,
      habits: habits,
      workoutPlan: WorkoutPlan(
        planName: 'Recovery',
        days: [WorkoutDay(dayId: 'friday', label: 'Rest', sections: [])],
      ),
    );
    expect(find.text('Rest day'), findsOneWidget);
    expect(find.text('Recovery day'), findsOneWidget);
    expect(find.text('No workout plan selected'), findsNothing);
    expect(find.text('No goals scheduled'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'past summaries count only habits scheduled and created for that day',
    (tester) async {
      final daily = _Daily();
      final habits = _Habits([
        _habit('friday', 'Friday walk', days: [DateTime.friday]),
        _habit('monday', 'Monday yoga', days: [DateTime.monday]),
        _habit('new', 'New habit', createdAt: DateTime(2026, 9, 19)),
        _habit('daily', 'Read a page'),
      ]);
      habits.values['2026-09-18'] = HabitCompletion(
        date: '2026-09-18',
        completions: {'daily': true},
        overrides: {'friday': 'notDone'},
      );
      addTearDown(daily.changes.close);
      addTearDown(habits.changes.close);
      await _show(tester, daily: daily, habits: habits);
      expect(find.text('Habits (1/2)'), findsOneWidget);
      expect(find.text('Not met: Friday walk'), findsOneWidget);
      expect(find.textContaining('Monday yoga'), findsNothing);
      expect(find.textContaining('New habit'), findsNothing);
      expect(find.text('1 of 2 things completed'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'an open summary refreshes the long-pressed date without changing selection',
    (tester) async {
      final daily = _Daily();
      final habits = _Habits([_habit('friday', 'Friday walk')]);
      addTearDown(daily.changes.close);
      addTearDown(habits.changes.close);
      await _show(tester, daily: daily, habits: habits);
      expect(daily.watchedDates, ['2026-09-18']);
      expect(habits.watchedDates, ['2026-09-18']);
      expect(find.text('Habits (0/1)'), findsOneWidget);
      habits.changes.add(
        HabitCompletion(date: '2026-09-18', overrides: {'friday': 'done'}),
      );
      daily.changes.add(DailyLog(date: '2026-09-18', dayFeeling: 'great'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Habits (1/1)'), findsOneWidget);
      expect(find.text('Thriving'), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(PastDaySummarySheet)),
      );
      expect(container.read(selectedDateProvider), DateTime(2026, 9, 19));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'empty scheduled habits are described honestly and long meals fit narrow large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final daily = _Daily();
      final habits = _Habits([
        _habit('monday', 'Monday yoga', days: [DateTime.monday]),
      ]);
      final meals = _Meals();
      meals.values['2026-09-18'] = DailyMealLog(
        date: '2026-09-18',
        customSlots: {
          for (var i = 0; i < 8; i++)
            'slot$i': MealSlotLog(totalCalories: 1250, emoji: 'lunch'),
        },
      );
      addTearDown(daily.changes.close);
      addTearDown(habits.changes.close);
      await _show(
        tester,
        daily: daily,
        habits: habits,
        meals: meals,
        profile: UserProfile(),
        textScale: 2,
      );
      expect(find.text('No habits scheduled'), findsOneWidget);
      expect(find.text('All habits completed!'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -800),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
