# Calculation Specification

This document describes the actual source behavior of the calculation modules in the Sleep-Optimizer-App. Every rule is traced to a source file and function.

## Notation

- **Verified** — observed directly in source code
- **Inferred** — deduced from behavior but not explicitly stated
- **Undefined** — behavior not verified or not handled

---

## A. SQI Calculation

**Source:** `lib/features/sleep_quality/domain/usecases/calculate_sqi.dart` — `CalculateSqi.call()`

### A.1 Input Keys and Accepted Values

| Key | Weight | Accepted Values | Notes |
|-----|--------|-----------------|-------|
| Sleep duration | 20 | 0–5 (int) | Missing key → 0 |
| Sleep regularity | 20 | 0–5 (int) | Missing key → 0 |
| Screen time | 15 | 0–5 (int) | Missing key → 0 |
| Exercise | 15 | 0–5 (int) | Missing key → 0 |
| Stress | 15 | 0–5 (int) | Missing key → 0 |
| Caffeine | 15 | 0–5 (int) | Missing key → 0 |

**Verified:** Lines 7–14, 18–20. The `factors` map defines the six keys and weights. Missing keys default to 0 via `responses[entry.key] ?? 0`.

**Inferred:** Input values outside 0–5 are not clamped; they are used as-is in the formula.

### A.2 Factor Weights

| Factor | Weight |
|--------|--------|
| Sleep duration | 20 |
| Sleep regularity | 20 |
| Screen time | 15 |
| Exercise | 15 |
| Stress | 15 |
| Caffeine | 15 |
| **Total** | **100** |

**Verified:** Lines 7–14.

### A.3 Score Calculation Formula

For each factor:
```
weightedValue = round((responseValue / 5) * weight)
```

Total score:
```
score = sum of all weightedValues
```

**Verified:** Lines 18–22, 32. Integer division is not used; `(value / 5)` produces a double, then multiplied by weight, then `.round()`.

**Inferred:** Rounding uses Dart's `round()` (ties away from zero).

### A.4 Rounding Behavior

- Per-factor: `((value / 5) * weight).round()` — **Verified** (line 20)
- Total score: sum of already-rounded integers — **Verified** (line 32)
- No additional rounding on total

### A.5 Score Range

- Minimum: 0 (all responses 0)
- Maximum: 100 (all responses 5)

**Verified:** By inspection of formula. Each factor max = `round((5/5) * weight)` = weight. Sum of weights = 100.

### A.6 Level Thresholds

| Level | Score Range |
|-------|-------------|
| Excellent | ≥ 80 |
| Good | 60–79 |
| Fair | 40–59 |
| Poor | ≤ 39 |

**Verified:** Lines 44–55 (`_mapLevel`).

### A.7 Weak-Factor Selection

1. Sort all 6 factors by weighted score ascending (lowest first)
2. Take first 2 factors
3. Return their keys as `List<String>`

**Verified:** Lines 24–30. Uses `List.sort` with `a.value.compareTo(b.value)` (ascending).

**Inferred (tie behavior):** `List.sort` is not stable in Dart. When two factors have equal weighted scores, their relative order is **undefined**. The current implementation does not specify a tiebreaker.

**Test evidence:** `test/generate_recommendations_test.dart` lines 181–182 explicitly note: "Maps are chosen so the two lowest factor scores are strictly distinct, making weakFactors deterministic (List.sort is not stable)."

### A.8 Invalid or Missing Input Behavior

- Missing key → treated as 0 (line 19)
- Extra keys in input → ignored (only the 6 defined factors are processed)
- Non-integer values → not handled (Dart type system prevents at compile time)
- Null responses map → would throw (not guarded)

**Verified:** Lines 7–20.

---

## B. Recommendation Engine

**Source:** `lib/features/recommendation/domain/usecases/generate_recommendations.dart` — `GenerateRecommendations.call()`

### B.1 Input Parameters

| Parameter | Type | Required | Notes |
|-----------|------|----------|-------|
| weakFactors | `List<String>` | Yes | From SQI calculation |
| level | `String` | Yes | One of: 'excellent', 'good', 'fair', 'poor' |
| recordId | `String` | No | Default: '' |
| userId | `String` | No | Default: '' |

**Verified:** Lines 86–91.

### B.2 Factor-to-Recommendation Mapping

| Factor | Title | Description | Action | Priority |
|--------|-------|-------------|--------|----------|
| Sleep duration | Aim for a consistent bedtime | A stable sleep schedule helps your body recover more efficiently. | Set a fixed bedtime and wake-up time. | High |
| Sleep regularity | Keep a steady rhythm | Regular sleep timing strengthens your sleep quality over time. | Stick to the same wake-up time each day. | Critical |
| Screen time | Reduce late screen exposure | Blue light can delay your sleep onset and reduce night-time rest. | Put your phone away 30 minutes before bed. | High |
| Exercise | Add light activity earlier in the day | Physical activity can improve your sleep readiness and energy balance. | Take a short walk or stretch earlier in the day. | Medium |
| Stress | Create a simple wind-down routine | A calm routine can reduce stress and support better sleep. | Try breathing exercises or journaling before bed. | Critical |
| Caffeine | Cut back on late caffeine | Caffeine can stay in your system and disrupt sleep. | Avoid caffeine at least 6 hours before bed. | High |

**Verified:** Lines 18–59 (`_factorMap`).

### B.3 Positive Reinforcement (Excellent Level)

| Field | Value |
|-------|-------|
| Title | Keep up the great habits! |
| Description | Your sleep habits are excellent — maintaining them will help you stay rested and perform at your best. |
| Action | Continue with your current sleep routine and share your good habits with friends. |
| Priority | Low |

**Verified:** Lines 62–69 (`_positiveReinforcement`).

### B.4 Output Model Fields

`Recommendation` (`lib/models/recommendation_model.dart` lines 9–33):
- `recommendationId` — document ID (empty for new)
- `userId` — owner UID
- `recordId` — FK to SQI record
- `factor` — factor name or 'General'
- `title` — recommendation title
- `description` — recommendation description
- `action` — actionable advice
- `priority` — 'critical' | 'high' | 'medium' | 'low'
- `createdAt` — timestamp (immutable in Firestore rules)

### B.5 Ordering Behavior

1. **Excellent**: Single positive reinforcement (priority: low)
2. **Good**: Single recommendation for `weakFactors.first` only
3. **Fair/Poor**: Up to 3 recommendations, in order of `weakFactors` (which is sorted by SQI score ascending), capped at 3

**Verified:** Lines 92–149.

**Inferred:** The order of recommendations for Fair/Poor follows the weak-factor order (lowest score first). Since weak-factor sort is unstable for ties, recommendation order for tied factors is also undefined.

### B.6 Conditions Affecting Output

- `level == 'excellent'` → ignores `weakFactors`, returns positive reinforcement only
- `level == 'good'` && `weakFactors.isNotEmpty` → returns only first weak factor
- `level == 'good'` && `weakFactors.isEmpty` → returns empty list
- Unknown factor names in `weakFactors` → skipped silently (line 132–133)
- Max 3 recommendations total (documented limit, line 11)

**Verified:** Lines 92–149.

---

## C. Sleep Planner

**Source:** `lib/features/sleep_planner/domain/usecases/calculate_planner_bedtimes.dart` — `CalculatePlannerBedtimes.call()`

### C.1 Supported Cycle Counts

| Cycles | Duration (min) |
|--------|----------------|
| 6 | 540 (9 hours) |
| 5 | 450 (7.5 hours) |
| 4 | 360 (6 hours) |

**Verified:** Lines 12, 22–23. Hardcoded list `[6, 5, 4]` in that order.

### C.2 Cycle Duration

- 90 minutes per cycle — **Verified** (line 13)

### C.3 Latency Handling

- Input: `latencyMinutes` (int)
- Range: 0–45 inclusive — **Verified** (lines 14, 18–20)
- Added to total sleep time: `totalMinutes = (cycles * 90) + latencyMinutes` — **Verified** (line 23)
- Default in UI: 15 minutes — **Verified** (`sleep_planner_page.dart` line 29)

### C.4 Input/Output Semantics

**Input:**
- `wakeUpTime: DateTime` — exact wake-up time (date component used for rollover)
- `latencyMinutes: int` — time to fall asleep

**Output:** `List<BedtimeOption>` with:
- `cycles: int` — 6, 5, or 4
- `bedtimeString: String` — formatted as "h:mm AM/PM" (12-hour)
- `durationMinutes: int` — cycles * 90 (excludes latency)

**Verified:** Lines 21–30, `BedtimeOption` entity.

### C.5 Date Rollover Behavior

- `DateTime.subtract(Duration)` handles rollover automatically
- Example: wakeUp 1:00 AM, 6 cycles → bedtime 4:00 PM previous day
- The date component of `wakeUpTime` is preserved in calculation

**Verified:** Line 24 uses `wakeUpTime.subtract(Duration(minutes: totalMinutes))`. Dart's `DateTime` handles day/month/year boundaries correctly.

**Inferred:** Only the time-of-day is displayed (via `_formatTime`), but the full DateTime is used for calculation. If wakeUpTime is 1:00 AM Jan 15, bedtime for 6 cycles shows "4:00 PM" (Jan 14).

### C.6 Assumptions from Existing Implementation

| Assumption | Status |
|------------|--------|
| 90-minute cycle heuristic predicts sleep stages | **Not claimed** — heuristic only |
| Fixed cycle counts (6, 5, 4) cover user needs | **Verified** — hardcoded |
| Latency 0–45 minutes covers realistic range | **Verified** — UI slider max 45 |
| Bedtime display uses 12-hour format | **Verified** — `_formatTime` |
| No timezone handling | **Verified** — uses local DateTime |
| No validation of wakeUpTime being in future | **Verified** — not checked |

**Note:** The 90-minute cycle heuristic is a simplified model. Actual sleep cycles vary (70–110 min), and the first cycle is often shorter. The app does not claim scientific validity.

---

## Cross-References

- SQI calculation ↔ Recommendation: `weakFactors` + `level.name` passed to `GenerateRecommendations`
- Sleep Planner ↔ SQI: No direct coupling (separate features)
- All calculations are pure functions with no side effects
- No Firebase, Firestore, Provider, or Flutter dependencies in calculation logic

---

## Version

This specification reflects the codebase as of commit `main` (post Phase 1 Stage A extraction).
Algorithm version: `1.0.0` (SQI), `1.0.0` (Recommendations), `1.0.0` (Planner)