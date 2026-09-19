import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/badge.dart';
import 'app_providers.dart';

final badgeRecordsUpdateProvider = StreamProvider<void>((ref) {
  ref.watch(accountGenerationProvider);
  return ref.watch(badgeRepoProvider).watchUpdates;
});

// Provides access to the list of badges for the UI
final badgesProvider = Provider<List<Badge>>((ref) {
  ref.watch(accountGenerationProvider);
  ref.watch(badgeRecordsUpdateProvider);
  final repo = ref.watch(badgeRepoProvider);
  return repo.getAllBadges();
});

// Provides access exactly when the engine fires an unlock
class BadgeUnlockQueue extends Notifier<List<Badge>> {
  @override
  List<Badge> build() {
    ref.watch(accountGenerationProvider);
    return [];
  }

  void enqueue(Badge badge) {
    if (state.any((b) => b.id == badge.id)) return; // Ignore duplicates
    state = [...state, badge];
  }

  void clear() => state = [];

  void dequeue() {
    if (state.isNotEmpty) {
      state = state.sublist(1);
    }
  }
}

final badgeUnlockEventProvider =
    NotifierProvider<BadgeUnlockQueue, List<Badge>>(() {
      return BadgeUnlockQueue();
    });

final badgeEngineProvider = Provider<BadgeEngine>((ref) {
  return BadgeEngine(ref);
});

class BadgeEngine {
  final Ref ref;
  bool _disposed = false;
  bool _running = false;
  bool _pending = false;
  Timer? _evaluationTimer;
  final Set<String> _localCategories = {};
  final List<StreamSubscription<String>> _localSubscriptions = [];

  void _localRecord(String date, Iterable<String> categories) {
    final now = ref.read(clockProvider);
    final today = DateTime(now.year, now.month, now.day);
    final recorded = DateTime.tryParse(date);
    if (recorded != today ||
        ref.read(accountTransitionProvider) ||
        ref.read(accountHydratingProvider)) {
      return;
    }
    _localCategories.addAll(categories);
    _schedule();
  }

  BadgeEngine(this.ref) {
    ref.onDispose(() {
      _disposed = true;
      _evaluationTimer?.cancel();
      for (final subscription in _localSubscriptions) {
        unawaited(subscription.cancel());
      }
    });
    _localSubscriptions.add(
      ref
          .read(dailyLogRepoProvider)
          .watchLocalWorkoutCompletions
          .listen((date) => _localRecord(date, const ['workout', 'streak'])),
    );
    _localSubscriptions.add(
      ref
          .read(mealRepoProvider)
          .watchLocalMealDays
          .listen((date) => _localRecord(date, const ['meal'])),
    );
    ref.listen(dailyLogsUpdateProvider, (_, _) => _schedule());
    ref.listen(dailyMealLogsUpdateProvider, (_, _) => _schedule());
    ref.listen(accountGenerationProvider, (_, _) {
      _localCategories.clear();
      _schedule();
    });
    ref.listen(accountTransitionProvider, (_, _) => _schedule());
    ref.listen(accountHydratingProvider, (_, _) => _schedule());
    ref.listen(clockProvider, (_, _) => _schedule());
    _schedule();
  }

  void _schedule() {
    _pending = true;
    if (_running || _disposed) return;
    _running = true;
    // Isar watchers and successful local commit signals describe the same
    // transaction. Coalesce them before deciding whether to present a trophy.
    _evaluationTimer = Timer(Duration.zero, () async {
      _evaluationTimer = null;
      try {
        while (_pending && !_disposed) {
          _pending = false;
          await _evaluateBadges();
        }
      } catch (error) {
        debugPrint('Badge evaluation will retry on the next update: $error');
      } finally {
        _running = false;
      }
    });
  }

  Future<void> _evaluateBadges() async {
    if (_disposed ||
        ref.read(accountTransitionProvider) ||
        ref.read(accountHydratingProvider)) {
      _localCategories.clear();
      return;
    }
    final celebrate = Set<String>.of(_localCategories);
    _localCategories.clear();
    final generation = ref.read(accountGenerationProvider);
    bool current() =>
        !_disposed &&
        generation == ref.read(accountGenerationProvider) &&
        !ref.read(accountTransitionProvider) &&
        !ref.read(accountHydratingProvider);
    final repo = ref.read(badgeRepoProvider);
    final now = ref.read(clockProvider);
    final today = DateTime(now.year, now.month, now.day);
    final allLogs = ref.read(dailyLogRepoProvider).getAllLogs();
    final completed = allLogs
        .where((log) {
          final day = DateTime.tryParse(log.date);
          return log.workoutCompleted && day != null && !day.isAfter(today);
        })
        .map((log) => log.date)
        .toSet()
        .length;
    final longestStreak = longestCompletedWorkoutStreak(allLogs, now);
    final mealDays = recordedMealDays(
      ref.read(mealRepoProvider).getAllLogs(),
      now,
    );

    for (final badge in repo.getAllBadges()) {
      if (!current()) return;
      if (badge.isUnlocked) continue;
      final progress = switch (badge.category) {
        'workout' => completed,
        'streak' => longestStreak,
        'meal' => mealDays,
        _ => badge.currentProgress,
      };
      final unlock = progress >= badge.requiredProgress;
      if (progress <= badge.currentProgress && !unlock) continue;
      final updated = badge.copyWith(
        currentProgress: progress,
        unlockedAt: unlock ? now : null,
      );
      await repo.saveBadge(updated, isCurrent: current);
      if (!current()) return;
      if (unlock && celebrate.contains(badge.category)) {
        ref.read(badgeUnlockEventProvider.notifier).enqueue(updated);
      }
    }
  }
}
