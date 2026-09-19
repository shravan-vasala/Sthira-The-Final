import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_motion.dart';

enum SurfaceCardElevation { home, nested }

/// Standard app surface card — Home cockpit chrome by default.
class SurfaceCard extends StatefulWidget {
  const SurfaceCard({
    super.key,
    required this.child,

    /// The container owns the horizontal inset. Cards inside a padded scrollable pass `margin: EdgeInsets.zero`.
    this.margin = const EdgeInsets.symmetric(horizontal: Spacing.screen),
    this.padding,
    this.dense = false,
    this.onTap,
    this.border,
    this.color,
    this.elevation = SurfaceCardElevation.home,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final bool dense;
  final VoidCallback? onTap;
  final BoxBorder? border;
  final Color? color;
  final SurfaceCardElevation elevation;
  final double? borderRadius;

  @override
  State<SurfaceCard> createState() => _SurfaceCardState();
}

class _SurfaceCardState extends State<SurfaceCard> {
  bool _isPressed = false;

  void _handleHighlightChanged(bool pressed) {
    if (_isPressed != pressed) {
      setState(() => _isPressed = pressed);
    }
  }

  @override
  void didUpdateWidget(covariant SurfaceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onTap == null) _isPressed = false;
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? Radii.card;
    final isLight = Theme.of(context).brightness == Brightness.light;

    final List<BoxShadow> shadows;
    switch (widget.elevation) {
      case SurfaceCardElevation.home:
        shadows = [
          BoxShadow(
            color: context.colors.textDark.withValues(
              alpha: isLight ? 0.05 : 0.0,
            ),
            blurRadius: isLight ? 12 : 16,
            offset: Offset(0, isLight ? 4 : 6),
          ),
        ];
      case SurfaceCardElevation.nested:
        shadows = [
          BoxShadow(
            color: context.colors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ];
    }

    final padding =
        widget.padding ??
        EdgeInsets.all(widget.dense ? Spacing.cardPadTight : Spacing.cardPad);
    final decoration = BoxDecoration(
      color: widget.color ?? context.colors.card,
      borderRadius: BorderRadius.circular(radius),
      border: widget.border,
      boxShadow: shadows,
    );

    if (widget.onTap == null) {
      return Container(
        margin: widget.margin,
        padding: padding,
        decoration: decoration,
        child: widget.child,
      );
    }

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Padding(
      // Empty gutters should remain scrollable without opening the card.
      padding: widget.margin ?? EdgeInsets.zero,
      child: AnimatedScale(
        scale: _isPressed && !reduceMotion ? 0.99 : 1.0,
        duration: reduceMotion ? Duration.zero : Motion.instant,
        curve: Motion.enter,
        child: DecoratedBox(
          decoration: decoration,
          child: Material(
            type: MaterialType.transparency,
            // Adding a Material must not change the card's inherited typography.
            textStyle: DefaultTextStyle.of(context).style,
            child: Semantics(
              button: true,
              child: InkWell(
                onTap: widget.onTap,
                onHighlightChanged: _handleHighlightChanged,
                borderRadius: BorderRadius.circular(radius),
                hoverColor: context.colors.primary.withValues(alpha: 0.04),
                focusColor: context.colors.primary.withValues(alpha: 0.12),
                highlightColor: context.colors.primary.withValues(alpha: 0.06),
                splashFactory: reduceMotion ? NoSplash.splashFactory : null,
                child: Padding(
                  // Container includes the border inset in its content padding.
                  padding: padding.add(decoration.padding),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
