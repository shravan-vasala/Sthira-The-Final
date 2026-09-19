import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_spacing.dart';

// The shell footer is measured by Scaffold. Scroll views use the inherited
// MediaQuery.padding.bottom so navigation, timer and system insets stay aligned.

/// Space below the final scroll item, using the shell's measured navigation,
/// rest timer and system inset. Call below any SafeArea that consumes an inset,
/// or let the scroll view own the bottom inset with SafeArea(bottom: false).
double shellScrollBottomPadding(BuildContext context) =>
    MediaQuery.paddingOf(context).bottom + Gap.x16;

/// Extra clearance for a nested Scaffold's floating action: Scaffold already
/// handles the system/keyboard inset, while the shell owns the measured dock.
double shellFloatingActionBottomPadding(BuildContext context) {
  if (MediaQuery.viewInsetsOf(context).bottom > 0) return 0;
  return math.max(
    0.0,
    MediaQuery.paddingOf(context).bottom -
        MediaQuery.viewPaddingOf(context).bottom,
  );
}

/// Horizontal inset for main-shell screens (Home / Progress / Profile).
const double kScreenPadding = Spacing.screen;

/// Default surface card corner radius.
const double kCardRadius = Radii.card;

/// Modal bottom sheet top corner radius (matches [BottomSheetTheme]).
const double kSheetRadius = Radii.sheet;

/// Primary / elevated button corner radius.
const double kButtonRadius = Radii.control;

/// Outlined button corner radius.
const double kOutlinedButtonRadius = Radii.control;

/// Full-width primary save CTA height.
const double kPrimaryButtonHeight = 52;

/// Compact row action height (Photo / Describe / Adjust).
const double kCompactButtonHeight = 40;
