import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_providers.dart';
import 'midnight_tick_provider.dart';
import '../services/screen_time_service.dart';
import '../services/health_connect_service.dart';
import '../utils/time_utils.dart';

final syncControllerProvider = NotifierProvider<SyncController, bool>(
  SyncController.new,
);
final healthSyncErrorProvider = StateProvider<String?>((ref) => null);

class SyncController extends Notifier<bool> with WidgetsBindingObserver {
  Future<void>? _pending;
  int? _runningGeneration;
  bool _disposed = false;

  @override
  bool build() {
    _disposed = false;
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      _disposed = true;
      WidgetsBinding.instance.removeObserver(this);
    });
    return false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.resumed) {
      ref.read(midnightTickProvider.notifier).refresh();
      unawaited(sync());
    } else if (lifecycle == AppLifecycleState.paused) {
      unawaited(ref.read(firestoreSyncServiceProvider).flushNow());
    }
  }

  Future<void> sync({
    bool isManualRefresh = false,
    String? explicitTargetDate,
  }) {
    // Every entry point (including the connect CTA) awaits the same job.
    // A request for the newly rebound account must run after the old job drains.
    final pending = _pending;
    if (pending != null) {
      final generation = ref.read(accountGenerationProvider);
      if (_runningGeneration != generation || isManualRefresh) {
        return pending.then(
          (_) => _disposed
              ? Future<void>.value()
              : sync(
                  isManualRefresh: isManualRefresh,
                  explicitTargetDate: explicitTargetDate,
                ),
        );
      }
      return pending;
    }
    if (ref.read(accountTransitionProvider)) return Future<void>.value();
    _runningGeneration = ref.read(accountGenerationProvider);
    return _pending = _run(
      isManualRefresh,
      explicitTargetDate,
    ).whenComplete(() => _pending = null);
  }

  Future<void> _run(bool manual, String? explicitDate) async {
    final generation = ref.read(accountGenerationProvider);
    final account = ref.read(activeAccountIdProvider);
    bool current() =>
        !_disposed &&
        !ref.read(accountTransitionProvider) &&
        generation == ref.read(accountGenerationProvider) &&
        account == ref.read(activeAccountIdProvider);
    state = true;
    try {
      final health = ref.read(healthConnectServiceProvider);
      final repository = ref.read(dailyLogRepoProvider);
      final prefs = ref.read(sharedPreferencesProvider);
      final now = DateTime.now();
      final today = todayKey(now);
      final prefix = 'health_${account}_';
      Future<void> persist(List<HealthDailyData> data) async {
        if (current())
          await repository.updateFromHealthConnect(data, isCurrent: current);
      }

      if (ref.read(dateStringProvider) == today) {
        unawaited(ref.read(coachNoteProvider.notifier).fetchNote(force: false));
      }
      if (ref.read(profileProvider).screenTimeEnabled) {
        final screenTime = ref.read(screenTimeServiceProvider);
        final result = await screenTime.getScreenTimeForToday();
        if (!current()) return;
        if (result.isValidSuccess)
          await repository.updateScreenTime(
            result.measuredDate!,
            result.minutes!,
          );
        if (!current()) return;
        final yesterday = todayKey(DateTime(now.year, now.month, now.day - 1));
        if (prefs.getString('${prefix}screen_time_closed_day') != yesterday) {
          final closedDay = await screenTime.getScreenTimeForDate(yesterday);
          if (!current()) return;
          if (closedDay.isValidSuccess && closedDay.measuredDate == yesterday) {
            await repository.updateScreenTime(yesterday, closedDay.minutes!);
            if (!current()) return;
            await prefs.setString('${prefix}screen_time_closed_day', yesterday);
          }
        }
      }
      if (!await health.isAvailable() || !current()) return;
      await prefs.setString('${prefix}last_attempt', now.toIso8601String());
      if (!current()) return;
      final todayData = await health.syncToday();
      if (!current()) return;
      if (todayData == null) {
        if (manual)
          ref.read(healthSyncErrorProvider.notifier).state =
              'Health Connect could not be read. Check access and try again.';
        return;
      }
      await persist([todayData]);
      if (!current()) return;
      ref.read(healthSyncErrorProvider.notifier).state = null;
      if (todayData.stepsResult.status == HealthStatus.success)
        ref.read(stepsSourceProvider.notifier).state =
            StepsSource.healthConnect;
      await prefs.setString('${prefix}today_sync', now.toIso8601String());
      final lastSync = DateTime.tryParse(
        prefs.getString('${prefix}history_sync') ?? '',
      );
      if (manual ||
          lastSync == null ||
          now.difference(lastSync).inMinutes >= 15) {
        var complete = true;
        final recent = <HealthDailyData>[];
        for (var i = 1; i < 7 && current(); i++) {
          final data = await health.readDate(
            DateTime(now.year, now.month, now.day - i),
          );
          recent.add(data);
          complete &=
              data.stepsResult.status != HealthStatus.error &&
              data.sleepResult.status != HealthStatus.error;
        }
        await persist(recent);
        if (!current()) return;
        await health.backfillInBatches(
          persist: persist,
          isCurrent: current,
          requestAccess: manual,
        );
        if (!current()) return;
        if (complete)
          await prefs.setString('${prefix}history_sync', now.toIso8601String());
      }
      final requested = DateTime.tryParse(explicitDate ?? '');
      if (manual && requested != null && !requested.isAfter(now)) {
        final days = DateTime.utc(now.year, now.month, now.day)
            .difference(
              DateTime.utc(requested.year, requested.month, requested.day),
            )
            .inDays;
        if (days > 6 && days <= 90 && current())
          await persist([await health.readDate(requested)]);
      }
      if (current()) {
        ref.invalidate(dailyLogProvider);
        ref.invalidate(habitCompletionsProvider);
      }
    } catch (_) {
      if (current())
        ref.read(healthSyncErrorProvider.notifier).state =
            'Some device data could not be refreshed. Your saved entries are safe; try again.';
    } finally {
      if (!_disposed) state = false;
    }
  }
}
