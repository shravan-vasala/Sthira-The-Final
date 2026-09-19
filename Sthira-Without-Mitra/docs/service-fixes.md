# Services and backend fixes

Latest social follow-up: [Social connections and friend details](social-connection-and-friend-details-review.md) — 869 passing Flutter cases, one skip, and 21 local social rules checks.

> Follow-up: See [remaining analysis implementation](pending-analysis-fixes.md) for subsequent fixes and final verification. Findings and test counts below describe their original review checkpoint.

Implementation summary, 19 September 2026. This follows the [complete services audit](app-services-audit.md), [AI review](service-audit/ai.md), [account/cloud/social review](service-audit/data-sync.md) and [platform/progress review](service-audit/platform-progress.md). Existing visual design and hero cards are preserved. No commit, push, production rules deployment or live account mutation was performed.

## Audit resolution matrix

| Audit area | Implemented result | Verification or remaining boundary |
|---|---|---|
| AI-01/02: portion basis and powder identity | Source serving mass stays separate from consumed mass through rescaling. Removed the unsafe whey-powder alias from a prepared drink; no replacement brand nutrition was invented. | Portion round-trip arithmetic and actual bundled lookup regressions. |
| AI-03/07/12: streaming and errors | Text transport aborts individual requests, including stalled header waits; cancellation finishes consumers. Only complete STOP responses succeed. HTTP status is classified independently of request IDs and latency. | Real local HTTP/SSE tests cover cancellation, concurrent requests, terminal-only STOP, truncation/blocked/missing completion and HTTP400 key errors. |
| AI-04/06/08/09: nutrition contract | Common foods receive the same explicit fallback instruction as rare foods. Shared Unicode-preserving name normalization reads legacy corrections. Estimated provenance remains visible in data; implausible nutrition stays unresolved. Large AI portions retain their original mass for review instead of being silently reduced. | Personal-food Isar round trips, schema/fallback/quantity tests. Common-food table expansion awaits documented reference data. |
| AI-05/11: personalized work | Suggestions cache exact account/date/macros/history/meals-left context. Coach and suggestion consumers reject stale chunks and writes; coach timestamps are account scoped. API-key setup recovers after edits/errors. | Competing coach refresh and account-generation tests; scanner saves capture the bound database. |
| AI-10: performance/accuracy evidence | Kept existing vision/text models and image settings. No speculative model switch, image degradation or request racing. | Real weighed-food accuracy and phone p50/p95 latency remain measurement work. |
| D1/5/6/7: account ownership | One serialized lifecycle pauses old work, binds the complete account scope, hydrates before creating cloud defaults, and rebinds guest on sign-out. Empty new accounts can adopt guest data once; retained legacy databases have a durable owner claim. | Isolated account/repository tests. Real Google sign-in, sign-out and multi-device recovery remain integration checks. |
| D2/16: bounded sync | Account-indexed, bounded outbox passes; transient backoff; durable quarantine for invalid/permanently rejected work; bounded pause/drain. Incremental authoritative snapshots avoid repeatedly reprocessing unchanged history. | Actual Isar with injectable cloud transport tests, including pending writes created during a commit. Device backlog/frame-time measurements remain open. |
| D3/4/9: conflict and deletion semantics | Full-record writes preserve clears/removals. Meal timestamps, sync versions and deletion tombstones survive restart. Pending local intent wins over stale remote data; authoritative removals and partial/cache snapshots are distinguished. | Durable meal conflict, tombstone, delta-snapshot, deletion and realtime profile regression tests. |
| D10/11: restoration completeness | Workout sessions participate in cloud hydration/export. Restore pauses both directions, drops obsolete queued intent, creates a fresh replacement outbox, and persists a crash-recovery reconciliation marker. Friend rosters can rebuild from durable sharing grants. | Queue/reconciliation ordering tests and backup round trips; destructive live cloud restore was not exercised. |
| D12: public plan ownership | Public refresh respects source/version and cannot replace user-owned plans or echo catalog imports as private edits. | Existing seed/plan protections retained; no new catalog or plan editor added. |
| D8/13/14: social relationships | Distinct request/acknowledgement roles and request identities; live acceptance recovery waits for local persistence. Removal atomically clears both reciprocal request records and the owner's sharing grant. Rules permit constrained reciprocal-request acceptance. | **11/11 Firestore emulator rules tests passed.** Coordinator tests cover stale work, persistence ordering and recovery. Updated rules must ship with the updated client. |
| D15: social publication | Actual score/date/account changes trigger updates. A small account-scoped durable outbox survives failures/restarts and exposes an awaitable flush. Profile snapshots cannot overwrite sharing permissions. Refresh failures have Retry. | Account/lifecycle wiring plus local rules checks. Production connectivity/device background behaviour remains unverified. |
| Backup creation, validation and restore | ZIP insertion/finalization is awaited and read back. Native consistent transactions replace incompatible nested calls. A verified safety copy is required; malformed archives roll back. Work and authenticated encryption run off the UI isolate. | Real Isar/ZIP/media/config round trips, rollback, ownership, encryption and archive-path/size/CRC tests. |
| Backup scope and migration | Complete schema5 snapshots include supported account records and referenced photos. Complete native schema4 snapshots migrate with an empty Friends collection. Unsupported old/future/incomplete formats are rejected before mutation. | See compatibility details below; no speculative destructive legacy converter. |
| CSV and diagnostic logging | CSV exports use the captured active account and explicit date boundaries. Reloaded diagnostic text is re-sanitized and bounded; preference writes/clear operations are serialized. | Actual CSV account/range/formula-output tests and diagnostic persistence tests. |
| Health ingestion and history | Missing readings stay unknown, successful zeros remain zero, manual overrides survive. Jobs and writes stay within their account/date; unchanged batches do not emit unnecessary writes. History uses checkpointed bounded chunks and retries failures. | Platform ingestion and ownership tests. Health Connect/wearable records require device verification. |
| Screen time and sleep semantics | Guest readings persist; previous-day reconciliation is included. Foreground usage uses bounded event intervals on a background native task queue. Sleep fallback is explicitly session duration attributed by end date. | Parsing/controller tests and native source review. Vendor usage accuracy, multi-window behaviour and actual sleep-stage data remain device checks. |
| Reminders and rest timer | Snooze/Skip/tap actions have a buffered, account-aware consumer. Scheduling uses actual completion rules, body-fat cadence and future photo dates. Native recurrence retains its first due date and restores alarms after reboot/time changes. Rest alerts expose exact/approximate/unavailable delivery with stable sound/vibration channel variants. | Reminder/action/date/ownership tests. Android compilation and delivery under reboot/Doze/timezone changes remain required. |
| Widgets and current date | Database subscriptions rebind on account changes; old writes are rejected. Profile/plan/habit/meal/clock changes update snapshots using shared completion semantics. Midnight/resume refresh current-day eligibility. | Widget/account ownership tests; physical launcher-widget verification remains open. |
| Media | Async copy/write/delete keeps the captured owner; new paths are account scoped while legacy paths remain readable. Backup restores preserve shared-file identity and avoid same-name collisions across media categories. | Media ownership and relative-path/shared-file backup regressions. |

## Deliberately preserved

The audit found no reason to replace the raw account-pinned AI cache, bounded in-memory AI logger, optional profiler, isolate image preparation, deterministic barcode calculations, progress aggregation/insight calculations or centralized haptics. Their existing controls remain. Backup encryption retains the authenticated v2 format and its existing derivation strength; it was not weakened to make exports appear faster.

This work makes data ownership, calculations, cancellation and recovery more dependable. It does not establish a measured scan-speed or meal-accuracy improvement.

## Backup and account compatibility

A backup is an account-record/photo snapshot, not a full device clone. API keys, login credentials, device preferences and disposable caches are excluded; restoring preserves device configuration. Schema4 and schema5 refer to the native data schema, separately from the encryption envelope version. Older encryption dispatch support does not mean arbitrary pre-Isar data can be restored. Unsupported older data must be re-exported through a compatible application version; future schemas are rejected.

Signed-in restore deliberately replaces the selected account's supported synced snapshot after a safety backup. Reconciliation failures distinguish an already committed local restore from a failure before replacement, and pending replacement work can resume after restart. Automatic backup dates/retention and exports are scoped to their account.

Account deletion remains unexposed and explicitly blocked in the service until authentication removal, private cloud records, social access, media, local databases and pending work can be cleaned up together. Deleting only the login identity would leave private data behind.

Ambiguous legacy accepted friend markers are not automatically replayed because that can recreate revoked access. Existing completed relationships recover from durable sharing grants. Legacy requests still awaiting a response can be explicitly accepted using the new role/identity contract.

## Verification and release boundary

- **Final Flutter verification: 459 passed, 1 skipped, 0 failed.** Full maintained suite completed after the final fixes; raw log: `build/service-fixes/verified-suite.log`. The skipped widget-channel integration test is explicitly marked unavailable in the maintained suite; the new widget ownership tests passed. The focused recovery run also passed 40/40 cases.
- **Final analyzer verification: 0 errors, 100 warnings, 408 informational findings.** Static analysis completed across `lib` and `test`; this is not a lint-clean repository. Raw output: `build/service-fixes/verified-analyzer.log`. `git diff --check` passed.
- **Social backend rules: 11 passed, 0 failed**, using a local demo project, Firebase CLI14.27.0, Firestore emulator1.19.8 and Firebase JS11.10.0. Tests cover ordinary/reciprocal/duplicate acceptance, decline/resend, removal before acknowledgement, stale replay, forged/third-party denial, legacy pending requests and preserving revoked access during subsequent profile publication. See [test instructions](../test/firestore/README.md) and [rules tests](../test/firestore/social.rules.test.mjs).
- The new Android notification receiver and usage-event integration were source reviewed. This environment has no configured Android SDK/device: APK compilation, Health Connect, notification actions/reboot/Doze, physical widgets, and usage comparisons must be checked before release.
- Real Google/Firebase account transitions, destructive cloud restore and multi-device conflict behaviour need integration verification. No production Firestore rules were deployed. Deploy [the updated rules](../firestore.rules) together with the client after release validation.
- Representative weighed Indian meals, lighting/occlusion, camera/gallery formats, cold/warm preparation and complete tap-to-result/save latency remain the basis for any later model or image-quality decision.


## Calendar and workout follow-up

The final screen/flow review is recorded in [calendar-workout-review.md](calendar-workout-review.md). The follow-up full regression suite passed **515 tests, with 1 existing integration test skipped and 0 failures**. This includes the earlier service/backend coverage. Native release boundaries above still apply.

## Project export

Keep source folders, assets, platform projects, tests, dependency lockfiles, rules and documentation. A source ZIP should exclude `build/` (including the downloaded Flutter SDK), `.dart_tool/`, `.git/`, `coverage/`, `android/.gradle/`, `test/firestore/node_modules/` and generated logs. Excluding those entries while making the archive is sufficient; deleting source folders is unnecessary. No ZIP or destructive cleanup was performed in this task.
