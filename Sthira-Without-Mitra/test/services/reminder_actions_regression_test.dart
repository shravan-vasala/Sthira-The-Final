import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/habit.dart';
import 'package:trufit_bodamma/models/reminder_config.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/providers/reminders_provider.dart';
import 'package:trufit_bodamma/providers/notification_action_controller.dart';
import 'package:trufit_bodamma/services/notification_service.dart';
import 'package:trufit_bodamma/utils/time_utils.dart';

class _Notifications implements NotificationService {
  @override
  final actionStream = StreamController<NotificationResponse>.broadcast();
  final List<NotificationResponse> pending = [];
  @override
  List<NotificationResponse> takePendingActions() {
    final copy = List<NotificationResponse>.of(pending);
    pending.clear();
    return copy;
  }

  @override
  Future<void> dismiss(int id) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Reminders extends RemindersNotifier {
  int reconciliations = 0;
  @override
  ReminderConfig build() => ReminderConfig(habitsEnabled: true);
  @override
  Future<void> queueSync() async {
    reconciliations++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('malformed persisted times and weekdays fall back safely', () {
    final config = ReminderConfig.fromMap({
      'habitTime': '99:-3',
      'backupDayOfWeek': 55,
      'workoutTime': 123,
    });
    expect(config.habitTime, const TimeOfDay(hour: 21, minute: 0));
    expect(config.backupDayOfWeek, DateTime.sunday);
    expect(config.workoutTime, const TimeOfDay(hour: 7, minute: 0));
    expect(ReminderConfig.fromJson('broken').habitsEnabled, isFalse);
  });
  test('all-day quiet hours never produce an unbounded snooze', () {
    expect(
      nextNonQuiet(
        ReminderConfig(
          quietHoursEnabled: true,
          quietHoursStart: const TimeOfDay(hour: 7, minute: 0),
          quietHoursEnd: const TimeOfDay(hour: 7, minute: 0),
        ),
        DateTime(2026, 9, 19, 9),
      ),
      isNull,
    );
    expect(
      nextNonQuiet(
        ReminderConfig(quietHoursEnabled: true),
        DateTime(2026, 9, 19, 23),
      ),
      DateTime(2026, 9, 20, 7),
    );
  });
  test('one over-target counter cannot hide another unfinished habit', () {
    final habits = [
      Habit(
        id: 'water',
        name: 'Water',
        icon: '',
        type: HabitType.counter,
        target: 2,
        initialCreatedAt: DateTime(2020),
      ),
      Habit(
        id: 'read',
        name: 'Read',
        icon: '',
        target: 1,
        initialCreatedAt: DateTime(2020),
      ),
    ];
    expect(
      hasUnfinishedScheduledHabits(
        habits,
        HabitCompletion(date: '2026-09-19', completions: {'water': 20}),
        DailyLog(date: '2026-09-19'),
        DateTime(2026, 9, 19),
      ),
      isTrue,
    );
  });
  test('auto habits use daily measurements, overrides and active weekdays', () {
    final habit = Habit(
      id: 'steps',
      name: 'Walk',
      icon: '',
      type: HabitType.autoSteps,
      target: 100,
      activeDays: [DateTime.saturday],
      initialCreatedAt: DateTime(2020),
    );
    final done = HabitCompletion(date: '2026-09-19');
    expect(
      hasUnfinishedScheduledHabits(
        [habit],
        done,
        DailyLog(date: '2026-09-19', steps: 200),
        DateTime(2026, 9, 19),
      ),
      isFalse,
    );
    expect(
      hasUnfinishedScheduledHabits(
        [habit],
        done,
        DailyLog(date: '2026-09-19'),
        DateTime(2026, 9, 19),
      ),
      isTrue,
    );
    expect(
      hasUnfinishedScheduledHabits(
        [habit],
        done,
        DailyLog(date: '2026-09-20'),
        DateTime(2026, 9, 20),
      ),
      isFalse,
    );
    expect(
      hasUnfinishedScheduledHabits(
        [habit],
        HabitCompletion(date: '2026-09-19', overrides: {'steps': 'done'}),
        DailyLog(date: '2026-09-19'),
        DateTime(2026, 9, 19),
      ),
      isFalse,
    );
  });
  test('notification intents reject wrong accounts and impossible dates', () {
    final now = DateTime(2026, 9, 19);
    expect(
      ReminderIntent.parse(
        jsonEncode({
          'v': 2,
          'account': 'other',
          'type': 'habit',
          'date': '2026-09-19',
        }),
        'guest',
        now,
      ),
      isNull,
    );
    expect(
      ReminderIntent.parse(
        jsonEncode({
          'v': 2,
          'account': 'guest',
          'type': 'habit',
          'date': '2026-02-31',
        }),
        'guest',
        now,
      ),
      isNull,
    );
  });
  test(
    'cold-start actions are consumed after controller subscribes and deduplicated',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = _Notifications();
      final response = NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        id: 1006,
        payload: jsonEncode({
          'v': 2,
          'account': 'guest',
          'type': 'habit',
          'date': todayKey(),
        }),
      );
      service.pending.add(response);
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          activeAccountIdProvider.overrideWithValue('guest'),
          notificationServiceProvider.overrideWithValue(service),
        ],
      );
      container.read(notificationActionControllerProvider);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(container.read(reminderNavigationProvider)?.type, 'habit');
      service.actionStream.add(response);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(prefs.getStringList('reminder_actions_guest')!.length, 1);
      container.dispose();
      await service.actionStream.close();
    },
  );
  test('cold-start tap survives same-account startup hydration', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = _Notifications();
    service.pending.add(
      NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        id: 1006,
        payload: jsonEncode({
          'v': 2,
          'account': 'guest',
          'type': 'habit',
          'date': todayKey(),
        }),
      ),
    );
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        activeAccountIdProvider.overrideWithValue('guest'),
        accountTransitionProvider.overrideWith((ref) => true),
        notificationServiceProvider.overrideWithValue(service),
      ],
    );
    container.read(notificationActionControllerProvider);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(reminderNavigationProvider), isNull);
    container.read(accountGenerationProvider.notifier).state++;
    container.read(accountTransitionProvider.notifier).state = false;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(container.read(reminderNavigationProvider)?.type, 'habit');
    container.dispose();
    await service.actionStream.close();
  });

  test(
    'skip and snooze persist date/account-scoped actions and reconcile',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = _Notifications();
      final notifier = _Reminders();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          activeAccountIdProvider.overrideWithValue('guest'),
          notificationServiceProvider.overrideWithValue(service),
          remindersProvider.overrideWith(() => notifier),
        ],
      );
      final controller = container.read(notificationActionControllerProvider);
      await controller.handle(
        NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotificationAction,
          id: 1006,
          actionId: 'skip',
          payload: jsonEncode({
            'v': 2,
            'account': 'guest',
            'type': 'habit',
            'date': todayKey(),
          }),
        ),
      );
      expect(prefs.getBool('reminder_skip_guest_habit_${todayKey()}'), isTrue);
      expect(notifier.reconciliations, 1);
      container.dispose();
      await service.actionStream.close();
    },
  );
}
