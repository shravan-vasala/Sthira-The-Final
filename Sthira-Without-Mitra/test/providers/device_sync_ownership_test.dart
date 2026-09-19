import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trufit_bodamma/models/user_profile.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/services/health_connect_service.dart';
import 'package:trufit_bodamma/services/screen_time_service.dart';
import 'package:trufit_bodamma/repositories/daily_log_repository.dart';
import 'package:trufit_bodamma/utils/time_utils.dart';

class _Profile extends ProfileNotifier {
  @override
  UserProfile build() => UserProfile(screenTimeEnabled: true);
}

class _Daily extends DailyLogRepository {
  final writes = <String>[];
  @override
  Future<void> updateScreenTime(String date, int minutes) async {
    writes.add('usage:$date:$minutes');
  }

  @override
  Future<void> updateFromHealthConnect(
    List<HealthDailyData> data, {
    bool Function()? isCurrent,
  }) async {
    if (isCurrent?.call() ?? true) writes.add('health:${data.first.dateStr}');
  }
}

class _Screen extends ScreenTimeService {
  @override
  Future<ScreenTimeResult> getScreenTimeForToday() async => ScreenTimeResult(
    status: 'success',
    minutes: 123,
    measuredDate: todayKey(),
  );
  @override
  Future<ScreenTimeResult> getScreenTimeForDate(String date) async =>
      ScreenTimeResult(status: 'success', minutes: 345, measuredDate: date);
}

class _Health extends HealthConnectService {
  int requests = 0;
  final Completer<HealthDailyData?> pending = Completer();
  final bool available;
  _Health({this.available = true});
  @override
  Future<bool> isAvailable() async => available;
  @override
  Future<HealthDailyData?> syncToday() {
    requests++;
    return pending.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<ProviderContainer> setup(_Daily repository, _Health health) async {
    SharedPreferences.setMockInitialValues({
      'health_guest_history_sync': DateTime.now().toIso8601String(),
    });
    return ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        dailyLogRepoProvider.overrideWithValue(repository),
        profileProvider.overrideWith(_Profile.new),
        activeAccountIdProvider.overrideWithValue('guest'),
        selectedDateProvider.overrideWith((ref) => DateTime(2000)),
        healthConnectServiceProvider.overrideWithValue(health),
        screenTimeServiceProvider.overrideWithValue(_Screen()),
      ],
    );
  }

  test(
    'guest usage readings and last completed native day are persisted',
    () async {
      final repository = _Daily();
      final container = await setup(repository, _Health(available: false));
      addTearDown(container.dispose);
      await container.read(syncControllerProvider.notifier).sync();
      expect(repository.writes, hasLength(2));
      expect(repository.writes.first, 'usage:${todayKey()}:123');
      expect(repository.writes.last, endsWith(':345'));
    },
  );
  test(
    'a health read cannot write after the account generation changes',
    () async {
      final repository = _Daily(), health = _Health();
      final container = await setup(repository, health);
      addTearDown(container.dispose);
      final pending = container.read(syncControllerProvider.notifier).sync();
      await Future<void>.delayed(Duration.zero);
      expect(health.requests, 1);
      container.read(accountGenerationProvider.notifier).state++;
      health.pending.complete(
        HealthDailyData(
          dateStr: todayKey(),
          stepsResult: HealthReadResult.success(100),
          sleepResult: HealthReadResult.empty(),
        ),
      );
      await pending;
      expect(
        repository.writes.where((entry) => entry.startsWith('health')),
        isEmpty,
      );
    },
  );
  test(
    'simultaneous refresh callers share one device health request',
    () async {
      final repository = _Daily(), health = _Health();
      final container = await setup(repository, health);
      addTearDown(container.dispose);
      final controller = container.read(syncControllerProvider.notifier);
      final first = controller.sync();
      final second = controller.sync();
      await Future<void>.delayed(Duration.zero);
      expect(health.requests, 1);
      health.pending.complete(
        HealthDailyData(
          dateStr: todayKey(),
          stepsResult: HealthReadResult.success(100),
          sleepResult: HealthReadResult.empty(),
        ),
      );
      await Future.wait([first, second]);
      expect(
        repository.writes.where((entry) => entry.startsWith('health')),
        hasLength(1),
      );
    },
  );
}
