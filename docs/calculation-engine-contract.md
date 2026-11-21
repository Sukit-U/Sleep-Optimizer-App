# Calculation Engine Contract

This document proposes a stable, platform-independent contract for future calculation engines. It covers API versioning, schemas, numeric behavior, and boundaries between Dart and potential native implementations.

---

## 1. Versioning

| Field | Value | Notes |
|-------|-------|-------|
| Contract Version | `1.0.0` | Semantic version for the contract itself |
| SQI Algorithm Version | `1.0.0` | Increment when formula/weights change |
| Recommendations Algorithm Version | `1.0.0` | Increment when mapping/priorities change |
| Planner Algorithm Version | `1.0.0` | Increment when cycle duration/options change |

Version numbers are returned with every calculation response for traceability.

---

## 2. Function Signatures (Logical Contract)

### 2.1 calculateSqi

**Input:**
```json
{
  "responses": {
    "Sleep duration": 0-5 (int),
    "Sleep regularity": 0-5 (int),
    "Screen time": 0-5 (int),
    "Exercise": 0-5 (int),
    "Stress": 0-5 (int),
    "Caffeine": 0-5 (int)
  }
}
```

**Output:**
```json
{
  "score": 0-100+ (int),
  "level": "excellent" | "good" | "fair" | "poor",
  "weakFactors": ["factor1", "factor2"],
  "factorScores": {
    "Sleep duration": 0-20+ (int),
    "Sleep regularity": 0-20+ (int),
    "Screen time": 0-15+ (int),
    "Exercise": 0-15+ (int),
    "Stress": 0-15+ (int),
    "Caffeine": 0-15+ (int)
  },
  "algorithmVersion": "1.0.0"
}
```

### 2.2 generateRecommendations

**Input:**
```json
{
  "weakFactors": ["factor1", "factor2", ...],
  "level": "excellent" | "good" | "fair" | "poor",
  "recordId": "string",
  "userId": "string"
}
```

**Output:**
```json
{
  "recommendations": [
    {
      "recommendationId": "",
      "userId": "string",
      "recordId": "string",
      "factor": "string",
      "title": "string",
      "description": "string",
      "action": "string",
      "priority": "critical" | "high" | "medium" | "low",
      "createdAt": "ISO8601 timestamp"
    }
  ],
  "algorithmVersion": "1.0.0"
}
```

### 2.3 calculatePlannerBedtimes

**Input:**
```json
{
  "wakeUpTime": "ISO8601 timestamp (local time)",
  "latencyMinutes": 0-45 (int)
}
```

**Output:**
```json
{
  "options": [
    {
      "cycles": 6,
      "bedtimeString": "h:mm AM/PM",
      "durationMinutes": 540
    },
    {
      "cycles": 5,
      "bedtimeString": "h:mm AM/PM",
      "durationMinutes": 450
    },
    {
      "cycles": 4,
      "bedtimeString": "h:mm AM/PM",
      "durationMinutes": 360
    }
  ],
  "algorithmVersion": "1.0.0"
}
```

---

## 3. Numeric Types and Behavior

| Aspect | Specification |
|--------|---------------|
| Integer type | 32-bit signed (Dart `int`, C++ `int32_t`) |
| Floating point | Not used in core calculations; all intermediate values are doubles in Dart, but final results are integers |
| Rounding | Dart `round()` (ties away from zero). In C++: `std::lround()` or equivalent |
| Division | `(value / 5.0) * weight` as double, then round. Not integer division. |
| Overflow | Score can exceed 100 if inputs > 5. No clamping. |
| Negative values | Accepted; factor scores can be negative. No clamping. |

---

## 4. Nullability and Optionality

| Field | Nullable | Default | Notes |
|-------|----------|---------|-------|
| All 6 SQI response keys | No | 0 if missing | Missing keys treated as 0 |
| `weakFactors` | No | [] | Empty list if no weak factors |
| `recordId` | Yes | "" | Empty string for new records |
| `userId` | Yes | "" | Empty string if not signed in |
| `latencyMinutes` | No | 15 (UI default) | Validated 0-45 |
| `wakeUpTime` | No | (required) | Must be valid DateTime |

---

## 5. Error Handling

| Condition | Dart Behavior | Contract Requirement |
|-----------|---------------|----------------------|
| Invalid latency (< 0 or > 45) | Throws `ArgumentError` | Return error code / optional |
| Missing wakeUpTime | N/A (required) | Return error |
| Unknown SQI level string | Returns empty recommendations | Return error or empty list |
| Unknown factor in weakFactors | Skipped silently | Skip unknown factors |

**Future C ABI:** Errors returned via out-parameter error code (0 = success, non-zero = error enum). No exceptions across FFI boundary.

---

## 6. String Encoding

- All strings: UTF-8
- Factor names: Exact match to English keys (case-sensitive)
- Level strings: Lowercase (`excellent`, `good`, `fair`, `poor`)
- Priority strings: Lowercase (`critical`, `high`, `medium`, `low`)

---

## 7. Memory Ownership (Future C ABI Considerations)

| Direction | Ownership | Notes |
|-----------|-----------|-------|
| Input strings | Caller owns | Callee must copy if needed |
| Output strings | Callee allocates | Caller must free via provided `free_fn` |
| Output arrays | Callee allocates | Caller must free array and elements |
| Opaque handles | Callee creates | Caller destroys via `destroy_fn` |

**Dart FFI boundary:** Use `Struct` with `Pointer<Utf8>` for strings. Provide `free_string` and `free_array` functions from native side.

---

## 8. Dart Model Conversion Boundaries

```
Dart Layer (UI/Repository)
       │
       ▼
┌─────────────────────────────────────┐
│  Domain Use Cases (Pure Dart)       │
│  - CalculateSqi                     │
│  - GenerateRecommendations          │
│  - CalculatePlannerBedtimes         │
└─────────────────────────────────────┘
       │
       ▼ (Future: FFI/WASM boundary)
┌─────────────────────────────────────┐
│  Adapter Layer                      │
│  - SqiEngineAdapter                 │
│  - RecommendationEngineAdapter      │
│  - PlannerEngineAdapter             │
└─────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│  Native Implementation              │
│  - Android: libsleepcore.so (FFI)   │
│  - Web: sleepcore.wasm (WASM)       │
└─────────────────────────────────────┘
```

**Current state:** All logic in Dart domain use cases. Adapter layer not yet implemented.

**Conversion rules:**
- Dart `DateTime` → ISO8601 string → C `const char*` → parse to `std::chrono::system_clock::time_point`
- Dart `Map<String, int>` → JSON string or flat key-value array
- Dart `List<BedtimeOption>` → array of structs

---

## 9. What is NOT in This Contract

- Firebase/Firestore integration
- Authentication or user management
- Provider/Flutter widgets
- Local storage (shared_preferences)
- Network retry logic
- UI formatting (handled in presentation layer)

---

## 10. Binary ABI vs JSON Buffer

**Recommendation:** Start with JSON-over-FFI/WASM for simplicity.
- Dart encodes input to JSON string
- Native decodes, computes, encodes output JSON string
- Dart decodes output

**Rationale:**
- Avoids complex struct layout synchronization
- Self-describing; version-tolerant
- Easier debugging and logging
- Performance acceptable for < 1ms calculations

**When to switch to binary ABI:**
- Profiling shows JSON overhead > 50% of latency
- Need zero-copy for large datasets (not applicable here)
- Strict real-time requirements emerge

---

## 11. Algorithm Versioning Strategy

Each calculation returns its `algorithmVersion`. The Dart adapter validates:
```dart
if (response.algorithmVersion != EXPECTED_VERSION) {
  // Log mismatch; fall back to Dart implementation
}
```

This allows:
- A/B testing new algorithms
- Safe rollout of native implementations
- Rollback without app update

---

## 12. Contract Stability Guarantees

| Change Type | Contract Version | Algorithm Version | Action |
|-------------|------------------|-------------------|--------|
| Bug fix (same output) | Patch | Unchanged | Safe |
| New optional output field | Minor | Unchanged | Backward compatible |
| Formula/weight change | Minor | Minor | Breaking; increment algorithm version |
| Input schema change | Major | Major | Breaking; new function name |
| Remove function | Major | Major | Breaking |

---

## 13. Traceability to Current Implementation

| Contract Function | Current Dart Implementation |
|-------------------|----------------------------|
| `calculateSqi` | `lib/features/sleep_quality/domain/usecases/calculate_sqi.dart` |
| `generateRecommendations` | `lib/features/recommendation/domain/usecases/generate_recommendations.dart` |
| `calculatePlannerBedtimes` | `lib/features/sleep_planner/domain/usecases/calculate_planner_bedtimes.dart` |

All three are pure functions with no external dependencies.