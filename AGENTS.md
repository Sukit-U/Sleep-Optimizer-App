# Sleep-Optimizer-App — AGENTS.md

## Quick Commands

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d windows          # desktop, no emulator needed
flutter emulators --launch Medium_Phone
flutter run                      # after emulator boots
```

## Entrypoints & Navigation

- `lib/main.dart` — app bootstrap. Initializes Firebase, `StorageService`, and `appThemeMode` (global `late`).
- `lib/app/app.dart` — `SleepOptimizerApp`, root `MaterialApp`. Theme controlled by `Provider<ThemeProvider>`.
- `lib/app/router.dart` — `AppRouter.generateRoute` is the single navigator source of truth.

## Architecture

- Flutter single-package app. Features in `lib/features/<feature>/domain|data|presentation/`.
- Some legacy screens sit alongside the feature structure without migration:
  - `lib/features/sqi/sqi_screen.dart`
  - `lib/features/settings/settings_screen.dart`
  - `lib/features/history/history_screen.dart`
- State management: `provider` package only. No Riverpod, Bloc, or GetX.

## Critical Gotchas

- **Dependency compatibility**: `lucide_icons` is broken with Flutter 3.44.8 / Dart 3.12.2 (`IconData` is `final`). Use MaterialIcons (`Icons.*`) only.
- **Global state**: `appStorage` and `appThemeMode` are global `late` variables. Do not import `main.dart` trigger-ally; they are initialized before `runApp`.
- **Boot order**: `Firebase.initializeApp()` must complete before any Firebase call is made.
- **Theme tokens**: `AppTypography`, `AppColors`, `AppSpacing` in `lib/core/theme/` are the source of truth. Don't inline raw values unless the screen cannot use tokens.
- **Router**: No GoRouter. Routes are `String` constants in `AppRoutes`; case selection is raw `switch`. Adding a route requires adding it in both `AppRoutes` and `AppRouter.generateRoute`.
- **Back button after bottom nav**: The bottom nav uses `pushReplacementNamed` to switch tabs, which clears the back stack. `BackButton()` in an AppBar calls `Navigator.pop()`, which exits the app since there's no previous route. Non-home screens must use `Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false)` for their back action instead of default `BackButton()`.

## Tests

- 3 existing tests: `test/widget_test.dart`, `test/sqi_calculator_test.dart`, `test/sleep_planner_calculator_test.dart`
- Run all: `flutter test`
- No integration-test setup detected.

## Lint & Format

- `flutter analyze` is the gate. Uses `flutter_lints` defaults only.
- No custom lints, no `dart format` enforcement detected in config.

## Docs

- Business/functional specs live in `project/*.md` if implementation rationale is needed.
- Do not add machine learning, wearable integration, or medical-diagnosis features (project constraints).
