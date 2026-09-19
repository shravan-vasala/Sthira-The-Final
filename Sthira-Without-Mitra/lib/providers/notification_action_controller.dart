import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/notification_service.dart';
import '../utils/time_utils.dart';
import 'app_providers.dart';
import 'reminders_provider.dart';

class ReminderNavigation {
  final String type;
  final DateTime date;
  const ReminderNavigation({required this.type, required this.date});
}

final reminderNavigationProvider = StateProvider<ReminderNavigation?>(
  (ref) => null,
);

class ReminderIntent {
  final String account;
  final String type;
  final DateTime date;
  const ReminderIntent(this.account, this.type, this.date);
  static ReminderIntent? parse(
    String? payload,
    String currentAccount,
    DateTime now,
  ) {
    try {
      final decoded = jsonDecode(payload ?? '');
      if (decoded is! Map) return null;
      final version = decoded['v'];
      if (version != 1 && version != 2) return null;
      final account = version == 1 ? 'guest' : decoded['account'];
      if (account is! String || account != currentAccount) return null;
      const types = {
        'habit',
        'lunch',
        'dinner',
        'workout',
        'backup',
        'photo',
        'bodyFat',
      };
      final type = decoded['type'];
      final dateText = decoded['date'];
      if (type is! String || !types.contains(type) || dateText is! String)
        return null;
      var date = DateTime.tryParse(dateText);
      if (date == null || todayKey(date) != dateText) return null;
      if (decoded['recurring'] == true) {
        final today = DateTime(now.year, now.month, now.day);
        date = DateTime(
          today.year,
          today.month,
          today.day - (today.weekday - date.weekday + 7) % 7,
        );
      }
      if (date.isAfter(now)) return null;
      return ReminderIntent(account, type, date);
    } catch (_) {
      return null;
    }
  }
}

final notificationActionControllerProvider =
    Provider<NotificationActionController>((ref) {
      final controller = NotificationActionController(ref);
      ref.onDispose(controller.dispose);
      return controller;
    });

class NotificationActionController {
  final Ref ref;
  late final StreamSubscription<NotificationResponse> _subscription;
  Future<void> _queue = Future.value();
  bool _disposed = false;
  final List<NotificationResponse> _deferred = [];
  NotificationActionController(this.ref) {
    final service = ref.read(notificationServiceProvider);
    _subscription = service.actionStream.stream.listen(_enqueue);
    ref.listen(accountTransitionProvider, (_, transitioning) {
      if (!transitioning && !_disposed) {
        final waiting = List<NotificationResponse>.of(_deferred);
        _deferred.clear();
        for (final response in waiting) {
          _enqueue(response);
        }
      }
    });
    for (final response in service.takePendingActions()) _enqueue(response);
  }

  void _enqueue(NotificationResponse response) {
    _queue = _queue
        .then((_) async {
          if (!_disposed) await handle(response);
        })
        .catchError((Object _) {
          if (!_disposed)
            ref.read(reminderErrorProvider.notifier).state =
                'That reminder action could not be completed. Please try again.';
        });
  }

  Future<void> handle(NotificationResponse response) async {
    if (_disposed) return;
    if (ref.read(accountTransitionProvider)) {
      _deferred.add(response);
      return;
    }
    final now = DateTime.now();
    final generation = ref.read(accountGenerationProvider);
    final account = ref.read(activeAccountIdProvider);
    bool current() =>
        !_disposed &&
        generation == ref.read(accountGenerationProvider) &&
        account == ref.read(activeAccountIdProvider);
    final intent = ReminderIntent.parse(response.payload, account, now);
    if (intent == null) return;
    final action = response.actionId ?? 'open';
    if (!{'open', '', 'snooze', 'skip'}.contains(action)) return;
    final prefs = ref.read(sharedPreferencesProvider);
    final handledKey = 'reminder_actions_$account';
    final handled = prefs.getStringList(handledKey) ?? [];
    final token = '${response.id}:$action:${response.payload}';
    if (handled.contains(token)) return;
    final date = todayKey(intent.date);
    if (action == 'skip' || action == 'snooze') {
      // An old notification must never skip or snooze a different day.
      if (date != todayKey(now)) return;
      if (action == 'skip') {
        await prefs.setBool(
          'reminder_skip_${account}_${intent.type}_$date',
          true,
        );
        await prefs.remove('reminder_snooze_${account}_${intent.type}_$date');
      } else {
        final countKey =
            'reminder_snooze_count_${account}_${intent.type}_$date';
        final count = prefs.getInt(countKey) ?? 0;
        if (count >= 3) return;
        final fire = nextNonQuiet(
          ref.read(remindersProvider),
          now.add(const Duration(hours: 1)),
        );
        if (fire == null || todayKey(fire) != date) {
          if (current())
            ref.read(reminderErrorProvider.notifier).state =
                'Snooze would fall outside today or during quiet hours.';
          return;
        }
        await prefs.setInt(
          'reminder_snooze_${account}_${intent.type}_$date',
          fire.millisecondsSinceEpoch,
        );
        await prefs.setInt(countKey, count + 1);
      }
      if (!current()) return;
      await ref.read(remindersProvider.notifier).queueSync();
    } else {
      if (!current()) return;
      ref.read(reminderNavigationProvider.notifier).state = ReminderNavigation(
        type: intent.type,
        date: intent.date,
      );
    }
    if (!current()) return;
    handled.add(token);
    await prefs.setStringList(
      handledKey,
      handled.length <= 100 ? handled : handled.sublist(handled.length - 100),
    );
    if (current() && response.id != null)
      await ref.read(notificationServiceProvider).dismiss(response.id!);
  }

  void dispose() {
    _disposed = true;
    unawaited(_subscription.cancel());
  }
}
