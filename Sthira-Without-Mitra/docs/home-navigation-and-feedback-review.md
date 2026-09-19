# Home date, navigation and feedback review

19 September 2026. Continues the [social checkpoint](social-connection-and-friend-details-review.md).

## Decisions

Keep the Home date. It identifies the day being viewed and logged, especially because browsing the weekly strip does not itself select a different day. Keep one quiet date below the greeting, the profile/avatar entry and the established hero cards. The added date semantics identify today, a past day or a future day, including the year.

Keep the four destinations and floating pill. Visible Home, Progress, Social and Profile labels remove guesswork. Equal-sized destinations prevent the active selection moving its neighbours. Keyboard focus, selected-state semantics, theme contrast and at least 48px targets improve usability. On narrow screens with enlarged text, destinations form two rows without shrinking the user's fonts.

Use the existing General Sans, Cabinet Grotesk, warm palette and theme tokens. The older DESIGN.md describes a historical three-tab/purple/Inter baseline; current code and the user's preference for the current design take precedence.

## Implemented refinements

- Navigation and the active rest timer occupy one measured Scaffold footer. Screen content uses the measured bottom inset, including system gestures. Typing temporarily hides the dock so the editor has room; the timer continues in its provider.
- Floating snackbars use a modest bottom margin instead of a second fixed navigation clearance. Shared text/action/dismiss colors are readable in both themes, with a softer shadow. Undo and Retry remain actionable.
- Manage Plans confirms customization through its selected plan and inline identity, without a redundant toast over Save and use. Editors and Manage Habits reserve room for the measured dock and their own actions. Nested Add Habit and Add photo buttons also clear the dock, while the final habit/photo remains above its floating button; keyboard spacing is applied once.
- Global reminder, social and account errors belong to the current account. Messages from the previous account are cleared, delayed stale reports are ignored, and Retry cannot run for another account. Duplicate reports in a single frame coalesce, while existing Undo/Retry messages keep their place. Blocking account preparation retains its own inline Retry.
- The rest timer has a short state label, full exercise context for tooltips/screen readers, readable controls and a countdown that does not announce every second. Completion feedback follows the shared message style. Countdown vibrations respect the existing preference.
- The scanner's offline band remains quiet and explains that saved meals can still be logged. Its text is readable and its connectivity status is announced.
- Duplicate automatic streak messages are removed. Day completion becomes a compact summary the user chooses to open, only when there are planned core activities to complete. Existing trophy criteria and stored achievements remain; historical backfill and cloud updates do not replay celebration banners.
- Trophy feedback keeps the gold/medal treatment, with explicit Dismiss and View trophies actions. The banner respects reduced motion, account boundaries, foreground state and accessibility/focus needs.

## Verification

- Final full maintained Flutter suite: **912 passed, one existing skip, zero failures**, across **132 test files**. This adds 43 passing cases since the 869-case social checkpoint. Log: `build/home-feedback-final-suite.log`.
- Final Dart analyzer: **zero errors, 54 warnings, 463 infos**. Existing diagnostics remain; this is not a clean-lint claim. Log: `build/home-feedback-final-analysis.log`.
- Eight temporary real-font render cases passed across light/dark, normal 390px and narrow 320px/200% text layouts. Navigation, timer/Undo message, trophy banner and completion sheet produced 12 PNGs in `build/navigation-audit/`. Representative renders were visually inspected; the enlarged navigation labels and completion heading were refined and rerendered.
- Regressions cover actual Progress/Manage Habits/Photo screens with the measured dock, final-item and floating-action reachability, keyboard spacing, immediate plan editing, account-safe error queues/Retry, successful local trophy provenance versus history/cloud backfill, badge lifecycle/accessibility, optional day completion, and rest-timer preferences.
- `git diff --check` passed. All **367 Dart files** under `lib/` and `test/` decode as UTF-8 with no replacement characters.
- Maintained tests remain under `test/`. Temporary render probes are not included in the 912-case total. The single skip remains the existing native widget-channel placeholder.

Focused/render evidence: `build/home-navigation-bars-final.log`, `build/celebration-final-verified.log`, `build/plan-feedback-final.log`, `build/floating-actions-focused.log`, `build/photo-footer-final.log`. Earlier failed runs isolated the redundant Customize toast and nested floating-action overlap; both were corrected before the final passing suite. Firestore and Android files did not change in this pass, so their separate checks were not rerun.

## Limits

These are local code, widget, accessibility-semantics and rendered-layout checks. A physical Android pass is still needed for gesture/three-button navigation, keyboard behaviour, TalkBack, native sound/vibration and background/resume behaviour. Earlier social/backend release checks still apply. No commit, push or deployment was made in this pass.
