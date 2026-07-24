# Business Rules

## 1. Sleep Planner Rules

The Sleep Planner uses the user's desired wake-up time to calculate multiple recommended bedtimes based on 90-minute sleep cycles.

### 1.1 Planner Purpose

Help users plan an appropriate bedtime based on their desired wake-up time and daily constraints.

### 1.2 Planner Inputs

- Wake-up Time (AM/PM) (required)
- Daily Constraints (optional)
  - Homework
  - School projects
  - Tutoring
  - Late arrival home
  - Personal activities

### 1.3 Planner Processing Rules

- Uses 90-minute sleep cycles
- Considers sleep latency
- Suggests multiple bedtime options

### 1.4 Planner Outputs

- Suggested bedtime (AM/PM)
- Sleep cycles
- Sleep duration

### 1.5 Planner Validation Rules

- Wake-up time cannot be empty
- Time must be valid
- Wake-up time must be within a 12-hour format (AM/PM).
- The system should reject invalid time values.

---

## 2. Sleep Quality Score Rules

The Sleep Quality Score (SQI) evaluates users' sleep-related behaviors using multiple weighted factors and categorizes the result into different sleep quality levels.

### 2.1 Score Purpose

Provide an understandable indicator of users' sleep-related behaviors.

### 2.2 Score Assessment Factors

- Sleep duration
- Sleep regularity
- Screen time
- Exercise
- Stress
- Caffeine

### 2.3 Score Range

0-100

### 2.4 Score Levels

The application categorizes users into one sleep quality level.

- Excellent
- Good
- Fair
- Poor

### 2.5 Score Processing Rules

- Each factor contributes to the total score.
- Weighted scoring is applied.

### 2.6 Score Validation Rules

All questions should be answered.

---

## 3. Recommendation Rules

Based on SQI score and user behaviour.

### 3.1 Recommendation Purpose

Recommendations are provided for users to develop healthier sleep habits.

### 3.2 Recommendation Trigger Conditions

Recommendations are generated based on:

- SQI score
- Low-scoring assessment factors
- User responses

### 3.3 Recommendation Categories

- Screen time
- Stress
- Exercise
- Sleep schedule
- Caffeine

### 3.4 Recommendation Priority Rules

- Show the most important recommendations first.
- Use concise recommendation for each.

---

## 4. History Rules

Store users' historical sleep planning and SQI results.

### 4.1 History Purpose

History is provided for users to review previous SQI results and observe changes in their sleep habits over time.

### 4.2 Stored Information

- Date
- SQI
- Level
- Planner Result

### 4.3 History Update Rules

- Save after SQI is completed.
- If the user skips a day, it will not show that day.

---

## 5. Settings Rules

Settings allows users to customize basic application settings and help users know the application information.

### 5.1 Settings Purpose

Settings are provided for users to customize basic application settings and access application information.

### 5.2 Available Settings

- Theme
- About

---

## 6. General System Rules

These rules apply across the entire application.

### 6.1 Navigation Rules

- Back button from result page should return to planner.
- Back button from planner page should return to home.
- Back button from SQI result page should return to SQI.
- Back button from SQI page should return to home.
- Back button from the rest of pages should return to home.
- Users can access Sleep Planner and SQI only from Home.
- Completing Planner or SQI should not automatically overwrite previous history.

### 6.2 Error Handling

- Display friendly messages.
- Do not crash.
- Display validation messages for missing required inputs.

### 6.3 Default Values

- Default theme is Dark.
- No default wake-up time.
- Default language follows device language.

### Rule Priorities

Critical

- Wake-up time is required.
- All SQI questions are required.

Important

- Recommendations should match the lowest-scoring factors.

Optional

- Daily constraints may be skipped.
