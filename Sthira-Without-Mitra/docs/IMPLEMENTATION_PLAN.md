# Implementation Plan

**Product:** TruFit Bodamma  
**Based on:** [`PRD.md`](PRD.md), [`DESIGN.md`](DESIGN.md), [`TRD.md`](TRD.md)  
**Version:** 1.0  
**Last updated:** 2026-08-02  

---

## 1. Status snapshot

The app is **largely implemented** as a private Android Flutter client. This plan prioritizes **ship readiness**, then polish, then optional debt — not a greenfield build.

| Area | Status |
|------|--------|
| Local Hive architecture | Done |
| Onboarding + seeded plans | Done |
| Home / Progress / Profile | Done |
| Workout logging + YouTube + rest timer | Done |
| Meals + habits + score | Done |
| Workout completion SoT helpers | Done (recent) |
| Dark-theme contrast fixes | Done (recent) |
| Health Connect cold-start sync | Done (recent) |
| Backup includes `meal_plans` | Done (recent) |
| PRD / Design / TRD docs | Done |
| Android SDK + profile APK on this machine | **In progress / blocked until SDK packages + licenses** |
| Signed Play-style release | Optional |
| Visual rebrand | Not required (see Design doc) |

---

## 2. Objectives

1. **Ship** a profile (or release) APK Bodamma can sideload.  
2. **Verify** P0 product behaviors on a real device (HC, dark UI, backup).  
3. **Stabilize** with tests green after each meaningful change.  
4. **Defer** redesign and large refactors unless they unblock shipping.

---

## 3. Workstreams

### Stream A — Delivery (highest priority)

| ID | Task | Owner | Deps | Done when |
|----|------|-------|------|-----------|
| A1 | Confirm Flutter on PATH (`C:\flutter\bin`) | Coach PC | — | `flutter --version` works |
| A2 | Install Android SDK packages via sdkmanager (`platforms;android-36`, `build-tools`, `platform-tools`) | Coach PC | cmdline-tools at `C:\Android\Sdk` | `sdkmanager --list_installed` shows them |
| A3 | Set `ANDROID_HOME` / `flutter config --android-sdk` | Coach PC | A2 | `flutter doctor` Android toolchain OK |
| A4 | Accept Android licenses | Coach PC | A3 | `flutter doctor --android-licenses` |
| A5 | `flutter pub get` + `flutter test` | Repo | A1 | All tests pass |
| A6 | `flutter build apk --profile` | Repo | A4–A5 | APK at `build/app/outputs/flutter-apk/app-profile.apk` |
| A7 | Install on phone (`build_and_install.ps1` or `adb install`) | Device | A6 | App launches |
| A8 | Optional: generate keystore + release APK | Coach PC | A6 | Signed APK for longer-term installs |

### Stream B — Device acceptance (P0 product)

Run on Bodamma’s phone (or test device) after A7:

| ID | Scenario | Pass criteria |
|----|----------|---------------|
| B1 | Fresh / upgrade install | Onboarding or existing data loads; seeded or restored plans visible |
| B2 | Log full training day | Habits + meals + sections → score increases |
| B3 | Rest day | Full workout points without logging exercises |
| B4 | Finish early | Day marked complete; workout points awarded |
| B5 | Health Connect | Grant once; kill app; reopen → today’s steps refresh without mandatory Sync CTA |
| B6 | Dark theme | Profile edit, Manage Habits, weight/sleep/steps sheets legible |
| B7 | Water habit | One-tap complete; goal editable |
| B8 | Backup round-trip | Export ZIP → clear/reinstall or second device → restore → data present |
| B9 | Airplane mode | Habit/meal/workout log still works |

### Stream C — Polish (P1, no redesign)

| ID | Task | Notes |
|----|------|-------|
| C1 | Home density | Push coach notes / secondary content below primary logging path |
| C2 | Dialog consistency | Shared styling for all entry sheets |
| C3 | Copy pass | Scan Home/Profile for leftover internal plan names |
| C4 | Regression watch | Any new sheet → `rootNavigator: true` if under bottom nav |
| C5 | Commit docs | Add `docs/PRD.md`, `DESIGN.md`, `TRD.md`, this plan when you want them on GitHub |

### Stream D — Technical debt (P2, after ship)

| ID | Task | Risk if deferred |
|----|------|------------------|
| D1 | Split oversized `app_providers.dart` | Maintainability only |
| D2 | Remove or wire unused `PhotoMealRepository` paths | Confusion only |
| D3 | Release signing default (stop debug signing in release) | Sideload trust / updates |
| D4 | Optional visual token refresh | Brand only — see Design §11 |

### Stream E — Explicitly out of plan

- Full UI redesign  
- Backend / accounts  
- iOS  
- Play Store listing  
- Multi-user coach dashboard  

---

## 4. Phased timeline (practical)

### Phase 0 — Docs & baseline (complete)

- [x] PRD  
- [x] Design doc (no mandatory redesign)  
- [x] TRD  
- [x] Implementation plan  
- [x] High-priority SoT / backup / HC / theme fixes landed & pushed  

### Phase 1 — Build environment (current)

**Goal:** reproducible APK on coach machine.

1. Finish SDK install (A2–A4).  
2. Run tests (A5).  
3. Build profile APK (A6).  

**Exit:** APK file exists; `flutter doctor` Android line is green or warnings-only.

### Phase 2 — Device hardening (1 short session)

**Goal:** Bodamma can use daily without coach sitting nearby.

1. Install (A7).  
2. Execute B1–B9 checklist; file bugs only for fails.  
3. Hotfix P0 fails only (contrast, HC, backup, crash).  

**Exit:** Checklist green or accepted waivers documented.

### Phase 3 — Stabilize & optional polish (ongoing)

1. C-stream polish as time allows.  
2. Weekly auto-backup verified on her device.  
3. Optional D3 release signing before long-term primary install.  

### Phase 4 — Optional later

- Brand token refresh (Design §11)  
- Plan editor UI for coach  
- Deeper HC metrics  

---

## 5. Suggested execution order (next actions)

```
1. sdkmanager install platform-tools platform android-36 build-tools
2. flutter config --android-sdk C:\Android\Sdk
3. flutter doctor
4. flutter test
5. flutter build apk --profile
6. adb install -r app-profile.apk
7. Run device checklist B1–B9
8. Fix only P0 failures; re-ship APK
9. Commit docs if desired
```

---

## 6. Definition of Done (v1 personal release)

- [ ] Profile or release APK installed on Bodamma’s phone  
- [ ] `flutter test` passes on coach machine  
- [ ] Device checklist B1–B9 passed (or waived in writing)  
- [ ] Backup ZIP produced and successfully restored at least once  
- [ ] No known P0 dark-theme or HC cold-start bugs  
- [ ] PRD/Design/TRD reflect shipped behavior  

**Not required for DoD:** redesign, Play Store, iOS, provider file split.

---

## 7. Change management

| Change type | Process |
|-------------|---------|
| Bugfix / polish | Branch or direct on `main`; test locally; sideload new APK |
| Schema change | Bump migration version + tests + backup restore test |
| Score / completion rules | Update `WorkoutCompletion` + score tests + PRD/TRD formula section |
| Seed plan content | Edit JSON assets; note in APK release message to sister |
| Design system tokens | Prefer `app_colors` / `app_theme` only; avoid one-off hex in widgets |

---

## 8. Rollback

| Failure | Rollback |
|---------|----------|
| Bad APK | Reinstall previous APK; restore latest backup ZIP if data migrated wrong |
| Bad migration | Keep prior APK; fix migration; never hand-edit Hive on device |
| HC confusion | Clear steps → re-enter manual; re-grant HC |

---

## 9. Effort guide (coach time)

| Phase | Rough effort |
|-------|----------------|
| Phase 1 SDK + first APK | 30–90 min (network/SDK dependent) |
| Phase 2 device checklist | 30–45 min |
| Phase 3 polish slice | 1–3 hours as needed |
| Redesign (if ever) | Days — not scheduled |

---

## 10. Summary

**Implement by shipping, not by rebuilding.** Finish Android toolchain → APK → device checklist → fix P0 only → optional polish. Docs already define product, design stance, and technical constraints; this plan is the execution order.
