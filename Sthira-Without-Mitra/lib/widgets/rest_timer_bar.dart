import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

/// The active timer stays reachable without squeezing its countdown or controls.
class RestTimerBar extends StatelessWidget {
  const RestTimerBar({
    super.key,
    required this.remainingSeconds,
    required this.isPaused,
    this.exerciseName,
    required this.onAddSeconds,
    required this.onTogglePause,
    required this.onClose,
  });
  final int remainingSeconds;
  final bool isPaused;
  final String? exerciseName;
  final ValueChanged<int> onAddSeconds;
  final VoidCallback onTogglePause;
  final VoidCallback onClose;

  static bool _compact(BuildContext context, double width) =>
      width < 340 || MediaQuery.textScalerOf(context).scale(12) > 15;

  static double heightFor(BuildContext context, double width) {
    double lineHeight(TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: '00:00', style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      final height = painter.height;
      painter.dispose();
      return height;
    }

    final header = math.max(
      48.0,
      lineHeight(context.text.micro) + lineHeight(context.text.bodyStrong),
    );
    final controls = math.max(48.0, lineHeight(context.text.micro) + 16);
    return 24 + header + (_compact(context, width) ? 8 + controls : 0);
  }

  static String _spokenCountdown(int seconds) {
    final remaining = math.max(0, seconds);
    final minutes = remaining ~/ 60;
    final rest = remaining % 60;
    final parts = [
      if (minutes > 0) '$minutes ${minutes == 1 ? 'minute' : 'minutes'}',
      if (rest > 0 || minutes == 0) '$rest ${rest == 1 ? 'second' : 'seconds'}',
    ];
    return '${parts.join(' ')} remaining';
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = _compact(context, constraints.maxWidth);
      final pause = IconButton(
        onPressed: onTogglePause,
        icon: Icon(isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
        color: context.colors.onPrimary,
        tooltip: isPaused ? 'Resume timer' : 'Pause timer',
      );
      final close = IconButton(
        onPressed: onClose,
        icon: const Icon(Icons.close_rounded),
        color: context.colors.onPrimary,
        tooltip: 'Close timer',
      );
      Widget add(int seconds) => TextButton(
        onPressed: () => onAddSeconds(seconds),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          minimumSize: const Size(48, 48),
          foregroundColor: context.colors.onPrimary,
        ),
        child: Text(
          '+$seconds'
          's',
          style: AppTheme.numeric(
            context.text.micro.copyWith(color: context.colors.onPrimary),
          ),
        ),
      );
      final summary = Row(
        children: [
          Icon(
            isPaused ? Icons.pause_circle_filled_rounded : Icons.timer_rounded,
            color: context.colors.onPrimary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Semantics(
              key: const ValueKey('rest-timer-summary'),
              label:
                  'Rest timer${isPaused ? ', paused' : ''}'
                  '${exerciseName == null ? '' : ' for $exerciseName'}',
              value: _spokenCountdown(remainingSeconds),
              // A timer changes every second; it should be read on focus, not
              // repeatedly interrupt the person with live announcements.
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: exerciseName == null
                        ? (isPaused ? 'Rest timer is paused' : 'Rest timer')
                        : '${isPaused ? 'Rest paused' : 'Resting'} for $exerciseName',
                    child: Text(
                      isPaused ? 'Rest paused' : 'Rest timer',
                      style: context.text.micro.copyWith(
                        color: context.colors.onPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${remainingSeconds ~/ 60}:${(remainingSeconds % 60).toString().padLeft(2, '0')}',
                    maxLines: 1,
                    style: AppTheme.numeric(
                      context.text.bodyStrong.copyWith(
                        color: context.colors.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!compact) ...[add(15), add(30), const SizedBox(width: 4)],
          pause,
          close,
        ],
      );
      return Container(
        height: heightFor(context, constraints.maxWidth),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.colors.orange,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: context.colors.orange.withValues(alpha: .3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: compact
            ? Column(
                children: [
                  Expanded(child: summary),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: add(15)),
                      Expanded(child: add(30)),
                    ],
                  ),
                ],
              )
            : summary,
      );
    },
  );
}
