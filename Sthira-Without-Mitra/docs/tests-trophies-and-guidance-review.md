# Tests, trophies and guidance follow-up

Latest follow-up: [Daily Check-in and remaining audit fixes](daily-check-in-and-pending-fixes.md) — 797 passing Flutter tests, one existing skip; current completion and release boundaries.

19 September 2026. The earlier final-experience checkpoint had 695 passing Flutter cases and one skip, distributed across 110 Dart test files. The number of cases is not a requested target to inflate.

## One test root

All maintained tests and test utilities are under `test/`, retaining feature subfolders:

- Moved the Isar setup helper to `test/helpers/download_isar.dart`.
- Moved the standalone Isar diagnostic to `test/manual/isar_instances.dart`; it is not counted as an automated test.
- Moved the Android static validator to `test/native/check_android_widget_resources.py` and corrected its project-root resolution.
- Moved eight historical test/analyzer output files from the repository root to `test/reports/legacy/`, without deleting their contents.
- Added `test/README.md` and updated the repository run instructions. Firestore emulator checks and live AI benchmarks remain explicit, separate runs. Temporary generated build probes are not maintained test cases.

## Trophies: only the missing useful milestones

The existing five defaults all recognize workouts. Added two modest meal-recording milestones:

| Trophy | Requirement |
|---|---|
| Meal momentum | Record a meal on seven different days |
| Steady tracker | Record a meal on thirty different days |

The days need not be consecutive. Multiple meals on one day count once; empty, malformed and future records do not count. Unknown nutrition does not invalidate an honestly recorded meal. These do not reward calorie restriction, food quantity or body weight. Existing records count, earned trophies survive restarts/imports, and existing workout trophies remain intact. Trophy banners also clear on account/queue changes; an old dismissal cannot consume the next account's queued achievement.

## Were coach notes, insights and meal suggestions analyzed before?

Yes, their services and several safety boundaries were examined in the earlier audits. That did not cover every Home-specific presentation and state path. This follow-up identified additional defects and adds regressions for them.

### Coach notes

The history modal captured its initial account's notes and nested an unconstrained list inside a scrolling sheet. Coach context also inherited misleading snapshot defaults: target weight substituted for missing observations, workout sections described as workout counts, historical dates mixed with today's schedule, and no plan confused with rest.

The follow-up uses explicit recorded context, an account-scoped history view and deliberate refresh behavior. A changed record invalidates stale work and marks existing guidance for refresh; it does not start a paid request after every edit. Missing prior-day habit records remain unknown, future imported notes stay hidden, and deletion or replacement during a failed refresh is resolved against current storage. See the maintained coach context/notifier/UI regressions for the final contract.

### Home insights

Progress's tested analytics path was separate from Home's legacy insights provider. Home treated sparse stored rows as consecutive calendar days, could treat missing steps as low activity, included future/current partial data and let an old generic nutrition message occupy the card.

Home now uses bounded calendar ranges and actual observed samples. It reports sample counts/date ranges and actual paired averages, avoids causal claims, and prioritizes recent actionable evidence. The existing Progress analytics and card design remain.

### Suggested meals

Normal cache reuse worked, but “Suggest something else” could replay the same cached suggestion. Optional cache failures could also prevent a useful result. Context did not consistently distinguish absent targets from reached targets or count all actual logged slots.

Explicit alternatives now request fresh generation and name the previous idea to avoid. Normal reopening still reuses matching cached context. Cache failures are recoverable, missing targets remain unknown, and reduced-motion preferences are respected. Meal ideas remain suggestions; they do not automatically log food or rewrite expert plans.

See [suggested-meals-follow-up-review.md](suggested-meals-follow-up-review.md) for details and limits.

## Verification

- Full Flutter suite: **757 passed, 1 existing skip, 0 failures**, across 119 maintained test files. Log: `build/tests-trophies-guidance-full-suite.log`. This is 62 additional passing cases since the 695-case checkpoint.
- Dart analyzer: **0 errors, 65 warnings, 462 infos**. Warnings/style notices remain; this is not a clean-lint claim. Log: `build/tests-trophies-guidance-final-analyzer.log`.
- Android resource validator passes at `test/native/check_android_widget_resources.py` (20 XML files, three widget variants).
- `git diff --check` and Dart source UTF-8 checks pass. Maintained-test inventory found no test source outside `test/`; eight historical reports were preserved.
- All new coach, Home-insight, suggested-meal, meal-trophy and trophy-banner regressions are included in the full suite, including refresh failure during a synchronized note replacement.

The existing skip is the unimplemented full native widget-channel integration contract. Firestore emulator tests are separate and were not rerun because rules were unchanged. Native Android/device behavior and live model response quality are not established by mocked Flutter tests.

No commit, push or deployment.
