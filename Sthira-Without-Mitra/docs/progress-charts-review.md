# Progress charts: experience and data review

The existing forest/peach palette, Cabinet Grotesk and General Sans fonts, rounded surfaces and restrained motion remain. This change focuses on reading and understanding personal records without adding decoration or AI calls.

## What changed

- The title opens a direct metric picker. Each metric remembers its selected range. Switching metrics returns to the top of the overview.
- The range shows exact dates. The prior comparison period covers the same number of calendar days; comparisons do not claim that a rolling range is a calendar week or month.
- Body metrics show the latest actual measurement and its recorded date, even when the graph shows weekly/monthly averages. An older aggregate without individual observations is labeled as a period average instead.
- Activity summaries describe recorded days. Nutrition uses "logged" throughout and makes incomplete food-log coverage explicit. Sleep describes duration rather than sleep quality.
- Summary statistics match the metric: first/latest/change for body measurements; recorded total, current-goal days and coverage for steps; shortest/longest/coverage for durations; logged average/current target/coverage for nutrition.
- Tap or horizontally scrub a graph to inspect a date. The readout and selection marker stay visible; inspecting never navigates away. "View day" and "View daily details" make navigation explicit. The daily-details sheet follows the same pattern.
- A readable, expandable records list provides an alternative to graph gestures. Missing entries remain missing; recorded zeroes have a visible baseline marker.
- The local KG/LB control converts the overview, observations, summary, goal and daily-details view without modifying the saved profile preference.
- A thin, labeled current-goal line replaces the broad goal band. Red low-point markers and competing shaded series were removed. Body trend lines require at least three readings in a seven-day window and preserve missing-day gaps.
- At narrow widths with enlarged text, toolbar actions move below the title so full metric names remain readable.
- Date-axis density follows available space and text size. The plot keeps a minimum height; surrounding content scrolls and summary statistics wrap. Reduced-motion settings remain respected.
- BMI requires an explicitly entered, finite, positive height. The Progress screen no longer substitutes the profile model's fallback height.

## How comparisons stay honest

The aggregate service keeps the dates and values of the underlying readings. Averages are weighted by recorded days rather than treating each bucket equally. Future dates and non-finite values are excluded. Missing days do not become zeroes.

Both the current and prior period must independently have sufficient observations. Activity and nutrition need at least three recorded days and 50% coverage. Body measurements use a weekly measurement cadence (at least one and approximately one per seven eligible days), with a date-spread check when multiple readings are needed. Comparisons are omitted when that evidence is absent.

For steps, screen time and nutrition, the live average and coverage may include today so far. Period comparisons exclude today's still-accumulating value and explicitly describe the average over completed days. Nutrition comparisons describe logged amounts, not an inferred full day's consumption. Zero-baseline comparisons use an absolute difference rather than a percentage. Body-fat changes use percentage points.

A goal is labeled "current" because it is the user's current setting, not a historical target snapshot. Calories above a goal are not presented as an achievement. The chart describes data and does not prescribe changes to eating or exercise.

## Verification

Focused tests cover aggregation, comparison evidence, missing/zero values, actual-versus-average readings, height validation, chart inspection, axis spacing, duration formatting, units, range memory and explicit navigation. Populated 320px screens at 200% system text are included; the render harness checks for layout exceptions before capturing the existing fonts in light and dark themes.

The broad suite reached 329 passing tests and one existing skipped platform-channel placeholder, then stalled in an unchanged coach-note/native-database test. That run was stopped; all three coach-note tests passed in a bounded isolated retry. After the final header adjustment, all 11 main Progress/responsive-control checks passed, along with seven actual-font preview scenarios. The remaining focused checks also passed: 13 shared-chart checks, 11 daily-details checks, 23 insight checks and eight provider checks. Analysis reports no issues in the changed Progress files; four existing informational lints remain in the untouched weekly-summary screen. This is not represented as a single uninterrupted passing full-suite run.

Relevant source tests are in:

- `test/services/progress_aggregation_service_test.dart`
- `test/services/progress_insight_service_test.dart`
- `test/providers/progress_chart_provider_test.dart`
- `test/widgets/shared_chart_card_test.dart`
- `test/screens/progress/`
- `test/screens/responsive_screen_controls_test.dart`

Run the tests with an installed Flutter SDK:

```sh
flutter test --no-pub --reporter expanded
```

Real-device touch and screen-reader checks remain useful before release. This is not a claim of usability testing with participants. Native Android build validation remains unavailable in this workspace because the Android SDK is not installed.

All changes remain local and uncommitted. Review PNGs and temporary Flutter tooling are generated under ignored `build/`; they are not needed in a source ZIP. Export the project source, assets, tests, documentation and dependency manifests, omitting `build/` and `.dart_tool/`. A recipient with Flutter installed can restore generated dependencies with `flutter pub get`.


## Follow-up implementation — 19 September 2026

Current Steps/Sleep goals are now independent of the day browsed on Home. Differing configured targets/directions receive an explanation instead of an arbitrary reference line. A distant weight goal stays visible as an above/below-chart annotation without expanding the measurement axis. Empty nutrition views open meal logging for today; saved incomplete nutrition is disclosed and excluded from the affected metric instead of appearing as zero, including in daily details.

Weekly habits now distinguish unscheduled, unrecorded and recorded-zero states, disclose completed/recorded/scheduled counts, and support the same local inspection plus accessible records list as the main chart. Weekly share exports preserve missing data, actual normalized score and partial-week coverage. Current/previous schedule predicates are consistent, and habit creation dates use the shared local-calendar rule. The centralized follow-up run passed all 75 focused Progress/provider/chart/drilldown/weekly/share tests; the verification counts above describe the earlier chart pass.
