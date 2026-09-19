# Product Requirements Document

**Product:** TruFit Bodamma  
**Version:** 1.0.0  
**Platform:** Android (Flutter)  
**Status:** Private personal release  
**Owner:** Shravan Kumar Vasala  
**Primary user:** Bodamma (sister)  
**Last updated:** 2026-08-02  

---

## 1. Overview

### 1.1 Product summary

TruFit Bodamma is a **local-first personal fitness coach app**. It helps one person follow a structured workout phase, stick to a calorie-aware meal plan, track daily habits and body metrics, and see progress over time — keeping core data on-device with optional, secure cloud syncing.

### 1.2 Problem

Generic fitness apps are noisy, privacy-invasive, and not tailored to a single coached plan. Bodamma needs a simple daily companion that:

- Shows **today’s workout and meals** clearly
- Makes logging **fast and encouraging**
- Keeps **core data private and local** by default
- Offers optional **Google Sign-In for Firestore text-data sync** (no photos)
- Lets her brother (coach) ship updates via APK / backup restore without building a backend

### 1.3 Goals

| Goal | Success signal |
|------|----------------|
| Daily adherence | User opens app and logs meals / habits / workout most training days |
| Clarity | Today’s plan is obvious within one glance on Home |
| Privacy | Local-first; optional Google sync (no photos); data exportable by user |
| Continuity | Encrypted backup/restore survives phone change |
| Motivation | Daily score + weekly summary + physique photos reinforce consistency |

### 1.4 Non-goals (v1)

- Social feed or public coaching platform
- iOS / web production release
- Public Play Store listing or monetization
- Real-time wearable write-back beyond Health Connect read
- Full nutrition database / barcode shopping features

---

## 2. Users & personas

### 2.1 Primary — Bodamma (athlete / trainee)

- Follows a coached **Phase 1 (8 weeks)** workout and **Balanced Non-Veg** meal plan (~1397 kcal)
- Wants low-friction daily check-ins (meals, water, sleep, steps, workout)
- May use Health Connect / phone step sensors
- Prefers dark, clear UI; not a power-user of fitness SaaS

### 2.2 Secondary — Coach (Shravan)

- Seeds and updates workout/meal plans
- Builds and sideloads APKs
- Reviews progress via shared screenshots / exported backups when needed
- Does **not** need remote admin access in v1

---

## 3. Product principles

1. **Local-first by default** — Hive on device is the primary system of record.
2. **Privacy by design** — Outbound network only for optional Firestore sync (text data only), Gemini (optional AI meals/coach), and YouTube (form videos). Health Connect is on-device.
3. **One day, one job** — Home is the daily cockpit; Progress is history; Profile is setup.
4. **Clear source of truth** — Avoid dual flags that disagree (see §6.2).
5. **Encourage, don’t punish** — Rest days count as complete for scoring; finish-early is allowed.

---

## 4. Scope & platform

| Item | Requirement |
|------|-------------|
| OS | Android (minSdk 26+) |
| Distribution | Sideload APK (profile/release via local scripts) |
| Offline | Core logging works offline; AI / YouTube need network |
| Auth | Optional Google Sign-In for Firestore sync |
| Storage | Hive (local primary) + optional Firestore sync + local files (photos, backups) |
| Optional integrations | Android Health Connect, Gemini API key (user-provided) |

---

## 5. Information architecture

### 5.1 Navigation

| Tab / area | Purpose |
|------------|---------|
| **Home** | Today (or selected day): score, metrics, habits, meals, workout entry, coach notes |
| **Progress** | Charts, weekly summary, phase progress, PRs / trends |
| **Profile** | Edit profile, manage plans, habits, reminders, theme, backup/restore, Health Connect / AI settings |

### 5.2 Key flows

1. Onboarding → profile + goals + optional Health Connect + optional Gemini key  
2. Daily: open Home → log weight/sleep/steps → check habits → log meals → do workout → Finish  
3. Progress review: weekly summary / charts / physique compare  
4. Phone change: export encrypted ZIP → restore on new device  

---

## 6. Functional requirements

### 6.1 Onboarding

| ID | Requirement | Priority |
|----|-------------|----------|
| OB-1 | First launch shows multi-step onboarding until completed | P0 |
| OB-2 | Capture name, height, starting weight, unit preference (kg/lb) | P0 |
| OB-3 | Set calorie target (default ~1397) and starter habits (e.g. sleep, walk, water) | P0 |
| OB-4 | Optional Health Connect permission / connection | P1 |
| OB-5 | Optional Gemini API key save (secure storage) | P1 |
| OB-6 | Seed default workout plan (Phase 1) and meal plan (Balanced Non-Veg) | P0 |

### 6.2 Daily Home

| ID | Requirement | Priority |
|----|-------------|----------|
| HM-1 | Week calendar strip to select past/today (not future logging for score) | P0 |
| HM-2 | Show daily score (0–100) with breakdown sheet | P0 |
| HM-3 | Log weight, sleep, steps (manual dialogs) | P0 |
| HM-4 | Auto-refresh today’s steps from Health Connect when available; persist connection state | P0 |
| HM-5 | Habits card: complete habits; water as one-tap checkbox with editable litre goal | P0 |
| HM-6 | Meals card titled for the day (e.g. “Today’s Meals”) with plan subtitle; open meal detail / log slots | P0 |
| HM-7 | Open today’s workout day from Home | P0 |
| HM-8 | Coach notes card (AI-assisted when configured) | P2 |
| HM-9 | Past-day summary sheet for historical days | P1 |
| HM-10 | Sync status / Health Connect sheet | P1 |

### 6.3 Workouts

| ID | Requirement | Priority |
|----|-------------|----------|
| WO-1 | Workout plan has days → sections → exercises (reps, rest, notes, optional YouTube URL) | P0 |
| WO-2 | Log sets/reps/weight per exercise (`ExerciseLog` is section/exercise completion SoT) | P0 |
| WO-3 | Section complete when every exercise in section has a log for that date | P0 |
| WO-4 | Day Finish flag (`DailyLog.workoutCompleted`) on Finish (full or early); auto-set when all sections logged | P0 |
| WO-5 | Planned rest (e.g. Sunday / empty sections) counts complete for scoring | P0 |
| WO-6 | In-workout rest timer with optional sound/vibration | P1 |
| WO-7 | Play YouTube form videos in-app | P1 |
| WO-8 | Exercise progress / PR tracking for logged lifts | P1 |
| WO-9 | Manage / switch workout plans from Profile | P1 |

### 6.4 Meals & nutrition

| ID | Requirement | Priority |
|----|-------------|----------|
| ML-1 | Active meal plan with breakfast / lunch / snack / dinner (customizable slots) | P0 |
| ML-2 | Log planned meal slots as eaten for the day | P0 |
| ML-3 | Show plan calories / items in meal detail | P0 |
| ML-4 | Optional photo calorie scan via Gemini when API key present | P2 |
| ML-5 | Track toward daily calorie + macro targets on profile | P1 |
| ML-6 | Manage meal plans from Profile | P1 |

### 6.5 Habits

| ID | Requirement | Priority |
|----|-------------|----------|
| HB-1 | Support habit types: checkbox, counter, auto-steps, auto-sleep | P0 |
| HB-2 | Water: checkbox completion with user-editable daily goal (litres) | P0 |
| HB-3 | Manage Habits screen: add / edit / reorder / delete with readable contrast | P0 |
| HB-4 | Steps/walk habits can drive daily score step component | P0 |

### 6.6 Body & physique

| ID | Requirement | Priority |
|----|-------------|----------|
| BD-1 | Body stats: weight, body fat, BMI from profile height | P0 |
| BD-2 | Progress photos with viewer | P1 |
| BD-3 | Side-by-side physique compare | P1 |

### 6.7 Progress & scoring

| ID | Requirement | Priority |
|----|-------------|----------|
| SC-1 | Daily score weights: Habits 40 / Workouts 30 / Meals 20 / Steps 10 (steps only if steps habit exists) | P0 |
| SC-2 | Future dates score 0 | P0 |
| SC-3 | Weekly summary screen | P1 |
| SC-4 | Phase progress based on plan start + completion rules | P1 |
| SC-5 | Charts for weight / steps / sleep / adherence trends | P1 |

### 6.8 Profile, reminders, backup

| ID | Requirement | Priority |
|----|-------------|----------|
| PF-1 | Edit profile (name, photo, height, targets, units) with usable dark-theme inputs | P0 |
| PF-2 | Theme light/dark | P1 |
| PF-3 | Local notification reminders (configurable) | P1 |
| PF-4 | Encrypted ZIP backup including Hive data + photos; restore | P0 |
| PF-5 | CSV export option for analysis | P2 |
| PF-6 | Offline banner when connectivity lost for network features | P2 |

### 6.9 Integrations

| ID | Requirement | Priority |
|----|-------------|----------|
| IN-1 | Health Connect: read steps (and sleep where supported); manual override allowed; source stamped on `DailyLog` | P0 |
| IN-2 | Gemini: meal scan + coach notes; API key in secure storage | P1 |
| IN-3 | YouTube: exercise demos only | P1 |

---

## 7. Data & privacy requirements

### 7.1 Storage

- All primary data in local Hive boxes (profile, daily logs, exercise logs, meals, habits, photos metadata, plans, etc.).
- Schema migrations must run safely on upgrade.
- Gemini API key never written to plain Hive JSON export without secure storage rules.

### 7.2 Source-of-truth rules (non-negotiable)

| Concept | Source of truth |
|---------|-----------------|
| Exercise / section completion | `ExerciseLog` |
| Day-level Finish | `DailyLog.workoutCompleted` (+ auto when all sections logged) |
| Rest-day “done” for scoring | `WorkoutCompletion` helpers |
| Steps / sleep values | `DailyLog` fields; optional `stepsSource` / `sleepSource` |

### 7.3 Privacy

- Core app runs fully local without accounts.
- **Optional Cloud Sync:** Google Sign-In enables syncing text collections to a private Firestore database (secured via Firebase Security Rules).
- **Media Privacy:** Photos are NEVER synced to Firestore.
- User can delete app data by uninstalling or clearing storage.
- Encrypted ZIP backups are required to migrate photos to a new device.

---

## 8. UX requirements

| ID | Requirement |
|----|-------------|
| UX-1 | Dark theme must keep text, fields, FABs, and sheets readable (no white-on-white) |
| UX-2 | Modal sheets that must clear bottom nav use root navigator |
| UX-3 | Home first viewport: day context, score/metrics, then habits/meals/workout — avoid cluttered promo chrome |
| UX-4 | Logging dialogs (weight, sleep, steps, habits) are quick and forgiving |
| UX-5 | Copy is personal and clear (e.g. “Today’s Meals”, “Balanced Non-Veg Plan”) |

---

## 9. Non-functional requirements

| Area | Requirement |
|------|-------------|
| Performance | Home and day switch feel instant on mid-range Android |
| Reliability | Logging never depends on network |
| Security | Encrypt backups; secure API key storage |
| Maintainability | Riverpod layers: models → repositories → providers → UI |
| Testability | Unit tests for score, workout completion, backup, PR helpers |
| Delivery | Local scripts: `scripts/build_and_install.ps1`, optional keystore generation |

---

## 10. Seeded content (v1 defaults)

| Asset | Content |
|-------|---------|
| Workout | Phase 1 (8 Weeks) — weekday sections with YouTube form links; rest day |
| Meals | Balanced Non-Veg Plan — ~1397 kcal across 4 slots |
| Habits | Sleep, walk/steps, water (and user-custom) |
| Targets | Calories ~1397; protein/carbs/fat defaults on profile |

---

## 11. Acceptance criteria (v1 release)

1. Fresh install → onboarding → seeded plans appear on Home.  
2. User can log a full training day (habits + meals + all sections) and see score rise.  
3. Rest day awards full workout points without logging exercises.  
4. Finish early sets day complete and awards workout points.  
5. Health Connect steps appear after grant without requiring a fresh “Sync” every cold start when previously connected.  
6. Backup ZIP restores plans, logs, and photos on a clean install.  
7. Dark theme: profile edit, manage habits, weight/sleep/steps dialogs remain legible.  
8. No crash on airplane mode for core logging.

---

## 12. Risks & constraints

| Risk | Mitigation |
|------|------------|
| Health Connect permission flakiness after process death | Persist connection flag; probe read; refresh on resume |
| Dual completion semantics | Documented SoT + `WorkoutCompletion` helpers |
| Gemini key / cost / network | Optional feature; offline logging unaffected |
| Sideload-only distribution | Document install + USB debugging for coach |
| Single-user product drift | Keep scope personal; avoid multi-tenant features |

---

## 13. Future considerations (post-v1)

- Coach share link / read-only progress export without full backup  
- Plan editor UI for brother without editing JSON seeds  
- iOS if needed later  
- Deeper sleep/HR from Health Connect  
- Smarter coach notes from weekly adherence  

---

## 14. Appendix — Daily score formula

```
habits   = (habitsDone / habitsCount) * 40
workouts = (sectionsDone / sectionsCount) * 30
           OR 30 on rest day
           OR 30 if Finish-early flag set
meals    = (slotsLogged / planSlots) * 20
steps    = min(1, steps / stepsTarget) * 10   // only if steps/walk habit exists

total    = round( (sum earned / sum max) * 100 )
```

Future dates → `0`.

---

## 15. Document control

| Field | Value |
|-------|-------|
| Derived from | Implemented app behavior (Flutter codebase + README) |
| Audience | Product owner, coach, future contributors |
| Related | `README.md`, `lib/utils/workout_completion.dart`, seed JSON under `assets/data/` |
