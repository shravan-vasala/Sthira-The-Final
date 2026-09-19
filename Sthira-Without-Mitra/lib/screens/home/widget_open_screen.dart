import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../utils/widget_navigation.dart';
import '../../utils/workout_completion.dart';

/// Resolves a launcher tap only after the active account has settled.
class WidgetOpenScreen extends ConsumerStatefulWidget {
  const WidgetOpenScreen({super.key, required this.action});
  final String action;
  @override
  ConsumerState<WidgetOpenScreen> createState() => _WidgetOpenScreenState();
}

class _WidgetOpenScreenState extends ConsumerState<WidgetOpenScreen> {
  bool _scheduled = false;
  bool _opened = false;

  void _open() {
    _scheduled = false;
    if (!mounted ||
        _opened ||
        ref.read(accountTransitionProvider) ||
        ref.read(accountHydratingProvider))
      return;
    _opened = true;
    // A pending launcher can span midnight before Home starts its ticker.
    final now = ref.refresh(clockProvider);
    final today = DateTime(now.year, now.month, now.day);
    ref.read(selectedDateProvider.notifier).state = today;
    ref.read(weekOffsetProvider.notifier).state = 0;
    var destination = switch (widget.action) {
      'steps' => '/progress?metric=steps',
      'meals' => '/home/meals',
      _ => '/home',
    };
    if (widget.action == 'workout') {
      final plan = ref.read(workoutPlanProvider);
      if (plan != null && WorkoutCompletion.hasSchedule(plan)) {
        final day = WorkoutCompletion.resolveWorkoutDay(
          plan,
          today,
          planStartDate: ref.read(profileProvider).planStartDate,
        );
        if (!WorkoutCompletion.isRestDay(day, today) && day.dayId != null) {
          destination = '/home/workout/${Uri.encodeComponent(day.dayId!)}';
        }
      }
    }
    context.go(destination);
  }

  @override
  Widget build(BuildContext context) {
    final transitioning = ref.watch(accountTransitionProvider);
    final hydrating = ref.watch(accountHydratingProvider);
    ref.watch(accountGenerationProvider);
    if (!transitioning && !hydrating && !_scheduled && !_opened) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _open());
    }
    return Scaffold(
      body: Center(
        child: Semantics(
          label: widgetActions.contains(widget.action)
              ? 'Opening today'
              : 'Opening Home',
          liveRegion: true,
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
