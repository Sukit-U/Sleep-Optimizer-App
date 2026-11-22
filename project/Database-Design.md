# Database Design

## 1. Overview
Snoozemate uses **Cloud Firestore** for cloud persistence and **SharedPreferences** for local caching and offline fallback. All Firestore reads and writes pass through `FirestoreService` (`lib/services/firestore_service.dart`).

---

## 2. Firestore Collections (`firestore.rules`)

*Note: There is no `users` collection; user settings live in `settings/{userId}`.*

### 2.1 `settings/{userId}`
- **Document ID**: Firebase Auth UID (`userId == request.auth.uid`)
- **Fields**: `userId` (string <= 100), `theme` (`'light'` or `'dark'`)
- **Rules**: Owner read, create, update; `allow delete: if false`.

### 2.2 `sleepPlans/{planId}`
- **Fields**:
  - `userId` (string 1..100, immutable)
  - `wakeUpTime` (timestamp)
  - `createdAt` (timestamp, immutable)
  - `sleepCycles` (int 1..10)
  - `suggestedBedtimes` (list 1..10 strings 1..100; parser expects 3 entries for `SleepPlanValid`)
- **Rules**: Authenticated owner CRUD (`userId == request.auth.uid`).

### 2.3 `sqiRecords/{recordId}`
- **Fields**:
  - `userId` (string 1..100, immutable)
  - `sqiScore` (int 0..100)
  - `sleepQualityLevel` (`'poor' | 'fair' | 'good' | 'excellent'`)
  - `questionnaireResponses` (map with exact 6 keys, int `1..5`)
  - `createdAt` (timestamp, immutable)
- **Rules**: Authenticated owner CRUD.

### 2.4 `recommendations/{recommendationId}`
- **Fields**:
  - `userId` (string 1..100, immutable)
  - `recordId` (string 1..100, immutable)
  - `factor` (string 1..200)
  - `title` (string 1..200)
  - `description` (string 1..2000)
  - `action` (string 1..2000)
  - `priority` (`'critical' | 'high' | 'medium' | 'low'` or TitleCase variants)
  - `createdAt` (timestamp, immutable)
- **Rules**: Read requires `resource.data.userId == auth.uid`. Create/update require matching `userId` and ownership of parent `sqiRecords/$(recordId)`. Delete requires parent ownership.

### 2.5 Default Rule
- `/{document=**}` denies all other reads and writes.

---

## 3. Local Storage Keys (`SharedPreferences`)
- `StorageService`: `'theme'`, `'app_locale'` (saved as `'th'`), `'local_sleep_plans'`, `'deleted_sleep_plan_ids'`, `'local_sqi_assessments'`, `'sqi_history'`, `'so.welcomeSeen'`.
- `PendingThemeStorage`: `'pending_settings_theme'`, `'pending_settings_user'`.
