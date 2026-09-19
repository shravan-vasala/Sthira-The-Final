import 'package:flutter/animation.dart';

/// Sthira motion system.
///
/// The brand is "Steady Aura" — motion should feel settled and inevitable,
/// never bouncy or attention-seeking. Three durations, two curves. If an
/// interaction seems to need something else, raise it rather than adding one.
abstract class Motion {
  /// State flips the user caused and is watching: toggles, checkboxes,
  /// selection pills, press feedback.
  static const Duration instant = Duration(milliseconds: 150);

  /// The default. Expand/collapse, cross-fades, content swaps, layout settles.
  static const Duration standard = Duration(milliseconds: 250);

  /// Entrances, sheet reveals, and the one-off celebration moments.
  static const Duration deliberate = Duration(milliseconds: 400);

  /// Everything that enters, moves, or settles.
  static const Curve enter = Curves.easeOutCubic;

  /// Everything that leaves or collapses.
  static const Curve exit = Curves.easeInCubic;
}
