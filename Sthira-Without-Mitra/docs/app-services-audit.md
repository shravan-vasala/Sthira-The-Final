# App services audit

Implementation follow-up: [services and backend fixes](service-fixes.md). Original findings below are retained as the audit record.

Reviewed 19 September 2026 against the current local working tree. Scope: all 25 files in `lib/services`, plus their providers, persistence models, repository callers, Android bridges, relevant rules and tests. This is an analysis pass. No app behaviour, maintained tests, commits or pushes were changed.

## Verdict

Keep the current architecture and the recent AI/progress improvements. There is no evidence that changing frameworks, adding more AI calls or replacing every service would help. The highest-value work is making account ownership, backup/restore, sync conflicts and measurement semantics dependable. Several concrete bugs can lose or misrepresent data; speed work should not hide them.

The AI JSON request path already has useful request deadlines, cancellation, fallback limits and local computation. The barcode parser and deterministic progress calculations are also worth preserving. The weaker boundaries are cloud writes versus local edits, account changes during asynchronous work, notification actions, backup transactions, and cached or estimated nutrition presented with excessive certainty.

## Coverage of every service

All paths in this table are under `lib/services/`.

| File | Decision | Main finding or reason to keep |
|---|---|---|
| `ai_client.dart` | Keep transport; fix streaming completion | JSON transport is bounded; token cancellation can leave text-stream consumers waiting forever. |
| `ai_cache.dart` | Keep account pinning | Recent cache ownership and invalid-result protections are valuable; review cache identity/version boundaries without a rewrite. |
| `ai_logger.dart` | Keep lightweight logging | Bounded in-memory diagnostics; no reason to put more logging on the scan's critical path. |
| `ai_profiler.dart` | Refine evidence quality | Timing helps, but synthetic fixtures and incomplete stage timings do not establish real meal accuracy. |
| `image_preprocessor.dart` | Keep isolate processing | Resizing/encoding away from UI is useful; account for decode failure and orientation/image-format coverage. |
| `gemini_food_service.dart` | Targeted accuracy fixes | Per-serving basis is corrupted in one text path; suggestion cache scope/precision and confidence need correction. |
| `nutrition_lookup_service.dart` | Improve data/metadata | Common foods are absent; a powder alias maps to a prepared drink; estimated provenance is dropped. |
| `barcode_food_service.dart` | Keep | Explicit nutrition bases, unit validation, barcode identity, bounded requests and recoverable errors add value. |
| `coach_service.dart` | Refine ownership/recovery | Streaming cancellation and account/date-specific note/cache lifecycle need consistency. |
| `app_database_manager.dart` | Fix account lifecycle | Per-account directories are good; guest transfer, retained legacy copies and callers' rebinding are incomplete. |
| `auth_service.dart` | Keep authentication; integrate lifecycle | Firebase/Google auth events do not themselves move repositories or clear account-owned work. |
| `firestore_sync_service.dart` | High-priority correction | First-open database selection, unbounded failed retries, conflict/deletion semantics and restore coordination. |
| `social_sync_service.dart` | Correct state transitions | Accepted-request markers can restore removed access; reciprocal requests conflict with rules. |
| `schema_migration_service.dart` | Implement supported-version contract | Restore migration is a no-op and unsupported schema versions are accepted by verification. |
| `backup_service.dart` | Highest-priority repair | Actual no-media backup produced an empty ZIP; restore hits incompatible transaction calls. |
| `backup_encryption_service.dart` | Keep authenticated v2 format | Random salt/nonce and tamper rejection are useful; move costly work off UI rather than weakening derivation. |
| `csv_export_service.dart` | Correct account scope; preserve format | Actual two-database export selected the first database; range and test coverage also need refinement. |
| `diagnostic_logger.dart` | Small hardening | New entries are bounded/redacted; reloaded entries bypass those protections and persistence failures are not awaited. |
| `health_connect_service.dart` | Fix ingestion/account boundaries | Empty becomes zero downstream; late reads cross account switches; partial backfill can be marked complete. |
| `notification_service.dart` | Finish behaviour and recovery | Snooze/Skip/tap events have no consumer; scheduling success is not exposed reliably. |
| `screen_time_service.dart` | Fix guest integration; verify native metric | Guest results are dropped; daily usage buckets are not a precisely clipped screen-time measurement. |
| `progress_aggregation_service.dart` | Keep | Sparse values, true zeros, weighting, date exclusions and unit handling are meaningful improvements. |
| `progress_insight_service.dart` | Keep | Coverage and comparison rules are useful; fix upstream false zeros and the stale current-day provider. |
| `widget_coordinator.dart` | Align lifecycle and semantics | Listeners can remain attached to old repositories; profile/plan changes do not trigger snapshots; meal counts differ from app. |
| `haptics.dart` | Keep | Small, centralized helper; no concrete high-value redesign identified. Device behaviour remains unmeasured. |

Detailed domain reviews are linked below. A service being marked Keep means no material rewrite is justified by this review, not that every device/network combination has been certified.

## Highest-priority findings

### 1. Backup creation and restore both have reproducible failures

`backup_service.dart:143-178` calls ZIP `addFile`, `addDirectory` and `close` without awaiting them. In the installed archive 4.0.9 implementation, file insertion waits for filesystem metadata, so finalization can happen first. An actual `createBackup(includeMedia: false)` call against a populated temporary database returned a path whose ZIP contained **zero entries**. This is the automatic backup path too. Do not report a backup as successful until required files exist and the archive can be read back.

Restore separately calls synchronous Isar JSON export/import inside an asynchronous write transaction (`backup_service.dart:516-524`). With pinned Isar 3.1.0+1 this throws a nested-transaction error at the initial queue snapshot, before clearing data. Both an otherwise valid fixture and a future-version fixture returned failure and retained the current records. Use a consistent transaction API and prove a complete create/verify/restore round trip on isolated data.

The Restore screen also ignores whether its promised safety backup succeeded (`backup_restore_screen.dart:388`). A valid safety copy should be a prerequisite for destructive replacement. This is especially important while fixing the broken archive writer.

### 2. One operation must remain bound to one account

The sync queue, backup and CSV services resolve `Isar.instanceNames.first` instead of the database belonging to the visible account (`firestore_sync_service.dart:46,183,213`; `backup_service.dart:76,410`; `csv_export_service.dart:65`). A two-database CSV probe exported the first account's 1,111-step record instead of the second account's 2,222-step record. The service offers no explicit account parameter to correct this.

Guest-to-account sign-in rebinds before deciding which local data to upload; sign-out does not rebind to guest. An empty signed-in database also queues a default profile during initialization, before cloud hydration. These are related lifecycle defects, not separate reasons to add warning dialogs.

Health reads can finish after shared repositories have been rebound. A temporary controller probe starts under A and observes the write through B. The health service retains its startup database for history configuration. Bind jobs, caches, queues, subscriptions and writes to an immutable account/database generation; cancel or drain old work before switching. The cloud notes below distinguish reproduced local behaviour from live-backend risks.

### 3. Failed sync must stop retrying and preserve the newer edit

`firestore_sync_service.dart:211-336` loops while retained queue items exist. Failed commits and malformed items stay queued and are retried immediately; pause is not checked inside the loop. Permission errors or an invalid item can sustain repeated work and prevent pause/drain from finishing. Use bounded attempts, backoff, an actual quarantined state, and pause/account checks at every batch boundary.

A second defect is durable conflict ordering. Meal saves put `updatedAt` into their outgoing payload, but `DailyMealLog` does not persist that version. After recreating the repository, an older cloud snapshot changed a locally pending **650-calorie meal to 250 calories**, while its newer outgoing write remained queued. Persist version/conflict metadata and make incoming snapshots respect pending mutations.

Cleared values also need explicit cloud deletion. Normal writes merge maps, while serializers omit null/removed fields. Clearing steps, sleep or a reflection can leave the old remote value present; removing a meal slot can leave a nested entry. Use deliberate field deletes or authoritative replacement semantics at the right document boundary. Firebase documents the distinction between merging and deleting fields in its [write-data documentation](https://firebase.google.com/docs/firestore/manage-data/add-data).

### 4. Fix food quantity meaning before pursuing more apparent speed

A remembered food with 100 calories per 50g initially computes a 100g portion correctly as 200 calories. The text-analysis result then changes its serving basis to 100g. Recalculating a 50g portion yields **50 calories instead of 100** (`gemini_food_service.dart:293,323` and scanner recalculation at `photo_calorie_scanner_sheet.dart:922`). Keep serving basis separate from consumed quantity throughout the contract.

The bundled lookup also aliases `whey protein` to a prepared 300g Protein Shake. The real local path returned **15 calories and 2.4g protein for '30 g whey protein', with high confidence**. This is a powder-versus-drink identity problem. All 119 bundled rows are marked estimated, but that provenance is dropped and successful local matching becomes high confidence. Preserve the difference between recognizing a food, estimating its portion and trusting its nutrient values.

Do not lower image quality further or replace the model merely to improve a stopwatch number. Correct the deterministic errors, improve reference-food coverage and evaluate weighed Indian meals before changing model/quality settings.

### 5. Stream cancellation must finish the consumer

Two probes of `AiClient.generateTextStream` showed a cancelled silent stream and an already-cancelled request never delivering completion or an error. The underlying source can be cancelled while the caller still waits. Current coach/suggestion wrappers impose 10/15-second overall deadlines, so those flows remain bounded, but cancellation needlessly waits for that deadline and can become a timeout. Finish the output stream exactly once on cancel/error/done and dispose timers/subscriptions. This primarily affects coach/text streaming; it is distinct from the already bounded meal JSON request path.

A further deterministic SDK-exception probe confirmed that error classification scans unrelated diagnostic metadata: a real HTTP 404 becomes invalid-key when its request ID or latency contains 403, or rate-limited when the request ID contains 429. Classify the typed HTTP status first, independently of display text. The maintained all-models-unavailable test failed once and passed in isolation; its original raw metadata was not retained, so this proves the mechanism rather than the precise cause of that first occurrence.

### 6. Missing measurements must stay missing

Health Connect returns explicit empty/error/success values, but repository ingestion converts empty sleep/steps to numeric zero (`daily_log_repository.dart:217-254`). That makes an unmeasured night look like zero hours of sleep and falsely increases chart coverage. Preserve unknown values and genuine successful zeros separately.

Backfill also treats any nonempty result list as full success: a probe returned one empty day after 89 failed days, satisfying the controller's completion condition. Track per-day outcomes and retry failed ranges. Reuse the same sync controller for Home and direct Steps actions.

### 7. Reminder controls need real, durable behaviour

Notification events are emitted to a broadcast action stream with no subscriber in the app. Snooze, Skip Today and reminder navigation therefore have no connected behaviour. The Body Fat toggle has no scheduling branch; a temporary provider probe recorded no notification when it was enabled.

Routine reminders are scheduled only seven days ahead without autonomous replenishment. Photo nudges are not scheduled for their future due date when a recent photo exists. Completion checks use different habit/meal/workout rules from the main app and do not watch the right updates. Implement one date-aware action controller and one tested schedule reconciliation path before adding more reminder types.

### 8. Removing a friend must remain removed

Accepted requests and acceptance acknowledgements are not distinguished consistently. An accepted request can remain in the recipient's own pending collection; removing the friend does not clear that marker. On a later start, pending-acceptance processing can recreate the friendship and its allowed-reader entry (`social_sync_service.dart:128-132,172-181`; `app_providers.dart:185-213`). This is a source-confirmed transition risk; it was not exercised against a live backend. Use explicit states and revoke related pending markers when removing access.

## Additional worthwhile corrections

### Backup completeness and recovery boundaries

Verification currently checks for a manifest and a nonempty JSON object, rather than a supported collection/schema contract. A fixture with schema **999** and only an unrecognized collection was accepted as valid. This was reproduced; destructive import was blocked by the transaction error described above. Reject unsupported versions and invalid structures before any mutation, validate counts/types, and define migrations instead of simply returning the input map.

There are further source-confirmed risks behind that blocking restore error. The intended restore clears the whole database, imports a collection allowlist that excludes Friends, and preserves the old outgoing queue unchanged. Listeners are not paused by merely pausing outgoing flushes. After the transaction fix, these paths could drop local friends, upload pre-restore edits or accept cloud snapshots over restored data. Resolve them together; this audit does **not** claim those later effects were observed during restore.

Media lives in shared app-level directories and backup enumerates those whole directories plus root image files, regardless of which account owns each record. Limit a backup to files referenced by its pinned account and define how missing media is reported. The auto-backup schedule/retention is also global, so one account's recent backup can suppress another's. Document what is included: barcode shortcuts, reminder settings and other preferences are not part of the JSON collection backup. Meal nutrition snapshots themselves are preserved in meal records.

### Responsiveness opportunities with a concrete cause

- Backup verification/restore read and decode whole ZIPs synchronously. Collection export, JSON, compression and password derivation also execute on the calling isolate. Async method signatures do not make this CPU work background work. Use bounded input sizes, stream where appropriate, and move heavy processing to a worker while retaining transaction consistency.
- Health backfill performs 180 sequential platform reads and up to 90 separate write/update events. Each routine-notification reconciliation cancels 130 IDs before scheduling replacements. Batch/checkpoint history and reconcile actual changes to avoid repeated work.
- Native Android usage-stat querying runs directly in the default platform-channel handler. Move expensive querying off the Android UI thread after measuring it; do not move Activity actions to a worker indiscriminately.
- These are structural costs, not measured phone latency. Benchmark first-frame time, scan-to-result, cancellation latency and frame stalls on a slower target Android device before setting numerical performance claims.

### Cache, date and widget consistency

Suggestion caching uses device-global preferences and rounded target buckets: the probe reused a suggestion for 199 calories when a different service credential requested 100 calories. Include account and relevant exact constraints in identity, validate cached output against the current request, and expire/delete it deliberately. Keep the newer account-pinned raw AI cache and barcode store.

The current-time provider caches its initial `DateTime.now()` and is never invalidated. Progress/score eligibility can stay on yesterday after midnight even while Home advances. Use one current-day signal refreshed on midnight/resume, separate from intentional historical selection.

`WidgetCoordinator` reads and subscribes to repository streams once (`widget_coordinator.dart:47-67`). Rebinding the same repository objects does not move existing stream subscriptions to the new Isar collections. It also does not watch profile/workout-plan changes, so a selected plan can stay stale until some unrelated event. Recreate/rebind the coordinator with account ownership and listen to the actual snapshot inputs. An in-flight sign-out clear also needs serialized writes rather than only checks around asynchronous platform calls.

Widget meal counting diverges from `DailyMealLog.loggedSlotsCount`: a calories-only meal is omitted and can produce null energy, while missing-plan fallback adds all custom slots on top of four defaults. Reuse the same completion/count contract. Native code already rejects a previous-day snapshot, which should be retained; process timers alone do not refresh a killed app.

### Exports, diagnostics and small helpers

CSV formula escaping, explicit units and the non-restorable-snapshot manifest are useful. Keep them. Correct its account dependency and the UI's Last 30/90 days inclusive-range off-by-one. Query the selected range rather than loading all history when that becomes a measured cost. Existing CSV tests copy the private sanitizer instead of exercising the exported file, so they cannot catch service integration defects.

DiagnosticLogger correctly bounds/redacts newly added entries, but loaded preference entries bypass both steps. A persisted synthetic 10,020-character message remained intact. Reapply sanitation on load and handle asynchronous preference-write failures; its current try/catch does not observe rejected Futures. Preserve the bounded ring rather than adding more verbose scan logging. There is no evidence to replace the small haptics helper.

The authenticated v2 encryption format is worth keeping; existing round-trip/tamper tests exercise it. Compatibility support for legacy CBC should not become the default writer. Do not weaken password derivation for speed; move it away from the UI. This review is not an independent cryptographic certification.

## Recommended delivery sequence

1. Repair and round-trip-test backup/restore, including account scope, safety copy, schema checks, queue/listener coordination and media coverage.
2. Unify account lifecycle; correct sync backoff, persisted conflict metadata, clears/deletions and social removal transitions.
3. Fix serving-basis/food-identity errors and confidence, suggestion-cache identity and stream completion.
4. Fix health empty/partial semantics and guest screen-time persistence; connect and test reminder actions/schedules.
5. Align midnight, widget and summary signals, then measure and address remaining performance hotspots.

Avoid broad refactoring, adding an analytics framework, switching AI providers or weakening validation unless measured evidence establishes a benefit.

## Verification and detailed evidence

The local observation runs completed 22 cases: a final combined run of 6 backup/export/diagnostic cases, 6 AI cases, 5 platform/controller cases and 4 repository/sync cases, followed by one SDK error-classification case with four metadata variants. One platform case is a successful signed-in control; the others document current failure behaviour or boundary gaps. Temporary observation harnesses intentionally reproduce defects; their completion must not be described as an app-pass result.

The existing service directory plus backup-encryption suite completed with 133 passed, 1 existing skipped widget placeholder and 1 failed API-key error-classification test. The failure expects model-not-found but receives invalid-key. The exact failing test passed on an isolated rerun; the subsequent deterministic SDK probe reproduced the metadata-classification defect. The AI appendix records this distinction. The CSV and widget-payload suites include copied logic/handwritten payloads, so their passing status does not cover the actual services.

Commands: `flutter test --no-pub --concurrency=1 --reporter expanded build/service-audit/backup-audit_test.dart build/service-audit/ai-review_test.dart build/service-audit/platform_probe_test.dart build/service-audit/data_sync_probe_test.dart`; `flutter test --no-pub --reporter expanded test/services test/backup_encryption_test.dart`. No real user database, cloud account, API quota, camera or device permission was used by the probes. All 358 baseline app/test/platform/configuration files remained unchanged, with no added or removed files in those scopes. `git diff --check` passed.

Detailed reviews:

- [AI, food, cache and coach services](service-audit/ai.md)
- [Authentication, databases, cloud sync and social](service-audit/data-sync.md)
- [Health, notifications, screen time and progress](service-audit/platform-progress.md)

Native Health Connect records, notification delivery/cold launch/Doze, actual account transitions, Firestore rules enforcement and lower-end Android profiling still need integration/device testing. The audit is complete at the source and deterministic-local-test level; it is not a production certification.
