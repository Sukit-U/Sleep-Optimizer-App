# Recommendation Logic

## 1. Overview

### Purpose

Provide personalized suggestions that help users improve their sleep habits.

### Inputs

- SQI score
- User responses
- Assessment factors

### Outputs

- SQI score
- Sleep quality level
- Personalized recommendations
- Recommendation priority

---

## 2. Recommendation Workflow

### Step 1. Collect User Responses

Collect users' responses from the SQI questionnaire.

### Step 2. Calculate SQI

Calculate the SQI score based on the defined scoring algorithm.

### Step 3. Identify Weak Factors

Identify the lowest-scoring factors that need improvement.

### Step 4. Select Recommendations

Select recommendations that match the identified weak factors.

### Step 5. Display Results

Display the SQI score, sleep quality level, and personalized recommendations.

---

## 3. Recommendation Categories

### Sleep Duration

Recommendations related to getting sufficient sleep.

### Sleep Regularity

Recommendations related to maintaining a consistent sleep schedule.

### Screen Time

Recommendations related to reducing screen exposure before bedtime.

### Exercise

Recommendations related to physical activity.

### Stress

Recommendations related to stress management.

### Caffeine

Recommendations related to caffeine consumption.

---

## 4. Recommendation Selection Rules

### Single Weak Factor

If only one factor is poor, show recommendations only for that factor.

### Multiple Weak Factors

If multiple factors are poor, prioritize the lowest-scoring factors.

### Good SQI

If SQI is Good, provide recommendations only for the lowest-scoring factor.

### Excellent SQI

If SQI is Excellent, provide positive reinforcement.

### Poor SQI

If SQI is Poor, prioritize the most critical recommendations and encourage immediate improvement.

---

## 5. Recommendation Priority

### Critical

Highest priority recommendations that should be shown first.

### High

Important recommendations with a strong impact on sleep quality.

### Medium

Recommendations with a moderate impact.

### Low

Minor suggestions for further improvement.

## Recommendation Principles

- Recommendations should be easy to understand.
- Recommendations should be actionable.
- Recommendations should be based on user responses.
- Recommendations should encourage positive behavior rather than criticize users.
- Recommendations should be realistic for high school students.

---

## 6. Recommendation Format

### Title

Short recommendation title.

### Description

Brief explanation of why the recommendation is important.

### Action

Simple action that the user can perform.

---

## 7. General Rules

### Number of Recommendations

Maximum 3 recommendations.

### Duplicate Prevention

No duplicate recommendations.

### Personalization

Recommendations should match user responses.

---

## 8. Future Improvements

- Adaptive recommendation optimization based on user behavior and sleep patterns.
- AI-assisted sleep coaching with personalized guidance.
- Learning user preferences to improve recommendation accuracy over time.
- Integration with wearable devices for automatic sleep data collection.
- Smart reminders and bedtime notifications based on the user's schedule.
