# Business Rules

## 1. Sleep Planner Rules

### 1.1 Purpose
Calculate bedtime options based on a target wake-up time using 90-minute sleep cycles and sleep latency.

### 1.2 Inputs
- **Wake-up Time** (`DateTime`, required)
- **Sleep Latency** (`int` in minutes, `0` to `45`; throws `ArgumentError` outside `0..45`)
- **Ready-to-Sleep Time** (`DateTime?`, optional; used by `EvaluateBedtimeFeasibility`)
- **Daily Constraint Chips** (UI selection chips on `SleepPlannerPage`)

### 1.3 Processing Rules (`CalculatePlannerBedtimes`)
- Supported cycle counts: `6`, `5`, `4` (90 minutes per cycle: `540`, `450`, `360` minutes).
- Formula: `bedtime = wakeUpTime.subtract(Duration(minutes: (cycles * 90) + latencyMinutes))`.
- Feasibility (`EvaluateBedtimeFeasibility`): When `readyToSleepTime` is provided, an option is feasible if `!bedtimeDateTime.isBefore(readyToSleepTime)`.

### 1.4 Outputs
- `BedtimeOption` list containing `cycles` (`6`, `5`, `4`), `bedtimeString` (`h:mm AM/PM`), `bedtimeDateTime`, and `durationMinutes`.

---

## 2. Sleep Quality Score (SQI) Rules

### 2.1 Assessment Factors & Weights (`CalculateSqi`)
| Factor Key | Weight | Input Range (UI & Rules) | Missing Key Default |
| --- | --- | --- | --- |
| `Sleep duration` | 20 | `1–5` (int) | `0` |
| `Sleep regularity` | 20 | `1–5` (int) | `0` |
| `Screen time` | 15 | `1–5` (int) | `0` |
| `Exercise` | 15 | `1–5` (int) | `0` |
| `Stress` | 15 | `1–5` (int) | `0` |
| `Caffeine` | 15 | `1–5` (int) | `0` |
| **Total** | **100** | | |

### 2.2 Formula
- Per-factor weighted score: `((value / 5) * weight).round()`
- Total SQI score: sum of all 6 rounded factor scores (`0–100`)
- Weak factors: the 2 lowest-scoring factors (`factorScores` sorted ascending, `.take(2)`).

### 2.3 Score Levels
- `excellent`: `>= 80`
- `good`: `60–79`
- `fair`: `40–59`
- `poor`: `0–39`

### 2.4 Validation Rules
- In `SleepQualityPage`, all 6 questions must be answered (`1–5`) before submission.
- `firestore.rules` enforces all 6 exact keys with integer values `1..5` on write.

---

## 3. Data & Security Rules

- Every Firestore document (`sleepPlans`, `sqiRecords`, `recommendations`, `settings`) is scoped to `request.auth.uid`.
- `createdAt` and `userId` are immutable after creation.
- `settings/{userId}` cannot be deleted (`allow delete: if false`).
