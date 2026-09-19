/// Sthira spacing system. Base 4pt scale.
///
/// These are the ONLY gap, radius and icon-size values permitted in the app.
/// If a layout appears to need something else, the layout is wrong — raise it
/// rather than adding a value here.
///
/// MIGRATION RULE
/// Later prompts will convert existing values. Record the mapping now so it is consistent across sessions:
/// | Found | Becomes |
/// |---|---|
/// | 6 | 8 |
/// | 10 | 8 or 12 (pick by role: inline → 8, stack → 12) |
/// | 14 | 12 or 16 |
/// | 18 | 16 |
/// | 28 | 24 or 32 |
/// | 30 | 32 |
/// | 48+ (as a gap) | 40 |
/// | radius 2, 3, 4 | `Radii.micro` (6) |
/// | radius 8, 10, 14 | `Radii.chip` (12) |
/// | radius 18, 40, 100 | `Radii.card` (20) or `StadiumBorder` — by role |
/// | radius 32 | `Radii.sheet` (24) |
/// | icon 11, 12, 14 | `IconSize.inline` (16) |
/// | icon 18, 22 | `IconSize.row` (20) |
/// | icon 28, 30, 32, 36 | `IconSize.nav` (24) |
/// | icon 48, 64 | `IconSize.hero` (40) |
///
/// If a gap currently reads as a deliberate odd value, it isn't — it was typed by hand.
library;

abstract class Gap {
  static const double x2 = 2; // optical nudge ONLY — baseline correction
  static const double x4 = 4; // inside a text pair (title -> its subtitle)
  static const double x8 = 8; // icon -> label, chip internals
  static const double x12 =
      12; // card -> card in a group; section header -> content
  static const double x16 = 16; // blocks inside a single card
  static const double x20 = 20; // screen inset
  static const double x24 = 24; // section -> section
  static const double x32 =
      32; // major break (around a hero, after last section)
  static const double x40 = 40; // page top / bottom breathing room
}

/// Semantic aliases. Prefer these at call sites — they document intent
/// and make a later scale change safe.
abstract class Spacing {
  static const double textPair = Gap.x4; // title -> its own subtitle
  static const double inline = Gap.x8; // leading icon -> label
  static const double stack = Gap.x12; // sibling cards; header -> content
  static const double block = Gap.x16; // groups inside one card
  static const double section = Gap.x24; // between sections
  static const double major = Gap.x32; // hero separation

  static const double screen = 20; // horizontal page inset — ALWAYS
  static const double cardPad = 20; // standard card internal padding
  static const double cardPadTight = 16; // dense/nested cards, grid tiles ONLY
  static const double sheetPadH = 24; // sheet horizontal inset
}

/// Corner radii. Six values. No others.
abstract class Radii {
  static const double sheet = 24; // bottom sheets
  static const double card = 20; // SurfaceCard, tiles
  static const double control = 16; // buttons, text fields
  static const double chip = 12; // chips, small containers, icon tiles
  static const double micro = 6; // macro pills, tiny tags
  // Fully round: use StadiumBorder or BorderRadius.circular(999).
  // Never a magic 40 / 100.
}

/// Icon sizes. Four values.
abstract class IconSize {
  static const double inline = 16; // trailing chevrons, inline metadata icons
  static const double row = 20; // list-row leading icons, button icons
  static const double nav = 24; // AppBar, bottom nav
  static const double hero = 40; // empty states, large decorative marks
}
