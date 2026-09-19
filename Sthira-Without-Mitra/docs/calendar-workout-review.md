# Calendar and workout wrap-up review

> Follow-up: See [remaining analysis implementation](pending-analysis-fixes.md) for subsequent fixes and final verification. Findings and test counts below describe their original review checkpoint.

19 September 2026. The existing design, typography tokens and hero cards remain. This pass addresses incorrect or fragile behaviour rather than redesigning the screens.

## Changes with clear user value

- Weekly calendar: the label follows the visible week and identifies month/year boundaries. Date-picker selections and external date changes move the strip; midnight/resume preserves the correct calendar week. Browsing weeks keeps the selected day unchanged until a day is chosen. Today returns from another week.
- Activity dots subscribe to all-date database updates, including exercise-only logs and meals on rest days. Habit dots respect their weekday schedule and require a recorded entry; partial counters and explicit zeros count without mistaking an unset limit goal for activity. A dot means activity was logged, not that every goal was completed; an empty current day is neutral.
- Calendar accessibility: equally spaced day targets, full-date labels and explicit screen-reader actions, reduced-motion support, and adaptive layout at 320px and 200% text without shrinking the selected system text size.
- Workout schedules use the selected date and program start date consistently across Home, workout screens, summaries, scores, reminders and widgets. Weeks-only plans work; resume uses exercise instance IDs, so repeated exercise names do not collide. Rest days no longer fulfil the weekly training target, and future dates do not announce a program has ended.
- Exercise logging reads each original set target instead of parsing a condensed display label. Bodyweight zero is valid. Invalid drafts preserve existing logs; removal is explicit. Saved set numbering, weight units, and unchanged kilogram precision survive reopening. Dates/accounts remain pinned across asynchronous editors and confirmations; future logging is disabled.
- Finishing a workout commits the session, daily status and initial program start date together, including their sync records. Labels distinguish completed, finished early and skipped; finishing early does not block continuing the workout. The global rest timer adapts to narrow screens and larger text, with space reserved for it above navigation.
- Missing/offline exercise videos have a safe recovery state instead of dereferencing an absent player. History tolerates malformed legacy records and long result labels.
- Reflections save to their originating date, cancel pending work on account change, and offer retry on failure. Historical summaries filter habits by the actual day, refresh while open, and wrap long meal descriptions.
- Manage Plans opens with its scrolling tabs correctly configured. Its targets and Recalculate control wrap instead of overflowing on narrow screens.

## Deliberate limits

Follow-up implementation now supports explicit duration prescriptions end to end: seconds are saved independently from repetitions and survive editing, native storage/backup, cloud JSON sync, CSV and exercise history. The four shipped 20-second cooldowns can be recorded without altering their authored targets or creating strength personal records. Distance prescriptions still require an actual distance contract; ambiguous Home Cardio guidance still has no authored time target. Neither is converted into invented time or repetitions. See [the seed and Progress follow-up](seed-and-progress-follow-up-review.md) for workout identity, rest semantics and Manage Plans override details.

Native Android build/device validation remains outstanding in this environment: keyboard behaviour, real video connectivity, screen readers, notification delivery and health/widget integrations need device checks. No production service was deployed, and no commit or push was made.

## Verification

**Full maintained suite: 515 passed, 1 existing platform integration test skipped, 0 failures.** Evidence: `build/wrapup-review/verified-suite.log`. The final focused calendar/workout/plan/transaction batch also passed 29 tests. After the last swipe-velocity guard, all 9 calendar regressions passed again with both normal and reduced animation settings (`build/wrapup-review/verified-calendar.log`). **Analyzer: 0 errors, 82 warnings, 419 informational findings** across `lib` and `test`; existing lint debt remains. Evidence: `build/wrapup-review/final-analyzer.log`. The last calendar activity change additionally passed focused static analysis with no errors or warnings. `git diff --check` passed. Calendar rendering checks cover light/dark themes at normal and 200% text. Existing service/backend verification and ZIP exclusions remain in [service-fixes.md](service-fixes.md).
