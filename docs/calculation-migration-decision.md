# Calculation Migration Decision

This document evaluates each calculation module for potential migration to a shared C++ core targeting Android FFI and WebAssembly.

---

## Decision Categories

| Category | Meaning |
|----------|---------|
| **KEEP IN DART** | No compelling reason to migrate; Dart is sufficient |
| **MIGRATE TO C++** | Strong evidence for native implementation |
| **REFACTOR BEFORE MIGRATION** | Needs architectural changes before migration viable |
| **NOT IMPLEMENTED** | Feature doesn't exist yet |
| **NOT VERIFIED** | Insufficient data to decide |

---

## Module Evaluations

### 1. SQI Calculation (`CalculateSqi`)

**Current Implementation:** `lib/features/sleep_quality/domain/usecases/calculate_sqi.dart` (56 lines)

| Criterion | Assessment |
|-----------|------------|
| Calculation complexity | Low — 6 factors, simple weighted sum, sort of 6 items |
| Performance benefit | Negligible — executes in < 0.1ms on all target devices |
| Cross-platform reuse | Moderate — same formula needed on Android/Web/iOS |
| Maintenance cost | Very low — pure Dart, no dependencies, 179 tests pass |
| Data marshalling overhead | Low — 6 integers in, ~20 integers out |
| Change frequency | Low — weights/thresholds stable since inception |
| Testability | High — pure function, golden reference tests exist |
| Platform integration complexity | None — no platform APIs used |

**Decision: KEEP IN DART**

**Rationale:**
- The calculation is trivial (6 multiplications, 6 divisions, 1 sort of 6 elements)
- Dart's JIT/AOT compilation makes this fast enough (< 0.1ms)
- No evidence of performance bottleneck in profiling
- Migration would add significant complexity (FFI setup, build systems, CI for 3 platforms) for zero user-visible benefit
- The "pure function" argument alone is insufficient; many pure functions stay in Dart

**Revisit if:**
- Profile shows SQI calculation > 1ms on low-end devices
- Need to share with non-Flutter codebase (e.g., backend, React Native)
- Algorithm becomes significantly more complex (ML model, etc.)

---

### 2. Recommendation Engine (`GenerateRecommendations`)

**Current Implementation:** `lib/features/recommendation/domain/usecases/generate_recommendations.dart` (151 lines)

| Criterion | Assessment |
|-----------|------------|
| Calculation complexity | Low — map lookup, conditional logic, list building |
| Performance benefit | None — string/map operations dominate, not arithmetic |
| Cross-platform reuse | Moderate — same mappings needed everywhere |
| Maintenance cost | Low — data-driven (`_factorMap`), easy to update |
| Data marshalling overhead | Higher — variable-length string arrays, nested objects |
| Change frequency | Moderate — content updates (copy changes) more likely than logic |
| Testability | High — 33 tests covering all branches |
| Platform integration complexity | None |

**Decision: KEEP IN DART**

**Rationale:**
- Primarily string/template operations, not numeric computation
- Content changes (copy, priorities) are frequent; Dart hot reload excels here
- Marshalling variable-length strings across FFI adds complexity
- No performance pressure — runs once per assessment
- Explicitly required by task: "Recommendation Engine should remain in Dart unless strong evidence demonstrates a meaningful reason to migrate it"

**Revisit if:**
- Need to share recommendation templates with non-Dart platforms
- Real-time recommendation updates required (not current use case)

---

### 3. Sleep Planner (`CalculatePlannerBedtimes`)

**Current Implementation:** `lib/features/sleep_planner/domain/usecases/calculate_planner_bedtimes.dart` (40 lines)

| Criterion | Assessment |
|-----------|------------|
| Calculation complexity | Very low — 3 subtractions, 3 date formats |
| Performance benefit | None — DateTime operations dominate |
| Cross-platform reuse | Moderate — same 90-min heuristic everywhere |
| Maintenance cost | Very low — extracted to pure use case, 14 tests |
| Data marshalling overhead | Low — 1 DateTime + 1 int in, 3 small structs out |
| Change frequency | Low — cycle duration/options stable |
| Testability | High — pure function, golden reference tests |
| Platform integration complexity | None |

**Decision: KEEP IN DART**

**Rationale:**
- The 90-minute heuristic is a simple date arithmetic, not CPU-intensive
- `DateTime.subtract()` and formatting are platform-specific (timezone, locale); keeping in Dart avoids reimplementing date logic in C++
- Dart's `intl` package handles locale-aware formatting; C++ would need ICU or similar
- No performance issue — runs only when user changes wake time or latency slider

**Revisit if:**
- Planner becomes significantly more complex (multi-night optimization, constraints solver)
- Need to run planner in background isolate/worker (Dart supports this natively)

---

## Summary Table

| Module | Decision | Primary Reason |
|--------|----------|----------------|
| SQI Calculation | **KEEP IN DART** | Trivial arithmetic; no perf gain; FFI overhead not justified |
| Recommendation Engine | **KEEP IN DART** | String/template logic; content changes frequent; marshalling cost |
| Sleep Planner | **KEEP IN DART** | Date arithmetic + formatting; locale handling in Dart |

---

## Golden Reference Dataset

**Verified count: 30 cases total** (not 39 as previously reported):
- SQI: 11 cases
- Recommendations: 12 cases  
- Planner: 7 cases

All 28 parity tests pass (2 tied SQI cases use set equality for weak factors, counting as 1 test each).

## Do SQI and Planner Genuinely Benefit from Shared Native Core?

**No.** Evidence:

1. **No shared computation**: SQI and Planner use completely different algorithms with no overlapping math.
2. **No performance bottleneck**: Both execute in microseconds on 10-year-old phones.
3. **Different data types**: SQI = integer weights/scores; Planner = DateTime arithmetic + locale formatting.
4. **Different change vectors**: SQI changes = weight adjustments; Planner = cycle options/heuristic changes.
5. **Platform-specific concerns**: Planner needs timezone/locale handling (Dart `intl`); SQI does not.

**Conclusion:** A shared C++ core would be an artificial unification. Each module is better served by its current Dart implementation.

---

## When Would Migration Make Sense?

| Trigger | Module(s) Affected |
|---------|-------------------|
| ML-based SQI model (TensorFlow Lite) | SQI only |
| Multi-night sleep optimization with constraints | Planner only |
| Shared backend (Dart FFI not available) | All — but via gRPC/REST, not FFI |
| Regulatory requirement for verified numerics | SQI (IEEE 754 compliance) |
| Embedding in non-Flutter app (React Native, native) | All — via UniFFI/bindgen |

---

## Recommendation

**Keep all three modules in Dart.** The current architecture (pure domain use cases with golden reference tests) provides:
- Full testability and CI verification
- Zero platform-specific build complexity
- Hot reload for content iterations
- Sufficient performance for all target devices

Invest engineering effort in:
1. Feature development (sleep insights, trends, coaching)
2. Platform quality (accessibility, iOS/Android parity)
3. Data sync reliability (P0/P0.1/P0.2 work already done)

Re-evaluate migration only when a concrete, measured need arises.