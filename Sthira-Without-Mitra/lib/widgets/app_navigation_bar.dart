import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// One measured footer keeps navigation, the rest timer, and floating messages
/// clear of each other and of the system gesture area.
class AppNavigationDock extends StatelessWidget {
  const AppNavigationDock({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
    this.restTimer,
  });

  final int currentIndex;
  final ValueChanged<int> onItemSelected;
  final Widget? restTimer;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: Gap.x16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (restTimer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.screen,
                  Gap.x8,
                  Spacing.screen,
                  Gap.x12,
                ),
                child: restTimer!,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.screen),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: AppNavigationBar(
                    currentIndex: currentIndex,
                    onItemSelected: onItemSelected,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stable destinations with visible names and keyboard/screen-reader access.
class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  static const _destinations = [
    (label: 'Home', icon: Icons.home_outlined, active: Icons.home_rounded),
    (
      label: 'Progress',
      icon: Icons.show_chart_outlined,
      active: Icons.show_chart_rounded,
    ),
    (
      label: 'Social',
      icon: Icons.people_outline_rounded,
      active: Icons.people_rounded,
    ),
    (
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      active: Icons.person_rounded,
    ),
  ];

  bool _needsRows(BuildContext context, double width) {
    final cellWidth = (width - Gap.x16) / _destinations.length;
    for (final destination in _destinations) {
      final painter = TextPainter(
        text: TextSpan(text: destination.label, style: context.text.caption),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      final fits = painter.width + Gap.x8 <= cellWidth;
      painter.dispose();
      if (!fits) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final rows = _needsRows(context, constraints.maxWidth);
      Widget item(int index) => Expanded(
        child: _Destination(
          label: _destinations[index].label,
          icon: currentIndex == index
              ? _destinations[index].active
              : _destinations[index].icon,
          selected: currentIndex == index,
          onTap: () {
            if (index != currentIndex) onItemSelected(index);
          },
        ),
      );
      return Material(
        color: context.colors.card,
        shape: rows
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.card),
              )
            : const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(Gap.x8),
          child: rows
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [item(0), item(1)]),
                    const SizedBox(height: Gap.x4),
                    Row(children: [item(2), item(3)]),
                  ],
                )
              : Row(
                  children: [
                    for (var i = 0; i < _destinations.length; i++) item(i),
                  ],
                ),
        ),
      );
    },
  );
}

class _Destination extends StatelessWidget {
  const _Destination({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconWidget = AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : Motion.instant,
      curve: Motion.enter,
      width: 48,
      height: 32,
      decoration: ShapeDecoration(
        color: selected ? context.colors.primary : Colors.transparent,
        shape: const StadiumBorder(),
      ),
      child: Icon(
        icon,
        size: IconSize.nav,
        color: selected ? context.colors.onPrimary : context.colors.textMedium,
      ),
    );
    final labelWidget = Text(
      label,
      textAlign: TextAlign.center,
      style: context.text.caption.copyWith(
        color: selected ? context.colors.textDark : context.colors.textMedium,
      ),
    );
    return Semantics(
      key: ValueKey('nav-${label.toLowerCase()}'),
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.control),
          focusColor: context.colors.primary.withValues(alpha: .2),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Gap.x4,
                vertical: Gap.x4,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  iconWidget,
                  const SizedBox(height: Gap.x4),
                  labelWidget,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
