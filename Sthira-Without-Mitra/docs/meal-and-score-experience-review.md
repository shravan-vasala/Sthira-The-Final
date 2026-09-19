# Meal, score and scanner experience review

> Follow-up: See [remaining analysis implementation](pending-analysis-fixes.md) for subsequent fixes and final verification. Findings and test counts below describe their original review checkpoint.

## Verdict

A broad redesign is not justified. The existing hero metrics, forest/peach colors, Cabinet Grotesk/General Sans pairing and rounded surfaces already give these screens a coherent identity. The useful work is correcting meaning, making actions predictable and accommodating real text sizes. No new design tokens, font families or decorative effects were introduced.

## Meal tile and meal page

- Preserve the hero and calorie/macronutrient hierarchy. Values, macros, food provenance and actions now wrap or stack when needed, including 320px screens at 200% system text.
- Say calories logged rather than implying a complete day's intake. Missing historical logs are not classified as below-target eating; calorie overshoots are not celebrated as success.
- Replace the inert "Tap to log" hint with a truthful empty state. Fix the nested Flexible error in Add another meal.
- Historical Repeat is explicitly Repeat today: it writes to today's next empty slot, preserves the historical meal and barcode metadata, prevents duplicate taps and reports the destination. Historical/targetless views do not offer irrelevant meal suggestions.

## Daily and weekly scores

- Daily scores are normalized to 100. The sheet and calendar badge no longer divide that normalized score by the raw category maximum again.
- Keep the 50/30/20 category weights. Actual planned rest retains its credit; having no workout plan no longer earns an invented rest-day bonus. Completed training is labeled as training.
- Calculate each day's scheduled habits from the full habit list, independent of which weekday the user is viewing.
- Weekly requirements stop at today. Sessions count training days, not rest days or individual workout sections. Explicit zero steps/sleep remain recorded values.
- Show coverage and week-in-progress context. Missing prior records do not manufacture a comparison; unfinished weeks do not compete with a full completed week. The selected plan/settings remain the basis because the app does not store historical plan snapshots.
- Weekly chart inspection stays in the summary, with an explicit View day action and a fixed 0-100 axis so scores remain visually comparable. Perfect-week recognition requires seven fully scored days.

These scores summarize the app's logging and configured plan rules. They are not clinical health ratings or independently measured nutrition accuracy.

## Meal scanning: speed and accuracy

Earlier code already prepared photos, hashes and request encoding off the UI thread, reused prepared bytes and HTTP connections, overlapped nutrition loading, and supported real cancellation and bounded requests. Repeating those changes or switching models without evidence would not add value.

This review adds:

- Optional cache reads/writes cannot fail or hold up a usable scan. Per-request cache storage stays with the originating account.
- Food response validation runs before caching. Invalid old entries are cache misses; semantically invalid new results are not saved.
- Text scans reuse the raw AI cache and re-resolve nutrition using current local/personal data, instead of trusting old processed totals indefinitely.
- Explicit gram quantities can use the local table without an AI request. Counted pieces and volumes do not assume a serving's mass or treat ml as grams.
- Reconnecting updates scanner controls without closing the sheet or losing input. Text analysis dismisses the keyboard so progress is visible.
- Review text describes an estimate rather than presenting model confidence as calibrated calorie accuracy. Incomplete results show Known total and Save partial log.
- Portion corrections survive subsequent scaling and remain meaningful in the saved label. Manual nutrition rejects invalid/non-finite input rather than quietly replacing it with zero.
- Older aggregate-only meals keep their earlier nutrition when adding foods. Personal shortcuts retain their source and initialize every carried-forward portion correctly.
- Save captures items and totals together, validates the original date/account, and persists the meal before optional portion memory. Editing/undo cannot alter an in-flight save, and a late Undo after closing is safe.

## Validation and limits

The complete automated suite passed: **379 tests, with one existing skipped placeholder**, using `flutter test --no-pub --concurrency=1 --reporter expanded`. Actual-font render checks also passed for the meal, scanner and score screens. The current scanner/provider wiring has no analyzer errors or new warnings; five existing calendar-file warnings remain. `git diff --check` passed.

Service tests verify zero AI calls for explicit gram inputs, one request across repeated descriptions with refreshed nutrition, nonblocking optional writes, invalid-response rejection, account binding, cancellation, image preparation and real loopback HTTP behavior. UI tests and actual-font renders cover light/dark themes, 320px at 200% text, partial results, manual correction and meal/score navigation.

No live Gemini benchmark or weighed-meal accuracy study was run. The configured models, prompts and image resolution are unchanged. No Android APK/device-camera validation was possible without an Android SDK in this environment. Device timing, real camera use and accuracy against weighed representative meals are still needed before making numeric speed or accuracy claims. Historical unsupported benchmark figures were removed from AI-06_MODEL_SWEEP.md.

All work remains local and uncommitted. Review images are under ignored build/meal-review, build/scanner-review and build/scores-review. Exclude build/ and .dart_tool/ from a source ZIP; keep source, assets, tests, documentation and dependency manifests.
