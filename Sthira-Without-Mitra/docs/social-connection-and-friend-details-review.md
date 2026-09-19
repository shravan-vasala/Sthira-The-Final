# Social connections and friend details

19 September 2026. This follows the [Daily Check-in and remaining fixes](daily-check-in-and-pending-fixes.md) checkpoint of 797 passing Flutter cases and one skip.

## Result and scope

The confirmed social connection, shared-profile and friend-details defects found in this pass are implemented. The existing Social/Friends/Leaderboard structure, friend cards, brand colors and typography remain. Friends now have a live shared-details sheet, accessible from the card, leaderboard and successful connection screen.

No private activity-history browser or public health-profile search was added. No real invitation, account mutation or deployment was performed.

## Findings and changes

| Area | Confirmed issue | Implemented behavior |
|---|---|---|
| Guest entry | Guests saw empty social content and the Enter ID flow could attempt a request without a usable account. | Both Social and Connect provide a direct sign-in path; account transitions show loading. |
| IDs and invitations | Full copied invitations failed ID validation; send failures only used transient snackbars; late responses could affect a changed account. | Paste accepts the app's invitation or a plain ID. Validation is shared with the service. Input stays available after failure, sending prevents duplicate actions, and responses are account-bound. |
| Request status | Repeated sends generated a new request identity and could reset accepted handshakes. The sent screen stayed pending after acceptance. | Existing pending identities remain intact. Pending/accepted/unavailable-ID results have distinct handling. The sent screen watches connections and changes to Connected with View friend details. |
| Recipient availability | A syntactically valid nonexistent ID could receive an undeliverable request. | New request creation requires an existing recipient social profile. Errors explain checking the ID or asking the friend to open the app and finish syncing. No public profile read is needed. |
| Incoming requests | StreamBuilder recreated subscriptions during UI changes; requests/errors lacked useful labels or direct retry; long rows overflowed. | One account-scoped provider supplies requests and counts. Accept/Decline are labeled, mutations prevent duplicate actions, and errors can resubscribe directly. |
| Friend metadata | Recovering a known friend did not update their name/avatar. | Local upsert refreshes metadata while preserving connection identity and its original date. |
| Connection recovery/removal | A failed profile stopped recovery of later friends; another device's removals were not reconciled live; removal could race a delayed recovery fetch. | Recovery isolates each friend. A distinct server-confirmed roster stream updates local membership; offline/pending snapshots cannot remove friends. Removal runs through the same serialized coordinator as recovery. |
| Stream lifecycle | An idle roster stream could hold cancellation open. | Stream transforms pass cancellation directly to the Firestore subscription, covered by a regression. |
| Friend details | No details screen existed; old values could look current; profile updates were labeled as activity/presence. | Live details show the actual shared day/week, recorded coverage, and an absolute Last shared time. Missing, denied, removed and loading states are explicit and retryable. |
| Shared values | Missing/malformed fields became fresh zeros; cards invented a 10,000-step goal. | Shared date/coverage metadata distinguishes recorded zero from missing data. Legacy/malformed records are read defensively. No progress target is invented for another person. |
| Weekly leaderboard | “Week” used a rolling seven-day score, excluding today; stale data could rank as zero; the local row did not consistently refresh. | A shared local publication provider uses Monday-to-today recorded days and supplies both publication and the local leaderboard. Unknown/stale/future values stay unranked; recorded zeros remain valid. Ties retain equal ranks. |
| Score clearing | Null scores were omitted from merged updates and could leave older values in Firestore. | Complete optional snapshot fields clear obsolete scores/coverage while keeping sharing permissions separate. Restored pending snapshots also clear missing scores. |
| Shared identity | A profile payload could disagree with the document ID requested. | Reads use the actual document identity; malformed payloads cannot impersonate another row. |
| Accessibility and layout | Long names/filters overflowed; controls were icon-only; repeated details headings consumed space at larger text. | Named actions, safe preset/initial avatars, flexible names and filters, and large-text layouts preserve access to the content. The details header is compact and does not duplicate the name. |

## What a friend can see

The details view uses the existing shared snapshot: name/preset avatar, shared day, steps, completed workouts, daily score, step-goal streak, weekly totals and weekly average score. Added date and coverage fields explain those existing aggregates.

Personal notes, Daily Check-in text, meal photos, progress photos, local image paths and private logs are not added to social publication. The rules continue to protect social activity using the existing accepted-friend sharing grants; they do not allow public discovery of health data.

Last shared means snapshot time, not online status. Absolute time labels use a fresh clock separately from the cached calendar-day provider. Delayed uploads retain the date of the recorded snapshot. Legacy rolling-seven-day scores are not presented as calendar-week averages until the updated client shares the new metadata.

## Backend rules

The rules now constrain invitation field types/timestamps and prevent accepted requests or acknowledgements from being replaced with pending requests. Existing request IDs cannot be silently replaced. New invitations require a published recipient; existing pending requests retain compatible acceptance behavior.

**21/21 local Firestore emulator tests passed**, including all 11 previous checks and ten added regressions. Five of the new cases failed before the rules fix, confirming the defects. Logs: `build/social-rules-before.log`, `build/social-rules-final.log`.

The emulator used a local demo project, not production accounts. The maintained harness remains under `test/firestore/`.

## Verification

- Full maintained Flutter suite: **869 passed, 1 existing skip, 0 failures**, across **127 test files** under `test/`. This adds 72 passing cases since the 797-case checkpoint. Log: `build/social-final-verified-suite.log`.
- Dart analyzer: **0 errors, 62 warnings, 468 infos**. Existing diagnostics remain; this is not a clean-lint claim. Log: `build/social-final-verified-analyzer.log`.
- Four temporary real-font render cases passed: normal 390px and 320px/200% text, light and dark. Twelve card/details/footer PNGs were produced in `build/social-audit/`. Representative normal light/dark and enlarged details renders were inspected, then the repeated header was simplified and rerendered. Log: `build/social-details-final-layout.log`.
- Regressions cover shared model parsing, actual reactive publication, calendar-week semantics, request UI, live details, access/account changes, SDK stream cancellation, native local friendship persistence and request/roster transitions.
- `git diff --check` passes. All 361 Dart files under `lib/` and `test/` decode as UTF-8 and contain no replacement characters.
- The existing Android resource validator was not rerun because Android files were unchanged in this social pass. No native device/production-account result is implied by these tests.

The single skip is the existing full native widget-channel integration placeholder. Firestore cases and temporary render cases are separate from Flutter's maintained suite count.

## Release boundaries

- Ship the updated client and Firestore rules together. Rules have not been deployed.
- Verify with two real accounts: share ID, send request, accept, wait for shared details, edit shared activity, reopen, remove, and check access from the peer and a second device.
- Verify the native share sheet and clipboard on the intended phone. No Android SDK/device was available for APK/native validation.
- A newly signed-in person's profile must finish its initial sync before their ID can receive a new request.
- An accepted request may briefly wait for the requester's acknowledgement before both profiles are readable. The UI treats unavailable shared data as unavailable, rather than showing invented zeros.
- Removing a friend revokes access to the remover's current shared profile. Previously viewed information cannot be recalled from someone else's device; this implementation does not claim remote data erasure.
- Earlier non-social release checks remain: real-device meal scanning latency/accuracy, camera/barcode, notifications, Health Connect and native widgets.

No commit, push, production deployment or ZIP export.
