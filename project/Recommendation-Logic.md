# Recommendation Logic

## 1. Overview
`GenerateRecommendations` (`lib/features/recommendation/domain/usecases/generate_recommendations.dart`) produces actionable tips from an `SqiResult`.

---

## 2. Selection Rules

1. **If `level == 'excellent'`** (`score >= 80`):
   - Returns **1** general recommendation (`factor: 'General'`, `title: 'Keep up the great habits!'`, `priority: 'low'`).
2. **If `level == 'good'`** (`score 60–79`) and `weakFactors` is not empty:
   - Returns **1** recommendation for `weakFactors.first` (if mapped in `_factorMap`).
3. **Otherwise (`fair` or `poor`, or `good` with empty `weakFactors`)**:
   - Iterates `weakFactors.take(3)` in the order emitted by `CalculateSqi` (ascending weighted score) and returns matching entries from `_factorMap` (up to 3; in practice `CalculateSqi` emits at most 2 `weakFactors`).
   - *Note*: The implementation does not re-sort recommendations by `RecommendationPriority`.

---

## 3. Factor Mapping (`_factorMap`)

| Factor Key | Title | Priority |
| --- | --- | --- |
| `Sleep duration` | Aim for a consistent bedtime | `high` |
| `Sleep regularity` | Keep a steady rhythm | `critical` |
| `Screen time` | Reduce late screen exposure | `high` |
| `Exercise` | Add light activity earlier in the day | `medium` |
| `Stress` | Create a simple wind-down routine | `critical` |
| `Caffeine` | Cut back on late caffeine | `high` |

---

## 4. Persistence Contract

When saved via `SubmitSqiAssessment`, each recommendation receives ID `'$recordId-r$index'` and is written to the `recommendations` collection with `userId`, `recordId`, `factor`, `title`, `description`, `action`, `priority`, and `createdAt`.
