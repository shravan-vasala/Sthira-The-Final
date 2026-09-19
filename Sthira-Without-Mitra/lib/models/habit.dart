import 'dart:convert';
import 'package:isar/isar.dart';
import 'daily_log.dart';

part 'habit.g.dart';

enum HabitType {
  checkbox,
  counter,
  autoSteps,
  autoSleep,
  autoFromScreenTime,
  timer,
}

enum GoalDirection { atLeast, atMost }

@collection
class Habit {
  Id idInternal = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  final String id;
  final String name;
  final String icon;
  @enumerated
  final HabitType type;
  final String unit;
  final double target;
  final double step;
  DateTime createdAt;
  final int order;
  @enumerated
  final GoalDirection goalDirection;
  final List<int>? activeDays;
  final DateTime? updatedAt;

  Habit({
    required this.id,
    required this.name,
    required this.icon,
    this.type = HabitType.checkbox,
    this.unit = '',
    required this.target,
    this.step = 1.0,
    DateTime? initialCreatedAt,
    this.order = 0,
    this.goalDirection = GoalDirection.atLeast,
    this.activeDays,
    this.updatedAt,
  }) : createdAt = initialCreatedAt ?? DateTime.now();

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? 'check',
      type: HabitType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => HabitType.checkbox,
      ),
      unit: json['unit'] as String? ?? '',
      target: (json['target'] as num?)?.toDouble() ?? 1.0,
      step: (json['step'] as num?)?.toDouble() ?? 1.0,
      initialCreatedAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.parse('2020-01-01'),
      order: json['order'] as int? ?? 0,
      goalDirection: GoalDirection.values.firstWhere(
        (e) => e.name == json['goalDirection'],
        orElse: () => GoalDirection.atLeast,
      ),
      activeDays: (json['activeDays'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'type': type.name,
    'unit': unit,
    'target': target,
    'step': step,
    'createdAt': createdAt.toIso8601String(),
    'order': order,
    'goalDirection': goalDirection.name,
    if (activeDays != null) 'activeDays': activeDays,
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

  Habit copyWith({
    String? name,
    String? icon,
    HabitType? type,
    String? unit,
    double? target,
    double? step,
    int? order,
    GoalDirection? goalDirection,
    List<int>? activeDays,
    DateTime? updatedAt,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      unit: unit ?? this.unit,
      target: target ?? this.target,
      step: step ?? this.step,
      initialCreatedAt: createdAt,
      order: order ?? this.order,
      goalDirection: goalDirection ?? this.goalDirection,
      activeDays: activeDays ?? this.activeDays,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static List<Habit> defaults = [
    Habit(
      id: 'sleep',
      name: 'Sleep 8 hours',
      icon: 'bedtime',
      type: HabitType.autoSleep,
      unit: 'hours',
      target: 8.0,
      initialCreatedAt: DateTime.parse('2020-01-01'),
      order: 0,
    ),
    Habit(
      id: 'walk',
      name: 'Walk 8000 steps',
      icon: 'walk',
      type: HabitType.autoSteps,
      unit: 'steps',
      target: 8000.0,
      initialCreatedAt: DateTime.parse('2020-01-01'),
      order: 1,
    ),
    Habit(
      id: 'water',
      name: 'Drink 3 L of water',
      icon: 'water',
      type: HabitType.checkbox,
      unit: 'L',
      target: 3.0,
      step: 1.0,
      initialCreatedAt: DateTime.parse('2020-01-01'),
      order: 2,
    ),
  ];
}

@collection
class HabitCompletion {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  final String date;

  @ignore
  final Map<String, dynamic> completions; // habitId -> bool or num
  @ignore
  final Map<String, String> overrides; // habitId -> 'done', 'notDone'
  @ignore
  final Map<String, int> streaks; // habitId -> current streak including this day

  final DateTime? updatedAt;

  String get isarCompletions => jsonEncode(completions);
  set isarCompletions(String json) {
    completions.clear();
    completions.addAll(jsonDecode(json) as Map<String, dynamic>);
  }

  String get isarOverrides => jsonEncode(overrides);
  set isarOverrides(String json) {
    overrides.clear();
    overrides.addAll(
      (jsonDecode(json) as Map<String, dynamic>).cast<String, String>(),
    );
  }

  String get isarStreaks => jsonEncode(streaks);
  set isarStreaks(String json) {
    streaks.clear();
    streaks.addAll(
      (jsonDecode(json) as Map<String, dynamic>).cast<String, int>(),
    );
  }

  HabitCompletion({
    required this.date,
    Map<String, dynamic>? completions,
    Map<String, String>? overrides,
    Map<String, int>? streaks,
    this.updatedAt,
  }) : completions = completions ?? {},
       overrides = overrides ?? {},
       streaks = streaks ?? {};

  bool isCompleted(Habit habit) {
    final val = completions[habit.id];
    if (val == null) return false;
    if (val is bool) return val;
    if (val is num && val.isFinite && val >= 0) {
      if (habit.goalDirection == GoalDirection.atMost) {
        return val <= habit.target;
      }
      return val >= habit.target;
    }
    return false;
  }

  double getProgress(Habit habit) {
    final val = completions[habit.id];
    if (val == null) return 0.0;
    if (val is bool) return val ? habit.target : 0.0;
    if (val is num) return val.toDouble();
    return 0.0;
  }

  HabitCompletion toggleCheckbox(String habitId) {
    final newCompletions = Map<String, dynamic>.from(completions);
    final current = newCompletions[habitId];
    newCompletions[habitId] = current is bool ? !current : true;
    return HabitCompletion(
      date: date,
      completions: newCompletions,
      overrides: overrides,
      streaks: streaks,
      updatedAt: DateTime.now(),
    );
  }

  HabitCompletion updateProgress(String habitId, double progress) {
    final newCompletions = Map<String, dynamic>.from(completions);
    newCompletions[habitId] = progress;
    // Clearing override if the user manually uses +/- buttons
    // to return to normal tracking.
    final newOverrides = Map<String, String>.from(overrides);
    newOverrides.remove(habitId);

    return HabitCompletion(
      date: date,
      completions: newCompletions,
      overrides: newOverrides,
      streaks: streaks,
      updatedAt: DateTime.now(),
    );
  }

  HabitCompletion setOverride(String habitId, String? overrideValue) {
    final newOverrides = Map<String, String>.from(overrides);
    if (overrideValue == null) {
      newOverrides.remove(habitId);
    } else {
      newOverrides[habitId] = overrideValue;
    }
    return HabitCompletion(
      date: date,
      completions: completions,
      overrides: newOverrides,
      streaks: streaks,
      updatedAt: DateTime.now(),
    );
  }

  HabitCompletion updateStreak(String habitId, int streak) {
    final newStreaks = Map<String, int>.from(streaks);
    newStreaks[habitId] = streak;
    return HabitCompletion(
      date: date,
      completions: completions,
      overrides: overrides,
      streaks: newStreaks,
      updatedAt: DateTime.now(),
    );
  }

  factory HabitCompletion.fromJson(Map<String, dynamic> json) {
    return HabitCompletion(
      date: json['date'] as String,
      completions:
          (json['completions'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v),
          ) ??
          {},
      overrides:
          (json['overrides'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as String),
          ) ??
          {},
      streaks:
          (json['streaks'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          {},
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'completions': completions,
    'overrides': overrides,
    'streaks': streaks,
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };
}

// Helpers
bool isHabitScheduledOn(Habit habit, DateTime date) {
  final localCreated = habit.createdAt.toLocal();
  final created = DateTime(
    localCreated.year,
    localCreated.month,
    localCreated.day,
  );
  final day = DateTime(date.year, date.month, date.day);
  return !created.isAfter(day) &&
      (habit.activeDays == null || habit.activeDays!.contains(day.weekday));
}

/// Whether a habit has a real check-in; an absent reading is never zero.
bool hasHabitRecord(
  Habit habit,
  HabitCompletion completions,
  DailyLog dailyLog,
) {
  final override = completions.overrides[habit.id];
  if (override == 'done' || override == 'notDone') return true;
  final Object? value = switch (habit.type) {
    HabitType.autoSteps => dailyLog.steps,
    HabitType.autoSleep => dailyLog.sleepHours,
    HabitType.autoFromScreenTime => dailyLog.screenTimeMinutes,
    _ => completions.completions[habit.id],
  };
  return value is bool || (value is num && value.isFinite && value >= 0);
}

double getHabitProgress(
  Habit habit,
  HabitCompletion completions,
  DailyLog dailyLog,
) {
  final override = completions.overrides[habit.id];
  if (override == 'done') return habit.target;
  if (override == 'notDone') return 0.0;

  switch (habit.type) {
    case HabitType.checkbox:
    case HabitType.counter:
    case HabitType.timer:
      return completions.getProgress(habit);
    case HabitType.autoSteps:
      return (dailyLog.steps ?? 0).toDouble();
    case HabitType.autoSleep:
      return dailyLog.sleepHours ?? 0.0;
    case HabitType.autoFromScreenTime:
      return (dailyLog.screenTimeMinutes ?? 0).toDouble();
  }
}

bool isHabitCompleted(
  Habit habit,
  HabitCompletion completions,
  DailyLog dailyLog,
) {
  final override = completions.overrides[habit.id];
  if (override == 'done') return true;
  if (override == 'notDone') return false;
  if (!hasHabitRecord(habit, completions, dailyLog)) return false;

  if (habit.type == HabitType.checkbox ||
      habit.type == HabitType.counter ||
      habit.type == HabitType.timer) {
    return completions.isCompleted(habit);
  }
  final progress = getHabitProgress(habit, completions, dailyLog);
  if (habit.goalDirection == GoalDirection.atMost) {
    return progress <= habit.target;
  }
  return progress >= habit.target;
}
