# Sthira — Spacing, Padding & Typography Systemization

## Role

You are refactoring the visual rhythm of a Flutter app called **Sthira** (dark, grounded, borderless, premium — "Steady Aura"). Read `sthira_design_system.md` first; it is the source of truth for look and feel.

This is **not** a redesign. The brand is settled and working. Your job is to remove inconsistency, not to invent a new aesthetic.

---

## HARD CONSTRAINTS — do not touch

- **Colors.** `lib/theme/app_colors.dart` is final. Do not add, remove, or re-tune a single hex value. Do not introduce `Colors.*` literals — if you find existing ones (`photo_calorie_scanner_sheet.dart:1189,1190,1196,1206,1213,1223,1224`, `day_complete_sheet.dart:74`, `meal_detail_screen.dart:1050`, `social_feed_screen.dart` skeletons), replace them with the nearest `context.colors.*` equivalent and nothing more.
- **Fonts.** Cabinet Grotesk (headlines) and General Sans (body) only. No new families. The only exception already in the app is Caveat for the Gita shloka — leave it.
- **Icons.** Keep every icon glyph exactly as-is. You may normalize icon *sizes*; you may not swap icons.
- **Card / tile concept.** The rounded `SurfaceCard` floating on the dark scaffold, the pill tags, the muted 4px progress tracks, the un-boxed trailing chevron — all stay. The owner explicitly likes these.
- **Floating pill bottom nav.** Its visual style stays. (One layout bug in it is in scope — see §7.)
- **No feature work.** No new screens, no new data, no new capabilities. Recomposition of existing elements is allowed; inventing new ones is not.

---

## THE DIAGNOSIS

I audited every screen. The app does not have a spacing problem in any one place — it has **no enforced system at all**, so 40+ files each improvised. The measured state:

| Dimension | Distinct values in use | Should be |
|---|---|---|
| `fontSize` literals | **22** (9,10,11,12,13,14,15,16,17,18,20,22,24,26,28,32,40,42,48,56,64,72) | 10 tokens |
| `BorderRadius.circular(N)` | **17** (2,3,4,6,8,10,12,14,16,18,20,24,32,40,100 + Stadium + Circle) | 6 tokens |
| Icon `size:` | **15** (11,12,14,16,18,20,22,24,28,30,32,36,40,48,64) | 4 tokens |
| Screen horizontal inset | **5** (0, 16, 20, 24, 32) | 1 |
| Card internal padding | **6** (0, 12, 16, 16/8, 20, 40) | 2 |
| Full-width primary CTA height | **3** (52, 54, 56) | 1 |
| AppBar treatment | **7 distinct** | 1 |
| Section-label idiom | **6 distinct** | 1 |
| Sheet title treatment | **4 distinct** | 1 |

Two root causes:

1. **The token layer exists and is ignored.** `lib/theme/app_typography.dart` defines 7 tokens and is called **exactly once in the entire codebase** (`lib/screens/home/home_screen.dart:337`). Against that: **698 inline `TextStyle(` literals**. `lib/theme/layout_insets.dart` defines 9 constants; `kScreenPadding` is referenced in 6 files (all under `screens/home/`), `kButtonRadius` in 1, and `shellScrollPadding()` in **zero**.

2. **The two type systems actively contradict each other.** `app_theme.dart`'s `TextTheme` and `app_typography.dart`'s `AppTypography` disagree on every overlapping slot. Worst: `AppTypography.titleLarge` = Cabinet **22/w700** (`app_typography.dart:22`) while `TextTheme.titleLarge` = Cabinet **16/w600** (`app_theme.dart:51`). Same name, different meaning. Body is 15/w500 in one and 14/w400 in the other. `kCardRadius = 20` carries the comment *"matches [CardTheme]"* — `CardThemeData` is **24** (`app_theme.dart:119`). The comment is a lie and has been for a while.

Deliver §1–§8 below, in that order.

---

## §1 — Create the spacing scale (new file)

Create `lib/theme/app_spacing.dart`. There is currently **no spacing token file at all** — that is the single highest-leverage fix in this task.

```dart
/// Base 4pt scale. These are the ONLY vertical/horizontal gap values
/// permitted in the app. If a layout seems to need something else,
/// the layout is wrong.
abstract class Gap {
  static const double x2  = 2;   // optical nudge only — baseline correction
  static const double x4  = 4;   // inside a text pair (title -> subtitle)
  static const double x8  = 8;   // icon -> label, chip internals
  static const double x12 = 12;  // card -> card in a group; section header -> content
  static const double x16 = 16;  // blocks inside a card
  static const double x20 = 20;  // screen inset
  static const double x24 = 24;  // section -> section
  static const double x32 = 32;  // major break (above a hero, after last section)
  static const double x40 = 40;  // page top/bottom breathing room
}

/// Semantic aliases — prefer these at call sites; they document intent.
abstract class Spacing {
  static const double textPair   = Gap.x4;   // title -> its own subtitle
  static const double inline     = Gap.x8;   // leading icon -> label
  static const double stack      = Gap.x12;  // sibling cards; header -> content
  static const double block      = Gap.x16;  // groups inside one card
  static const double section    = Gap.x24;  // between sections
  static const double major      = Gap.x32;  // hero separation

  static const double screen     = 20;       // horizontal page inset — ALWAYS
  static const double cardPad    = 20;       // standard card internal padding
  static const double cardPadTight = 16;     // dense/nested cards, grid tiles ONLY
  static const double sheetPadH  = 24;       // sheet horizontal inset
}

/// Corner radii. Six values. No others.
abstract class Radii {
  static const double sheet   = 24;  // bottom sheets
  static const double card    = 20;  // SurfaceCard, tiles
  static const double control = 16;  // buttons, text fields
  static const double chip    = 12;  // chips, small containers, icon tiles
  static const double micro   = 6;   // macro pills, tiny tags
  // Full-round: use StadiumBorder / BorderRadius.circular(999), never a magic 40/100.
}

/// Icon sizes. Four values.
abstract class IconSize {
  static const double inline  = 16;  // trailing chevrons, inline metadata icons
  static const double row     = 20;  // list-row leading icons, button icons
  static const double nav     = 24;  // AppBar, bottom nav
  static const double hero    = 40;  // empty states, large decorative marks
}
```

Then fix the lie: update `kCardRadius`'s comment, or better — delete `cardTheme` from `app_theme.dart` entirely (see §8, it has zero consumers).

**Migration rule for every existing gap value:** `6→8`, `10→8 or 12` (pick by role), `14→12 or 16`, `18→16`, `28→24 or 32`, `30→32`, `48→40`, `100/116→see §7`. If a gap currently reads as deliberate at an odd value, it isn't — it was typed by hand.

---

## §2 — Collapse the type scale to 10 tokens

Rewrite `lib/theme/app_typography.dart` to exactly this. Keep the `context.text.*` extension pattern — it's good, it's just unused.

| Token | Family | Size | Weight | ls | height | Use |
|---|---|---|---|---|---|---|
| `metric` | Cabinet Grotesk | **44** | w800 | −1.6 | 1.0 | THE one hero number on a screen. Max one per screen. |
| `display` | Cabinet Grotesk | **32** | w800 | −1.0 | 1.05 | Large numeric readouts in cards/dialogs |
| `screenTitle` | Cabinet Grotesk | **24** | w800 | −0.6 | 1.15 | AppBar titles, sheet titles, the Home greeting |
| `cardTitle` | Cabinet Grotesk | **17** | w700 | −0.2 | 1.25 | Card / tile titles |
| `sectionLabel` | Cabinet Grotesk | **16** | w700 | 0 | 1.2 | `SectionHeader` — colored `primary` per the design system |
| `eyebrow` | General Sans | **11** | w700 | 1.2 | 1.2 | UPPERCASE micro-labels above a group |
| `body` | General Sans | **15** | w500 | 0 | 1.45 | Reading text |
| `bodyStrong` | General Sans | **15** | w700 | 0 | 1.4 | List-row titles, emphasized body |
| `caption` | General Sans | **13** | w500 | 0 | 1.4 | Metadata, subtitles under a title |
| `micro` | General Sans | **11** | w600 | 0 | 1.2 | Pills, badges, chart axis labels |

**Delete these sizes from the app entirely: 9, 10, 12, 14, 18, 20, 22, 26, 28, 42, 48, 56, 64, 72.**

### Migration decision rule — apply per call site, do not blind-replace

- **14 (106 occurrences)** — the biggest bucket. Split it:
  - a sentence a user actually reads → `body` (15)
  - metadata sitting under a title → `caption` (13)
  - text inside a pill/chip/axis label → `micro` (11)
- **12 (93 occurrences)** — subtitle role → `caption` (13); chip/axis/badge role → `micro` (11)
- **13 (101)** → `caption`, unless it is an uppercase tracked label → `eyebrow`
- **16 (65)** → body text → `bodyStrong` (15); a title → `cardTitle` (17)
- **10, 9 (37)** → `micro` (11)
- **17, 18 (37)** → `cardTitle` (17)
- **20, 22, 24, 26 (55)** → `screenTitle` (24)
- **28, 32 (20)** → `display` (32)
- **40, 42, 48, 56, 64, 72 (15)** → `metric` (44)

**Yes, this means the 72pt weekly score (`weekly_summary_screen.dart:330`) and the 64pt daily score (`daily_score_sheet.dart:81`) come down to 44.** Do it. Those numbers are not premium, they are loud. Premium is a well-set 44 with real space around it. The 48pt progress hero (`progress_screen.dart:448`) and the two 56s (`meal_detail_screen.dart:275`, `sync_status_sheet.dart:131`) go to 44 as well.

### Then kill the contradiction

`app_theme.dart`'s `TextTheme` and `AppTypography` must stop disagreeing. Redefine the `TextTheme` slots **as aliases of the 10 tokens above** so a bare `Text('x')` and a `context.text.body` render identically:

```
displayLarge   -> metric        headlineLarge  -> display
headlineMedium -> screenTitle   headlineSmall  -> cardTitle
titleLarge     -> cardTitle     titleMedium    -> bodyStrong
titleSmall     -> caption       bodyLarge      -> body
bodyMedium     -> body          bodySmall      -> caption
labelLarge     -> bodyStrong    labelMedium    -> caption
labelSmall     -> micro
```

Note `TextTheme.titleLarge` becomes 17 (was 16) and `AppTypography.titleLarge` ceases to exist as a name — this resolves the collision. Also normalize the dark theme's construction: light builds a fresh `TextTheme`, dark does `ThemeData(brightness: dark).textTheme.apply().copyWith()` (`app_theme.dart:316`), so dark silently inherits Material defaults for `displayLarge/Medium/Small`. Build both the same way.

### Enforce it

After migration, **`context.text.*` should be the dominant path and inline `TextStyle(` should be rare.** Target: fewer than 60 remaining inline `TextStyle(` literals in `lib/`, and every survivor must be a `context.text.X.copyWith(color: ...)` — color overrides only. If you find yourself overriding `fontSize` in a `copyWith`, the token set is wrong; tell me rather than adding a size.

Also add a lint or a `// ignore`-free convention comment at the top of `app_typography.dart` documenting the rule.

---

## §3 — The greeting (the owner specifically flagged this)

**Current state, `lib/screens/home/home_screen.dart:124-128` and `:270-378`.**

Be blunt about why it reads wrong. It is six separate mistakes stacked:

1. **It's the largest text on the screen and it's in the wrong typeface.** 24pt **General Sans** (`:297,:311,:321`). Every other title in the app is Cabinet Grotesk. The single most prominent element on the home screen is the one thing that is off-brand.
2. **The weight changes based on data.** No name set → `w500` (`:299`). Name set → `w400` prefix + `w600` name (`:313`,`:323`). The same greeting renders at two different weights depending on whether a profile name exists.
3. **It's crammed against the status bar.** `vertical: 8` (`:125`) under `SafeArea(bottom: false)`. Then there is **40px of air below it** before "This week" (8 + `SizedBox(24)` at `:128` + the strip's own `vertical: 8` at `week_calendar_strip.dart:111`). Tight on top, loose on the bottom — the exact inverse of what reads as composed.
4. **It's indented 24 while the entire rest of the screen is at 20** (`:125` vs `kScreenPadding`). A 4px ragged left edge at the very top of the app, where the eye lands first.
5. **No `height:` is set**, so 24pt General Sans uses its default loose line box — which is what makes point 3 feel worse.
6. **It's a lonely full-width line with nothing beside it and no date on the normal path.** The date row only renders when `!isToday` (`:331`). On the day you actually open the app, the header is one orphan sentence floating in space. It reads as placeholder copy, not as a page header.

Plus: it is the only top-level child **excluded from the `StaggeredFadeIn` sequence** — indices run 1..6 and index 0 is unused. On launch, every element animates in except the first thing you look at.

### Rebuild it as a proper page header

```
[ SafeArea top ]
  Gap.x12
  EYEBROW  — "MONDAY, 15 SEPTEMBER"  (eyebrow token, textLight, always visible,
                                       not only when !isToday)
  Gap.x4
  GREETING — "Good morning, Shravan"  (screenTitle token = Cabinet 24/w800/ls-0.6/h1.15)
             prefix in textMedium, name in textDark — color carries the emphasis,
             NOT weight. Single w800 throughout.
  Gap.x24
[ WeekCalendarStrip ]
```

Rules:
- Horizontal inset `Spacing.screen` (20). Not 24.
- Trailing slot on the greeting row: when `!isToday`, the existing "Return to Today" chip moves here, right-aligned and baseline-aligned to the greeting. When viewing today, the slot is empty — do not invent something to fill it.
- Remove `vertical: 8` from the greeting's padding and remove `vertical: 8` from `week_calendar_strip.dart:111`'s margin. All vertical rhythm comes from explicit `Gap.*` in the parent column, never from a child's own margin. That double-counting is the source of the 40px gap.
- Wrap the greeting in `StaggeredFadeIn(index: 0)` so the sequence starts where the eye does.
- If a user avatar already exists in the profile data, an optional 40px avatar in the trailing slot is acceptable and would strengthen the header. **Only if it already exists** — do not add avatar plumbing.

---

## §4 — Fix the shared components first (everything else follows)

These six files are the leverage points. Fix them before touching individual screens.

### `lib/widgets/section_header.dart`
- Title → `sectionLabel` token (Cabinet 16/w700/primary). It currently hardcodes the same values at `:34-40`; just route through the token.
- Icon size → `IconSize.inline` (18 → 16), gap → `Spacing.inline` (currently 6 at `:30`).
- **Add a `trailing` size contract.** Right now the Habits header's trailing is a raw `IconButton` (`home_screen.dart:459-468`) with Material's default 48×48 + `all(8)`, making that header **~27px taller than the other three** and pushing its icon ~8px off the 20px gutter. The Workouts header's trailing is a bare 12pt text (`:592-620`). Constrain `trailing` to a max height of 24 and strip IconButton padding so all headers are the same height and all trailing elements land on the same right edge.
- Delete the extra `EdgeInsets.symmetric(horizontal: 4.0)` wrapper on the Habits count (`home_screen.dart:441`) — it makes that count sit 12px from its title while Workouts' sits at 8.
- `WeekCalendarStrip`'s "This week" (`week_calendar_strip.dart:156-164`, Cabinet 18/w700/textDark) is a de-facto section header that bypasses this widget. Route it through `SectionHeader`.

### `lib/widgets/surface_card.dart`
- Default padding stays `Spacing.cardPad` (20). Add an explicit `dense` flag that yields `cardPadTight` (16).
- **`margin` has no default** (`:13`) — that is how the 24-vs-20 drift happened. Default it to `EdgeInsets.symmetric(horizontal: Spacing.screen)` and let screens opt out, not opt in.
- `ai_meal_suggestion_card.dart:170-173` and `:205-208` wrap a `Padding(all(20))` **inside** a `SurfaceCard` that already applies 20 → **40px of inset on all four sides**, double every other card in the app. Delete the inner `Padding`.

### `lib/widgets/app_bottom_sheet.dart`
The wrapper is good. The problem is ~8 sheets pass no `title:` and hand-build their own, so they hit the `else → SizedBox(16)` branch (`:83`) instead of the 20 title gap, and drift on every axis.
- **Force every sheet through `title:`/`subtitle:`.** Offenders that build their own: `water_entry_dialog.dart:104`, `sleep_entry_dialog.dart:118`, `steps_entry_dialog.dart:64`, `body_fat_entry_dialog.dart:75`, `timer_entry_dialog.dart:183`, `photo_calorie_scanner_sheet.dart:938`, `day_complete_sheet.dart:91`, `meal_detail_screen.dart:1204`.
- Title → `screenTitle` token. Subtitle → `caption`, gap `Gap.x8`. (Current subtitle gaps: 6, 8, and 12 across three sheets.)
- **Fix the safe-area double-count.** `AppSheet` already does `SafeArea(top:false)` (`:93`) + 24 bottom pad (`:115`). Five children add `MediaQuery.padding.bottom` on top anyway — `sleep:264`, `steps:198`, `body_fat:201`, `weight:176`, `day_complete:115` — and `timer:299` adds `padding.bottom + 8`. Remove all six; the wrapper owns it.
- **`past_day_summary_sheet.dart:138-146` bypasses `AppSheet` entirely** despite being launched via `showAppBottomSheet` (`week_calendar_strip.dart:382`). Own container, own 48×4 grabber (vs 40×4), no backdrop blur, no `viewInsets` handling, and inconsistent horizontal padding **within itself** (24 header at `:161`, 20 rows at `:213`, 20 metrics at `:321`, 20 CTA at `:381`). Migrate it onto `AppSheet`.
- Same for `share_preview_sheet.dart:102-105` (radius **32** vs `kSheetRadius` 24, own `fromLTRB(20,20,20,32)`, re-implements the grabber, title at 18/w800 vs 24/w800) and `photo_compare_screen.dart:204-349` and `trophy_room_card.dart:101` (radius **32**).
- Fix the `Expanded` inside the `SingleChildScrollView` at `photo_calorie_scanner_sheet.dart:1580` — unbounded flex child.

### `lib/widgets/primary_button.dart`
- Single full-width CTA contract: `kPrimaryButtonHeight` (52), `Radii.control` (16), label `bodyStrong`.
- **Three screens hand-roll a different height:** `sync_status_sheet.dart:203` and `:280` use **56**, `past_day_summary_sheet.dart:382` uses **54**. Replace with `PrimaryButton`.
- **`CompactButton` (40dp, radius 12) has zero call sites** despite `layout_insets.dart:30-31` documenting it as the "Photo / Describe / Adjust" row action — the exact row that `meal_detail_screen.dart:877-909` hand-builds at 14dp padding / 14sp. Use `CompactButton` there, or delete it.
- **~9 buttons set no `shape`**, so they fall through to the theme's `StadiumBorder` (`app_theme.dart:161`) and render as full pills sitting 10dp from radius-16 siblings: `photo_calorie_scanner_sheet.dart:1170,1178,1218,1293,1330,1340,1793`, `setup_sheets.dart:291`, `meal_detail_screen.dart:1042`. Pick one: either the theme's button shape becomes `Radii.control` (recommended — the app's language is soft rectangles, not pills) or every call site sets it. Do not leave both.
- The onboarding "Next" button (`onboarding_screen.dart:413-434`) is a **third** primary geometry (`h32/v16`, radius 16, 16/w800). Route it through `PrimaryButton`.

### `lib/widgets/app_text_field.dart`
It diverges from the app's own `inputDecorationTheme` on **three axes simultaneously**: padding `h20/v16` vs theme `h16/v16` (`:86` vs `app_theme.dart:219`), radius **16** vs theme **14** (`:75` vs `:210`), and it nulls the focus ring (`BorderSide.none` at `:84` vs the theme's 1.5px primary at `:215`).
- Pick one: `Radii.control` (16), padding `h16/v16`, and **keep the focus ring** — losing focus affordance is an accessibility regression, not a style choice.
- Make `inputDecorationTheme` match, then have `AppTextField` stop overriding.
- There are currently **six distinct field padding configurations** app-wide and the five numeric entry dialogs render fields at **three different heights (61 / 70 / 74)**. One height.
- The label-above-field pattern uses 8 different label styles across 8 sites (`app_text_field.dart:44`, `water:251`, `photo_scanner:1108,1505`, `add_progress_photo:155,198`, `body_stats:217`, `add_meal_slot:153`, `sync_status:156`). All → `eyebrow`, gap `Gap.x8`.

### AppBar — pick one treatment
There are currently **seven**:
- no AppBar + centered in-body 32pt title (`profile_screen.dart:70-81`)
- Cabinet 24/w800 centered + custom Row leading (`progress_screen.dart:607-621`)
- Cabinet 24/w800 centered (`weekly_summary_screen.dart:35-42`)
- Cabinet 24/w800 left + explicit leading (`reminders_screen.dart:53`, `backup_restore_screen.dart:475`)
- Cabinet bold / no size + explicit leading (`manage_habits_screen.dart:24`)
- plain `Text` → theme 20/w700 (`manage_plans:24`, `social_feed:44`, `connect:42`, `yearly_activity:13`, `exercise_progress:117`)
- no AppBar, hand-built header (`workout_screen.dart:139-228`, inset `fromLTRB(8,8,20,0)` — left edge at 8 while everything below is at 20)

**The contract:** Material `AppBar`, `centerTitle: false`, title = `screenTitle` token (Cabinet 24/w800), leading = `Icons.arrow_back_ios_rounded` at `IconSize.nav`, shown only when `Navigator.canPop`. Remove every per-screen `centerTitle: true` and every per-screen title `TextStyle`. `profile_screen` gets a real AppBar. `workout_screen`'s hand-built header either becomes an AppBar or adopts the same metrics exactly.

Also: `progress_screen.dart:602` uses a default-24 left chevron next to a `size: 16` right chevron in the same title Row — visually lopsided. Same bug at `activity_heatmap.dart:128` vs `:147`.

---

## §5 — Per-screen deltas

Apply §1–§4 everywhere, then these screen-specific fixes.

### Home — `lib/screens/home/`
The vertical rhythm is nearly right (24 above a section header, 12 below) but leaks through child margins.
- `home_screen.dart:202` — the one gap that breaks the pattern: `SizedBox(20)` where every sibling is 24. → `Spacing.section`.
- `meals_card.dart:189` — a trailing `SizedBox(16)` as the last child inside a card that already has 20 padding → **20 top / 36 bottom**. Delete it.
- `daily_insight_card.dart:42` uses `all(16)` — the only 16-padded card on Home. → `cardPad` (20). Its `:38` uses a literal 20 instead of `kScreenPadding`.
- `daily_insight_card.dart` has **no margin**, `coach_notes_card.dart:103` has `bottom: 12` — so the bottom of the scroll shifts 12px depending on which of the two renders. Remove the card's own bottom margin; the parent owns it.
- `daily_progress_grid.dart:281,:455` — `_StepsCard` and `_ProgressCard` are raw `Container`s at radius **24**, directly above `_WeeklySummaryLink` at radius **16** (`home_screen.dart:395`). Three radii in one stack. All → `Radii.card` (20), and make them `SurfaceCard`s so they pick up the shadow.
- `habits_card.dart` — card is `EdgeInsets.zero` (`:36`) with rows at `h20/v16` and a `SizedBox(2)` between (`:51`), giving a **34px** row-to-row gap from a "2px separator". Use `v12` rows with no separator, or keep 16 and drop the 2.
- `habits_card.dart:105-117` — a 48×48 box holding a 28×28 circle, then `SizedBox(width: 2)`. Net: the circle's visual left edge is 30px in, the label starts at 70px — a 40px optical gap expressed as `width: 2`. Size the box to the circle and use a real `Spacing.inline`.
- Tap targets for equivalent affordances are 48, 44 (`habits_card.dart:499`), and **20** (`coach_notes_card.dart:155`, constraints stripped — below the 48px minimum). Normalize to 44 minimum.
- `coach_notes_card.dart:211` — the loading state adds `vertical: 10` padding the data state doesn't have, so the card jumps 20px when the note arrives.
- `home_screen.dart:229-231` — an `Align` with **no child** in the root `Stack`. Delete.
- `home_screen.dart:219` — `SizedBox(height: 100)` magic number. See §7.

### Progress — `lib/screens/progress/`
- `progress_screen.dart` has **no screen-level padding**; five children self-pad at 24, 20, 12, 4, and 16. Hoist to one `Spacing.screen`.
- `progress_screen.dart:296` vs `:322` — the stat strip is inset 12 for 7 of 8 metrics and **20 for `MetricType.steps`**. The footer shifts 8px sideways when you swipe. Fix.
- `weekly_summary_screen.dart` gap run is `32, 24, 32, 16, 32, 16, 40, 40` — eight gaps, four values, no pattern. Rebuild on `section` (24) between blocks, `major` (32) around the hero only.
- `weekly_summary_screen.dart:93-100` — when `habitCompletionRate == 0` the habit card vanishes but both surrounding `SizedBox`es remain → a **48px** void appears from nowhere. Move the gap inside the conditional.
- `weekly_summary_screen.dart` — `_DailyScoresChartCard` and `_HabitChartCard` are siblings that **differ on every single dimension**: header icon 20 vs 16, header→chart gap 32 vs 24, chart height 140 vs 80, axis labels 12 vs 10, bar width 16 vs 10, bar radius 6 vs 3. Unify everything except chart height and bar width (those are legitimately data-driven).
- `shared_chart_card.dart:158-161` emits an **unconditional** `SizedBox(16)` before a *conditional* footer. Both `progress_screen.dart:519` and `chart_drilldown_sheet.dart:101` pass empty stat lists → 16px of dead space under the chart on both. Move the gap inside the conditional.
- `shared_chart_card.dart` — bottom axis labels get `top: 8` padding (`:361`), left axis labels get **none** (`:387`) and sit flush against the canvas. Give both `Gap.x8`.
- Five radii on `weekly_summary_screen` alone (24/20/16/12/12), four on `exercise_progress_screen` (16/20/12/14).
- `exercise_progress_screen.dart:258-260` — **the only bordered card in the app**, directly contradicting the `// Sthira: No borders!` comments at `workout_screen.dart:284`, `insights_card.dart:82`, `workout_screen.dart:561`. Remove the border.
- `activity_heatmap.dart:347` and `:373` both apply `bottom: 3` to the same rows → **6px** effective gap, while the height estimator at `:175` assumes 3. The `childAspectRatio` under-estimates card height by `3 × rows`. Fix the double-count and the estimator together.

### Workout — `lib/screens/workout/`
- `workout_screen.dart:140` — header at `fromLTRB(8, 8, 20, 0)`: **left inset 8, right 20**. Everything below is at 20. Fix to 20/20.
- `workout_screen.dart` gap run `12 → 4 → 12 → 10 → 0 → 16 → 12/16`. When `totalExercises == 0`, a child vanishes but its `SizedBox(4)` (`:250`) stays.
- `_SectionWidget:701,:778` — `margin bottom 24` **plus** a trailing `SizedBox(8)` = 32 between sections.
- `_SectionWidget:707` — section header inset 4 horizontally while the `ExerciseCard`s below it are at 0 inside the same list. Align to 0.
- **Card-to-card gap changes based on content:** 16 without a rest timer, 24+ with one (`ExerciseCard` margin 12 + `RestTimerLabel` `vertical: 6` ×2). Make the gap constant and let the timer label live inside it.
- `rest_timer_label.dart:31` — `horizontal: 16` inside a list already padded 20, so its divider rule sits **36px** from the screen edge while the cards sit at 20. → 0.
- `exercise_card.dart` — `padding: zero` then re-pads internally at **14** (`:63`) with a **bottom of 8** (`:374`). Asymmetric box. → `cardPad` 20 / `cardPadTight` 16, symmetric.
- `exercise_card.dart:203` vs `:376` — metadata `Wrap(spacing: 8)` directly above an action `Wrap(spacing: 24)`. 3× mismatch in adjacent rows.
- `log_data_dialog.dart:227` — a 48dp `OutlinedButton` stacked **10px above** a 52dp `PrimaryButton`, different radii (12 vs 16). Same height, same radius.
- `log_data_dialog.dart:370,:405` — ± stepper tap targets are 34px (8 + 18 + 8). Below minimum.

### Profile — `lib/screens/profile/`
- `profile_screen.dart` — `_MenuCard` (radius **24**, padding `all(20)`, icon inset 20, subtitle **12**, pitch **96**) and `_SettingsSwitch` (radius **20**, padding `h16/v8`, icon inset **16**, subtitle **13**, pitch **84**) are interleaved in one visually continuous stack of 12 rows. **This is the most visible inconsistency in the app.** One row component: radius `Radii.card`, padding `cardPad`, title `bodyStrong`, subtitle `caption`, icon tile 44×44 at `Radii.chip`, icon `IconSize.row`, gap `Spacing.inline`, trailing chevron `IconSize.inline`, one pitch.
- Same for `backup_restore_screen.dart:662` `_ActionCard` (16/16, title 16, gap 4, subtitle 13) and `reminders_screen.dart:321` `_buildToggleCard` (16/16, title 16, gap 4, subtitle 13) — three implementations of one row.
- `profile_screen.dart:190-192` — if `badges.isEmpty`, `TrophyRoomCard` returns `SizedBox.shrink()` and the CloudSync card sits **flush (0px)** against the first menu card. Gap must live in the parent.
- `trophy_room_card.dart:41` — `horizontal: 16` **stacking on the parent's 20** → the trophy card sits at **36px** while every sibling sits at 20; its label at `:46` adds another 4 → 40. Remove.
- `trophy_room_card.dart:71-72` — `Wrap(spacing: 8, runSpacing: 24)`. 3× mismatch.
- `trophy_room_card.dart:258` vs `:277` — unlocked medallions are 52px, in-progress ones are 56px (the ring). Row is ragged. Make the ring fit inside 52.
- The profile header block consumes **~297px before the first stat card** (title block ~74 + header ~223, avatar 100×100). Bring the avatar to 72 and use `screenTitle` for the page title in a real AppBar; that recovers ~90px above the fold.
- Avatar is 100×100 in view (`:122`) and 80×80 in edit (`:1377`) with the same 32pt initial and a 40px fallback icon sized for neither. One size.
- `manage_habits_screen.dart:60` — `fromLTRB(0, 8, 0, 100)`: **zero horizontal padding**, rows fall back to ListTile's default 16. And the bottom 100 is for a nav bar that isn't there (this screen is pushed on the root navigator from `home_screen.dart:465`).
- `manage_habits_screen.dart:126-223` — ~128px of trailing furniture per row (two 48px IconButtons + 8 + a 24px icon). Collapse.
- `manage_plans_screen.dart` — header strip at 20 (`:45`,`:167`), tab bodies at **16** (`:371`,`:500`,`:570`). Content jumps 4px at the boundary.
- `backup_restore_screen.dart:491` — `all(24.0)` screen inset, and the body is a plain `Column` with **no scroll view** → overflows on short screens. Fix both.
- `reminders_screen.dart` — section header gap is **24 above / 8 below** (`:106` vs `:299`) and the header is indented 4 while its card is at 20. → 24/12, indent 0.

### Social — `lib/screens/social/`
- **Every inset in `social_feed_screen.dart` is 16, not 20** (`:109,:122,:144,:236,:417,:472`), except `:253` which is 24. → `Spacing.screen`.
- `social_feed_screen.dart:606` — the "me" leaderboard row gets `padding: all(8)` while every other row gets `vertical: 8` only. The current user's row is indented 8px and 8px taller than its neighbours. Same padding, use background color for the distinction.
- `social_feed_screen.dart:791-814` — the skeleton row has a **48px avatar + 16px gap**; the real row it replaces has a **40px avatar + ListTile's default gap**. Visible jump on load. Match them.
- `social_feed_screen.dart:164-167` — the processing state (`Padding(all(12))` + 24px spinner) is a different width than the two-button state, so rows shift while a request resolves. Fixed-width trailing slot.
- `friend_status_card.dart` — bottom margin is **32** when the profile loads (`:59`) and **24** when it's null/loading (`:25,:140,:143`). A mixed list has alternating gaps.
- **A friend's name renders at four sizes**: 18 (`friend_status_card.dart:75`), 16 (`:31`), 16 (`social_feed:151`), 16 (`social_feed:621`). One token.
- **The avatar renders at two sizes**: 48 (`friend_status_card.dart:198,:217`) vs 40 (`social_feed:279,:685`).
- `friend_status_card.dart:323-386` — `_StatBlock` has 4px above the value and **0px below it**, so the label collides with the numeral while the icon floats. And the Streak column has no progress bar, making it **12px shorter** than its two neighbours in a `spaceAround` Row — the row is bottom-ragged. Reserve the bar's space.
- `connect_screen.dart` — the two tabs of one screen use different insets: `margin horizontal 32` (`:139`) vs `padding all(24)` (`:308`). And the label→content gap is 24 in one tab, 16 in the other.
- `connect_screen.dart:106,:315` — the section label omits `fontFamily`, so it renders in **General Sans** while the byte-identical style at `reminders_screen.dart:304` and `backup_restore_screen.dart:569` specifies Cabinet Grotesk. Same intent, two typefaces.

### Meals & entry dialogs
- **The six numeric entry dialogs (water/sleep/weight/steps/body_fat/timer) should be near-identical and diverge on 15 axes.** Extract a single `NumericEntrySheet` component. The divergences to collapse:
  - input font 24 / 32 / 32 / 32 / 32
  - `contentPadding` `h16v16` / theme / `h20v18` / theme / `h20v18`
  - fill `colors.card` (water only) vs `inputFill`
  - water has a visible border + 2px focus ring; the other four have **no border and no focus ring at all**
  - suffix 16/no-weight (water) vs 18/w600 (the rest)
  - water has no hint style; the rest use Cabinet 32/w800
  - `autofocus` true on weight/steps/body_fat, false on water/sleep
  - `textAlign` left on water, center on the rest
  - error display: none (water) / manual centered (sleep) / manual left (weight, steps) / `errorText` at Material's 12sp (body_fat)
  - clear action: `Expanded` TextButton beside the CTA (water) / TextButton in the title row with padding stripped (sleep, steps) / same but **without** the padding override so it renders 64×36 (body_fat) / `OutlinedButton` beside the CTA (timer) / **none** (weight)
  - title left-aligned on five, **centered** on timer
  - gap→CTA 24 on five, **40** on timer
  - bottom padding: none / `padding.bottom` ×4 / `padding.bottom + 8`
  - body_fat puts a prefill note **after** the CTA
- `timer_entry_dialog.dart:225-230` — the 48pt countdown omits `fontFamily`, so the app's most prominent live numeral renders in General Sans. Every other big numeral is Cabinet.
- `day_complete_sheet.dart:93-97` — same omission on the 22pt title.
- `meal_detail_screen.dart:1192-1194` — `_ProvenanceExplanationSheet` adds `horizontal: 24` **inside** `AppSheet`'s 24 → **48px** horizontal inset.
- `meal_detail_screen.dart:806-841` — Add Serving / Repeat / Replace use `padding: zero`, `minimumSize: Size.zero`, `shrinkWrap` at 13/w600. Sub-minimum tap targets on primary actions.
- `photo_calorie_scanner_sheet.dart:1016` vs `:1039` — 'Camera' is `w700`, 'Gallery' is `w600`, in the same Row.

### Onboarding — `lib/screens/onboarding/`
- **Title sizes across the flow: 48 (welcome) / 40 / 40 / 40 / 32 (completion).** Five sizes for one role. All → `metric` (44) for welcome, `display` (32) for the rest — or pick one. Welcome's 48 also omits `height:` while the other three set `h1.1`.
- Top padding: 32 / 32 / **64** / **64** across four pages.
- Hero mark: welcome is a **120×120 image**, the other three are **size-48 icons**. Not reconcilable as-is; at minimum give the three icon pages the same top padding and mark→title gap.
- Bottom spacer: 24 / 48 / 48 / 48.
- `onboarding_screen.dart:367` — `_NavButtons` is inset `horizontal: 32` while every page's content is at **24**. The Next button sits 8px inboard of everything above it.
- Pages hardcode `Colors.white` for titles (`welcome:154`, `about_you:162`, `your_plan:169`, `connect:122`) and `Color(0xFF0F1513)` for the scaffold (`onboarding_screen.dart:235`, `welcome_page.dart:456`) while their cards use `context.colors.*` — in light mode you get light cards on a hardcoded dark background. Route through `context.colors`.
- `sthira_aura_background.dart:4` takes `currentPage` and **never reads it** — the background is static across all four pages. Either use it or drop the parameter.
- Mixed `withOpacity` / `withValues` within the same flow. Pick `withValues`.

### Photo screens
- `physique_pictures_screen.dart:296` and `photo_compare_screen.dart:255` — both are 3-column grids with `crossAxisSpacing: 8, mainAxisSpacing: 8` and **neither sets `childAspectRatio`**, so tiles default to 1.0. Set it explicitly.
- Same thumbnail, two radii: **12** (`physique:337`) vs **8** (`photo_compare:288,299`).
- Same pose badge, two paddings: `h6/v2` (`physique:383`) vs `h4/v2` + `fontSize: 9` (`photo_compare:310-330`).
- `physique_pictures_screen.dart:253` — a `horizontal: 40` inset found nowhere else in the app.
- `photo_viewer_screen.dart` has a top overlay with no `SafeArea` and no bottom overlay padding.

---

## §6 — Verify the rhythm holds

After the per-screen work, every scrollable screen must read as:

```
[ AppBar / page header ]
  Gap.x24
  SectionHeader
  Gap.x12
  content (cards separated by Gap.x12)
  Gap.x24
  SectionHeader
  Gap.x12
  content
  Gap.x32
[ bottom clearance ]
```

Non-negotiables:
- **All vertical rhythm lives in the parent column.** No child contributes its own top/bottom margin. The current 40px greeting gap, the 32px workout section gap, and the 52px yearly-activity gap are all double-counts of exactly this kind.
- **Every screen's horizontal inset is `Spacing.screen` (20).** No exceptions, including sheets' *content* (sheets themselves use `sheetPadH` 24, applied once by `AppSheet`).
- **A section's gap is owned by the section.** If a section can conditionally disappear, its gap disappears with it.

---

## §7 — The bottom-nav clearance bug (real, not cosmetic)

`kShellScrollBottomPadding = 116` (`layout_insets.dart:10`) is honored by **exactly one of seventeen** shell screens — `meal_detail_screen.dart:103`. The other sixteen end at 100, 24, 20, 16, or nothing. Content is reachable-but-cramped or hidden under the floating nav on most of the app.

Compounding it: `layout_insets.dart:5` documents *"Body uses [extendBody]"*, but **`extendBody` is never set anywhere in `lib/`** — the Scaffold at `app_router.dart:295` does not set it. So the nav bar already consumes layout height, and any screen that also adds 100/116 is double-padding.

**Resolve this properly:**
1. Determine which is true — either set `extendBody: true` on the shell Scaffold and keep the clearance constant, or drop `extendBody` and reduce the constant to just breathing room. Measure the actual occupied height: `64` (bar) + `16` (bottom pad) + `safeArea.bottom` ≈ 80–114 (`app_router.dart:482-488`).
2. Apply the result to **all seventeen** shell screens listed in §5. `shellScrollPadding()` (`layout_insets.dart:33`) exists for exactly this and has **zero call sites** — use it or delete it.
3. Screens pushed on the **root** navigator (`manage_habits_screen.dart:60` pads 100, `exercise_progress_screen`, `youtube_player_screen`) have no nav bar and must not pad for one.
4. The nav pill is inset `horizontal: 32` (`app_router.dart:482`) while content is at 20 — it sits 12px inboard of every card. Consider 20 for alignment, but this is a judgement call: check it visually before committing.
5. The rest-timer banner injects an extra `76.0` of bottom `MediaQuery.padding` when active (`app_router.dart:300`) and floats at `bottom: 16` — under the nav pill's own `bottom: 16`. Verify they don't overlap.

---

## §8 — Dead code found during the audit (delete, low risk)

These are confusing future readers and some are actively misleading:

- **`cardTheme` / `CardThemeData`** (`app_theme.dart:116-122`, `:404-410`) — **zero consumers**. No bare `Card(` widget exists in `lib/`. Its radius 24 contradicts `kCardRadius` 20, and `layout_insets.dart:16` claims they match.
- **`bottomNavigationBarTheme`** (`app_theme.dart:140-154`, `:428-442`) — dead; the shell uses a custom `_CustomNavBar` (`app_router.dart:469`) that renders no labels.
- **`shellScrollPadding()`** (`layout_insets.dart:33-40`) — zero call sites. Use it (§7) or remove it.
- **`InsightsCard`** (`lib/screens/progress/widgets/insights_card.dart`) — never instantiated; `progress_screen.dart:19` imports it unused.
- **`_buildRectStat`** (`progress_screen.dart:357-390`) — never called.
- **`lib/screens/home/widgets/daily_share_card.dart`** — referenced nowhere. It duplicates `lib/share/daily_share_layout.dart` with different geometry (headline 32 vs 42, score 32 vs 100/84). Two parallel implementations, one live, one orphaned.
- **Empty `Align`** with no child (`home_screen.dart:229-231`).
- **`ai_meal_suggestion_card.dart`** is in `screens/home/widgets/` but its only call site is `meal_detail_screen.dart:149`. Move or note it.
- Unused imports: `progress_screen.dart:6` (`layout_insets.dart`), `meals_card.dart:10` (`app_typography.dart` — imported, never called).
- `chart_drilldown_sheet.dart:4-8` uses absolute `package:trufit_bodamma/...` imports while every sibling uses relative. Normalize.

---

## RULES OF ENGAGEMENT

1. **Work in the order given.** §1 → §2 → §4 → §3 → §5. Tokens before components before screens. If you go screen-first you will re-do the work.
2. **One commit per section** so each step is reviewable and revertable.
3. **Run `flutter analyze` after each section.** Zero new warnings.
4. **Run the existing test suite after each section.** Widget tests that assert on sizes will break — fix the test to the new token, don't weaken the assertion.
5. **Screenshot every screen before and after.** Home, Progress, Workout, Profile, Social, Meals, each of the 6 entry dialogs, each of the 4 onboarding pages. Compare side by side in both light and dark.
6. **Do not add any value outside the token sets.** If a layout genuinely needs a gap, radius, icon size, or font size that isn't in §1/§2 — stop and tell me which one and why. Do not quietly add an 11th font size.
7. **Push back on me.** If any instruction here makes a screen worse, say so with the specific screen and your reasoning rather than following it. Two I am least sure about: dropping the 72pt weekly score to 44, and aligning the nav pill from 32 to 20.

## DEFINITION OF DONE

- `lib/theme/app_spacing.dart` exists and is the only source of gaps, radii, and icon sizes.
- `app_typography.dart` defines exactly 10 tokens; `TextTheme` aliases them; the two no longer contradict.
- Inline `TextStyle(` count in `lib/` drops from **698** to under **60**, and every survivor is a `copyWith(color:)`.
- Distinct `fontSize` literals: **22 → 0** (all via tokens).
- Distinct `BorderRadius.circular(N)` literals: **17 → 0** (all via `Radii`).
- Distinct icon `size:` literals: **15 → 0** (all via `IconSize`).
- Every screen's horizontal inset is 20. Every sheet's is 24, applied once by `AppSheet`.
- Every full-width primary CTA is 52dp.
- Every AppBar is identical.
- All 17 shell screens have correct bottom clearance and nothing hides under the nav.
- The Home greeting is Cabinet Grotesk, left-aligned at 20, with a persistent date eyebrow, one weight, and proper top breathing room.
