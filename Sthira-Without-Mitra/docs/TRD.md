# Technical Requirements Document (TRD)

**Product:** TruFit Bodamma  
**Companion docs:** [`PRD.md`](PRD.md), [`DESIGN.md`](DESIGN.md)  
**Version:** 1.0  
**Platform:** Android (Flutter)  
**Package ID:** `com.trufit.trufit_bodamma`  
**Last updated:** 2026-08-02  

---

## 1. Purpose

This TRD defines **how** TruFit Bodamma is built and constrained technically. Product *what/why* lives in the PRD; visual rules live in the Design doc. Implementers and the coach-developer use this for architecture, data, integrations, build, and quality gates.

---

## 2. System context

```
┌─────────────────────────────────────────────────────────┐
│                  TruFit Bodamma (Android)                 │
│  Flutter UI → Riverpod → Repositories → Hive / files     │
│                                                           │
│  Services: Health Connect · Gemini · YouTube · Notifs    │
│            Backup/Encrypt · Schema migration · CSV       │
└───────────────┬───────────────────┬──────────────────────┘
                │                   │
        On-device only         Optional network
        Health Connect         Gemini API
                               YouTube (iframe)
```

**No cloud backend. No auth server. No remote DB.**

---

## 3. Technology stack

| Layer | Choice | Notes |
|-------|--------|-------|
| Framework | Flutter (Dart SDK ^3.12.2) | Portrait-only |
| State | `flutter_riverpod` ^2.6 | ProviderScope overrides for repos |
| Navigation | `go_router` ^14 | Shell routes: Home / Progress / Profile |
| Local DB | Hive (`hive` + `hive_flutter`) | JSON strings in `Box<String>` |
| Prefs | `shared_preferences` | Onboarding flag, HC sync timestamps, theme |
| Secure secrets | `flutter_secure_storage` | Gemini API key |
| Charts | `fl_chart` | Progress |
| Health | `health` ^13 | Health Connect |
| AI | `google_generative_ai` | Meal scan + coach notes |
| Video | `youtube_player_iframe` | Form demos |
| Backup | `archive` + `encrypt` / `crypto` | ZIP + optional password |
| Notifications | `flutter_local_notifications` | Reminders |
| Min Android | API 26 | `compileSdk` 36, Java 17 |
| App version | `1.0.0+1` (`pubspec.yaml`) | |

---

## 4. Architecture requirements

### 4.1 Layers (mandatory)

| Layer | Responsibility | Location |
|-------|----------------|----------|
| Models | Immutable/plain Dart entities + JSON | `lib/models/` |
| Repositories | Hive open/read/write; seed load | `lib/repositories/` |
| Providers | Reactive UI state, derived scores | `lib/providers/` |
| Services | Cross-cutting I/O (HC, Gemini, backup, notifs, migration) | `lib/services/` |
| Utils | Pure helpers (completion, PR calc) | `lib/utils/` |
| UI | Screens / widgets only; no direct Hive | `lib/screens/`, `lib/widgets/` |
| Theme | Colors + ThemeData | `lib/theme/` |
| Router | GoRouter + redirects (onboarding) | `lib/router/` |

**Rule:** UI must not open Hive boxes directly. Tests may use repo/helpers with test Hive setup.

### 4.2 Startup sequence

1. `WidgetsFlutterBinding.ensureInitialized()`  
2. Lock portrait + system UI style  
3. `Hive.initFlutter()`  
4. `SchemaMigrationService.runStartupMigrations(prefs)`  
5. `init()` all repositories + `HealthConnectService` + `NotificationService` in parallel  
6. Non-blocking `BackupService().autoBackup()`  
7. `runApp(ProviderScope(overrides: [...], child: TruFitApp))`

### 4.3 Source-of-truth (engineering)

| Concept | Canonical store | Helper / API |
|---------|-----------------|--------------|
| Exercise / section done | `exercise_logs` via `ExerciseLogRepository` | `WorkoutCompletion` |
| Day Finish flag | `DailyLog.workoutCompleted` | Auto-set when all sections logged; Finish button |
| Rest day complete | Derived | `WorkoutCompletion.isRestDay` |
| Steps / sleep values | `daily_logs` | Optional `stepsSource` / `sleepSource` |
| Profile + targets | `user_profile` | `ProfileRepository` |
| Gemini key | Secure storage | Not in plain profile JSON export without scrubbing |

Do **not** add completion booleans onto `WorkoutPlan` models.

---

## 5. Data requirements

### 5.1 Hive boxes (backup set)

From `BackupService._boxesToBackup`:

| Box | Contents |
|-----|----------|
| `health_connect_meta` | HC sync metadata |
| `workout_plans` | Plans (seeded + custom) |
| `workout_sessions` | Session state if used |
| `meal_plans` | Meal plans |
| `user_profile` | Profile JSON (API key scrubbed on backup) |
| `scanned_photo_meals` | Gemini scan logs |
| `media_metadata` | Physique photo metadata |
| `daily_meal_logs` | Per-day meal slot logs |
| `meal_completions` | Meal completion markers |
| `habit_config` | Habit definitions |
| `habit_completions` | Per-day habit values |
| `exercise_logs` | Per-exercise logs |
| `exercise_prs` | Personal records |
| `daily_logs` | Weight, steps, sleep, workoutCompleted |
| `body_stats` | Body measurements |
| `coach_notes` | Cached coach notes |

**Plus files:** progress photos / media paths included in ZIP backup.

### 5.2 Seed assets

| Asset | Path | Requirement |
|-------|------|-------------|
| Workout Phase 1 | `assets/data/seed_workout_plan.json` | Loaded if no plan |
| Meal plan | `assets/data/seed_meal_plan.json` | Balanced Non-Veg ~1397 kcal |
| App icon | `assets/icon/app_icon.png` | Regenerated via `flutter_launcher_icons` |

### 5.3 Schema migration

- `SchemaMigrationService.currentSchemaVersion` must bump when box shape / semantics change.
- Migrations run **before** repo init completes critical reads.
- Migrations must be idempotent and tested (`schema_migration_service_test.dart`).

### 5.4 Daily score (technical)

Implemented in `daily_score_provider.dart`:

| Bucket | Max | Logic |
|--------|-----|-------|
| Habits | 40 | Completed habits / count |
| Workouts | 30 | Sections done / sections; rest = full; finish-early = full |
| Meals | 20 | Logged plan slots / plan slots |
| Steps | 10 | Only if steps/walk habit exists; `min(1, steps/target) * 10` |
| Future date | 0 | No scoring |

---

## 6. Functional technical requirements

### 6.1 Routing

| Path | Screen |
|------|--------|
| `/onboarding` | Onboarding |
| `/home` | Home shell child |
| `/home/meals`, `body-stats`, `physique-pictures`, `workout/:dayId` | Nested |
| `/progress`, `/progress/weekly-summary` | Progress |
| `/profile`, `manage-plans`, `backup-restore`, `reminders` | Profile |
| `/youtube-player`, `/exercise-progress` | Top-level |

Redirect: if onboarding incomplete → `/onboarding`.

### 6.2 Health Connect

| Req | Detail |
|-----|--------|
| HC-T1 | Use `health` plugin; graceful if HC unavailable |
| HC-T2 | Persist `hc_connected` in SharedPreferences |
| HC-T3 | On Home open/resume: refresh **today** steps without gating solely on `hasPermissions` |
| HC-T4 | Periodic / manual backfill (7d, 90d) as implemented |
| HC-T5 | Stamp `stepsSource` / `sleepSource` on `DailyLog` |
| HC-T6 | Manual entry must overwrite / coexist with clear UX |

### 6.3 Gemini

| Req | Detail |
|-----|--------|
| GM-T1 | Key in secure storage; optional |
| GM-T2 | Features degrade when key missing or offline |
| GM-T3 | Photo meal scan + coach notes only; no training data exfil beyond API calls |
| GM-T4 | Connectivity banner via `connectivity_plus` for network features |

### 6.4 Backup / restore

| Req | Detail |
|-----|--------|
| BK-T1 | ZIP includes all `_boxesToBackup` + media files |
| BK-T2 | Optional password encryption |
| BK-T3 | Manifest includes `schemaVersion`, `appVersion`, `createdAt` |
| BK-T4 | Restore opens boxes, writes keys, restores files; profile key scrubbing on export |
| BK-T5 | Weekly auto-backup non-blocking on startup |
| BK-T6 | Unit tests cover box list includes `meal_plans` |

### 6.5 Notifications

| Req | Detail |
|-----|--------|
| NT-T1 | Local only; timezone-aware (`timezone`, `flutter_timezone`) |
| NT-T2 | Config persisted; toggles in Reminders screen |

### 6.6 Android platform

| Req | Detail |
|-----|--------|
| AN-T1 | `minSdk` 26, `compileSdk` 36, Java/Kotlin 17 |
| AN-T2 | Core library desugaring enabled |
| AN-T3 | Health Connect permissions declared in AndroidManifest as required by `health` plugin |
| AN-T4 | Release may use debug signing until keystore generated (`scripts/generate_keystore.ps1`) |
| AN-T5 | Profile/release APK via Flutter CLI / `scripts/build_and_install.ps1` |

---

## 7. Non-functional requirements

| ID | Area | Requirement |
|----|------|-------------|
| NF-1 | Offline | Core Hive logging works with no network |
| NF-2 | Latency | Day switch + habit toggle feel instant on mid-range devices |
| NF-3 | Privacy | No analytics SDK; no account telemetry |
| NF-4 | Security | Encrypt backups; secure API key; scrub secrets from ZIP profile |
| NF-5 | Reliability | Migrations + backup restore must not brick app; fail with user-visible error |
| NF-6 | Testability | Pure utils + score + repos covered by unit tests |
| NF-7 | Maintainability | Prefer small providers/utils over growing `app_providers.dart` unbounded (soft) |
| NF-8 | Portrait | Landscape unsupported |

---

## 8. Security & privacy controls

1. No remote user identity.  
2. Gemini key: secure storage only; never log.  
3. Backup password: user-supplied; document loss = unrecoverable archive.  
4. Photos stay on device / in user-held ZIP.  
5. Network: Gemini + YouTube CDN only for optional features.  

---

## 9. Testing requirements

| Type | Scope | Location |
|------|-------|----------|
| Unit | Score, workout completion, PR calc, streaks, phase, migrations, backup box set | `test/` |
| Repo | Hive-backed repos with `test_hive_setup` | `test/repositories/` |
| Widget | Onboarding (smoke) | `test/screens/` |
| Manual | HC sync cold start, dark theme sheets, backup round-trip on device | Checklist below |

**Gate before sideload to Bodamma:** `flutter test` green + manual Home logging smoke.

---

## 10. Build & delivery requirements

| Step | Command / artifact |
|------|--------------------|
| Deps | `flutter pub get` |
| Test | `flutter test` |
| Profile APK | `flutter build apk --profile` → `build/app/outputs/flutter-apk/app-profile.apk` |
| Install | `.\scripts\build_and_install.ps1` (USB debugging) |
| Icons | `dart run flutter_launcher_icons` |
| Signed release | Keystore via `generate_keystore.ps1` + `key.properties` (optional) |

**Toolchain prerequisites:** Flutter stable, Android SDK (`ANDROID_HOME`), licenses accepted, JDK 17-compatible.

---

## 11. Explicit non-requirements (technical)

- Backend / Firebase / Supabase  
- iOS target in v1  
- Multi-isolate Hive write orchestration beyond current patterns  
- Removing unused `PhotoMealRepository` is cleanup, not a blocker  
- Splitting `app_providers.dart` is refactor debt, not a v1 ship blocker  

---

## 12. Risks (technical)

| Risk | Impact | Mitigation |
|------|--------|------------|
| HC permission probe flaky | Steps missing after kill | Persist `hc_connected`; always try today read |
| Dual workout completion | Wrong scores / UI | `WorkoutCompletion` + tests |
| Schema drift on restore | Data loss | Version in manifest; migrations |
| SDK not installed on coach PC | Can’t build APK | Document SDK path; cmdline-tools under `C:\Android\Sdk` |
| Gemini cost / failure | Coach notes / scan fail | Optional; offline path intact |

---

## 13. Traceability

| PRD area | Primary code |
|----------|--------------|
| Daily Home | `screens/home/*` |
| Workouts | `screens/workout/*`, `exercise_log_repository`, `workout_completion` |
| Meals | `meal_repository`, `meals_card`, meal detail |
| Habits | `habit_repository`, `habits_card`, manage habits |
| Score | `daily_score_provider` |
| HC | `health_connect_service` |
| Backup | `backup_service`, encryption service |
| Design tokens | `app_colors.dart`, `app_theme.dart` |
