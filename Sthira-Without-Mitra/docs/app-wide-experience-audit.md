# App-wide experience audit

> Follow-up: See [remaining analysis implementation](pending-analysis-fixes.md) for subsequent fixes and final verification. Findings and test counts below describe their original review checkpoint.

Reviewed 19 September 2026 against the current local working tree. This is a read-only app audit: no production code, maintained tests, commits or pushes were changed. Temporary probes, screenshots and detailed working notes are under ignored `build/app-audit/`.

## Blunt verdict

Keep the design. The hero cards, forest/peach palette, Cabinet Grotesk headings, General Sans body text, rounded surfaces, floating navigation and meaningful avatar/trophy/selection borders are worth preserving. The normal-size onboarding and Profile captures are coherent. A new font family, more animation, another hero or blanket border removal would add little.

Refinement is justified. The weaker parts are forms, small controls, date/account context, and what happens after Save, Restore, Retry or Back. Some of these are real correctness failures. Reliable actions and readable values will contribute more to a premium experience than a visual redesign.

## Coverage

Inspected all 17 registered routes, all 21 screen files, the four onboarding pages and completion state, and their principal sheets/widgets. Existing meal/score/progress work was reviewed alongside the remaining surfaces. This does not mean every platform, permission dialog, network response or possible data combination was exercised.

| Screen or flow | Judgment | Specific value to add |
|---|---|---|
| Home | Keep composition and heroes; refine controls and state | Clear habit/streak rows, date-safe reflection, top safe-area handling, accurate workout resume state |
| Welcome | Keep aura, brand and three compact feature cards | Wrap tagline; truthful offline wording; accessible reflection link |
| About you | Keep short optional form | Stack constrained fields, readable unit switch, keyboard-safe navigation |
| Your plan | Keep calorie hero and editable targets | Distinguish preset from personalized estimate, expose assumptions, wrap macros |
| Onboarding Connect/completion | Keep optional integrations | Reflow integration rows/footer; adopt restored account state; remove duplicate coach-name draft |
| Meal page/tile, AI scan, barcode capture/product editor | Keep current refinements | No further cosmetic redesign justified; real camera/live inference remain device checks |
| Daily score, weekly summary | Keep corrected hero/coverage hierarchy | Repair workout shortcut; share the same date/completion rules with older summary/share surfaces |
| Progress/chart drilldown | Keep recent chart interaction work | Measure all rendered decimal axis labels at large text, not just endpoints |
| Yearly activity | Keep calendar concept | Avoid fixed layout consuming all heatmap space at large text; legible, reachable date inspection |
| Workout/exercise cards | Keep visual hierarchy | Correct per-set logging, future-date guards, selected-date labels, truthful finished/partial/skipped states |
| Log workout sheet | Needs focused refinement | Show complete numeric inputs; preserve bodyweight logs; explicit validation and recovery |
| Exercise progress/history | Keep chart and PR treatment | Wrap PR rows, readable decimal axes, consistently skip malformed records |
| Video tutorial | Keep focused player | Render offline/error recovery before constructing a player |
| Manage Plans, meal plans/slots | Most substantial utility refinement | Fix tab assertion, refresh saved plans, protect unsaved work, reflow controls, clearer Customize/Advanced labels |
| Profile/Edit Profile | Keep identity and hero | Adaptive journey/cloud rows, complete macro inputs, field-level errors and truthful sync state |
| Avatar/trophy surfaces | Keep borders, artwork and new adaptive shelf | Refresh counts reliably; unify streak/achievement rules; recover share failures |
| Manage Habits | Keep list and editor concept | Fit seven weekday controls, name/announce selection, keep final list row above Add button |
| Reminders | Keep preview and quiet hours | Reflow weekday/time controls; explain denied permissions and offer recovery |
| Backup/restore, CSV export | Keep verification and explicit restore confirmation | Bind to visible account, always leave busy state on failure, state backup coverage/location accurately |
| AI/Health/Cloud setup sheets | Keep shared sheet design | Recover when inputs change mid-request; honest optional/setup/connected/error wording |
| Body Stats | Keep measurement cards | Validate numbers, preserve units, stack cards when values need room |
| Weight/steps/sleep/water/body-fat entry | Keep focused numeric sheets | Consistent save-in-progress and failure feedback; maintain pinned-date context |
| Physique gallery/photo viewer | Keep dated gallery, pose filters and focused viewer | Correct filtered-selection deletion, describe missing images, name actions and selected states |
| Add Progress Photo | Keep optional weight/note and matching-pose reference | Show weight unit, reject invalid values, recover camera failures without losing inputs |
| Photo comparison/share | Keep both comparison modes | Accessible slider, responsive toolbar, explicit success/cancel/error outcomes |
| Social/Friends/Leaderboard/Connect | Keep simple tabs and friend cards | Reflow long names/filters; direct empty-state action; readable retryable errors |
| Gita reflection | Keep its distinct quiet composition | Name the 2:47 launcher and improve its target; verify Telugu on target devices |
| App shell, rest timer, badges, missing-route page | Keep navigation shape and badges | Responsive timer actions, correct routes, coherent keyboard/focus and status semantics |

## Priority 1: correctness and recovery

### 1. Account changes and data tools must use the visible account

Source inspection found related lifecycle gaps:

- `lib/providers/app_providers.dart:338` opens/rebinds the account database before the new-account branch exports existing data. Modern guest data is not migrated by `lib/services/app_database_manager.dart:52`; a user's previous local records can appear missing after enabling sync.
- Onboarding snapshots its form/habits before sign-in (`lib/screens/onboarding/onboarding_screen.dart:58`). A restore on Connect can then be overwritten by the final stale draft commit (`:194`).
- Sign-out (`lib/screens/profile/profile_screen.dart:1028`) signs out authentication without a corresponding repository rebind to guest.
- Sync queue selection (`lib/services/firestore_sync_service.dart:46,183,213`), backup creation/restoration (`lib/services/backup_service.dart:76,410`) and CSV export (`lib/services/csv_export_service.dart:65`) use the first open Isar instance. That can differ from the account shown on screen when more than one database is open.

Treat these as one account-continuity effort. Capture the originating account, explicitly rebind repositories/providers, preserve or deliberately merge guest/restore data, and validate with two populated databases. Do not add repeated warning dialogs to compensate for ambiguous data ownership. These are source-confirmed control-flow findings; live Google/Firestore transitions and destructive restore were not run.

### 2. Workout logging must preserve what the user entered

Reproduced with temporary deterministic tests:

- A planned `2 x 10` display using the multiplication symbol is parsed as 2 reps per set; timed `20s` is treated as 20 repetitions. Original per-set targets are collapsed through a display-string parser (`lib/utils/exercise_log_save.dart:19`, `lib/utils/target_parser.dart:19`, `lib/models/workout_plan.dart:218`). Parse original set data and distinguish durations.
- Existing zero-load/bodyweight sets appear as blank weight. Save rejects those rows, can delete the exercise log, and still shows a successful Logged message (`lib/screens/workout/log_data_dialog.dart:77,275,327`). Keep zero/bodyweight explicit, validate each row, and separate Remove from Save.
- Future-date As planned/Adjust actions still write even when other workout controls are disabled (`lib/screens/workout/widgets/exercise_card.dart:390`). Use one date policy for every entry point.

### 3. Save, restore and retry must actually recover

- Invalid backup/password verification returns while `_isLoading` remains true, leaving Restore noninteractive (`lib/screens/profile/backup_restore_screen.dart:312,330,474`). Reset busy state in a guaranteed finalization path.
- Editing an AI key while verification runs triggers an early return without resetting `_isVerifying` (`lib/widgets/setup_sheets.dart:64,150,218`). Cancel/reset the old attempt and allow retry without saving the wrong key.
- Offline/missing-ID tutorial paths leave the player controller null but build `_controller!` before the error branch (`lib/screens/workout/youtube_player_screen.dart:52,194`). The missing-controller failure was reproduced; native online playback was not tested.
- Same-name plan saves do not refresh the active plan provider, so Home can keep showing old contents after success (`lib/screens/profile/manage_plans_screen.dart:888`, `lib/providers/workout_providers.dart:8`). This stale-provider behavior was reproduced.
- Manage Plans' scrolling TabBar inherits `TabAlignment.fill`; it asserts in the bundled Flutter 3.47.5 renderer (`lib/screens/profile/manage_plans_screen.dart:34`). Set compatible alignment explicitly and verify on the release SDK.

### 4. Keep date context stable while editing

A temporary test reproduced a reflection note typed for 19 September being saved to 18 September after switching dates before the 800ms debounce fired. The callback reads the newly updated widget date/feeling (`lib/screens/home/widgets/day_feeling_card.dart:43,57,68`). Capture the originating date/account, settle or cancel the draft on navigation, and show an appropriate past/today/future question. The five blank bars also need meaningful labels and selected-state semantics before selection.

### 5. Fix navigation and workout identity consistency

The daily-score workout action opens nonexistent `/workout` (`lib/screens/home/widgets/daily_score_sheet.dart:180`); the router defines `/home/workout/:dayId` (`lib/router/app_router.dart:135`). Resolve the selected day's actual route.

Home resume/count logic uses exercise names (`lib/screens/home/home_screen.dart:431`), while saved logs and completion use instance IDs. Multi-week plans can also be hidden or resolved differently across Home and Workout. Use one plan/date/week/instance resolver. Preserve the hero's appearance; make its Ready/Continue/Completed state dependable.

## Priority 2: the visual refinement that is actually needed

### Adaptive layout, without shrinking system text

Actual-font inspection found more than hypothetical edge cases:

- **Onboarding:** 390px/100% is coherent. At 320px/200%, all four pages have layout defects. The Connect title breaks into a vertical letter column; Start my journey splits mid-word; the plan macro row overflows by 38px. Replace rigid rows and the unused footer balancing spacer with adaptive layouts.
- **Profile:** normal rendering is clean. At 320px/200%, journey/cloud rows overflow. Macro fields show only the leading digits of 150/250/70 because the three columns retain large prefix-icon slots. Stack fields where necessary.
- **Workout log:** a normal 390px rendering clips 12.5 kg to `12.`. At 320px/200%, reps/weight text disappears and Log as planned clips. Give the value a usable width and ensure only one component owns the keyboard inset.
- **Home:** the calendar's fixed day geometry and progress/streak rows need room for real content; the current card composition should stay. A simulated system top inset also shows the date starting above the safe region. Respect safe-area padding without adding a new header.
- **Body Stats:** fixed two-column cards overflow with enlarged values. Switch to a single column/stacked number and unit when constrained.
- **Yearly activity:** large text causes the fixed summary/footer to consume the heatmap space. Let the whole screen scroll with content-sized sections.
- **Rest timer:** its global one-row overlay overflows at 320px/200%; actions need an adaptive arrangement and clear increments. The navigation pill itself can remain.
- **Exercise history:** PR title/value rows overflow. Decimal axis labels can wrap even without a framework overflow, so measure rendered tick strings as well as endpoints.

Use existing typography, spacing and shape tokens. Keep normal-width compositions when they already work. Borders remain appropriate for avatars, trophies, selection, focus and outlined actions.

### Trustworthy values and understandable actions

- Body Stats accepts a negative measurement; a temporary probe saved waist -8.0 (`lib/screens/home/body_stats_screen.dart:306`). Validate finite positive values and keep invalid edits visible. Imported measurement units also need consistent treatment.
- The onboarding target starts from the model's 1250 preset and is marked edited before the user asks for a suggestion. Clearly distinguish preset/current target/estimate and explain calculator assumptions. This is a labeling/state issue, not a nutritional recommendation.
- Share summaries, past-day summaries, journey statistics and badges do not consistently reuse scheduled-habit/target/override rules. For example, raw positive progress can become complete in a share card (`lib/screens/home/share_preview_sheet.dart:73`), and past-day summary omits weekday filtering (`lib/screens/home/widgets/past_day_summary_sheet.dart:48`). Reuse the same selected-date completion model and refresh signals.
- Finished early and Skipped can both appear green Done in workouts. Show the actual status, selected date, and a clear resume/correction action.
- Social error branches expose raw exceptions without Retry (`lib/screens/social/social_feed_screen.dart:121,323`), and the empty Friends view sends users to an unnamed top-right icon. Use the existing error/empty-state components with direct actions. A long-name friend card overflowed by 70px at normal 390px width in the temporary renderer; filter constraints were source-reviewed. Use wrapping within the existing social design.
- Manage Habits' seven 44px day choices exceed the 272px content area of a 320px sheet. Use a fitting arrangement and full weekday/selection semantics. Reminder toggles need visible feedback when permission is denied.
- A selected photo can fall out of the filtered deletion lookup while still being counted in Delete confirmation (`lib/screens/home/physique_pictures_screen.dart:77,171,247`). Resolve against all selected records or clear selection intentionally on filter change.
- Add Progress Photo omits the weight unit and silently accepts bad metadata (`lib/screens/home/widgets/add_progress_photo_sheet.dart:85,365`). Label the current unit and validate without losing draft data.
- Share exporters return false on failure, bypassing UI catch blocks. Distinguish cancelled/success/error, prevent duplicate work, and explain failure while retaining the preview.
- Restore/cloud/offline copy should describe actual capabilities: photo AI requires connectivity; cloud/local text backups do not necessarily contain photos. Keep optional integrations optional, with neutral Not connected wording rather than treating skipped setup as an error.

## What should wait

A visual plan editor may eventually improve usability, but it is a larger feature. First make existing import/customize/save reliable and protect unsaved changes. A bodyweight reps chart could be useful later; do not add another chart simply to fill space. Reordering Home or adding decorative heroes should wait for evidence from actual usage. There is no justification for new fonts, extra gradients, repeated celebrations, a new navigation shape or removing useful borders.

## Suggested delivery order

1. Protect account/date ownership and workout data; repair dead routes, assertions and stuck states.
2. Refine onboarding and numeric editors with existing components; fix observed Home/Profile/history/yearly/timer layout failures.
3. Align date/completion/share/achievement meanings and recovery messages.
4. Verify on target Android devices with real keyboard, permissions, camera, TalkBack, Google restore and offline/online transitions.

## Evidence and limits

The audit uses source inspection plus temporary Flutter observation harnesses with bundled fonts and deterministic repositories. Onboarding: three configurations/fifteen captures; Profile: two configurations/eight captures; Workout: twelve observation cases including defect reproductions and rendered surfaces; Home/remaining surfaces: fourteen observation cases. The harnesses intentionally collect layout errors and reproduce existing bugs, so successful harness completion is **not** a claim that these app flows passed validation.

Normal 390px, narrow 320px, 200% text, selected keyboard-inset scenarios, and light/dark Home/body/yearly renders were inspected. Not every screen was rendered in every combination. Native platform dialogs, full authenticated backend transitions, physical status bars, camera capture, YouTube playback, screen readers and Indic font fallback still require device verification. The simulated keyboard/inset evidence should not be described as a native device test.

The preceding full regression run passed 379 tests with one existing skip; this audit exposes scenarios that that suite did not cover. Do not use that baseline as evidence against the concrete defects above.

Detailed working notes and screenshots: `build/app-audit/onboarding.md`, `profile-and-utilities.md`, `workout-and-gita.md`, `home-layout-observations.json`, and their adjacent PNGs/logs. Build artifacts are optional review material and should stay out of the user's source ZIP. This report remains in `docs/` so the actionable findings travel with the source.
