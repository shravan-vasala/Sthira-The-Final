# Water, sleep, reflection, photos, startup and widgets

Read-only production review, 19 September 2026, following the 628-pass / 1-skip implementation checkpoint. The new probes exposed gaps that the maintained suite did not exercise. No app code, maintained tests, commits or pushes were changed in this review. Temporary tests, screenshots and logs are under ignored `build/final-experience-audit/`.

## Implementation follow-up

The confirmed corrections and Home avatar were subsequently authorized and implemented. See [final experience fixes](final-experience-fixes.md) for current behavior, verification and remaining device checks. Findings and probe counts below describe the original read-only checkpoint.

## Verdict

Keep the visual identity, hero cards, quick-entry sheets and Caveat interpretation. Correctness, account continuity, startup consistency and a few small controls need further work. The earlier passing suite does not establish that these newly tested edge cases work.

## Findings worth fixing

| Priority | Area | Evidence and consequence | Smallest useful correction |
|---|---|---|---|
| P1 | Water completion | Saving 3000 ml, reducing to 500 ml, then clearing leaves the default water habit complete. Reproduced against the notifier; `lib/providers/daily_log_notifier.dart:198` and `:230` preserve the old true value. | Reconcile completion with the current amount; keep explicit user overrides distinguishable. |
| P1 | Sleep precision | 22:02–06:00 saves as 8.0 hours rather than 7h58m; opening and saving an unchanged precise reading also rounds it up. This can incorrectly satisfy an 8-hour goal. `lib/screens/home/sleep_entry_dialog.dart:35`, `:58`, `:142`. | Preserve the full recorded/calculated duration. Format for display without rewriting the stored value. |
| P1 | Photo account lifecycle | Viewer and comparison cache prior photo lists/selections after an account change. Comparison can retain old-account content for sharing. A pending viewer deletion invokes the current repository instead of rejecting stale screen state. `photo_viewer_screen.dart:45,82`; `photo_compare_screen.dart:109,482,775`. | Retire account-bound screens/selections and pending actions on account change. Existing repository ownership protection remains useful; a dispatched stale deletion is not proof that another account's file was deleted. |
| P1 | Launcher-widget navigation | The actual widget URIs do not match registered Flutter routes: `trufit://home/meals` supplies path `/meals`; `trufit://progress?metric=steps` supplies an empty path. Router probes return route errors. The workout link also uses literal `today` instead of the resolved workout day ID. `TrufitWidgetProvider.kt:115,119,147`; `app_router.dart:140`. | Establish one URI-to-route contract, reset to the actual current day, and resolve the real workout schedule. Verify both cold and warm native taps. |
| P2 | Widget values | A paused step habit still supplies an 8000-step goal. With two recurring profile meal slots and one lunch log, Home's denominator is 2 and the widget's is 5. Both reproduced against the production coordinator. `widget_coordinator.dart:152–181`. | Reuse applicable schedule/goal and meal-denominator logic from the app. |
| P2 | Native unknown readings | Kotlin renders today's null steps as “0” and renders a full progress bar when a reading has no goal. `TrufitWidgetProvider.kt:77–91`. | Distinguish unknown from recorded zero; omit goal progress when no applicable goal exists. Native source finding, not a device render test. |
| P2 | Water layout/identity | The reached-goal amount/badge row overflows at 320px and 200% text. Renaming the default water habit to Hydration hides the goal because the sheet searches the name while persistence uses stable ID. `water_entry_dialog.dart:78,116`. | Wrap/stack the amount and badge; resolve water consistently by identity. |
| P2 | Progress photo details | Gallery weights always show kg even with pounds selected. Saved notes cannot be read in the gallery/viewer/comparison. A comparison opened with one photo displays two empty selectors. All reproduced. `physique_pictures_screen.dart:484`; `photo_compare_screen.dart:623`. | Respect preferred units, show notes in the viewer, and preselect the one available photo with a clear second-photo action. |
| P2 | Reflection entry points | Onboarding's 2:47 target measures 29.4×37px, with a tap action but no button identity or meaningful label. Light-mode contrast is 1.78:1 on Welcome and 2.08:1 on Profile. | Reuse the existing 48px accessible action and light-theme `accentText`. Keep the quiet visual role. |
| P2 | Startup background | Android's API21+ launch drawable references `@color/launch_aubergine`, which has no definition in the project. The base drawable is white, while the app uses warm light and forest dark backgrounds. No Android12-specific splash resources are present. | Resolve the missing resource and make native launch/normal backgrounds coherent with the app palette. Check system light/dark and saved theme choices on Android. This is a resource audit; no APK was built. |
| P3 | Startup copy encoding | Importing the real app entrypoint compiles, but emits invalid UTF-8 warnings from the “Preparing your account” ellipsis in `main.dart`. | Normalize the source text to UTF-8; retain a real-entrypoint smoke test. |

Kotlin/XML paths in the table are under `android/app/src/main/`; Dart widget/screen paths are under `lib/`. Precise probe commands and evidence are in the adjacent build logs.

## What should stay

- The forest/peach dark palette, warm light palette, Cabinet headings and General Sans body text.
- Caveat for the reflection interpretation. Four real-font renders passed: light/dark, 390px normal text and 320×640 at 200% text. Long text scrolls to its end and the modal dismisses.
- Water quick-add controls, explicit Clear, saved-zero semantics and draft-preserving retry behavior.
- Sleep's selected-time layout: its 320px/200% probe passed.
- Progress photo capture recovery, filtered selection deletion, existing comparison modes and accessible slider. Populated comparison and Add Photo with a reference both passed real-font 320px/200% checks.
- Existing meaningful borders on avatars, trophies, focus and selection.

The Telugu verse appears blank in the desktop renderer. The three bundled Latin font families have no Telugu glyphs, so Android fallback needs a real-device check. This does not prove the verse fails on Android. Bundle a suitable Telugu fallback only if target-device verification demonstrates a need.

## Home avatar recommendation

A small avatar is a reasonable personal touch, but a low-priority refinement: Profile is already one tap away in the bottom navigation. It does not justify changing the hero or greeting typography.

Use the existing profile photo/preset avatar with initials fallback, a quiet border, a 40–44px image inside a minimum 48px labeled tap target, and a direct Profile action. Put it at the trailing side of the header without taking away the greeting's readable width; use an adaptive arrangement for long names and enlarged text. Reuse the saved identity rather than introducing another avatar picker or identity setting. Verify missing files and account changes before displaying it.

## Tests worth maintaining with the fixes

1. Water: reach goal → correct below target → clear; explicit overrides; renamed habit; reached-goal layout at 320px/200%.
2. Sleep: exact overnight minutes, unchanged imported readings, threshold near the configured goal, and keyboard/screen-reader access to both time controls.
3. Photos: account switch while viewing/comparing/deleting/sharing; kg/lb display; readable saved notes; zero/one/two photos; capture cancellation/errors and missing images.
4. Widgets: real coordinator parity with Home, inactive/conflicting goals, unknown vs zero, stale-date snapshots, actual generated links, and native RemoteViews rendering/resizing at enlarged text.
5. Startup/reflection: Android resource/build smoke test and cold-start theme matrix; real entrypoint UTF-8/compilation; 48px named reflection controls, light contrast and Telugu rendering.
6. If the avatar is added: photo/preset/initials/missing-file fallback, account refresh, long names and 200% text, and one-tap Profile navigation.

## New probe results

- Water/sleep: six desired-behavior checks; five expose the documented defects, one layout passes. `first-probes.log`.
- Photos: six checks passed; four intentionally observe/reproduce the defects above, two verify large-text layouts. This is not a six-test claim that the photo flows are correct. `second-probes.log`.
- Gita: all five final probes passed after fixing the temporary harness cleanup. The screenshots and measurements still reveal the small entry point/contrast and desktop glyph gaps. `gita-verified.log`.
- Widgets: three desired-behavior checks expose the route, paused-goal and denominator mismatches. `widget-probes.log`.
- Actual entrypoint: one compile smoke check passed with the documented UTF-8 warning. `entrypoint.log`.

The 628-pass maintained suite was not rerun because app code and maintained tests were unchanged. The new probes are deliberately outside that suite so known failures remain review evidence rather than silently weakening test expectations. These cases should become maintained regressions when the fixes are implemented.

Native Android build, launcher rendering, TalkBack, actual sharing and startup transitions remain device/integration validation. No release-readiness claim is made.
