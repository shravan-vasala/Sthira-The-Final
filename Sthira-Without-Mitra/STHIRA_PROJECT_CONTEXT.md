# Sthira — Project Context & Decision Log

Durable context for any AI session working on this repo. Read alongside `sthira_design_system.md`.

**Purpose:** the design system describes *how the app should look*. This file records *decisions already made, mistakes already made, and what is deliberately out of scope* — so no session re-litigates settled questions or rebuilds something that was already rejected.

Last updated: 2026-09-18.

---

## 1. NON-NEGOTIABLES

These are settled. Do not re-open them.

| # | Rule | Why |
|---|---|---|
| 1 | **Colors in `lib/theme/app_colors.dart` are final.** | Palette is settled. Never add, remove or re-tune a hex. |
| 2 | **Fonts: Cabinet Grotesk (headings) + General Sans (body).** Caveat is used for exactly one thing — the Gita verse interpretation, via `context.text.quote`. | Third family exists for that one purpose only. Never borrow it. |
| 3 | **The app is borderless.** | Stated in the design system; `// Sthira: No borders!` comments exist in the code. Any `Border.all` is a defect. |
| 4 | **Expert content is immutable.** Seed meal and workout plan content is authored by a nutritionist and a trainer. JSON *structure* may change; meals, items, quantities, exercises, reps, and guidance text may not. | A content-hash test enforces this (see `seed-01`). If it fails, you changed content. |
| 5 | **AI must never touch the nutritionist plan.** `Meal.suggestions` is clinical guidance and is never sent to a model, summarised, or paraphrased. | Owner's explicit instruction. A test asserts the AI prompt contains no plan content. |
| 6 | **"Suggest Meal" is the AI feature**, driven by remaining macros. It is separate from plan guidance and must be visibly distinguishable to the user. | Two kinds of authority, one screen. |
| 7 | **No gamification.** No confetti, streaks-on-charts, badges-as-motivation, or celebration overlays beyond what already exists. | Brand is "steady, grounded". |
| 8 | **No AI in the daily note.** The user's own words are not summarised, sentiment-analysed, or fed to a model. | Privacy + the coach feature already covers narrative. |
| 9 | **Do not add motion.** The app is already richly animated (42 `flutter_animate` uses, 20 `AnimationController`s, 46 haptic calls). It needs *consistency*, not more. | Owner: "I don't want to push it." |
| 10 | **Platforms are `android/` and `web/` only.** There is no `ios/`. | Drives icon choice — use `Icons.arrow_back_rounded`, never `arrow_back_ios_*`. |

---

## 2. THE TOKEN SYSTEM

Established by prompts 01–02. **Every value in the app must come from these.** If a layout appears to need something else, raise it rather than adding one.

**`lib/theme/app_spacing.dart`**
- `Spacing`: `textPair` 4 · `inline` 8 · `stack` 12 · `block` 16 · `section` 24 · `major` 32 · `screen` 20 · `cardPad` 20 · `cardPadTight` 16 · `sheetPadH` 24
- `Radii`: `sheet` 24 · `card` 20 · `control` 16 · `chip` 12 · `micro` 6
- `IconSize`: `inline` 16 · `row` 20 · `nav` 24 · `hero` 40

**`lib/theme/app_typography.dart` — 11 tokens via `context.text.*`**
`metric` 44 · `display` 32 · `screenTitle` 24 · `cardTitle` 17 · `sectionLabel` 16 · `eyebrow` 11 · `body` 15/w500 · `bodyStrong` 15/w700 · `caption` 13 · `micro` 11 · `quote` Caveat 22

**Motion tokens (`motion-01`) are NOT yet implemented.** If `Motion.*` does not exist, use a literal 250ms + `Curves.easeOutCubic` and note it — do not invent a competing constant.

---

## 3. FAILURE LOG — do not rebuild these this way

### Daily Check-in v1 (deleted, commit `d02f3de`, 831 lines)

Rejected by the owner: *"pathetic… I hate it, in terms of design."* Recover with `git show d02f3de^:lib/screens/home/widgets/daily_checkin_sheet.dart`.

What was wrong, specifically:
- **A Save button** on a single-tap choice — which forced unsaved state, which forced a "Discard changes?" dialog. Three modal surfaces to record a mood.
- **Bordered tiles** (`Border.all(width: 1.5)`) in a borderless app.
- **Card-on-card with no contrast** — `colors.card` tiles inside a `colors.card` sheet, so they were invisible except for their borders. The owner described this as "the background was transparent."
- **Tiles 60×76dp** with a check badge at `Positioned(right: -2, bottom: -2)` — overflowing its own parent. The owner described this as "bulged."
- **Two bespoke `CustomPainter` illustrations** (botanical, clover) and, before that, emoji faces. Both were attempts to *draw a mood*. The app illustrates nothing anywhere; any picture looks foreign.

**The lesson:** v1 asked the user to fill in a form about their feelings. The replacement should be one tap.

**The backend already exists and survived:** `DailyLog.dayFeeling`, `DailyLog.dayNote`, `clearCheckIn()`, `checkInUpdatedAt`, `dailyLogRepository.updateCheckIn/removeCheckIn`. Any rebuild is UI-only.

### Over-uniform shared-widget rules (prompt 03)

Three later defects traced to "make it uniform" instructions with no escape hatch:
- `SurfaceCard.margin` defaulting to `Spacing.screen` → **double insets** anywhere the container already padded (40dp on screens, **44dp inside `AppSheet`**).
- `SectionHeader` clamping `trailing` with a fixed `SizedBox(height: 24)` → **cropped** a legitimately taller badge. A max-height constrains; a fixed height crops.
- `left: 4` on section labels surviving in multiple files after being flagged in one.

**The lesson:** when enforcing uniformity, prefer a *maximum* over a *fixed* value, and state which layer owns a given axis.

### Flutter traps already hit here

- **`Container` + `alignment` + bounded parent expands to full width.** Caused three action buttons to each take a full row in `exercise_card.dart`. Only a bug when the Container has no explicit size *and* shrink-wrap was intended.
- **`ElevatedButton.icon` does not wrap its label in `Flexible`** — oversized labels hard-clip with no ellipsis ("Tak", not "Take…").
- **`_seedIfEmpty()` guards on name existence**, so shipping a corrected seed asset reaches **zero** existing users. Both `meal_repository` and `workout_repository` had this.

---

## 4. VERIFIED EXTERNAL FACTS

Checked against `ai.google.dev` in **September 2026**. Re-verify if significant time has passed — this area moves.

- Model IDs in `lib/services/ai_client.dart` (`gemini-3.7-flash`, `gemini-3.6-flash`, `gemini-3.8-flash`, `gemini-3.5-flash-lite`, `gemini-3.1-flash-lite`) are **all real, current and stable**. Not a bug.
- **Gemini 3 models think by default.** `gemini-3.8-flash` defaults to `thinking_level: "medium"`; `gemini-3.5-flash-lite` to `"minimal"`.
- The parameter is **`thinking_level`** (a `generation_config` field) — *not* `thinkingConfig`/`thinkingBudget`.
- **Flash-lite models support vision** and are the fastest tier.
- Implicit caching is on by default for 2.5+; minimum **4,096 tokens** on Gemini 3 flash. Put large static content at the *start* of the prompt.
- `gemini-2.0-flash` / `gemini-2.0-flash-lite` are **shut down** — never add them as fallbacks.

---

## 5. VERIFICATION COMMANDS

Run these to establish current state rather than assuming. Baselines are pre-refactor (commit `1b88ec6`).

```bash
# Typography migration
grep -rhoE "fontSize: [0-9]+" lib --include=*.dart | sort -u | wc -l     # was 22 distinct → target 0 outside app_typography.dart
grep -rho "TextStyle(" lib --include=*.dart | wc -l                       # was 698 → target <60
grep -rho "context\.text\." lib --include=*.dart | wc -l                  # was 1

# Radii + icon sizes (KNOWN INCOMPLETE as of 2026-09-18)
grep -rhoE "BorderRadius\.circular\([0-9]+\)" lib --include=*.dart | sort -u | wc -l   # was 17 distinct; 131 raw calls remained
grep -rhoE "size: [0-9]+" lib --include=*.dart | sort -u | wc -l                       # was 15 distinct; 137 raw values remained

# Defect classes already seen — sweep for new instances
grep -rn "alignment: Alignment" lib --include=*.dart | grep -v "textAlign\|WrapAlignment\|MainAxisAlignment\|CrossAxisAlignment"
grep -rn "Border.all" lib --include=*.dart          # should be zero
grep -rn "withOpacity" lib --include=*.dart         # deprecated; should be zero
grep -rn "Colors\." lib --include=*.dart | grep -v "app_colors.dart"
grep -rn "MediaQuery.disableAnimations" lib --include=*.dart   # reduce-motion support
```

---

## 6. PROMPT STATUS

All prompts live in `antigravity_prompts/`.

**Implemented:** `01`–`17` (spacing/typography/components), `02b` (quote token), `06b` (icons), `seed-01` (plan provenance + migration), `meal-01` (AI/nutritionist boundary), `polish-01` (post-refactor screenshot pass).

**Written, not implemented:** `polish-02` (clipped button labels, snackbar over nav) · `chart-01`/`chart-02` (chart integrity, then insight) · `motion-01` (motion tokens) · `feature-01` (day feeling + note) · `feature-02` (workout plan weeks) · `fix-01` (home widget won't load) · `ai-01`–`ai-07` (meal-scan latency).

**Dependency notes:**
- `chart-02` requires `chart-01` — you cannot make a chart insightful while its own numbers contradict each other.
- `feature-02` requires `seed-01`'s migration mechanism.
- `ai-05`/`ai-06` require `ai-01`'s measurement harness. Do not tune the model without it.
- `polish-01` was edited *after* being implemented (A10/A11 were appended). Those two items are now in `polish-02` instead — **do not treat polish-01 as an accurate record of what shipped.**

---

## 7. KNOWN OUTSTANDING ISSUES

Not yet covered by any prompt, or covered but unverified:

- **Radii and icon-size migration is incomplete.** `Radii.*` and `IconSize.*` exist and are half-adopted. ~131 raw `BorderRadius.circular()` and ~137 raw icon `size:` values remained as of 2026-09-18, including values (`30`, `36`, `22`, `28`, `64`) not in the token set at all.
- **Reduce-motion is not respected** anywhere. `MediaQuery.disableAnimations` is unchecked. Accessibility gap.
- **The Android home widget shows "couldn't load."** Top suspect: `widget_info.xml` declares `widgetFeatures="reconfigurable|configuration_optional"` with **no `android:configure` activity**, which is invalid and fails on debug *and* release. Second: no ProGuard keep rules for `es.antonborri.home_widget` (release only). See `fix-01`.
- **Two dead widget layouts** (`widget_layout_small.xml`, `widget_layout_large.xml`) contain the only off-brand values in the widget — raw hex, `#2D1A25` as text on near-black, and faux-bold. Delete, do not repair.
- **`previousMeals` is never passed** to `suggestMealStream`, so the AI believes every meal is the first of the day. The parameter, prompt text, and cache-key hash all exist and are inert.
- **`phase_progress_provider` hardcodes `totalWeeks = 8`** and `requiredDaysPerWeek = 4`. Neither is read from the plan. `currentWeek` is unbounded — "Week 9 of 8" is reachable.
- **Four stabilisation commits** followed the refactor ("missing context.colors", "syntax errors and theme definitions", two test-harness fixes). Worth confirming those repairs did not reintroduce hardcoded values.

---

## 8. HOW TO ANALYSE THIS APP

The owner's goals are **premium UI, good UX, a bug-free backend, and fast reliable AI**. Those are four different investigations with four different methods. **A single "analyse everything" pass produces shallow results on all four.** Run them separately.

| Pass | Method | Cannot be done by reading code |
|---|---|---|
| **UI polish** | Screenshot every screen in every state (empty / loading / error / full), light + dark, 1× and 1.5× text scale, on a 360dp device. Compare against the token sets in §2. | Correct — needs real screenshots. Most defects in `polish-01` were invisible in source. |
| **UX** | Walk each task end to end: log a meal, complete a workout, scan a photo, add a friend. Note every state with no feedback, every layout that shifts mid-interaction, every tap target under 44dp. | Correct — needs a device. |
| **Backend correctness** | Run the test suite. Then adversarially test migrations: fresh install, legacy record, user-edited record, offline→sync, two devices, DST boundary. | Correct — needs execution, not inspection. |
| **AI speed/reliability** | `ai-01` first: golden set of real Telugu/South-Indian meal photos with weighed ground truth, phase timers, and a written pass/fail gate. Then measure before changing anything. | **Absolutely** — a latency claim without a baseline is invented, and an accuracy claim without ground truth is unfalsifiable. |

**The rule that matters most:** never claim a speed win without a before/after measurement, and never claim accuracy was preserved without a labelled set. The owner's constraint is *"don't compromise accuracy"* — that is unverifiable by inspection.
