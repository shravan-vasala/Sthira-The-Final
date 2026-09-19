import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_log.dart';

import '../models/habit.dart';
import '../services/health_connect_service.dart';
import 'app_providers.dart';

class DailyLogNotifier extends Notifier<DailyLog> {
  StreamSubscription? _sub;
  int _generation = 0;

  @override
  DailyLog build() {
    final generation = ++_generation;
    ref.watch(accountGenerationProvider);
    final repo = ref.watch(dailyLogRepoProvider);
    final date = ref.watch(dateStringProvider);

    ref.onDispose(() {
      _generation++;
      _sub?.cancel();
    });

    _sub?.cancel();
    _sub = repo.watchLog(date).listen((log) {
      if (generation != _generation) return;
      state = log ?? repo.getOrCreate(date);
    });

    return repo.getOrCreate(date);
  }

  Future<void> updateWeight(double weight) async {
    await updateWeightForDate(state.date, weight);
  }

  Future<void> updateWeightForDate(String date, double weight) async {
    final generation = _generation;
    final repo = ref.read(dailyLogRepoProvider);
    await repo.updateWeight(date, weight);
    if (generation != _generation) return;
    if (state.date == date) {
      state = repo.getOrCreate(date);
    }
  }

  Future<void> updateSteps(int steps, {String? source}) async {
    await updateStepsForDate(state.date, steps, source: source);
  }

  Future<void> updateStepsForDate(
    String date,
    int steps, {
    String? source,
  }) async {
    final generation = _generation;
    final repo = ref.read(dailyLogRepoProvider);
    await repo.updateSteps(date, steps, source: source ?? 'manual');
    if (generation != _generation) return;
    if (state.date == date) {
      state = repo.getOrCreate(date);
    }
    ref.read(stepsSourceProvider.notifier).state = (source == 'healthConnect')
        ? StepsSource.healthConnect
        : StepsSource.manual;
  }

  Future<void> clearStepsForDate(String date) async {
    final generation = _generation;
    final repo = ref.read(dailyLogRepoProvider);
    await repo.clearSteps(date);
    if (generation != _generation) return;
    if (state.date == date) {
      state = repo.getOrCreate(date);
    }
    ref.read(stepsSourceProvider.notifier).state = StepsSource.manual;
  }

  Future<void> updateSleep(double hours, {String? source}) async {
    await updateSleepForDate(state.date, hours, source: source);
  }

  Future<void> updateSleepForDate(
    String date,
    double hours, {
    String? source,
  }) async {
    final generation = _generation;
    final repo = ref.read(dailyLogRepoProvider);
    await repo.updateSleep(date, hours, source: source ?? 'manual');
    if (generation != _generation) return;
    if (state.date == date) {
      state = repo.getOrCreate(date);
    }

    final habitRepo = ref.read(habitRepoProvider);
    final allHabits = habitRepo.getHabits();
    for (final habit in allHabits.where((h) => h.type == HabitType.autoSleep)) {
      if (hours >= habit.target) {
        await habitRepo.setCompletion(date, habit.id, true);
        if (generation != _generation) return;
      } else {
        final current = habitRepo.getCompletions(date).completions[habit.id];
        if (current != true) {
          await habitRepo.setCompletion(date, habit.id, false);
          if (generation != _generation) return;
        }
      }
    }
    if (state.date == date) {
      ref.invalidate(habitCompletionsProvider);
    }
  }

  Future<void> clearSleep() async {
    await clearSleepForDate(state.date);
  }

  Future<void> clearSleepForDate(String date) async {
    final generation = _generation;
    final repo = ref.read(dailyLogRepoProvider);
    await repo.clearSleep(date);
    if (generation != _generation) return;
    if (state.date == date) {
      state = repo.getOrCreate(date);
    }

    final habitRepo = ref.read(habitRepoProvider);
    final allHabits = habitRepo.getHabits();
    for (final habit in allHabits.where((h) => h.type == HabitType.autoSleep)) {
      final current = habitRepo.getCompletions(date).completions[habit.id];
      if (current != true) {
        await habitRepo.setCompletion(date, habit.id, false);
        if (generation != _generation) return;
      }
    }
    if (state.date == date) {
      ref.invalidate(habitCompletionsProvider);
    }
  }

  Future<void> updateBodyFat(double bodyFat) async {
    await updateBodyFatForDate(state.date, bodyFat);
  }

  Future<void> updateBodyFatForDate(String date, double bodyFat) async {
    final generation = _generation;
    final repo = ref.read(dailyLogRepoProvider);
    await repo.updateBodyFat(date, bodyFat);
    if (generation != _generation) return;
    if (state.date == date) {
      state = repo.getOrCreate(date);
    }
  }

  Future<void> clearBodyFatForDate(String date) async {
    final generation = _generation;
    final repo = ref.read(dailyLogRepoProvider);
    await repo.clearBodyFat(date);
    if (generation != _generation) return;
    if (state.date == date) {
      state = repo.getOrCreate(date);
    }
  }

  Future<void> updateWater(int waterMl) async {
    await updateWaterForDate(state.date, waterMl);
  }

  Future<void> updateWaterForDate(String date, int waterMl) async {
    final generation = _generation;
    final repo = ref.read(dailyLogRepoProvider);
    await repo.updateWater(date, waterMl);
    if (generation != _generation) return;
    if (state.date == date) {
      state = repo.getOrCreate(date);
    }

    final habitRepo = ref.read(habitRepoProvider);
    final allHabits = habitRepo.getHabits();
    final waterHabit = allHabits.where((h) => h.id == 'water').firstOrNull;
    if (waterHabit != null) {
      double targetInMl = waterHabit.target.toDouble();
      if (waterHabit.unit.toLowerCase() == 'l' ||
          waterHabit.unit.toLowerCase() == 'liters') {
        targetInMl *= 1000;
      }
      if (targetInMl.isFinite && targetInMl > 0) {
        final complete = waterHabit.goalDirection == GoalDirection.atMost
            ? waterMl <= targetInMl
            : waterMl >= targetInMl;
        await habitRepo.setCompletion(date, waterHabit.id, complete);
        if (generation != _generation) return;
      }
    }
    if (state.date == date) {
      ref.invalidate(habitCompletionsProvider);
    }
  }

  Future<void> clearWater() async {
    await clearWaterForDate(state.date);
  }

  Future<void> clearWaterForDate(String date) async {
    final generation = _generation;
    final repo = ref.read(dailyLogRepoProvider);
    await repo.clearWater(date);
    if (generation != _generation) return;
    if (state.date == date) {
      state = repo.getOrCreate(date);
    }

    final habitRepo = ref.read(habitRepoProvider);
    final waterHabit = habitRepo
        .getHabits()
        .where((h) => h.id == 'water')
        .firstOrNull;
    if (waterHabit != null) {
      await habitRepo.clearCompletion(date, waterHabit.id);
      if (generation != _generation) return;
    }
    if (state.date == date) {
      ref.invalidate(habitCompletionsProvider);
    }
  }

  Future<void> updateWorkoutStatus(String dayId, String status) async {
    final generation = _generation;
    final repo = ref.read(dailyLogRepoProvider);
    await repo.updateWorkoutStatus(state.date, dayId, status);
    if (generation != _generation) return;
    state = repo.getOrCreate(state.date);

    final profile = ref.read(profileProvider);
    if (profile.planStartDate == null) {
      final now = DateTime.now();
      // ignore: unawaited_futures
      ref
          .read(profileProvider.notifier)
          .updateProfile(
            profile.copyWith(
              planStartDate: DateTime(now.year, now.month, now.day),
            ),
          );
    }
  }
}

final dailyLogProvider = NotifierProvider<DailyLogNotifier, DailyLog>(() {
  return DailyLogNotifier();
});

final dailyLogsRangeProvider =
    Provider.family<List<DailyLog>, (String, String)>((ref, range) {
      ref.watch(dailyLogsUpdateProvider);
      final (start, end) = range;
      ref.watch(accountGenerationProvider);
      return ref.watch(dailyLogRepoProvider).getLogsInRange(start, end);
    });
