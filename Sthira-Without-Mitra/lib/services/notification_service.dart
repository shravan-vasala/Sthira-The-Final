import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final actionStream = StreamController<NotificationResponse>.broadcast();
  final List<NotificationResponse> _pendingActions = [];
  final Map<int, String> _scheduled = {};

  List<NotificationResponse> takePendingActions() {
    final pending = List<NotificationResponse>.of(_pendingActions);
    _pendingActions.clear();
    return pending;
  }

  void _deliver(NotificationResponse response) {
    if (actionStream.hasListener) {
      actionStream.add(response);
    } else {
      _pendingActions.add(response);
    }
  }

  static const _routineChannel = MethodChannel(
    'com.trufit.trufit_bodamma/routines',
  );
  bool _nativeListenerAttached = false;
  bool _initialized = false;
  Future<void>? _initFuture;

  Future<void> init() async {
    if (_initialized) return;
    if (_initFuture != null) {
      return _initFuture;
    }
    _initFuture = _doInit();
    try {
      await _initFuture;
    } finally {
      _initFuture = null;
    }
  }

  Future<void> _doInit() async {
    if (!_nativeListenerAttached) {
      _nativeListenerAttached = true;
      _routineChannel.setMethodCallHandler((call) async {
        if (call.method == 'action') _receiveNativeAction(call.arguments);
      });
    }
    tz.initializeTimeZones();

    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (e) {
      debugPrint(
        'Timezone lookup unavailable; routine alarms use native local time.',
      );
      tz.setLocalLocation(tz.UTC);
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_stat_sthira');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    try {
      final result = await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );
      _initialized = result ?? false;
      if (_initialized)
        _receiveNativeAction(
          await _routineChannel.invokeMethod('launchAction'),
        );

      // Handle App Launch explicitly for Prompt 01 fix
      final details = await _notificationsPlugin
          .getNotificationAppLaunchDetails();
      if (details != null &&
          details.didNotificationLaunchApp &&
          details.notificationResponse != null) {
        // Buffer until the app-level action controller subscribes
        _deliver(details.notificationResponse!);
      }
    } catch (e) {
      debugPrint('Failed to initialize local notifications: $e');
    }
  }

  void _receiveNativeAction(dynamic raw) {
    if (raw is! String) return;
    try {
      final value = jsonDecode(raw);
      if (value is! Map || value['payload'] is! String || value['id'] is! int)
        return;
      _deliver(
        NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotificationAction,
          id: value['id'] as int,
          payload: value['payload'] as String,
          actionId: value['action'] is String
              ? value['action'] as String
              : null,
        ),
      );
    } catch (_) {}
  }

  void _onNotificationResponse(NotificationResponse response) {
    debugPrint(
      'Notification Action received: ${response.actionId} with payload: ${response.payload}',
    );
    _deliver(response);
  }

  Future<bool> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      final bool? granted = await androidImplementation
          .requestNotificationsPermission();
      // Do not bind inexact routine permissions to exact alarms.
      return granted ?? false;
    }
    return false;
  }

  Future<bool> requestExactAlarmPermission() async {
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImplementation != null) {
      final bool? exactGranted = await androidImplementation
          .requestExactAlarmsPermission();
      return exactGranted ?? false;
    }
    return false;
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
    for (final id in await _nativePending()) {
      await _routineChannel.invokeMethod('cancel', {'id': id});
    }
    _scheduled.clear();
  }

  /// Inspect OS pending IDs once instead of issuing dozens of empty cancels.
  Future<void> cancelRange(int startId, int endId) async {
    final ids = {
      ...await _nativePending(),
      ...(await _notificationsPlugin.pendingNotificationRequests()).map(
        (item) => item.id,
      ),
    };
    for (final id in ids) {
      if (id >= startId && id <= endId) await cancel(id);
    }
  }

  Future<void> dismiss(int id) =>
      _routineChannel.invokeMethod('dismiss', {'id': id});

  Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id);
    if (id >= 1000) await _routineChannel.invokeMethod('cancel', {'id': id});
    _scheduled.remove(id);
  }

  Future<List<int>> _nativePending() async =>
      (await _routineChannel.invokeListMethod<int>('pending')) ?? [];

  Future<void> reconcileRoutineSchedules(
    List<RoutineNotification> desired, {
    required bool Function() isCurrent,
  }) async {
    await init();
    if (!_initialized)
      throw StateError('Notifications could not be initialized');
    final android = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (desired.isNotEmpty &&
        !(await android?.areNotificationsEnabled() ?? false))
      throw StateError('Notification permission is disabled');
    // Migrate away from the previous expiring schedules only when they exist.
    for (final item
        in await _notificationsPlugin.pendingNotificationRequests()) {
      if (!isCurrent()) return;
      if (item.id >= 1000 && item.id < 7000)
        await _notificationsPlugin.cancel(item.id);
    }
    final existingIds = (await _nativePending()).toSet();
    final ids = desired.map((item) => item.id).toSet();
    for (final id in existingIds) {
      if (!isCurrent()) return;
      if (id < 7000 && !ids.contains(id)) await cancel(id);
    }
    for (final item in desired) {
      if (!isCurrent()) return;
      if (existingIds.contains(item.id) &&
          _scheduled[item.id] == item.fingerprint)
        continue;
      await scheduleAbsolute(
        id: item.id,
        title: item.title,
        body: item.body,
        scheduledDate: item.date,
        payload: item.payload,
        addSnooze: item.actions,
        addSkip: item.actions,
        repeatWeekly: item.repeatWeekly,
      );
      _scheduled[item.id] = item.fingerprint;
    }
  }

  /// Cancels habits (1000-1031)
  Future<void> cancelHabits() => cancelRange(1000, 1031);

  /// Cancels meals (2000-2031 lunch, 2100-2131 dinner)
  Future<void> cancelMeals() async {
    await cancelRange(2000, 2031);
    await cancelRange(2100, 2131);
  }

  /// Cancels workouts (3000-3031)
  Future<void> cancelWorkouts() => cancelRange(3000, 3031);

  /// Cancels backups (4000)
  Future<void> cancelBackup() => cancelRange(4000, 4000);

  /// Cancels photos (5000)
  Future<void> cancelPhotos() => cancelRange(5000, 5000);

  /// Cancels body fat (6000)
  Future<void> cancelBodyFat() => cancelRange(6000, 6000);

  Future<void> scheduleAbsolute({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    bool addSnooze = true,
    bool addSkip = true,
    bool repeatWeekly = false,
  }) async {
    if (!_initialized) await init();
    if (!_initialized)
      throw StateError('Notifications could not be initialized');

    if (!scheduledDate.isAfter(DateTime.now())) return;
    await _routineChannel.invokeMethod('schedule', {
      'id': id,
      'title': title,
      'body': body,
      'at': scheduledDate.millisecondsSinceEpoch,
      'localDate':
          '${scheduledDate.year.toString().padLeft(4, '0')}-${scheduledDate.month.toString().padLeft(2, '0')}-${scheduledDate.day.toString().padLeft(2, '0')}',
      'hour': scheduledDate.hour,
      'minute': scheduledDate.minute,
      'weekday': scheduledDate.weekday % 7 + 1,
      'weekly': repeatWeekly,
      'actions': addSnooze || addSkip,
      'payload': payload,
    });
  }

  Future<RestTimerDelivery> scheduleRestTimer(
    int seconds,
    String? exerciseName, {
    bool playSound = true,
    bool enableVibration = true,
  }) async {
    if (!_initialized) await init();
    if (!_initialized) return RestTimerDelivery.unavailable;

    final title = 'Rest Complete!';
    final body = exerciseName != null
        ? 'Time for $exerciseName'
        : 'Your rest timer has finished.';

    try {
      final android = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final exact = await android?.canScheduleExactNotifications() ?? false;
      await _notificationsPlugin.zonedSchedule(
        // Use ID 100 for rest timer to clearly separate from routine IDs
        100,
        title,
        body,
        tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds)),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'rest_timer_${playSound ? 'sound' : 'silent'}_${enableVibration ? 'vibrate' : 'still'}',
            'Rest Timer',
            channelDescription: 'Notifications for rest timer completion',
            importance: Importance.max,
            priority: Priority.high,
            playSound: playSound,
            enableVibration: enableVibration,
          ),
        ),
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      return exact ? RestTimerDelivery.exact : RestTimerDelivery.approximate;
    } catch (e) {
      return RestTimerDelivery.unavailable;
    }
  }

  Future<void> cancelRestTimer() async {
    try {
      await _notificationsPlugin.cancel(100);
    } catch (e) {
      // Ignore
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

enum RestTimerDelivery { exact, approximate, unavailable }

class RoutineNotification {
  final int id;
  final String title;
  final String body;
  final DateTime date;
  final String payload;
  final bool repeatWeekly;
  final bool actions;
  const RoutineNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    required this.payload,
    this.repeatWeekly = false,
    this.actions = true,
  });
  String get fingerprint => jsonEncode([
    title,
    body,
    date.toIso8601String(),
    payload,
    repeatWeekly,
    actions,
  ]);
}
