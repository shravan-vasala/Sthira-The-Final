# Final experience fixes

Latest follow-up: [Daily Check-in and remaining audit fixes](daily-check-in-and-pending-fixes.md) — 797 passing Flutter tests, one existing skip; current completion and release boundaries.

Implemented following the [final audit](final-experience-review.md), 19 September 2026. This is a refinement of the current design: the hero cards, palette, type families, meaningful borders and Caveat interpretation remain.

Subsequent work: [test consolidation, meal trophies and guidance review](tests-trophies-and-guidance-review.md). The verification below records this earlier checkpoint.

## Implemented

- Water corrections recalculate derived habit completion. Clear removes the derived completion atomically, preserving explicit overrides and concurrent edits. The sheet resolves the default habit by stable ID and wraps the reached-goal badge at large text sizes.
- Sleep keeps exact calculated/imported durations until the user edits them. Saving 7h58m no longer turns it into an eight-hour success. Bedtime and wake-time controls have named button semantics and keyboard activation.
- Clearing water, sleep and other individual daily measurements preserves the day's reflection and check-in metadata.
- Progress photo screens retire old-account images, selection and pending actions. Export rechecks account ownership across asynchronous capture/file preparation before handing off to the native share sheet. Existing repository ownership checks remain.
- Gallery weights follow the preferred units, viewer notes are readable, and a single available photo stays selected while the second side offers the existing Add Photo flow.
- Welcome and Profile share a 48px, named reflection action with readable light-theme colour. Caveat styling and content remain.
- Home has a 44px profile image inside a 48px labeled action. It reuses the saved photo/preset, has an initials fallback, retains a quiet border and opens Profile. The greeting keeps its full width. Profile also uses the same safe media-path renderer.
- Widget meal totals match Home. Step goals respect schedule, creation date, direction and ambiguity; unknown steps remain unknown, and absent goals do not show a completed progress bar.
- Widget shortcuts use one canonical URI contract, wait for account readiness, reset the selected day and resolve the real workout day, including longer plans. Legacy installed shortcuts are normalized.
- Android widget layouts use supported RemoteViews classes, larger layout breakpoints, stacked goal/nutrition text and accessible action descriptions. Compact layouts prioritize the step count; launcher rendering remains a device check.
- Native launch/normal backgrounds use the existing warm light and forest dark colours. Android 12 splash resources inherit the correct day/night base. Flutter system bars follow the resolved app theme. The invalid source encoding in the app entrypoint is corrected.

## Verification

- Full maintained Flutter suite: **695 passed, 1 existing skip, 0 failures**. Log: `build/final-experience-full-suite.log`.
- Dart analyzer: **0 errors, 70 warnings, 460 infos**. This is not a clean-lint claim; the earlier checkpoint had 79 warnings and 452 infos. Log: `build/final-experience-verified-analyzer.log`.
- Android static resource validation passed: 20 XML files, all 3 RemoteViews variants, local resource references, provider-updated view IDs and light/night startup inheritance at API26/API31. Run `python test/native/check_android_widget_resources.py`. Negative probes confirmed detection of unsupported views, missing resources, wrong root updates and splash qualifier regressions.
- Four final real-font header renders passed: both themes at 390px/100% and 320px/200%. The dark normal and light large renders were visually inspected. Files: `build/final-experience-audit/final-header-*.png`.
- `git diff --check` passed.

Maintained regressions cover corrections and atomic clears, exact sleep thresholds, account changes during photo viewing/deletion/export, preferred units and notes, large text, keyboard/semantics, avatar fallback, widget payloads, midnight transitions and actual workout navigation. A real-entrypoint compile test is included.

## Native validation boundary

This workstation has no Android SDK, emulator or attached device, so no APK or launcher render is claimed. Before release, verify widget resizing and TalkBack, cold/warm shortcut taps, actual native sharing, and startup on Android 12+ and older supported devices. Native startup resources follow the system theme; an explicit in-app theme that differs from the system can still transition to its saved Flutter theme after launch.

Telugu font fallback still needs a target-device check. The desktop renderer's missing glyphs are not proof of an Android failure; no unlicensed font or speculative replacement was added. An already-open operating-system share sheet cannot be retracted when the account changes.

No commit, push or deployment was performed.
