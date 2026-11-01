# Project Review — Sleep Optimizer

**Date:** 2026-07-29 (updated 2026-07-31)  
**Scope:** Full repository audit — architecture, features, documentation, code quality, Flutter best practices, Firebase integration, production readiness, technical debt.

> **Architecture update (2026-07-31):** The codebase was cleaned up after this review. Findings below that are now resolved are marked **✓ resolved**.
> - **Single data layer:** `lib/services/firestore_service.dart` is now the only Firestore access point. The legacy `FirebaseService` facade (`lib/core/services/firebase_service.dart`) was deleted; `settings_repository.dart` was rewired onto `FirestoreService`.
> - **User identity:** every feature now reads `AppConfig.defaultUserId` (`'default_user'`) from `lib/core/config/app_config.dart` — the hardcoded `'local-user'` values were removed (legacy records migrated via `lib/scripts/user_id_migration.dart`).
> - **Dead code removed:** empty folders, unused widgets/constants/models (`app_constants`, `exceptions`, `failures`, `app_bar`, `app_button`, `app_card` moved to `lib/shared/widgets/`, `home_card`, `home_card_surface`, `settings_model`, `user_model`, legacy screens, `SleepPlanEntity`/`RecommendationEntity`), and the `appThemeMode` global. Tests are now 2 (`widget_test`, `sqi_calculator_test`).

---

# 1. Overall Architecture

## Folder Structure

```
Sleep-Optimizer-App/
├── lib/
│   ├── app/
│   │   ├── app.dart              # Root MaterialApp + shared `appStorage` global
│   │   └── router.dart           # AppRoutes constants + AppRouter.generateRoute
│   ├── core/
│   │   ├── config/               # AppConfig (defaultUserId)
│   │   ├── providers/            # ThemeProvider (ChangeNotifier)
│   │   ├── services/             # StorageService (SharedPreferences)
│   │   └── theme/                # AppColors, AppSpacing, AppTypography, AppTheme
│   ├── features/
│   │   ├── home/                 # HomePage, HomeBody, SuggestedBedtimesPage
│   │   ├── sleep_planner/        # SleepPlannerPage (presentation only; planner math inline)
│   │   ├── sleep_quality/        # SleepQualityPage (SQI questionnaire) + domain/data layers
│   │   ├── recommendation/       # RecommendationPage + GenerateRecommendations usecase
│   │   ├── history/              # HistoryPage
│   │   ├── settings/             # SettingsPage + settings repository
│   │   └── splash/               # SplashPage
│   ├── models/                   # SleepPlan, SQIRecord, Recommendation + RecommendationPriority (Firestore DTOs)
│   ├── scripts/                  # user_id_migration.dart (CLI migration)
│   ├── services/                 # FirestoreService (single data-access layer)
│   ├── shared/widgets/           # AppCard, SectionTitle
│   ├── firebase_options.dart
│   └── main.dart
├── project/                      # All specification docs
├── test/                         # 2 tests (widget_test, sqi_calculator_test)
└── pubspec.yaml
```

## Architecture Pattern

- **Flutter MVVM-lite** with `provider` for state management.
- Feature-based folder structure (`features/<name>/domain|data|presentation`).
- Clean separation between domain entities, data repositories, and UI presentations exists in structure but is inconsistently implemented in practice (many screens access Firestore directly).
- No dependency injection framework — `FirestoreService` and `StorageService` are accessed via direct instantiation, the shared `appStorage` global, or constructor passing.

## State Management

- `provider` package (`ChangeNotifier`).
- `ThemeProvider` manages theme mode.
- `appStorage` is a nullable global declared in `app/app.dart` and assigned once in `main()` before `runApp`. Pages (settings, sleep quality) import it for local theme/history persistence. The former `appThemeMode` global was removed — theme mode is owned by `ThemeProvider`.
- No other state management solution (no Riverpod, Bloc, GetX).

## Routing

- Custom `AppRouter.generateRoute` with raw `switch` on `String` route names.
- No GoRouter — manual `pushReplacementNamed` for bottom-nav tab switching.
- Bottom nav in `HomePage` uses `pushReplacementNamed`, which clears the back stack. This was the root cause of the back-button bug fixed in `home_page.dart:46` (now uses `pushNamedAndRemoveUntil(route, (r) => r.isFirst)`).
- `suggestedBedtimes` and `profile` routes are defined but `suggestedBedtimes` has zero callers in the codebase.
- `profile` route was deleted from `AppRoutes` and `AppRouter` (confirmed in uncommitted working tree diff).

## Theme System

- Dark-first theme with light theme support (stub).
- `AppColors` defines the color palette (periwinkle primary `#6E9EF5`, muted purple accent `#C47FD9`, dark background `#252830`).
- `AppSpacing` uses an 8-point grid with 16px base unit.
- `AppTypography` defines text styles using `GoogleFonts.sora` for headers and `GoogleFonts.inter` for body.
- `AppTheme` is a 525-line file producing fully configured `ThemeData` for both light and dark modes with Material 3.
- `theme.dart` is a barrel export file.

---

# 2. Feature Completion

## Splash

| Metric | Status |
|--------|--------|
| UI completion | ~90% |
| Business logic | ~60% |
| Data persistence | None |
| Missing requirements | Auto-navigation is disabled — no auto-entry after welcome screen is seen (Lovable flow skips splash on subsequent visits). Feature `_welcomeKey` in SharedPreferences is set but never checked on re-entry. |
| Known issues | Splash always shows on every cold start. Should check `_welcomeKey` and auto-navigate to Home if already seen. |

## Home

| Metric | Status |
|--------|--------|
| UI completion | ~85% |
| Business logic | ~70% |
| Data persistence | None for latest score |
| Missing requirements | Latest Score section always shows empty state — no data binding to actual SQI records (FR-4.1, FR-4.2). Profile banner and "Set profile" CTA were removed from HomeBody but could be needed. |
| Known issues | `HomeBody` has no profile banner (removed). Feature card grid only shows 2 cards (Planner, SQI) but design spec expects 4 (Planner, SQI, History, Settings). `SuggestedBedtimesPage` is defined as a route but never navigated to. |

## Sleep Planner

| Metric | Status |
|--------|--------|
| UI completion | ~90% |
| Business logic | ~85% |
| Data persistence | Saves to Firestore via `FirestoreService.addSleepPlan` |
| Missing requirements | No validation for wake-up time (FR-7.1, Business Rules 1.5). No "Calculate" button — bedtimes are auto-calculated on load. The Lovable reference has a "Calculate" button that triggers computation; current implementation calculates on every build. |
| Known issues | Sleep latency default is hardcoded to 15 (`_latency = 15`) with no user-adjustable input other than the slider (0–45 min). The slider labeled "Time to fall asleep" is correct but the UI label should clarify it maps to latency. |

## SQI

| Metric | Status |
|--------|--------|
| UI completion | ~80% |
| Business logic | ~90% |
| Data persistence | Saves to Firestore via `FirestoreService.addSQIRecord` |
| Missing requirements | The active questionnaire (`sleep_quality_page.dart`) now covers the 6 real factors (Sleep duration, Regularity, Screen time, Exercise, Stress, Caffeine). **✓ resolved** — the legacy `sqi_screen.dart` / `sqi_page.dart` duplicates were deleted in the cleanup. |
| Known issues | None remaining — single questionnaire implementation. |

## Recommendation

| Metric | Status |
|--------|--------|
| UI completion | ~75% |
| Business logic | ~80% |
| Data persistence | Recommendations are persisted to the `recommendations` collection via `FirestoreService.addRecommendation` (read back by `getRecommendations(recordId)`) |
| Missing requirements | **✓ resolved** — the "Home" / "View history" / "View Recommendations" buttons are now wired to `Navigator` calls (verified in `recommendation_page.dart`). |
| Known issues | **✓ resolved** — navigation buttons are wired; no stubs remain. |

## History

| Metric | Status |
|--------|--------|
| UI completion | ~85% |
| Business logic | ~50% |
| Data persistence | Loads from Firestore via `FirestoreService` (`getSQIRecords`/`getSleepPlans`, sorted by `createdAt` desc) — **✓ resolved** |
| Missing requirements | Delete functionality works against Firestore (`deleteSQIRecord`/`deleteSleepPlan`); empty-state CTAs switch tabs. The `suggestedBedtimes` route still has no navigation CTA linking to it. |
| Known issues | None remaining for data loading — the hardcoded-placeholder and dead-CTA findings are **✓ resolved**. |

## Settings

| Metric | Status |
|--------|--------|
| UI completion | ~90% |
| Business logic | ~80% |
| Data persistence | Saves theme to Firestore via `FirestoreSettingsRepository` and falls back to SharedPreferences |
| Missing requirements | About section is static text with no dynamic version info. The legacy `settings_screen.dart` duplicate was deleted in the cleanup. |
| Known issues | **✓ resolved** — `settings_page.dart` has a `Switch` wired to `ThemeProvider` via `Provider.of<ThemeProvider>(context)`; theme toggling works. |

---

# 3. Documentation Compliance

## Inconsistencies Against Project Specs

### README
| Finding | Detail |
|---------|--------|
| README status stale | README says `Development: Not Started` but the app is fully implemented and running. |

### Business Rules (`Business-Rules.md`)
| Finding | Detail |
|---------|--------|
| Rule 6.1 violated | "Users can access Sleep Planner and SQI only from Home." — The app uses a bottom nav that allows direct access, but the nav IS on the Home screen. This is compliant in spirit but the rule says "only from Home" which could be interpreted as "only from the Home page, not from other pages." |
| Rule 6.2 | **✓ resolved / superseded** — the legacy `sqi_result_page.dart` and `/sqi-result` route no longer exist; the SQI flow completes into the recommendation page. |
| Rule 6.3 violated | "Preserve data when users navigate between screens." `pushReplacementNamed` destroys the previous route state. Data entered on SQI is lost if user navigates away and returns. |

### Functional Requirements (`Functional-Requirements.md`)
| Finding | Detail |
|---------|--------|
| FR-6.3 | **✓ resolved** — the back-stack bug was fixed via `pushNamedAndRemoveUntil(route, (r) => r.isFirst)` in `home_page.dart:46`. |
| FR-7.1 | Wake-up time validation is missing from the Sleep Planner — no check for empty/invalid input before calculating bedtimes. |
| FR-7.2 | **✓ resolved** — the active questionnaire in `sleep_quality_page.dart` covers the 6 real factors (the legacy `sqi_page.dart` dummy questions were removed). |
| FR-9.1, FR-9.2 | Sleep Plans and SQI records are saved to Firestore, but the app has no offline support and no error handling for failed saves. |
| FR-9.3 | **✓ resolved** — HistoryPage loads records from Firestore via `FirestoreService` (`getSQIRecords`/`getSleepPlans`, `deleteSQIRecord`/`deleteSleepPlan`). |

### Recommendation Logic
| Finding | Detail |
|---------|--------|
| Max 3 recommendations | `GenerateRecommendations.call` uses `weakFactors.take(3)` — compliant. |
| No duplicate prevention | No deduplication logic exists. If two weak factors map to the same recommendation (unlikely in current factorMap but possible with custom factors), duplicates could occur. |
| Good SQI positive reinforcement | `GenerateRecommendations` does not handle the "Excellent SQI → positive reinforcement" rule from Recommendation Logic doc. It only uses weak factors. |
| Poor SQI critical priority | `GenerateRecommendations` does not prioritize critical recommendations for the "Poor SQI" case. The priority is determined by the factor's static config, not by the SQI score level. |

### Data Model
| Finding | Detail |
|---------|--------|
| `Recommendation.priority` stored as `String` | `RecommendationPriority` (enum) now lives alongside the model in `recommendation_model.dart` and is consumed by `GenerateRecommendations`; the persisted model still stores `priority` as a String (`.name`) to match the Firestore schema. The type mismatch means Firestore queries cannot filter by priority without parsing — still open. |
| `SleepPlanEntity` had `sleepDuration` as `String` | **✓ resolved** — the domain entity was deleted; planner logic is inline in `SleepPlannerPage`. |

### Database Design
| Finding | Detail |
|---------|--------|
| `SleepPlannerPage` calls `FirestoreService().addSleepPlan()` directly | The unused repository layer was deleted in the cleanup — `FirestoreService` is now the single data layer by design. |
| Repository usage is inconsistent | Only `SqiRepository` and `FirestoreSettingsRepository` remain; other features call `FirestoreService` directly. Largely **✓ resolved** — the legacy dual-layer confusion is gone. |

### User Flows
| Finding | Detail |
|---------|--------|
| SQI flow missing "Save Result" step | UI Guidelines say SQI Result should have "Save Result" and "View Recommendations" actions. The current SQIResultPage has neither functional. |
| Planner Result flow missing | The design spec has a separate "Planner Result" screen, but the Sleep Planner merges results inline on the same screen. No separate result screen exists. |

### UI Guidelines
| Finding | Detail |
|---------|--------|
| Bottom Navigation used in violation of spec | Design System says "Bottom Navigation: Not used in the current version." but `home_page.dart` implements a custom floating bottom nav. |
| Navigation style mismatch | Design System specifies "Top App Bar." Current implementation uses Material `AppBar` on most screens — compliant. |
| Missing loading indicators | Splash and History screens show `CircularProgressIndicator` in legacy versions but current pages lack loading states for Firestore operations. |

### Design System
| Finding | Detail |
|---------|--------|
| Font family mismatch | Design System says "Sans serif." Typography uses `Nunito` for headers and `DM Sans` for body — both are sans-serif, compliant. But `AppTypography` falls back to system fonts if custom fonts are not loaded (GoogleFonts handles this dynamically, which is acceptable). |
| Icons | Design System specifies "Rounded Outline Icons" at 24px. Current implementation uses Material Icons (`Icons.*`) which are Material design, not rounded outline. |
| No animations | Design System mentions animations as future improvement — no animations implemented. |

---

# 4. Code Quality

## Architecture
- Feature-based folder structure is well-organized.
- `core/` provides shared theme, spacing, typography, and common widgets.
- `features/<name>/domain|data|presentation` structure exists but is inconsistently used — many screens bypass repositories and call Firestore directly.

## SOLID Principles
- **Single Responsibility**: Most files are reasonably focused. `app_theme.dart` at 525 lines is a notable exception.
- **Open/Closed**: N/A — `AppButton` was deleted in the cleanup; only the shared `AppCard`/`SectionTitle` remain.
- **Liskov Substitution**: Only `SqiRepository`/`SettingsRepository` remain and are used consistently.
- **Interface Segregation**: **✓ resolved** — `HomeRepository` (empty abstract class) was deleted.
- **Dependency Inversion**: Not properly implemented. Screens instantiate concrete `FirestoreService` directly rather than depending on abstractions. `SettingsRepository` is the only one properly injected.

## Separation of Concerns
- **Weak** in practice. `SleepPlannerPage` (555 lines) contains business logic (bedtime calculation) alongside UI rendering. `SQIPage` has questionnaire state management mixed with presentation.
- The `home_body.dart` at 310 lines mixes layout, navigation, and greeting logic.

## Reusability
- `AppCard` (`lib/shared/widgets/app_card.dart`) is the main reusable widget but remains underutilized — many screens build custom containers instead. `AppButton`/`AppBarWidget` were deleted.
- **✓ resolved** — `home_card.dart` and `home_card_surface.dart` (dead code) were deleted.

## Naming
- Mostly consistent and descriptive.
- `_currentIndex` in `HomePage` is clear.
- `_BedtimeOption` in `sleep_planner_page.dart` is a private class that should probably be in the domain layer.
- **✓ resolved** — the `SleepPlanEntity` duplicate was deleted; only the `SleepPlan` model remains.

## Dead Code
**✓ resolved** — the 2026-07-31 cleanup removed all listed dead files: legacy screens (`home_screen`, `sqi_screen`, `settings_screen`, `history_screen`), `home_card.dart`, `home_card_surface.dart`, `app_scaffold.dart` (never existed), `exceptions.dart`, `failures.dart`, `app_constants.dart`, `app_bar.dart`, `app_button.dart`, `user_model.dart`, `settings_model.dart`, and `feature_card.dart`.

Remaining minor items (functional, not dead code):
| File | Issue |
|------|-------|
| `lib/features/history/presentation/pages/history_page.dart` | Empty-state CTAs switch tabs (not yet deep links to Planner/SQI). |

## Duplicated Code
- **✓ resolved** — the `SleepPlanEntity`/`SleepPlan` and `SqiResult`/`SQIRecord` domain/DTO splits were consolidated; the old `sqi_screen.dart` copy of `SQIRecord` was deleted.
- **✓ resolved** — `RecommendationEntity`/`Recommendation` collapsed into the single `Recommendation` model (`generate_recommendations.dart` returns it directly); the legacy `FirebaseService` wrapper layer was deleted.
- `FirestoreSqiRepository` still wraps `FirestoreService` with little added logic — minor boilerplate.
- Theme toggle logic is duplicated in `ThemeProvider.toggleTheme()` and `ThemeProvider.setTheme()`.
- `SettingsRepository.saveSettings` and `SettingsRepository.loadSettings` both have duplicate error-handling patterns (try Firestore, fall back to local storage).

---

# 5. Flutter Best Practices

## Widgets
- **✓ resolved** — the 440-line custom `AppButton` was deleted in the cleanup; only the shared `AppCard`/`SectionTitle` widgets remain.
- `GestureDetector` is overused where `InkWell` or `Material` ink effects would be more idiomatic (e.g., `HomeBody` feature cards).
- `BottomNavigationBar` is not used; a custom floating pill nav is implemented instead, which is fine for design fidelity but does not leverage Flutter's built-in `BottomNavigationBar` semantics or accessibility.

## Performance
- `home_page.dart` uses `BackdropFilter` with `sigmaX: 16, sigmaY: 16` for the floating bottom nav — this is a per-pixel GPU operation that runs on every rebuild (performance concern noted in the code review).
- `SizedBox` wrapping the entire home screen content with `SingleChildScrollView` inside `SafeArea` is a reasonable approach for the constrained-width layout.
- Ambient orbs use `ImageFiltered` with `ImageFilter.blur(sigmaX: 50, sigmaY: 50)` — expensive GPU operation, especially on older devices. Present on `SplashPage` and `SQIResultPage`.
- `IntrinsicHeight` in `home_body.dart` feature grid forces two layout passes — avoidable with a `Row` of fixed-height containers.

## Accessibility
- Most text uses `GoogleFonts` with explicit `fontSize` values but does not use `MediaQuery` or `textScaleFactor` — users with larger font sizes may overflow containers.
- Touch targets are generally adequate (48px minimum for buttons) but feature cards in `home_body.dart` use `GestureDetector` without minimum size guarantees.
- Color contrast in dark theme is generally good but the `mutedForeground` color `#AEB2BE` on `#252830` background has insufficient contrast ratio for compliance.

## Responsiveness
- `HomePage` constrains width to `min(448.0, screenWidth - 32)` — good for mobile but no tablet or landscape handling is visible.
- `SplashPage` uses `MediaQuery.size` for orb positioning which adapts to screen size.
- No `LayoutBuilder` or `MediaQuery` breakpoints for different screen sizes are implemented.

## Material 3
- `useMaterial3: true` is set in both themes — compliant.
- `ColorScheme` is properly configured with primary, secondary, surface, error, and on-color variants.
- Material 3 components (`NavigationBarThemeData`, switch/checkbox/radio themes) are configured.
- However, custom bottom nav bypasses Material 3's `NavigationBar` widget, losing built-in M3 semantics.

---

# 6. Firebase

## Current Integration
- **Firebase initialized** in `main.dart` before any other service usage (single call).
- **`FirestoreService`** (`lib/services/firestore_service.dart`): the single data-access layer for all features (planner, SQI, history, settings, recommendations). Direct Firestore access with no initialization guard — will crash if Firebase is not initialized before use.
- **`StorageService`** (`lib/core/services/storage_service.dart`): `SharedPreferences` wrapper for local theme/history fallback.
- **User identity:** all records are written under `AppConfig.defaultUserId` (`'default_user'`), the single constant in `lib/core/config/app_config.dart`.

## Issues
| Issue | Detail |
|-------|-------|
| Single Firestore access path | **✓ resolved** — the legacy `FirebaseService` facade was deleted; everything routes through `FirestoreService`. |
| No auth | No authentication flow exists despite `users` collection in DB schema; all data lives under the shared `AppConfig.defaultUserId` — still open. |
| No offline persistence | Firestore defaults are used; no explicit offline persistence configuration. |
| Hardcoded user IDs | **✓ resolved** — `'local-user'` is gone; every feature reads `AppConfig.defaultUserId` from `lib/core/config/app_config.dart`. |
| `Firebase.initializeApp()` called twice | **✓ resolved** — the redundant `FirebaseService.initialize()` call no longer exists; `main()` initializes Firebase exactly once. |

---

# 7. Production Readiness

## Error Handling
- **Missing** in most screens. `SleepPlannerPage._handleSave` does not catch Firestore errors. `SQIPage._nextQuestion` does not show validation for empty wake-up time (FR-7.1 violated).
- `SettingsRepository.saveSettings` has try/catch with local fallback — the only robust error handling.
- `HistoryPage` now loads from Firestore via `FirestoreService` — error handling applies (and empty-state CTAs switch tabs).
- **✓ resolved** — `RecommendationPage` navigation buttons (Home, View history) are wired to `Navigator` calls.

## Loading States
- **Missing** from most screens. `SleepPlannerPage._handleSave` has no loading indicator during Firestore save. `SQIPage` has no loading state during questionnaire submission.
- **Present** in legacy `HistoryScreen` and `SettingsScreen` (now unused).
- **Partially present** in `SplashPage` — no loading indicator on the Continue button.

## Empty States
- `HomeBody._buildLatestScoreSection` always shows empty state text "Take your first assessment" with no data binding.
- `HistoryPage` shows empty states for both SQI records and sleep plans; CTAs switch tabs.
- `RecommendationPage` shows appropriate empty states when no results exist.

## Offline Support
- **Not implemented.** Firestore operations will fail offline. No local caching or offline-first strategy exists beyond SharedPreferences for theme.

## Security
- No input sanitization on Firestore writes.
- No auth to prevent unauthorized data access — all data is written under the shared `AppConfig.defaultUserId` ('default_user').
- Firestore rules not visible in codebase — assume open access in development, which is a security risk for production.
- No HTTPS pinning or certificate validation visible.

---

# 8. Technical Debt (Ranked)

### High

1. **Dual SQI questionnaire implementations** — **✓ resolved**; the 499-line legacy `sqi_screen.dart` was deleted. The active questionnaire lives in `sleep_quality_page.dart`.
2. **Unused repository layer bypass** — largely **✓ resolved**; the unused planner/recommendation repository classes were deleted. `SqiRepository`/`SettingsRepository` remain; other features call `FirestoreService` directly by design.
3. **`pushReplacementNamed` back-stack bug** (now fixed at `home_page.dart:46`) — caused all non-home screens to exit the app on back press. Was present across 6 screens before the fix.
4. **`FirebaseService.initialize()` called redundantly** — **✓ resolved**; `FirebaseService` was deleted, and `main()` initializes Firebase exactly once.

### Medium

5. **Empty CTA/navigation handlers** in HistoryPage, RecommendationPage — broken interactive elements.
6. **Ambient orbs** (`ImageFilter.blur(sigmaX: 50)`) on SplashPage and SQIResultPage — GPU-expensive, not in design spec.
7. **`HomeBody` feature grid** only shows 2 of 4 expected feature cards per design spec.
8. **Hardcoded user IDs** — mostly **✓ resolved**; all features now read `AppConfig.defaultUserId` (`'default_user'`) from one constant. Real authentication is still absent.
9. **No offline support** — Firestore operations will fail without connectivity.
10. **`suggestedBedtimes` route** defined in router but never navigated to.

### Low
11. **`AppTypography` references unused font families** (`Nunito` in header, `DM Sans` in body, but app uses `GoogleFonts.sora` and `GoogleFonts.inter` dynamically).
12. **`HomeRepository`** empty abstract class — **✓ resolved** (deleted).
13. **`AppBarWidget`** unused — **✓ resolved** (`app_bar.dart` deleted; screens use `AppBar()` directly).
14. **Duplicated error handling** in `SettingsRepository` save/load methods.
15. **`app_scaffold.dart`** referenced-but-missing — **✓ resolved** (the dangling reference was removed).
16. **Duplicate `theme` field** on `User`/`Settings` models — **✓ resolved** (both models deleted; theme persists via `StorageService` + Firestore settings map).

---

# 9. Recommended Next Steps

### Immediate (fix blocking issues)
1. **Merge or delete `sqi_screen.dart`** — **✓ resolved**; the legacy duplicate was deleted.
2. **Wire up empty CTAs** in HistoryPage and RecommendationPage with functional `onTap` / `onPressed` handlers.
3. **Add firestore error handling** to `SleepPlannerPage._handleSave` and `SQIPage` submission flow with user-facing SnackBar or dialog.
4. **Remove ambient orbs** from `SplashPage` and `SQIResultPage` or reduce blur sigma per performance review.

### Short-term (next sprint)
5. **Consolidate Firestore access** — **✓ resolved** (inverted): `FirestoreService` is now the single data layer; the legacy `FirebaseService` facade was deleted.
6. **Implement History data loading** from Firestore instead of hardcoded placeholders.
7. **Add loading states** to Sleep Planner save and SQI submission.
8. **Implement proper user authentication** — user identity is now consistent (`AppConfig.defaultUserId`), but real authentication is still missing.
9. **Add input validation** for Sleep Planner wake-up time per FR-7.1 and Business Rules 1.5.

### Medium-term
10. **Add offline support** — enable Firestore offline persistence or cache data in SharedPreferences/Hive.
11. **Consolidate theme toggle logic** in `ThemeProvider` to remove duplication between `setTheme` and `toggleTheme`.
12. **Implement responsive breakpoints** for tablet and landscape orientations.
13. **Add accessibility** — ensure `textScaleFactor` respect, increase contrast ratios for `mutedForeground` color, add semantic labels.

### Long-term
14. **Migrate to GoRouter** for typed route navigation and better back-stack management.
15. **Introduce dependency injection** to properly wire repositories to services.
16. **Implement the recommendation persistence** — recommendations should be saved to Firestore and retrieved on the RecommendationPage.
17. **Add integration tests** for full user flows (Splash → Home → Planner → Result → Home).
