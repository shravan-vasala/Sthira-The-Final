# Platform and progress service audit

Scope: fresh read-only inspection on 2026-09-19. All five assigned service files reviewed in full, with native Android implementation, manifest, sync/reminder/rest-timer/progress providers, repository persistence, entry points and existing tests. No production or maintained-test edits. Temporary observation probes: `build/service-audit/platform_probe_test.dart`. All five observation cases completed in the final coordinated run; log: `build/service-audit/final-observations.log`. These assertions deliberately confirm current defects plus a signed-in control, not correct production behaviour.

## Per-service coverage and verdict

| Service | Coverage | Verdict |
|---|---|---|
| `health_connect_service.dart` | Configure, availability, combined permissions, history request, today/date reads, sleep interval union, 7/90-day sync, completion marker, manual-data preservation and account transitions | Good explicit result types and overlap clipping; persistence loses their missing-data semantics. Backfill recovery/account boundaries need corrections. |
| `notification_service.dart` | Initialization single-flight, timezone lookup, app-launch/tap callbacks, permission requests, ID ranges, absolute/rest scheduling, Android manifest and pinned plugin implementation | Initialization guard is useful; callback integration is absent, body-fat setting disconnected, routine scheduling semantics incomplete. |
| `screen_time_service.dart` | Result parsing, Android gates, usage permission/settings fallback, native query, date ownership, status consumers | Useful typed result envelope and native date; guest persistence is disabled, native aggregation is not a strictly bounded screen-time measurement. |
| `progress_aggregation_service.dart` | Every metric and daily/weekly/monthly path; missing/zero, finite values, future exclusion, weighting, leap/calendar boundaries, unit conversion and dated observations | Recent implementation is sound for current local-date inputs. Keep. Main correctness risks originate upstream from stale clock and health-derived fake zeros. |
| `progress_insight_service.dart` | Every hero/stat/coverage/comparison path; current-day exclusion, evidence thresholds, body/latest vs period averages, units, zero baseline, incomplete nutrition disclosure | Keep; weighted averages and honest coverage are valuable. No reproducible India-time-zone defect found within this service. |

## Ranked findings

### P1. Late health reads can write into a different account's rebound repository

- Paths: `lib/providers/sync_controller.dart:91-122`; `lib/providers/app_providers.dart:338-356`; `lib/screens/home/widgets/daily_progress_grid.dart:199-235`; `lib/services/health_connect_service.dart:26-30`.
- Trigger: health sync awaits platform reads, then sign-in switches/reinitializes the shared repository objects before those reads finish. Health writes have none of the UID/generation check used for screen time.
- Effect: old-operation results are committed through the newly rebound account repository. Health service itself retains its startup `late final Isar`, so history completion is read/written in the old database after sign-in. Global `hc_connected`/last-sync preferences also survive account transitions.
- Minimal fix: use a database/account generation token on all reads and pre-write boundaries; cancel/drain health jobs during transitions; reconstruct or explicitly rebind account-owned health configuration and reset/scoped timestamps.
- Confidence: direct control-flow finding; executed temporary mock observation reproduces a late write into B after starting under A. Device/cloud transition remains untested.

### P1. Missing health data becomes a recorded zero and corrupts insight coverage

- Paths: `lib/services/health_connect_service.dart:151`; `lib/repositories/daily_log_repository.dart:217-243`; `lib/services/progress_aggregation_service.dart:93-98,130`.
- Trigger: a day has no sleep session; service returns `HealthReadResult.empty`. Repository writes `sleepHours: 0.0`. Equivalent handling writes zero steps for a null native result.
- Effect: a missing/unavailable measurement becomes a real zero in charts, averages, scores and recorded-day coverage; an existing nonmanual value may be overwritten by empty data. With seven nights where only one has an eight-hour reading, this path can report seven recorded nights and roughly 1.1 hours average instead of one recorded night at eight hours.
- Minimal fix: preserve unknown/null on empty results; keep explicit successful zero values; retain last-known values with freshness information until source deletion is established. Test integration from health result to repository to insight, not only aggregation fixtures.
- Confidence: high source-confirmed. Existing aggregation tests correctly distinguish genuine zero and missing; they do not protect this ingestion boundary.

### P1. Snooze, Skip Today and reminder deep links are not connected to app behaviour

- Paths: `lib/services/notification_service.dart:18,59-78,163-179`; `lib/main.dart:106-107,223-228`; `lib/providers/reminders_provider.dart:108-125`.
- Trigger: tap a reminder/action, including launch from terminated state.
- Effect: the service emits to a broadcast `actionStream` with no subscribers anywhere in `lib`. There are also no writes to the snooze/skip preference keys. Foreground tap opens the app but does not implement the requested action. Cold-launch microtask runs during pre-runApp initialization, so even a later listener would miss that event.
- Minimal fix: one long-lived controller consumes/validates versioned payloads, applies skip/snooze and date-aware navigation, and queues cold-launch intent until router readiness; test cold/warm launch and duplicate actions.
- Confidence: high source-confirmed repository-wide searches. Pinned notification plugin 17.2.4 routes the current `showsUserInterface: true` actions through the Activity, so a missing ActionBroadcastReceiver is NOT asserted as the cause.

### P2. Successful screen-time readings never persist for guests

- Paths: `lib/providers/sync_controller.dart:61-79`.
- Trigger: local/offline user enables usage access without signing into Google.
- Effect: the ownership guard requires non-null auth UID, so even a valid native result is dropped. This contradicts the app's guest/local mode.
- Minimal fix: validate the active database/account generation including the guest scope; do not equate local-write permission with cloud authentication.
- Confidence: reproduced; a successful 123-minute guest result caused zero writes, while the signed-in control persisted it.

### P2. Backfill marks a partial failure as permanently complete; an alternate path never marks completion

- Paths: `lib/services/health_connect_service.dart:208-247`; `lib/providers/sync_controller.dart:119-125`; `lib/screens/home/widgets/daily_progress_grid.dart:223-235`.
- Trigger: 89 days fail for both metrics and one day yields empty data. Backfill returns a nonempty list, the controller writes it and marks the whole job complete. The direct Steps CTA path does the reads/writes but never calls `markBackfillDone`.
- Effect: failed old dates are not automatically retried, while the direct path can redundantly redo successful history. Today's/7-day partial failures also still write a successful-looking global sync timestamp.
- Minimal fix: return per-day/per-metric outcome and explicit completeness; checkpoint only successful ranges, retry failures, share one controller with the CTA and expose partial/error state.
- Confidence: high source-confirmed; executed probe confirmed the 1 empty +89 failed shape. History denied remains retryable, which is good.

### P2. Body-fat reminder toggle is disconnected

- Paths: `lib/screens/profile/reminders_screen.dart:294-303`; `lib/models/reminder_config.dart:26,159`; `lib/providers/reminders_provider.dart:63-80,128-383`; `lib/services/notification_service.dart:142`.
- Trigger: enable Body Fat Reminder.
- Effect: flag saves, but no scheduling branch reads it. It is also absent from permission-enabling detection, so Android notification permission is not requested when it is the sole enabled type.
- Minimal fix: define/use cadence and scheduling/cancellation with permission gating, or remove the toggle until implemented. Avoid leaving a working-looking control.
- Confidence: reproduced; bodyFatEnabled=true with other categories disabled scheduled zero notifications.

### P2. Reminder completion checks and listeners diverge from the app's real completion model

- Paths: `lib/providers/reminders_provider.dart:23-34,140-170,200-202,260-266`; `lib/models/habit.dart:317-372`.
- Trigger: complete a counter beyond target while another habit remains incomplete, finish an auto-derived habit, change a habit schedule, log lunch, or complete a workout when only workout reminders are enabled.
- Effect: raw summed habit progress can cancel all reminders even with unfinished habits, while auto-habit data/overrides/active weekdays are ignored. Habit completions and meal-log updates have no notification rescheduling listener. Daily-log listener is gated only by habits/meals, so workout-only completion does not reschedule. Weeks-only workout plans also have no active days in `workoutPlan.days`.
- Minimal fix: evaluate scheduled habits individually through shared completion semantics with the relevant daily log; watch actual habit/meal/workout changes and resolve the actual current plan week.
- Confidence: high source-confirmed; needs behavioural scheduling tests with auto/counter/overrides, inactive weekdays and workout-only configuration.

### P2. Reminder schedules expire, and photo nudges are never scheduled ahead of eligibility

- Paths: `lib/providers/reminders_provider.dart:143,197,270,320-321,354-380,386-387`; `lib/main.dart:225`.
- Trigger: stay away from the app longer than seven days, or take a photo then stay away until the 14-day nudge is due.
- Effect: habits/meals/workouts exist only as seven one-shot notifications; backup has one occurrence. No background replenishment/recurrence exists. For a recent photo, scheduler cancels the photo reminder and schedules nothing for the future due date, so that nudge depends on a later app event. Photo payload can also contain today's date when its fire time is tomorrow.
- Minimal fix: use a deliberate recurring/replenishment strategy; calculate the next photo due date even when not due now; align payload date with scheduled date. Verify reboot, absent app use and timezone changes on devices.
- Confidence: high source-confirmed; no on-device long-running delivery test.

### P2. Rescheduling amplifies health backfill into avoidable native/database work

- Paths: `lib/services/notification_service.dart:115-139`; `lib/providers/reminders_provider.dart:32-57,138,195,257,310,341`; `lib/services/health_connect_service.dart:226-230`; `lib/repositories/daily_log_repository.dart:217-243`; `lib/screens/home/home_screen.dart:49`.
- Trigger: initial Home sync (marked manual), bulk health backfill, or frequent daily-log updates with reminders enabled.
- Effect: backfill does 180 sequential native reads and up to 90 separate transactions/update events. Every notification reconciliation first makes 130 individual cancellation calls across all categories, including disabled ones, then schedules replacements. The `_needsSync` loop coalesces overlapping jobs but is not a debounce/diff and may repeat while bulk data arrives. Direct CTA sync bypasses the controller guard and can overlap it.
- Minimal fix: single-flight sync shared by all callers; today's data first, checkpointed batch history; batch unchanged-safe persistence, coalesced notifications based on actual schedule differences. Measure on a slower Android phone before deeper optimization.
- Confidence: high structural cost, not a measured latency claim. Dart await does not by itself block rendering.

### P2. Native screen-time calculation is not an exact current-day screen-time measurement and runs on UI thread

- Paths: `android/app/src/main/kotlin/com/trufit/trufit_bodamma/MainActivity.kt:20,28,71-78`; `lib/services/screen_time_service.dart:68-93`.
- Trigger: query during an ongoing foreground session, system bucket boundaries/overlap, many applications, or a slow usage-stats service.
- Effect: summing per-package `totalTimeInForeground` from `queryUsageStats(INTERVAL_DAILY)` does not guarantee strictly clipped midnight-to-now totals; the Android API explicitly permits expanding query bounds to whole intervals. The default MethodChannel handler performs the native query and iteration on the platform UI thread, making it a plausible resume jank source. No historical-day query exists, so yesterday's value stays at its last app sync.
- Minimal fix: define whether metric means foreground app usage or screen-on time; reconstruct bounded intervals/events with overlap/ongoing-session handling for the intended metric, query/reconcile the last completed day, run the expensive native query via a background task queue while keeping Activity actions on UI thread.
- Confidence: high API/source mismatch; exact magnitude/vendor behaviour requires Android comparison with system usage UI. Official sources: [UsageStatsManager](https://developer.android.com/reference/android/app/usage/UsageStatsManager#queryUsageStats(int,long,long)), [Flutter channel threading](https://docs.flutter.dev/platform-integration/platform-channels#execute-channel-handlers-on-a-background-thread-android).

### P2. Cached clock does not roll progress and score eligibility forward at midnight

- Paths: `lib/providers/app_providers.dart:58`; `lib/providers/progress_chart_provider.dart:20-21`; `lib/screens/progress/progress_screen.dart:446-448`; `lib/providers/midnight_tick_provider.dart:32-36`; `lib/providers/sync_controller.dart:25-29`.
- Trigger: keep process alive overnight or resume it next day.
- Effect: `Provider<DateTime>` caches its first `DateTime.now()` and is never invalidated. Midnight notifier only invalidates selectedDate, so new-day measurements can remain outside progress ranges or be treated as future while Home's selected date moves forward. Daily/weekly score services consume the same cached clock.
- Minimal fix: one app-level current-day provider refreshed at midnight and on resume; preserve intentional historical selection separately. Services already accept explicit today values, which is the correct test seam.
- Confidence: high source-confirmed; add an overnight/resume test spanning Home, progress and scores.

### P2. Sign-out cleanup does not clear persisted reminder configuration and can race an in-flight rescheduler

- Paths: `lib/providers/reminders_provider.dart:15,36-40,44-59,390-394`; `lib/screens/profile/profile_screen.dart:1028`.
- Trigger: sign out with enabled reminders, then restart, or sign out while queueSync is awaiting platform calls.
- Effect: `clearOnSignOut` cancels then resets memory but never removes/saves `reminder_config`, so restart restores old settings. A running reconciliation retains old profile/repository data and can schedule again after cancelAll.
- Minimal fix: scope preferences deliberately, persist reset or retain intentional per-account config, invalidate/drain a scheduler generation before cancellation and prevent late work.
- Confidence: high source-confirmed; transition race/device notifications untested.

### P2. Rest timer uses inexact alarms and immutable channel settings

- Paths: `lib/services/notification_service.dart:224-233`; `lib/providers/rest_timer_provider.dart:63-72,190-199`.
- Trigger: rest timer in background, or toggle sound/vibration after the first notification channel is created.
- Effect: `inexactAllowWhileIdle` does not guarantee a seconds-level completion alert; Android 12+ may deliver this alarm substantially later. Fixed `rest_timer` channel means later per-notification sound/vibration settings do not reconfigure the established channel. All scheduling errors are swallowed, so settings can appear functional without delivery.
- Minimal fix: select a supported exact-timer strategy with explicit permitted fallback and truthful delivery state; use channel variants/OS settings for sound-vibration preferences; sequence cancellation/scheduling and persist timer state atomically. Do not blindly request more permissions for routine reminders, whose inexact mode is appropriate.
- Confidence: source and official API contract; actual background/device timing untested. Current app has no production caller starting a timer, so prioritize after restoring a meaningful entry point rather than spending effort on a dormant feature. Sources: [Android alarms](https://developer.android.com/develop/background-work/services/alarms), [notification plugin channel caveats](https://pub.dev/packages/flutter_local_notifications/versions/17.2.4).

### P2/P3. Sleep-session duration and date-boundary semantics need an explicit contract

- Paths: `lib/services/health_connect_service.dart:126-192`.
- Trigger: sleep record includes awake stages, or a night-shift session ends after the hardcoded 18:00 cutoff.
- Effect: service unions whole sleep-session start/end intervals and labels them sleep hours. A session can include awake time; 18:00 clipping can split a long daytime session across dates even though the comment says sleep ending on the selected date. Existing overlap union itself is correct and worth keeping.
- Minimal fix: state session-duration fallback clearly; if intended metric is time asleep, union asleep stages when available with a deliberate fallback; choose/document end-date attribution and test naps/night shifts.
- Confidence: source/API-confirmed semantics; no real wearable dataset compared. [Android SleepSessionRecord](https://developer.android.com/reference/androidx/health/connect/client/records/SleepSessionRecord) distinguishes awake/sleep stages.

## Lower-priority portability and robustness observations

- Calendar navigation is mostly DST-safe, but `getStepsForDate` uses `start.add(Duration(days:1))`, backfill subtracts 24-hour durations, weekly Monday alignment subtracts 24-hour durations, and insight cutoff coverage uses duration `inDays`. This is not an India-zone defect; use calendar constructors/UTC date arithmetic before supporting travel/DST regions and test transition dates.
- `getStepsForDate` can build end < start for a future date. Manual explicit refresh uses absolute day distance, permitting future requests in the historical branch. Reject future target dates before native calls; observed UI normally avoids manual future editing, so this is boundary hardening.
- Health `_ensureConfigured` has no single-flight future while Home/Steps/setup can call concurrently. Consider consolidation before optimization; no configure crash reproduced.
- Notification init may fail timezone resolution, silently causing all schedule methods to return success-like `void` without scheduling. Expose initialization/permission/scheduling outcomes rather than silent success, but retain the current retryable `_initFuture` pattern.
- ScreenTimeResult has status strings and casts rather than a validated enum/numeric/date contract. Existing tests only exercise successful parsing/missing fields, not wrong-type/native boundary results. This is a useful boundary test addition, not a reason to rewrite the service.
- Reminder quiet-hours equality represents a full-day quiet period; snooze loop would never terminate if persisted snooze exists and quiet start equals end. Currently snooze actions are disconnected, so fix this boundedness before connecting them. Validate persisted weekday/time values to avoid unbounded next-weekday loops from malformed preferences.

## Existing strengths to retain

- Health manual overrides are preserved; sleep overlap clipping avoids obvious double counting; error/empty types already provide the right abstraction.
- Notification init single-flight, disjoint IDs and inexact routine mode avoid duplicate init/exact-alarm coupling.
- Sync controller has a basic overlap guard and observer disposal; screen-time result carries native measurement date.
- Progress service calculations preserve sparse observations, real zeros, finite values, actual measurement dates, weighted period means, future exclusions and logged-intake caveats. No need to add a new analytics framework or more AI to these deterministic computations.

## Verification limits

Source review included pinned package source (`health 13.3.1`, `flutter_local_notifications 17.2.4`), not only latest online descriptions. All five temporary platform probe cases completed successfully in the root-coordinated final run. Probe assertions intentionally reproduce defects and are not evidence that real-device services pass. No physical Android, Health Connect/wearable records, notification delivery/reboot/Doze, actual Google account transitions or native profiler were exercised. Existing progress aggregation/insight tests are meaningful, but no maintained health/notification scheduling tests were found; screen-time tests cover result parsing only.
