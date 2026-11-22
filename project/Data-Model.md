# Data Model

## 1. Overview
Logical data entities and relationships used by Snoozemate (`lib/models/`).

---

## 2. Entities

### 2.1 Settings (User Preferences)
- `userId` (String, Primary Key / Document ID): Firebase Auth UID
- `theme` (String): `'light'` or `'dark'`

### 2.2 SleepPlan (`lib/models/sleep_plan_model.dart`)
- `planId` (String, Primary Key)
- `userId` (String, Foreign Key)
- `wakeUpTime` (DateTime)
- `createdAt` (DateTime)
- `sleepCycles` (int)
- `suggestedBedtimes` (List<String>)
- Local-only metadata: `syncStatus` (`pending`, `synced`, `failed`), `cloudPlanId` (`String?`)

*Note: `SleepPlan` does not store a `sleepDuration` field in Firestore.*

### 2.3 SQIRecord (`lib/models/sqi_record_model.dart`)
- `recordId` (String, Primary Key)
- `userId` (String, Foreign Key)
- `sqiScore` (int, `0–100`)
- `sleepQualityLevel` (String: `'poor'`, `'fair'`, `'good'`, `'excellent'`)
- `questionnaireResponses` (Map<String, dynamic>)
- `createdAt` (DateTime)

### 2.4 Recommendation (`lib/models/recommendation_model.dart`)
- `recommendationId` (String, Primary Key)
- `userId` (String, Foreign Key)
- `recordId` (String, Foreign Key to `SQIRecord`)
- `factor` (String)
- `title` (String)
- `description` (String)
- `action` (String)
- `priority` (String: `'critical'`, `'high'`, `'medium'`, `'low'`)
- `createdAt` (DateTime)

---

## 3. Lifecycle Operations

- **SleepPlan & SQIRecord**: Created with new IDs (`newSleepPlanId`, `newSqiRecordId`) on each save/submission and can be deleted individually. Deleting an `SQIRecord` deletes its child `Recommendations` in a batch (`deleteSqiRecordWithRecommendations`).
- **Settings**: Created/updated at `settings/{userId}` with `allow delete: if false` in `firestore.rules`.
