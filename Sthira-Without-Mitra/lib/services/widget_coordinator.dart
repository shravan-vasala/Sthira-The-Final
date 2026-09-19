import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../providers/app_providers.dart';
import '../models/daily_log.dart';
import '../models/user_profile.dart';
import '../models/meal_plan.dart';
import '../models/workout_plan.dart';
import '../models/habit.dart';
import '../utils/workout_completion.dart';
import '../utils/meal_completion.dart';
import '../theme/app_motion.dart';

final widgetCoordinatorProvider = Provider<WidgetCoordinator>((ref) {
  ref.watch(accountGenerationProvider);
  final transitioning = ref.watch(accountTransitionProvider);
  final coordinator = WidgetCoordinator(ref, suspended: transitioning);
  ref.onDispose(() => coordinator.dispose());
  return coordinator;
});

class WidgetCoordinator {
  final Ref _ref;
  Timer? _debounceTimer;
  final List<StreamSubscription> _subs = [];
  Timer? _midnightTimer;
  int _updateGeneration = 0;
  bool _disposed = false;
  // Shared serialization spans coordinator instances during account rebinding.
  static Future<void> _platformWrites = Future.value();
  static int _platformGeneration = 0;
  late final int _ownerGeneration;
  late final int _accountGeneration;

  WidgetCoordinator(this._ref, {bool suspended = false}) {
    _ownerGeneration = ++_platformGeneration;
    _accountGeneration = _ref.read(accountGenerationProvider);
    if (suspended) {
      unawaited(_clearWidgetData());
      return;
    }
    // A suspended account can resume after midnight before Home is mounted.
    _ref.invalidate(clockProvider);
    _initListeners();
    // Schedule an initial update on boot
    _scheduleUpdate();
    _scheduleMidnightRefresh();
  }

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);

    _midnightTimer = Timer(timeUntilMidnight, () {
      _ref.invalidate(clockProvider);
      _scheduleUpdate();
      _scheduleMidnightRefresh(); // Reschedule for the next midnight
    });
  }

  void _initListeners() {
    final dailyLogRepo = _ref.read(dailyLogRepoProvider);
    final mealRepo = _ref.read(mealRepoProvider);
    final habitRepo = _ref.read(habitRepoProvider);
    final exerciseLogRepo = _ref.read(exerciseLogRepoProvider);
    final database = _ref.read(activeDatabaseProvider);
    if (database != null) {
      _subs.add(
        database.habitCompletions.watchLazy().listen((_) => _scheduleUpdate()),
      );
      _subs.add(
        database.userProfiles.watchLazy().listen((_) => _scheduleUpdate()),
      );
      _subs.add(
        database.mealPlans.watchLazy().listen((_) => _scheduleUpdate()),
      );
      _subs.add(
        database.workoutPlans.watchLazy().listen((_) => _scheduleUpdate()),
      );
    }
    _ref.listen(clockProvider, (_, __) => _scheduleUpdate());
    _ref.listen(profileProvider, (_, __) => _scheduleUpdate());
    _ref.listen(workoutPlanProvider, (_, __) => _scheduleUpdate());

    _subs.add(dailyLogRepo.watchUpdates.listen((_) => _scheduleUpdate()));
    _subs.add(mealRepo.watchUpdates.listen((_) => _scheduleUpdate()));
    _subs.add(habitRepo.watchUpdates.listen((_) => _scheduleUpdate()));
    _subs.add(exerciseLogRepo.watchUpdates.listen((_) => _scheduleUpdate()));
  }

  bool get _ownsScope =>
      !_disposed &&
      _ownerGeneration == _platformGeneration &&
      _accountGeneration == _ref.read(accountGenerationProvider);

  Future<void> clear() => _clearWidgetData();

  Future<void> _clearWidgetData() async {
    _debounceTimer?.cancel();
    _updateGeneration++;
    await _write('{}', _updateGeneration);
  }

  Future<void> _write(String snapshot, int generation) {
    _platformWrites = _platformWrites
        .catchError((Object _) {})
        .then((_) async {
          if (!_ownsScope || generation != _updateGeneration) return;
          await HomeWidget.saveWidgetData<String>('widget_data', snapshot);
          if (!_ownsScope || generation != _updateGeneration) return;
          await HomeWidget.updateWidget(androidName: 'TrufitWidgetProvider');
        })
        .catchError((Object error) {
          debugPrint('Widget refresh unavailable: $error');
        });
    return _platformWrites;
  }

  void _scheduleUpdate() {
    if (!_ownsScope) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Motion.deliberate, () {
      _updateGeneration++;
      _pushSnapshot(_updateGeneration);
    });
  }

  Future<void> _pushSnapshot(int generation) async {
    try {
      if (!_ownsScope ||
          generation != _updateGeneration ||
          _ref.read(accountTransitionProvider))
        return;

      final now = _ref.read(clockProvider);
      final todayStr = DateFormat('yyyy-MM-dd').format(now);

      final profile = _ref.read(profileProvider);
      final dailyLogRepo = _ref.read(dailyLogRepoProvider);
      final mealRepo = _ref.read(mealRepoProvider);
      final habitRepo = _ref.read(habitRepoProvider);
      final workoutRepo = _ref.read(workoutRepoProvider);
      final exerciseLogRepo = _ref.read(exerciseLogRepoProvider);

      final log = dailyLogRepo.getLog(todayStr);

      // --- 1. Steps ---
      final steps = log?.steps;

      // Real step goal derived from habit configuration
      final habits = habitRepo.getHabits();
      final stepHabits = habits
          .where(
            (habit) =>
                habit.type == HabitType.autoSteps &&
                isHabitScheduledOn(habit, now),
          )
          .toList();
      final targets = stepHabits.map((habit) => habit.target).toSet();
      final stepGoal =
          stepHabits.isNotEmpty &&
              targets.length == 1 &&
              stepHabits.every(
                (habit) =>
                    habit.goalDirection == GoalDirection.atLeast &&
                    habit.target.isFinite &&
                    habit.target > 0,
              )
          ? targets.single.round()
          : null;

      // --- 2. Meals ---
      final mealLog = mealRepo.getDailyLog(todayStr);

      final int mealsLogged = mealLog.loggedSlotsCount;
      final hasNutrition = mealLog.customSlots.values.any(
        (slot) =>
            slot.items.isNotEmpty ||
            slot.totalCalories > 0 ||
            slot.totalProtein > 0 ||
            slot.totalCarbs > 0 ||
            slot.totalFat > 0,
      );

      final totalMeals = MealCompletion.calculateTotalMeals(profile, mealLog);

      // Nutrition totals
      final totalCal = mealLog.totalCalories;
      final totalProtein = mealLog.totalProtein;

      // --- 3. Habits ---
      // We only care about habits scheduled for today
      final activeHabitsForToday = habits
          .where((habit) => isHabitScheduledOn(habit, now))
          .toList();

      final completions = habitRepo.getCompletions(todayStr);
      final int habitsDone = activeHabitsForToday.where((h) {
        return isHabitCompleted(
          h,
          completions,
          log ?? DailyLog(date: todayStr),
        );
      }).length;
      final int totalHabits = activeHabitsForToday.length;

      // --- 4. Workout ---
      final activePlan = workoutRepo.getActivePlan(
        preferredKey: profile.activeWorkoutPlan,
      );

      bool isRest = false;
      String workoutTitle = "No Plan";
      String workoutStatus = "Tap to view";

      if (log?.workoutCompleted == true) {
        workoutTitle = "Workout Done";
        workoutStatus = "Great job!";
      } else if (log?.workoutStatus == 'skipped') {
        workoutTitle = 'Workout Skipped';
        workoutStatus = 'Logged for today';
      } else if (log?.workoutStatus == 'partial') {
        workoutTitle = 'Workout Started';
        workoutStatus = 'Continue when ready';
      } else if (activePlan != null) {
        final workoutDay = WorkoutCompletion.resolveWorkoutDay(
          activePlan,
          now,
          planStartDate: profile.planStartDate,
        );
        isRest = WorkoutCompletion.isRestDay(workoutDay, now);

        if (isRest) {
          workoutTitle = "Rest Day";
          workoutStatus = "Recovery";
        } else {
          final isDone = WorkoutCompletion.isTrainingDayCompleteWithRepo(
            todayStr,
            workoutDay,
            exerciseLogRepo,
          );
          if (isDone) {
            workoutTitle = "Workout Done";
            workoutStatus = "Great job!";
          } else {
            workoutTitle = workoutDay.label ?? 'Workout';
            workoutStatus = "Pending";
          }
        }
      }

      // Build JSON Snapshot
      final snapshot = {
        'date': todayStr,
        'updatedAt': DateFormat('HH:mm').format(DateTime.now()),

        'steps': steps,
        'stepGoal': stepGoal,

        'mealsLogged': mealsLogged,
        'totalMeals': totalMeals > 0 ? totalMeals : 0,

        'habitsDone': habitsDone,
        'totalHabits': totalHabits,

        'energy': hasNutrition && mealLog.hasCompleteCalories ? totalCal : null,
        'protein': hasNutrition && mealLog.hasCompleteMacros
            ? totalProtein
            : null,

        'isRest': isRest,
        'workoutTitle': workoutTitle,
        'workoutStatus': workoutStatus,
      };

      if (!_ownsScope ||
          generation != _updateGeneration ||
          _ref.read(accountTransitionProvider))
        return;
      await _write(jsonEncode(snapshot), generation);
    } catch (e) {
      debugPrint('WidgetCoordinator error: $e');
    }
  }

  void dispose() {
    _disposed = true;
    if (_ownerGeneration == _platformGeneration) _platformGeneration++;
    _updateGeneration++;
    _debounceTimer?.cancel();
    _midnightTimer?.cancel();
    for (var sub in _subs) {
      sub.cancel();
    }
  }
}
