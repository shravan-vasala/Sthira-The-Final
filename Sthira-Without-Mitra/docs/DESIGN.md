# Design Document

> Historical design baseline. The current app uses four tabs, the warm palette, General Sans and Cabinet Grotesk. Preserve the current code and hero-card design; see [the current navigation and feedback review](home-navigation-and-feedback-review.md) for the latest refinements.

**Product:** TruFit Bodamma  
**Companion to:** [`docs/PRD.md`](PRD.md)  
**Version:** 1.0  
**Last updated:** 2026-08-02  

---

## 1. Do we have to change the design?

**No — a full redesign is not required for v1.**

The current IA and screen structure already match the product: a personal daily coach with **Home / Progress / Profile**. Recent work fixed real usability issues (dark-theme contrast, sheet layering, meal copy, water habit UX). Those were **polish and bugfixes**, not a new visual system.

| Decision | Recommendation |
|----------|----------------|
| Tear down UI and rebuild | **No** |
| Keep 3-tab structure | **Yes** |
| Keep purple Material card language | **Yes for now** (established system) |
| Keep fixing contrast / density / copy | **Yes — ongoing** |
| Optional later visual refresh (less “generic purple fitness”) | **Optional**, only if you want stronger brand personality |

**When you *would* redesign:** if Bodamma finds Home overwhelming, if you want a distinct sister-branded look for a wider release, or if you intentionally leave the purple/indigo system. Until then, **evolve in place**.

---

## 2. Design goals

1. **Daily clarity** — Within one glance: what day, what’s the score, what still needs logging.
2. **Fast logging** — Weight, sleep, steps, habits, meals, sets should take seconds.
3. **Encouraging, not stressful** — Rest days feel complete; finish-early is allowed.
4. **Readable in dark mode** — Primary preferred theme for the trainee; no white-on-white text/fields.
5. **Private & calm** — No social chrome, ads, or marketplace noise.
6. **Consistent system** — One color/token layer (`AppColors` + `AppTheme`), shared section headers and cards.

---

## 3. Users & design implications

| Persona | Design implication |
|---------|-------------------|
| Bodamma | Large tap targets, clear labels, dark-friendly, Hindi/English-friendly plain copy, minimal settings during the day |
| Coach (you) | Profile/plan management can be denser; backup/restore must feel safe and explicit |

---

## 4. Information architecture

```
Onboarding (first run only)
 └── Welcome → Profile → Goals → Health Connect (opt) → Gemini (opt)

Main shell (bottom nav)
 ├── Home          → day strip, score, metrics, habits, meals, workout, coach notes
 ├── Progress      → metric charts, ranges, weekly summary, phase
 └── Profile       → edit profile, plans, habits, reminders, theme, backup, integrations

Overlays / routes
 ├── Workout day → sections → log sets → YouTube → rest timer → Finish
 ├── Meal detail / photo scan
 ├── Body stats / physique photos / compare
 └── Sheets: score breakdown, sync status, past-day summary, entry dialogs
```

**One job per surface**

| Surface | Job |
|---------|-----|
| Home | Complete *today* (or inspect a past day) |
| Progress | Understand *trends* |
| Profile | Change *setup* |
| Workout | Execute and log *this session* |

---

## 5. Current visual system (as implemented)

### 5.1 Brand / color

Defined in `lib/theme/app_colors.dart`.

| Token | Light | Dark | Role |
|-------|-------|------|------|
| Primary | `#7C3AED` | `#7C3AED` | Actions, selected nav, accents |
| Indigo / gradient end | `#4F46E5` | `#4F46E5` | Primary gradients |
| Scaffold | `#F8F7FC` | `#0F0F14` | App background |
| Surface / card | `#FFFFFF` | `#1A1A24` | Cards, sheets |
| Text strong | `#1F2937` | `#F3F4F6` | Titles, primary copy |
| Text medium | `#6B7280` | `#9CA3AF` | Secondary |
| Success | `#22C55E` | `#22C55E` | Complete / positive |
| Warning / energy | `#F97316` | `#F97316` | Highlights |
| Danger | `#EF4444` | `#EF4444` | Errors / destructive |
| Soft tint cards | pink / mint / lavender | darkened equivalents | Habit / metric chips |

**Character today:** Material 3 + purple→indigo fitness aesthetic. Functional and familiar; not strongly “Bodamma-branded.” That is acceptable for a private family app.

### 5.2 Typography

- Family: **Inter** via Google Fonts (`AppTheme`)
- Hierarchy: headline 28/22/18 → title 16/14/12 → body 16/14/12 → labels
- Section labels on Home use uppercase + letter-spacing (e.g. MEALS / HABITS) for scanability

### 5.3 Shape & elevation

- Cards: ~20px radius, elevation 0, soft primary-tinted shadow in theme
- Inputs / dialogs: rounded, outlined; dark theme must set fill + label colors explicitly
- Bottom nav: 3 destinations — Home, Progress, Profile

### 5.4 Motion

- Page transitions via `go_router` / Material defaults
- Rest timer feedback (sound / vibration toggles in profile)
- Prefer short, purposeful transitions; avoid decorative noise

### 5.5 Iconography & imagery

- Material Icons + emoji where habits/meal slots historically used emoji
- Physique photos: full-bleed in viewer/compare, not decorative stock
- YouTube thumbnails for exercise form

---

## 6. Screen design specs

### 6.1 Onboarding

- 5 steps, linear pager
- One decision per step; skip allowed for HC / Gemini
- End state: seeded Phase 1 workout + Balanced Non-Veg meals + starter habits

### 6.2 Home (daily cockpit)

**Top → bottom (current composition)**

1. Greeting / day context + week calendar strip  
2. Daily score affordance  
3. Metrics grid (weight, steps, sleep, …)  
4. Habits section  
5. Meals section (“Today’s Meals” + plan subtitle)  
6. Workout CTA / status  
7. Coach notes (secondary)

**Rules**

- Selecting a past day shows summary / limited edit patterns; future days don’t inflate score  
- Sheets that must clear the bottom nav use **root navigator**  
- Section headers share the same alignment pattern for MEALS / HABITS

### 6.3 Workout

- Day → expandable sections → exercise cards  
- Log dialog for sets/reps/weight  
- Rest timer visible between sets  
- Finish (full or early) clearly ends the day flag  
- Rest day: calm empty/complete state, not an error

### 6.4 Progress

- Metric switcher (weight, steps, sleep, BMI, …)  
- Range switcher (week / month / 6 months)  
- Chart card + summary numbers  
- Path to weekly summary / phase progress

### 6.5 Profile

- Identity (name, photo, height, targets)  
- Plan management  
- Habits management  
- Reminders, theme, Health Connect, Gemini key  
- Backup / restore — destructive actions need confirm copy

---

## 7. Component inventory

| Component | Purpose | Notes |
|-----------|---------|-------|
| Week calendar strip | Day selection | Home only |
| Daily progress grid | Weight / steps / sleep tiles | Sync CTA only when HC never connected / no data |
| Habits card | Daily habit completion | Water = checkbox + editable goal |
| Meals card | Slot logging entry | Title + plan name, not raw plan id |
| Coach notes card | Optional AI encouragement | Degrade gracefully offline |
| Score sheet | Breakdown Habits/Workouts/Meals/Steps | Matches PRD formula |
| Sync status sheet | HC explanation | Root navigator |
| Entry dialogs | Weight / sleep / steps | Explicit dark colors |
| Exercise card + log dialog | Session logging | SoT = ExerciseLog |
| Chart card | Progress trends | Shared Progress widget |
| Offline banner | Network-dependent features | Don’t block local logging |

---

## 8. Interaction principles

1. **Tap to complete** preferred over multi-step for habits (especially water).  
2. **Manual always wins** — user can override HC steps/sleep.  
3. **Optimistic local write** — Hive update → UI invalidates; no spinner for simple checks.  
4. **Explain sources** — steps/sleep show Health Connect vs manual where relevant.  
5. **Safe overlays** — dialogs/sheets never trap under bottom nav or lose focus contrast.

---

## 9. Accessibility & quality bar

| Bar | Requirement |
|-----|-------------|
| Contrast | Body text and field labels readable on card/scaffold in dark and light |
| Touch | Primary actions ≥ ~48dp effective target |
| Feedback | Completing a habit / meal / set gives immediate visual state change |
| Errors | Soft cards / snackbars; never silent failure on backup restore |
| Empty | Rest day and “no logs yet” are calm, instructive states |

---

## 10. What to improve (without redesign)

Priority order for design/engineering polish:

| Priority | Item | Why |
|----------|------|-----|
| P0 | Keep dark-theme contrast regressions fixed | Blocks daily use |
| P0 | Preserve SoT + scoring UX (rest / finish-early feel fair) | Trust |
| P1 | Reduce Home vertical noise (coach notes / secondary below fold) | Faster daily path |
| P1 | Consistent dialog styling (all entry sheets share one pattern) | Quality |
| P2 | Tone down emoji reliance in favor of icons where it feels childish | Polish |
| P2 | Optional brand refresh: warmer accent, non-Inter display font, less purple-default | Only if desired |

**Out of scope for “must change”:** new nav model, glassmorphism, dashboard-of-widgets redesign, marketing landing inside the app.

---

## 11. Optional future visual direction (not committed)

If you later want a stronger personal brand (still local-first product):

- Keep structure; change **tokens only** first (primary, scaffold, fonts)  
- Prefer a calm fitness direction (deep teal / warm charcoal) over another purple SaaS look  
- Brand moment: greeting with **her name** as the hero signal on Home, not a marketing headline  
- Avoid redesigning Progress charts until tokens settle  

Do **not** start this until P0/P1 polish is stable and Bodamma has used the app for a full training week.

---

## 12. Design ↔ engineering map

| Design concern | Code home |
|----------------|-----------|
| Colors / gradients | `lib/theme/app_colors.dart` |
| Theme (M3, Inter, components) | `lib/theme/app_theme.dart` |
| Home composition | `lib/screens/home/home_screen.dart` + `widgets/` |
| Progress | `lib/screens/progress/` |
| Profile / habits | `lib/screens/profile/` |
| Workout | `lib/screens/workout/` |
| Scoring UX copy/breakdown | `daily_score_provider.dart` + score sheet |
| Completion semantics | `lib/utils/workout_completion.dart` |

---

## 13. Acceptance checklist (design)

- [ ] Dark mode: profile edit, manage habits, weight/sleep/steps, dropdowns all legible  
- [ ] Home: MEALS and HABITS headers align; meal title reads as “Today’s Meals”  
- [ ] Water habit completes in one tap; goal editable in Manage Habits  
- [ ] Sheets open above bottom nav when required  
- [ ] Rest day and finish-early feel intentional, not broken  
- [ ] No requirement to re-learn navigation after APK update  

---

## 14. Summary

**Ship and polish the existing design.** It already expresses the PRD. Redesign is optional later for brand personality — not a blocker for Bodamma using the app daily.
