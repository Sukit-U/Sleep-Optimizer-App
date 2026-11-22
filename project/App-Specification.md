# App Specification

## 1. Overview

### Purpose
Snoozemate helps high school students make better sleep decisions and build healthier sleep habits.

### Target Users
High school students (15–18 years old) who experience insufficient sleep due to academic and daily-life constraints.

### Core Value
The app helps students plan realistic bedtimes and understand daily behaviors that affect sleep quality.

---

## 2. Problem Statement

### Current Situation
High school students often face heavy homework, extracurricular activities, and tutoring classes. Returning home late reduces time for adequate sleep.

### Problem
Students struggle to manage bedtime schedules and often maintain habits such as late-night screen use, caffeine intake, and irregular sleep schedules.

### Impact
- Reduced sleep quality and daytime drowsiness.
- Reduced concentration and lower academic performance.
- Irregular sleep schedules over time.

---

## 3. Scope

### In Scope
- Sleep Planner (6, 5, and 4 cycles of 90 minutes, configurable latency 0–45 minutes, feasibility check)
- Sleep Quality Score (SQI) across 6 weighted factors
- Personalized Recommendations
- History (SQI records and saved sleep plans)
- Settings (Dark Mode toggle, Cloud Sync status/retry, About)
- Anonymous Firebase Authentication and offline local fallback

### Out of Scope
- Sleep stage tracking
- Medical diagnosis
- Wearable integration
- Machine learning

---

## 4. Core Features

### 4.1 Sleep Planner
Calculates bedtime options from a target wake-up time using 90-minute cycles (`6`, `5`, and `4` cycles) plus user-selected sleep latency (`0` to `45` minutes). Optionally checks feasibility against a "ready to sleep" time and allows saving the plan.

### 4.2 Sleep Quality Score (SQI)
Evaluates six sleep-related behavior factors (`1–5` scale in the UI), computes a weighted score from `0` to `100`, and classifies it as `poor`, `fair`, `good`, or `excellent`.

### 4.3 Recommendations
Selects actionable advice cards based on the SQI level and lowest-scoring factors.

### 4.4 History
Displays saved SQI records and sleep plans. Users can inspect past recommendation details and delete individual records.

### 4.5 Settings
- Dark Mode toggle (`ThemeProvider`)
- Cloud Sync status indicator and manual retry
- About card with app metadata

---

## 5. System Workflow & Localization

- **Locale**: The app currently runs in Thai (`Locale('th')` locked in `SnoozefriendApp` and `LocaleProvider`), while `AppLocalizations` contains both `'en'` and `'th'` maps.
- **Sleep Planner Flow**: Welcome (`/splash`) → Home (`/`) → Sleep Planner (`/sleep-planner`) with live inline calculation → Save plan. *(Note: `/suggested-bedtimes` exists in `AppRouter` as a static placeholder route.)*
- **SQI Flow**: Home (`/`) → Sleep Quality (`/sleep-quality`) → `RecommendationPage` (pushed with `SqiResult`) → Home (`/`) or History (`/history`).

---

## 6. Non-Functional Requirements

- **Performance**: Bedtime and SQI calculations run synchronously on-device.
- **Compatibility**: Supports Android (`dev`/`prod` flavors), iOS, and Web (`web/` directory present).
- **Privacy**: Uses anonymous Firebase Auth UIDs (`AuthService`). `firestore.rules` restricts every collection to the owning `request.auth.uid`.
