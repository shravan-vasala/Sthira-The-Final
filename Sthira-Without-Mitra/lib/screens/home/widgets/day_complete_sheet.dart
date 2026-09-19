import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../../../widgets/app_bottom_sheet.dart';
import '../../../widgets/primary_button.dart';

/// Completion is available on demand, without interrupting a save or sync.
class DayCompleteAction extends ConsumerWidget {
  const DayCompleteAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(dailyScoreProvider);
    final date = ref.watch(dateStringProvider);
    final now = ref.watch(clockProvider);
    final selected = DateTime.tryParse(date);
    final today = DateTime(now.year, now.month, now.day);
    if (!score.isPrimaryComplete ||
        score.habitsMax + score.mealsMax + score.workoutsMax <= 0 ||
        score.isFutureDate ||
        selected != today ||
        ref.watch(accountTransitionProvider) ||
        ref.watch(accountHydratingProvider)) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        icon: const Icon(Icons.check_circle_outline_rounded),
        label: const Text('Day complete · View summary', softWrap: true),
        onPressed: () => showDayCompleteSheet(context, ref),
      ),
    );
  }
}

Future<void> showDayCompleteSheet(BuildContext context, WidgetRef ref) async {
  final score = ref.read(dailyScoreProvider);
  final date = ref.read(dateStringProvider);
  final now = ref.read(clockProvider);
  if (!score.isPrimaryComplete ||
      score.habitsMax + score.mealsMax + score.workoutsMax <= 0 ||
      score.isFutureDate ||
      DateTime.tryParse(date) != DateTime(now.year, now.month, now.day) ||
      ref.read(accountTransitionProvider) ||
      ref.read(accountHydratingProvider) ||
      !context.mounted ||
      ModalRoute.of(context)?.isCurrent != true) {
    return;
  }
  final generation = ref.read(accountGenerationProvider);
  await showAppBottomSheet<void>(
    context: context,
    builder: (context) => DayCompleteSheet(
      score: score.totalScore,
      accountGeneration: generation,
    ),
  );
}

class DayCompleteSheet extends ConsumerWidget {
  const DayCompleteSheet({
    required this.score,
    required this.accountGeneration,
    super.key,
  });
  final int score;
  final int accountGeneration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void closeForAccountChange() {
      final route = ModalRoute.of(context);
      if (!context.mounted || route == null || !route.isActive) return;
      if (route.isCurrent) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).removeRoute(route);
      }
    }

    ref.listen(accountGenerationProvider, (_, next) {
      if (next != accountGeneration) closeForAccountChange();
    });
    ref.listen(accountTransitionProvider, (_, next) {
      if (next) closeForAccountChange();
    });
    if (ref.watch(accountGenerationProvider) != accountGeneration ||
        ref.watch(accountTransitionProvider)) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => closeForAccountChange(),
      );
      return const SizedBox.shrink();
    }
    return AppSheet(
      title: 'Day complete',
      subtitle:
          'Your planned activities are complete. Your day score is $score.',
      scrollable: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.green.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: context.colors.green,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Done',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
