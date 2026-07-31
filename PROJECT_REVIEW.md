# Project Review — Sleep Optimizer

**Date:** 2026-07-29  
**Scope:** Full repository audit — architecture, features, documentation, code quality, Flutter best practices, Firebase integration, production readiness, technical debt.

---

# 1. Overall Architecture

## Folder Structure

```
Sleep-Optimizer-App/
├── lib/
│   ├── app/
│   │   ├── app.dart              # Root MaterialApp with theme + router
│   │   └── router.dart           # AppRoutes constants + AppRouter.generateRoute
│   ├── core/
│   │   ├── config/               # AppConfig (minimal)
│   │   ├── constants/            # AppConstants (minimal)
│   │   ├── errors/               # exceptions.dart, failures.dart (empty shells)
│   │   ├── presentation/widgets/ # AppBarWidget, AppButton, AppCard
│   │   ├── providers/            # ThemeProvider (ChangeNotifier)
│   │   ├── services/             # FirebaseService (facade), StorageService (SharedPreferences)
│   │   ├── theme/                # AppColors, AppSpacing, AppTypography, AppTheme, theme.dart barrel
│   │   └── widgets/              # app_scaffold.dart (missing — not found)
│   ├── features/
│   │   ├── home/                 # HomePage, HomeBody, SuggestedBedtimesPage, legacy HomeScreen
│   │   ├── sleep_planner/        # SleepPlannerPage + domain/data layers
│   │   ├── sleep_quality/        # SleepQualityPage (SQI questionnaire) + domain/data layers
│   │   ├── sqi/                  # SQIPage, SQIResultPage + legacy SQIScreen
│   │   ├── recommendation/       # RecommendationPage + domain/data layers
│   │   ├── history/              # HistoryPage + legacy HistoryScreen
│   │   ├── settings/             # SettingsPage + legacy SettingsScreen
│   │   └── splash/               # SplashPage
│   ├── models/                   # SleepPlan, SQIRecord, Recommendation, User, Settings (Firestore DTOs)
│   ├── services/                 # FirestoreService (direct Firestore access)
│   ├── shared/widgets/           # SectionTitle
│   ├── firebase_options.dart
│   └── main.dart
├── project/                      # All specification docs
├── test/                         # 3 tests (widget_test, sqi_calculator_test, sleep_planner_calculator_test)
└── pubspec.yaml
```

## Architecture Pattern

- **Flutter MVVM-lite** with `provider` for state management.
- Feature-based folder structure (`features/<name>/domain|data|presentation`).
- Clean separation between domain entities, data repositories, and UI presentations exists in structure but is inconsistently implemented in practice (many screens access Firestore directly).
- No dependency injection framework — `FirebaseService` and `StorageService` are accessed via global instance or constructor passing.

## State Management

- `provider` package (`ChangeNotifier`).
- `ThemeProvider` manages theme mode.
- `appStorage` and `appThemeMode` are global `late` variables in `main.dart` — a fragile pattern that risks null access if accessed before initialization.
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
| Missing requirements | SQIPage in `sqi_page.dart` has 5 dummy questions but the spec requires 6 factors (Sleep duration, Sleep regularity, Screen time, Exercise, Stress, Caffeine). The `sqi_screen.dart` legacy file has all 6 real questions. Two codebases coexist — `sqi_page.dart` uses placeholder "Option 1-4" answers while `sqi_screen.dart` has the real questionnaire. |
| Known issues | Dual implementation of SQI questionnaire. `sqi_page.dart` (current) has hardcoded dummy answers (`'Option ${index + 1}'`). `sqi_screen.dart` (legacy) has real questions. Recommend consolidating to one. |

## Recommendation

| Metric | Status |
|--------|--------|
| UI completion | ~75% |
| Business logic | ~80% |
| Data persistence | Recommendations are generated in-memory by `GenerateRecommendations` use case; not persisted independently (saved as part of SQI record in Firestore) |
| Missing requirements | "View Recommendations" CTA button on RecommendationPage has empty `onPressed` — non-functional. "Home" and "View history" buttons also have empty `onPressed`. |
| Known issues | Navigation buttons in the recommendation page body are all stubs with no action. |

## History

| Metric | Status |
|--------|--------|
| UI completion | ~85% |
| Business logic | ~50% |
| Data persistence | Uses placeholder in-memory data (`_sqiRecords`, `_sleepPlans`) — no Firestore integration |
| Missing requirements | HistoryPage uses hardcoded placeholder data instead of loading from Firestore. Delete functionality is stubbed (removes from in-memory list only). The `suggestedBedtimes` route exists but no navigation CTA links to it. |
| Known issues | No real data loading from Firestore. The empty-state CTAs ("Take assessment", "Open planner") have empty `onTap` handlers. |

## Settings

| Metric | Status |
|--------|--------|
| UI completion | ~90% |
| Business logic | ~80% |
| Data persistence | Saves theme to Firestore via `FirestoreSettingsRepository` and falls back to SharedPreferences |
| Missing requirements | About section is static text with no dynamic version info. The `settings_page.dart` and legacy `settings_screen.dart` coexist. |
| Known issues | `settings_page.dart` uses `Provider.of<ThemeProvider>(context)` with `listen: false` in the onChanged callback of the Switch — correct pattern but the settings page does not currently use a Switch widget for theme toggling; it only has a static display. |

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
| Rule 6.2 partially violated | "Back button from SQI result page should return to SQI." Current `sqi_result_page.dart` uses `pushReplacementNamed('/sqi-result')` from SQIPage, so the back stack has no SQI page to return to. Back goes to Home instead. |
| Rule 6.3 violated | "Preserve data when users navigate between screens." `pushReplacementNamed` destroys the previous route state. Data entered on SQI is lost if user navigates away and returns. |

### Functional Requirements (`Functional-Requirements.md`)
| Finding | Detail |
|---------|--------|
| FR-6.3 | Navigation does not preserve data between screens due to `pushReplacementNamed` clearing state. |
| FR-7.1 | Wake-up time validation is missing from the Sleep Planner — no check for empty/invalid input before calculating bedtimes. |
| FR-7.2 | SQI questionnaire validation only checks `_responses.length != _questions.length` but the current `sqi_page.dart` uses 5 dummy questions with 4 answer options each, not the 6 real factors from the spec. |
| FR-9.1, FR-9.2 | Sleep Plans and SQI records are saved to Firestore, but the app has no offline support and no error handling for failed saves. |
| FR-9.3 | No "retrieve previously saved" feature works in History — HistoryPage uses hardcoded mock data instead of loading from Firestore. |

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
| `Recommendation` model has `priority` as `String` | Business Rules and Recommendation Logic define `RecommendationPriority` as an enum (`critical`, `high`, `medium`, `low`) — the domain model uses the enum, but the Firestore DTO in `recommendation_model.dart` stores it as a `String`. The mapping is correct but the type mismatch means Firestore queries cannot filter by priority without parsing. |
| `SleepPlanEntity` has `sleepDuration` as `String` | The domain entity stores duration as a formatted string (e.g., `"9h 0m"`) rather than as a computable integer, making it unusable for sorting or comparison. |

### Database Design
| Finding | Detail |
|---------|--------|
| `FirestoreService` uses `saveSleepPlan` but `SleepPlannerPage` directly calls `FirestoreService().addSleepPlan(sleepPlan)` | The repository layer (`SleepPlannerRepository`) exists but is unused — `SleepPlannerPage` bypasses it entirely, going directly to `FirestoreService`. |
| Same bypass pattern exists for all features | `SQIPage` uses `FirestoreService().addSQIRecord()`, not `SqiRepository`. `SettingsPage` uses `FirestoreSettingsRepository` correctly. Inconsistency across the codebase. |

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
- **Open/Closed**: `AppButton` is extensible via enum variants but adding a new variant requires modifying the switch statement in 5 places.
- **Liskov Substitution**: Repository abstract classes exist but are unused in most feature screens.
- **Interface Segregation**: `HomeRepository` is an empty abstract class with no methods — a dead abstraction.
- **Dependency Inversion**: Not properly implemented. Screens instantiate concrete `FirestoreService` directly rather than depending on abstractions. `SettingsRepository` is the only one properly injected.

## Separation of Concerns
- **Weak** in practice. `SleepPlannerPage` (555 lines) contains business logic (bedtime calculation) alongside UI rendering. `SQIPage` has questionnaire state management mixed with presentation.
- The `home_body.dart` at 310 lines mixes layout, navigation, and greeting logic.

## Reusability
- `AppButton`, `AppCard`, `AppBarWidget` exist as reusable widgets but are underutilized — many screens build custom containers instead.
- `home_card.dart` and `home_card_surface.dart` exist but are dead code (never imported).

## Naming
- Mostly consistent and descriptive.
- `_currentIndex` in `HomePage` is clear.
- `_BedtimeOption` in `sleep_planner_page.dart` is a private class that should probably be in the domain layer.
- Inconsistent naming: `SleepPlanEntity` (domain) vs `SleepPlan` (Firestore DTO) vs `SleepPlan` (model) — three different classes with overlapping names across different packages.

## Dead Code
| File | Issue |
|------|-------|
| `lib/features/home/home_screen.dart` | Legacy Material-style Home; dead. |
| `lib/features/home/presentation/widgets/components/home_card.dart` | Never imported anywhere. |
| `lib/features/home/presentation/widgets/components/home_card_surface.dart` | Never imported anywhere (line 11 import never used). |
| `lib/features/home/presentation/widgets/components/home_card_surface.dart` | `home_card_surface.dart` line 11 has an import that is never used. |
| `lib/features/profile/presentation/pages/profile_page.dart` | Deleted in working tree (was dead code). |
| `lib/features/sqf/sqi_screen.dart` | Legacy SQI screen; not used by the current `sqi_page.dart`. |
| `lib/features/settings/settings_screen.dart` | Legacy Settings screen; not used by the current `settings_page.dart`. |
| `lib/features/history/history_screen.dart` | Legacy History screen; not used by the current `history_page.dart`. |
| `lib/core/presentation/widgets/app_scaffold.dart` | File does not exist at the expected path. |
| `lib/core/errors/exceptions.dart` | Empty or minimal. |
| `lib/core/errors/failures.dart` | Empty or minimal. |
| `lib/core/config/app_config.dart` | Minimal/unused. |
| `lib/core/constants/app_constants.dart` | Minimal/unused. |
| `lib/features/recommendation/presentation/pages/recommendation_page.dart` lines 100-111 | Home and View history buttons have empty `onPressed` handlers. |
| `lib/features/history/presentation/pages/history_page.dart` | Empty-state CTAs have empty `onTap` handlers (lines 333-337). |

## Duplicated Code
- `SleepPlanEntity` (domain) and `SleepPlan` (model/Firestore DTO) share nearly identical fields — could be unified.
- Same pattern exists for `SQIRecord` / `SqiResult` vs the old `SQIRecord` in `sqi_screen.dart`.
- `FirestoreSleepPlannerRepository`, `FirestoreSqiRepository`, `FirestoreRecommendationRepository` all follow the same pattern of wrapping `FirebaseService` with no additional logic — the repository layer is boilerplate.
- Theme toggle logic is duplicated in `ThemeProvider.toggleTheme()` and `ThemeProvider.setTheme()`.
- `SettingsRepository.saveSettings` and `SettingsRepository.loadSettings` both have duplicate error-handling patterns (try Firestore, fall back to local storage).

---

# 5. Flutter Best Practices

## Widgets
- Custom `AppButton` with animation controller and multiple variants is well-structured but at 440 lines is heavy for a button widget.
- `GestureDetector` is overused where `InkWell` or `Material` ink effects would be more idiomatic (e.g., `HomeBody` feature cards, `AppButton` itself already uses `GestureDetector` + `Material` + `InkWell` internally, which is correct).
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
- **Firebase initialized** in `main.dart:16` before any other service usage.
- **`FirebaseService`** (`lib/core/services/firebase_service.dart`): A facade that wraps `FirebaseFirestore.instance` with initialization guards. Returns empty lists / null for read operations when Firebase is not initialized (graceful degradation).
- **`FirestoreService`** (`lib/services/firestore_service.dart`): Direct Firestore access with no initialization guard — will crash if Firebase is not initialized before use. This is used directly by `SleepPlannerPage` and `SQIPage`, creating a fragility.
- **`StorageService`** (`lib/core/services/storage_service.dart`): `SharedPreferences` wrapper for theme persistence.

## Issues
| Issue | Detail |
|-------|-------|
| Dual Firestore access paths | `FirestoreService` (direct, no guard) and `FirebaseService` (guarded) both exist. `SleepPlannerPage` uses `FirestoreService` directly; `SettingsPage` uses `FirestoreSettingsRepository` which uses `FirebaseService`. Inconsistent. |
| No auth | User ID is hardcoded as `'default_user'` and `'local-user'`. No authentication flow exists despite `users` collection in DB schema. |
| No offline persistence | Firestore defaults are used; no explicit offline persistence configuration. |
| Hardcoded user IDs | `SleepPlannerPage` uses `'default_user'` (line 111). `SQIPage` / `SettingsPage` use `'local-user'`. |
| `Firebase.initializeApp()` called twice | Once in `main.dart:16` and again in `FirebaseService.initialize()` — redundant. |

---

# 7. Production Readiness

## Error Handling
- **Missing** in most screens. `SleepPlannerPage._handleSave` does not catch Firestore errors. `SQIPage._nextQuestion` does not show validation for empty wake-up time (FR-7.1 violated).
- `SettingsRepository.saveSettings` has try/catch with local fallback — the only robust error handling.
- `HistoryPage` uses hardcoded data, so error handling is irrelevant for data loading (but empty-state CTAs are non-functional).
- `RecommendationPage` navigation buttons (Home, View history) have empty `onPressed` — no error possible since nothing happens, but poor UX.

## Loading States
- **Missing** from most screens. `SleepPlannerPage._handleSave` has no loading indicator during Firestore save. `SQIPage` has no loading state during questionnaire submission.
- **Present** in legacy `HistoryScreen` and `SettingsScreen` (now unused).
- **Partially present** in `SplashPage` — no loading indicator on the Continue button.

## Empty States
- `HomeBody._buildLatestScoreSection` always shows empty state text "Take your first assessment" with no data binding.
- `HistoryPage` shows empty states for both SQI records and sleep plans with non-functional CTAs.
- `RecommendationPage` shows appropriate empty states when no results exist.

## Offline Support
- **Not implemented.** Firestore operations will fail offline. No local caching or offline-first strategy exists beyond SharedPreferences for theme.

## Security
- No input sanitization on Firestore writes.
- User IDs are hardcoded strings — no auth to prevent unauthorized data access.
- Firestore rules not visible in codebase — assume open access in development, which is a security risk for production.
- No HTTPS pinning or certificate validation visible.

---

# 8. Technical Debt (Ranked)

### High

1. **Dual SQI questionnaire implementations** (`sqi_page.dart` vs `sqi_screen.dart`) — 499 lines of dead legacy code in `sqi_screen.dart` that does not match the new `sqi_page.dart`. Risk of confusion and merge conflicts.
2. **Unused repository layer bypass** — `SleepPlannerPage`, `SQIPage`, and most features call `FirestoreService` directly instead of using their repository abstractions. The repository classes (`SleepPlannerRepository`, `SqiRepository`, etc.) are effectively dead code themselves.
3. **`pushReplacementNamed` back-stack bug** (now fixed at `home_page.dart:46`) — caused all non-home screens to exit the app on back press. Was present across 6 screens before the fix.
4. **`FirebaseService.initialize()` called redundantly** from both `main.dart` and every `FirebaseService` method call — wasted initialization overhead.

### Medium

5. **Empty CTA/navigation handlers** in HistoryPage, RecommendationPage — broken interactive elements.
6. **Ambient orbs** (`ImageFilter.blur(sigmaX: 50)`) on SplashPage and SQIResultPage — GPU-expensive, not in design spec.
7. **`HomeBody` feature grid** only shows 2 of 4 expected feature cards per design spec.
8. **Hardcoded user IDs** (`'default_user'`, `'local-user'`) throughout the codebase.
9. **No offline support** — Firestore operations will fail without connectivity.
10. **`suggestedBedtimes` route** defined in router but never navigated to.

### Low
11. **`AppTypography` references unused font families** (`Nunito` in header, `DM Sans` in body, but app uses `GoogleFonts.sora` and `GoogleFonts.inter` dynamically).
12. **`HomeRepository`** is an empty abstract class — wasted abstraction.
13. **`AppBarWidget`** exists at `core/presentation/widgets/app_bar.dart` but is unused — `setting_page.dart` and others use `AppBar()` directly.
14. **Duplicated error handling** in `SettingsRepository` save/load methods.
15. **`app_scaffold.dart`** file referenced but does not exist at `core/presentation/widgets/app_scaffold.dart`.
16. **Duplicate `theme` field** exists on both `User` model and `Settings` model with identical structure.

---

# 9. Recommended Next Steps

### Immediate (fix blocking issues)
1. **Merge or delete `sqi_screen.dart`** — remove legacy dual implementation to eliminate dead code and confusion.
2. **Wire up empty CTAs** in HistoryPage and RecommendationPage with functional `onTap` / `onPressed` handlers.
3. **Add firestore error handling** to `SleepPlannerPage._handleSave` and `SQIPage` submission flow with user-facing SnackBar or dialog.
4. **Remove ambient orbs** from `SplashPage` and `SQIResultPage` or reduce blur sigma per performance review.

### Short-term (next sprint)
5. **Consolidate Firestore access** — route all Firestore operations through `FirebaseService` (with initialization guard) instead of direct `FirestoreService` calls.
6. **Implement History data loading** from Firestore instead of hardcoded placeholders.
7. **Add loading states** to Sleep Planner save and SQI submission.
8. **Implement proper user authentication** or at minimum consistent user identity (avoid hardcoded IDs).
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
