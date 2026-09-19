import 'dart:convert';
import 'reminders_provider.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';
import 'package:trufit_bodamma/theme/app_colors.dart';
import '../services/notification_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/haptics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../router/app_router.dart';
import 'app_providers.dart';

String kTimerEndTimeKey = 'rest_timer_end_time';
String kTimerRemainingKey = 'rest_timer_remaining';
String kTimerIsPausedKey = 'rest_timer_is_paused';
String kTimerExerciseKey = 'rest_timer_exercise';

class RestTimerState {
  final int remainingSeconds;
  final bool isActive;
  final bool isPaused;
  final String? exerciseName;

  RestTimerState({
    required this.remainingSeconds,
    this.isActive = false,
    this.isPaused = false,
    this.exerciseName,
  });

  RestTimerState copyWith({
    int? remainingSeconds,
    bool? isActive,
    bool? isPaused,
    String? exerciseName,
  }) {
    return RestTimerState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isActive: isActive ?? this.isActive,
      isPaused: isPaused ?? this.isPaused,
      exerciseName: exerciseName ?? this.exerciseName,
    );
  }
}

class RestTimerNotifier extends Notifier<RestTimerState> {
  Timer? _timer;
  int? _targetEndTimeEpoch;
  Future<void> _notificationQueue = Future.value();
  Future<void> _storageQueue = Future.value();
  int _revision = 0;
  bool _disposed = false;

  @override
  RestTimerState build() {
    ref.watch(accountGenerationProvider);
    _disposed = false;
    _revision++;
    _timer?.cancel();
    _targetEndTimeEpoch = null;
    final transitioning = ref.watch(accountTransitionProvider);
    if (transitioning) _cancelNotification();
    ref.onDispose(() {
      _disposed = true;
      _revision++;
      _timer?.cancel();
    });
    final revision = _revision;
    Future.microtask(() {
      if (!_disposed && !transitioning && revision == _revision)
        _loadPersistedTimer();
    });
    ref.listen(profileProvider, (previous, next) {
      if (!state.isActive || state.isPaused) return;
      if (next.restTimerNotification) {
        _scheduleNotification(state.remainingSeconds, state.exerciseName);
      } else {
        _cancelNotification();
      }
    });
    return RestTimerState(remainingSeconds: 0);
  }

  Future<void> _scheduleNotification(int seconds, String? exerciseName) {
    final profile = ref.read(profileProvider);
    final revision = ++_revision;
    final accountGeneration = ref.read(accountGenerationProvider);
    final service = ref.read(notificationServiceProvider);
    final deadline = _targetEndTimeEpoch;
    _notificationQueue = _notificationQueue.catchError((Object _) {}).then((
      _,
    ) async {
      if (_disposed ||
          revision != _revision ||
          accountGeneration != ref.read(accountGenerationProvider))
        return;
      await service.cancelRestTimer();
      if (_disposed || revision != _revision || !profile.restTimerNotification)
        return;
      final remaining = deadline == null
          ? seconds
          : ((deadline - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
      if (remaining <= 0) return;
      final delivery = await service.scheduleRestTimer(
        remaining,
        exerciseName,
        playSound: profile.restTimerSound,
        enableVibration: profile.restTimerVibration,
      );
      if (_disposed || revision != _revision) return;
      if (delivery == RestTimerDelivery.approximate) {
        ref.read(reminderErrorProvider.notifier).state =
            'Android may delay background rest alerts. The in-app timer remains accurate.';
      } else if (delivery == RestTimerDelivery.unavailable) {
        ref.read(reminderErrorProvider.notifier).state =
            'The background rest alert could not be scheduled. Keep the app open for the timer.';
      }
    });
    return _notificationQueue;
  }

  void _cancelNotification() {
    ++_revision;
    final service = ref.read(notificationServiceProvider);
    _notificationQueue = _notificationQueue
        .catchError((Object _) {})
        .then((_) => service.cancelRestTimer());
  }

  void _loadPersistedTimer() {
    final prefs = ref.read(sharedPreferencesProvider);
    if (state.isActive) return;
    final key = 'rest_timer_v2_${ref.read(activeAccountIdProvider)}';
    var saved = prefs.getString(key);
    if (saved == null && !(prefs.getBool('rest_timer_v2_migrated') ?? false)) {
      final end = prefs.getInt(kTimerEndTimeKey);
      final remaining = prefs.getInt(kTimerRemainingKey);
      if (end != null || remaining != null)
        saved = jsonEncode({
          'end': end,
          'remaining': remaining,
          'paused': prefs.getBool(kTimerIsPausedKey) ?? false,
          'exercise': prefs.getString(kTimerExerciseKey),
        });
      unawaited(prefs.setBool('rest_timer_v2_migrated', true));
      for (final legacy in [
        kTimerEndTimeKey,
        kTimerRemainingKey,
        kTimerIsPausedKey,
        kTimerExerciseKey,
      ]) {
        unawaited(prefs.remove(legacy));
      }
    }
    try {
      final value = jsonDecode(saved ?? '{}') as Map<String, dynamic>;
      final paused = value['paused'] == true;
      final end = value['end'] is int ? value['end'] as int : null;
      final remaining = paused
          ? (value['remaining'] is int ? value['remaining'] as int : 0)
          : end == null
          ? 0
          : ((end - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
      if (remaining <= 0) {
        _clearPersistedTimer();
        return;
      }
      _targetEndTimeEpoch = end;
      state = RestTimerState(
        remainingSeconds: remaining,
        isActive: true,
        isPaused: paused,
        exerciseName: value['exercise'] is String
            ? value['exercise'] as String
            : null,
      );
      if (!paused) _startInternalTimer();
    } catch (_) {
      _clearPersistedTimer();
    }
  }

  Future<void> _persistTimer() {
    final prefs = ref.read(sharedPreferencesProvider);
    final key = 'rest_timer_v2_${ref.read(activeAccountIdProvider)}';
    final snapshot = state.isActive
        ? jsonEncode({
            'end': _targetEndTimeEpoch,
            'remaining': state.remainingSeconds,
            'paused': state.isPaused,
            'exercise': state.exerciseName,
          })
        : null;
    _storageQueue = _storageQueue.catchError((Object _) {}).then((_) async {
      if (snapshot == null) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, snapshot);
      }
    });
    return _storageQueue;
  }

  Future<void> _clearPersistedTimer() {
    final prefs = ref.read(sharedPreferencesProvider);
    final key = 'rest_timer_v2_${ref.read(activeAccountIdProvider)}';
    _storageQueue = _storageQueue.catchError((Object _) {}).then((_) async {
      await prefs.remove(key);
    });
    return _storageQueue;
  }

  void startTimer(int seconds, {String? exerciseName}) {
    if (seconds <= 0) {
      stopTimer();
      return;
    }
    _revision++;
    _timer?.cancel();
    _targetEndTimeEpoch =
        DateTime.now().millisecondsSinceEpoch + (seconds * 1000);
    state = RestTimerState(
      remainingSeconds: seconds,
      isActive: true,
      isPaused: false,
      exerciseName: exerciseName,
    );
    _persistTimer();
    _startInternalTimer();

    final profile = ref.read(profileProvider);
    if (profile.restTimerNotification) {
      _scheduleNotification(seconds, exerciseName);
    }
  }

  void _startInternalTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_targetEndTimeEpoch != null) {
        final remaining =
            ((_targetEndTimeEpoch! - DateTime.now().millisecondsSinceEpoch) /
                    1000)
                .ceil();
        if (remaining > 0) {
          if (remaining <= 3 && ref.read(profileProvider).restTimerVibration) {
            Haptics.toggle();
          }
          state = state.copyWith(remainingSeconds: remaining);
        } else {
          _onTimerComplete();
        }
      }
    });
  }

  void _onTimerComplete() {
    _timer?.cancel();
    _cancelNotification();
    final completedExercise = state.exerciseName;
    state = RestTimerState(
      remainingSeconds: 0,
      isActive: false,
      isPaused: false,
    );
    _clearPersistedTimer();

    // Trigger feedback based on profile settings
    final profile = ref.read(profileProvider);
    if (profile.restTimerVibration) {
      Haptics.success();
    }
    if (profile.restTimerSound) {
      SystemSound.play(SystemSoundType.alert);
    }

    // Show Snackbar if context is available
    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.timer_off_rounded, color: context.colors.accentText),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rest complete',
                      style: context.text.body.copyWith(
                        color: context.colors.textDark,
                      ),
                    ),
                    if (completedExercise != null)
                      Text(
                        'Time for $completedExercise',
                        style: context.text.micro.copyWith(
                          color: context.colors.textMedium,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void stopTimer() {
    _timer?.cancel();
    _cancelNotification();
    state = state.copyWith(
      isActive: false,
      isPaused: false,
      remainingSeconds: 0,
    );
    _clearPersistedTimer();
  }

  void pauseTimer() {
    if (state.isActive && !state.isPaused) {
      _timer?.cancel();
      _cancelNotification();
      state = state.copyWith(isPaused: true);
      _persistTimer();
    }
  }

  void resumeTimer() {
    if (state.isActive && state.isPaused) {
      _targetEndTimeEpoch =
          DateTime.now().millisecondsSinceEpoch +
          (state.remainingSeconds * 1000);
      state = state.copyWith(isPaused: false);
      _persistTimer();
      _startInternalTimer();
      final profile = ref.read(profileProvider);
      if (profile.restTimerNotification) {
        _scheduleNotification(state.remainingSeconds, state.exerciseName);
      }
    }
  }

  void addSeconds(int seconds) {
    if (state.isActive) {
      final newRemaining = state.remainingSeconds + seconds;
      if (newRemaining <= 0) {
        stopTimer();
        return;
      }
      if (state.isPaused) {
        state = state.copyWith(remainingSeconds: newRemaining);
      } else {
        _targetEndTimeEpoch =
            (_targetEndTimeEpoch ?? DateTime.now().millisecondsSinceEpoch) +
            (seconds * 1000);
        state = state.copyWith(remainingSeconds: newRemaining);
        final profile = ref.read(profileProvider);
        if (profile.restTimerNotification) {
          _scheduleNotification(newRemaining, state.exerciseName);
        }
      }
      _persistTimer();
    }
  }

  // Note: Notifier automatically handles disposal in Riverpod, but we can override it if we want.
  // Actually, we should hook into ref.onDispose instead of overriding dispose().
}

final restTimerProvider = NotifierProvider<RestTimerNotifier, RestTimerState>(
  () {
    return RestTimerNotifier();
  },
);
