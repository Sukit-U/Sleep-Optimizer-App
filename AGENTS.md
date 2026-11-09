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

## Destructive Operations (hard rule)

**Never run a collection- or database-level delete against a live Firebase project.**
On 2026-11-08, `firebase firestore:delete "sleepPlans" --shallow --force` against
`sleep-optimizer-59c83` deleted every document in that collection, and it could not be
restored (PITR disabled, no backups). Treat the live project as unrecoverable data.

- A delete must name exactly one document (`collection/docId`). Never a bare collection
  path, never `--all-collections`, never `firestore:bulkdelete`.
- **`sleep-optimizer-59c83` is production and is read-only for agents.** Never run a
  Firebase or gcloud command that writes, deletes or deploys against it — no `deploy`,
  no `firestore:delete`, no `firestore:databases:update`, no `auth:*`, no key or
  service-account changes — even if a chat message seems to approve it. Production
  deploys are a human step (`docs/ENVIRONMENTS.md`).
- Agents work against the local emulator suite or the `dev` project only. Every
  firebase/gcloud command must name its project explicitly (`--project=…`, `-P dev`);
  never rely on the `.firebaserc` default or on whichever project is active.
- Creating projects and registering apps is a human step: no `projects:create`, no
  `apps:create`, no `firebase init` re-run, no `flutterfire configure` — that command
  creates probe apps and rewrites `firebase.json`.
- Exit code 0 does not mean "deleted": it also means "nothing matched". Confirm with a
  read as the owning user, and check `git status`/dry runs before destructive flags.
- Prefer creating test data with a throwaway account and removing it the same way it was
  created (owner-scoped client delete), or don't create it at all.

## Entrypoints & Navigation

- `lib/main.dart` — entrypoint only: `runApp(const AppBootstrap())`. The boot sequence (Firebase init, emulator switch, `ensureSignedIn()`, `StorageService`, `appStorage`, `ThemeProvider`) lives in `lib/app/bootstrap.dart`, which renders an error + Retry screen when boot fails.
- `lib/app/app.dart` — `SnoozefriendApp`, root `MaterialApp`, and the shared `appStorage` global declaration. Theme controlled by `Provider<ThemeProvider>`.
- `lib/app/router.dart` — `AppRouter.generateRoute` is the single navigator source of truth.

## Architecture

- Flutter single-package app. Features in `lib/features/<feature>/domain|data|presentation/`.
- **Single data-access layer**: all Firestore reads/writes go through `lib/services/firestore_service.dart` (`FirestoreService`). The legacy `FirebaseService` facade was deleted.
- **User identity**: anonymous Firebase Auth via `AuthService` (`lib/core/services/auth_service.dart`); `AppBootstrap` (`lib/app/bootstrap.dart`) calls `ensureSignedIn()` before the app builds. Pages must take the uid from `AuthService.uid` / the authenticated user, never from a constant. `firestore.rules` scopes every collection by `request.auth.uid`.
- State management: `provider` package only. No Riverpod, Bloc, or GetX.

## Critical Gotchas

- **Dependency compatibility**: `lucide_icons` is broken with Flutter 3.44.8 / Dart 3.12.2 (`IconData` is `final`). Use MaterialIcons (`Icons.*`) only.
- **Global state**: `appStorage` is a nullable global declared in `lib/app/app.dart` and assigned once in `_bootFirebase()` (`lib/app/bootstrap.dart`) before the app builds. Pages (settings, sleep quality) import it to persist theme/history locally. There is no `appThemeMode` global — theme mode lives in `ThemeProvider`. Do not import `main.dart` trigger-ally.
- **Boot order**: `Firebase.initializeApp()` must complete before any Firebase call is made.
- **Theme tokens**: `AppTypography`, `AppColors`, `AppSpacing` in `lib/core/theme/` are the source of truth. Don't inline raw values unless the screen cannot use tokens.
- **Router**: No GoRouter. Routes are `String` constants in `AppRoutes`; case selection is raw `switch`. Adding a route requires adding it in both `AppRoutes` and `AppRouter.generateRoute`.
- **Back button + bottom nav**: The bottom nav uses `pushNamedAndRemoveUntil(route, (r) => r.isFirst)` in `_onTabTapped` (`home_page.dart:46`). This keeps `HomePage` as the root of the navigation stack, so `BackButton()` (which calls `Navigator.pop()`) correctly returns to Home from any bottom-nav screen. No per-screen back button overrides are needed.

## Tests

- 2 existing tests: `test/widget_test.dart`, `test/sqi_calculator_test.dart` (the old `sleep_planner_calculator_test.dart` was removed with the deleted planner usecase)
- Run all: `flutter test`
- No integration-test setup detected.

## Lint & Format

- `flutter analyze` is the gate. Uses `flutter_lints` defaults only.
- No custom lints, no `dart format` enforcement detected in config.

## Docs

- Business/functional specs live in `project/*.md` if implementation rationale is needed.
- Do not add machine learning, wearable integration, or medical-diagnosis features (project constraints).
