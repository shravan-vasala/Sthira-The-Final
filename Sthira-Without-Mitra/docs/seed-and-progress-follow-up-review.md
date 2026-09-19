# Seed plans and Progress: follow-up review

> Follow-up: See [remaining analysis implementation](pending-analysis-fixes.md) for the consolidated completion matrix and final verification. Original findings below are retained as history.

Reviewed 19 September 2026 against the current working tree. This is a content-to-behavior audit, not a nutrition or training prescription. The initial audit was read-only; implementation updates below record subsequently authorized changes.

## Scope and status

The previous service review covered seed loading, versioning, account isolation, and preservation of user-owned plans (`docs/service-audit/data-sync.md:14`). Earlier passing tests are useful evidence for those mechanics and the scenarios exercised; they do not establish ingredient nutrition accuracy, correct identifiers for every shipped exercise, or coverage of the entire real seed-to-logging flow. The content hash tests in `test/immutability_test.dart:34-111` deliberately protect unchanged content, not its correctness.

The user has separately authorized a heatmap remodel. That implementation and its verification are tracked by the main task. The findings below record the state at the time of the audit; implementation updates at the end identify work subsequently authorized and completed. Preserve the existing visual language and hero cards; the highest-value work is truthful logging and understandable information.

## Meal seed

### Verified inventory

`assets/data/seed_meal_plan.json` contains one version-1 plan, four meals, 13 food rows, and eight guidance strings. Its stated 1,250 kcal total equals the sum of the meals (400 + 420 + 90 + 340). Every meal's calories equal the sum of its food rows. Nine of the 13 rows combine alternative foods under a single calorie value. No item contains structured protein, carbohydrate, or fat values; no recipe/reference/author metadata is provided.

The Indian food selection is useful and worth preserving: rice/phulkas, moong/chana, greens, curd/buttermilk, ragi, and familiar fruit. There is no need to replace the food list or invent a much larger catalog to address the defects below.

### M1 — P1: logging the plan derives eaten nutrients from goals

**Evidence:** `lib/utils/meal_plan_complete.dart:35-58` calculates protein, carbs, and fat from the user's target macros multiplied by `planned.calories / profile.targetCalories`. It distributes those inferred macros among the foods according to their calorie share. `lib/screens/home/meal_detail_screen.dart:1146-1158` persists this result when the user marks a meal completed as planned.

**Impact:** the same food and portion can produce different recorded nutrients after a goal change. Even the seed's lemon-water and tea rows receive allocated protein/fat. These are synthetic values, yet they enter the same nutrition totals used by charts and summaries.

**Smallest valuable change:** preserve nutrition supplied for the actual food/variant. If it is unavailable, represent macros as unknown and explain that totals are incomplete; do not infer intake from a goal or silently replace unknown values with zero. This requires a clear completeness contract through storage and charts, not a cosmetic label alone.

**Needed verification:** logging the identical plan item under different profile targets must preserve its nutrition; an item with missing macros must remain distinguishable from a measured zero; progress summaries must not treat incomplete macro data as full intake.

### M2 — P1: alternatives and portions are not a loggable recipe

**Evidence:** `assets/data/seed_meal_plan.json:27` combines chicken/soya/paneer and three different quantities under one 160-kcal value. Lines 54-56 use `1 to 2` phulkas and a 60g chicken/soya choice without a structured cooked/dry basis. The logging helper stores these combined names directly (`lib/utils/meal_plan_complete.dart:44-57`).

**Impact:** completed-as-planned cannot establish which alternative or amount was eaten. Numerical calorie totals reconcile, but that arithmetic does not validate the selected ingredient's nutrition.

**Smallest valuable change:** keep the guidance, but offer explicit alternatives and quantities before logging. Source each variant's nutrition from documented data or the content author. Do not invent replacement values. Keep the existing fast path only where a single food/portion is unambiguous.

**Needed verification:** every selectable variant has its own stable identity, measurable portion basis, and corresponding nutrition; logging one variant does not save all alternatives as a single food.

### M3 — P2: imported item nutrition is silently discarded

**Evidence:** `lib/models/meal_plan.dart:140-158` supports only `name`, `quantity`, and `calories`. Imported `proteinG`, `carbsG`, `fatG`, and `portion` are not retained. `test/models/meal_plan_test.dart:16-25` supplies those fields, but the item assertion checks only its name.

**Smallest valuable change:** define one supported import contract, preserve supported nutrition, and reject or explicitly map unsupported fields. Fix this before relying on imported plans to solve M1.

**Needed verification:** realistic plan JSON round-trips portions and nutrition; malformed/negative/non-finite values are rejected rather than silently accepted or discarded.

### M4 — P2: a fixed template looks personalized

**Evidence:** the meal screen prefixes the plan with the user's name and displays the user's target (`lib/screens/home/meal_detail_screen.dart:40-50`), while the seed portions remain fixed at 1,250 kcal. Onboarding starts at that value and treats an existing positive default as manually edited (`lib/screens/onboarding/onboarding_screen.dart:50,73-75`).

**Smallest valuable change:** distinguish the starter meal template and its own total from the user's daily target. Keep goals independently editable. Do not claim automatic personalization or silently scale the author's plan.

### M5 — P2: expert labeling lacks visible provenance

**Evidence:** `lib/screens/profile/manage_plans_screen.dart:647,710` describes an expert protocol; `lib/screens/home/meal_detail_screen.dart:1242-1245` labels plan provenance “nutritionist.” The bundled asset/model do not carry author, credentials, review date, or nutrition references.

**Interpretation:** this does not prove the plan was not written by an expert. It means the application does not expose evidence for the label.

**Smallest valuable change:** attach real attribution if available; otherwise use neutral “Meal plan” wording. Retain authored guidance until reviewed rather than inventing clinical claims or editing nutritional prescriptions during a UI pass.

## Workout seed

### Verified inventory

`assets/data/seed_workout_plan.json` contains a version-2 plan named “Phase 1 (8 Weeks),” seven weekdays, 17 sections, 65 exercise occurrences, and 39 distinct exercise names. It defines one repeated weekly schedule with `durationWeeks: 8`, not eight distinct progression weeks. All 65 exercise occurrences omit `instanceId`. Four cooldown occurrences declare `durationSeconds: 20`. Of the 65 occurrences, 54 have blank notes; 63 have YouTube links with syntactically valid 11-character video identifiers. Live video availability was not checked.

### W1 — P1: shipped exercise identity differs between save and completion

**Evidence:** `lib/models/workout_plan.dart:246` leaves an omitted `instanceId` null. `lib/utils/seed_migration_manager.dart:68-76` imports the seed directly. Save/card paths fall back to exercise name (`lib/utils/exercise_log_save.dart:90`; `lib/screens/workout/widgets/exercise_card.dart:52-56`), whereas shared completion looks up an empty identifier (`lib/utils/workout_completion.dart:110`; Home's resume lookup in `lib/screens/home/home_screen.dart:429`).

**Impact:** logging a shipped exercise under its name does not satisfy the shared per-exercise lookup. On Saturday, Modified Burpees occurs twice (`assets/data/seed_workout_plan.json:756,870`) and Jumping Jacks occurs twice (`:782,857`), so the name fallback also allows two distinct occurrences to share/overwrite a record.

**Smallest valuable change:** assign deterministic stable occurrence IDs to actual seed plans during loading/migration and use the same identity everywhere. Preserve readable names and retain access to legacy name-keyed logs; avoid blindly assigning one historical log to several duplicate occurrences.

**Needed verification:** load the real asset into the actual repository, save each occurrence, verify Home/card/shared completion agree, and prove same-name Saturday occurrences stay independent. Include a legacy-log migration fixture. Manually-ID'd synthetic exercises do not test this boundary.

### W2 — P1: the shipped Sunday is not recognized as a rest day

**Evidence:** Sunday contains one “Rest Day” section with no exercises (`assets/data/seed_workout_plan.json:887-893`). `lib/utils/workout_completion.dart:12-13` recognizes only `day.sections.isEmpty`.

**Impact:** the seed's intended rest day is classified as a training day; the weekly training target becomes seven rather than six.

**Smallest valuable change:** use one explicit rest-day representation and normalize legacy empty-section rest days. Ensure all readers share that rule.

**Needed verification:** actual-seed Sunday renders rest, contributes no required training session, and cannot become a false missed-workout insight or phase-progress increment.

### W3 — P2: seed prescriptions exceed the logging model

**Evidence:** four cooldowns specify 20-second durations (`assets/data/seed_workout_plan.json:189,373,561,742`). Current logging intentionally rejects unsupported timed targets rather than turning seconds into repetitions. Wednesday “Home Cardio” supplies `reps: ["1"]` without a duration or explanatory note (`:385-406`).

**Impact:** four strength days cannot record every prescribed exercise through the current detailed set logger. “One” for cardio does not tell the user what activity amount is intended.

**Smallest valuable change:** choose a proper duration/completion representation with the content author; timed exercises must not be forced into repetition counts. Until supported, make the limitation and its effect on completion explicit. Do not invent exercise targets.

### W4 — P2: instructional and program clarity need a content pass

Air Squats (`assets/data/seed_workout_plan.json:800-808`) and Lateral Shuffle (`:826-834`) lack both video and notes. Some repeated names differ between per-side/per-arm and no side instruction. “Cat Camel” and “Cat Camel Stretch” share a video but split name-based history. These need authored clarifications and stable exercise identity, not more decorative UI.

The eight-week title can remain if it means following the same weekly routine for eight weeks. If progression was intended, it is not encoded in the seed; do not describe it as an adaptive eight-week program.

## Heatmap: separately authorized remodel

The original heatmap deserved a focused remodel. Its provider recomputed current score/current-plan rules across historical dates, and its recorded-data check missed exercise-only records and habit overrides. It also queried repositories repeatedly per day. The yearly screen used a fixed `Expanded` chart plus a large footer, constraining the useful map on small displays (`lib/providers/yearly_heatmap_provider.dart`, `lib/screens/progress/widgets/activity_heatmap.dart`, and `lib/screens/progress/yearly_activity_screen.dart`; findings refer to the pre-remodel source).

The separately authorized remodel is now implemented and verified: all twelve months are visible in the initial 390-pixel overview, with explicit month/day inspection and factual recorded-area intensity. See [the heatmap implementation and validation report](yearly-heatmap-review.md) for responsive previews, data semantics, passing tests and the remaining native-device validation limit. See the implementation updates below for subsequent seed and Progress work.

## Progress screen and weekly summary

The main Progress screen has already received substantive improvements. Keep its hero cards, established typography, and inspectable main chart. Do not replace the dashboard merely to create visual novelty.

### P1 — P2: habit feedback can misrepresent missing or zero data

**Evidence:** `lib/screens/progress/weekly_summary_screen.dart:463-464` emits “Habits need a little more focus” when the habit rate is below 40% and workouts exist, even if no habits were scheduled. Line 95 hides the habit chart whenever its rate is zero, including a fully observed week with scheduled habits and zero completion.

**Smallest valuable change:** gate habit advice by scheduled/observed habit data; keep genuine 0% visible, distinct from no schedule and no records. Use factual language tied to the selected period.

**Needed verification:** no-habit week, scheduled zero-completion week, missing-record week, and positive-completion week produce distinct and accurate views.

### P2 — P2: week comparisons apply inconsistent schedule detection

**Evidence:** current-week rest-day record detection uses `WorkoutCompletion.hasSchedule` (`lib/providers/weekly_summary_provider.dart:258`), while previous-week detection uses `workoutPlan.days.isNotEmpty` (`:496`).

**Impact:** a weeks-only plan can use inconsistent comparison denominators between adjacent weeks.

**Smallest valuable change:** use the same date-aware schedule and record rules for both periods. Test a weeks-only plan across the comparison boundary.

### P3 — P2: weekly habit bars cannot be inspected

**Evidence:** `lib/screens/progress/weekly_summary_screen.dart:666` disables chart touch, with no alternative daily record list.

**Smallest valuable change:** expose the day's completed/scheduled count and date through tapping and accessible semantics or a compact records view. Keep the existing chart style.

### P4 — P2: Progress goals depend on an unrelated Home date

**Evidence:** the Steps and Sleep charts obtain their target from `habitsProvider` (`lib/screens/progress/progress_screen.dart:476-485`). That provider filters habits by `dateStringProvider` and its weekday (`lib/providers/habit_providers.dart:7-16`), which follows the date selected on Home. Progress derives its chart end from the current clock date (`lib/screens/progress/progress_screen.dart:163-165`), not that Home selection.

**Impact:** browsing an old Sunday on Home can remove or change the “current goal” and target-day insight on a Progress chart that still ends today. For example, a Monday–Friday steps habit disappears from the goal lookup when Sunday is selected. The chart and its target can therefore refer to different dates without explaining the mismatch.

**Smallest valuable change:** give Progress an explicit goal source independent of the Home browsing date. For a current-goal line, resolve the relevant current configuration/date; if weekday-specific targets differ, define and label how the chart evaluates those targets rather than arbitrarily taking the first matching habit. Keep historical-goal support separate from this bounded consistency correction.

**Needed verification:** freeze the clock on a weekday and configure a Monday–Friday steps habit. Change Home's selected date between that weekday and an old Sunday; Progress's unchanged date range, current-goal line, and target-day summary must remain consistent. Include Sleep, no matching configured goal, and differing weekday-target cases.

### Optional focused improvements

- A distant weight goal is included in the y-axis bounds at `lib/screens/progress/widgets/shared_chart_card.dart:370`, potentially flattening real changes. Prefer an off-scale goal annotation when a distant target would dominate the observed data range.
- Calories/protein empty states lack a direct “Log meal” action (`lib/screens/progress/progress_screen.dart:331,378`), while other metrics offer useful entry actions. Add a contextual route to logging.
- Exercise-specific progress already exists. Prefer a useful link from Progress to it over adding another large strength dashboard or expanding the metric selector without a clear use case.

## Recommended order

1. Correct actual-seed workout identity/rest-day behavior and meal nutrition truthfulness; these affect reported progress.
2. The separately authorized heatmap remodel is complete in the working tree; perform its native-device pass before release.
3. Apply the bounded weekly-summary correctness/inspection fixes.
4. Refine seed choices, portions, and instructions with their author, preserving the existing Indian focus and visual design.

This audit used source inspection and read-only inventory/arithmetic checks. It did not rerun Flutter tests, alter data, validate nutritional appropriateness, prescribe training, verify live videos, or deploy anything.


## Progress implementation update — 19 September 2026

P1–P4 are now implemented, preserving the existing hero cards and visual language. The original findings above are retained as audit history.

- **P1:** weekly habits distinguish no schedule, scheduled but unrecorded, and recorded zero completion. Counts disclose completed, recorded and scheduled instances. Unknown calories are excluded from averages/target classifications and disclosed. Image/text shares preserve these meanings, show the actual score out of 100 and disclose partial-week coverage.
- **P2:** current and previous weeks use the same schedule predicate. Audit correction: the existing `DailyScore.planForScoring` normalization already protected ordinary weeks-only plans from the literal `.days.isNotEmpty` difference. This change hardens consistency rather than claiming every weeks-only plan previously had wrong denominators. Habit denominators now respect creation day in local calendar time; earlier days are not backfilled with newly created habits.
- **P3:** weekly habit bars use the shared inspectable chart, keep recorded zero visible, and offer a readable daily-records list with exact counts. Inspection remains local and never changes Home's selected day.
- **P4:** Steps/Sleep reference goals read the complete current habit configuration independently of Home's browsing date. Conflicting weekday targets or goal directions suppress the single goal and explain why rather than arbitrarily selecting the first habit. These remain current reference goals, not invented historical goal snapshots.
- **Bounded improvements:** distant weight goals are labeled above/below the plotted range so they do not flatten visible changes. Empty nutrition charts offer a direct current-day meal logging action, and incomplete nutrition remains explicit in the overview and drilldown even when no usable points exist.
- **Not added:** another workout dashboard or generic exercise-progress link. The existing route requires a particular exercise; adding a duplicate picker without evidence of a navigation problem would add clutter.

The centralized Flutter run passed all 75 focused Progress/provider/chart/drilldown/weekly/share tests. Native share-sheet and screen-reader checks remain device validation tasks.

## Workout and Manage Plans implementation update - 19 September 2026

The user confirmed the routines and meals were suggested by experts and authorized the implementation fixes. The expert assets, exercises, prescribed targets, notes and expert-suggested attribution remain intact. The original findings above describe the earlier audit checkpoint.

- **W1 implemented:** deterministic occurrence IDs are assigned on seed/import loading and persisted for legacy native plans. Cards, saves, Home resume and shared completion use consistent identities. A legacy name log is reused only when its weekday and name identify one unambiguous occurrence; repeated-name records remain readable in history without falsely completing multiple exercises. Saving an unambiguous legacy record migrates its existing row and old sync key rather than duplicating it.
- **W2 implemented:** shared rest detection accepts empty sections such as the shipped Sunday. Training totals exclude empty sections, matching the completed-section count. The actual seed requires six training days per week.
- **W3 implemented for explicit durations:** actual seconds have their own nullable set field; timed records carry no invented repetitions. The seconds editor, As planned action, completion, native storage and backup, cloud JSON sync, CSV export and exercise history preserve duration. Purely timed records do not create empty strength PRs. All four authored 20-second cooldown prescriptions remain unchanged.
- **W4 retained for expert clarification:** missing instructions/videos, side-specific inconsistencies and the unspecified Home Cardio duration are not rewritten. Home Cardio explicitly identifies its authored target and directs the user to the expert video for session guidance. Video identifiers were inspected syntactically; live availability was not verified. Distance targets remain unsupported for detailed logging rather than being saved as rep counts.


Manage Plans now preserves expert originals and creates a separately saved, selected user copy with its original plan name as provenance. Saving a changed name creates another plan rather than destructively renaming the original. Native seed-refresh regressions verify user overrides survive; restored expert content remains separately available.

Workout customization exposes a program-length field supporting 1-104 whole weeks, including 8 and 10. A routine without an authored length stays ongoing unless the user chooses a length. Repeating schedules retain their authored exercises. Individual-week schedules retain existing weeks; extending a program explicitly copies the final week and assigns independent identities, while shortening removes final weeks. The UI explains this operation and does not claim expert-authored progression. Individual-week exercise edits and imports still use advanced JSON; no full visual program builder was introduced.

Both plan editors retain drafts across tabs and require an explicit discard when switching or leaving. Account changes invalidate pending saves; refreshes do not silently replace a dirty draft, and conflicting same-name edits require saving under another name. Malformed meal drafts cannot crash the calorie summary, and malformed week arrays are rejected without silently discarding them. Suggested meal-plan calories remain separate from the user's personal daily target.

Verification uses real seed assets in native Isar fixtures for IDs, repeated exercises, legacy migration, rest semantics, empty-section totals, timed completion/roundtrip and 8/10-week overrides. The initial centralized workout/customization/onboarding batch passed 29 tests. Additional editor, habit and reminder regressions were added afterward; final aggregate results belong to the main implementation report. Reminder UI regressions passed at 320px and 200% text, including weekday editing and visible permission/scheduling errors. No commit, push or deployment was made; real-device validation remains outstanding.


## Meal, onboarding, and journey implementation update - 19 September 2026

The user subsequently authorized the pending fixes and confirmed that the bundled meals and exercises are expert suggested. **M5 is resolved by that confirmation**: expert attribution is retained, using "Expert-suggested" rather than claiming a particular credential. The authored seed JSON, food choices, guidance, and calorie values remain unchanged. Named author/review metadata can be added when supplied; it is not required to proceed.

- **M1:** planned logging preserves supplied item nutrition and no longer derives eaten nutrients from personal goals. Nullable completeness flags survive Isar, JSON, backup, repeat, and append flows. Missing macros remain unknown; explicit measured zero remains zero. Historical goal-derived planned macros remain in the saved source record but are excluded from usable intake. Existing genuine aggregate-only records remain compatible.
- **M2:** each of the four actual seed meals contains an alternative or ambiguous portion. The shortcut now requires the user to choose the foods and portions actually eaten through the existing describe/manual review flow. It does not silently log all alternatives or invent ingredient-specific nutrition. A fully specified custom item retains the fast planned-log path.
- **M3:** imported quantity/portion and camel-case or snake-case item macro values round-trip. Malformed, negative, non-finite nutrition and non-whole item calories are rejected. Daily-target metadata is not accepted as actual food nutrition.
- **M4:** meal screens show the plan's own total separately from the personal daily target, preserve the actual plan name, and explain that editing a target does not change authored portions. Manage Plans supports a protected user-owned customization with expert origin retained; see the workout/Manage Plans update.
- **Nutrition consumers:** meal tiles/details, widgets, summaries, charts, insights, CSV, and drilldowns disclose incomplete nutrition. Incomplete metric days are excluded from that metric's averages and trend/target claims. Known calorie values are retained even when macros are missing.
- **Scanner review:** old planned macro values are neither displayed as known nor prefilled into editable macro fields. Explicit macro entry is required before an edit can mark them known. Append preserves an older saved aggregate's unassigned remainder as "Previously saved totals", without assigning it to an unresolved food; the original unresolved detail and provenance remain, and completeness is still false. Unknown macro items do not become remembered-food shortcuts.

Onboarding now wraps and stacks controls at 320px/200% text, honors reduced motion, accurately distinguishes offline saved data from online AI estimates, keeps existing targets/macros until an explicit choice, explains estimate assumptions, and adopts a recovered account's current profile into the setup draft. There is no automatic resizing of the expert meal plan.

Journey statistics now count distinct recorded days including habit-only and exercise-only entries, count finished workouts separately, react to account/data/date changes, and show legible zero values in a responsive layout. Meal streaks have no arbitrary 30-day cap. Steps streaks use configured scheduled habits and explicit overrides rather than a guessed target or Home's browsed weekday. Workout streak badges require consecutive dated workout completions; gaps and unrelated activity do not qualify. Already-earned badges remain earned, and stale account evaluations cannot write new progress.

**Verification at this update:** centralized runs passed the meal nutrition/repository/packaged append/meal-experience checks, all four onboarding layout tests, seven Journey/streak/badge tests, and three Profile editor tests. The two additional scanner regression cases and final small follow-up assertions are ready for the coordinator's final suite. Earlier tests prove the behaviors exercised, not clinical validity of the authored recipes or live model accuracy.

**Content boundary:** the seed still does not provide ingredient-specific macros or separate nutrition for every alternative, and historical fabricated values cannot be reconstructed into actual past food intake. No replacement nutrition, medical advice, or expert prescription was invented.
