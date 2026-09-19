# Yearly heatmap remodel

> Follow-up: See [remaining analysis implementation](pending-analysis-fixes.md) for subsequent fixes and final verification. Findings and test counts below describe their original review checkpoint.

Implemented 19 September 2026. The user wanted a useful yearly view: the previous layout showed part of one large month and required excessive scrolling.

## Result

The first card now presents twelve compact, Monday-aligned calendars. At 390 × 844 logical pixels and normal text size, all twelve months are visible in the initial viewport, with the December tile above the reserved floating-navigation area. The grid uses three columns at this size, two on narrow screens or with larger text, and four where the available width supports them. Accessibility takes precedence over forcing the entire year into a smaller viewport.

The map comes before its statistics. The existing fonts, peach accent, forest/cream surfaces and rounded cards are retained. One page scroll replaces the constrained chart and fixed explanatory footer. No changes to the main Progress hero cards were needed.

Tap a month to open a readable calendar sheet, then inspect a day. Inspection stays in the heatmap; the explicit **View day** action updates Home's selected day and week before navigating. Future days are visibly distinct and cannot be selected. Month/day semantics include the full date and recorded-data state. Year controls include a return to the current year and prevent browsing future years.

## What the colors mean

Intensity represents one to four recorded areas: habits, workouts, meals and wellbeing. It does not claim that a goal was achieved or assess a person's health. A saved zero, partial habit, skipped workout or reflection is still a recorded entry; its detail remains factual. Blank metadata records are excluded.

The summary shows days recorded, the longest consecutive run of recorded days within the displayed year, and the number of months with entries. No-entry days remain neutral. Future dates have a separate outlined state. Historical records are not re-scored using today's habits, meal targets or workout plan.

## Data and responsiveness

An immutable calendar model collects the year's records using four filtered bulk reads inside one Isar read transaction. This replaces per-day repository lookups and DailyScore calculations. No device timing claim is made: the reduced query/score work is verified in the implementation, not a benchmark.

Lazy database watchers refresh all four areas, including edits to historical dates. The provider captures the active account database, observes account transitions and the injected clock, and releases subscriptions when no longer used. Exercise-only records, archived-habit entries, explicit overrides, meal photos and zero-valued wellbeing entries are included. Leap days and strict date keys are handled; future and malformed records are excluded.

## Validation

- 22 focused tests passed: four model, three native Isar/provider and fifteen widget tests.
- Full Flutter suite: **537 passed, 1 existing skipped test**, no failures.
- Widget coverage includes 320/390-pixel widths, light/dark themes, 100%/200% text, empty/error states, retry, year navigation, future-date semantics and deliberate Home navigation.
- All 30 September date labels are checked for clipping in all eight responsive combinations using the bundled fonts.
- Both populated-year themes assert that December remains within the initial 390 × 844 viewport above navigation clearance.
- Scoped analysis of the seven heatmap implementation/test files has no issues. Broader lib/test analysis has no errors; unrelated warnings and lints remain.
- Whitespace checks pass.

Captures were generated from the widget implementation using explicitly synthetic fixture records, not a user's account:

- Dark overview: `build/heatmap-review/year-dense-390-1x-dark.png`
- Light overview: `build/heatmap-review/year-dense-390-1x-light.png`
- Large-text detail: `build/heatmap-review/month-320-2x-light.png`

The captures use a test router and do not render the app's floating navigation; its clearance is asserted separately. No Android device/emulator was available, so native navigation, insets and touch behavior still need a device pass before release.

Test logs: `build/heatmap-final-focused-tests.log`, `build/heatmap-full-suite.log`, `build/heatmap-scoped-analysis.log` and `build/heatmap-final-analysis.log`. Preview images and logs are local build artifacts rather than shipped assets.

## Separate findings

Meal/workout seed and remaining Progress findings are documented in [the follow-up review](seed-and-progress-follow-up-review.md). Those recommendations are not implemented by this heatmap change.

No seed content, database schema or stored records were changed by the remodel. No commit, push or deployment was performed.
