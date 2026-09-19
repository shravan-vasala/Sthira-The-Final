# Remaining analysis findings: implementation

Latest follow-up: [Daily Check-in and remaining audit fixes](daily-check-in-and-pending-fixes.md) — 797 passing Flutter tests, one existing skip; current completion and release boundaries.

> Subsequent review: [water, sleep, reflection, photos, startup and widgets](final-experience-review.md) found additional edge cases outside the 628-test checkpoint below. Those confirmed fixes and the Home avatar are now implemented; see [final experience fixes](final-experience-fixes.md) for current verification and device checks.

19 September 2026. Follow-up to the app-wide experience, seed/Progress and service audits. The earlier reports describe their original audit checkpoints; this document records the subsequent implementation. Existing hero cards, fonts, colors, navigation and useful avatar/trophy borders are preserved.

The user confirmed that the bundled meals and exercises come from experts. Their recommendations, guidance, food quantities and exercise prescriptions have not been rewritten. Missing nutrient or duration information is not invented.

## Manage Plans and expert suggestions

- Customize makes and selects a user-owned copy, keeping the expert original available. Meal and workout copies retain their origin; user edits survive seed/catalog refreshes.
- Workout program length is editable, including 8 and 10 weeks. Repeating weekly routines and distinct week schedules both work. An unspecified repeating duration stays ongoing.
- Extending a distinct-week plan repeats its last week; the editor explains this. Exercises and individual-week detail remain editable through the existing Advanced JSON editor/import flow.
- Saving refreshes the active plan immediately. Unsaved work is protected during plan/tab/back changes. Invalid data retains the draft and shows a recoverable error.
- Plan calorie totals stay distinct from the user's personal target. Customizing a plan does not silently change the profile target.

## Completed findings

| Area | Result |
|---|---|
| Expert meal logging | Ingredient quantity and nutrition completeness persist independently. Unknown macros no longer become invented ingredient values. Known zero remains different from unknown. Meal logging retains photos and appended packaged-food entries. Scanner editing cannot confirm unknown macros without explicit input; appending to older aggregate-only data preserves its saved subtotal. |
| Nutrition summaries | Progress, weekly summaries, shares, widgets and past-day summaries disclose incomplete nutrition or omit misleading totals/goal comparisons. |
| Real workout seeds | Stable occurrence IDs separate repeated exercise names. Unique legacy logs remain available; ambiguous history is retained without counting one log as multiple exercises. Empty sections do not dilute completion. The shipped Sunday resolves as rest. |
| Timed exercises | Duration is stored and logged in seconds, survives native persistence/backup and participates in activity detection. Unspecified time remains unspecified. Unsupported prescriptions are not relabeled as reps. |
| Progress and weekly score | Chart goals are independent of Home's selected date. Weekly comparison periods use consistent schedule rules. Recorded zero, unrecorded and unscheduled habits are distinct. Daily habit bars are inspectable. Distant weight goals do not flatten the measured range. |
| Onboarding | Large-text layouts, optional integration copy and preset/estimate labels are refined. Restored account data is adopted instead of overwritten by a stale draft. |
| Habit management | Paused and off-day habits remain editable. Editing preserves creation date and goal direction. Weekday controls wrap and announce selection. Newly created habits do not rewrite earlier denominators. |
| Streaks and achievements | Real recorded dates, configured goals and applicable schedules determine counts. Arbitrary 30/60-day caps and invented goals are removed. Missing dates break relevant runs; earned badges remain earned. Account and background changes refresh safely. |
| Profile | Cloud state is truthful; journey stats and macro fields fit narrow/large-text layouts. Numeric validation is inline, edits recover on failure and account changes cannot redirect a pending save. Avatar cleanup cannot turn an already saved profile into a reported save failure. |
| Numeric and body-stat entry | Values retain their date/account context; duplicate saves are blocked and failures keep the draft. Invalid water input cannot delete a prior record; zero is a real reading and Clear is explicit. Body-stat numbers are validated and stored measurement units preserved. |
| Reminders | Denied permissions/scheduling errors are visible. Time and weekday controls adapt to larger text. Time-picker results cannot update a different account. |
| Photos | Deletion resolves the entire selection across filters. Camera failure retains pose/weight/note, weight units are explicit, invalid values are rejected and missing previews are handled. Comparison has an accessible slider and adaptive controls. |
| Sharing | Success, cancellation, unavailable confirmation and failure are separate outcomes. Failed/cancelled shares retain the preview, duplicate exports are blocked and images/overlays are disposed. |
| Home and small controls | Home respects the top system inset. The quiet reflection launcher has a named, accessible action without changing its visual role. |

Earlier account lifecycle, cloud sync, social rules, backup recovery, AI cancellation, barcode logging, calendar, workout flow and yearly heatmap fixes remain in the working tree. See [service fixes](service-fixes.md), [calendar/workout review](calendar-workout-review.md) and [yearly heatmap review](yearly-heatmap-review.md).

## Data compatibility

Native data schema is now 6. New fields are additive: nutrition certainty, logged durations and custom-plan origin. Complete native schema 4 and 5 backups remain accepted with compatible unknown defaults; older backups are not made artificially certain. Unsupported/incomplete snapshots remain rejected before replacement. Source seed files remain unchanged.

## Verification

- Full maintained Flutter suite: **628 passed, 1 existing integration test skipped, 0 failures**. Log: `build/pending-fixes-verified-suite.log`.
- Full static analysis across `lib` and `test`: **0 errors, 79 warnings, 452 informational findings**. Existing lint debt remains; this is not a lint-clean claim. Log: `build/pending-fixes-verified-analyzer.log`.
- Native Isar/ZIP tests cover schema 6 fields and complete v4/v5 restore compatibility. Plan tests cover expert protection, 8/10-week custom plans, explicit weeks, seed refresh, ongoing routines, invalid drafts and unsaved edits.
- Real-font widget tests include 320px width and 200% text for key onboarding, profile, plan, habit, reminder, comparison and chart surfaces. These are renderer tests, not a physical-device pass.
- New scanner regressions verify unknown macros are not confirmed by an unchanged edit and appending preserves saved aggregate nutrition.
- `git diff --check` passed. Both expert seed-plan assets have zero diff.

## Remaining boundaries

- Physical Android build/device validation is still required for camera/barcode capture, Google/Firebase account transitions, notification delivery/reboot/Doze, Health Connect, screen readers, native sharing and actual widgets. This environment has no configured Android SDK/device.
- Updated Firestore rules already passed 11 local emulator tests in the earlier service pass; they have not been deployed. Client/rules release must be coordinated.
- Faster and more accurate meal scanning requires measured phone latency and representative weighed meals before claiming an improvement from a model/image-quality change. No speculative model switch or extra request racing was introduced.
- Missing expert-authored details (for example an unspecified exercise duration or ingredient nutrition) require source information. They remain honestly unspecified.
- A full visual exercise/meal editor is a separate feature; existing JSON editing/import remains for detailed plan changes.

No commit, push, production deployment, ZIP or source cleanup was performed. The user's no-commit instruction remains in effect.
