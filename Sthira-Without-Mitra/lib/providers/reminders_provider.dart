import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/reminder_config.dart';
import '../models/habit.dart';
import '../models/daily_log.dart';
import '../services/notification_service.dart';
import '../utils/workout_completion.dart';
import 'app_providers.dart';

final reminderErrorProvider = StateProvider<String?>((ref) => null);
final _reminderHabitChanges = StreamProvider<void>((ref) {
  ref.watch(accountGenerationProvider);
  return ref.watch(activeDatabaseProvider)?.habits.watchLazy() ??
      const Stream.empty();
});
final _reminderCompletionChanges = StreamProvider<void>((ref) {
  ref.watch(accountGenerationProvider);
  return ref.watch(activeDatabaseProvider)?.habitCompletions.watchLazy() ??
      const Stream.empty();
});

bool reminderQuietAt(ReminderConfig config, DateTime date) {
  if (!config.quietHoursEnabled) return false;
  final minute = date.hour * 60 + date.minute;
  final start =
      config.quietHoursStart.hour * 60 + config.quietHoursStart.minute;
  final end = config.quietHoursEnd.hour * 60 + config.quietHoursEnd.minute;
  if (start == end) return true;
  return start < end
      ? minute >= start && minute < end
      : minute >= start || minute < end;
}

DateTime? nextNonQuiet(ReminderConfig config, DateTime start) {
  // Equality means a full-day quiet period. Never spin while applying snoozes.
  if (config.quietHoursEnabled &&
      config.quietHoursStart == config.quietHoursEnd)
    return null;
  var date = start;
  for (var i = 0; i <= 1440; i++) {
    if (!reminderQuietAt(config, date)) return date;
    date = date.add(const Duration(minutes: 1));
  }
  return null;
}

bool hasUnfinishedScheduledHabits(
  List<Habit> habits,
  HabitCompletion completions,
  DailyLog log,
  DateTime date,
) {
  final day = DateTime(date.year, date.month, date.day);
  return habits
      .where(
        (habit) =>
            !DateTime(
              habit.createdAt.year,
              habit.createdAt.month,
              habit.createdAt.day,
            ).isAfter(day) &&
            (habit.activeDays == null ||
                habit.activeDays!.contains(date.weekday)),
      )
      .any((habit) {
        if (completions.overrides[habit.id] == 'done') return false;
        if (completions.overrides[habit.id] == 'notDone') return true;
        if (habit.type == HabitType.autoFromScreenTime &&
            log.screenTimeMinutes == null)
          return true;
        if (habit.type == HabitType.autoSteps && log.steps == null) return true;
        if (habit.type == HabitType.autoSleep && log.sleepHours == null)
          return true;
        return !isHabitCompleted(habit, completions, log);
      });
}

class RemindersNotifier extends Notifier<ReminderConfig> {
  late SharedPreferences _prefs;
  late NotificationService _notifications;
  Future<void>? _pending;
  bool _needsSync = false;
  bool _disposed = false;
  int _schedulerGeneration = 0;
  String get _account => ref.read(activeAccountIdProvider);
  String get _key => 'reminder_config_$_account';

  @override
  ReminderConfig build() {
    ref.watch(accountGenerationProvider);
    _disposed = false;
    _schedulerGeneration++;
    _prefs = ref.watch(sharedPreferencesProvider);
    _notifications = ref.watch(notificationServiceProvider);
    ref.listen(workoutPlanProvider, (_, __) => unawaited(queueSync()));
    ref.listen(progressPhotosStreamProvider, (_, __) => unawaited(queueSync()));
    ref.listen(dailyLogsUpdateProvider, (_, __) => unawaited(queueSync()));
    ref.listen(dailyMealLogsUpdateProvider, (_, __) => unawaited(queueSync()));
    ref.listen(_reminderHabitChanges, (_, __) => unawaited(queueSync()));
    ref.listen(_reminderCompletionChanges, (_, __) => unawaited(queueSync()));
    ref.listen(exerciseLogsUpdateProvider, (_, __) => unawaited(queueSync()));
    ref.listen(clockProvider, (_, __) => unawaited(queueSync()));
    ref.onDispose(() {
      _disposed = true;
      _schedulerGeneration++;
    });
    final saved = _prefs.getString(_key);
    if (saved != null) return ReminderConfig.fromJson(saved);
    // Adopt the old device setting once, for the account active during migration.
    final legacy = _prefs.getString('reminder_config');
    if (legacy != null) {
      unawaited(
        _prefs
            .setString(_key, legacy)
            .then((_) => _prefs.remove('reminder_config')),
      );
      return ReminderConfig.fromJson(legacy);
    }
    return ReminderConfig();
  }

  Future<void> queueSync() {
    _needsSync = true;
    return _pending ??= _drain().whenComplete(() => _pending = null);
  }

  Future<void> _drain() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    while (_needsSync && !_disposed) {
      _needsSync = false;
      if (ref.read(accountTransitionProvider)) continue;
      final generation = _schedulerGeneration;
      final accountGeneration = ref.read(accountGenerationProvider);
      bool current() =>
          !_disposed &&
          !ref.read(accountTransitionProvider) &&
          generation == _schedulerGeneration &&
          accountGeneration == ref.read(accountGenerationProvider);
      try {
        final schedules = _buildSchedules(DateTime.now());
        await _notifications.reconcileRoutineSchedules(
          schedules,
          isCurrent: current,
        );
        if (current()) ref.read(reminderErrorProvider.notifier).state = null;
      } catch (_) {
        if (current())
          ref.read(reminderErrorProvider.notifier).state =
              'Reminders could not be updated. Check notification access and try again.';
      }
    }
  }

  Future<void> updateConfig(ReminderConfig config) async {
    final generation = ref.read(accountGenerationProvider);
    final key = _key;
    final enabling =
        (config.habitsEnabled && !state.habitsEnabled) ||
        (config.workoutsEnabled && !state.workoutsEnabled) ||
        (config.mealsEnabled && !state.mealsEnabled) ||
        (config.backupEnabled && !state.backupEnabled) ||
        (config.photosEnabled && !state.photosEnabled) ||
        (config.bodyFatEnabled && !state.bodyFatEnabled);
    if (enabling) {
      bool granted;
      try {
        granted = await _notifications.requestPermissions();
      } catch (_) {
        granted = false;
      }
      if (_disposed || generation != ref.read(accountGenerationProvider))
        return;
      if (!granted) {
        ref.read(reminderErrorProvider.notifier).state =
            'Notification permission is off. Enable it in system settings to receive reminders.';
        return;
      }
    }
    if (_disposed || generation != ref.read(accountGenerationProvider)) return;
    state = config;
    await _prefs.setString(key, config.toJson());
    await queueSync();
  }

  List<RoutineNotification> _buildSchedules(DateTime now) {
    final config = state;
    final account = _account;
    final profile = ref.read(profileProvider);
    final logs = ref.read(dailyLogRepoProvider);
    final habits = ref.read(habitRepoProvider);
    final meals = ref.read(mealRepoProvider);
    final plan = ref.read(workoutPlanProvider);
    final specs = <RoutineNotification>[];
    String dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
    String payload(String type, DateTime date, {bool recurring = false}) =>
        jsonEncode({
          'v': 2,
          'account': account,
          'type': type,
          'date': dateKey(date),
          'recurring': recurring,
        });
    bool skipped(String type, DateTime date) =>
        _prefs.getBool('reminder_skip_${account}_${type}_${dateKey(date)}') ??
        false;
    void weekly(
      String type,
      int baseId,
      TimeOfDay time,
      String title,
      String body,
      bool Function(DateTime) applies,
      bool Function(DateTime) complete,
    ) {
      for (var offset = 0; offset < 7; offset++) {
        var date = DateTime(
          now.year,
          now.month,
          now.day + offset,
          time.hour,
          time.minute,
        );
        if (!applies(date) || reminderQuietAt(config, date)) continue;
        if (!date.isAfter(now) || skipped(type, date) || complete(date))
          date = DateTime(
            date.year,
            date.month,
            date.day + 7,
            date.hour,
            date.minute,
          );
        specs.add(
          RoutineNotification(
            id: baseId + date.weekday,
            title: title,
            body: body,
            date: date,
            payload: payload(type, date, recurring: true),
            repeatWeekly: true,
          ),
        );
      }
    }

    if (config.habitsEnabled)
      weekly(
        'habit',
        1000,
        config.habitTime,
        'Evening Routine',
        'Time to check in on your habits.',
        (date) => hasUnfinishedScheduledHabits(
          habits.getHabits(),
          HabitCompletion(date: dateKey(date)),
          DailyLog(date: dateKey(date)),
          date,
        ),
        (date) => !hasUnfinishedScheduledHabits(
          habits.getHabits(),
          habits.getCompletions(dateKey(date)),
          logs.getLog(dateKey(date)) ?? DailyLog(date: dateKey(date)),
          date,
        ),
      );
    if (config.mealsEnabled) {
      weekly(
        'lunch',
        2000,
        config.lunchTime,
        'Lunch Check-in',
        'Have you logged lunch?',
        (_) => true,
        (date) => meals.isMealLogged(dateKey(date), 'lunch'),
      );
      weekly(
        'dinner',
        2100,
        config.dinnerTime,
        'Dinner Check-in',
        'Time to track your dinner.',
        (_) => true,
        (date) => meals.isMealLogged(dateKey(date), 'dinner'),
      );
    }
    bool workoutDone(DateTime date) {
      final log = logs.getLog(dateKey(date));
      if (log?.workoutStatus == 'completed' || log?.workoutStatus == 'skipped')
        return true;
      if (plan == null) return false;
      final day = WorkoutCompletion.resolveWorkoutDay(
        plan,
        date,
        planStartDate: profile.planStartDate,
      );
      return WorkoutCompletion.isTrainingDayCompleteWithRepo(
        dateKey(date),
        day,
        ref.read(exerciseLogRepoProvider),
      );
    }

    if (config.workoutsEnabled && plan != null)
      weekly(
        'workout',
        3000,
        config.workoutTime,
        'Workout Scheduled',
        'Your workout is ready when you are.',
        (date) {
          return WorkoutCompletion.resolveWorkoutDay(
            plan,
            date,
            planStartDate: profile.planStartDate,
          ).sections.isNotEmpty;
        },
        workoutDone,
      );
    if (config.backupEnabled)
      weekly(
        'backup',
        4000,
        config.backupTime,
        'Weekly Backup',
        'Back up your data securely.',
        (date) => date.weekday == config.backupDayOfWeek,
        (_) => false,
      );
    if (config.bodyFatEnabled)
      weekly(
        'bodyFat',
        6000,
        const TimeOfDay(hour: 10, minute: 0),
        'Body Fat Check-in',
        'Update your body fat measurement when you are ready.',
        (date) => date.weekday == DateTime.sunday,
        (date) => logs.getLog(dateKey(date))?.bodyFat != null,
      );
    if (config.photosEnabled) {
      final photos = ref.read(mediaRepoProvider).getAllProgressPhotosDetailed();
      DateTime? last;
      for (final photo in photos) {
        final date = DateTime.tryParse(photo.date);
        if (date != null && (last == null || date.isAfter(last))) last = date;
      }
      final due = last == null
          ? now
          : DateTime(last.year, last.month, last.day + 14);
      final base = due.isAfter(now) ? due : now;
      var scheduled = DateTime(
        base.year,
        base.month,
        base.day,
        config.photoTime.hour,
        config.photoTime.minute,
      );
      if (!scheduled.isAfter(now) || skipped('photo', scheduled))
        scheduled = DateTime(
          scheduled.year,
          scheduled.month,
          scheduled.day + 1,
          scheduled.hour,
          scheduled.minute,
        );
      final fire = nextNonQuiet(config, scheduled);
      if (fire != null)
        specs.add(
          RoutineNotification(
            id: 5000,
            title: 'Progress Photo',
            body: 'Take a photo to track your progress.',
            date: fire,
            payload: payload('photo', fire),
          ),
        );
    }
    const types = [
      'habit',
      'lunch',
      'dinner',
      'workout',
      'backup',
      'photo',
      'bodyFat',
    ];
    for (var i = 0; i < types.length; i++) {
      final type = types[i];
      final until = _prefs.getInt(
        'reminder_snooze_${account}_${type}_${dateKey(now)}',
      );
      if (until == null || skipped(type, now)) continue;
      final alreadyDone = switch (type) {
        'habit' => !hasUnfinishedScheduledHabits(
          habits.getHabits(),
          habits.getCompletions(dateKey(now)),
          logs.getLog(dateKey(now)) ?? DailyLog(date: dateKey(now)),
          now,
        ),
        'lunch' || 'dinner' => meals.isMealLogged(dateKey(now), type),
        'workout' => workoutDone(now),
        'bodyFat' => logs.getLog(dateKey(now))?.bodyFat != null,
        _ => false,
      };
      if (alreadyDone) continue;
      final fire = nextNonQuiet(
        config,
        DateTime.fromMillisecondsSinceEpoch(until),
      );
      if (fire == null || !fire.isAfter(now) || dateKey(fire) != dateKey(now))
        continue;
      // Keep snoozes in the reconciled ID range so disabling a category clears them.
      final enabled = switch (type) {
        'habit' => config.habitsEnabled,
        'lunch' || 'dinner' => config.mealsEnabled,
        'workout' => config.workoutsEnabled,
        'backup' => config.backupEnabled,
        'photo' => config.photosEnabled,
        _ => config.bodyFatEnabled,
      };
      if (enabled)
        specs.add(
          RoutineNotification(
            id: 6500 + i,
            title: 'Your Check-in',
            body: 'Ready to continue?',
            date: fire,
            payload: jsonEncode({
              'v': 2,
              'account': account,
              'type': type,
              'date': dateKey(fire),
              'occurrence': until,
            }),
          ),
        );
    }
    return specs;
  }

  Future<void> initializeNotifications() => queueSync();

  Future<void> clearOnSignOut() async {
    _schedulerGeneration++;
    _needsSync = false;
    await _pending;
    await _notifications.cancelAll();
  }
}

final remindersProvider = NotifierProvider<RemindersNotifier, ReminderConfig>(
  RemindersNotifier.new,
);
