# Sthira UI experience review

> Follow-up: See [remaining analysis implementation](pending-analysis-fixes.md) for subsequent fixes and final verification. Findings and test counts below describe their original review checkpoint.

The current identity is worth keeping: Cabinet Grotesk headings, General Sans reading text, Caveat for the Gita interpretation, forest surfaces, warm peach highlights, softly rounded cards and the floating navigation. The highest-value improvements are legibility, predictable interactions and layouts that accommodate real content. Replacing fonts or adding effects would not address the issues found.

## Scope and evidence

Reviewed the shared theme, type/spacing/motion tokens and controls, plus Home, calendar, meals, Progress, profile, avatar picker and trophy components. Checked the actual widget implementations rather than applying a visual redesign. Targeted widget tests cover narrow screens, enlarged system text, action semantics, keyboard input and clock transitions. Component and trophy previews are rendered by Flutter with the bundled fonts. This is not a claim of a complete accessibility audit or usability testing with participants.

## Typography and hierarchy

Keep the existing scale. Its roles already form a coherent hierarchy:

| Role | Existing size | Intended use |
| --- | --- | --- |
| Metric / display | 44 / 32 | A primary number or a large card readout |
| Screen title | 24 | Screen, sheet and personal greeting |
| Card title | 17 | A specific tile or card |
| Section label | 16 | Groups such as Meals and Trophy room |
| Body / strong body | 15 | Reading and list content |
| Caption | 13 | Dates, field labels and supporting information |
| Micro / eyebrow | 11 | Short, secondary metadata |

Promoted shared field labels, the greeting date and trophy captions to the existing 13px role. Trophy headings now use the same sentence-case section style as Home. There are no new type sizes or font families. Full badge names can wrap rather than being ellipsized, and full personal names remain visible.

## Changes and why they add value

| Area | Issue found | Result |
| --- | --- | --- |
| Primary actions | Fixed height could clip scaled text; loading replaced all context with a spinner; disabled labels overrode button colors | Minimum height with natural growth, retained label and announced progress, coherent enabled/disabled foregrounds |
| Compact actions | Fixed 40px box and single-line ellipsis; label explicitly used muted caption color even on filled buttons | Padded touch targets, wrapping labels, inherited button foregrounds |
| Section headings | Trailing actions were reconstructed and forced into a 24px box; title/count could crowd them | Original action properties retained, 48px icon targets, wrapping title/count and heading semantics |
| Actionable cards | Gesture-only activation; empty outer gutters opened cards; press motion ignored reduced-motion preference | Native focus/keyboard/hover feedback, card-only hit region, reduced-motion support; supplied borders and geometry preserved |
| Light theme | White content on peach in ColorScheme, pale text on selected segments, peach small text on white surfaces | Existing dark onPrimary and existing warm-brown accent used for readable foregrounds; peach fills preserved |
| Profile | Avatar actions lacked accessible labels/keyboard feedback; focused profile fields had no visible focus outline | Framed, labeled avatar actions and visible field focus |
| Trophies | Fixed three-column aspect ratio plus tiny truncated names; faded progress labels | Up to three columns according to width/text scale, natural heights, complete labels and clear progress; award borders/progress rings retained |
| Meals | Three macro pills were forced into one row | Pills wrap when needed |
| Progress | Range controls and chart title/unit could overflow on narrow screens at large text sizes | Reachable scrolling range controls, selected-state semantics, 48px targets and wrapping chart titles; toolbar actions are labeled |

Press feedback remains brief and restrained. The extra repeating shimmer on loading primary buttons was removed because the progress indicator already communicates work. No additional decorative motion, shadows or marketing content was introduced.

## Greeting and date

The greeting is a small but useful part of the experience when it communicates context accurately:

- Today retains the existing personal greeting, full name and 24px title hierarchy.
- The selected date uses readable title case at 13px. A different year is shown explicitly.
- A past day says "Your day in review"; a future day says "Your day ahead". This avoids presenting today's greeting as context for another day's records.
- "Return to today" has its own native, comfortably sized action and resets both the selected day and displayed week.
- The greeting refreshes at noon, 17:00, midnight and app resume using a single scheduled boundary timer, not periodic polling. Existing selected-date and midnight-rollover provider behavior remains unchanged.

No new greeting carousel, motivational slogan, weather or redundant hero section is needed.

## Border policy

Borderless surfaces are a visual preference, not a universal prohibition. Keep a border when it communicates identity, selection, progress, focus or an action boundary:

- Circular frames for profile images/avatars.
- Selected avatar outlines and checkmarks.
- Trophy medallions and locked-progress rings.
- Focused inputs and outlined secondary actions.
- Compact semantic pills where their boundary improves scanning.

General cards continue to use the current surface contrast and rounding; no blanket border migration was applied.

## Validation and review

The complete relevant UI suite passed 35 checks (33 behavioral/theme checks and 2 preview-render checks). The regression suite exercises 320px screens with 2x system text, trophies up to 3x, large names, keyboard activation, nested controls, cancelled presses, reduced motion, disabled/loading states, time-of-day transitions and date reset. Theme checks verify at least 4.5:1 contrast for section accent text and primary-button content on their tested surfaces.

Reproduce the relevant screen/control checks:

```powershell
build/tooling/flutter/bin/flutter.bat test --no-pub --reporter expanded test/widgets test/screens test/theme_test.dart
```

Generate review images with bundled fonts:

```powershell
build/tooling/flutter/bin/flutter.bat test --no-pub --dart-define=UI_PREVIEW=true test/widgets/ui_components_test.dart test/screens/profile/trophy_room_card_test.dart
```

For emoji in headless trophy previews, optionally set `UI_EMOJI_FONT` to a local emoji font path (on Windows, `C:\Windows\Fonts\seguiemj.ttf`). This font is used only by the preview harness and is not bundled with the app.

Images are written to ignored `build/ui-review/`. The component sheet is a review composition of actual widgets, not a new product screen. Device testing with TalkBack/VoiceOver and real touch input remains useful before release.

## Deliberately deferred

Further candidates found during inspection include calendar day cells at very large text scales, faded zero-state journey statistics, a few remaining fixed metric rows and switch-label semantics. These deserve focused changes and relevant tests, rather than a blanket migration. The navigation's current shape, font pairing, established spacing scale and brand palette did not need a redesign.

All UI changes in this review remain local and uncommitted.
