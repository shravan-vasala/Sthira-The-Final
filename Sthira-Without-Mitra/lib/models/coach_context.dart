import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'daily_log.dart';
import 'daily_meal_log.dart';
import 'habit.dart';
import 'user_profile.dart';
import 'workout_plan.dart';
import '../utils/workout_completion.dart';

/// Only observed data and explicitly scheduled work are coaching evidence.
class CoachContext {
  final DateTime date;
  final DateTime today;
  final String userName;
  final String coachName;
  final int? steps;
  final double? sleep;
  final int? calories;
  final bool caloriesComplete;
  final int habitsDone;
  final int habitsTotal;
  final int habitsRecorded;
  final int previousHabitsRecorded;
  final int previousHabitsTotal;
  final double? yesterdayHabitRate;
  final int sectionsDone;
  final int sectionsTotal;
  final bool hasWorkoutPlan;
  final bool isRestDay;
  final String? workoutStatus;
  final int? daysSinceLastWorkout;
  final String weightComparison;
  final bool hasEntries;

  const CoachContext({
    required this.date,
    required this.today,
    this.userName = '',
    this.coachName = '',
    this.steps,
    this.sleep,
    this.calories,
    this.caloriesComplete = true,
    this.habitsDone = 0,
    this.habitsTotal = 0,
    this.habitsRecorded = 0,
    this.previousHabitsRecorded = 0,
    this.previousHabitsTotal = 0,
    this.yesterdayHabitRate,
    this.sectionsDone = 0,
    this.sectionsTotal = 0,
    this.hasWorkoutPlan = false,
    this.isRestDay = false,
    this.workoutStatus,
    this.daysSinceLastWorkout,
    this.weightComparison = 'Not enough recorded measurements',
    this.hasEntries = false,
  });

  bool get isToday => _sameDay(date, today);
  bool get isFuture => DateTime(
    date.year,
    date.month,
    date.day,
  ).isAfter(DateTime(today.year, today.month, today.day));
  String get dateKey => DateFormat('yyyy-MM-dd').format(date);
  String get coachLabel =>
      coachName.trim().isEmpty ? 'Coach' : coachName.trim();
  String get name => userName.trim().isEmpty ? 'friend' : userName.trim();

  String get evidence =>
      '''
Selected date: $dateKey (${isToday ? 'today' : 'historical day'})
Steps: ${steps ?? 'not recorded'}
Sleep hours: ${sleep ?? 'not recorded'}
Calories recorded: ${calories ?? 'not recorded'}${calories != null && !caloriesComplete ? ' (partial; some logged foods have unknown calories)' : ''}
Recorded habit goals met on this date: $habitsDone / $habitsTotal scheduled; records available for $habitsRecorded habits (missing checks are unknown)
Previous calendar day's scheduled habit rate: ${yesterdayHabitRate == null ? 'unknown or incomplete' : '${(yesterdayHabitRate! * 100).round()}%'}; $previousHabitsRecorded / $previousHabitsTotal scheduled habits have records
Workout schedule: ${!hasWorkoutPlan
          ? 'no plan selected'
          : isRestDay
          ? 'scheduled rest'
          : 'training'}
Completed workout sections: $sectionsDone / $sectionsTotal (sections, not separate workouts)
Recorded workout status: ${workoutStatus ?? 'not recorded'}
Days since last recorded workout activity (within 14 days): ${daysSinceLastWorkout ?? 'unknown'}
Weight comparison: $weightComparison
''';

  String get fingerprint => sha256
      .convert(
        utf8.encode(jsonEncode([userName, coachName, evidence, hasEntries])),
      )
      .toString();

  String fingerprintForNote(String note) =>
      sha256.convert(utf8.encode('$fingerprint|$note')).toString();

  factory CoachContext.fromRecords({
    required DateTime date,
    required DateTime today,
    required UserProfile profile,
    required DailyLog log,
    required DailyMealLog meals,
    required List<Habit> habits,
    required HabitCompletion completions,
    required HabitCompletion previousCompletions,
    required List<DailyLog> history,
    required Set<String> exerciseDates,
    WorkoutPlan? workoutPlan,
    required bool Function(String date, String instanceId) hasLog,
  }) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    final previous = DateTime(date.year, date.month, date.day - 1);
    final previousKey = DateFormat('yyyy-MM-dd').format(previous);
    final scheduled = habits.where((h) => isHabitScheduledOn(h, date)).toList();
    final previousHabits = habits
        .where((h) => isHabitScheduledOn(h, previous))
        .toList();
    final previousLog =
        history.where((l) => l.date == previousKey).firstOrNull ??
        DailyLog(date: previousKey);
    final previousDone = previousHabits
        .where((h) => isHabitCompleted(h, previousCompletions, previousLog))
        .length;
    final previousRecorded = previousHabits
        .where((h) => hasHabitRecord(h, previousCompletions, previousLog))
        .length;
    final hasPlan = WorkoutCompletion.hasSchedule(workoutPlan);
    final day = hasPlan
        ? WorkoutCompletion.resolveWorkoutDay(
            workoutPlan!,
            date,
            planStartDate: profile.planStartDate,
          )
        : null;
    final rest = day != null && WorkoutCompletion.isRestDay(day, date);
    int? lastWorkout;
    for (var offset = 0; offset <= 14; offset++) {
      final earlier = DateTime(date.year, date.month, date.day - offset);
      final earlierKey = DateFormat('yyyy-MM-dd').format(earlier);
      final daily = earlierKey == key
          ? log
          : history.where((l) => l.date == earlierKey).firstOrNull;
      if (exerciseDates.contains(earlierKey) ||
          daily?.workoutStatus == 'completed' ||
          daily?.workoutStatus == 'partial') {
        lastWorkout = offset;
        break;
      }
    }
    var weightComparison = 'Not enough recorded measurements';
    final weekStart = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(date.year, date.month, date.day - 7));
    final earlierWeights =
        history
            .where(
              (l) =>
                  l.weight != null &&
                  l.date.compareTo(weekStart) >= 0 &&
                  l.date.compareTo(key) < 0,
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    if (log.weight != null && earlierWeights.isNotEmpty) {
      final earlier = earlierWeights.first;
      final change = log.weight! - earlier.weight!;
      weightComparison =
          '${earlier.weight} kg on ${earlier.date} to ${log.weight} kg on $key '
          '(${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} kg); no judgment about whether this is desirable';
    }
    return CoachContext(
      date: date,
      today: today,
      userName: profile.name,
      coachName: profile.coachName,
      steps: log.steps,
      sleep: log.sleepHours,
      calories: meals.loggedSlotsCount > 0 ? meals.totalCalories : null,
      caloriesComplete: meals.hasCompleteCalories,
      habitsDone: scheduled
          .where((h) => isHabitCompleted(h, completions, log))
          .length,
      habitsTotal: scheduled.length,
      habitsRecorded: scheduled
          .where((h) => hasHabitRecord(h, completions, log))
          .length,
      previousHabitsRecorded: previousRecorded,
      previousHabitsTotal: previousHabits.length,
      yesterdayHabitRate:
          previousHabits.isEmpty || previousRecorded != previousHabits.length
          ? null
          : previousDone / previousHabits.length,
      sectionsDone: day == null || rest
          ? 0
          : WorkoutCompletion.completedSectionCount(key, day, hasLog),
      sectionsTotal: day == null || rest
          ? 0
          : day.sections.where((s) => s.exercises.isNotEmpty).length,
      hasWorkoutPlan: hasPlan,
      isRestDay: rest,
      workoutStatus: log.workoutStatus,
      daysSinceLastWorkout: lastWorkout,
      weightComparison: weightComparison,
      hasEntries:
          log.steps != null ||
          log.sleepHours != null ||
          log.weight != null ||
          meals.loggedSlotsCount > 0 ||
          completions.completions.isNotEmpty ||
          completions.overrides.isNotEmpty ||
          log.workoutStatus != null ||
          exerciseDates.contains(key),
    );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
