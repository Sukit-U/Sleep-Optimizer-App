# UI Guidelines

## 1. Overview
Snoozemate uses a dark-first, low-glare interface constrained to `min(448.0, screenWidth - 32)` on `HomePage`. The app is currently locked to Thai (`Locale('th')`).

---

## 2. Navigation Guidelines
- Initial route: `/splash` (`SplashPage`), advancing to `/` on **Continue**.
- Bottom navigation: Floating pill bar at the bottom of `HomePage` with 5 tabs (`home`, `sleepPlanner`, `sleepQuality`, `history`, `settings`).
- `RecommendationPage` is not a named route; `SleepQualityPage` pushes it directly with an `SqiResult`.

---

## 3. Screen Guidelines

### 3.1 Welcome (`SplashPage` — `/splash`)
- Single `Icons.nightlight_round` icon in primary color.
- Wordmark `"Snoozemate"` (`Kanit`), one-line summary, educational disclaimer, and a full-width **Continue** button (52 px height, 14 px radius).

### 3.2 Home (`HomePage` / `HomeBody` — `/`)
- Greeting header with date.
- `TonightSuggestionCard` showing latest planned bedtime.
- 2-column `HomeFeatureCard` grid linking to **Sleep Planner** and **Sleep Quality**.
- `LatestScoreSection` showing the latest SQI score.

### 3.3 Sleep Planner (`SleepPlannerPage` — `/sleep-planner`)
- `PopScope` discard confirmation when unsaved edits exist.
- Wake-up time picker, latency slider (`0–45` min), optional ready-to-sleep time picker, 5 constraint chips, live `BedtimeOptionCard` list, and `PlannerSaveButton`.

### 3.4 Sleep Quality (`SleepQualityPage` — `/sleep-quality`) & `RecommendationPage`
- `PopScope` discard confirmation; 6 `SQIQuestionCard` items (`1–5` `ChoiceChip`s); `FilledButton.icon` submit; `OutlinedButton.icon` to view last result.
- `RecommendationPage`: circular back button header, 160 px `CircularProgressIndicator` score ring, factor breakdown bars, recommendation cards, and Home / History buttons.

### 3.5 History (`HistoryPage` — `/history`)
- Segmented pill control (`sqi` / `plans`), `SQIRecordCard`, `HistorySleepPlanCard`, `EmptyStateCard`, `ErrorStateWidget`, and delete confirmation dialogs.

### 3.6 Settings (`SettingsPage` — `/settings`)
- Dark Mode `Switch` card, Cloud Sync status card (with conditional Retry `TextButton`), and About card.
