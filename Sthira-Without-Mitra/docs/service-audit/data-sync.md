# Data, account, migration, and social service audit

Read-only audit of current working tree, 19 September 2026. No production or maintained-test files were edited. Root ran `build/service-audit/data_sync_probe_test.dart`; all four observation cases reproduced the present defects. These are deliberate bug reproductions, not acceptance tests proving correct behavior. Firebase Auth, Google sign-in, Firestore networking, and deployed rules were not exercised.

## Coverage and strengths to preserve

| Service / boundary | Reviewed | Useful existing behavior | Verdict |
|---|---|---|---|
| `AppDatabaseManager` | Complete file; main startup; account transition; database schema list; isolation tests | Named user databases; reuses already-open matching instance; avoids overwriting an existing destination database | Keep per-account storage, repair migration ownership and lifecycle |
| `AuthService` | Complete file; interfaces; both auth provider declarations; all sign-in/out/delete callers | Google cancellation returns null; errors are surfaced; sign-out invokes both Firebase and Google | Credentials alone are handled; app state transition is incomplete |
| `FirestoreSyncService` | Complete file; interface; every repository attachment, queue writer, cloud importer/exporter, backup pause/resume caller | Local transactional outbox in repositories; one active flusher; UID-tagged queue entries; upload/delete canonical folding; removes exact acknowledged IDs; checks UID before network commit; 450-operation queue chunks | Preserve outbox design; repair scope, retry, replacement/deletion semantics, and hydration |
| `SocialSyncService` | Complete file; SocialProfile; FriendRepository; controller, streams, Connect, acceptance, remove, leaderboard callers | Private allowed-reader profile access; IDs forced from request document IDs; batched grant/accept marker; debounced profile captures UID and does not overwrite allowedReaders when omitted | Request lifecycle and account awareness need correction |
| `SchemaMigrationService` | Complete file; startup and backup restore callers; existing migration test | Explicit version marker; migration work separated from cache pruning | Current implementation is a version stamp/pass-through, not a backup migration mechanism |
| `SeedMigrationManager` | Complete meal/workout branches; actual seed assets; both repository initializers | Versioned seed updates preserve record ID; user-name collision produces separate Expert plan; existing user-authored plans protected | No high-priority defect found inside the seed manager; preserve approach and add meaningful upgrade fixtures |
| `firestore.rules` | All rule paths matched against client collection paths and batched acceptance behavior | Own-user restriction on private sync; private social reads; sender/recipient restriction on requests; read-only public plans | Broad access design is sound; reverse-request acceptance case conflicts with rules |

Supporting review: profile, daily logs, meal logs/plans, habits/completions, body stats, workout plans/sessions, exercise logs/PRs, coach notes, badges, friends repositories; account/sync/social providers; main startup; backup UI/service boundary. Widget/health observations were relayed to the agent owning device services.

## P1: correctness, privacy and availability

### D1. Outbox reads and helper writes target the first opened database, not the active account

**Evidence:** `lib/services/firestore_sync_service.dart:46`, `:157`, `:170`, `:183`, `:213`; `lib/providers/app_providers.dart:342` switches repositories without closing the earlier DB. Repository queue writers correctly tag and persist records in their own `_isar.name`.

**Trigger/consequence:** Open guest or account A, then sign into B in the same process. B's repositories store edits in B, but flush/pending-count look in the first opened DB. Filtering for B's UID does not fix choosing A's DB: B edits can remain unsynced and its pending count can be misleading. The helper profile/upload/delete methods may instead put B-tagged work into A's local outbox. Restart can appear to fix it by changing which database is opened first.

**Minimum fix:** Inject or resolve an explicit active database with account generation/UID; pin it for the flush, queue and count stream; rebind streams during every account transition. Keep queue ownership checks. Do not fix this only by closing databases without draining/cancelling their work.

**Confidence:** High, fresh source trace; existing isolation tests do not instantiate the actual sync service with multiple open DBs.

### D2. Failed or malformed outbox work causes an unbounded retry loop; pause/drain can hang

**Evidence:** `firestore_sync_service.dart:208-228`, `:273-298`, `:307-328`, `:62-66`.

**Trigger/consequence:** A commit repeatedly returns permission-denied/invalid-data or another permanent error. Nothing removes those items and the while loop immediately fetches and submits them again. Malformed payloads are logged as quarantined but never moved or marked: an all-malformed set can repeatedly attempt empty batches. There is no backoff, progress check, attempt budget or pause check inside the loop. `pauseAndDrainSync` waits for `_isFlushing` to clear, which may never occur; a network commit awaiting connectivity also has no bounded drain behavior. A bad record can keep unrelated records in the same failed batch pending.

**Minimum fix:** Exit the current pass on no progress/error; bounded exponential retry for transient failures; durable quarantine with a visible recovery path for invalid records; check paused/account generation before each chunk/iteration; define a bounded, cancellation-aware drain. Persist work until acknowledged.

**Confidence:** High source control flow; no live/backend failure injection performed.

### D3. Full-record payloads use merge semantics, so cleared fields and removed nested entries survive in the cloud

**Evidence:** `firestore_sync_service.dart:292` and `:464` use `SetOptions(merge: true)`; `lib/models/daily_log.dart:84-103` omits null fields; `DailyLog.clearSteps`, `clearSleep`, `clearCheckIn`; `lib/repositories/meal_repository.dart:354-369` removes a slot from a map; `lib/models/habit.dart` removes overrides from the map.

**Trigger/consequence:** Remove a check-in or clear steps/sleep after they were synced. The queued JSON omits the field, and merge leaves the previous cloud value intact. A stream echo or another device can show the supposedly deleted data again. Deleting one meal slot while other slots remain similarly leaves the absent nested key in the cloud map; clearing the entire map is a distinct empty-map case. Habit override removal can fail in the same way when other overrides remain.

**Minimum fix:** Explicitly distinguish replace-snapshot writes from patch writes. For complete private documents use replacement with an appropriate conflict/version policy, or specify delete sentinels/mergeFields for owned maps and fields. Preserve top-level account metadata when replacing its profile sub-map. Do not turn off merge indiscriminately across social profile updates.

**Confidence:** High source + official SDK semantics. [Firebase add/update data documentation](https://firebase.google.com/docs/firestore/manage-data/add-data) states omitted fields remain under merge and discusses empty-map replacement. [Official Firestore SDK reference](https://github.com/googleapis/nodejs-firestore/blob/main/dev/src/reference/document-reference.ts) documents the same merge contract. No real cloud delete test was run.

### D4. Meal conflict protection loses its timestamp on persistence/restart

**Evidence:** `lib/models/daily_meal_log.dart:7-99` has no persisted/serialized `updatedAt`. `meal_repository.dart:229-236`, slot writers and append add it only to outbound payloads. Incoming guard `:90-96` asks `reloaded.toJson()['updatedAt']`, which is always absent. `_localEdits` only lives in the repository instance.

**Reproduced:** Save a 650 kcal lunch and its durable queue entry. Recreate the repository against the same DB, attach a mock cloud stream, then send a day-old 250 kcal lunch. Stored/displayed meal becomes 250 kcal while the newer 650 kcal queue item remains. Probe executes real `MealRepository`/Isar methods and mock transport only.

**Minimum fix:** Persist the mutation/version timestamp in the local meal model, round-trip it through backup/cloud formats, consult durable pending intent before replacing local state, and use the same version rule for stream and bulk imports. Specify cross-device conflict policy rather than relying on process memory.

**Confidence:** Reproduced; `data_sync_probe_test.dart`, first case.

### D5. Empty account initialization queues a default profile before remote hydration

**Evidence:** `lib/repositories/profile_repository.dart:19-23`, `:59-77`; `lib/main.dart:94-110`; Firestore service constructor `:29-30`. Startup fetches user plans but has no profile pull. Manual sign-in begins repository reinitialization before `hasCloudData`/`pullProfile` at `app_providers.dart:345-377`.

**Trigger/consequence:** A signed-in account has an empty/recreated local database. `ProfileRepository.init` generates a default profile plus an upload queue entry; constructing the sync service immediately flushes. This can overwrite a real cloud profile before hydration and can make a root user document appear to contain an existing backup even when only bootstrap data was written. In the manual sign-in case the first-DB bug may mask part of the race; correcting D1 must not expose it unnoticed.

**Reproduced portion:** Initializing a real ProfileRepository against an empty non-guest DB immediately creates `_profile_` upload work with default values. Cloud overwrite is source-confirmed risk, not a live observed account mutation.

**Minimum fix:** Separate unsynced local defaults from intentional user edits; determine/hydrate account state under paused outbound sync before queueing creation, then reconcile and resume.

### D6. Sign-out and guest/account migration lack a complete app-level lifecycle

**Evidence:** `lib/services/auth_service.dart:71-79`; `lib/screens/profile/profile_screen.dart:1028-1029`; only actual DB open calls are `main.dart:75` and manual sign-in `app_providers.dart:342`. The latter reinitializes repositories after sign-in and exports only the new scope, `:345-358`, `:422-471`. Existing open DBs remain open. `authStateProvider` updates auth display state, not repository binding.

**Trigger/consequence:** Sign out of A: app repositories still point at A, so A's private history can remain visible and subsequent signed-out edits still write/queue in A's database. Sign into a new account from current guest storage: guest data is not copied/imported into that account; UI switches to a new/default scope and uploads that scope rather than the user's existing guest history. A failed midway account transition has no rollback/recovery state and can leave partially rebound services. Reused repository objects also retain cached stream references/process-memory maps.

**Minimum fix:** One serialized account transition coordinator: capture old scope, pause/drain, cancel subscribers, migrate/adopt guest data according to explicit product intent, initialize/hydrate every service, invalidate/rebind all state, resume; handle sign-out and error rollback through the same coordinator. Do not rely solely on auth provider rebuilds.

**Confidence:** High source trace; no live Google accounts used. Previous screen audit identified related account symptoms; this pass freshly traced their services.

### D7. Legacy root database can be copied into every newly opened user account

**Evidence:** `lib/services/app_database_manager.dart:66-77` copies `default.isar` whenever a destination is absent but never claims/records the legacy source's owner or marks its migration consumed.

**Trigger/consequence:** An upgraded install retains the legacy root database. Opening account A and then a new B can seed both from the same private legacy data. Leaving the original file is sensible for rollback, but its mere continued presence must not authorize another account migration.

**Minimum fix:** A one-time migration manifest tying legacy data to its adopted guest/account scope; preserve the recovery copy separately and refuse to silently seed subsequent unrelated accounts. Test migration with actual legacy populated DB, not just a new guest DB.

**Confidence:** High source; current test named guest migration only saves/reads one guest DB and does not exercise this path.

### D8. Removing a friend can be reversed on the next startup

**Evidence:** `lib/services/social_sync_service.dart:130-147` retains the recipient's original request marked accepted and writes the sender's acceptance marker. `:99-107` reads all accepted records in the same collection as pending acceptances, without distinguishing the two roles. `:171-176` only removes allowed-reader access. `lib/providers/app_providers.dart:185-209` processes these on startup and adds local friend/access again through `social_sync_service.dart:197-212`. The removal UI invokes only removeFriendAccess and local remove (`friend_status_card.dart:270-271`).

**Trigger/consequence:** B accepts A, then removes A before B's next startup consumes the retained accepted record. On startup, B treats its own original accepted request as an incoming acceptance marker and can add A back to its friend list and allowedReaders. Even if a profile fetch returns null, processPendingAcceptance still grants access. This undermines a user's explicit revocation.

**Minimum fix:** Distinct request/acceptance/relationship state and roles; atomically invalidate outstanding reciprocal markers on removal; idempotent acceptance with explicit revocation precedence. A removed relationship must not be recreated from stale acceptance work.

**Confidence:** High source/rule-compatible control flow. Verify with Firestore emulator and two-user lifecycle before release; no live access changes performed.

## P2: incomplete synchronization and recovery

### D9. Cloud deletions and edits are not reconciled consistently across collections

**Evidence:** `FirestoreSyncService.streamCollection:367-385` emits a full map with no deletion metadata. Meal/daily/badge listeners only iterate returned entries. `meal_repository.dart:108-130` never removes a missing plan. BodyStats `:56-66`, ExerciseLog `:141-164`, CoachNote `:52-63` imports are insert-only. Profile/habits/body/workout/exercise/coach attachments mostly only store `_sync`, with no realtime reader. Main fetches workout/meal plans; manual sign-in pulls other collections once.

**Reproduced:** A meal plan received from a mock stream remains after the next full snapshot is empty. A body measurement corrected in cloud from waist82 to78 is ignored when the date already exists locally.

**Consequence:** Another device's deletions do not remove stale data; corrections to existing measurement/exercise/PR/note records may never reach this device, even through manual sign-in import. A locally removed but not yet uploaded plan can also be recreated by an older snapshot because there is no pending-delete/tombstone guard.

**Minimum fix:** A collection-by-collection contract defining replacement/merge/delete behavior, durable versions/tombstones, pending-intent precedence, and an explicit refresh lifecycle. Process remote removals only with an authoritative snapshot/change stream and protect local unsynced data. Avoid blanket deleting all absent local records on any cached/partial snapshot.

**Confidence:** Two behaviors reproduced, remaining collection differences source confirmed.

### D10. Workout sessions and friend relationships are missing from restore/reconstruction flows

**Evidence:** `workout_repository.dart:285` queues workout_sessions and defines import/export at `:367-405`, but `CloudSyncController` never pulls/bulk-uploads that collection. FriendRepository stores local Isar rows only and is not part of private cloud bulk restore; social allowedReaders exist remotely but are never used to rebuild a complete friend roster. Accepted markers are consumed/deleted.

**Consequence:** New-device account restore does not reconstruct finished workout sessions through the provided helpers. A user can retain server-side social sharing permissions while losing their local list of accepted friends after reinstall/restore; pending acceptance history is not a durable roster. Root independently reviewed archive collection omissions.

**Minimum fix:** Explicit tested persistence inventory for all user-created collections, and a durable relationship model/roster with recovery rather than relying on temporary request markers.

### D11. Manual restore pauses outgoing work but not inbound listeners, and retains stale outbox intent

**Evidence:** `backup_restore_screen.dart:385` invokes pause/drain, not repository detachment. `backup_service.dart:515-523` preserves old queued payloads while replacing data; no replacement outbox is generated. UI resumes sync in finally.

**Important current limitation:** Root reproduced an earlier blocking restore failure: the synchronous export inside an asynchronous Isar transaction raises a nested-transaction error before data is cleared. Therefore the following is a **latent design defect once that blocker is fixed**, not an observed destructive restore.

**Consequence after blocker is fixed:** Old pre-restore edits may upload immediately after restore; live incoming daily/meal snapshots can overwrite restored records. Cloud state is neither replaced nor intentionally kept separate, and restored local data is not consistently queued.

**Minimum fix:** Define local-only vs account-wide restore semantics, pause both directions under a generation barrier, reconcile/drop/rebuild pending work transactionally for that explicit mode, and only then reattach. Preserve a valid recovery backup. Root owns archive implementation findings.

### D12. Startup public-plan refresh can overwrite personal plans and race private refresh

**Evidence:** `main.dart:125-133` starts public/private workout fetches independently. `workout_repository.dart:332-361` sends both through `savePlan`, which replaces by key and queues the result back to the account. No source/ownership protection or version comparison is used in these remote paths. Meal global fetch similarly replaces matching plan names directly.

**Consequence:** A user-edited plan sharing a public plan key can be overwritten; whichever remote response finishes later wins and workout public updates can be re-uploaded as private plans. This bypasses the protection the SeedMigrationManager correctly implements.

**Minimum fix:** Stable IDs/namespaces plus source-aware versioned updates; do not modify user-owned records with public catalog refresh; hydrate private plans deterministically and import without echoing the same fetched data back to cloud.

### D13. Social acceptance is one-shot, not auth/reactive, and can acknowledge before local persistence

**Evidence:** `app_providers.dart:185-215` schedules one microtask at controller creation. It does not subscribe to auth or accepted-request changes. `:201` does not await friendRepo.addFriend; `:209` can delete the remote acceptance marker regardless of fetch returning null/local write completion. `socialSyncServiceProvider` and friend stream providers watch a stable auth-service object, not current UID.

**Consequence:** A friend accepting while the sender's app remains open need not appear until restart. Starting as guest and then signing in need not run the acceptance check. A transient fetch/local persistence failure can still consume the only marker; stable provider streams created signed-out may remain empty after login. Profile schema/document initialization is also assumed by batch.update during acceptance.

**Minimum fix:** UID-keyed stream lifecycle; authenticated startup/resume/acceptance reconciliation; await and verify required local persistence before acknowledging remote work; retry typed transient errors without treating them as absence; create/ensure own social profile before updates.

### D14. Reciprocal friend requests violate acceptance-marker rules

**Evidence:** `firestore.rules:12-33` allows accepted=true marker only on create; update permits sender only accepted=false, or target performing acceptance. `social_sync_service.dart:144` batch.set writes the reverse request path as accepted=true.

**Trigger/consequence:** A requests B and B requests A before either accepts. B's acceptance marker lands on an already-existing B-to-A request, so it is an update. B is its sender, not its target, and accepted=true fails every update rule. Entire acceptance batch is denied. The acceptance button only has try/finally, so this also lacks a clear recovery explanation.

**Minimum fix:** Model request and acceptance roles explicitly and add constrained reciprocal-request transitions to rules/client together. Emulator tests must cover no prior reverse request, simultaneous requests, duplicate acceptance, decline/resend, removal and stale markers. Do not relax write ownership broadly.

**Confidence:** High rules/client trace; emulator not run and deployed-rule parity unverified.

### D15. Social score publication misses relevant changes and cannot reliably flush on lifecycle events

**Evidence:** `_pushProfile` is triggered by dailyLogProvider/profileProvider changes only (`app_providers.dart:171-183`), although it reads `todayScoreProvider`; habit and meal changes can change scores without changing those watched sources. Social service push returns after scheduling a 3-second timer, has no durable outbox/dispose/flush, and errors only debug-print. Pending acceptance fetch/decline errors return empty/success-like outcomes. Connect's send call silently succeeds when signed out because service returns early.

**Consequence:** Friends can see stale meal/habit-derived scores; a quick background/termination can lose the last scheduled update. Guest send request can show sent-success without sending. Connectivity/permission errors may look like no requests/friend not found.

**Minimum fix:** Watch the actual score snapshot plus date rollover/auth lifecycle; typed result/error states; an awaitable flush/retry strategy for final social publication; avoid success on unmet authentication. Preserve small social payloads/private access.

### D16. Snapshot/queue work scales with entire history on the UI isolate

**Evidence:** `firestore_sync_service.dart:221-226` synchronously reads/sorts all outbox records then filters UID; `SyncQueueItem` has no UID/timestamp compound index. Stream snapshots map every document; each repository emission parses/re-serializes/compares every returned record and often runs one transaction per record. Three realtime collections have no history bounds. Error loops amplify this.

**Consequence:** Mature accounts and reconnect backlog can produce avoidable UI work, memory and repeated parsing; operation batching alone does not bound total work. Cloud sign-in also sequentially performs 11+ full collection fetch/import passes.

**Minimum fix:** First fix correctness. Then measure backlog/history sizes and frame time; index UID/ordering, fetch bounded pages, consume docChanges with deletion handling, batch local imports, parse immutable snapshots off the UI isolate where justified. Parallelize only independent hydration under a consistent account/generation. Do not add speculative caches that weaken correctness.

## Lower priority / contract gaps

- **Auth deletion incomplete:** `auth_service.dart:83-89` deletes Firebase Auth user only, does not orchestrate private Firestore/social/requests/local-media/outbox cleanup or recent-login recovery. No UI call was found, so this is an unexposed API contract gap, not an active deletion screen bug. Define account deletion end-to-end before surfacing it.
- **Service disposal absent:** Firestore connectivity subscription is never retained/cancelled; debounce timers and social timer have no dispose hook. Normal singleton lifetime limits current impact, but provider recreation/tests/account-scoped refactoring would leave workers alive. Add explicit lifecycle cancellation when correcting D6.
- **Duplicate auth provider declarations:** `app_providers.dart:164` and `auth_provider.dart:10` declare distinct providers with the same name. Both currently delegate to Firebase's singleton but only one is overridden in main. Consolidate to prevent divergent mock/lifecycle wiring; avoid treating this alone as proof of two real signed-in identities.
- **Schema migration is pass-through:** `schema_migration_service.dart:35-40` ignores manifestVersion; startup stamps version4 without legacy data transforms. Root confirmed verify accepts a future schema manifest. Reject unsupported future/legacy archive formats before restoration unless an actual conversion is provided. Existing v1 test only checks UserProfile.fromJson fallback defaults, not migration of backup structure into Isar.
- **Seed migration:** Keep current source/version protection. Add real fixture coverage for initial seed, repeat run, bumped asset version, same-name user plan, older Expert record, preservation of user records and IDs. Current source lookup by name is acceptable for shipped assets; renaming a seed later needs explicit migration/retirement mapping.

## Test evidence and limits

Root executed the four audit cases from `build/service-audit/data_sync_probe_test.dart`:
1. Durable new meal650 overwritten by older cloud250 after fresh repository instance; newer outbox still exists.
2. Remote meal-plan disappearance leaves local record present.
3. Empty account ProfileRepository initialization generates default profile upload work.
4. Existing body measurement import ignores corrected remote value.

Existing maintained tests reviewed: `test/services/data_isolation_test.dart`, `test/repositories/attach_sync_lifecycle_test.dart`, `test/repositories/badge_repository_merge_test.dart`, `test/services/schema_migration_service_test.dart`, plus repository concurrency boundaries. Useful tests cover direct isolated DB writes, cancelling/replacing attached subscriptions, protecting DailyLog against older timestamps, and preserving exact queue IDs. However, tests labelled overlapping flushes copy dedup logic rather than invoking FirestoreSyncService; the guest migration test does not migrate guest to account; the schema test only exercises model defaults. Existing green counts do not cover the identified actual service lifecycles.

Next high-value validation: actual Firestore service with injectable transport/time/connectivity; isolated account-transition tests; emulator rules/relationship lifecycle; restore under paused inbound/outbound work after root's archive blockers are fixed; bounded failure/drain behavior; deleted nullable fields/nested maps; multi-device edit/delete conflict. No live user data or credentials were accessed or changed during this audit.
