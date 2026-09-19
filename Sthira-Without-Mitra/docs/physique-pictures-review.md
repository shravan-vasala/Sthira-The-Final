# Physique pictures review

Reviewed on 2026-09-19 in response to checking whether physique pictures were implemented.

## Existing feature

The feature already exists at **Home → Daily progress → Physique** and the `/home/physique-pictures` route. It supports:

- Camera capture or gallery import; date, front/side/back pose, optional weight in the user's units, and a note.
- A date-grouped gallery with pose filters, full-screen zoom/swipe viewing, and single or bulk deletion.
- Photo comparisons with same-pose defaults, photo selection/swap, side-by-side and adjustable slider modes, and user-initiated sharing.
- Account-scoped local media and metadata, plus the existing media ZIP backup/restore flow.

The existing visual design and comparison modes are retained.

## Confirmed fixes

1. **Reachable first photo action.** The empty gallery could place its first-photo button behind the navigation dock and active rest timer. The empty state now scrolls and uses the measured dock inset. A regression checks 320px width, 200% text and an active timer; the button can be reached and opens the add-photo sheet.
2. **Safe dismissed-gallery confirmation.** A root delete-confirmation sheet can outlive its gallery. Its callback now checks that the gallery is mounted before reading providers, preventing a disposed-provider access and deletion after leaving the gallery.
3. **Account-specific error feedback.** Deferred picker, photo-save and optional habit-update errors only display while the originating account remains current. The existing save retry and committed-photo behavior are preserved.
4. **Shared media preservation.** Backup restore can make an avatar, meal and physique photo refer to the same physical file. Deleting physique metadata now unlinks the file only if no remaining progress-photo, avatar, meal-slot or scanned-meal reference resolves to it. Ordinary unreferenced files still get removed. Account ownership and metadata-first deletion remain in place; a failed reference check skips optional file cleanup.

There are no schema or backup format changes.

## Verification

- Before the empty-state fix, the new layout regression failed because the first-photo action was covered by the dock.
- Photo gallery, lifecycle and share-export tests: **26 passed**.
- Native Isar/temp-file photo cleanup, account ownership and backup tests: **35 passed**, including nine new shared-file/deletion regressions.
- The real-font dark-theme empty screen was rendered and visually inspected at 320px width and 200% text with the active timer. Generated probe/render files are under `build/physique-audit/`, outside the maintained test tree.
- Full maintained Flutter suite: **926 passed, one existing native-contract placeholder skipped**. This adds 14 regression cases to the previous 912-case checkpoint.
- Static analysis: **0 errors, 54 warnings, 461 infos** across `lib` and `test`; existing warnings remain.
- All 368 Dart files under `lib/` and `test/` decode as UTF-8. Maintained tests occupy 133 files under `test/`.
- `git diff --check` passed.

Logs: `build/physique-flow-verification.log`, `build/physique-storage-verification.log`, `build/physique-final-suite.log` and `build/physique-final-analysis.log`.

Native camera/gallery permissions, native sharing and accessibility on the intended Android phone still need a device smoke test. Platform interactions here use test doubles; no APK/device run or actual sharing was performed. Nothing was committed, pushed or deployed.
