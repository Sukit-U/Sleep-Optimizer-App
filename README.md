# Sleep Optimizer (Snoozemate)

## Overview

Snoozemate is a Flutter mobile application for high school students. It helps students plan bedtimes and assess daily sleep habits.

---

## Project Goal

The app helps students make practical sleep decisions within academic constraints. It combines a Sleep Planner and a Sleep Quality Score (SQI).

The app focuses on education and habit improvement. It does not provide medical diagnosis or sleep tracking.

---

## Core Features

- **Sleep Planner**: Calculates bedtimes for 6, 5, and 4 cycles (90 minutes each) with configurable sleep latency (0–45 minutes) and feasibility checks.
- **Sleep Quality Score (SQI)**: Assesses sleep behaviors across six weighted factors (0–100 scale).
- **Personalized Recommendations**: Generates actionable tips based on SQI level and weak factors.
- **History**: Displays saved SQI records and sleep plans from Cloud Firestore and local storage.
- **Settings**: Provides Dark Mode toggle, Cloud Sync status with retry, and About info.

---

## Technology Stack

- **Framework**: Flutter (Dart SDK `^3.12.2`)
- **State Management**: `provider` (`^6.1.5+1`)
- **Backend & Database**: `firebase_core` (`^5.1.0`), `cloud_firestore` (`^7.1.0`), `firebase_auth` (`^7.0.1`), `firebase_app_check` (`^0.5.1`)
- **Authentication**: Anonymous Firebase Auth managed by `AuthService`. Firestore rules scope every collection by `request.auth.uid`.
- **Data Access Layer**: All Firestore reads and writes go through `FirestoreService` (`lib/services/firestore_service.dart`).
- **Local Storage**: `shared_preferences` (`^2.5.6`)
- **Typography & Icons**: Bundled `Kanit` font (`assets/fonts/Kanit-*.ttf`) and Material Icons (`Icons.*`) / `cupertino_icons`.

---

## Environments & Builds

The app defines two build targets. Every command must specify both `--flavor` and `--dart-define=APP_ENV`. See [docs/ENVIRONMENTS.md](docs/ENVIRONMENTS.md).

| Target | Firebase project | Flags |
| --- | --- | --- |
| dev (default) | `sleep-optimizer-dev` | `--flavor dev --dart-define=APP_ENV=dev` |
| prod | `sleep-optimizer-59c83` | `--flavor prod --dart-define=APP_ENV=prod` |

Run and build dev:

```bash
flutter pub get
flutter run --flavor dev --dart-define=APP_ENV=dev
flutter build apk --debug --flavor dev --dart-define=APP_ENV=dev
```

Run against the local Firebase emulator suite:

```bash
firebase emulators:start --only auth,firestore --project=demo-snoozemate
flutter run --flavor dev --dart-define=APP_ENV=dev --dart-define=USE_FIREBASE_EMULATOR=true
```

Build prod (requires `android/key.properties` for release signing):

```bash
flutter build apk --release --flavor prod --dart-define=APP_ENV=prod
flutter build appbundle --release --flavor prod --dart-define=APP_ENV=prod
```

Artifacts output to `build/app/outputs/flutter-apk/` and `build/app/outputs/bundle/prodRelease/`.

`APP_ENV` defaults to `dev`. Any value other than `dev` or `prod` throws a `StateError` at startup.

---

## Project Constraints

- Educational Information Systems project for high school students (15–18 years old).
- Mobile-first targets (`android/`, `ios/`, `web/`).
- No machine learning.
- No wearable integration.
- No medical diagnosis.

---

## Repository Structure

```
Sleep-Optimizer-App/
├── .agents/                  # Agent skills and configuration
├── .github/workflows/        # CI (ci.yml) and release (release.yml) pipelines
├── android/                  # Android native project with dev/prod flavors
├── assets/                   # Bundled Kanit fonts and assets
├── docs/                     # Environment, App Check, calculation, and ops docs
├── firestore-rules-test/     # Emulator test suite for firestore.rules
├── ios/                      # iOS native project
├── lib/
│   ├── app/                  # Bootstrap, environment selection, and AppRouter
│   ├── core/                 # Theme tokens, l10n, providers, and services
│   ├── features/             # home, history, recommendation, settings, sleep_planner, sleep_quality, splash
│   ├── models/               # Data models and Firestore read parsers
│   ├── services/             # FirestoreService (single Firestore access layer)
│   └── shared/               # Formatters and reusable UI widgets
├── project/                  # Product and design specifications
├── scripts/                  # Release versioning and Firestore migration scripts
├── test/                     # 37 Dart/Flutter test files (*_test.dart)
├── web/                      # Web target files
├── firestore.rules           # Security rules scoping data by request.auth.uid
└── pubspec.yaml              # Package dependencies and font assets
```

---

## Verification & CI

Run formatting, static analysis, and all tests:

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```
