import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trufit_bodamma/providers/app_providers.dart';
import 'package:trufit_bodamma/repositories/daily_log_repository.dart';
import 'package:trufit_bodamma/repositories/habit_repository.dart';
import 'package:trufit_bodamma/models/daily_log.dart';
import 'package:trufit_bodamma/models/habit.dart';

// Fake repositories for testing without Hive
class FakeHabitRepository extends HabitRepository {
  final Map<String, HabitCompletion> completions = {};
  final List<Habit> _habits = [
    Habit.defaults.firstWhere((h) => h.id == 'water'),
  ];

  @override
  HabitCompletion getCompletions(String date) {
    return completions[date] ?? HabitCompletion(date: date);
  }

  @override
  List<Habit> getHabits() => _habits;

  @override
  Stream<HabitCompletion?> watchCompletions(String date) async* {
    yield getCompletions(date);
  }
}

class FakeDailyLogRepository extends DailyLogRepository {
  final Map<String, DailyLog> logs = {};

  @override
  DailyLog? getLog(String date) {
    return logs[date];
  }
}

void main() {
  test('habitStreakProvider calculates streak correctly', () {
    final habitRepo = FakeHabitRepository();
    final dailyLogRepo = FakeDailyLogRepository();

    // Simulate completions
    habitRepo.completions['2023-10-05'] = HabitCompletion(
      date: '2023-10-05',
      completions: {'water': true},
    );
    habitRepo.completions['2023-10-04'] = HabitCompletion(
      date: '2023-10-04',
      completions: {'water': true},
    );
    habitRepo.completions['2023-10-03'] = HabitCompletion(
      date: '2023-10-03',
      completions: {'water': true},
    );
    habitRepo.completions['2023-10-02'] = HabitCompletion(
      date: '2023-10-02',
      completions: {'water': false},
    ); // missed

    final container = ProviderContainer(
      overrides: [
        habitRepoProvider.overrideWithValue(habitRepo),
        dailyLogRepoProvider.overrideWithValue(dailyLogRepo),
        dateStringProvider.overrideWith((ref) => '2023-10-05'),
      ],
    );

    final streak = container.read(habitStreakProvider('water'));
    expect(streak, 3); // 5th, 4th, 3rd = 3 days
  });

  test(
    'habitStreakProvider calculates streak with overrides (e.g. rest day)',
    () {
      final habitRepo = FakeHabitRepository();
      final dailyLogRepo = FakeDailyLogRepository();

      habitRepo.completions['2023-10-05'] = HabitCompletion(
        date: '2023-10-05',
        completions: {'water': true},
      );
      habitRepo.completions['2023-10-04'] = HabitCompletion(
        date: '2023-10-04',
        overrides: {'water': 'done'},
      ); // Rest day override
      habitRepo.completions['2023-10-03'] = HabitCompletion(
        date: '2023-10-03',
        completions: {'water': true},
      );

      final container = ProviderContainer(
        overrides: [
          habitRepoProvider.overrideWithValue(habitRepo),
          dailyLogRepoProvider.overrideWithValue(dailyLogRepo),
          dateStringProvider.overrideWith((ref) => '2023-10-05'),
        ],
      );

      final streak = container.read(habitStreakProvider('water'));
      expect(streak, 3);
    },
  );
}
