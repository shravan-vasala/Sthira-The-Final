import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/layout_insets.dart';

/// Full-width primary action. Grows beyond 52dp when its label needs room.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconColor,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? iconColor;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final button = _ButtonPressFeedback(
      builder: (states) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          statesController: states,
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, kPrimaryButtonHeight),
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.section,
              vertical: Spacing.stack,
            ),
            backgroundColor: context.colors.primary,
            foregroundColor: context.colors.onPrimary,
            disabledBackgroundColor: isLoading
                ? context.colors.primary
                : context.colors.insetSurface,
            disabledForegroundColor: isLoading
                ? context.colors.onPrimary
                : context.colors.textMedium,
            textStyle: context.text.bodyStrong,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kButtonRadius),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading) ...[
                SizedBox.square(
                  dimension: IconSize.row,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.colors.onPrimary,
                  ),
                ),
                const SizedBox(width: Spacing.inline),
              ] else if (icon != null) ...[
                Icon(
                  icon,
                  size: IconSize.row,
                  color: onPressed == null ? null : iconColor,
                ),
                const SizedBox(width: Spacing.inline),
              ],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          ),
        ),
      ),
    );

    if (!isLoading) return button;
    return Semantics(
      label: label,
      value: 'In progress',
      liveRegion: true,
      button: true,
      enabled: false,
      child: ExcludeSemantics(child: button),
    );
  }
}

/// A compact action with a padded touch target and room for larger text.
class CompactButton extends StatelessWidget {
  const CompactButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.filled = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, kCompactButtonHeight)),
      tapTargetSize: MaterialTapTargetSize.padded,
      padding: const WidgetStatePropertyAll(EdgeInsets.all(Spacing.inline)),
      textStyle: WidgetStatePropertyAll(
        context.text.caption.copyWith(fontWeight: FontWeight.w600),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kOutlinedButtonRadius),
        ),
      ),
    );
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: IconSize.inline),
          const SizedBox(width: Spacing.inline),
        ],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );

    return _ButtonPressFeedback(
      builder: (states) => SizedBox(
        width: double.infinity,
        child: filled
            ? ElevatedButton(
                statesController: states,
                onPressed: onPressed,
                style: style,
                child: child,
              )
            : OutlinedButton(
                statesController: states,
                onPressed: onPressed,
                style: style,
                child: child,
              ),
      ),
    );
  }
}

/// Uses the actual Material button state for touch, keyboard and cancellation.
class _ButtonPressFeedback extends StatefulWidget {
  const _ButtonPressFeedback({required this.builder});

  final Widget Function(WidgetStatesController states) builder;

  @override
  State<_ButtonPressFeedback> createState() => _ButtonPressFeedbackState();
}

class _ButtonPressFeedbackState extends State<_ButtonPressFeedback> {
  final _states = WidgetStatesController();
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _states.addListener(_updatePressed);
  }

  void _updatePressed() {
    final pressed = _states.value.contains(WidgetState.pressed);
    if (_pressed == pressed) return;
    // Material may clear pressed state during a rebuild that disables a button.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updatePressed();
      });
      return;
    }
    setState(() => _pressed = pressed);
  }

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedScale(
      scale: !reduceMotion && _pressed ? 0.98 : 1,
      duration: reduceMotion ? Duration.zero : Motion.instant,
      curve: Motion.enter,
      child: widget.builder(_states),
    );
  }
}
