import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/services/haptics.dart';
import 'package:trufit_bodamma/services/notification_service.dart';

class _Profile extends ProfileNotifier {
  _Profile(this.vibrate);
  final bool vibrate;
  @override
  UserProfile build() => UserProfile(
    restTimerVibration: vibrate,
    restTimerSound: false,
    restTimerNotification: false,
  );
}

class _Notifications implements NotificationService {
  @override
  Future<void> cancelRestTimer() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Runs an actual notifier timer tick without sleeping or changing its clock.
/// The timer starts at three seconds, so an immediate tick enters the existing
/// final-countdown branch regardless of the wall-clock date.
class _TickTimer implements Timer {
  _TickTimer(this.callback);
  final void Function(Timer) callback;
  bool _active = true;
  int _tick = 0;
  @override
  bool get isActive => _active;
  @override
  int get tick => _tick;
  @override
  void cancel() => _active = false;
  void fire() {
    if (!_active) return;
    _tick++;
    callback(this);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final enabled in [false, true]) {
    test('final countdown respects vibration setting: $enabled', () async {
      SharedPreferences.setMockInitialValues({'rest_timer_v2_migrated': true});
      final prefs = await SharedPreferences.getInstance();
      final events = <MethodCall>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'HapticFeedback.vibrate') events.add(call);
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      final previousHaptics = Haptics.enabled;
      Haptics.enabled = true;
      addTearDown(() => Haptics.enabled = previousHaptics);
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          activeAccountIdProvider.overrideWithValue('account-a'),
          profileProvider.overrideWith(() => _Profile(enabled)),
          notificationServiceProvider.overrideWithValue(_Notifications()),
        ],
      );
      addTearDown(container.dispose);
      late _TickTimer timer;
      runZoned(
        () {
          container.read(restTimerProvider.notifier).startTimer(3);
          timer.fire();
        },
        zoneSpecification: ZoneSpecification(
          createPeriodicTimer: (self, parent, zone, duration, callback) {
            expect(duration, const Duration(seconds: 1));
            return timer = _TickTimer(callback);
          },
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(container.read(restTimerProvider).isActive, isTrue);
      expect(
        events.map((event) => event.arguments),
        enabled ? ['HapticFeedbackType.mediumImpact'] : isEmpty,
      );
      container.read(restTimerProvider.notifier).stopTimer();
      expect(timer.isActive, isFalse);
    });
  }
}
