# Daily Check-in and remaining audit fixes

Latest social follow-up: [Social connections and friend details](social-connection-and-friend-details-review.md) — 869 passing Flutter cases, one skip, and 21 local social rules checks.

19 September 2026. Follow-up to [tests, trophies and guidance](tests-trophies-and-guidance-review.md). This report supersedes earlier counts and distinguishes confirmed local defects from release checks requiring a device or external service.

## Product decision

Daily Check-in adds value as an optional feeling or personal note, available today and on past days. It is a reflection, not a goal to complete. Keep the existing quiet styling, typography, colors and hero cards. No additional emotional score, check-in streak, trophy, notification or AI journaling was added.

The app was made for the owner's sister. A code review cannot establish whether she will enjoy it; her routine use is the remaining product validation. The useful next feedback is whether she can record a meal, correct it, record water and leave a reflection without confusion or pressure.

## Implemented

| Area | Confirmed problem | Result |
|---|---|---|
| Check-in choices | Bars had no visible labels until selection; cumulative fill looked like a rating; tapping the selected feeling erased its note. | All five choices are labeled, keyboard accessible and explicitly selected. Repeated taps preserve the entry. Explicit Clear asks before removing a written note. |
| Personal notes | Existing note-only entries were hidden and could not be edited without a mood. | Notes can be written independently, previewed when collapsed and reopened for editing. |
| Save feedback | No persistent status; stale props could overwrite edits; overlapping writes could finish out of order. | Local choices respond immediately, writes are serialized across Home/history, and Saved/Saving/Retry feedback follows the actual result. Clean focused editors accept synchronized corrections; dirty drafts remain intact. |
| Navigation failures | A failed originating-day flush could lose its draft after a date or page change. | Unsaved drafts remain in an account-scoped memory holder; returning to the day restores the draft and offers Retry. Successful writes are durable; this recovery holder lasts for the current account session, not an app restart. |
| Account safety | Queued/recovery work could outlive an editor. | Captured account guards reject old-account writes and recovery updates. Account changes discard retained drafts. |
| Accessibility | Unlabeled controls, large-text layout and reduced-motion gaps. | Five choices fit a normal phone; labels wrap evenly at larger text sizes. Native keyboard controls, adequate tap targets, existing light-theme text contrast and reduced-motion behavior are preserved. |
| Future dates | The reflection editor could record a feeling for a future day. | Future days show when check-in becomes available. |
| Persistence | Null note values retained the old note through copyWith. Metric snapshot updates could overwrite concurrent reflection edits. | Nullable mood and note clearing are explicit; note-only saves are valid. Water updates and water/body-fat clears use narrow atomic mutations. |
| Sync feedback | A background flush exception could report an already committed save as failed. | Durable local data and its queued upload remain successful; background sync retries independently. |
| Calendar/history | Reflection-only days looked empty. No workout plan was described as rest, and missing habit records as misses. | Recorded activity includes nonblank reflections and explicit readings. History distinguishes entries from completed goals, missing observations from unmet goals, and no plan from scheduled rest. |
| Daily score | A partial calorie subtotal could earn the accuracy bonus despite unknown calories. | Accuracy points require complete calorie data. Known calories remain usable when only macros are unknown. Mood does not award or remove points. |
| Legacy photo meals | Imported photo-only meals could look like known zero nutrition; adding food could erase that uncertainty. | Photo-only and multi-photo records remain logged with unknown nutrition unless an existing explicit flag certifies zero. Scanner/barcode append preserve prior uncertainty and independent calorie/macro completeness. |
| CSV export | The duration header was in the daily table and absent from the exercise table, shifting subsequent column labels. | Daily and exercise headers now align with their actual row values, including reflections and exercise duration. |

No persisted schema fields were added. Expert-authored meal/workout plans were not rewritten.

## Reflection privacy

Feelings and notes stay in the existing private DailyLog account data. They are included in owner-only account sync and user-requested backup/CSV exports; they are not local-only. They are absent from public social profile pushes and AI coach context. A new regression proves that adding a reflection does not change the coach input fingerprint or trigger AI activity.

Clearing the reflection removes its fields and timestamp while preserving unrelated readings. Account daily-log cloud writes replace documents, so cleared fields are removed remotely as well.

## Verification

- Full Flutter suite: **797 passed, 1 existing skip, 0 failures**, across **120 maintained test files** under `test/`. This adds 40 passing cases to the 757-case checkpoint. Log: `build/pending-fixes-final-full-suite.log`.
- New regression coverage: 13 additional check-in UI/lifecycle cases, 10 persistence/export/privacy cases, 7 score/history cases, and 10 photo-only nutrition/import/append cases.
- Dart analyzer: **0 errors, 64 warnings, 460 infos**. These remaining diagnostics mean this is not a clean-lint claim. Log: `build/pending-fixes-final-analyzer.log`.
- Four real-font Daily Check-in render cases passed: light/dark at normal 390px and enlarged 320px/200% text. Generated artifacts: `build/daily-check-in-audit/`. Normal light/dark renders and the enlarged light render were inspected.
- Android resource validator passed: 20 XML files and three widget variants, with API26/API31 light/night startup references checked. No APK compilation or native rendering was performed.
- `git diff --check` passed. All 350 Dart files under `lib/` and `test/` decode as UTF-8.
- The one skip remains the pre-existing full native widget-channel integration placeholder. It is not a passing device test.
- Firestore rules were unchanged this turn; the earlier 11 local emulator checks were not rerun or counted as Flutter cases.

## Remaining boundaries

The confirmed local defects identified in this follow-up are implemented. Historical audit notes must be read with their later completion reports; the old implementation plan is not a current backlog.

| Remaining work | Why it remains |
|---|---|
| Android build and physical-device flows | No Android SDK/device is available here. Verify camera/barcode permissions, launcher widgets, notification delivery/reboot/Doze, Health Connect, accessibility and native sharing on the target phone. |
| Production Firestore release and authenticated/multi-device behavior | Local rule checks are separate from production deployment and real-account testing. No production rules were deployed. |
| Meal scanning latency and recognition accuracy | The prepared opt-in benchmark needs a real device, configured service and representative weighed Indian meals. No unmeasured speed or accuracy improvement is claimed from this pass. |
| Missing expert portions/nutrients/instructions | Require expert source information; do not invent quantities or nutrition. |
| Optional product expansions | A full visual plan editor, new distance-logging contract, account deletion UI and an expanded sourced food catalog remain separate scope decisions, not unfinished bug fixes. |
| Target-device language rendering | Telugu/font fallback requires verification on the intended Android device. |

No commit, push, deployment, ZIP export or source cleanup was performed.
