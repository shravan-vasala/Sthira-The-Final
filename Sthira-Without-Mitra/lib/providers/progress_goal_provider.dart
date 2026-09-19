import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import 'app_providers.dart';

final progressHabitHistoryUpdatesProvider = StreamProvider.autoDispose<void>((
  ref,
) {
  ref.watch(accountGenerationProvider);
  return ref
          .watch(activeDatabaseProvider)
          ?.habitCompletions
          .watchLazy(fireImmediately: true) ??
      const Stream<void>.empty();
});

class ProgressHabitGoal {
  const ProgressHabitGoal({this.value, this.context});
  final double? value;
  final String? context;

  static ProgressHabitGoal resolve(
    List<Habit> habits,
    HabitType type,
    DateTime today,
  ) {
    final cutoff = DateTime(today.year, today.month, today.day + 1);
    final matching = habits
        .where(
          (habit) =>
              habit.type == type &&
              habit.createdAt.isBefore(cutoff) &&
              (habit.activeDays == null || habit.activeDays!.isNotEmpty) &&
              habit.target.isFinite &&
              habit.target > 0,
        )
        .toList();
    if (matching.isEmpty) return const ProgressHabitGoal();
    if (matching.any((habit) => habit.goalDirection != GoalDirection.atLeast)) {
      return const ProgressHabitGoal(
        context:
            'Your habits use different goal rules. No single reference goal is shown.',
      );
    }
    final targets = matching.map((habit) => habit.target).toSet();
    if (targets.length != 1) {
      return const ProgressHabitGoal(
        context:
            'Your targets vary by habit or day. No single reference goal is shown.',
      );
    }
    return ProgressHabitGoal(value: targets.single);
  }
}

final progressHabitGoalProvider = Provider.autoDispose
    .family<ProgressHabitGoal, HabitType>((ref, type) {
      final habits = ref.watch(allHabitsProvider);
      return ProgressHabitGoal.resolve(habits, type, ref.watch(clockProvider));
    });
