import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_providers.dart';
import '../models/meal_plan.dart';
import '../models/daily_meal_log.dart';

final mealPlanProvider = Provider<MealPlan?>((ref) {
  ref.watch(planRecordsUpdateProvider);
  ref.watch(accountGenerationProvider);
  final repo = ref.watch(mealRepoProvider);
  final profile = ref.watch(profileProvider);

  final activePlanId = profile.activeMealPlan ?? repo.defaultPlanName;
  MealPlan? plan = repo.getMealPlan(activePlanId);
  if (plan == null && repo.defaultPlanName != activePlanId) {
    plan = repo.getMealPlan(repo.defaultPlanName);
  }
  return plan;
});

class DailyMealLogNotifier extends Notifier<DailyMealLog> {
  int _generation = 0;

  @override
  DailyMealLog build() {
    final generation = ++_generation;
    ref.watch(accountGenerationProvider);
    final repo = ref.watch(mealRepoProvider);
    final date = ref.watch(dateStringProvider);

    final sub = repo.watchDailyLog(date).listen((log) {
      if (generation != _generation) return;
      state = log ?? repo.getDailyLog(date);
    });

    ref.onDispose(() {
      _generation++;
      unawaited(sub.cancel());
    });

    return repo.getDailyLog(date);
  }

  Future<void> saveMealSlot(
    String slotName,
    MealSlotLog slotLog, {
    String? targetDate,
  }) async {
    final repo = ref.read(mealRepoProvider);
    final String date = targetDate ?? ref.read(dateStringProvider);
    final generation = _generation;
    await repo.saveMealSlot(date, slotName, slotLog);
    if (generation != _generation) return;
    if (state.date == date) {
      state = repo.getDailyLog(date);
    }
  }

  Future<void> appendMealItem(
    String slotId,
    MealItemLog item, {
    String? targetDate,
    String? slotName,
    String? slotEmoji,
  }) async {
    final repo = ref.read(mealRepoProvider);
    final String date = targetDate ?? ref.read(dateStringProvider);
    final generation = _generation;
    await repo.appendMealItem(
      date,
      slotId,
      item,
      slotName: slotName,
      slotEmoji: slotEmoji,
    );
    // The durable append succeeded even if navigation/account changes disposed
    // or rebuilt this provider while it was saving. Do not invite a retry.
    if (generation != _generation) return;
    if (state.date == date) {
      state = repo.getDailyLog(date);
    }
  }

  Future<void> clearMealSlot(String slotName, {String? targetDate}) async {
    final repo = ref.read(mealRepoProvider);
    final String date = targetDate ?? ref.read(dateStringProvider);
    final generation = _generation;
    await repo.clearMealSlot(date, slotName);
    if (generation != _generation) return;
    if (state.date == date) {
      state = repo.getDailyLog(date);
    }
  }
}

final dailyMealLogProvider =
    NotifierProvider<DailyMealLogNotifier, DailyMealLog>(
      DailyMealLogNotifier.new,
    );

final dailyMealLogsRangeProvider =
    Provider.family<List<DailyMealLog>, (String, String)>((ref, range) {
      ref.watch(dailyMealLogsUpdateProvider);
      final (start, end) = range;
      ref.watch(accountGenerationProvider);
      final mealRepo = ref.watch(mealRepoProvider);
      return mealRepo.getLogsInRange(start, end);
    });
