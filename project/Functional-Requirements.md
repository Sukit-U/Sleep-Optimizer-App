# Functional Requirements

## 1. Overview
This document defines the implemented functional capabilities of Snoozemate.

---

## 2. Functional Requirements

### FR-1: Sleep Planner
- **FR-1.1**: The system shall allow users to pick a wake-up time, set sleep latency (`0–45` minutes), and optionally set a ready-to-sleep time.
- **FR-1.2**: The system shall calculate bedtimes for `6`, `5`, and `4` 90-minute cycles.
- **FR-1.3**: The system shall evaluate bedtime feasibility against the optional ready-to-sleep time.
- **FR-1.4**: The system shall save the sleep plan to Cloud Firestore and local storage (`SharedPreferences`).

### FR-2: Sleep Quality Score (SQI)
- **FR-2.1**: The system shall display 6 sleep behavior questions rated from `1` to `5`.
- **FR-2.2**: The system shall require all 6 answers before submitting.
- **FR-2.3**: The system shall compute the weighted SQI score (`0–100`) and classify it (`poor`, `fair`, `good`, `excellent`).
- **FR-2.4**: The system shall save the SQI record to Cloud Firestore or fall back to local storage (`local_sqi_assessments`) with retry support when offline.

### FR-3: Recommendations
- **FR-3.1**: The system shall identify the 2 lowest-scoring factors from the SQI assessment (`weakFactors`).
- **FR-3.2**: The system shall generate recommendations via `GenerateRecommendations` based on `level` and `weakFactors`.
- **FR-3.3**: The system shall persist generated recommendations to the `recommendations` collection linked by `recordId` and `userId`.

### FR-4: History
- **FR-4.1**: The system shall display saved SQI records and sleep plans in a segmented list (`sqi` / `plans`).
- **FR-4.2**: The system shall display saved recommendations in a bottom sheet when an SQI record is tapped.
- **FR-4.3**: The system shall allow users to delete individual sleep plans and SQI records (with cascade deletion of linked recommendations) after confirmation.

### FR-5: Settings & Cloud Sync
- **FR-5.1**: The system shall allow users to toggle Dark Mode (`ThemeProvider`).
- **FR-5.2**: The system shall display Cloud Sync status and allow manual retry for pending sync items.
- **FR-5.3**: The system shall display app version and educational disclaimer in the About card.
