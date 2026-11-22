# User Flows

## 1. Navigation Structure (`lib/app/router.dart`)

```
Splash / Welcome (/splash)
  └─ Continue (saves so.welcomeSeen) → Home (/)

Home (/)  [Bottom Nav Root]
  ├── Sleep Planner (/sleep-planner)
  ├── Sleep Quality (/sleep-quality) → RecommendationPage (pushed with SqiResult)
  ├── History (/history)
  └── Settings (/settings)
```

- Tapping a bottom nav tab calls `pushNamedAndRemoveUntil(route, (r) => r.isFirst)`. `HomePage` stays as the stack root.
- `/suggested-bedtimes` (`SuggestedBedtimesPage`) exists in `AppRouter` as a static placeholder screen and is not part of the active Sleep Planner flow.

---

## 2. Core Flows

### 2.1 Welcome Flow
1. App checks `so.welcomeSeen` on startup.
2. User taps **Continue** on `/splash`.
3. App saves `so.welcomeSeen = true` and navigates to `/` via `pushReplacementNamed`.

### 2.2 Sleep Planner Flow
1. User opens `/sleep-planner` from Home or the bottom nav.
2. User selects wake-up time, adjusts sleep latency (`0–45` min), optionally sets ready-to-sleep time, and optionally toggles constraint chips.
3. App updates `BedtimeOptionCard` results live inline (6, 5, and 4 cycles).
4. User taps the save button (`PlannerSaveButton`) to store the plan.

### 2.3 SQI & Recommendation Flow
1. User opens `/sleep-quality` and answers all 6 questions (`1–5`).
2. User taps the submit `FilledButton.icon`.
3. App computes `SqiResult`, saves the record (to Firestore or local queue if offline), and pushes `RecommendationPage(result: result)`.
4. User views the score ring, factor breakdown bars, and recommendation cards, then navigates to Home or History.

### 2.4 History Flow
1. User opens `/history`.
2. User switches between SQI Records (`sqi`) and Sleep Plans (`plans`).
3. Tapping an SQI card opens `showRecommendationSheet`; tapping delete opens a confirmation dialog (`confirmDeleteSqiRecord` / `confirmDeleteSleepPlan`).

### 2.5 Settings Flow
1. User opens `/settings`.
2. User toggles Dark Mode (`Switch`), views Cloud Sync status (with Retry when needed), or reads the About card.
