# Sleep Optimizer

## Overview

Sleep Optimizer is an educational mobile application that helps high school students improve their sleep habits through sleep planning and sleep quality assessment.

---

## Project Goal

The project aims to help students make better sleep decisions within real-life academic constraints by combining a Sleep Planner and a Sleep Quality Score (SQI).

The application focuses on education and behavior improvement rather than medical diagnosis or sleep tracking.

---

## AI Development Notes

When implementing this project:

- Read the documentation in the recommended order.
- Follow the Business Rules before implementing features.
- Keep all features consistent with the Functional Requirements.
- Do not introduce features outside the current project scope.
- Prioritize simplicity and maintainability.
- Reuse existing components whenever possible.
- Keep documentation synchronized when requirements change.
- Ask for clarification when requirements are ambiguous instead of making assumptions.

---

## Core Features

- Sleep Planner
- Sleep Quality Score (SQI)
- Personalized Recommendations
- History
- Settings

---

## Environments & Builds

The app has two build targets, and every command names the target with **both** a flavor and
`APP_ENV` — the flavor picks `android/app/src/<flavor>/google-services.json`, `APP_ENV` picks
the matching Dart Firebase config. See [docs/ENVIRONMENTS.md](docs/ENVIRONMENTS.md).

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

Against the local Firebase emulator suite (nothing leaves the machine):

```bash
firebase emulators:start --only auth,firestore --project=demo-snoozemate
flutter run --flavor dev --dart-define=APP_ENV=dev --dart-define=USE_FIREBASE_EMULATOR=true
```

Build prod (release signing comes from the gitignored `android/key.properties`; without it
the artifacts are unsigned):

```bash
flutter build apk --release --flavor prod --dart-define=APP_ENV=prod
flutter build appbundle --release --flavor prod --dart-define=APP_ENV=prod
```

Artifacts land at `build/app/outputs/flutter-apk/app-dev-debug.apk`,
`build/app/outputs/flutter-apk/app-prod-release.apk` and
`build/app/outputs/bundle/prodRelease/app-prod-release.aab`.

`APP_ENV` defaults to `dev`; any value other than `dev`/`prod` fails at startup with a
`StateError`. CI (`.github/workflows/ci.yml`) builds the dev debug APK, and
`.github/workflows/release.yml` builds the prod AAB + APK on `v*` tags.

---

## Planned Technology Stack

Frontend

- Flutter

Backend

- Firebase (planned)

Development Tools

- Figma
- Lovable
- Cline (Agentic AI Software Engineer)
- GitHub
- Git
- VS Code

---

## Project Constraints

- Educational Information Systems project.
- Three-member development team.
- Expected duration: 2–4 months.
- Mobile-first application.
- No machine learning.
- No wearable integration.
- No medical diagnosis.
- Focus on simple and explainable features.

---

## Documentation Guide

The project documentation is organized as follows:

| Document                | Purpose                  |
| ----------------------- | ------------------------ |
| App Specification       | Overall project overview |
| Business Rules          | Business logic           |
| Functional Requirements | System capabilities      |
| Recommendation Logic    | Recommendation algorithm |
| Data Model              | Logical data structure   |
| Database Design         | Database schema          |
| User Flows              | User interaction         |
| UI Guidelines           | Screen guidelines        |
| Design System           | Visual design rules      |

---

## Recommended Reading Order

Start reading in this order:

1. App Specification
2. Business Rules
3. Functional Requirements
4. Recommendation Logic
5. Data Model
6. Database Design
7. User Flows
8. UI Guidelines
9. Design System

---

## Project Structure

Sleep Optimizer/
│
├── .agents/
│   └── skills/
│       ├── algorithm-explanation/
│       ├── approval-gate/
│       ├── documentation-sync/
│       ├── firebase-development/
│       ├── flutter-development/
│       └── ui-review/
│
├── ai/
│   └── sleep_optimization_context.md
│
├── assets/
│
├── project/
│   ├── App-Specification.md
│   ├── Business-Rules.md
│   ├── Functional-Requirements.md
│   ├── Recommendation-Logic.md
│   ├── Data-Model.md
│   ├── Database-Design.md
│   ├── User-Flows.md
│   ├── UI-Guidelines.md
│   ├── Design-System.md
│
│
├── research/
│   └── SleepCycle_Analysis.md
│
├── .clinerules
└── README.md

---

## Current Status

- Documentation: ✅ Complete
- Research: ✅ Complete
- UI Design: ⏳ In Progress
- Development: ⏳ Not Started
- Testing: ⏳ Planned

## Repository Organization

This repository is organized into several main sections:

- project/ — Project documentation and specifications.
- ai/ — Project context shared with AI coding assistants.
- research/ — Supporting research and references.
- .cline/ — AI skills, development rules, and coding workflows for Cline.
- assets/ — Project assets.
- README.md — Repository overview and documentation entry point.
