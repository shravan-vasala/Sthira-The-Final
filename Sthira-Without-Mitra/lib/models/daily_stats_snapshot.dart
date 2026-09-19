import 'package:intl/intl.dart';
import '../models/daily_log.dart';
import '../models/daily_meal_log.dart';
import '../models/habit.dart';
import '../models/meal_plan.dart';
import '../models/user_profile.dart';
import '../models/workout_plan.dart';
import '../repositories/daily_log_repository.dart';
import '../utils/workout_completion.dart';
import '../utils/meal_completion.dart';

class DailyStatsSnapshot {
  final int habitsDone;
  final int habitsTotal;
  final double habitRate;

  final int workoutsDone;
  final int workoutsTotal;
  final bool isRestDay;
  final int daysSinceLastWorkout;

  final int mealsLogged;
  final int mealsTotal;

  final double weight;
  final String weightTrend;

  final int steps;
  final double sleepHours;
  final int totalCalories;

  const DailyStatsSnapshot({
    required this.habitsDone,
    required this.habitsTotal,
    required this.habitRate,
    required this.workoutsDone,
    required this.workoutsTotal,
    required this.isRestDay,
    required this.daysSinceLastWorkout,
    required this.mealsLogged,
    required this.mealsTotal,
    required this.weight,
    required this.weightTrend,
    required this.steps,
    required this.sleepHours,
    required this.totalCalories,
  });

  static DailyStatsSnapshot compute({
    required DateTime date,
    required String dateStr,
    required List<Habit> habits,
    required HabitCompletion habitCompletions,
    required DailyLog dailyLog,
    required WorkoutPlan? workoutPlan,
    required bool Function(String dateStr, String exerciseName) hasLog,
    required MealPlan? mealPlan,
    required DailyMealLog mealLog,
    required double targetWeight,
    required DailyLogRepository dailyLogRepo,
    required UserProfile profile,
  }) {
    // 1. Habits
    int habitsDone = 0;
    for (final h in habits) {
      if (isHabitCompleted(h, habitCompletions, dailyLog)) habitsDone++;
    }
    final double habitRate = habits.isEmpty ? 0.0 : habitsDone / habits.length;

    // 2. Workouts
    int workoutsDone = 0;
    int workoutsTotal = 0;
    bool isRestDay = false;
    int daysSinceLastWorkout = 0;

    if (workoutPlan != null && WorkoutCompletion.hasSchedule(workoutPlan)) {
      final day = WorkoutCompletion.resolveWorkoutDay(
        workoutPlan,
        date,
        planStartDate: profile.planStartDate,
      );
      isRestDay = WorkoutCompletion.isRestDay(day, date);
      workoutsTotal = isRestDay
          ? 1
          : day.sections
                .where((section) => section.exercises.isNotEmpty)
                .length;

      if (isRestDay) {
        if (WorkoutCompletion.isDayWorkoutDone(
          date: dateStr,
          day: day,
          dateTime: date,
          hasLog: hasLog,
          dailyLog: dailyLog,
        )) {
          workoutsDone = 1;
        }

        DateTime checkDate = date.subtract(const Duration(days: 1));
        while (daysSinceLastWorkout < 14) {
          final checkStr = DateFormat('yyyy-MM-dd').format(checkDate);
          final cLog = dailyLogRepo.getLog(checkStr);
          if (cLog != null && cLog.workoutCompleted) break;
          daysSinceLastWorkout++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        }
      } else {
        if (workoutsTotal > 0) {
          workoutsDone = WorkoutCompletion.completedSectionCount(
            dateStr,
            day,
            hasLog,
          );
        }
      }
    } else {
      isRestDay = true;
      workoutsTotal = 1;
      if (dailyLog.workoutCompleted) workoutsDone = 1;
    }

    // 3. Meals
    final int mealsLogged = mealLog.loggedSlotsCount;
    final int mealsTotal = MealCompletion.calculateTotalMeals(profile, mealLog);

    // 4. Weight Trend
    String weightTrend = 'stable';
    final todayWeight = dailyLog.weight ?? targetWeight;
    final weekAgo = date.subtract(const Duration(days: 7));
    final weekAgoStr = DateFormat('yyyy-MM-dd').format(weekAgo);
    final weekAgoLog = dailyLogRepo.getLog(weekAgoStr);
    final pastWeight = weekAgoLog?.weight ?? targetWeight;
    if (todayWeight > pastWeight + 0.5) {
      weightTrend = 'up';
    } else if (todayWeight < pastWeight - 0.5) {
      weightTrend = 'down';
    }

    return DailyStatsSnapshot(
      habitsDone: habitsDone,
      habitsTotal: habits.length,
      habitRate: habitRate,
      workoutsDone: workoutsDone,
      workoutsTotal: workoutsTotal,
      isRestDay: isRestDay,
      daysSinceLastWorkout: daysSinceLastWorkout,
      mealsLogged: mealsLogged,
      mealsTotal: mealsTotal,
      weight: todayWeight,
      weightTrend: weightTrend,
      steps: dailyLog.steps ?? 0,
      sleepHours: dailyLog.sleepHours ?? 0.0,
      totalCalories: mealLog.totalCalories,
    );
  }
}
