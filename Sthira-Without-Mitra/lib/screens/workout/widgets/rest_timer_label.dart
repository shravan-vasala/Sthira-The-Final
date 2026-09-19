import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/app_providers.dart';
import 'package:trufit_bodamma/theme/app_typography.dart';

class RestTimerLabel extends ConsumerWidget {
  const RestTimerLabel({
    super.key,
    required this.seconds,
    required this.exerciseName,
  });

  final int seconds;
  final String exerciseName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (seconds <= 0) return const SizedBox.shrink();

    final timerState = ref.watch(restTimerProvider);
    final isActive =
        timerState.isActive && timerState.exerciseName == exerciseName;
    final displaySeconds = isActive ? timerState.remainingSeconds : seconds;

    final display = displaySeconds >= 60
        ? '${displaySeconds ~/ 60} min${displaySeconds % 60 > 0 ? ' ${displaySeconds % 60} sec' : ''}'
        : '$displaySeconds sec';

    return Row(
      children: [
        Expanded(
          child: Divider(
            color: isActive ? context.colors.orange : context.colors.border,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 8,
          child: Text(
            isActive ? 'Resting for $display' : 'Rest for $display after set',
            textAlign: TextAlign.center,
            style: AppTheme.numeric(
              context.text.micro.copyWith(
                color: isActive
                    ? context.colors.orange
                    : context.colors.textLight,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(
            color: isActive ? context.colors.orange : context.colors.border,
          ),
        ),
      ],
    );
  }
}
