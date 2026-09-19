import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/daily_meal_log.dart';
import 'package:trufit_bodamma/models/habit.dart';
import 'package:trufit_bodamma/models/meal_plan.dart';
import 'package:trufit_bodamma/models/workout_plan.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/repositories/daily_log_repository.dart';
import 'package:trufit_bodamma/repositories/meal_repository.dart';
import 'package:trufit_bodamma/repositories/habit_repository.dart';
import 'package:trufit_bodamma/repositories/workout_repository.dart';
import 'package:trufit_bodamma/repositories/exercise_log_repository.dart';
import 'package:trufit_bodamma/services/widget_coordinator.dart';

class _Daily extends DailyLogRepository {
  @override
  Stream<void> get watchUpdates => const Stream.empty();
  @override
  DailyLog? getLog(String date) => null;
}

class _Meals extends MealRepository {
  @override
  Stream<void> get watchUpdates => const Stream.empty();
  @override
  MealPlan? getMealPlan(String key) => null;
  @override
  DailyMealLog getDailyLog(String date) => DailyMealLog(
    date: date,
    customSlots: {'lunch': MealSlotLog(totalCalories: 250)},
  );
}

class _Habits extends HabitRepository {
  @override
  Stream<void> get watchUpdates => const Stream.empty();
  @override
  List<Habit> getHabits() => [];
  @override
  HabitCompletion getCompletions(String date) => HabitCompletion(date: date);
}

class _Exercises extends ExerciseLogRepository {
  @override
  Stream<void> get watchUpdates => const Stream.empty();
}

class _Workouts extends WorkoutRepository {
  @override
  WorkoutPlan? getActivePlan({String? preferredKey}) => null;
}

class _Profile extends ProfileNotifier {
  @override
  UserProfile build() => UserProfile();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('home_widget');
  ProviderContainer setup() => ProviderContainer(
    overrides: [
      dailyLogRepoProvider.overrideWithValue(_Daily()),
      mealRepoProvider.overrideWithValue(_Meals()),
      habitRepoProvider.overrideWithValue(_Habits()),
      workoutRepoProvider.overrideWithValue(_Workouts()),
      exerciseLogRepoProvider.overrideWithValue(_Exercises()),
      activeDatabaseProvider.overrideWithValue(null),
      profileProvider.overrideWith(_Profile.new),
      workoutPlanProvider.overrideWithValue(null),
    ],
  );
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );
  test(
    'calorie-only meals count in the widget using logged-slot semantics',
    () async {
      final saved = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'saveWidgetData')
              saved.add((call.arguments as Map)['data'] as String);
            return true;
          });
      final container = setup();
      container.read(widgetCoordinatorProvider);
      await Future<void>.delayed(const Duration(milliseconds: 450));
      expect(saved, hasLength(1));
      expect((jsonDecode(saved.single) as Map)['mealsLogged'], 1);
      expect((jsonDecode(saved.single) as Map)['energy'], 250);
      container.dispose();
    },
  );
  test(
    'account clear is serialized after an already-running old snapshot',
    () async {
      final gate = Completer<void>();
      final started = Completer<void>();
      final saved = <String>[];
      var updates = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'saveWidgetData') {
              final data = (call.arguments as Map)['data'] as String;
              if (saved.isEmpty && data != '{}') {
                started.complete();
                await gate.future;
              }
              saved.add(data);
            }
            if (call.method == 'updateWidget') updates++;
            return true;
          });
      final container = setup();
      container.read(widgetCoordinatorProvider);
      await started.future;
      container.read(accountTransitionProvider.notifier).state = true;
      final suspended = container.read(widgetCoordinatorProvider);
      final clear = suspended.clear();
      gate.complete();
      await clear;
      expect(saved.last, '{}');
      expect(
        updates,
        1,
        reason: 'The obsolete save must never refresh the visible widget',
      );
      container.dispose();
    },
  );
}
