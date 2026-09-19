import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_providers.dart';

import '../models/habit.dart';
import '../models/daily_log.dart';

final habitDefinitionsUpdateProvider = StreamProvider<void>((ref) {
  ref.watch(accountGenerationProvider);
  return ref.watch(activeDatabaseProvider)?.habits.watchLazy() ??
      const Stream.empty();
});

final allHabitsProvider = Provider<List<Habit>>((ref) {
  ref.watch(accountGenerationProvider);
  ref.watch(habitDefinitionsUpdateProvider);
  return ref.watch(habitRepoProvider).getHabits();
});

final habitsProvider = Provider<List<Habit>>((ref) {
  ref.watch(accountGenerationProvider);
  final habits = ref.watch(allHabitsProvider);
  final dateStr = ref.watch(dateStringProvider);
  final date = DateTime.parse(dateStr);

  return habits.where((h) => isHabitScheduledOn(h, date)).toList();
});

class HabitCompletionsNotifier extends Notifier<HabitCompletion> {
  @override
  HabitCompletion build() {
    ref.watch(accountGenerationProvider);
    final repo = ref.watch(habitRepoProvider);
    final date = ref.watch(dateStringProvider);

    final sub = repo.watchCompletions(date).listen((completion) {
      state = completion ?? repo.getCompletions(date);
    });

    ref.onDispose(() => sub.cancel());

    return repo.getCompletions(date);
  }

  Future<void> toggle(String habitId) async {
    final repo = ref.read(habitRepoProvider);
    final date = ref.read(dateStringProvider);
    await repo.toggleCheckboxCompletion(date, habitId);
    state = repo.getCompletions(date);
  }

  Future<void> updateProgress(String habitId, double progress) async {
    final repo = ref.read(habitRepoProvider);
    final date = ref.read(dateStringProvider);
    await repo.updateProgress(date, habitId, progress);
    state = repo.getCompletions(date);
  }

  Future<void> setOverride(String habitId, String? overrideValue) async {
    final date = ref.read(dateStringProvider);
    await setOverrideForDate(date, habitId, overrideValue);
  }

  Future<void> setOverrideForDate(
    String date,
    String habitId,
    String? overrideValue,
  ) async {
    final repo = ref.read(habitRepoProvider);
    await repo.setOverride(date, habitId, overrideValue);

    final currentDate = ref.read(dateStringProvider);
    if (date == currentDate) {
      state = repo.getCompletions(date);
    }
  }
}

final habitCompletionsProvider =
    NotifierProvider<HabitCompletionsNotifier, HabitCompletion>(
      HabitCompletionsNotifier.new,
    );

final habitStreakProvider = Provider.family<int, String>((ref, habitId) {
  ref.watch(accountGenerationProvider);
  ref.watch(yearlyActivityChangesProvider);
  ref.watch(dailyLogsUpdateProvider);
  ref.watch(habitCompletionsProvider);
  final habit = ref
      .watch(allHabitsProvider)
      .where((h) => h.id == habitId)
      .firstOrNull;
  if (habit == null || habit.activeDays?.isEmpty == true) return 0;
  final now = ref.watch(clockProvider);
  final selected = DateTime.tryParse(ref.watch(dateStringProvider)) ?? now;
  var day = selected.isAfter(now)
      ? DateTime(now.year, now.month, now.day)
      : DateTime(selected.year, selected.month, selected.day);
  final repo = ref.watch(habitRepoProvider);
  final dailyRepo = ref.watch(dailyLogRepoProvider);
  final creation = habit.createdAt.toLocal();
  final firstDay = DateTime(creation.year, creation.month, creation.day);
  var streak = 0;
  final endDay = day;
  while (!day.isBefore(firstDay)) {
    if (isHabitScheduledOn(habit, day)) {
      final key =
          '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final completion = repo.getCompletions(key);
      final log = dailyRepo.getLog(key) ?? DailyLog(date: key);
      if (isHabitCompleted(habit, completion, log)) {
        streak++;
      } else if (day != endDay ||
          endDay != DateTime(now.year, now.month, now.day)) {
        break;
      }
    }
    day = DateTime(day.year, day.month, day.day - 1);
  }
  return streak;
});
